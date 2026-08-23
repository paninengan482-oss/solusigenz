
window.SG_DEFAULT_SETTINGS={
 hero_title:"Semua kebutuhan digital, lebih sederhana.",
 hero_subtitle:"Solusi Genz membantu generasi sekarang mendapatkan layanan digital melalui pengalaman yang praktis, rapi, dan mudah dipantau.",
 promo_title:"Promo Spesial Solusi Genz",promo_discount:"30",reward_per_purchase:"1",
 reward_note:"Kumpulkan poin dari setiap pembelian dan tukarkan dengan hadiah dari Solusi Genz.",
 company_profile:"Solusi Genz adalah platform layanan digital yang membantu generasi sekarang mendapatkan kebutuhan digital dengan alur yang praktis, jelas, dan mudah dipantau.",
 about_title:"Tentang Kami",about_text:"Solusi Genz hadir untuk membantu generasi digital mendapatkan layanan yang praktis, mudah dipahami, dan nyaman digunakan.",
 support_whatsapp:"",logo_data_url:"",affiliate_rate:"10",founder_name:"Difa Al Azizi",sourcing_name:"Difa Al Azizi"
};
window.SG_STORE_SETTINGS={...window.SG_DEFAULT_SETTINGS};
window.sgApplyGlobalBrand=function(s){
 const logo=s?.logo_data_url||"assets/solusi-genz-logo.jpg";
 document.querySelectorAll("[data-sg-logo]").forEach(el=>{el.innerHTML="";const img=document.createElement("img");img.src=logo;img.alt="Solusi Genz";el.appendChild(img)});
};
window.sgLoadSettings=async function(){
 let s={...window.SG_DEFAULT_SETTINGS};
 try{
  const r=await fetch(window.SG_SUPABASE_URL+"/rest/v1/rpc/sg_public_store_settings",{method:"POST",headers:{"Content-Type":"application/json","apikey":window.SG_SUPABASE_KEY},body:"{}",cache:"no-store"});
  if(r.ok){const rows=await r.json();const row=Array.isArray(rows)?rows[0]:rows;if(row)s={...s,...row}}
 }catch(e){console.warn("settings fallback",e)}
 window.SG_STORE_SETTINGS=s;window.sgApplyGlobalBrand(s);
 document.dispatchEvent(new CustomEvent("sg-settings-ready",{detail:s}));return s;
};
