SOLUSI GENZ — BUSINESS FINAL V3
Revisi sesuai pengecekan terakhir.

PERUBAHAN:
- Semua fitur dan halaman sebelumnya dipertahankan.
- Login Owner terpisah di admin.html dihapus.
- Owner login hanya dari halaman utama melalui ID: ADMINSOLUSI123 + password akun Supabase Owner.
- Password TIDAK ditulis di source code. Set password akun paninengan482@gmail.com di Supabase menjadi password Owner yang Anda inginkan.
- Katalog Produk Owner diperbaiki: form/input/textarea lebih kontras dan rapi.
- Pelanggan WAJIB upload bukti transfer, bukan hanya klik "Saya Sudah Bayar".
- Setelah bukti dikirim: status Menunggu Verifikasi.
- Owner melihat tombol "Lihat Bukti" di daftar pesanan.
- Setelah verifikasi, Owner bisa mengetik "Akses Produk" dan "Catatan Penting" berdasarkan invoice.
- Akses + catatan langsung muncul di halaman Pesanan pelanggan.
- Mobile Admin dan Pelanggan dipoles: form 1 kolom, tabel scroll horizontal, card lebih rapat, tombol lebih mudah disentuh.

URUTAN:
1. Extract ZIP.
2. Upload seluruh isi ZIP ke ROOT repo GitHub solusigenz dan replace file lama.
3. Commit.
4. Tunggu Vercel Ready.
5. Supabase > SQL Editor > copy seluruh RUN_ONCE_SUPABASE_FINAL.sql > Run.
6. Pastikan akun Auth paninengan482@gmail.com aktif. Jika ingin password "adminsolusi", ubah password akun tersebut di Supabase Auth menjadi adminsolusi.
7. Tes:
   - halaman utama > login Owner pakai ID ADMINSOLUSI123
   - pelanggan buat order
   - pelanggan upload bukti transfer
   - Owner buka Pesanan > Lihat Bukti > set Lunas
   - Owner isi Kirim Akses ke Pelanggan
   - pelanggan buka Pesanan dan cek akses/catatan
8. Tes mobile di HP.

CATATAN:
Jangan menaruh password Owner di HTML/JS. Alias ID boleh ada di website, password tetap diverifikasi oleh Supabase.
