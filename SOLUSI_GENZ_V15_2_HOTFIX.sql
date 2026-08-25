-- SOLUSI GENZ V15.2 HOTFIX
-- Perbaikan checkout + affiliate pada database yang berasal dari versi lama.

-- Checkout: izinkan struktur lama, namun simpan auth.uid() sebagai customer_id bila tersedia.
do $$
begin
  begin alter table public.sg_orders alter column customer_id drop not null; exception when undefined_column then null; end;
  begin alter table public.sg_orders alter column product_id drop not null; exception when undefined_column then null; end;
end $$;

create or replace function public.sg_create_order(
 p_invoice text,p_product_name text,p_price bigint,p_customer_name text,p_whatsapp text,p_email text,p_payment_method text
) returns jsonb language plpgsql security definer set search_path=public as $$
declare v_product_id uuid; v_order_id uuid; v_jwt_email text:=lower(coalesce(auth.jwt()->>'email',''));
begin
 if auth.uid() is null or v_jwt_email='' or v_jwt_email<>lower(trim(p_email)) then raise exception 'Harus login sebagai pemilik pesanan'; end if;
 select id into v_product_id from public.sg_products where lower(name)=lower(p_product_name) limit 1;
 insert into public.sg_orders(invoice,customer_id,product_id,product_name,price,status,customer_name,whatsapp,email,payment_method,created_at)
 values(p_invoice,auth.uid(),v_product_id,p_product_name,p_price,'Menunggu Pembayaran',p_customer_name,p_whatsapp,v_jwt_email,p_payment_method,now())
 returning id into v_order_id;
 return jsonb_build_object('id',v_order_id,'invoice',p_invoice,'status','Menunggu Pembayaran');
end $$;

-- Affiliate: buat data affiliate langsung dari akun yang sedang login.
drop function if exists public.sg_affiliate_me(text);
create or replace function public.sg_affiliate_me(p_email text default null)
returns table(referral_code text,total_referrals bigint,total_buyers bigint,total_transactions bigint,held_commission numeric,available_commission numeric,processing_commission numeric,total_commission numeric,paid_commission numeric)
language plpgsql security definer set search_path=public as $$
declare e text:=lower(coalesce(auth.jwt()->>'email','')); c text;
begin
 if auth.uid() is null or e='' then raise exception 'Harus login'; end if;
 if not exists(select 1 from public.sg_orders o where lower(o.email)=e and o.status in ('Diproses','Selesai','Lunas','Dibayar')) then
   raise exception 'Affiliate aktif setelah transaksi pertama valid';
 end if;
 c:=public.sg_make_referral_code(e);
 insert into public.sg_affiliates(user_id,email,referral_code,created_at)
 values(auth.uid(),e,c,now())
 on conflict(email) do update set user_id=auth.uid(), referral_code=coalesce(public.sg_affiliates.referral_code,excluded.referral_code);
 return query select c,
 (select count(*) from public.sg_referrals r where lower(r.affiliate_email)=e),
 (select count(distinct l.buyer_email) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e),
 (select count(*) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e and l.status='tertahan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e and l.status='tersedia'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e and l.status='diproses'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e and l.status<>'dibatalkan'),0),
 coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where lower(l.affiliate_email)=e and l.status='dibayar'),0);
end $$;

grant execute on function public.sg_create_order(text,text,bigint,text,text,text,text) to authenticated;
grant execute on function public.sg_affiliate_me(text) to authenticated;
notify pgrst,'reload schema';
