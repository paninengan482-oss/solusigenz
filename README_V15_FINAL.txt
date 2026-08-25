SOLUSI GENZ V15 — REVISI FLOW FINAL

MASTER: paket ini dibuat dari solusigenz-main(1).zip.

PERUBAHAN UTAMA:
- Reward/poin dihapus dari alur dan dialihkan ke Affiliate.
- Halaman publik tidak menampilkan akses Admin.
- Checkout membuat status Menunggu Pembayaran.
- Konsumen WAJIB upload bukti pembayaran; tidak ada tombol “Saya Sudah Bayar”.
- Admin dapat lihat bukti, Terima, atau Tolak/Minta Bukti Ulang.
- Setelah pembayaran diterima, status Diproses.
- Admin dapat mengirim username/email, password, petunjuk, dan masa aktif produk.
- Konsumen melihat akses produk di Pesanan Saya.
- Notifikasi pembayaran, penolakan, akses produk, dan pencairan.
- Affiliate: referral tidak menghasilkan komisi hanya dari pendaftaran.
- Komisi fixed: 1–3 hari Rp2.000; 1 minggu Rp5.000; 1 bulan Rp10.000; 1 tahun Rp20.000.
- Komisi Tertahan -> Saldo Tersedia setelah pesanan Selesai.
- Withdraw default minimum Rp50.000, dengan bukti transfer Admin.
- Link grup WhatsApp hanya muncul untuk pelanggan dengan transaksi valid.
- Founder dan Digital Product Sourcing: Difa Al Azizi.
- Tema warna existing dipertahankan.

PENTING — JANGAN JALANKAN SQL AFFILIATE LAMA LAGI.
Untuk revisi ini, setelah backup database, jalankan hanya:
SOLUSI_GENZ_V15_FLOW_FINAL.sql

Urutan deployment:
1. Backup database Supabase.
2. Jalankan SOLUSI_GENZ_V15_FLOW_FINAL.sql di SQL Editor.
3. Deploy seluruh folder website V15 ke Vercel.
4. Tes satu flow lengkap: akun referral -> beli -> upload bukti -> Admin terima -> Admin kirim akses -> Selesai -> cek komisi.
5. Baru gunakan sebagai website utama.

CATATAN KOMISI:
Nama/durasi produk di katalog harus berisi durasi yang jelas (1-3 Hari, 1 Minggu, 1 Bulan, 1 Tahun). Sistem sengaja tidak menebak nominal komisi bila durasi tidak dikenali, agar saldo tidak salah.
