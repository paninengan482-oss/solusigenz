(function(){
  async function sendAccessV2(inv){
    const username = prompt("Username / email akses produk:", "");
    if(username === null) return;
    const password = prompt("Password akses produk:", "");
    if(password === null) return;
    const instructions = prompt("Petunjuk login / penggunaan:", "Silakan login menggunakan data di atas.") || "";
    const exp = prompt("Tanggal berakhir (YYYY-MM-DD) atau kosong:", "") || "";
    const token = sessionStorage.getItem("sg_admin_token") || "";

    if(!token){
      alert("Sesi Admin habis. Silakan login ulang.");
      location.replace("auth.html");
      return;
    }

    try{
      const res = await fetch(window.SG_SUPABASE_URL + "/rest/v1/rpc/sg_admin_send_access_v2", {
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
          p_expires_at: exp ? new Date(exp + "T23:59:59").toISOString() : null
        }),
        cache: "no-store"
      });

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
      if(btn.dataset.v2patched === "1") return;
      const clone = btn.cloneNode(true);
      clone.dataset.v2patched = "1";
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
  setTimeout(patchButtons, 500);
  setTimeout(patchButtons, 1200);
})();