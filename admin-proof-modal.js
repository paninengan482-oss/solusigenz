(function(){
  function ensureModal(){
    var existing = document.getElementById("sgProofModal");
    if(existing) return existing;

    var modal = document.createElement("div");
    modal.id = "sgProofModal";
    modal.style.cssText = [
      "position:fixed","inset:0","z-index:99999","display:none",
      "align-items:center","justify-content:center","padding:20px",
      "background:rgba(0,0,0,.78)"
    ].join(";");

    modal.innerHTML = `
      <div style="position:relative;max-width:min(94vw,900px);max-height:92vh;width:100%;
                  background:#fff;border-radius:18px;padding:14px;box-shadow:0 24px 80px rgba(0,0,0,.35)">
        <button id="sgProofClose" type="button"
          style="position:absolute;right:14px;top:14px;border:0;border-radius:999px;width:38px;height:38px;
                 font-size:22px;cursor:pointer;background:#111827;color:#fff;z-index:2">×</button>
        <div style="padding:6px 48px 12px 6px;font-weight:700;font-size:18px">Bukti Pembayaran</div>
        <div id="sgProofFrame"
          style="overflow:auto;max-height:80vh;text-align:center;background:#f3f4f6;border-radius:12px;padding:10px"></div>
      </div>`;

    document.body.appendChild(modal);

    function close(){
      modal.style.display = "none";
      var frame = document.getElementById("sgProofFrame");
      if(frame) frame.innerHTML = "";
    }

    document.getElementById("sgProofClose").onclick = close;
    modal.addEventListener("click", function(e){ if(e.target === modal) close(); });
    document.addEventListener("keydown", function(e){ if(e.key === "Escape") close(); });
    return modal;
  }

  function openProof(dataUrl){
    if(!dataUrl){
      alert("Bukti pembayaran tidak ditemukan.");
      return;
    }

    var modal = ensureModal();
    var frame = document.getElementById("sgProofFrame");
    frame.innerHTML = "";

    if(/^data:image\//i.test(dataUrl)){
      var img = document.createElement("img");
      img.src = dataUrl;
      img.alt = "Bukti pembayaran";
      img.style.cssText = "max-width:100%;height:auto;border-radius:10px;display:block;margin:auto";
      frame.appendChild(img);
    }else{
      var a = document.createElement("a");
      a.href = dataUrl;
      a.textContent = "Buka bukti pembayaran";
      a.target = "_blank";
      a.rel = "noopener";
      a.style.cssText = "display:inline-block;padding:12px 16px;background:#2563eb;color:#fff;border-radius:10px;text-decoration:none";
      frame.appendChild(a);
    }

    modal.style.display = "flex";
  }

  function patchProofLinks(){
    document.querySelectorAll('#ordersBody a.btn-mini').forEach(function(a){
      if(!a.textContent.trim().toLowerCase().includes("lihat bukti")) return;

      // PENTING: jangan patch ulang link yang sama.
      if(a.dataset.sgProofPatched === "1") return;

      var href = a.getAttribute("href") || "";
      if(!href) return;

      // Simpan data bukti sebelum href dihapus.
      a.dataset.sgProofUrl = href;
      a.dataset.sgProofPatched = "1";

      a.removeAttribute("href");
      a.removeAttribute("target");
      a.style.cursor = "pointer";

      a.addEventListener("click", function(e){
        e.preventDefault();
        openProof(a.dataset.sgProofUrl || "");
      });
    });
  }

  var observer = new MutationObserver(function(){
    patchProofLinks();
  });

  observer.observe(document.documentElement, {childList:true, subtree:true});
  document.addEventListener("DOMContentLoaded", patchProofLinks);
  setTimeout(patchProofLinks, 300);
  setTimeout(patchProofLinks, 1000);
})();