-- SOLUSI GENZ V15.1 - FLOW FINAL + DATABASE COMPATIBILITY FIX
-- Jalankan SEKALI di Supabase SQL Editor SETELAH backup database.
-- Tidak menghapus pesanan lama. Menambahkan flow bukti bayar, akses produk,
-- affiliate fixed per durasi, saldo/withdraw, notifikasi dan komunitas.


-- =========================================================
-- V15.1 COMPATIBILITY PREFLIGHT (database versi lama)
-- Menghapus hanya RPC/function Solusi Genz yang akan dibuat ulang.
-- Data tabel/pesanan TIDAK dihapus.
-- =========================================================
do $$
declare r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname = any(array[
      'sg_notify','sg_my_notifications','sg_mark_notification_read','sg_create_order',
      'sg_submit_payment','sg_my_order_details','sg_my_orders','sg_admin_list_orders',
      'sg_admin_verify_payment','sg_admin_send_access','sg_make_referral_code',
      'sg_affiliate_register','sg_affiliate_attach_referral','sg_commission_by_duration',
      'sg_sync_commission_for_order','sg_order_affiliate_trigger','sg_affiliate_eligibility',
      'sg_affiliate_me','sg_affiliate_commissions','sg_request_withdraw','sg_my_withdrawals',
      'sg_admin_list_withdrawals','sg_admin_finish_withdraw','sg_customer_community',
      'sg_admin_save_flow_settings','sg_public_extra_settings','sg_admin_get_flow_settings',
      'sg_owner_affiliate_summary','sg_apply_affiliate_commission_on_paid'
    ])
  loop
    execute 'drop function if exists '||r.sig||' cascade';
  end loop;
end $$;

-- =========================================================
-- 0. STATUS PESANAN YANG KONSISTEN
-- =========================================================
do $$
declare r record;
begin
  for r in select conname from pg_constraint
    where conrelid='public.sg_orders'::regclass and contype='c'
      and pg_get_constraintdef(oid) ilike '%status%'
  loop execute format('alter table public.sg_orders drop constraint %I',r.conname); end loop;
end $$;

alter table public.sg_orders add constraint sg_orders_status_check check (status in (
  'pending','Menunggu Pembayaran','Menunggu Verifikasi','Diproses','Selesai','Dibatalkan','Bermasalah','Lunas','Dibayar'
));
update public.sg_orders set status='Menunggu Pembayaran' where status='pending';

-- =========================================================
-- 1. DATA PEMBAYARAN + AKSES PRODUK
-- =========================================================
alter table public.sg_orders add column if not exists payment_proof_data_url text;
alter table public.sg_orders add column if not exists payment_proof_submitted_at timestamptz;
alter table public.sg_orders add column if not exists payment_rejection_reason text;
alter table public.sg_orders add column if not exists access_username text;
alter table public.sg_orders add column if not exists access_password text;
alter table public.sg_orders add column if not exists access_instructions text;
alter table public.sg_orders add column if not exists access_expires_at timestamptz;
alter table public.sg_orders add column if not exists access_sent_at timestamptz;

-- =========================================================
-- 2. PENGATURAN TOKO TAMBAHAN
-- =========================================================
create table if not exists public.sg_store_settings_ext (
 id int primary key default 1,
 founder_name text not null default 'Difa Al Azizi',
 sourcing_name text not null default 'Difa Al Azizi',
 affiliate_enabled boolean not null default true,
 whatsapp_group_url text not null default '',
 withdraw_minimum bigint not null default 50000,
 updated_at timestamptz not null default now()
);
insert into public.sg_store_settings_ext(id) values(1) on conflict(id) do nothing;
alter table public.sg_store_settings_ext add column if not exists sourcing_name text not null default 'Difa Al Azizi';
alter table public.sg_store_settings_ext add column if not exists whatsapp_group_url text not null default '';
alter table public.sg_store_settings_ext add column if not exists withdraw_minimum bigint not null default 50000;
update public.sg_store_settings_ext set founder_name='Difa Al Azizi', sourcing_name='Difa Al Azizi' where id=1;

