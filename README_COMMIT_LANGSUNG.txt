SOLUSI GENZ — FINAL REVISION / COMMIT LANGSUNG

Paket ini dibuat sebagai OVERLAY untuk repository Solusi Genz yang sekarang.
Upload/commit seluruh isi ZIP ini ke root repository dan izinkan file yang sama tertimpa.

PENTING:
- Jangan hapus file supabase-config.js yang SUDAH ADA di repository/live project.
- File tersebut tidak disertakan karena ZIP sumber yang diterima memang tidak berisi konfigurasi Supabase.
- Tidak ada kredensial baru/fiktif yang ditambahkan.

PERBAIKAN UTAMA:
1. Memperbaiki JavaScript admin yang rusak akibat nama identifier referral berubah menjadi teks biasa.
2. Mengaktifkan binding tombol admin: Refresh, Refresh Pencairan, Simpan Pengaturan, Upload Logo, Logo Default, Logout.
3. Mengaktifkan kembali upload gambar Banner Utama, Cara Order, Affiliate/Kode Undangan, dan Dukungan Pelanggan.
4. Tombol produk pelanggan menjadi "Pesan Sekarang" dan menuju checkout.
5. Tampilan produk dibuat lebih jelas, tidak terlihat hitam/kosong.
6. Dashboard admin diperbaiki untuk layar HP: navigasi, kartu statistik, form, tabel scroll, upload gambar, dan tombol.
7. Menambahkan profile.html, revamp.css, dan logo SVG yang hilang dari ZIP sumber.
8. Menambahkan ilustrasi Solusi Genz sebagai default untuk Hero, Cara Order, Affiliate, dan Pelanggan.
9. Memperbaiki alur referral pada checkout dan affiliate agar memakai identifier referral_code yang valid.

HASIL CEK:
- Semua inline JavaScript pada HTML lolos pemeriksaan sintaks Node.js.
- Semua referensi file lokal tersedia, kecuali supabase-config.js yang harus tetap memakai file konfigurasi existing di repository.
