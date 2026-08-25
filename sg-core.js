(function(){
  const U=window.SG_SUPABASE_URL, K=window.SG_SUPABASE_KEY;

  function keys(mode){
    return mode==="admin"
      ? {access:"sg_admin_token", refresh:"sg_admin_refresh", email:"sg_admin_email", store:sessionStorage}
      : {access:"sg_user_token", refresh:"sg_user_refresh", email:"sg_user_email", store:localStorage};
  }

  function getAccess(mode){ const k=keys(mode); return k.store.getItem(k.access)||""; }
  function getRefresh(mode){ const k=keys(mode); return k.store.getItem(k.refresh)||""; }

  function setSession(mode,data,email){
    const k=keys(mode);
    if(data?.access_token) k.store.setItem(k.access,data.access_token);
    if(data?.refresh_token) k.store.setItem(k.refresh,data.refresh_token);
    if(email) k.store.setItem(k.email,String(email).toLowerCase());
  }

  function clearAdmin(){
    ["sg_admin_token","sg_admin_refresh","sg_admin_email"].forEach(k=>sessionStorage.removeItem(k));
  }
  function clearUser(){
    ["sg_user_token","sg_user_refresh","sg_user_email","sg_user_name","sg_user_id","sg_user_wa"].forEach(k=>localStorage.removeItem(k));
  }

  async function refresh(mode){
    const rt=getRefresh(mode);
    if(!rt) return false;
    try{
      const r=await fetch(U+"/auth/v1/token?grant_type=refresh_token",{
        method:"POST",
        headers:{"Content-Type":"application/json","apikey":K},
        body:JSON.stringify({refresh_token:rt}),
        cache:"no-store"
      });
      if(!r.ok) return false;
      const d=await r.json();
      setSession(mode,d);
      return !!d.access_token;
    }catch(_){ return false; }
  }

  function sessionExpired(mode){
    if(mode==="admin") clearAdmin(); else clearUser();
    location.replace("auth.html?expired=1");
  }

  async function rpc(name,body={},arg3=null,arg4=null){
    // Compatible with both:
    // SGCore.rpc(name, body, "user")
    // SGCore.rpc(name, body, token, "user")
    let mode="user";
    let explicitToken="";
    if(arg4==="admin"||arg4==="user"){ mode=arg4; explicitToken=arg3||""; }
    else if(arg3==="admin"||arg3==="user"){ mode=arg3; }
    else if(typeof arg3==="string" && arg3){ explicitToken=arg3; }

    async function request(token){
      return fetch(U+"/rest/v1/rpc/"+name,{
        method:"POST",
        headers:{
          "Content-Type":"application/json",
          "apikey":K,
          "Authorization":"Bearer "+token
        },
        body:JSON.stringify(body||{}),
        cache:"no-store"
      });
    }

    let token=explicitToken||getAccess(mode);
    if(!token){ sessionExpired(mode); throw new Error("SESSION_EXPIRED"); }

    let r=await request(token);
    let raw=await r.text();

    if(r.status===401 || /jwt expired|invalid.*jwt|token.*expired/i.test(raw)){
      if(explicitToken){
        // Explicit tokens are only used during login/preflight; don't mutate unrelated sessions.
        throw new Error(raw||"Unauthorized");
      }
      const ok=await refresh(mode);
      if(ok){
        token=getAccess(mode);
        r=await request(token);
        raw=await r.text();
      }
    }

    if(!r.ok){
      if(r.status===401 || /jwt expired|invalid.*jwt|token.*expired/i.test(raw)){
        sessionExpired(mode);
        throw new Error("SESSION_EXPIRED");
      }
      throw new Error(raw||("HTTP "+r.status));
    }

    if(!raw) return null;
    try{return JSON.parse(raw)}catch(_){return raw}
  }

  window.SGCore={rpc,refresh,setSession,clearAdmin,clearUser,getAccess,getRefresh};
})();