-- =========================================================
-- 3. NOTIFIKASI
-- =========================================================
create table if not exists public.sg_notifications (
 id bigint generated always as identity primary key,
 email text not null,
 category text not null default 'Info' check(category in ('Info','Perlu Tindakan','Berhasil')),
 title text not null,
 message text not null default '',
 action_url text,
 read_at timestamptz,
 created_at timestamptz not null default now()
);
-- Kompatibilitas tabel notifikasi dari versi lama
alter table public.sg_notifications add column if not exists email text;
alter table public.sg_notifications add column if not exists category text default 'Info';
alter table public.sg_notifications add column if not exists title text;
alter table public.sg_notifications add column if not exists message text default '';
alter table public.sg_notifications add column if not exists action_url text;
alter table public.sg_notifications add column if not exists read_at timestamptz;
alter table public.sg_notifications add column if not exists created_at timestamptz default now();
alter table public.sg_notifications enable row level security;
create index if not exists sg_notifications_email_created_idx on public.sg_notifications(lower(email),created_at desc);

create or replace function public.sg_notify(p_email text,p_category text,p_title text,p_message text,p_action_url text default null)
returns bigint language plpgsql security definer set search_path=public as $$
declare v_id bigint;
begin
 insert into public.sg_notifications(email,category,title,message,action_url)
 values(lower(p_email),case when p_category in ('Info','Perlu Tindakan','Berhasil') then p_category else 'Info' end,p_title,coalesce(p_message,''),p_action_url)
 returning id into v_id;
 return v_id;
end $$;

create or replace function public.sg_my_notifications()
returns table(id bigint,category text,title text,message text,action_url text,read_at timestamptz,created_at timestamptz)
language sql security definer set search_path=public as $$
 select n.id,n.category,n.title,n.message,n.action_url,n.read_at,n.created_at
 from public.sg_notifications n where lower(n.email)=lower(coalesce(auth.jwt()->>'email',''))
 order by n.created_at desc limit 50;
$$;

create or replace function public.sg_mark_notification_read(p_id bigint)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.sg_notifications set read_at=now()
 where id=p_id and lower(email)=lower(coalesce(auth.jwt()->>'email',''));
 return found;
end $$;

-- =========================================================
-- 4. CHECKOUT & BUKTI PEMBAYARAN
-- =========================================================
create or replace function public.sg_create_order(
 p_invoice text,p_product_name text,p_price bigint,p_customer_name text,p_whatsapp text,p_email text,p_payment_method text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_product_id uuid; v_order_id uuid; v_jwt_email text:=lower(coalesce(auth.jwt()->>'email',''));
begin
 if auth.uid() is null or v_jwt_email='' or v_jwt_email<>lower(trim(p_email)) then raise exception 'Harus login sebagai pemilik pesanan'; end if;
 select id into v_product_id from public.sg_products where lower(name)=lower(p_product_name) limit 1;
 insert into public.sg_orders(invoice,customer_id,product_id,product_name,price,status,customer_name,whatsapp,email,payment_method,created_at)
 values(p_invoice,null,v_product_id,p_product_name,p_price,'Menunggu Pembayaran',p_customer_name,p_whatsapp,lower(p_email),p_payment_method,now())
 returning id into v_order_id;
 return jsonb_build_object('id',v_order_id,'invoice',p_invoice,'status','Menunggu Pembayaran');
end $$;

drop function if exists public.sg_submit_payment(text);
create or replace function public.sg_submit_payment(p_invoice text,p_proof_data_url text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_email text:=lower(coalesce(auth.jwt()->>'email',''));
begin
 if auth.uid() is null then raise exception 'Harus login'; end if;
 if p_proof_data_url is null or length(p_proof_data_url)<100 then raise exception 'Bukti pembayaran wajib diunggah'; end if;
 if length(p_proof_data_url)>2500000 then raise exception 'Ukuran bukti terlalu besar'; end if;
 update public.sg_orders set status='Menunggu Verifikasi',payment_proof_data_url=p_proof_data_url,
   payment_proof_submitted_at=now(),payment_rejection_reason=null
 where invoice=p_invoice and lower(email)=v_email and status in ('pending','Menunggu Pembayaran','Bermasalah');
 if not found then raise exception 'Pesanan tidak ditemukan atau tidak dapat dikirim'; end if;
 perform public.sg_notify(v_email,'Info','Bukti pembayaran terkirim','Bukti pembayaran sedang menunggu verifikasi Admin.','status.html?id='||p_invoice);
 return jsonb_build_object('invoice',p_invoice,'status','Menunggu Verifikasi');
end $$;

create or replace function public.sg_my_order_details(p_invoice text)
returns table(invoice text,product_name text,price bigint,status text,customer_name text,payment_method text,created_at timestamptz,payment_rejection_reason text,access_username text,access_password text,access_instructions text,access_expires_at timestamptz,access_sent_at timestamptz)
language sql security definer set search_path=public as $$
 select o.invoice,o.product_name,o.price,o.status,o.customer_name,o.payment_method,o.created_at,o.payment_rejection_reason,
   case when o.access_sent_at is not null then o.access_username else null end,
   case when o.access_sent_at is not null then o.access_password else null end,
   case when o.access_sent_at is not null then o.access_instructions else null end,
   o.access_expires_at,o.access_sent_at
 from public.sg_orders o
 where o.invoice=p_invoice and lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) limit 1;
$$;

create or replace function public.sg_my_orders()
returns table(invoice text,product_name text,price bigint,status text,payment_method text,created_at timestamptz,access_sent_at timestamptz)
language sql security definer set search_path=public as $$
 select o.invoice,o.product_name,o.price,o.status,o.payment_method,o.created_at,o.access_sent_at
 from public.sg_orders o where lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) order by o.created_at desc;
