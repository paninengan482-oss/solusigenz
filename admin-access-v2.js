(function(){
  function normalizeExpiry(raw){
    raw = (raw || "").trim();
    if(!raw) return null;

    // Hanya terima format YYYY-MM-DD.
    if(!/^\d{4}-\d{2}-\d{2}$/.test(raw)) return null;

    const d = new Date(raw + "T23:59:59");
    if(Number.isNaN(d.getTime())) return null;

    return d.toISOString();
  }

  async function sendAccessV2(inv){
    const username = prompt("Username / email akses produk:", "");
    if(username === null) return;

    const password = prompt("Password akses produk:", "");
    if(password === null) return;

    const instructions = prompt(
      "Petunjuk login / penggunaan:",
      "Silakan login menggunakan data di atas."
    ) || "";

    const expRaw = prompt(
      "Tanggal berakhir (YYYY-MM-DD). Jika tidak ada, kosongkan:",
      ""
    );
    if(expRaw === null) return;

    const expiresAt = normalizeExpiry(expRaw);

    if(expRaw.trim() && !expiresAt){
      alert("Format tanggal tidak valid. Gunakan contoh 2026-09-26 atau kosongkan.");
      return;
    }

    const token = sessionStorage.getItem("sg_admin_token") || "";
    if(!token){
      alert("Sesi Admin habis. Silakan login ulang.");
      location.replace("auth.html");
      return;
    }

    try{
      const res = await fetch(
        window.SG_SUPABASE_URL + "/rest/v1/rpc/sg_admin_send_access_v2",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": window.SG_SUPABASE_KEY,
            "Authorization": "Bearer " + token
          },
          body: JSON.stringify({
            p_invoice: inv,
            p_username: username,
            p_password: password,
            p_instructions: instructions,
            p_expires_at: expiresAt
          }),
          cache: "no-store"
        }
      );

      if(!res.ok) throw new Error(await res.text());

      alert("Akses berhasil dikirim. Status pesanan menjadi Selesai.");
      location.reload();
    }catch(err){
      console.error(err);
      alert("Kirim akses gagal: " + (err.message || "Unknown error"));
    }
  }

  function patchButtons(){
    document.querySelectorAll("#ordersBody button.access").forEach(btn=>{
      if(btn.dataset.v11patched === "1") return;

      const clone = btn.cloneNode(true);
      clone.dataset.v11patched = "1";
      btn.replaceWith(clone);

      clone.addEventListener("click", function(e){
        e.preventDefault();
        e.stopPropagation();
        sendAccessV2(clone.dataset.id);
      });
    });
  }

  const obs = new MutationObserver(patchButtons);
  obs.observe(document.documentElement, {childList:true, subtree:true});

  document.addEventListener("DOMContentLoaded", patchButtons);
  setTimeout(patchButtons, 400);
  setTimeout(patchButtons, 1000);
})();