SOLUSI GENZ V15.11 - FIX INVALID TIME VALUE

Penyebab:
Field tanggal berakhir menerima nilai yang bukan tanggal valid, lalu JavaScript gagal di toISOString().

Perbaikan:
- Kosong = diperbolehkan
- Format valid = YYYY-MM-DD
- Nilai lain ditolak sebelum dikirim
- Tombol Kirim Akses tetap memakai sg_admin_send_access_v2

Cara pasang:
1. Upload admin-access-v2.js ke ROOT repo GitHub.
2. Replace file admin-access-v2.js yang lama.
3. Commit ke main.
4. Tunggu Vercel Ready.
5. Refresh Dashboard Admin.
6. Tes Kirim Akses.
7. Pada tanggal berakhir, isi contoh 2026-09-26 atau kosongkan.
