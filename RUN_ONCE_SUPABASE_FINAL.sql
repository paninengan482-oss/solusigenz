-- SOLUSI GENZ BUSINESS FINAL — 27 AUG 2026
-- WAJIB dijalankan SEKALI di Supabase SQL Editor setelah commit file website.
-- Menambahkan: owner whitelist, media website editable, foto produk editable.

begin;

-- Owner hanya email ini.
create or replace function public.sg_is_admin()
returns boolean language sql stable security definer set search_path=public
as $$
  select lower(coalesce(auth.jwt()->>'email','')) = 'paninengan482@gmail.com';
$$;

-- Media website yang bisa diganti dari Admin.
create table if not exists public.sg_store_settings_ext (
  id int primary key default 1,
  founder_name text not null default 'Difa Al Azizi',
  affiliate_enabled boolean not null default true,
  updated_at timestamptz not null default now()
);
alter table public.sg_store_settings_ext add column if not exists hero_media_data_url text;
alter table public.sg_store_settings_ext add column if not exists transaction_media_data_url text;
alter table public.sg_store_settings_ext add column if not exists referral_media_data_url text;
alter table public.sg_store_settings_ext add column if not exists support_media_data_url text;
insert into public.sg_store_settings_ext(id,founder_name,affiliate_enabled) values(1,'Difa Al Azizi',true)
on conflict(id) do update set founder_name=coalesce(nullif(public.sg_store_settings_ext.founder_name,''),'Difa Al Azizi');

drop function if exists public.sg_public_extra_settings();
create function public.sg_public_extra_settings()
returns table(
 founder_name text,
 affiliate_enabled boolean,
 hero_media_data_url text,
 transaction_media_data_url text,
 referral_media_data_url text,
 support_media_data_url text
)
language sql security definer set search_path=public as $$
 select s.founder_name,s.affiliate_enabled,s.hero_media_data_url,s.transaction_media_data_url,s.referral_media_data_url,s.support_media_data_url
 from public.sg_store_settings_ext s where s.id=1;
$$;

create or replace function public.sg_admin_save_extra_settings_v2(
 p_founder_name text,
 p_affiliate_enabled boolean,
 p_hero_media_data_url text,
 p_transaction_media_data_url text,
 p_referral_media_data_url text,
 p_support_media_data_url text
) returns boolean language plpgsql security definer set search_path=public as $$
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 insert into public.sg_store_settings_ext(id,founder_name,affiliate_enabled,hero_media_data_url,transaction_media_data_url,referral_media_data_url,support_media_data_url,updated_at)
 values(1,coalesce(nullif(trim(p_founder_name),''),'Difa Al Azizi'),coalesce(p_affiliate_enabled,true),p_hero_media_data_url,p_transaction_media_data_url,p_referral_media_data_url,p_support_media_data_url,now())
 on conflict(id) do update set
 founder_name=excluded.founder_name,affiliate_enabled=excluded.affiliate_enabled,
 hero_media_data_url=excluded.hero_media_data_url,transaction_media_data_url=excluded.transaction_media_data_url,
 referral_media_data_url=excluded.referral_media_data_url,support_media_data_url=excluded.support_media_data_url,updated_at=now();
 return true;
end $$;

-- Foto produk editable dari Admin.
alter table public.sg_catalog_products add column if not exists image_data_url text;

drop function if exists public.sg_catalog_list();
create function public.sg_catalog_list()
returns table(id uuid,name text,category text,duration text,description text,price bigint,commission_amount numeric,active boolean,sort_order int,image_data_url text)
language sql security definer set search_path=public as $$
 select p.id,p.name,p.category,p.duration,p.description,p.price,p.commission_amount,p.active,p.sort_order,p.image_data_url
 from public.sg_catalog_products p where p.active=true order by p.sort_order,p.created_at;
$$;

drop function if exists public.sg_admin_catalog_list();
create function public.sg_admin_catalog_list()
returns table(id uuid,name text,category text,duration text,description text,price bigint,commission_amount numeric,active boolean,sort_order int,image_data_url text)
language plpgsql security definer set search_path=public as $$
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select p.id,p.name,p.category,p.duration,p.description,p.price,p.commission_amount,p.active,p.sort_order,p.image_data_url
 from public.sg_catalog_products p order by p.sort_order,p.created_at;
end $$;

create or replace function public.sg_admin_catalog_save_v2(
 p_id uuid,p_name text,p_category text,p_duration text,p_description text,p_price bigint,
 p_commission_amount numeric,p_active boolean,p_sort_order int,p_image_data_url text
) returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 if p_id is null then
  insert into public.sg_catalog_products(name,category,duration,description,price,commission_amount,active,sort_order,image_data_url)
  values(trim(p_name),coalesce(nullif(trim(p_category),''),'Digital'),nullif(trim(p_duration),''),p_description,greatest(0,p_price),greatest(0,p_commission_amount),coalesce(p_active,true),coalesce(p_sort_order,100),p_image_data_url)
  returning id into v_id;
 else
  update public.sg_catalog_products set
   name=trim(p_name),category=coalesce(nullif(trim(p_category),''),'Digital'),duration=nullif(trim(p_duration),''),
   description=p_description,price=greatest(0,p_price),commission_amount=greatest(0,p_commission_amount),
   active=coalesce(p_active,true),sort_order=coalesce(p_sort_order,100),image_data_url=p_image_data_url,updated_at=now()
  where id=p_id returning id into v_id;
 end if;
 return v_id;
end $$;

revoke all on function public.sg_public_extra_settings() from public;
grant execute on function public.sg_public_extra_settings() to anon,authenticated;
revoke all on function public.sg_admin_save_extra_settings_v2(text,boolean,text,text,text,text) from public;
grant execute on function public.sg_admin_save_extra_settings_v2(text,boolean,text,text,text,text) to authenticated;
revoke all on function public.sg_catalog_list() from public;
grant execute on function public.sg_catalog_list() to anon,authenticated;
revoke all on function public.sg_admin_catalog_list() from public;
grant execute on function public.sg_admin_catalog_list() to authenticated;
revoke all on function public.sg_admin_catalog_save_v2(uuid,text,text,text,text,bigint,numeric,boolean,int,text) from public;
grant execute on function public.sg_admin_catalog_save_v2(uuid,text,text,text,text,bigint,numeric,boolean,int,text) to authenticated;

notify pgrst,'reload schema';
commit;
