-- SOLUSI GENZ - FINAL AFFILIATE ENGINE REPAIR
-- Idempotent. Safe to run more than once.

create or replace function public.sg_commission_for_order(p_product_name text, p_price numeric default 0)
returns numeric
language plpgsql
stable
set search_path=public
as $$
declare v numeric;
begin
  select p.commission_amount into v
  from public.sg_catalog_products p
  where lower(trim(p.name))=lower(trim(coalesce(p_product_name,'')))
  limit 1;
  if coalesce(v,0)>0 then return v; end if;
  if lower(coalesce(p_product_name,'')) ~ '(1\\s*tahun|tahun)' then return 20000; end if;
  if lower(coalesce(p_product_name,'')) ~ '(1\\s*bulan|bulan)' then return 10000; end if;
  if lower(coalesce(p_product_name,'')) ~ '(1\\s*minggu|minggu)' then return 5000; end if;
  if lower(coalesce(p_product_name,'')) ~ '(1\\s*hari|2\\s*hari|3\\s*hari|1\\s*-\\s*3\\s*hari)' then return 2000; end if;
  return 0;
end $$;

create or replace function public.sg_affiliate_sync_self(p_email text)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_uid uuid:=auth.uid();
  v_email text;
  v_ref text;
  v_aff text;
begin
  if v_uid is null then return false; end if;
  select lower(trim(u.email)), upper(trim(coalesce(u.raw_user_meta_data->>'referral_code','')))
    into v_email,v_ref
  from auth.users u where u.id=v_uid;
  if v_email is null or v_email<>lower(trim(coalesce(p_email,''))) then return false; end if;

  if v_ref<>'' then
    select lower(a.email) into v_aff from public.sg_affiliates a
    where upper(trim(a.referral_code))=v_ref limit 1;
    if v_aff is not null and v_aff<>v_email then
      insert into public.sg_referrals(buyer_user_id,buyer_email,affiliate_email,referral_code)
      values(v_uid,v_email,v_aff,v_ref)
      on conflict(buyer_email) do update set
        buyer_user_id=coalesce(public.sg_referrals.buyer_user_id,excluded.buyer_user_id);
    end if;
  end if;

  insert into public.sg_affiliate_commission_ledger
    (invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount,status,created_at)
  select o.invoice,r.affiliate_email,v_email,coalesce(o.price,0),0,
         public.sg_commission_for_order(o.product_name,o.price),
         'tercatat',coalesce(o.paid_at,o.created_at,now())
  from public.sg_orders o
  join public.sg_referrals r on lower(trim(r.buyer_email))=v_email
  where lower(trim(o.email))=v_email
    and lower(trim(coalesce(o.status,''))) in ('lunas','dibayar','diproses','selesai')
  on conflict(invoice) do update set
    affiliate_email=excluded.affiliate_email,
    buyer_email=excluded.buyer_email,
    order_amount=excluded.order_amount,
    commission_amount=excluded.commission_amount;
  return true;
end $$;

grant execute on function public.sg_affiliate_sync_self(text) to authenticated;

create or replace function public.sg_apply_affiliate_commission_on_paid()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
declare v_aff text; v_comm numeric;
begin
  if lower(coalesce(new.status,'')) not in ('lunas','dibayar','diproses','selesai') then return new; end if;
  select r.affiliate_email into v_aff from public.sg_referrals r
  where lower(trim(r.buyer_email))=lower(trim(new.email)) limit 1;
  if v_aff is null then return new; end if;
  v_comm:=public.sg_commission_for_order(new.product_name,new.price);
  insert into public.sg_affiliate_commission_ledger(invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount,status,created_at)
  values(new.invoice,v_aff,lower(trim(new.email)),coalesce(new.price,0),0,v_comm,'tercatat',coalesce(new.paid_at,now()))
  on conflict(invoice) do update set affiliate_email=excluded.affiliate_email,buyer_email=excluded.buyer_email,order_amount=excluded.order_amount,commission_amount=excluded.commission_amount;
  return new;
end $$;

drop trigger if exists trg_sg_affiliate_commission_on_paid on public.sg_orders;
create trigger trg_sg_affiliate_commission_on_paid
  after insert or update of status on public.sg_orders
  for each row
  when (lower(coalesce(new.status,'')) in ('lunas','dibayar','diproses','selesai'))
  execute function public.sg_apply_affiliate_commission_on_paid();

-- Backfill all existing referral users from auth metadata.
insert into public.sg_referrals(buyer_user_id,buyer_email,affiliate_email,referral_code)
select u.id,lower(trim(u.email)),lower(a.email),upper(trim(a.referral_code))
from auth.users u
join public.sg_affiliates a
  on upper(trim(a.referral_code))=upper(trim(coalesce(u.raw_user_meta_data->>'referral_code','')))
where trim(coalesce(u.email,''))<>'' and lower(trim(u.email))<>lower(a.email)
on conflict(buyer_email) do nothing;

-- Backfill all existing valid paid orders.
insert into public.sg_affiliate_commission_ledger(invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount,status,created_at)
select o.invoice,r.affiliate_email,lower(trim(o.email)),coalesce(o.price,0),0,
       public.sg_commission_for_order(o.product_name,o.price),
       'tercatat',coalesce(o.paid_at,o.created_at,now())
from public.sg_orders o
join public.sg_referrals r on lower(trim(r.buyer_email))=lower(trim(o.email))
where lower(trim(coalesce(o.status,''))) in ('lunas','dibayar','diproses','selesai')
on conflict(invoice) do update set
  affiliate_email=excluded.affiliate_email,
  buyer_email=excluded.buyer_email,
  order_amount=excluded.order_amount,
  commission_amount=excluded.commission_amount;

notify pgrst,'reload schema';