$$;

-- =========================================================
-- 5. ADMIN PESANAN / VERIFIKASI / AKSES PRODUK
-- =========================================================
drop function if exists public.sg_admin_list_orders();
create function public.sg_admin_list_orders()
returns table(invoice text,customer_name text,whatsapp text,email text,product_name text,price bigint,payment_method text,status text,created_at timestamptz,payment_proof_data_url text,payment_proof_submitted_at timestamptz,payment_rejection_reason text,access_sent_at timestamptz)
language plpgsql security definer set search_path=public as $$
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select o.invoice,o.customer_name,o.whatsapp,o.email,o.product_name,o.price,o.payment_method,o.status,o.created_at,
 o.payment_proof_data_url,o.payment_proof_submitted_at,o.payment_rejection_reason,o.access_sent_at
 from public.sg_orders o order by o.created_at desc nulls last;
end $$;

create or replace function public.sg_admin_verify_payment(p_invoice text,p_accept boolean,p_reason text default '')
returns boolean language plpgsql security definer set search_path=public as $$
declare v_email text;
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 select lower(email) into v_email from public.sg_orders where invoice=p_invoice;
 if v_email is null then raise exception 'Pesanan tidak ditemukan'; end if;
 if p_accept then
   update public.sg_orders set status='Diproses',payment_rejection_reason=null where invoice=p_invoice and status='Menunggu Verifikasi';
   perform public.sg_notify(v_email,'Berhasil','Pembayaran diverifikasi','Pembayaran sudah diterima. Pesanan sedang diproses.','status.html?id='||p_invoice);
 else
   update public.sg_orders set status='Bermasalah',payment_rejection_reason=coalesce(nullif(trim(p_reason),''),'Bukti pembayaran perlu dikirim ulang.') where invoice=p_invoice;
   perform public.sg_notify(v_email,'Perlu Tindakan','Kirim ulang bukti pembayaran',coalesce(nullif(trim(p_reason),''),'Bukti pembayaran perlu dikirim ulang.'),'status.html?id='||p_invoice);
 end if;
 return found;
end $$;

