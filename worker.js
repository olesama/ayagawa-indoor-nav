
// Cloudflare Worker + D1 example for anonymous route aggregation.
// Bind a D1 database as DB.
export default {
  async fetch(request, env) {
    const u = new URL(request.url);
    if (request.method === "OPTIONS") {
      return new Response(null,{headers:{
        "Access-Control-Allow-Origin":"*",
        "Access-Control-Allow-Methods":"POST,GET,OPTIONS",
        "Access-Control-Allow-Headers":"Content-Type"
      }});
    }
    if (u.pathname === "/route-sample" && request.method === "POST") {
      const x = await request.json();
      if (!x.facility || !x.from || !x.destination || !Number.isFinite(+x.meters)) {
        return new Response("bad request",{status:400});
      }
      await env.DB.prepare(
        `INSERT INTO route_samples
        (facility, start_point, destination, meters, steps, duration_sec, turns, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(
        String(x.facility),String(x.from),String(x.destination),
        +x.meters,+x.steps||0,+x.durationSec||0,+x.turns||0,
        new Date().toISOString()
      ).run();
      return Response.json({ok:true},{headers:{"Access-Control-Allow-Origin":"*"}});
    }
    if (u.pathname === "/route-average" && request.method === "GET") {
      const facility=u.searchParams.get("facility")||"";
      const start=u.searchParams.get("from")||"";
      const destination=u.searchParams.get("destination")||"";
      const rows=await env.DB.prepare(
        `SELECT meters FROM route_samples
         WHERE facility=? AND start_point=? AND destination=?
         ORDER BY created_at DESC LIMIT 500`
      ).bind(facility,start,destination).all();
      const vals=(rows.results||[]).map(r=>+r.meters).filter(v=>v>0).sort((a,b)=>a-b);
      let use=vals;
      if(vals.length>=5){
        const cut=Math.max(1,Math.floor(vals.length*.1));
        use=vals.slice(cut,vals.length-cut);
      }
      const avg=use.length?use.reduce((a,b)=>a+b,0)/use.length:0;
      return Response.json({count:vals.length,averageMeters:avg},{headers:{"Access-Control-Allow-Origin":"*"}});
    }
    return new Response("Indoor Nav learning API",{status:200});
  }
};
