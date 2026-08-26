SOLUSI GENZ — FINAL UI + AFFILIATE/WITHDRAW MERGE — 27-08-2026

PERUBAHAN FRONTEND:
- Beranda: penjelasan affiliate diperjelas + tabel komisi + flow + FAQ.
- Founder default: Difa Al Azizi.
- Digital Product Sourcing: Difa Al Azizi.
- Affiliate: total referral, transaksi, komisi tertahan, saldo tersedia, saldo WD dalam proses, total komisi.
- Affiliate: form pengajuan pencairan + riwayat WD + lihat bukti transfer.
- Admin: menu Pencairan + badge permintaan + proses Dibayar/Ditolak.
- Tema biru/putih terbaru dipertahankan.

DATABASE:
Frontend WD membutuhkan fungsi V17.3:
- sg_request_withdraw
- sg_my_withdrawals
- sg_admin_list_withdrawals
- sg_admin_finish_withdraw
Dan ledger komisi dengan status tertahan/tersedia/dibayar.

CATATAN:
Jangan jalankan SQL lama yang mengembalikan reward/poin. Gunakan rangkaian SQL affiliate final yang sudah dipakai pada database Solusi Genz (V17.1 + V17.3).
