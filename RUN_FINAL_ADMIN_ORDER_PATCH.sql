-- =========================================================
-- SOLUSI GENZ — FINAL ADMIN + ORDER ENGINE PATCH
-- 27 AUG 2026
-- Jalankan SEKALI di Supabase SQL Editor setelah upload ZIP final.
-- =========================================================

begin;

-- Owner/admin utama
create or replace function public.sg_is_admin()
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select lower(coalesce(auth.jwt()->>'email','')) = 'paninengan482@gmail.com';
$$;

-- Pastikan kolom order lengkap
alter table public.sg_orders add column if not exists payment_proof_data_url text;
alter table public.sg_orders add column if not exists access_text text;
alter table public.sg_orders add column if not exists access_note text;
alter table public.sg_orders add column if not exists access_delivered_at timestamptz;

-- =========================================================
-- PELANGGAN: daftar pesanan sendiri otomatis
-- =========================================================
drop function if exists public.sg_my_orders_v4();

create function public.sg_my_orders_v4()
returns table(
  invoice text,
  product_name text,
  price bigint,
  customer_name text,
  email text,
  whatsapp text,
  payment_method text,
  status text,
  created_at timestamptz,
  payment_proof_data_url text,
  access_text text,
  access_note text,
  access_delivered_at timestamptz
)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
begin
  if v_email='' then raise exception 'Harus login'; end if;

  return query
  select
    o.invoice,o.product_name,o.price,o.customer_name,o.email,o.whatsapp,
    o.payment_method,o.status,o.created_at,o.payment_proof_data_url,
    o.access_text,o.access_note,o.access_delivered_at
  from public.sg_orders o
  where lower(o.email)=v_email
  order by o.created_at desc;
end;
$$;

-- =========================================================
-- PELANGGAN: upload bukti transfer
-- =========================================================
drop function if exists public.sg_submit_payment_v3(text,text);

create function public.sg_submit_payment_v3(
  p_invoice text,
  p_proof_data_url text
)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
begin
  if v_email='' then raise exception 'Harus login'; end if;
  if p_proof_data_url is null or length(p_proof_data_url)<30 then
    raise exception 'Bukti transfer wajib';
  end if;

  update public.sg_orders
     set payment_proof_data_url=p_proof_data_url,
         status='Menunggu Verifikasi'
   where upper(invoice)=upper(trim(p_invoice))
     and lower(email)=v_email
     and lower(coalesce(status,'')) not in ('selesai','berhasil');

  return found;
end;
$$;

-- =========================================================
-- ADMIN: list SEMUA pesanan
-- =========================================================
drop function if exists public.sg_admin_list_orders();

create function public.sg_admin_list_orders()
returns table(
  invoice text,
  customer_name text,
  email text,
  whatsapp text,
  product_name text,
  price bigint,
  payment_method text,
  status text,
  created_at timestamptz,
  payment_proof_data_url text,
  access_text text,
  access_note text,
  access_delivered_at timestamptz
)
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;

  return query
  select
    o.invoice,o.customer_name,o.email,o.whatsapp,o.product_name,o.price,
    o.payment_method,o.status,o.created_at,o.payment_proof_data_url,
    o.access_text,o.access_note,o.access_delivered_at
  from public.sg_orders o
  order by o.created_at desc;
end;
$$;

-- =========================================================
-- ADMIN: ubah status manual bila diperlukan
-- =========================================================
drop function if exists public.sg_admin_set_status(text,text);

