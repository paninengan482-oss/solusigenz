SOLUSI GENZ — FINAL ADMIN READ FIX V5

Perbaikan:
- Admin tidak lagi bergantung pada format RPC tabel lama.
- Pesanan dibaca lewat sg_admin_orders_v5() dalam format JSON.
- KPI dashboard dibaca lewat sg_admin_dashboard_v5().
- Total Pesanan, Menunggu Verifikasi, Sedang Diproses, dan Omzet mengambil data langsung dari sg_orders.
- Tombol Refresh admin aktif memuat ulang semua data.
- Checkout pelanggan tidak diubah.

PASANG:
1. Upload/commit semua isi ZIP ke GitHub.
2. Tunggu Vercel selesai.
3. Jalankan seluruh RUN_FINAL_ADMIN_ORDER_PATCH.sql di Supabase.
4. Jika Success, KELUAR dari admin.
5. Login admin lagi.
6. Klik Refresh.