create or replace function public.sg_admin_send_access(p_invoice text,p_username text,p_password text,p_instructions text,p_expires_at timestamptz default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare v_email text;
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 update public.sg_orders set access_username=p_username,access_password=p_password,access_instructions=p_instructions,
 access_expires_at=p_expires_at,access_sent_at=now(),status='Selesai' where invoice=p_invoice and status in ('Diproses','Lunas','Dibayar') returning lower(email) into v_email;
 if v_email is null then raise exception 'Pesanan belum siap dikirim atau tidak ditemukan'; end if;
 perform public.sg_notify(v_email,'Berhasil','Akses produk sudah tersedia','Buka detail pesanan untuk melihat akses produk.','status.html?id='||p_invoice);
 return true;
end $$;

-- =========================================================
-- 6. AFFILIATE: RELASI TETAP + KOMISI FIXED BERDASARKAN DURASI
-- =========================================================
create table if not exists public.sg_affiliates(user_id uuid,email text primary key,referral_code text unique not null,created_at timestamptz not null default now());
create table if not exists public.sg_referrals(buyer_user_id uuid,buyer_email text primary key,affiliate_email text not null references public.sg_affiliates(email) on delete restrict,referral_code text not null,created_at timestamptz not null default now());
create table if not exists public.sg_affiliate_commission_ledger(
 id bigint generated always as identity primary key,invoice text unique not null,affiliate_email text not null references public.sg_affiliates(email) on delete restrict,
 buyer_email text not null,order_amount numeric(14,2) not null default 0,commission_rate numeric(5,2) not null default 0,commission_amount numeric(14,2) not null default 0,
 status text not null default 'tertahan',created_at timestamptz not null default now(),available_at timestamptz,paid_at timestamptz
);
alter table public.sg_affiliates enable row level security;
alter table public.sg_referrals enable row level security;
alter table public.sg_affiliate_commission_ledger enable row level security;
alter table public.sg_affiliate_commission_ledger add column if not exists available_at timestamptz;

do $$ declare r record; begin
 for r in select conname from pg_constraint where conrelid='public.sg_affiliate_commission_ledger'::regclass and contype='c' and pg_get_constraintdef(oid) ilike '%status%'
 loop execute format('alter table public.sg_affiliate_commission_ledger drop constraint %I',r.conname); end loop;
end $$;
update public.sg_affiliate_commission_ledger set status='tertahan' where status='tercatat';
alter table public.sg_affiliate_commission_ledger add constraint sg_affiliate_ledger_status_check check(status in ('tertahan','tersedia','diproses','dibayar','dibatalkan'));

create or replace function public.sg_make_referral_code(p_email text) returns text language sql immutable as $$ select upper(substr(md5(lower(coalesce(p_email,''))),1,8)); $$;

create or replace function public.sg_affiliate_register(p_email text default null,p_user_id uuid default null)
returns text language plpgsql security definer set search_path=public as $$
declare v_email text:=lower(coalesce(auth.jwt()->>'email','')); c text;
begin
 if auth.uid() is null or v_email='' then raise exception 'Harus login'; end if;
 if not exists(select 1 from public.sg_orders o where lower(o.email)=v_email and o.status in ('Diproses','Selesai','Lunas','Dibayar')) then raise exception 'Affiliate aktif setelah transaksi pertama valid'; end if;
 c:=public.sg_make_referral_code(v_email);
 insert into public.sg_affiliates(user_id,email,referral_code) values(auth.uid(),v_email,c)
 on conflict(email) do update set user_id=coalesce(excluded.user_id,sg_affiliates.user_id);
 return c;
end $$;

create or replace function public.sg_affiliate_attach_referral(p_buyer_email text,p_buyer_user_id uuid,p_referral_code text)
returns boolean language plpgsql security definer set search_path=public as $$
declare aff text; v_email text:=lower(coalesce(auth.jwt()->>'email',''));
begin
 if auth.uid() is null or v_email='' or v_email<>lower(p_buyer_email) then return false; end if;
 if p_referral_code is null or trim(p_referral_code)='' then return false; end if;
 select a.email into aff from public.sg_affiliates a where a.referral_code=upper(trim(p_referral_code)) and exists(select 1 from public.sg_orders o where lower(o.email)=lower(a.email) and o.status in ('Diproses','Selesai','Lunas','Dibayar')) limit 1;
 if aff is null or lower(aff)=v_email then return false; end if;
 insert into public.sg_referrals(buyer_user_id,buyer_email,affiliate_email,referral_code)
 values(coalesce(p_buyer_user_id,auth.uid()),v_email,aff,upper(trim(p_referral_code))) on conflict(buyer_email) do nothing;
 return exists(select 1 from public.sg_referrals where buyer_email=v_email and affiliate_email=aff);
end $$;

create or replace function public.sg_commission_by_duration(p_product_name text)
returns numeric language plpgsql immutable as $$
declare s text:=lower(coalesce(p_product_name,'')); begin
 if s ~ '(1[ -]?3 *hari|1 *hari|2 *hari|3 *hari)' then return 2000;
 elsif s ~ '(1 *minggu|7 *hari)' then return 5000;
 elsif s ~ '(1 *bulan|30 *hari)' then return 10000;
 elsif s ~ '(1 *tahun|12 *bulan|365 *hari)' then return 20000;
 else return 0; end if;
end $$;

create or replace function public.sg_sync_commission_for_order(p_invoice text)
returns boolean language plpgsql security definer set search_path=public as $$
declare o record; aff text; v_comm numeric; v_duration text;
begin
 select * into o from public.sg_orders where invoice=p_invoice;
 if o.invoice is null or o.status not in ('Diproses','Selesai','Lunas','Dibayar') then return false; end if;
 select affiliate_email into aff from public.sg_referrals where lower(buyer_email)=lower(o.email) limit 1;
 if aff is null then return false; end if;
 select duration into v_duration from public.sg_catalog_products where lower(name)=lower(o.product_name) limit 1;
 v_comm:=public.sg_commission_by_duration(coalesce(v_duration,'')||' '||o.product_name);
 if v_comm<=0 then raise notice 'Durasi produk % belum dikenali; komisi tidak dibuat agar nominal tidak salah.',o.product_name; return false; end if;
 if coalesce(v_comm,0)<=0 then return false; end if;
 insert into public.sg_affiliate_commission_ledger(invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount,status,created_at,available_at)
 values(o.invoice,aff,lower(o.email),o.price,0,v_comm,case when o.status='Selesai' then 'tersedia' else 'tertahan' end,now(),case when o.status='Selesai' then now() else null end)
 on conflict(invoice) do update set affiliate_email=excluded.affiliate_email,buyer_email=excluded.buyer_email,order_amount=excluded.order_amount,commission_amount=excluded.commission_amount,
 status=case when public.sg_affiliate_commission_ledger.status in ('dibayar','diproses') then public.sg_affiliate_commission_ledger.status else excluded.status end,
 available_at=case when excluded.status='tersedia' then coalesce(public.sg_affiliate_commission_ledger.available_at,now()) else public.sg_affiliate_commission_ledger.available_at end;
 return true;
end $$;

create or replace function public.sg_order_affiliate_trigger() returns trigger language plpgsql security definer set search_path=public as $$
begin
 if new.status in ('Diproses','Selesai','Lunas','Dibayar') and old.status is distinct from new.status then perform public.sg_sync_commission_for_order(new.invoice); end if;
 return new;
end $$;
drop trigger if exists trg_sg_affiliate_commission_on_paid on public.sg_orders;
drop trigger if exists trg_sg_order_affiliate_v15 on public.sg_orders;
create trigger trg_sg_order_affiliate_v15 after update of status on public.sg_orders for each row execute function public.sg_order_affiliate_trigger();

-- Isi ledger untuk order lama yang sudah valid dan mempunyai referral.
do $$ declare r record; begin
 for r in select invoice from public.sg_orders where status in ('Diproses','Selesai','Lunas','Dibayar') loop perform public.sg_sync_commission_for_order(r.invoice); end loop;
end $$;

create or replace function public.sg_affiliate_eligibility(p_email text)
returns table(eligible boolean,valid_orders bigint) language sql security definer set search_path=public as $$
 select exists(select 1 from public.sg_orders o where lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) and o.status in ('Diproses','Selesai','Lunas','Dibayar')),
 (select count(*) from public.sg_orders o where lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) and o.status in ('Diproses','Selesai','Lunas','Dibayar'));
