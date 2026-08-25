SOLUSI GENZ V15.10 - FIX KIRIM AKSES

1. Upload admin-access-v2.js ke ROOT repo GitHub solusigenz.
2. Buka admin.html.
3. Tepat sebelum </body>, tambahkan:
   <script src="admin-access-v2.js"></script>
4. Commit ke main.
5. Tunggu Vercel Ready.
6. Refresh Dashboard Admin.
7. Klik Kirim Akses pada pesanan Diproses.

Patch ini memanggil RPC baru:
sg_admin_send_access_v2
