
-- SOLUSI GENZ V13.2 FINAL SETTINGS + LOGO + TENTANG KAMI
-- Jalankan SEKALI di Supabase > SQL Editor > New Query > Run.

create table if not exists public.sg_store_settings (
  id integer primary key default 1,
  hero_title text not null default 'Langganan Digital Lebih Hemat di Solusi Genz!',
  hero_subtitle text not null default 'Harga terbaik • Proses ringkas • Aman & terpercaya',
  promo_title text not null default 'Promo Spesial Solusi Genz',
  promo_discount text not null default '30',
  reward_per_purchase text not null default '1',
  reward_note text not null default 'Kumpulkan poin dari setiap pembelian dan tukarkan dengan hadiah dari Solusi Genz.',
  company_profile text not null default 'Solusi Genz adalah platform layanan digital generasi sekarang.',
  about_title text not null default 'Tentang Kami',
  about_text text not null default 'Solusi Genz hadir untuk membantu generasi digital mendapatkan layanan yang praktis, mudah dipahami, dan nyaman digunakan.',
  support_whatsapp text not null default '',
  logo_data_url text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.sg_store_settings add column if not exists about_title text not null default 'Tentang Kami';
alter table public.sg_store_settings add column if not exists about_text text not null default 'Solusi Genz hadir untuk membantu generasi digital mendapatkan layanan yang praktis, mudah dipahami, dan nyaman digunakan.';
alter table public.sg_store_settings add column if not exists logo_data_url text not null default '';
alter table public.sg_store_settings add column if not exists support_whatsapp text not null default '';

insert into public.sg_store_settings(id) values(1)
on conflict (id) do nothing;

create or replace function public.sg_public_store_settings()
returns setof public.sg_store_settings
language sql
security definer
set search_path=public
as $$
  select * from public.sg_store_settings where id=1;
$$;

create or replace function public.sg_admin_get_store_settings()
returns setof public.sg_store_settings
language plpgsql
security definer
set search_path=public
as $$
begin
  if not exists (
    select 1 from public.sg_admins a
    where lower(a.email)=lower(auth.jwt()->>'email')
      and a.active=true
  ) then
    raise exception 'Akses admin ditolak';
  end if;
  return query select * from public.sg_store_settings where id=1;
end;
$$;

create or replace function public.sg_admin_save_store_settings(
  p_hero_title text,
  p_hero_subtitle text,
  p_promo_title text,
  p_promo_discount text,
  p_reward_per_purchase text,
  p_reward_note text,
  p_company_profile text,
  p_about_title text,
  p_about_text text,
  p_support_whatsapp text,
  p_logo_data_url text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  if not exists (
    select 1 from public.sg_admins a
    where lower(a.email)=lower(auth.jwt()->>'email')
      and a.active=true
  ) then
    raise exception 'Akses admin ditolak';
  end if;

  insert into public.sg_store_settings(
    id,hero_title,hero_subtitle,promo_title,promo_discount,
    reward_per_purchase,reward_note,company_profile,about_title,
    about_text,support_whatsapp,logo_data_url,updated_at
  )
  values(
    1,p_hero_title,p_hero_subtitle,p_promo_title,p_promo_discount,
    p_reward_per_purchase,p_reward_note,p_company_profile,p_about_title,
    p_about_text,p_support_whatsapp,p_logo_data_url,now()
  )
  on conflict(id) do update set
    hero_title=excluded.hero_title,
    hero_subtitle=excluded.hero_subtitle,
    promo_title=excluded.promo_title,
    promo_discount=excluded.promo_discount,
    reward_per_purchase=excluded.reward_per_purchase,
    reward_note=excluded.reward_note,
    company_profile=excluded.company_profile,
    about_title=excluded.about_title,
    about_text=excluded.about_text,
    support_whatsapp=excluded.support_whatsapp,
    logo_data_url=excluded.logo_data_url,
    updated_at=now();

  return jsonb_build_object('success',true);
end;
$$;

revoke all on function public.sg_public_store_settings() from public;
grant execute on function public.sg_public_store_settings() to anon,authenticated;

revoke all on function public.sg_admin_get_store_settings() from public;
grant execute on function public.sg_admin_get_store_settings() to authenticated;

revoke all on function public.sg_admin_save_store_settings(text,text,text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.sg_admin_save_store_settings(text,text,text,text,text,text,text,text,text,text,text) to authenticated;

notify pgrst,'reload schema';
