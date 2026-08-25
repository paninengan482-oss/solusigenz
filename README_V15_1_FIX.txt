SOLUSI GENZ V15.1 DATABASE COMPATIBILITY FIX

Gunakan file SQL: SOLUSI_GENZ_V15_FLOW_FINAL.sql
Versi ini sudah ditambah compatibility preflight untuk database Solusi Genz versi lama.
Preflight menghapus function/RPC lama yang bentrok lalu membuat ulang versi V15. Data pesanan/tabel tidak dihapus.
Jalankan SQL satu kali. Jika Supabase menampilkan Potential issues detected, pilih Run without RLS karena script mengatur RLS sendiri pada tabel yang diperlukan.