$$;

drop function if exists public.sg_affiliate_me(text);
create or replace function public.sg_affiliate_me(p_email text default null)
returns table(referral_code text,total_referrals bigint,total_buyers bigint,total_transactions bigint,held_commission numeric,available_commission numeric,processing_commission numeric,total_commission numeric,paid_commission numeric)
language plpgsql security definer set search_path=public as $$
declare e text:=lower(coalesce(auth.jwt()->>'email','')); c text;
begin
 if auth.uid() is null or e='' then raise exception 'Harus login'; end if;
 c:=public.sg_affiliate_register();
 return query select c,
 (select count(*) from public.sg_referrals r where r.affiliate_email=e),
 (select count(distinct l.buyer_email) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e),
 (select count(*) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e and l.status='tertahan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e and l.status='tersedia'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e and l.status='diproses'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e and l.status<>'dibatalkan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=e and l.status='dibayar'),0);
end $$;

drop function if exists public.sg_affiliate_commissions(text);
create or replace function public.sg_affiliate_commissions(p_email text default null)
returns table(invoice text,buyer_email text,order_amount numeric,commission_amount numeric,status text,created_at timestamptz,available_at timestamptz,paid_at timestamptz)
language sql security definer set search_path=public as $$
 select l.invoice,l.buyer_email,l.order_amount,l.commission_amount,l.status,l.created_at,l.available_at,l.paid_at
 from public.sg_affiliate_commission_ledger l where l.affiliate_email=lower(coalesce(auth.jwt()->>'email','')) order by l.created_at desc;
