-- SOLUSI GENZ V14 - KATALOG DINAMIS + AFFILIATE SETELAH TRANSAKSI
-- Jalankan sekali di Supabase SQL Editor.

create table if not exists public.sg_catalog_products (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 category text not null default 'Digital',
 duration text,
 description text,
 price bigint not null check(price>=0),
 commission_amount numeric(14,2) not null default 0 check(commission_amount>=0),
 active boolean not null default true,
 sort_order int not null default 100,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.sg_catalog_products enable row level security;

insert into public.sg_catalog_products(name,category,duration,description,price,commission_amount,sort_order) values
('CapCut Premium','Video Editing',null,'Fitur premium untuk kebutuhan editing video dan konten kreatif.',75000,7500,10),
('Canva Pro','Design',null,'Akses desain premium untuk konten dan kebutuhan visual.',65000,6500,20),
('ChatGPT Plus','AI',null,'Layanan AI untuk belajar, kerja, ide, dan produktivitas.',99000,9900,30)
on conflict(name) do nothing;

create or replace function public.sg_catalog_list()
returns table(id uuid,name text,category text,duration text,description text,price bigint,commission_amount numeric,active boolean,sort_order int)
language sql security definer set search_path=public as $$
 select p.id,p.name,p.category,p.duration,p.description,p.price,p.commission_amount,p.active,p.sort_order
 from public.sg_catalog_products p where p.active=true order by p.sort_order,p.created_at;
$$;

create or replace function public.sg_admin_catalog_list()
returns table(id uuid,name text,category text,duration text,description text,price bigint,commission_amount numeric,active boolean,sort_order int)
language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 return query select p.id,p.name,p.category,p.duration,p.description,p.price,p.commission_amount,p.active,p.sort_order from public.sg_catalog_products p order by p.sort_order,p.created_at;
end $$;

create or replace function public.sg_admin_catalog_save(p_id uuid,p_name text,p_category text,p_duration text,p_description text,p_price bigint,p_commission_amount numeric,p_active boolean,p_sort_order int)
returns uuid language plpgsql security definer set search_path=public as $$ declare v_id uuid; begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;
 if p_id is null then
  insert into public.sg_catalog_products(name,category,duration,description,price,commission_amount,active,sort_order) values(trim(p_name),coalesce(nullif(trim(p_category),''),'Digital'),nullif(trim(p_duration),''),p_description,greatest(0,p_price),greatest(0,p_commission_amount),coalesce(p_active,true),coalesce(p_sort_order,100)) returning id into v_id;
 else
  update public.sg_catalog_products set name=trim(p_name),category=coalesce(nullif(trim(p_category),''),'Digital'),duration=nullif(trim(p_duration),''),description=p_description,price=greatest(0,p_price),commission_amount=greatest(0,p_commission_amount),active=coalesce(p_active,true),sort_order=coalesce(p_sort_order,100),updated_at=now() where id=p_id returning id into v_id;
 end if; return v_id; end $$;

create or replace function public.sg_admin_catalog_delete(p_id uuid) returns boolean language plpgsql security definer set search_path=public as $$ begin
 if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if; delete from public.sg_catalog_products where id=p_id; return found; end $$;

create or replace function public.sg_affiliate_eligibility(p_email text)
returns table(eligible boolean,valid_orders bigint) language sql security definer set search_path=public as $$
 select exists(select 1 from public.sg_orders o where lower(o.email)=lower(p_email) and o.status in ('Lunas','Dibayar','Diproses','Selesai')),
        (select count(*) from public.sg_orders o where lower(o.email)=lower(p_email) and o.status in ('Lunas','Dibayar','Diproses','Selesai'));
$$;

create table if not exists public.sg_store_settings_ext (id int primary key default 1,founder_name text not null default 'Dede Fahruroji',affiliate_enabled boolean not null default true,updated_at timestamptz not null default now());
insert into public.sg_store_settings_ext(id,founder_name) values(1,'Dede Fahruroji') on conflict(id) do update set founder_name='Dede Fahruroji';
create or replace function public.sg_public_extra_settings() returns table(founder_name text,affiliate_enabled boolean) language sql security definer set search_path=public as $$ select founder_name,affiliate_enabled from public.sg_store_settings_ext where id=1; $$;
create or replace function public.sg_admin_save_extra_settings(p_founder_name text,p_affiliate_enabled boolean) returns boolean language plpgsql security definer set search_path=public as $$ begin if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if; update public.sg_store_settings_ext set founder_name=coalesce(nullif(trim(p_founder_name),''),'Dede Fahruroji'),affiliate_enabled=coalesce(p_affiliate_enabled,true),updated_at=now() where id=1; return true; end $$;

-- Referral hanya sah jika pemilik kode sudah pernah memiliki transaksi valid.
create or replace function public.sg_affiliate_attach_referral(p_buyer_email text,p_buyer_user_id uuid,p_referral_code text)
returns boolean language plpgsql security definer set search_path=public as $$ declare aff text; begin
 if p_referral_code is null or trim(p_referral_code)='' then return false; end if;
 select a.email into aff from public.sg_affiliates a where a.referral_code=upper(trim(p_referral_code)) and exists(select 1 from public.sg_orders o where lower(o.email)=lower(a.email) and o.status in ('Lunas','Dibayar','Diproses','Selesai')) limit 1;
 if aff is null or lower(p_buyer_email)=lower(aff) then return false; end if;
 insert into public.sg_referrals(buyer_user_id,buyer_email,affiliate_email,referral_code) values(p_buyer_user_id,lower(p_buyer_email),aff,upper(trim(p_referral_code))) on conflict(buyer_email) do nothing; return true;
end $$;

-- Komisi fixed mengikuti katalog produk saat order menjadi Lunas.
create or replace function public.sg_apply_affiliate_commission_on_paid() returns trigger language plpgsql security definer set search_path=public as $$
declare v_affiliate_email text; v_commission numeric:=0; begin
 if lower(coalesce(new.status,'')) <> 'lunas' then return new; end if;
 select r.affiliate_email into v_affiliate_email from public.sg_referrals r where lower(r.buyer_email)=lower(new.email) limit 1;
 if v_affiliate_email is null then return new; end if;
 select coalesce(p.commission_amount,0) into v_commission from public.sg_catalog_products p where lower(p.name)=lower(new.product_name) limit 1;
 v_commission:=coalesce(v_commission,round(coalesce(new.price,0)::numeric*0.10,2));
 insert into public.sg_affiliate_commission_ledger(invoice,affiliate_email,buyer_email,order_amount,commission_rate,commission_amount,status,created_at) values(new.invoice,v_affiliate_email,lower(new.email),new.price,0,v_commission,'tercatat',now())
 on conflict(invoice) do update set affiliate_email=excluded.affiliate_email,buyer_email=excluded.buyer_email,order_amount=excluded.order_amount,commission_rate=0,commission_amount=excluded.commission_amount,status='tercatat'; return new; end $$;

drop trigger if exists trg_sg_affiliate_commission_on_paid on public.sg_orders;
create trigger trg_sg_affiliate_commission_on_paid after update of status on public.sg_orders for each row when(lower(coalesce(new.status,''))='lunas' and lower(coalesce(old.status,''))<>'lunas') execute function public.sg_apply_affiliate_commission_on_paid();

revoke all on function public.sg_catalog_list() from public; grant execute on function public.sg_catalog_list() to anon,authenticated;
revoke all on function public.sg_admin_catalog_list() from public; grant execute on function public.sg_admin_catalog_list() to authenticated;
revoke all on function public.sg_admin_catalog_save(uuid,text,text,text,text,bigint,numeric,boolean,int) from public; grant execute on function public.sg_admin_catalog_save(uuid,text,text,text,text,bigint,numeric,boolean,int) to authenticated;
revoke all on function public.sg_admin_catalog_delete(uuid) from public; grant execute on function public.sg_admin_catalog_delete(uuid) to authenticated;
revoke all on function public.sg_affiliate_eligibility(text) from public; grant execute on function public.sg_affiliate_eligibility(text) to authenticated;
revoke all on function public.sg_admin_save_extra_settings(text,boolean) from public; grant execute on function public.sg_admin_save_extra_settings(text,boolean) to authenticated;
grant execute on function public.sg_public_extra_settings() to anon,authenticated;
notify pgrst,'reload schema';