create function public.sg_admin_set_status(
  p_invoice text,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;

  if p_status not in ('pending','Menunggu Verifikasi','Lunas','Diproses','Selesai','Berhasil','Dibatalkan') then
    raise exception 'Status tidak valid';
  end if;

  update public.sg_orders
     set status=p_status
   where upper(invoice)=upper(trim(p_invoice));

  return found;
end;
$$;

-- =========================================================
-- ADMIN: kirim akses = otomatis SELESAI
-- =========================================================
drop function if exists public.sg_admin_deliver_access(text,text,text,text);

create function public.sg_admin_deliver_access(
  p_invoice text,
  p_access_text text,
  p_access_note text,
  p_status text
)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;

  if nullif(trim(coalesce(p_access_text,'')),'') is null then
    raise exception 'Akses produk wajib diisi';
  end if;

  update public.sg_orders
     set access_text=trim(p_access_text),
         access_note=nullif(trim(coalesce(p_access_note,'')),''),
         access_delivered_at=now(),
         status='Selesai'
   where upper(invoice)=upper(trim(p_invoice));

  return found;
end;
$$;

-- =========================================================
-- ADMIN: summary dashboard / omzet
-- Omzet hanya pesanan yang benar-benar selesai.
-- =========================================================
drop function if exists public.sg_admin_sales_summary_v4();

create function public.sg_admin_sales_summary_v4()
returns table(
  total_orders bigint,
  waiting_verification bigint,
  processing_orders bigint,
  completed_orders bigint,
  omzet numeric
)
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.sg_is_admin() then raise exception 'Akses admin ditolak'; end if;

  return query
  select
    count(*)::bigint,
    count(*) filter (where lower(coalesce(o.status,''))='menunggu verifikasi')::bigint,
    count(*) filter (where lower(coalesce(o.status,''))='diproses')::bigint,
    count(*) filter (where lower(coalesce(o.status,'')) in ('selesai','berhasil'))::bigint,
    coalesce(sum(o.price) filter (
      where lower(coalesce(o.status,'')) in ('selesai','berhasil')
    ),0)::numeric
  from public.sg_orders o;
end;
$$;

-- Izin RPC
revoke all on function public.sg_my_orders_v4() from public;
grant execute on function public.sg_my_orders_v4() to authenticated;

revoke all on function public.sg_submit_payment_v3(text,text) from public;
grant execute on function public.sg_submit_payment_v3(text,text) to authenticated;

revoke all on function public.sg_admin_list_orders() from public;
grant execute on function public.sg_admin_list_orders() to authenticated;

revoke all on function public.sg_admin_set_status(text,text) from public;
grant execute on function public.sg_admin_set_status(text,text) to authenticated;

revoke all on function public.sg_admin_deliver_access(text,text,text,text) from public;
grant execute on function public.sg_admin_deliver_access(text,text,text,text) to authenticated;

revoke all on function public.sg_admin_sales_summary_v4() from public;
grant execute on function public.sg_admin_sales_summary_v4() to authenticated;

notify pgrst,'reload schema';

commit;


-- =========================================================
-- FINAL CHECKOUT FIX — ORDER CREATION
-- =========================================================
begin;

drop function if exists public.sg_create_order_v4(text,text,bigint,text,text,text);

create function public.sg_create_order_v4(
  p_invoice text,
  p_product_name text,
  p_price bigint,
  p_customer_name text,
  p_whatsapp text,
  p_payment_method text
)
returns text
language plpgsql
security definer
set search_path=public
as $$
declare
  v_email text := lower(coalesce(auth.jwt()->>'email',''));
  v_invoice text := upper(trim(coalesce(p_invoice,'')));
begin
  if v_email='' then
    raise exception 'Harus login';
  end if;

  if v_invoice='' then
    raise exception 'Invoice tidak valid';
  end if;

  if nullif(trim(coalesce(p_product_name,'')),'') is null then
    raise exception 'Produk tidak valid';
  end if;

  if coalesce(p_price,0)<=0 then
    raise exception 'Harga tidak valid';
  end if;

  if nullif(trim(coalesce(p_customer_name,'')),'') is null then
    raise exception 'Nama wajib';
  end if;

  if nullif(trim(coalesce(p_whatsapp,'')),'') is null then
    raise exception 'WhatsApp wajib';
  end if;

  insert into public.sg_orders(
    invoice,
    product_name,
    price,
    customer_name,
    email,
    whatsapp,
    payment_method,
    status
  )
  values(
    v_invoice,
    trim(p_product_name),
    p_price,
    trim(p_customer_name),
    v_email,
    trim(p_whatsapp),
    coalesce(nullif(trim(p_payment_method),''),'Transfer Bank Mandiri'),
    'pending'
  );

  return v_invoice;
end;
$$;

revoke all on function public.sg_create_order_v4(text,text,bigint,text,text,text) from public;
grant execute on function public.sg_create_order_v4(text,text,bigint,text,text,text) to authenticated;

notify pgrst,'reload schema';

commit;