$$;

-- =========================================================
-- 7. WITHDRAW
-- =========================================================
create table if not exists public.sg_withdrawals(
 id bigint generated always as identity primary key,
 affiliate_email text not null references public.sg_affiliates(email) on delete restrict,
 amount numeric(14,2) not null check(amount>0),
 method text not null,account_name text not null,account_number text not null,
 status text not null default 'diproses' check(status in ('diproses','dibayar','ditolak')),
 admin_note text,proof_data_url text,created_at timestamptz not null default now(),processed_at timestamptz
);
alter table public.sg_withdrawals enable row level security;

create or replace function public.sg_request_withdraw(p_amount numeric,p_method text,p_account_name text,p_account_number text)
returns bigint language plpgsql security definer set search_path=public as $$
declare e text:=lower(coalesce(auth.jwt()->>'email','')); v_avail numeric; v_min bigint; v_id bigint; v_remaining numeric;
begin
 if auth.uid() is null then raise exception 'Harus login'; end if;
 perform public.sg_affiliate_register();
 if exists(select 1 from public.sg_withdrawals where affiliate_email=e and status='diproses') then raise exception 'Masih ada pencairan yang sedang diproses'; end if;
 select withdraw_minimum into v_min from public.sg_store_settings_ext where id=1;
 select coalesce(sum(commission_amount),0) into v_avail from public.sg_affiliate_commission_ledger where affiliate_email=e and status='tersedia';
 if p_amount<v_min then raise exception 'Minimum pencairan Rp %',v_min; end if;
 if p_amount>v_avail then raise exception 'Saldo tersedia tidak mencukupi'; end if;
 insert into public.sg_withdrawals(affiliate_email,amount,method,account_name,account_number) values(e,p_amount,trim(p_method),trim(p_account_name),trim(p_account_number)) returning id into v_id;
 v_remaining:=p_amount;
 for v_id in select id from public.sg_affiliate_commission_ledger where affiliate_email=e and status='tersedia' order by available_at,created_at for update loop
   exit when v_remaining<=0;
   if (select commission_amount from public.sg_affiliate_commission_ledger where id=v_id)<=v_remaining then
     v_remaining:=v_remaining-(select commission_amount from public.sg_affiliate_commission_ledger where id=v_id);
     update public.sg_affiliate_commission_ledger set status='diproses' where id=v_id;
   else
     raise exception 'Ajukan nominal sesuai kelipatan komisi yang tersedia';
   end if;
 end loop;
 select max(id) into v_id from public.sg_withdrawals where affiliate_email=e and status='diproses';
 perform public.sg_notify(e,'Info','Pencairan diajukan','Permintaan pencairan sedang diproses Admin.','affiliate.html');
 return v_id;
