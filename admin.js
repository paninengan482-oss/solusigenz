const token = sessionStorage.getItem('sg_admin_token');
const money = n => 'Rp' + Number(n || 0).toLocaleString('id-ID');
const esc = v => String(v ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
adminEmail.textContent = sessionStorage.getItem('sg_admin_email') || 'Admin';
let orders = [], products = [];
async function rpc(n,b={}) {
  const r = await fetch(SG_SUPABASE_URL + '/rest/v1/rpc/' + n, {
    method:'POST', headers:{'Content-Type':'application/json','apikey':SG_SUPABASE_KEY,'Authorization':'Bearer '+token},
    body:JSON.stringify(b), cache:'no-store'
  });
  if(!r.ok){ if(r.status===401||r.status===403) location.replace('admin-login.html'); throw Error(await r.text()); }
  return r.json();
}
function resize(file){
  return new Promise((res,rej)=>{const fr=new FileReader();fr.onload=()=>{const im=new Image();im.onload=()=>{const max=1000,s=Math.min(1,max/Math.max(im.width,im.height)),c=document.createElement('canvas');c.width=Math.round(im.width*s);c.height=Math.round(im.height*s);c.getContext('2d').drawImage(im,0,0,c.width,c.height);res(c.toDataURL('image/jpeg',.78));};im.onerror=rej;im.src=fr.result;};fr.readAsDataURL(file);});
}
async function loadOrders(){
  try{
    orders = await rpc('sg_admin_launch_orders');
    statOrders.textContent = orders.length;
    statVerify.textContent = orders.filter(o=>o.status==='Menunggu Verifikasi').length;
    statProcess.textContent = orders.filter(o=>o.status==='Diproses').length;
    statRevenue.textContent = money(orders.filter(o=>['Diproses','Selesai'].includes(o.status)).reduce((a,o)=>a+Number(o.price||0),0));
    orderRows.innerHTML = orders.length ? orders.map(o=>`<tr><td><b>${esc(o.invoice)}</b><br><small>${new Date(o.created_at).toLocaleString('id-ID')}</small></td><td>${esc(o.customer_name)}<br><small>${esc(o.email)}<br>${esc(o.whatsapp||'')}</small></td><td>${esc(o.product_name)}<br><small>${esc(o.payment_method||'')}</small></td><td>${money(o.price)}</td><td><span class="pill ${o.status==='Selesai'?'ok':o.status==='Menunggu Verifikasi'?'warn':''}">${esc(o.status)}</span></td><td>${o.proof_data_url?`<a href="${o.proof_data_url}" target="_blank"><img class="proof" src="${o.proof_data_url}"></a>`:'-'}</td><td>${o.status==='Menunggu Verifikasi'?`<div class="order-actions"><button class="btn btn-primary accept" data-i="${esc(o.invoice)}">Terima</button><button class="btn btn-danger reject" data-i="${esc(o.invoice)}">Tolak</button></div>`:'-'}</td></tr>`).join('') : '<tr><td colspan="7">Belum ada pesanan.</td></tr>';
    document.querySelectorAll('.accept').forEach(b=>b.onclick=()=>review(b.dataset.i,true));
    document.querySelectorAll('.reject').forEach(b=>b.onclick=()=>review(b.dataset.i,false));
    accessInvoice.innerHTML = '<option value="">Pilih invoice...</option>' + orders.filter(o=>['Diproses','Selesai'].includes(o.status)).map(o=>`<option value="${esc(o.invoice)}">${esc(o.invoice)} — ${esc(o.product_name)} — ${esc(o.customer_name)}</option>`).join('');
  }catch(e){ orderRows.innerHTML='<tr><td colspan="7">Data belum dapat dimuat. Jalankan SOLUSI_GENZ_LAUNCH_MIGRATION.sql.</td></tr>'; }
}
async function review(i,ok){
  let reason=''; if(!ok){ reason=prompt('Alasan penolakan / minta bukti ulang:','Bukti belum sesuai atau dana belum ditemukan.')||''; if(!reason)return; }
  await rpc('sg_admin_review_payment',{p_invoice:i,p_accept:ok,p_reason:reason}); await loadOrders();
}
sendAccessBtn.onclick = async()=>{
  if(!accessInvoice.value) return alert('Pilih invoice.'); sendAccessBtn.disabled=true;
  try{ await rpc('sg_admin_send_product_access',{p_invoice:accessInvoice.value,p_identity:accessIdentity.value.trim(),p_secret:accessSecret.value,p_instruction:accessInstruction.value.trim(),p_active_until:accessUntil.value.trim()}); accessMsg.style.display='block';accessMsg.className='notice ok';accessMsg.textContent='Akses produk terkirim dan pelanggan menerima notifikasi.';accessIdentity.value='';accessSecret.value='';accessInstruction.value='';accessUntil.value='';await loadOrders(); }
  catch(e){accessMsg.style.display='block';accessMsg.textContent='Akses belum berhasil dikirim.';} finally{sendAccessBtn.disabled=false;}
};
async function loadProducts(){
  try{ products=await rpc('sg_admin_catalog_list'); productRows.innerHTML=products.length?products.map(p=>`<tr><td>${esc(p.name)}</td><td>${esc(p.duration||'-')}</td><td>${money(p.price)}</td><td>${money(p.commission_amount)}</td><td>${p.active?'Aktif':'Nonaktif'}</td><td><button class="btn btn-outline editp" data-id="${p.id}">Edit</button></td></tr>`).join(''):'<tr><td colspan="6">Belum ada produk.</td></tr>'; document.querySelectorAll('.editp').forEach(b=>b.onclick=()=>editProduct(b.dataset.id)); }
  catch(e){ productRows.innerHTML='<tr><td colspan="6">Katalog belum dapat dimuat.</td></tr>'; }
}
function editProduct(id){ const p=products.find(x=>String(x.id)===String(id)); if(!p)return; productId.value=p.id;productName.value=p.name||'';productCategory.value=p.category||'';productDuration.value=p.duration||'';productPrice.value=p.price||0;productCommission.value=p.commission_amount||0;productActive.value=String(!!p.active);productDescription.value=p.description||'';location.hash='#products'; }
function clearProduct(){ productId.value='';productName.value='';productCategory.value='';productDuration.value='';productPrice.value='';productCommission.value='';productDescription.value='';productActive.value='true'; }
saveProductBtn.onclick=async()=>{if(!productName.value.trim())return alert('Nama produk wajib diisi.');await rpc('sg_admin_catalog_save',{p_id:productId.value||null,p_name:productName.value.trim(),p_category:productCategory.value.trim(),p_duration:productDuration.value.trim(),p_description:productDescription.value.trim(),p_price:Number(productPrice.value||0),p_commission_amount:Number(productCommission.value||0),p_active:productActive.value==='true',p_sort_order:100});clearProduct();loadProducts();};
clearProductBtn.onclick=clearProduct;
async function loadAffiliate(){try{const d=await rpc('sg_owner_affiliate_summary');affiliateRows.innerHTML=d.length?d.map(a=>`<tr><td>${esc(a.affiliate_email)}</td><td>${esc(a.referral_code)}</td><td>${a.total_referrals||0}</td><td>${a.total_transactions||0}</td><td>${money(a.total_commission)}</td><td>${money(a.paid_commission)}</td></tr>`).join(''):'<tr><td colspan="6">Belum ada affiliate.</td></tr>';}catch(e){affiliateRows.innerHTML='<tr><td colspan="6">Data affiliate belum tersedia.</td></tr>';}}
async function loadWd(){
  try{const d=await rpc('sg_admin_withdrawals');wdRows.innerHTML=d.length?d.map(w=>`<tr><td>#${w.id}<br><small>${new Date(w.requested_at).toLocaleString('id-ID')}</small></td><td>${esc(w.affiliate_email)}</td><td>${money(w.amount)}</td><td>${esc(w.method)}<br>${esc(w.account_name)}<br>${esc(w.account_number)}</td><td><span class="pill ${w.status==='Selesai'?'ok':w.status==='Ditolak'?'bad':'warn'}">${esc(w.status)}</span></td><td>${w.status==='Dalam Proses'?`<button class="btn btn-primary finishwd" data-id="${w.id}">Tandai Dibayar</button> <button class="btn btn-danger rejectwd" data-id="${w.id}">Tolak</button>`:'-'}</td></tr>`).join(''):'<tr><td colspan="6">Belum ada permintaan.</td></tr>';document.querySelectorAll('.finishwd').forEach(b=>b.onclick=()=>finishWd(b.dataset.id,true));document.querySelectorAll('.rejectwd').forEach(b=>b.onclick=()=>finishWd(b.dataset.id,false));}
  catch(e){wdRows.innerHTML='<tr><td colspan="6">Withdraw belum dapat dimuat.</td></tr>';}
}
async function finishWd(id,ok){
  if(ok){const inp=document.createElement('input');inp.type='file';inp.accept='image/*';inp.onchange=async()=>{if(!inp.files[0])return;const data=await resize(inp.files[0]);await rpc('sg_admin_finish_withdrawal',{p_id:Number(id),p_accept:true,p_reason:'',p_transfer_proof_data_url:data});loadWd();};inp.click();}
  else{const reason=prompt('Alasan penolakan:','Data rekening tidak sesuai.')||'';if(!reason)return;await rpc('sg_admin_finish_withdrawal',{p_id:Number(id),p_accept:false,p_reason:reason,p_transfer_proof_data_url:''});loadWd();}
}
async function loadStore(){try{const d=await rpc('sg_public_launch_settings'),s=d?.[0];if(s){groupUrl.value=s.whatsapp_group_url||'';minWd.value=s.minimum_withdraw||50000;wdSla.value=s.withdraw_sla||'';holdRule.value=s.commission_hold_rule||'';}}catch(_){}}
saveStoreBtn.onclick=async()=>{try{await rpc('sg_admin_save_launch_settings',{p_whatsapp_group_url:groupUrl.value.trim(),p_minimum_withdraw:Number(minWd.value||50000),p_withdraw_sla:wdSla.value.trim(),p_commission_hold_rule:holdRule.value.trim()});storeMsg.style.display='block';storeMsg.className='notice ok';storeMsg.textContent='Pengaturan berhasil disimpan.';}catch(e){storeMsg.style.display='block';storeMsg.textContent='Pengaturan belum berhasil disimpan.';}};
async function refresh(){await Promise.all([loadOrders(),loadProducts(),loadAffiliate(),loadWd(),loadStore()]);}
refreshBtn.onclick=refresh;logoutBtn.onclick=()=>{sessionStorage.clear();location.replace('admin-login.html');};refresh();
