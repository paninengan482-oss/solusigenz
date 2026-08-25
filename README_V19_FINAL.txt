SOLUSI GENZ V19 FINAL LAUNCH UI

FOKUS REVISI:
- Tampilan lebih hitam, jelas, premium, tidak pucat.
- Ada tekstur/grid halus + gradasi elegan supaya tidak hitam polos.
- Desktop dibuat lebih lega dan tidak terlalu ramai.
- Mobile dibuat lebih compact dan proporsional.
- Nominal uang/komisi dibuat hijau.
- Notifikasi dibuat gelap, jelas, dan tombol tidak terlalu besar.
- Setelah login, affiliate yang aktif langsung melihat ucapan:
  "Selamat! Komisi affiliate Anda Rp..."
- Pelanggan dapat memasang/ganti foto profil kapan saja.
  Foto disimpan ke metadata akun Supabase yang SUDAH ADA, jadi tidak perlu SQL.
- Foto katalog produk dapat diganti kapan saja lewat:
  https://solusigenz.my.id/product-media.html
  Foto disimpan pada field deskripsi produk yang SUDAH ADA dengan marker internal,
  sehingga tidak perlu menambah tabel/kolom database.

FILE:
1. solusi-genz-v19-final.css (BARU)
2. v17-core.css (REPLACE)
3. shop.html (REPLACE)
4. profile.html (REPLACE)
5. affiliate.html (REPLACE)
6. product-media.html (BARU)

TIDAK PERLU SQL.
TIDAK MENGUBAH checkout.html, status.html, admin.html, auth.html, sg-core.js, atau fungsi bisnis.

CARA PASANG:
1. Extract ZIP.
2. Upload keenam file sekaligus ke ROOT GitHub repo solusigenz.
3. Replace file lama jika diminta.
4. Commit ke main.
5. Tunggu Vercel Ready.
6. Tutup tab lama lalu buka ulang website.
7. Login pelanggan dan cek Dashboard/Profil/Affiliate.
8. Untuk ganti foto produk, login Admin lalu buka /product-media.html.

CATATAN:
- Foto profil dikompres otomatis.
- Foto produk dikompres otomatis.
- Checkout tetap membaca nama+harga produk seperti sebelumnya.