end $$;

create or replace function public.sg_my_withdrawals()
returns table(id bigint,amount numeric,method text,account_name text,account_number text,status text,admin_note text,proof_data_url text,created_at timestamptz,processed_at timestamptz)
language sql security definer set search_path=public as $$
 select w.id,w.amount,w.method,w.account_name,w.account_number,w.status,w.admin_note,w.proof_data_url,w.created_at,w.processed_at
 from public.sg_withdrawals w where w.affiliate_email=lower(coalesce(auth.jwt()->>'email','')) order by w.created_at desc;
$$;

create or replace function public.sg_admin_list_withdrawals()
returns table(id bigint,affiliate_email text,amount numeric,method text,account_name text,account_number text,status text,admin_note text,proof_data_url text,created_at timestamptz,processed_at timestamptz)
language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select w.id,w.affiliate_email,w.amount,w.method,w.account_name,w.account_number,w.status,w.admin_note,w.proof_data_url,w.created_at,w.processed_at from public.sg_withdrawals w order by w.created_at desc;
end $$;

create or replace function public.sg_admin_finish_withdraw(p_id bigint,p_paid boolean,p_note text default '',p_proof_data_url text default '')
returns boolean language plpgsql security definer set search_path=public as $$
declare v_w public.sg_withdrawals%rowtype; v_ledger record; v_left numeric;
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 select * into v_w from public.sg_withdrawals where id=p_id and status='diproses' for update;
 if v_w.id is null then raise exception 'Permintaan tidak ditemukan / sudah diproses'; end if;
 v_left:=v_w.amount;
 if p_paid then
   if p_proof_data_url is null or length(p_proof_data_url)<100 then raise exception 'Bukti transfer wajib diunggah'; end if;
   update public.sg_withdrawals set status='dibayar',admin_note=p_note,proof_data_url=p_proof_data_url,processed_at=now() where id=p_id;
   for v_ledger in select id,commission_amount from public.sg_affiliate_commission_ledger where affiliate_email=v_w.affiliate_email and status='diproses' order by created_at for update loop
     exit when v_left<=0;
     update public.sg_affiliate_commission_ledger set status='dibayar',paid_at=now() where id=v_ledger.id;
     v_left:=v_left-v_ledger.commission_amount;
   end loop;
   perform public.sg_notify(v_w.affiliate_email,'Berhasil','Pencairan berhasil','Dana sudah ditransfer. Bukti transfer tersedia di riwayat pencairan.','affiliate.html');
 else
   update public.sg_withdrawals set status='ditolak',admin_note=coalesce(nullif(trim(p_note),''),'Permintaan pencairan ditolak.'),processed_at=now() where id=p_id;
   update public.sg_affiliate_commission_ledger set status='tersedia' where affiliate_email=v_w.affiliate_email and status='diproses';
   perform public.sg_notify(v_w.affiliate_email,'Perlu Tindakan','Pencairan ditolak',coalesce(nullif(trim(p_note),''),'Periksa kembali data pencairan.'),'affiliate.html');
 end if;
 return true;
end $$;

-- =========================================================
-- 8. KOMUNITAS + SETTINGS
-- =========================================================
create or replace function public.sg_customer_community()
returns table(eligible boolean,whatsapp_group_url text) language sql security definer set search_path=public as $$
 select exists(select 1 from public.sg_orders o where lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) and o.status in ('Diproses','Selesai','Lunas','Dibayar')),
 case when exists(select 1 from public.sg_orders o where lower(o.email)=lower(coalesce(auth.jwt()->>'email','')) and o.status in ('Diproses','Selesai','Lunas','Dibayar'))
 then (select e.whatsapp_group_url from public.sg_store_settings_ext e where e.id=1) else '' end;
