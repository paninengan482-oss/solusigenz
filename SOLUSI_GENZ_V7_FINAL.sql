-- SOLUSI GENZ V7 FINAL CLEAR
-- Jalankan SELURUH file ini SEKALI di Supabase > SQL Editor.
-- Aman dijalankan di project yang sudah memiliki data Solusi Genz.

-- 1) Pastikan kolom yang diperlukan tersedia dan tidak menghalangi checkout.
alter table public.sg_orders add column if not exists customer_name text;
alter table public.sg_orders add column if not exists whatsapp text;
alter table public.sg_orders add column if not exists email text;
alter table public.sg_orders add column if not exists payment_method text;
alter table public.sg_orders add column if not exists created_at timestamptz default now();

do $$
begin
  begin
    alter table public.sg_orders alter column customer_id drop not null;
  exception when undefined_column then null;
  end;
  begin
    alter table public.sg_orders alter column product_id drop not null;
  exception when undefined_column then null;
  end;
end $$;

-- 2) Rapikan aturan status agar semua tahap toko diperbolehkan.
do $$
declare r record;
begin
  for r in
    select conname
    from pg_constraint
    where conrelid='public.sg_orders'::regclass
      and contype='c'
      and pg_get_constraintdef(oid) ilike '%status%'
  loop
    execute format('alter table public.sg_orders drop constraint %I',r.conname);
  end loop;
end $$;

alter table public.sg_orders
add constraint sg_orders_status_check
check (status in (
  'pending','Menunggu Verifikasi','Lunas','Dibayar','Diproses','Selesai','Dibatalkan'
));

-- 3) Admin.
create table if not exists public.sg_admins (
  email text primary key,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.sg_admins add column if not exists active boolean not null default true;
alter table public.sg_admins enable row level security;

insert into public.sg_admins(email,active)
values ('paninengan482@gmail.com',true)
on conflict (email) do update set active=true;

create or replace function public.sg_is_admin()
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.sg_admins a
    where lower(a.email)=lower(coalesce(auth.jwt()->>'email',''))
      and a.active=true
  );
$$;

-- 4) Checkout pelanggan.
create or replace function public.sg_create_order(
  p_invoice text,
  p_product_name text,
  p_price bigint,
  p_customer_name text,
  p_whatsapp text,
  p_email text,
  p_payment_method text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_product_id uuid;
  v_order_id uuid;
begin
  select id into v_product_id
  from public.sg_products
  where lower(name)=lower(p_product_name)
  limit 1;

  insert into public.sg_orders(
    invoice,customer_id,product_id,product_name,price,status,
    customer_name,whatsapp,email,payment_method,created_at
  ) values (
    p_invoice,null,v_product_id,p_product_name,p_price,'pending',
    p_customer_name,p_whatsapp,p_email,p_payment_method,now()
  ) returning id into v_order_id;

  return jsonb_build_object('id',v_order_id,'invoice',p_invoice,'status','pending');
end;
$$;

-- 5) Cek status pelanggan.
create or replace function public.sg_check_order(p_invoice text)
returns table(
  invoice text,
  product_name text,
  price bigint,
  status text,
  customer_name text,
  payment_method text,
  created_at timestamptz
)
language sql
security definer
set search_path=public
as $$
  select o.invoice,o.product_name,o.price,o.status,o.customer_name,o.payment_method,o.created_at
  from public.sg_orders o
  where o.invoice=p_invoice
  limit 1;
$$;

-- 6) Pelanggan menekan "Saya Sudah Bayar".
create or replace function public.sg_submit_payment(p_invoice text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  update public.sg_orders
  set status='Menunggu Verifikasi'
  where invoice=p_invoice
    and status in ('pending');

  if not found then
    if exists(select 1 from public.sg_orders where invoice=p_invoice and status='Menunggu Verifikasi') then
      return jsonb_build_object('invoice',p_invoice,'status','Menunggu Verifikasi');
    end if;
    raise exception 'Invoice tidak ditemukan atau sudah diproses';
  end if;

  return jsonb_build_object('invoice',p_invoice,'status','Menunggu Verifikasi');
end;
$$;

-- 7) Dashboard admin membaca seluruh pesanan.
create or replace function public.sg_admin_list_orders()
returns table(
  invoice text,
  customer_name text,
  whatsapp text,
  email text,
  product_name text,
  price bigint,
  payment_method text,
  status text,
  created_at timestamptz
)
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then
    raise exception 'Akses admin ditolak';
  end if;

  return query
  select o.invoice,o.customer_name,o.whatsapp,o.email,o.product_name,
         o.price,o.payment_method,o.status,o.created_at
  from public.sg_orders o
  order by o.created_at desc nulls last;
end;
$$;

-- 8) Dashboard admin mengubah status.
create or replace function public.sg_admin_set_status(p_invoice text,p_status text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then
    raise exception 'Akses admin ditolak';
  end if;

  if p_status not in ('pending','Menunggu Verifikasi','Lunas','Dibayar','Diproses','Selesai','Dibatalkan') then
    raise exception 'Status tidak valid';
  end if;

  update public.sg_orders
  set status=p_status
  where invoice=p_invoice;

  if not found then
    raise exception 'Invoice tidak ditemukan';
  end if;

  return jsonb_build_object('invoice',p_invoice,'status',p_status);
end;
$$;

-- Alias kompatibilitas untuk versi lama jika masih terbuka di browser.
create or replace function public.sg_admin_update_order_status(p_invoice text,p_status text)
returns jsonb
language sql
security definer
set search_path=public
as $$
  select public.sg_admin_set_status(p_invoice,p_status);
$$;

-- 9) Hak akses RPC.
revoke all on function public.sg_create_order(text,text,bigint,text,text,text,text) from public;
revoke all on function public.sg_check_order(text) from public;
revoke all on function public.sg_submit_payment(text) from public;
revoke all on function public.sg_admin_list_orders() from public;
revoke all on function public.sg_admin_set_status(text,text) from public;
revoke all on function public.sg_admin_update_order_status(text,text) from public;

 grant execute on function public.sg_create_order(text,text,bigint,text,text,text,text) to anon,authenticated;
 grant execute on function public.sg_check_order(text) to anon,authenticated;
 grant execute on function public.sg_submit_payment(text) to anon,authenticated;
 grant execute on function public.sg_is_admin() to authenticated;
 grant execute on function public.sg_admin_list_orders() to authenticated;
 grant execute on function public.sg_admin_set_status(text,text) to authenticated;
 grant execute on function public.sg_admin_update_order_status(text,text) to authenticated;

notify pgrst,'reload schema';

-- 10) Tes ringan: hasil harus satu baris admin aktif.
select email,active from public.sg_admins where lower(email)=lower('paninengan482@gmail.com');
