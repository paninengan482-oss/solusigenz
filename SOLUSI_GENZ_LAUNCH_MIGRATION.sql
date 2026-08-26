-- SOLUSI GENZ LAUNCH MIGRATION 2026-08-26
-- Jalankan di Supabase SQL Editor setelah backup. Idempotent untuk struktur utama.
-- Bergantung pada schema Solusi Genz V7/V14 yang sudah ada, termasuk sg_orders, sg_admins, sg_is_admin, katalog, dan affiliate.
create extension if not exists pgcrypto;

create table if not exists public.sg_payment_proofs(
 invoice text primary key,
 buyer_email text not null,
 proof_data_url text not null,
 note text,
 status text not null default 'Menunggu Verifikasi',
 reject_reason text,
 submitted_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid
);
create table if not exists public.sg_product_access(
 invoice text primary key,
 buyer_email text not null,
 login_identity text,
 login_secret text,
 login_instruction text,
 active_until text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.sg_notifications(
 id bigint generated always as identity primary key,
 recipient_email text not null,
 category text not null default 'Info',
 title text not null,
 message text,
 action_url text,
 is_read boolean not null default false,
 created_at timestamptz not null default now()
);
create table if not exists public.sg_withdrawals(
 id bigint generated always as identity primary key,
 affiliate_email text not null,
 amount numeric(14,2) not null,
 method text not null,
 account_name text not null,
 account_number text not null,
 status text not null default 'Dalam Proses',
 reject_reason text,
 transfer_proof_data_url text,
 requested_at timestamptz not null default now(),
 completed_at timestamptz
);
create table if not exists public.sg_support_tickets(
 id bigint generated always as identity primary key,
 invoice text not null,
 buyer_email text not null,
 message text not null,
 status text not null default 'Baru',
 created_at timestamptz not null default now()
);
create table if not exists public.sg_launch_settings(
 id int primary key default 1,
 whatsapp_group_url text default '',
 minimum_withdraw numeric(14,2) not null default 50000,
 withdraw_sla text not null default 'Maksimal 1x24 jam hari kerja',
 commission_hold_rule text not null default 'Komisi tersedia setelah pesanan berstatus Selesai',
 updated_at timestamptz not null default now()
);
insert into public.sg_launch_settings(id) values(1) on conflict(id) do nothing;

alter table public.sg_payment_proofs enable row level security;
alter table public.sg_product_access enable row level security;
alter table public.sg_notifications enable row level security;
alter table public.sg_withdrawals enable row level security;
alter table public.sg_support_tickets enable row level security;
alter table public.sg_launch_settings enable row level security;

create or replace function public.sg_my_email() returns text language sql stable security definer set search_path=public as $$
 select lower(email) from auth.users where id=auth.uid();
$$;

create or replace function public.sg_user_orders()
returns table(invoice text,product_name text,price numeric,status text,payment_method text,created_at timestamptz)
language sql security definer set search_path=public as $$
 select o.invoice,o.product_name,o.price,o.status,o.payment_method,o.created_at from public.sg_orders o
 where lower(trim(o.email))=public.sg_my_email() order by o.created_at desc;
$$;

create or replace function public.sg_submit_payment_proof(p_invoice text,p_proof_data_url text,p_note text default '')
returns boolean language plpgsql security definer set search_path=public as $$
declare em text:=public.sg_my_email();
begin
 if em is null or not exists(select 1 from public.sg_orders where invoice=p_invoice and lower(trim(email))=em) then return false; end if;
 insert into public.sg_payment_proofs(invoice,buyer_email,proof_data_url,note,status,submitted_at,reject_reason)
 values(p_invoice,em,p_proof_data_url,p_note,'Menunggu Verifikasi',now(),null)
 on conflict(invoice) do update set proof_data_url=excluded.proof_data_url,note=excluded.note,status='Menunggu Verifikasi',submitted_at=now(),reject_reason=null;
 update public.sg_orders set status='Menunggu Verifikasi' where invoice=p_invoice;
 insert into public.sg_notifications(recipient_email,category,title,message,action_url)
 select a.email,'Perlu Tindakan','Bukti Pembayaran Baru','Bukti pembayaran baru untuk invoice '||p_invoice,'admin.html#payments' from public.sg_admins a where coalesce(a.active,true)=true;
 return true;
end $$;

create or replace function public.sg_my_payment_proof(p_invoice text)
returns table(status text,reject_reason text,submitted_at timestamptz) language sql security definer set search_path=public as $$
 select p.status,p.reject_reason,p.submitted_at from public.sg_payment_proofs p where p.invoice=p_invoice and p.buyer_email=public.sg_my_email();
$$;

create or replace function public.sg_my_product_access(p_invoice text)
returns table(login_identity text,login_secret text,login_instruction text,active_until text,updated_at timestamptz)
language sql security definer set search_path=public as $$
 select a.login_identity,a.login_secret,a.login_instruction,a.active_until,a.updated_at from public.sg_product_access a where a.invoice=p_invoice and a.buyer_email=public.sg_my_email();
$$;

create or replace function public.sg_my_notifications()
returns table(id bigint,category text,title text,message text,action_url text,is_read boolean,created_at timestamptz)
language sql security definer set search_path=public as $$
 select n.id,n.category,n.title,n.message,n.action_url,n.is_read,n.created_at from public.sg_notifications n where n.recipient_email=public.sg_my_email() order by n.created_at desc limit 50;
$$;
create or replace function public.sg_mark_notification_read(p_id bigint) returns boolean language plpgsql security definer set search_path=public as $$
begin update public.sg_notifications set is_read=true where id=p_id and recipient_email=public.sg_my_email(); return found; end $$;

create or replace function public.sg_submit_support_ticket(p_invoice text,p_message text) returns boolean language plpgsql security definer set search_path=public as $$
declare em text:=public.sg_my_email(); begin
 if em is null or not exists(select 1 from public.sg_orders where invoice=p_invoice and lower(trim(email))=em) then return false; end if;
 insert into public.sg_support_tickets(invoice,buyer_email,message) values(p_invoice,em,p_message);
 insert into public.sg_notifications(recipient_email,category,title,message,action_url)
 select a.email,'Perlu Tindakan','Permintaan Bantuan Baru','Kendala akses untuk '||p_invoice,'admin.html#support' from public.sg_admins a where coalesce(a.active,true)=true;
 return true; end $$;

create or replace function public.sg_admin_launch_orders()
returns table(invoice text,customer_name text,email text,whatsapp text,product_name text,price numeric,payment_method text,status text,created_at timestamptz,proof_data_url text,proof_status text,reject_reason text)
language sql security definer set search_path=public as $$
 select o.invoice,o.customer_name,o.email,o.whatsapp,o.product_name,o.price,o.payment_method,o.status,o.created_at,p.proof_data_url,p.status,p.reject_reason
 from public.sg_orders o left join public.sg_payment_proofs p on p.invoice=o.invoice
 where public.sg_is_admin() order by o.created_at desc;
$$;
create or replace function public.sg_admin_review_payment(p_invoice text,p_accept boolean,p_reason text default '') returns boolean language plpgsql security definer set search_path=public as $$
declare em text;
begin
 if not public.sg_is_admin() then raise exception 'forbidden'; end if;
 select lower(trim(email)) into em from public.sg_orders where invoice=p_invoice; if em is null then return false; end if;
 if p_accept then
  update public.sg_payment_proofs set status='Diterima',reviewed_at=now(),reviewed_by=auth.uid(),reject_reason=null where invoice=p_invoice;
  update public.sg_orders set status='Diproses',paid_at=coalesce(paid_at,now()) where invoice=p_invoice;
  insert into public.sg_notifications(recipient_email,category,title,message,action_url) values(em,'Berhasil','Pembayaran diverifikasi','Pembayaran diterima. Pesanan sedang diproses.','shop.html#orders');
 else
  update public.sg_payment_proofs set status='Ditolak',reviewed_at=now(),reviewed_by=auth.uid(),reject_reason=p_reason where invoice=p_invoice;
  update public.sg_orders set status='Menunggu Pembayaran' where invoice=p_invoice;
  insert into public.sg_notifications(recipient_email,category,title,message,action_url) values(em,'Perlu Tindakan','Kirim ulang bukti pembayaran',coalesce(nullif(p_reason,''),'Bukti pembayaran perlu dikirim ulang.'),'shop.html#orders');
 end if;
 return true;
end $$;

create or replace function public.sg_admin_send_product_access(p_invoice text,p_identity text,p_secret text,p_instruction text,p_active_until text) returns boolean language plpgsql security definer set search_path=public as $$
declare em text; begin
 if not public.sg_is_admin() then raise exception 'forbidden'; end if;
 select lower(trim(email)) into em from public.sg_orders where invoice=p_invoice; if em is null then return false; end if;
 insert into public.sg_product_access(invoice,buyer_email,login_identity,login_secret,login_instruction,active_until)
 values(p_invoice,em,p_identity,p_secret,p_instruction,p_active_until)
 on conflict(invoice) do update set login_identity=excluded.login_identity,login_secret=excluded.login_secret,login_instruction=excluded.login_instruction,active_until=excluded.active_until,updated_at=now();
 update public.sg_orders set status='Selesai' where invoice=p_invoice;
 insert into public.sg_notifications(recipient_email,category,title,message,action_url) values(em,'Berhasil','Akses produk sudah tersedia','Buka Pesanan Saya untuk melihat akses produk.','shop.html#orders');
 -- komisi menjadi tersedia hanya ketika pesanan selesai
 update public.sg_affiliate_commission_ledger set status='tersedia' where invoice=p_invoice and status<>'dibayar';
 return true; end $$;

create or replace function public.sg_affiliate_wallet(p_email text)
returns table(referral_code text,total_referrals bigint,referrals_bought bigint,held numeric,available numeric,total numeric,minimum_withdraw numeric)
language plpgsql security definer set search_path=public as $$
declare em text:=public.sg_my_email(); c text; held_v numeric; earned_v numeric; reserved_v numeric; begin
 if em is null or em<>lower(trim(p_email)) then raise exception 'forbidden'; end if;
 c:=public.sg_affiliate_register(em,auth.uid());
 select coalesce(sum(l.commission_amount),0) into held_v from public.sg_affiliate_commission_ledger l where l.affiliate_email=em and l.status in ('tercatat','tertahan');
 select coalesce(sum(l.commission_amount),0) into earned_v from public.sg_affiliate_commission_ledger l where l.affiliate_email=em and l.status in ('tersedia','dibayar');
 select coalesce(sum(w.amount),0) into reserved_v from public.sg_withdrawals w where w.affiliate_email=em and w.status in ('Dalam Proses','Selesai');
 return query select c,
  (select count(*) from public.sg_referrals r where r.affiliate_email=em),
  (select count(distinct l.buyer_email) from public.sg_affiliate_commission_ledger l where l.affiliate_email=em and l.commission_amount>0),
  held_v,
  greatest(earned_v-reserved_v,0),
  held_v+earned_v,
  (select s.minimum_withdraw from public.sg_launch_settings s where id=1);
end $$;

create or replace function public.sg_request_withdrawal(p_amount numeric,p_method text,p_account_name text,p_account_number text) returns bigint language plpgsql security definer set search_path=public as $$
declare em text:=public.sg_my_email(); earned numeric; reserved numeric; avail numeric; minwd numeric; wid bigint; begin
 if em is null then raise exception 'forbidden'; end if;
 select coalesce(sum(commission_amount),0) into earned from public.sg_affiliate_commission_ledger where affiliate_email=em and status in ('tersedia','dibayar');
 select coalesce(sum(amount),0) into reserved from public.sg_withdrawals where affiliate_email=em and status in ('Dalam Proses','Selesai');
 avail:=greatest(earned-reserved,0);
 select minimum_withdraw into minwd from public.sg_launch_settings where id=1;
 if p_amount<minwd or p_amount>avail then raise exception 'Saldo tidak mencukupi atau di bawah minimum withdraw'; end if;
 insert into public.sg_withdrawals(affiliate_email,amount,method,account_name,account_number) values(em,p_amount,p_method,p_account_name,p_account_number) returning id into wid;
 insert into public.sg_notifications(recipient_email,category,title,message,action_url) select a.email,'Perlu Tindakan','Permintaan Pencairan Baru','Permintaan withdraw dari '||em,'admin.html#withdrawals' from public.sg_admins a where coalesce(a.active,true)=true;
 return wid; end $$;

create or replace function public.sg_my_withdrawals() returns table(id bigint,amount numeric,method text,account_name text,account_number text,status text,reject_reason text,transfer_proof_data_url text,requested_at timestamptz,completed_at timestamptz)
language sql security definer set search_path=public as $$ select w.id,w.amount,w.method,w.account_name,w.account_number,w.status,w.reject_reason,w.transfer_proof_data_url,w.requested_at,w.completed_at from public.sg_withdrawals w where w.affiliate_email=public.sg_my_email() order by w.requested_at desc; $$;

create or replace function public.sg_admin_withdrawals() returns setof public.sg_withdrawals language sql security definer set search_path=public as $$ select * from public.sg_withdrawals where public.sg_is_admin() order by requested_at desc; $$;
create or replace function public.sg_admin_finish_withdrawal(p_id bigint,p_accept boolean,p_reason text,p_transfer_proof_data_url text default '') returns boolean language plpgsql security definer set search_path=public as $$
declare em text; begin
 if not public.sg_is_admin() then raise exception 'forbidden'; end if;
 select affiliate_email into em from public.sg_withdrawals where id=p_id; if em is null then return false; end if;
 if p_accept then
  update public.sg_withdrawals set status='Selesai',transfer_proof_data_url=p_transfer_proof_data_url,completed_at=now() where id=p_id;
  insert into public.sg_notifications(recipient_email,category,title,message,action_url) values(em,'Berhasil','Pencairan berhasil','Pencairan affiliate telah ditransfer.','affiliate.html#withdraw');
 else
  update public.sg_withdrawals set status='Ditolak',reject_reason=p_reason,completed_at=now() where id=p_id;
  insert into public.sg_notifications(recipient_email,category,title,message,action_url) values(em,'Perlu Tindakan','Pencairan ditolak',p_reason,'affiliate.html#withdraw');
 end if; return true; end $$;

create or replace function public.sg_public_launch_settings() returns table(whatsapp_group_url text,minimum_withdraw numeric,withdraw_sla text,commission_hold_rule text) language sql security definer set search_path=public as $$ select whatsapp_group_url,minimum_withdraw,withdraw_sla,commission_hold_rule from public.sg_launch_settings where id=1; $$;
create or replace function public.sg_admin_save_launch_settings(p_whatsapp_group_url text,p_minimum_withdraw numeric,p_withdraw_sla text,p_commission_hold_rule text) returns boolean language plpgsql security definer set search_path=public as $$ begin if not public.sg_is_admin() then raise exception 'forbidden'; end if; update public.sg_launch_settings set whatsapp_group_url=p_whatsapp_group_url,minimum_withdraw=p_minimum_withdraw,withdraw_sla=p_withdraw_sla,commission_hold_rule=p_commission_hold_rule,updated_at=now() where id=1; return true; end $$;

grant execute on function public.sg_user_orders() to authenticated;
grant execute on function public.sg_submit_payment_proof(text,text,text) to authenticated;
grant execute on function public.sg_my_payment_proof(text) to authenticated;
grant execute on function public.sg_my_product_access(text) to authenticated;
grant execute on function public.sg_my_notifications() to authenticated;
grant execute on function public.sg_mark_notification_read(bigint) to authenticated;
grant execute on function public.sg_submit_support_ticket(text,text) to authenticated;
grant execute on function public.sg_affiliate_wallet(text) to authenticated;
grant execute on function public.sg_request_withdrawal(numeric,text,text,text) to authenticated;
grant execute on function public.sg_my_withdrawals() to authenticated;
grant execute on function public.sg_admin_launch_orders() to authenticated;
grant execute on function public.sg_admin_review_payment(text,boolean,text) to authenticated;
grant execute on function public.sg_admin_send_product_access(text,text,text,text,text) to authenticated;
grant execute on function public.sg_admin_withdrawals() to authenticated;
grant execute on function public.sg_admin_finish_withdrawal(bigint,boolean,text,text) to authenticated;
grant execute on function public.sg_admin_save_launch_settings(text,numeric,text,text) to authenticated;
grant execute on function public.sg_public_launch_settings() to anon,authenticated;
notify pgrst,'reload schema';
