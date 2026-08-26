window.SG_DEFAULT_SETTINGS={
 hero_title:"Langganan Digital Lebih Hemat di Solusi Genz!",
 hero_subtitle:"Layanan Produk Digital Hemat & Praktis",
 hero_note:"Harga terbaik • Proses ringkas • Aman & terpercaya",
 promo_title:"Solusi Genz",promo_discount:"0",reward_per_purchase:"0",reward_note:"",
 company_profile:"Solusi Genz adalah platform produk digital yang mengutamakan proses pembelian yang ringkas, transparan, dan mudah dipantau.",
 about_title:"Tentang Solusi Genz",
 about_text:"Solusi Genz membantu pelanggan mendapatkan produk digital melalui proses yang praktis dan terstruktur.",
 support_whatsapp:"",logo_data_url:"",affiliate_rate:"10",
 founder_name:"Difa Al Azizi",sourcing_name:"Difa Al Azizi",
 hero_media_data_url:"",transaction_media_data_url:"",referral_media_data_url:"",support_media_data_url:"",
 affiliate_title:"Affiliate Solusi Genz",
 affiliate_text:"Dapatkan komisi dengan cara share kode undangan kamu ke teman terdekat, lalu ajak mereka membeli produk digital Solusi Genz. Komisi juga akan terus kamu dapatkan ketika teman yang kamu undang melakukan repeat order.",
 commission_1_3_days:"2000",
 commission_1_week:"5000",
 commission_1_month:"10000",
 commission_1_year:"20000",
 order_title:"Cara Order"
};
window.SG_STORE_SETTINGS={...window.SG_DEFAULT_SETTINGS};
window.sgApplyGlobalBrand=function(s){
 const logo=s?.logo_data_url||"solusi-genz-v2.svg";
 document.querySelectorAll("[data-sg-logo]").forEach(el=>{
   el.innerHTML="";
   const img=document.createElement("img");
   img.src=logo;img.alt="Solusi Genz";el.appendChild(img)
 });
 document.querySelectorAll("img.sg-logo,img.auth-logo").forEach(img=>img.src=logo);
 document.querySelectorAll("[data-sg-media]").forEach(img=>{
   const key=img.dataset.sgMedia;
   const val=s?.[key];
   if(val) img.src=val;
 });
};
window.sgLoadSettings=async function(){
 let s={...window.SG_DEFAULT_SETTINGS};
 try{
  const r=await fetch(window.SG_SUPABASE_URL+"/rest/v1/rpc/sg_public_store_settings",{method:"POST",headers:{"Content-Type":"application/json","apikey":window.SG_SUPABASE_KEY},body:"{}",cache:"no-store"});
  if(r.ok){const rows=await r.json();const row=Array.isArray(rows)?rows[0]:rows;if(row)s={...s,...row}}
 }catch(e){}
 try{
  const r=await fetch(window.SG_SUPABASE_URL+"/rest/v1/rpc/sg_public_extra_settings",{method:"POST",headers:{"Content-Type":"application/json","apikey":window.SG_SUPABASE_KEY},body:"{}",cache:"no-store"});
  if(r.ok){const rows=await r.json();const row=Array.isArray(rows)?rows[0]:rows;if(row)s={...s,...row}}
 }catch(e){}
 window.SG_STORE_SETTINGS=s;
 window.sgApplyGlobalBrand(s);
 document.dispatchEvent(new CustomEvent("sg-settings-ready",{detail:s}));
 return s;
};