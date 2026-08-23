
window.SG_DEFAULT_SETTINGS = {
  hero_title: "Langganan Digital Lebih Hemat di Solusi Genz!",
  hero_subtitle: "Harga terbaik • Proses ringkas • Aman & terpercaya",
  promo_title: "Promo Spesial Solusi Genz",
  promo_discount: "30",
  reward_per_purchase: "1",
  reward_note: "Kumpulkan poin dari setiap pembelian dan tukarkan dengan hadiah dari Solusi Genz.",
  company_profile: "Solusi Genz adalah platform layanan digital yang membantu generasi sekarang mendapatkan kebutuhan digital dengan alur yang praktis, jelas, dan mudah dipantau.",
  about_title: "Tentang Kami",
  about_text: "Solusi Genz hadir untuk membantu generasi digital mendapatkan layanan yang praktis, mudah dipahami, dan nyaman digunakan.",
  support_whatsapp: "",
  logo_data_url: ""
};

window.SG_STORE_SETTINGS = {...window.SG_DEFAULT_SETTINGS};

window.sgApplyGlobalBrand = function(settings){
  const logo = settings && settings.logo_data_url ? settings.logo_data_url : "";
  document.querySelectorAll("[data-sg-logo]").forEach(el => {
    if (logo) {
      el.innerHTML = "";
      const img = document.createElement("img");
      img.src = logo;
      img.alt = "Logo Solusi Genz";
      img.className = "sg-owner-logo";
      el.appendChild(img);
      el.classList.add("has-owner-logo");
    }
  });
};

window.sgLoadSettings = async function(){
  let s = {...window.SG_DEFAULT_SETTINGS};
  try {
    const r = await fetch(window.SG_SUPABASE_URL + "/rest/v1/rpc/sg_public_store_settings", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": window.SG_SUPABASE_KEY
      },
      body: "{}",
      cache: "no-store"
    });
    if (r.ok) {
      const rows = await r.json();
      const row = Array.isArray(rows) ? rows[0] : rows;
      if (row) s = {...s, ...row};
    } else {
      console.warn("Store settings RPC:", await r.text());
    }
  } catch(e) {
    console.warn("Store settings fallback:", e);
  }

  window.SG_STORE_SETTINGS = s;
  window.sgApplyGlobalBrand(s);
  document.dispatchEvent(new CustomEvent("sg-settings-ready", {detail:s}));
  return s;
};