$$;

create or replace function public.sg_admin_save_flow_settings(p_whatsapp_group_url text,p_withdraw_minimum bigint,p_founder_name text,p_sourcing_name text)
returns boolean language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 update public.sg_store_settings_ext set whatsapp_group_url=coalesce(trim(p_whatsapp_group_url),''),withdraw_minimum=greatest(0,coalesce(p_withdraw_minimum,50000)),
 founder_name=coalesce(nullif(trim(p_founder_name),''),'Difa Al Azizi'),sourcing_name=coalesce(nullif(trim(p_sourcing_name),''),'Difa Al Azizi'),updated_at=now() where id=1; return true; end $$;

drop function if exists public.sg_public_extra_settings();
create or replace function public.sg_public_extra_settings()
returns table(founder_name text,sourcing_name text,affiliate_enabled boolean,withdraw_minimum bigint)
language sql security definer set search_path=public as $$ select founder_name,sourcing_name,affiliate_enabled,withdraw_minimum from public.sg_store_settings_ext where id=1; $$;

create or replace function public.sg_admin_get_flow_settings()
returns table(whatsapp_group_url text,withdraw_minimum bigint,founder_name text,sourcing_name text)
language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select e.whatsapp_group_url,e.withdraw_minimum,e.founder_name,e.sourcing_name from public.sg_store_settings_ext e where e.id=1; end $$;

-- =========================================================
-- 9. OWNER AFFILIATE SUMMARY
-- =========================================================
drop function if exists public.sg_owner_affiliate_summary();
create function public.sg_owner_affiliate_summary()
returns table(affiliate_email text,referral_code text,total_referrals bigint,total_buyers bigint,total_transactions bigint,held_commission numeric,available_commission numeric,processing_commission numeric,total_commission numeric,paid_commission numeric)
language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select a.email,a.referral_code,
 (select count(*) from public.sg_referrals r where r.affiliate_email=a.email),
 (select count(distinct l.buyer_email) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email),
 (select count(*) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status='tertahan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status='tersedia'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status='diproses'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status<>'dibatalkan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status='dibayar'),0)
 from public.sg_affiliates a order by a.created_at desc;
end $$;

-- =========================================================
-- 10. GRANTS
-- =========================================================
grant execute on function public.sg_create_order(text,text,bigint,text,text,text,text) to authenticated;
grant execute on function public.sg_submit_payment(text,text) to authenticated;
grant execute on function public.sg_my_order_details(text) to authenticated;
grant execute on function public.sg_my_orders() to authenticated;
grant execute on function public.sg_my_notifications() to authenticated;
grant execute on function public.sg_mark_notification_read(bigint) to authenticated;
grant execute on function public.sg_affiliate_register(text,uuid) to authenticated;
grant execute on function public.sg_affiliate_attach_referral(text,uuid,text) to authenticated;
grant execute on function public.sg_affiliate_eligibility(text) to authenticated;
grant execute on function public.sg_affiliate_me(text) to authenticated;
grant execute on function public.sg_affiliate_commissions(text) to authenticated;
grant execute on function public.sg_request_withdraw(numeric,text,text,text) to authenticated;
grant execute on function public.sg_my_withdrawals() to authenticated;
grant execute on function public.sg_customer_community() to authenticated;
grant execute on function public.sg_public_extra_settings() to anon,authenticated;
grant execute on function public.sg_admin_list_orders() to authenticated;
grant execute on function public.sg_admin_verify_payment(text,boolean,text) to authenticated;
grant execute on function public.sg_admin_send_access(text,text,text,text,timestamptz) to authenticated;
grant execute on function public.sg_admin_list_withdrawals() to authenticated;
grant execute on function public.sg_admin_finish_withdraw(bigint,boolean,text,text) to authenticated;
grant execute on function public.sg_admin_save_flow_settings(text,bigint,text,text) to authenticated;
grant execute on function public.sg_admin_get_flow_settings() to authenticated;
grant execute on function public.sg_owner_affiliate_summary() to authenticated;

notify pgrst,'reload schema';
