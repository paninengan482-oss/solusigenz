(function(){
  function clearAdmin(){
    sessionStorage.removeItem("sg_admin_token");
    sessionStorage.removeItem("sg_admin_email");
  }
  function clearUser(){
    localStorage.removeItem("sg_user_token");
    localStorage.removeItem("sg_user_email");
    localStorage.removeItem("sg_user_name");
    localStorage.removeItem("sg_user_id");
  }
  function isExpiredText(t){
    return /jwt expired|token.*expired|invalid.*jwt/i.test(String(t||""));
  }
  async function rpc(name, body, token, mode){
    const r = await fetch(window.SG_SUPABASE_URL + "/rest/v1/rpc/" + name, {
      method:"POST",
      headers:{
        "Content-Type":"application/json",
        "apikey":window.SG_SUPABASE_KEY,
        "Authorization":"Bearer " + token
      },
      body:JSON.stringify(body||{}),
      cache:"no-store"
    });
    const raw = await r.text();
    if(!r.ok){
      if(r.status===401 || isExpiredText(raw)){
        if(mode==="admin") clearAdmin(); else clearUser();
        location.replace("auth.html?expired=1");
        throw new Error("SESSION_EXPIRED");
      }
      throw new Error(raw || ("HTTP " + r.status));
    }
    try { return raw ? JSON.parse(raw) : null; } catch(_) { return raw; }
  }
  window.SGCore = {rpc, clearAdmin, clearUser};
})();