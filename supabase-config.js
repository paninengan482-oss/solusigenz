window.SG_SUPABASE_URL = 'https://ityifqihjhcofddcsnpp.supabase.co';
window.SG_SUPABASE_KEY = 'sb_publishable_x_sfc1Uk_VT6aCdZMFuhCQ_zOefolMU';

(function(){
  if(!/\/auth\.html$/i.test(location.pathname)) return;

  document.addEventListener('click', async function(e){
    const btn = e.target && e.target.closest ? e.target.closest('#submit') : null;
    if(!btn) return;

    const idEl = document.getElementById('email');
    const pwEl = document.getElementById('password');
    if(!idEl || !pwEl) return;

    const loginId = (idEl.value || '').trim();
    if(loginId.toLowerCase() !== 'adminsolusi123') return;

    e.preventDefault();
    e.stopImmediatePropagation();

    const msg = document.getElementById('msg');
    const oldText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Memproses...';
    if(msg){
      msg.style.display = 'block';
      msg.textContent = 'Memeriksa akun...';
    }

    try {
      const r = await fetch(window.SG_SUPABASE_URL + '/auth/v1/token?grant_type=password', {
        method: 'POST',
        headers: {
          'Content-Type':'application/json',
          'apikey':window.SG_SUPABASE_KEY
        },
        body: JSON.stringify({
          email:'paninengan482@gmail.com',
          password:pwEl.value
        })
      });

      if(!r.ok) throw new Error('Login gagal');
      const d = await r.json();

      if(!d.access_token || !d.user ||
         String(d.user.email || '').toLowerCase() !== 'paninengan482@gmail.com'){
        throw new Error('Akun tidak cocok');
      }

      sessionStorage.setItem('sg_admin_token', d.access_token);
      sessionStorage.setItem('sg_admin_email', 'paninengan482@gmail.com');

      localStorage.removeItem('sg_user_token');
      localStorage.removeItem('sg_user_email');
      localStorage.removeItem('sg_user_name');
      localStorage.removeItem('sg_user_id');

      location.replace('admin.html');
    } catch(err) {
      if(msg){
        msg.style.display = 'block';
        msg.textContent = 'ID atau password salah.';
      }
      btn.disabled = false;
      btn.textContent = oldText || 'Masuk';
    }
  }, true);
})();
