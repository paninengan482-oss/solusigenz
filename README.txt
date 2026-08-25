SOLUSI GENZ V15.12 - FIX LIHAT BUKTI

Penyebab bug:
admin-proof-modal.js melakukan patch tombol Lihat Bukti berkali-kali.
Patch pertama mengambil URL bukti lalu menghapus href.
MutationObserver kemudian mem-patch tombol yang sama lagi dan membaca href kosong.
Akibatnya muncul: "Bukti pembayaran tidak ditemukan."

Cara pasang:
1. Extract ZIP.
2. Ambil admin-proof-modal.js.
3. GitHub repo solusigenz -> upload ke ROOT.
4. Replace admin-proof-modal.js yang lama.
5. Commit ke main.
6. Tunggu Vercel Ready.
7. Refresh Dashboard Admin (Ctrl+Shift+R bila perlu).
8. Klik Lihat Bukti.

Tidak perlu SQL lagi untuk fix ini.
Jangan ubah admin-access-v2.js yang sudah bekerja.
