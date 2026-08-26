SOLUSI GENZ — BUSINESS FINAL V4 LAUNCH READY

REVISI TERAKHIR:
- Form akses performa TIDAK tampil lagi di halaman utama.
- Semua login berada di halaman Masuk yang sama.
- Pelanggan login memakai email + password.
- Akses performa memakai ID: ADMINSOLUSI123 dan password akun Supabase yang terhubung ke paninengan482@gmail.com.
- Untuk memakai password adminadmin, set password akun paninengan482@gmail.com di Supabase Authentication menjadi adminadmin.
- Di tampilan publik tidak memakai kata Owner/Admin. Dashboard internal diberi nama "Performa Solusi Genz".
- Halaman login pelanggan: logo di tengah, tanpa badge "Akun Pelanggan", salam baru.
- Bagian Produk Digital tampil sebelum Cara Order.
- "Cara Kerja" diganti "Cara Order".
- Bahasa affiliate diubah agar fokus pada share kode undangan + transaksi pembelian + repeat order.
- Tidak ada bahasa rekrutmen/rekrut orang.
- Nominal komisi 1–3 hari, 1 minggu, 1 bulan, 1 tahun bisa diubah dari Performa.
- Judul dan penjelasan Affiliate bisa diubah dari Performa.
- Tentang Kami tetap bisa diubah dari Performa.
- Logo tetap bisa diubah.
- Banner lebar di hero bisa diganti gambar desain sendiri dari Performa.
- Logo besar di sisi kanan hero dihapus.
- Tampilan HP dibuat vertikal: scroll ke bawah, tidak perlu geser halaman ke samping.
- Form katalog produk di HP diperketat supaya tidak melebar keluar kartu.
- Checkout, bukti transfer, verifikasi, kirim akses, affiliate, komisi, pencairan tetap dipertahankan.

URUTAN PASANG:
1. Extract ZIP.
2. Upload SEMUA isi ke ROOT repo GitHub solusigenz, replace file lama.
3. Commit.
4. Tunggu Vercel Ready.
5. Supabase > SQL Editor > copy seluruh RUN_ONCE_SUPABASE_FINAL.sql > Run SEKALI.
6. Supabase Authentication > user paninengan482@gmail.com > pastikan password sesuai yang ingin dipakai. Jika target password: adminadmin, set password menjadi adminadmin.
7. Tes login:
   - pelanggan: email + password
   - performa: ID ADMINSOLUSI123 + password adminadmin
8. Tes order > upload bukti > verifikasi > kirim akses > pelanggan melihat akses.
9. Tes affiliate dan pencairan.
10. Tes di HP: semua halaman hanya scroll vertikal.

CATATAN:
Password tidak ditulis langsung di source website. ID ADMINSOLUSI123 hanya alias login; password tetap diverifikasi Supabase.
