-- SOLUSI GENZ REVAMP OWNER + AFFILIATE
-- Jalankan SEKALI di Supabase SQL Editor setelah backup.
-- Tidak menyimpan uang di website. Tabel commission_ledger hanya mencatat hak komisi.

create table if not exists public.sg_store_settings_ext (
  id int primary key default 1,
  affiliate_rate numeric(5,2) not null default 10,
  affiliate_enabled boolean not null default true,
  founder_name text not null default 'Difa Al Azizi',
  sourcing_name text not null default 'Difa Al Azizi',
  hidden_customer_emails text[] not null default '{}',
  updated_at timestamptz not null default now()
);
insert into public.sg_store_settings_ext(id) values(1) on conflict (id) do nothing;

create table if not exists public.sg_affiliates (
  user_id uuid,
  email text primary key,
  referral_code text unique not null,
  created_at timestamptz not null default now()
);
create table if not exists public.sg_referrals (
  buyer_user_id uuid,
  buyer_email text primary key,
  affiliate_email text not null references public.sg_affiliates(email) on delete cascade,
  referral_code text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.sg_affiliate_commission_ledger (
  id bigint generated always as identity primary key,
  invoice text unique not null,
  affiliate_email text not null references public.sg_affiliates(email) on delete cascade,
  buyer_email text,
  order_amount numeric(14,2) not null default 0,
  commission_rate numeric(5,2) not null default 0,
  commission_amount numeric(14,2) not null default 0,
  status text not null default 'tercatat',
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

alter table public.sg_store_settings_ext enable row level security;
alter table public.sg_affiliates enable row level security;
alter table public.sg_referrals enable row level security;
alter table public.sg_affiliate_commission_ledger enable row level security;

-- Helper: deterministic referral code from email. User can share link even before affiliate table exists.
create or replace function public.sg_make_referral_code(p_email text)
returns text language sql immutable as $$
  select upper(substr(md5(lower(coalesce(p_email,''))),1,8));
$$;

create or replace function public.sg_affiliate_register(p_email text, p_user_id uuid default null)
returns text language plpgsql security definer set search_path=public as $$
declare c text;
begin
  if p_email is null or trim(p_email)='' then return null; end if;
  c:=public.sg_make_referral_code(p_email);
  insert into public.sg_affiliates(user_id,email,referral_code)
  values(p_user_id,lower(p_email),c)
  on conflict(email) do update set user_id=coalesce(excluded.user_id,sg_affiliates.user_id);
  return c;
end $$;

create or replace function public.sg_affiliate_attach_referral(p_buyer_email text,p_buyer_user_id uuid,p_referral_code text)
returns boolean language plpgsql security definer set search_path=public as $$
declare aff text;
begin
  if p_referral_code is null or trim(p_referral_code)='' then return false; end if;
  select email into aff from public.sg_affiliates where referral_code=upper(trim(p_referral_code));
  if aff is null then return false; end if;
  if lower(p_buyer_email)=lower(aff) then return false; end if;
  insert into public.sg_referrals(buyer_user_id,buyer_email,affiliate_email,referral_code)
  values(p_buyer_user_id,lower(p_buyer_email),aff,upper(trim(p_referral_code)))
  on conflict(buyer_email) do nothing; -- repeat order keeps original recruiter
  return true;
end $$;

-- Called after an order has been created.
-- IMPORTANT: assumes existing order list RPC returns invoice, email, price, status.
create or replace function public.sg_affiliate_attach_order(p_invoice text,p_buyer_user_id uuid default null,p_buyer_email text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare aff text; rate numeric; amount numeric;
begin
  select affiliate_email into aff from public.sg_referrals where buyer_email=lower(p_buyer_email);
  if aff is null then return false; end if;
  select affiliate_rate into rate from public.sg_store_settings_ext where id=1;
  -- Resolve order amount using your existing admin order RPC is not possible inside SQL.
  -- Start ledger at 0; Owner status function below can fill it when order is paid if orders table is known.
  amount:=0;
  insert into public.sg_affiliate_commission_ledger(invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount)
  values(p_invoice,aff,lower(p_buyer_email),amount,rate,round(amount*rate/100,2))
  on conflict(invoice) do nothing;
  return true;
end $$;

-- Affiliate dashboard. Uses authenticated email supplied by frontend and registers affiliate automatically.
create or replace function public.sg_affiliate_me(p_email text)
returns table(referral_code text,total_referrals bigint,total_transactions bigint,total_commission numeric,paid_commission numeric,commission_rate numeric)
language plpgsql security definer set search_path=public as $$
declare c text;
begin
  c:=public.sg_affiliate_register(lower(p_email),auth.uid());
  return query
  select c,
    (select count(*) from public.sg_referrals r where r.affiliate_email=lower(p_email)),
    (select count(*) from public.sg_affiliate_commission_ledger l where l.affiliate_email=lower(p_email)),
    coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=lower(p_email)),0),
    coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=lower(p_email) and l.status='dibayar'),0),
    (select affiliate_rate from public.sg_store_settings_ext where id=1);
