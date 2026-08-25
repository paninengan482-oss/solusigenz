(function(){
  if(!document.querySelector('link[data-sg-black-final]')){
    const l=document.createElement("link");
    l.rel="stylesheet";
    l.href="solusi-genz-black-final.css";
    l.setAttribute("data-sg-black-final","1");
    document.head.appendChild(l);
  }
})();
window.SG_DEFAULT_SETTINGS={
 hero_title:"Produk digital pilihan, akses lebih praktis.",
 hero_subtitle:"Belanja produk digital dengan alur yang jelas. Setelah transaksi pertama berhasil, kamu juga dapat mengaktifkan akses affiliate Solusi Genz.",
 promo_title:"Solusi Genz",promo_discount:"0",reward_per_purchase:"0",reward_note:"",
 company_profile:"Solusi Genz adalah platform produk digital yang mengutamakan proses pembelian yang ringkas, transparan, dan mudah dipantau.",
 about_title:"Tentang Solusi Genz",about_text:"Solusi Genz membantu pelanggan mendapatkan produk digital melalui proses yang praktis dan terstruktur. Program affiliate hanya terbuka setelah pelanggan melakukan transaksi produk yang valid, sehingga komisi berasal dari aktivitas penjualan nyata.",
 support_whatsapp:"",logo_data_url:"",affiliate_rate:"10",founder_name:"Dede Fahruroji",sourcing_name:"Difa Al Azizi"
};
window.SG_STORE_SETTINGS={...window.SG_DEFAULT_SETTINGS};
window.sgApplyGlobalBrand=function(s){
 const logo=s?.logo_data_url||"solusi-genz-v2.svg";
 document.querySelectorAll("[data-sg-logo]").forEach(el=>{el.innerHTML="";const img=document.createElement("img");img.src=logo;img.alt="Solusi Genz";el.appendChild(img)});
 document.querySelectorAll('img.sg-logo,img.auth-logo,img[src="assets/solusi-genz-logo.jpg"]').forEach(img=>{if(!s?.logo_data_url)img.src="solusi-genz-v2.svg"});
};
window.sgLoadSettings=async function(){
 let s={...window.SG_DEFAULT_SETTINGS};
 try{const r=await fetch(window.SG_SUPABASE_URL+"/rest/v1/rpc/sg_public_store_settings",{method:"POST",headers:{"Content-Type":"application/json","apikey":window.SG_SUPABASE_KEY},body:"{}",cache:"no-store"});if(r.ok){const rows=await r.json();const row=Array.isArray(rows)?rows[0]:rows;if(row)s={...s,...row}}}catch(e){}
 try{const r=await fetch(window.SG_SUPABASE_URL+"/rest/v1/rpc/sg_public_extra_settings",{method:"POST",headers:{"Content-Type":"application/json","apikey":window.SG_SUPABASE_KEY},body:"{}",cache:"no-store"});if(r.ok){const rows=await r.json();const row=Array.isArray(rows)?rows[0]:rows;if(row)s={...s,...row}}}catch(e){}
 window.SG_STORE_SETTINGS=s;window.sgApplyGlobalBrand(s);document.dispatchEvent(new CustomEvent("sg-settings-ready",{detail:s}));return s;
};