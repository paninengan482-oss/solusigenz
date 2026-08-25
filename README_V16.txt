SOLUSI GENZ V16 CORE REBUILD

TUJUAN
- Tidak ada SQL baru.
- Memakai database/RPC Supabase yang sudah ada.
- Menghentikan bug JWT expired yang membuat Dashboard Admin 0.
- Reset Password diperbaiki.
- Lihat Bukti tidak lagi memakai patch MutationObserver.
- Kirim Akses memakai sg_admin_send_access_v2 dengan validasi tanggal.
- Checkout, upload bukti, dan status pelanggan memakai handler sesi yang sama.

UPLOAD / REPLACE KE ROOT REPO:
1. supabase-config.js
2. sg-core.js
3. auth.html
4. reset-password.html
5. admin.html
6. checkout.html
7. status.html
8. v16-core.css

JANGAN HAPUS:
- index.html
- shop.html
- affiliate.html
- profile.html
- revamp.css
- solusi-genz-v2.svg
- file lainnya

SETELAH UPLOAD:
1. Commit ke main.
2. Tunggu Vercel Ready.
3. Buka auth.html.
4. Login ulang.
5. Tes 1 order dari awal sampai akses diterima pelanggan.

CATATAN:
Jika sesi Admin kedaluwarsa, halaman otomatis kembali ke login, bukan menampilkan Dashboard 0.
