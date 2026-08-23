
-- SOLUSI GENZ V13: owner-editable store settings
create table if not exists public.sg_store_settings (
  id integer primary key,
  hero_title text not null default 'Langganan Digital Lebih Hemat di Solusi Genz!',
  hero_subtitle text not null default 'Harga terbaik • Proses ringkas • Aman & terpercaya',
  promo_title text not null default 'Promo Spesial Solusi Genz',
  promo_discount text not null default '30',
  reward_per_purchase text not null default '1',
  reward_note text not null default 'Kumpulkan poin dari setiap pembelian dan tukarkan dengan hadiah dari Solusi Genz.',
  company_profile text not null default 'Solusi Genz adalah platform layanan digital generasi sekarang.',
  support_whatsapp text not null default '',
  updated_at timestamptz not null default now()
);
insert into public.sg_store_settings(id) values (1) on conflict (id) do nothing;
alter table public.sg_store_settings enable row level security;

drop policy if exists "sg settings public read" on public.sg_store_settings;
create policy "sg settings public read" on public.sg_store_settings for select using (true);

drop policy if exists "sg settings admin update" on public.sg_store_settings;
create policy "sg settings admin update" on public.sg_store_settings
for update using (
  exists(select 1 from public.sg_admins a where lower(a.email)=lower(auth.jwt()->>'email') and a.active=true)
) with check (
  exists(select 1 from public.sg_admins a where lower(a.email)=lower(auth.jwt()->>'email') and a.active=true)
);

drop policy if exists "sg settings admin insert" on public.sg_store_settings;
create policy "sg settings admin insert" on public.sg_store_settings
for insert with check (
  exists(select 1 from public.sg_admins a where lower(a.email)=lower(auth.jwt()->>'email') and a.active=true)
);

grant select on public.sg_store_settings to anon, authenticated;
grant insert, update on public.sg_store_settings to authenticated;
notify pgrst, 'reload schema';
