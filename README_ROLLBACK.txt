SOLUSI GENZ — ROLLBACK TAMPILAN FAVORIT

Tujuan:
Mengembalikan tampilan ke gaya sebelum V18/V19/V20 yang tadi lebih nyaman dipakai.

Yang TIDAK diubah:
- Login
- Checkout
- Upload bukti pembayaran
- Admin verifikasi
- Kirim akses
- Referral
- Repeat order
- Komisi tertahan -> tersedia
- Pencairan
- Notifikasi pencairan

File yang direplace:
1. shop.html
2. affiliate.html
3. profile.html
4. v17-core.css
5. store-settings-v14.js

TIDAK PERLU SQL.

PENTING:
File tambahan dari V18/V19/V20 seperti:
- solusi-genz-black-final.css
- solusi-genz-v19-final.css
- solusi-genz-v20-clean.css
boleh tetap ada di GitHub. Setelah rollback ini, file-file tersebut TIDAK dipanggil lagi sehingga tidak memengaruhi tampilan.

Cara pasang:
1. Extract ZIP.
2. Upload 5 file di atas ke ROOT repo GitHub.
3. Replace file lama.
4. Commit ke main.
5. Tunggu Vercel Ready.
6. Tutup semua tab Solusi Genz.
7. Buka ulang website.