end $$;

create or replace function public.sg_affiliate_commissions(p_email text)
returns table(invoice text,buyer_email text,order_amount numeric,commission_amount numeric,status text,created_at timestamptz)
language sql security definer set search_path=public as $$
 select invoice,buyer_email,order_amount,commission_amount,status,created_at
 from public.sg_affiliate_commission_ledger where affiliate_email=lower(p_email) order by created_at desc;
$$;

create or replace function public.sg_owner_affiliate_summary()
returns table(affiliate_email text,referral_code text,total_referrals bigint,total_transactions bigint,total_commission numeric,paid_commission numeric)
language sql security definer set search_path=public as $$
 select a.email,a.referral_code,
   (select count(*) from public.sg_referrals r where r.affiliate_email=a.email),
   (select count(*) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email),
   coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email),0),
   coalesce((select sum(l.commission_amount) from public.sg_affiliate_commission_ledger l where l.affiliate_email=a.email and l.status='dibayar'),0)
 from public.sg_affiliates a order by a.created_at desc;
$$;

create or replace function public.sg_owner_set_affiliate_program(p_rate numeric,p_enabled boolean)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.sg_store_settings_ext set affiliate_rate=greatest(0,least(100,p_rate)),affiliate_enabled=p_enabled,updated_at=now() where id=1;
 return true;
end $$;

create or replace function public.sg_admin_hide_customer(p_email text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 update public.sg_store_settings_ext
 set hidden_customer_emails=array(select distinct x from unnest(hidden_customer_emails || lower(p_email)) x),updated_at=now()
 where id=1;
 return true;
end $$;

-- Extend public/admin store settings without breaking old V13.2 settings table.
-- These wrappers assume existing functions sg_public_store_settings / sg_admin_get_store_settings still exist.

create or replace function public.sg_owner_save_store_settings(
 p_hero_title text,p_hero_subtitle text,p_promo_title text,p_promo_discount text,
 p_reward_per_purchase text,p_reward_note text,p_company_profile text,p_about_title text,p_about_text text,
 p_support_whatsapp text,p_logo_data_url text,p_affiliate_rate text,p_founder_name text,p_sourcing_name text)
returns boolean language plpgsql security definer set search_path=public as $$
begin
 perform public.sg_admin_save_store_settings(
   p_hero_title,p_hero_subtitle,p_promo_title,p_promo_discount,p_reward_per_purchase,p_reward_note,
   p_company_profile,p_about_title,p_about_text,p_support_whatsapp,p_logo_data_url
 );
 update public.sg_store_settings_ext set affiliate_rate=coalesce(nullif(p_affiliate_rate,'')::numeric,10),
 founder_name=coalesce(nullif(p_founder_name,''),'Difa Al Azizi'),
 sourcing_name=coalesce(nullif(p_sourcing_name,''),'Difa Al Azizi'),updated_at=now() where id=1;
 return true;
end $$;

-- IMPORTANT:
-- For automatic REAL commission values, update your existing order-status RPC so when status becomes
-- Lunas/Diproses/Selesai it updates sg_affiliate_commission_ledger.order_amount and commission_amount
-- from the real order price. The frontend package already supports the ledger UI.
