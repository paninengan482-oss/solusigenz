SOLUSI GENZ — BUSINESS FINAL 27 AGUSTUS 2026

FILE INI ADALAH PAKET REVISI FINAL UNTUK DIUPLOAD/REPLACE KE ROOT REPOSITORY solusigenz.

YANG SUDAH DIKERJAKAN:
- Dark professional theme.
- Logo asli Solusi Genz tetap dipakai dan bisa diganti dari Admin.
- Gambar hero/banner bisa diganti dari Admin.
- Ilustrasi transaksi, affiliate/referral, dukungan bisa diganti dari Admin.
- Foto setiap produk bisa ditambah/diganti/hapus dari Admin.
- Produk, harga, durasi, komisi affiliate tetap editable.
- Affiliate/rekrutmen dan pencairan tetap memakai database yang sudah ada.
- Owner dikunci ke email: paninengan482@gmail.com (password TIDAK disimpan di source code).
- Lupa password pelanggan/Owner aktif melalui email Supabase.
- Checkout diperbaiki agar memakai session token pelanggan.
- Responsive desktop/mobile.

URUTAN PASANG:
1. Extract ZIP.
2. Upload semua file/folder di dalam paket ini ke ROOT repo GitHub solusigenz dan replace file lama.
3. Commit changes.
4. Tunggu Vercel menjadi Ready.
5. Buka Supabase > SQL Editor.
6. Buka file RUN_ONCE_SUPABASE_FINAL.sql, copy seluruh isi, Run SEKALI.
7. Supabase Authentication harus memiliki user Owner dengan email paninengan482@gmail.com dan password Owner yang Anda tentukan.
8. Untuk lupa password, di Supabase Authentication > URL Configuration, pastikan Site URL mengarah ke https://solusigenz.my.id dan redirect URL mengizinkan https://solusigenz.my.id/reset-password.html
9. Tes: login pelanggan, buat pesanan, admin ubah status ke Lunas, affiliate aktif, ajukan pencairan, admin proses pencairan.
10. Setelah tes berhasil, gunakan domain utama solusigenz.my.id untuk bisnis.

CATATAN KEAMANAN:
Password Owner sengaja tidak ditulis di file HTML/JS. Password harus tetap berada di Supabase Authentication.
