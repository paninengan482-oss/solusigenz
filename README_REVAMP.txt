SOLUSI GENZ — REVAMP OWNER + AFFILIATE V1

INI PAKET UNTUK BRANCH:
revamp-owner-affiliate-v1

ISI REVISI:
- Foto founder di hero dihapus.
- Hero memakai logo Solusi Genz.
- Founder: Difa Al Azizi.
- Digital Product Sourcing: Difa Al Azizi.
- Tema warna navy/blue/violet dipertahankan.
- Tipografi dan layout dibuat lebih premium/minimal.
- Dashboard Admin diganti Dashboard Owner.
- KPI Total Pesanan, Menunggu Verifikasi, Diproses, Omzet bisa diklik.
- Notifikasi jumlah pesanan baru.
- Daftar pelanggan unik.
- Pengaturan logo, hero, promo, reward, profil, founder dan sourcing.
- Menu Affiliate Owner dan Affiliate Pelanggan.
- Link referral per pelanggan.
- Referral buyer dikunci ke recruiter awal agar repeat order tetap memberikan komisi.
- Website hanya mencatat omzet/komisi. Dana transaksi tetap di bank/payment channel.

PENTING:
1. Backup dulu database Supabase.
2. Upload file dari paket ini KE BRANCH revamp-owner-affiliate-v1, JANGAN ke main.
3. File yang namanya sama boleh replace.
4. Jangan hapus file lama yang tidak ada di paket ini seperti status.html, rewards.html, subscriptions.html, assets brand SVG, vercel.json.
5. Jalankan REVAMP_AFFILIATE_OWNER.sql di Supabase SQL Editor.
6. Tes branch/preview Vercel dulu.
7. JANGAN merge ke main sampai login, checkout, admin, order status, dan affiliate sudah dites.

CATATAN KOMISI:
SQL ini membangun struktur referral dan ledger komisi. Agar nominal komisi otomatis memakai harga order sebenarnya, fungsi status-order Supabase yang lama perlu ditambah update ledger ketika order Lunas/Diproses/Selesai. Paket frontend sudah siap menampilkan data tersebut.
