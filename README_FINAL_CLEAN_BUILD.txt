SOLUSI GENZ — CLEAN FINAL BUILD

Versi ini mengganti paket sebelumnya.

Perbaikan penting:
- Memperbaiki error JavaScript di halaman Admin yang membuat seluruh fungsi admin berhenti dan angka tetap 0.
- Memperbaiki error JavaScript di halaman Affiliate.
- Checkout tetap memakai fungsi order final.
- Pesanan pelanggan otomatis.
- Bukti transfer -> Menunggu Verifikasi.
- Admin membaca pesanan, bukti transfer, pelanggan dan KPI.
- Admin kirim akses -> otomatis Selesai/Berhasil.
- Omzet hanya menghitung pesanan berhasil.
- Seluruh inline JavaScript telah dicek syntax sebelum ZIP dibuat.

PASANG:
1. Timpa seluruh file website dengan isi ZIP ini.
2. Commit ke GitHub dan tunggu Vercel selesai deploy.
3. Jalankan RUN_FINAL_ADMIN_ORDER_PATCH.sql di Supabase.
4. Keluar dari admin lalu login lagi.
5. Refresh.

Paket lama tidak perlu dipakai lagi.
