SOLUSI GENZ — FINAL BUGFIX LAUNCH

BUG PEMESANAN SUDAH DIPERBAIKI:
- JavaScript checkout yang rusak dibersihkan total.
- Fungsi membuat pesanan dibuat ulang: sg_create_order_v4.
- Email pesanan otomatis memakai email akun login.
- Affiliate dibuat opsional sehingga error affiliate tidak lagi menggagalkan order.
- Setelah klik Buat Pesanan, pesanan masuk database dan langsung membuka Pesanan Saya.
- Upload bukti transfer -> Menunggu Verifikasi.
- Admin melihat bukti -> kirim akses -> otomatis Selesai/Berhasil.
- Akses muncul otomatis di pelanggan.
- Omzet hanya bertambah dari pesanan berhasil.

PASANG FINAL:
1. Upload/commit seluruh isi ZIP ini ke GitHub, timpa file lama.
2. Tunggu Vercel selesai deploy.
3. Supabase > SQL Editor > buka RUN_FINAL_ADMIN_ORDER_PATCH.sql.
4. Copy SEMUA isi file SQL lalu Run.
5. Pastikan Success.
6. Buka website baru/refresh lalu tes 1 pesanan.

Jangan jalankan SQL lama lagi.
