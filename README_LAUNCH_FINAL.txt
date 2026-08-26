SOLUSI GENZ — LAUNCH REVISION 26 AGUSTUS 2026

Basis revisi: SOLUSI_GENZ_FINAL_AFFILIATE_ENGINE_V2(4).zip
Acuan flow: Rangkuman_Revisi_Solusi_Genz_Besok.pdf
Acuan visual: tampilan CorelDRAW putih + navy/royal blue yang disetujui.

PERUBAHAN UTAMA
- Beranda dirombak mengikuti tema visual putih + navy/royal blue, proporsi compact dan responsive.
- Tombol/link Admin di halaman publik dihapus.
- Admin menggunakan URL khusus /admin-login.html dan validasi sg_is_admin yang sudah ada.
- Flow bayar diubah: tidak ada lagi "Saya Sudah Bayar"; pelanggan upload bukti pembayaran.
- Admin menerima/menolak bukti dan alasan penolakan kembali ke pelanggan.
- Admin dapat mengirim akses produk (username/email, password, petunjuk, masa aktif) ke Pesanan Saya.
- Status disederhanakan: Menunggu Pembayaran, Menunggu Verifikasi, Diproses, Selesai.
- Reward/poin dihapus dari UI dan rewards.html dialihkan ke Affiliate.
- Affiliate: referral, komisi fixed durasi (2k/5k/10k/20k), tertahan, tersedia, withdraw.
- Withdraw: permintaan, data rekening/e-wallet, admin upload bukti transfer, selesai/ditolak.
- Notifikasi konsumen/Admin/Affiliate ditambahkan.
- Kartu grup WhatsApp hanya muncul untuk pelanggan dengan transaksi valid jika link diisi Admin.
- Pengaturan produk + link grup + minimum withdraw tersedia di Dashboard Admin.

PENTING — 2 LANGKAH SEBELUM LAUNCH
1) Commit/replace isi repo dengan paket ini dan tunggu Vercel deploy.
2) Di Supabase SQL Editor, jalankan SATU file: SOLUSI_GENZ_LAUNCH_MIGRATION.sql
   File ini menambah struktur yang diperlukan untuk upload bukti, akses produk, notifikasi, bantuan, dan withdraw.
   Schema V7/V14 lama tetap dipakai dan tidak perlu dihapus.

ADMIN
URL khusus: /admin-login.html
Gunakan akun Admin Supabase yang sudah terdaftar pada tabel sg_admins. Halaman publik tidak menampilkan link Admin.

CATATAN PENGUJIAN PAKET
- Seluruh file HTML telah dicek untuk link lokal yang hilang: tidak ada.
- Seluruh JavaScript inline dan admin.js telah melewati pemeriksaan syntax Node.js.
- Flow baru dibuat di atas tabel/order/affiliate existing agar data lama tidak sengaja dihapus.
