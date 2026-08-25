SOLUSI GENZ V17 FINAL AUDITED

Ini bukan patch satu fitur. Ini sinkronisasi menyeluruh front-end inti.

REPLACE 11 FILE DI ROOT REPO:
1. supabase-config.js
2. sg-core.js
3. auth.html
4. reset-password.html
5. shop.html
6. checkout.html
7. status.html
8. affiliate.html
9. profile.html
10. admin.html
11. v17-core.css

TIDAK PERLU SQL BARU.

Yang diperbaiki:
- Seluruh halaman memakai satu SGCore.
- Access token + refresh token tersimpan.
- Jika token kedaluwarsa, sistem mencoba refresh otomatis.
- Login Admin: Adminsolusi123 / email Admin asli.
- Login pelanggan tetap terpisah.
- Link referral disimpan saat registrasi.
- Referral ditempel saat checkout.
- Checkout tervalidasi dan tombol dipulihkan jika gagal.
- Upload bukti dan status pelanggan konsisten.
- Affiliate/pencairan memakai sesi yang sama.
- Admin lengkap: pesanan, bukti, kirim akses, affiliate, WD, pelanggan, produk, pengaturan.
- Form Admin dapat diketik.
- Patch lama admin-proof-modal.js dan admin-access-v2.js tidak dipanggil oleh admin V17.

CATATAN:
Tidak ada sistem web yang bisa dijanjikan secara mutlak 'tidak pernah bug'. Paket ini sudah dibuat untuk menghilangkan konflik versi yang menjadi sumber masalah selama ini dan mengonsolidasikan satu alur kode.

DEPLOY:
- Extract ZIP.
- Upload/Replace SEMUA 11 file sekaligus ke root GitHub.
- Commit main.
- Tunggu Vercel Ready.
- Logout / tutup tab lama, lalu buka website baru.
- Login ulang.
- Tes alur: pelanggan pilih produk -> checkout -> upload bukti -> admin terima -> kirim akses -> pelanggan lihat akses.
