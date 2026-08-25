-- Solusi Genz V15.4 - identity update only
update public.sg_store_settings_ext
set founder_name='Dede Fahruroji',
    sourcing_name='Difa Al Azizi',
    updated_at=now()
where id=1;
notify pgrst, 'reload schema';
