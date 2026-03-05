import { useState, useEffect, useRef, useCallback } from "react";

// ── Supabase Client ─────────────────────────────────────────────────────────
const SUPABASE_URL = "https://rfnxevgbxxtazyjsyvpv.supabase.co";
const SUPABASE_KEY = "sb_publishable_DZztRYfapxIooxnp70zoAw_aR62RXcl";

// ── Trial Key System ───────────────────────────────────────────────────────
// Each key allows ANY email to sign up for a 14-day Team Pro trial.
// The key is used as the password during sign-up — replaced by user's own
// password once they subscribe after trial.
const TRIAL_KEYS = [
  "SCOUT-ED9T0-7R0S8",
  "SCOUT-LFIZW-1F8PH",
  "SCOUT-VLRO7-0YS2K",
  "SCOUT-LLLED-75AME",
  "SCOUT-B9DXC-GL8DU",
  "SCOUT-HAW33-RE41V",
  "SCOUT-J7YE1-ACAIF",
  "SCOUT-CKGEW-QGPPV",
  "SCOUT-AFU3F-M6FNL",
  "SCOUT-I1TB2-U47KB",
];
const TRIAL_DAYS = 14;

// Lightweight Supabase client (no npm needed — uses fetch directly)
const supabase = (() => {
  const headers = {
    "Content-Type": "application/json",
    "apikey": SUPABASE_KEY,
    "Authorization": `Bearer ${SUPABASE_KEY}`,
  };

  const authHeaders = (token) => token
    ? { ...headers, "Authorization": `Bearer ${token}` }
    : headers;

  // Store session in memory + localStorage
  let _session = null;
  try { _session = JSON.parse(localStorage.getItem("sb_session")); } catch {}

  const saveSession = (s) => {
    _session = s;
    if (s) localStorage.setItem("sb_session", JSON.stringify(s));
    else localStorage.removeItem("sb_session");
  };

  const auth = {
    getSession: () => _session,

    signUp: async ({ email, password, options }) => {
      const r = await fetch(`${SUPABASE_URL}/auth/v1/signup`, {
        method: "POST", headers,
        body: JSON.stringify({ email, password, data: options?.data || {} }),
      });
      const d = await r.json();
      if (d.access_token) saveSession(d);
      return { data: d, error: d.error || (d.msg ? { message: d.msg } : null) };
    },

    signInWithPassword: async ({ email, password }) => {
      const r = await fetch(`${SUPABASE_URL}/auth/v1/token?grant_type=password`, {
        method: "POST", headers,
        body: JSON.stringify({ email, password }),
      });
      const d = await r.json();
      if (d.access_token) saveSession(d);
      return { data: d, error: d.error_description ? { message: d.error_description } : null };
    },

    signOut: async () => {
      if (_session?.access_token) {
        await fetch(`${SUPABASE_URL}/auth/v1/logout`, {
          method: "POST", headers: authHeaders(_session.access_token),
        });
      }
      saveSession(null);
      return { error: null };
    },

    getUser: () => _session?.user || null,
  };

  const from = (table) => ({
    select: (cols = "*") => ({
      eq: async (col, val) => {
        const token = _session?.access_token;
        const r = await fetch(
          `${SUPABASE_URL}/rest/v1/${table}?select=${cols}&${col}=eq.${val}&order=created_at.desc`,
          { headers: authHeaders(token) }
        );
        const d = await r.json();
        return { data: Array.isArray(d) ? d : [], error: d.error || null };
      },
      order: async (col, { ascending } = {}) => {
        const token = _session?.access_token;
        const dir = ascending ? "asc" : "desc";
        const r = await fetch(
          `${SUPABASE_URL}/rest/v1/${table}?select=${cols}&order=${col}.${dir}`,
          { headers: authHeaders(token) }
        );
        const d = await r.json();
        return { data: Array.isArray(d) ? d : [], error: d.error || null };
      },
    }),

    insert: async (rows) => {
      const token = _session?.access_token;
      const r = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
        method: "POST",
        headers: { ...authHeaders(token), "Prefer": "return=representation" },
        body: JSON.stringify(Array.isArray(rows) ? rows : [rows]),
      });
      const d = await r.json();
      return { data: Array.isArray(d) ? d : [d], error: d.error || null };
    },

    update: (vals) => ({
      eq: async (col, val) => {
        const token = _session?.access_token;
        const r = await fetch(
          `${SUPABASE_URL}/rest/v1/${table}?${col}=eq.${val}`,
          {
            method: "PATCH",
            headers: { ...authHeaders(token), "Prefer": "return=representation" },
            body: JSON.stringify(vals),
          }
        );
        const d = await r.json();
        return { data: Array.isArray(d) ? d : [d], error: d.error || null };
      },
    }),

    delete: () => ({
      eq: async (col, val) => {
        const token = _session?.access_token;
        const r = await fetch(
          `${SUPABASE_URL}/rest/v1/${table}?${col}=eq.${val}`,
          { method: "DELETE", headers: authHeaders(token) }
        );
        return { error: null };
      },
    }),
  });

  return { auth, from };
})();

// ── Fonts & Global Styles ──────────────────────────────────────────────────
const GlobalStyles = () => (
  <style>{`
    *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
    :root{
      --bg:#070B14;
      --surface:#0D1525;
      --surface2:#101D30;
      --surface3:#152038;
      --border:#1A2E4A;
      --border2:#1E3A5F;
      --accent:#00FF87;
      --accent2:#00C6FF;
      --coral:#FF6B35;
      --gold:#FFD700;
      --green:#00FF87;
      --red:#FF4D6D;
      --orange:#FF6B35;
      --purple:#7C3AED;
      --text:#E8F5E9;
      --text2:#3A6080;
      --text3:#1a3a5c;
      --font-display:-apple-system,BlinkMacSystemFont,sans-serif;
      --font-body:-apple-system,BlinkMacSystemFont,sans-serif;
      --font-mono:'SFMono-Regular','Menlo','Consolas',monospace;
    }
    html{scroll-behavior:smooth}
    body{
      background:
        radial-gradient(ellipse 70% 55% at 85% 8%, rgba(0,198,255,0.13) 0%, transparent 55%),
        radial-gradient(ellipse 60% 45% at 10% 80%, rgba(0,255,135,0.10) 0%, transparent 50%),
        radial-gradient(ellipse 40% 35% at 50% 50%, rgba(0,198,255,0.04) 0%, transparent 60%),
        linear-gradient(145deg, #070B14 0%, #090E1A 30%, #0A1628 60%, #070F1E 100%);
      background-attachment:fixed;
      color:var(--text);
      font-family:-apple-system,BlinkMacSystemFont,sans-serif;
      -webkit-font-smoothing:antialiased;
      -moz-osx-font-smoothing:grayscale;
      text-rendering:optimizeLegibility;
      overflow-x:hidden;
      min-height:100vh;
    }
    input,textarea,select{font-family:var(--font-body)}
    ::-webkit-scrollbar{width:6px;height:6px}
    ::-webkit-scrollbar-track{background:var(--surface)}
    ::-webkit-scrollbar-thumb{background:var(--border2);border-radius:3px}
    ::-webkit-scrollbar-thumb:hover{background:var(--accent)}
    input[type=range]{-webkit-appearance:none;appearance:none;height:6px;border-radius:3px;outline:none;cursor:pointer}
    input[type=range]::-webkit-slider-thumb{-webkit-appearance:none;width:16px;height:16px;border-radius:50%;cursor:pointer;border:2px solid var(--bg)}
    .slide-in{animation:slideIn .3s ease}
    @keyframes slideIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
    .fade-in{animation:fadeIn .4s ease}
    @keyframes fadeIn{from{opacity:0}to{opacity:1}}
    .pulse{animation:pulse 2s infinite}
    @keyframes pulse{0%,100%{opacity:1}50%{opacity:.6}}
    @keyframes spin{to{transform:rotate(360deg)}}
    .spinner{width:20px;height:20px;border:2px solid var(--border2);border-top-color:var(--accent);border-radius:50%;animation:spin .7s linear infinite;display:inline-block}
    .gradient-text{background:linear-gradient(135deg,var(--accent),var(--accent2));-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text}
    .glow{box-shadow:0 0 20px rgba(0,255,135,.12),0 0 40px rgba(0,255,135,.05)}
    .rec-badge{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:4px;font-size:11px;font-weight:600;letter-spacing:.5px;text-transform:uppercase}
    .rec-sign{background:rgba(0,255,135,.12);color:var(--accent);border:1px solid rgba(0,255,135,.3)}
    .rec-watch{background:rgba(255,215,0,.1);color:var(--gold);border:1px solid rgba(255,215,0,.25)}
    .rec-pass{background:rgba(255,77,109,.1);color:var(--red);border:1px solid rgba(255,77,109,.25)}
    .rec-trial{background:rgba(0,198,255,.1);color:var(--accent2);border:1px solid rgba(0,198,255,.25)}
    .status-badge{display:inline-flex;align-items:center;gap:4px;padding:2px 7px;border-radius:3px;font-size:10px;font-weight:600;text-transform:uppercase;letter-spacing:.5px}
    .btn{display:inline-flex;align-items:center;justify-content:center;gap:8px;padding:10px 20px;border-radius:8px;border:none;cursor:pointer;font-family:var(--font-body);font-weight:700;font-size:14px;transition:all .2s;outline:none;letter-spacing:.2px}
    .btn-primary{background:linear-gradient(135deg,var(--accent),#00d46e);color:#000;box-shadow:0 4px 20px rgba(0,255,135,.25)}
    .btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 28px rgba(0,255,135,.4)}
    .btn-secondary{background:var(--surface3);color:var(--text);border:1px solid var(--border2)}
    .btn-secondary:hover{background:var(--border2);border-color:var(--accent)}
    .btn-ghost{background:transparent;color:var(--text2);border:1px solid var(--border)}
    .btn-ghost:hover{background:var(--surface3);color:var(--text)}
    .btn-danger{background:rgba(255,77,109,.12);color:var(--red);border:1px solid rgba(255,77,109,.3)}
    .btn-danger:hover{background:rgba(255,77,109,.22)}
    .card{background:rgba(10,18,35,0.82);border:1px solid var(--border);border-radius:12px;padding:20px;backdrop-filter:blur(4px)}
    .modal-overlay{position:fixed;inset:0;background:rgba(5,10,8,.88);backdrop-filter:blur(10px);z-index:1000;display:flex;align-items:center;justify-content:center;padding:20px;animation:fadeIn .2s ease}
    .modal{background:rgba(9,16,30,0.96);border:1px solid var(--border2);border-radius:16px;max-width:860px;width:100%;max-height:90vh;overflow-y:auto;position:relative;animation:slideIn .3s ease;backdrop-filter:blur(12px)}
    .form-group{display:flex;flex-direction:column;gap:6px}
    .form-label{font-size:11px;font-weight:700;color:var(--text2);text-transform:uppercase;letter-spacing:.8px}
    .form-input{background:rgba(13,20,38,0.9);border:1px solid var(--border2);border-radius:8px;padding:10px 14px;color:var(--text);font-size:14px;transition:border-color .2s}
    .form-input:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 2px rgba(0,255,135,.08)}
    .form-input.error{border-color:var(--red)}
    .form-error{font-size:12px;color:var(--red)}
    .tab-bar{display:flex;gap:4px;background:var(--surface2);border:1px solid var(--border);border-radius:10px;padding:4px}
    .tab-btn{flex:1;padding:8px 14px;border-radius:7px;border:none;cursor:pointer;font-family:var(--font-body);font-weight:700;font-size:13px;transition:all .2s;background:transparent;color:var(--text2)}
    .tab-btn.active{background:var(--surface3);color:var(--accent);border:1px solid var(--border2)}
    .tab-btn:hover:not(.active){color:var(--text)}
    .section-title{font-size:22px;font-weight:800;letter-spacing:-.3px;color:var(--text)}
    .section-subtitle{font-size:13px;color:var(--text2);margin-top:4px;font-weight:500}
    .nav-item{display:flex;align-items:center;gap:10px;padding:10px 14px;border-radius:8px;cursor:pointer;font-size:13px;font-weight:600;color:var(--text2);transition:all .2s;border:none;background:transparent;width:100%;text-align:left}
    .nav-item:hover{background:var(--surface3);color:var(--text)}
    .nav-item.active{background:rgba(0,255,135,.08);color:var(--accent);border:1px solid rgba(0,255,135,.18)}
    .score-bar{height:6px;border-radius:3px;transition:width .5s ease}
    .plan-card{background:rgba(10,18,35,0.8);border:1px solid var(--border);border-radius:14px;padding:24px;cursor:pointer;transition:all .2s;position:relative;overflow:hidden;backdrop-filter:blur(6px)}
    .plan-card:hover{border-color:var(--accent);transform:translateY(-2px);box-shadow:0 8px 30px rgba(0,255,135,.1)}
    .plan-card.selected{border-color:var(--accent);background:rgba(0,255,135,.04);box-shadow:0 0 24px rgba(0,255,135,.12)}
    .plan-popular::before{content:'MOST POPULAR';position:absolute;top:14px;right:-24px;background:var(--accent);color:#000;font-size:10px;font-weight:800;padding:3px 28px;transform:rotate(45deg);letter-spacing:.5px}
    table{width:100%;border-collapse:collapse}
    th{text-align:left;padding:10px 14px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.7px;color:var(--text2);border-bottom:1px solid var(--border)}
    td{padding:12px 14px;font-size:13px;border-bottom:1px solid var(--border);vertical-align:middle}
    tr:last-child td{border-bottom:none}
    tr:hover td{background:var(--surface3)}
    .pipeline-bar{height:28px;border-radius:6px;overflow:hidden;display:flex}
    .kpi-card{background:rgba(10,18,35,0.8);border:1px solid var(--border);border-radius:12px;padding:18px 20px;backdrop-filter:blur(4px)}
    .kpi-value{font-size:36px;font-weight:800;letter-spacing:-1px}
    .kpi-label{font-size:11px;color:var(--text2);font-weight:700;margin-top:2px;text-transform:uppercase;letter-spacing:.6px}
  `}</style>
);

// ── Constants ──────────────────────────────────────────────────────────────
const POSITIONS = ["Goalkeeper","Centre-Back","Right-Back","Left-Back","Defensive Mid","Central Mid","Attacking Mid","Right Wing","Left Wing","Centre-Forward","Striker"];
const PLAYING_LEVELS = ["Sunday League","Amateur","Semi-Professional","Professional","International"];
const NATIONALITIES = ["English","Spanish","French","German","Brazilian","Argentine","Dutch","Portuguese","Italian","Belgian","Uruguayan","Colombian","Mexican","American","Japanese","South Korean","Nigerian","Ghanaian","Senegalese","Ivorian","Moroccan","Egyptian","Algerian","Cameroonian","Other"];
const FORMATIONS = ["4-4-2","4-3-3","4-2-3-1","4-5-1","3-5-2","3-4-3","5-3-2","5-4-1","4-1-4-1","4-4-1-1","3-4-2-1","4-3-2-1","4-2-2-2","4-3-1-2","3-6-1","4-6-0","5-2-3","4-1-2-3","3-3-4","4-4-1-1 (Flat)","4-2-4","3-5-1-1","4-1-3-2","5-1-4","4-0-6"];
const STYLES = ["Possession","Counter-Attack","Low Block","Tiki-Taka","Long Ball","Gegenpressing"];
const BUDGETS = ["Under £50k","£50k–£250k","£250k–£1M","£1M–£5M","£5M–£10M","£10M+"];
const OUTFIELD_ATTRS = ["Pace","Shooting","Passing","Dribbling","Defending","Physical","Vision","Work Rate"];
const GK_ATTRS = ["Reflexes","Handling","Positioning","Distribution","Aerial Ability","Command of Area","One-on-One","Concentration"];
const STATUSES = ["No Status","Watching","Trialling","Signed","Rejected"];

function isGK(pos){return pos==="Goalkeeper"}
function getAttrs(pos){return isGK(pos)?GK_ATTRS:OUTFIELD_ATTRS}
function getScoreColor(v){if(v>=80)return"#00FF87";if(v>=60)return"#00C6FF";if(v>=40)return"#FF6B35";return"#FF4D6D"}
function getRecommendation(score){if(score>=80)return"SIGN";if(score>=65)return"TRIAL";if(score>=50)return"WATCH";return"PASS"}
function recClass(r){return r==="SIGN"?"rec-sign":r==="TRIAL"?"rec-trial":r==="WATCH"?"rec-watch":"rec-pass"}
function calcScore(attrs){const vals=Object.values(attrs);return vals.length?Math.round(vals.reduce((a,b)=>a+b,0)/vals.length):0}
function fmtDate(d){return new Date(d).toLocaleDateString("en-GB",{day:"numeric",month:"short",year:"numeric"})}
function generateId(){return Math.random().toString(36).slice(2,10)}

// ── Seed Data ──────────────────────────────────────────────────────────────
const SEED_PLAYERS = [
  {id:"p1",name:"Marcus Webb",age:22,nationality:"English",position:"Centre-Forward",playingLevel:"Semi-Professional",club:"FC Northgate",appearances:28,goals:14,assists:7,cleanSheets:0,goalsConceded:0,attributes:{Pace:78,Shooting:82,Passing:64,Dribbling:73,Defending:38,Physical:71,Vision:68,WorkRate:75},scoutNotes:"Excellent movement in the box. Clinical finisher. Could step up to professional level.",aiReport:"",status:"Trialling",marketValue:180000,scoutId:"scout1",scoutName:"James Harper",createdAt:"2025-01-15"},
  {id:"p2",name:"Alejandro Torres",age:24,nationality:"Spanish",position:"Attacking Mid",playingLevel:"Professional",club:"Valdemor CF",appearances:31,goals:8,assists:16,cleanSheets:0,goalsConceded:0,attributes:{Pace:72,Shooting:74,Passing:88,Dribbling:84,Defending:51,Physical:63,Vision:90,WorkRate:79},scoutNotes:"Exceptional vision. Dictates tempo effortlessly. Could be a gem at this level.",aiReport:"",status:"Watching",marketValue:350000,scoutId:"scout2",scoutName:"Laura Chen",createdAt:"2025-02-01"},
  {id:"p3",name:"Kwame Asante",age:26,nationality:"Ghanaian",position:"Centre-Back",playingLevel:"Semi-Professional",club:"Accra Stars FC",appearances:35,goals:3,assists:4,cleanSheets:0,goalsConceded:0,attributes:{Pace:69,Shooting:45,Passing:71,Dribbling:58,Defending:85,Physical:87,Vision:65,WorkRate:82},scoutNotes:"Dominant in the air. Commanding presence. Strong leadership qualities.",aiReport:"",status:"Signed",marketValue:200000,scoutId:"scout1",scoutName:"James Harper",createdAt:"2025-01-20"},
  {id:"p4",name:"Oliver Marsh",age:20,nationality:"English",position:"Goalkeeper",playingLevel:"Amateur",club:"Redhill United",appearances:24,goals:0,assists:0,cleanSheets:12,goalsConceded:22,attributes:{Reflexes:80,Handling:74,Positioning:72,Distribution:68,AerialAbility:75,CommandOfArea:70,OneOnOne:77,Concentration:78},scoutNotes:"Outstanding reflexes for his age. Reads the game well. Needs work on distribution.",aiReport:"",status:"Watching",marketValue:90000,scoutId:"scout2",scoutName:"Laura Chen",createdAt:"2025-02-10"},
  {id:"p5",name:"Rafael Dominguez",age:19,nationality:"Argentine",position:"Right Wing",playingLevel:"Semi-Professional",club:"Rosario Juniors B",appearances:22,goals:6,assists:9,cleanSheets:0,goalsConceded:0,attributes:{Pace:88,Shooting:70,Passing:72,Dribbling:86,Defending:40,Physical:61,Vision:74,WorkRate:68},scoutNotes:"Raw talent. Electric on the ball. Could be unplayable with proper coaching.",aiReport:"",status:"No Status",marketValue:150000,scoutId:"scout3",scoutName:"Tom Bradley",createdAt:"2025-02-20"},
];

const SEED_SCOUTS = [
  {id:"scout1",name:"James Harper",email:"j.harper@scoutara.com"},
  {id:"scout2",name:"Laura Chen",email:"l.chen@scoutara.com"},
  {id:"scout3",name:"Tom Bradley",email:"t.bradley@scoutara.com"},
];

// ── Radar Chart ────────────────────────────────────────────────────────────
function RadarChart({attrs,size=200}){
  const keys=Object.keys(attrs);const vals=Object.values(attrs);
  const n=keys.length;const cx=size/2;const cy=size/2;const r=(size/2)-30;
  const angle=(i)=>(-Math.PI/2)+(2*Math.PI*i/n);
  const pt=(i,pct)=>{const a=angle(i);return[cx+pct*r*Math.cos(a),cy+pct*r*Math.sin(a)]};
  const polyPts=vals.map((v,i)=>pt(i,v/100)).map(([x,y])=>`${x},${y}`).join(" ");
  const gridLevels=[0.2,0.4,0.6,0.8,1];
  return(
    <svg width={size} height={size} style={{overflow:"visible"}}>
      {gridLevels.map(l=>{
        const gPts=keys.map((_,i)=>pt(i,l)).map(([x,y])=>`${x},${y}`).join(" ");
        return <polygon key={l} points={gPts} fill="none" stroke="rgba(255,255,255,0.06)" strokeWidth="1"/>;
      })}
      {keys.map((_,i)=>{const[x,y]=pt(i,1);return<line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke="rgba(255,255,255,0.08)" strokeWidth="1"/>})}
      <polygon points={polyPts} fill="rgba(0,255,135,0.2)" stroke="var(--accent)" strokeWidth="2"/>
      {vals.map((v,i)=>{const[x,y]=pt(i,v/100);return<circle key={i} cx={x} cy={y} r={3} fill="var(--accent)"/>})}
      {keys.map((k,i)=>{
        const a=angle(i);const lx=cx+(r+18)*Math.cos(a);const ly=cy+(r+18)*Math.sin(a);
        return<text key={i} x={lx} y={ly} textAnchor="middle" dominantBaseline="middle" fontSize="9" fill="var(--text2)" fontFamily="-apple-system,BlinkMacSystemFont,sans-serif">{k.length>8?k.slice(0,7)+"…":k}</text>;
      })}
    </svg>
  );
}

// ── AI Report Generator (calls Anthropic API) ──────────────────────────────
// ── AI helper — routes through secure Vercel serverless function ───────────
async function callAI(prompt, maxTokens=1000){
  try{
    const res=await fetch("/api/chat",{
      method:"POST",
      headers:{"Content-Type":"application/json"},
      body:JSON.stringify({prompt, max_tokens:maxTokens}),
    });
    if(res.status===404){
      // API route not yet configured — AI not available
      throw new Error("AI_UNAVAILABLE");
    }
    if(!res.ok){
      const err=await res.json().catch(()=>({}));
      throw new Error(err.error||"Request failed");
    }
    const data=await res.json();
    return data.content||"Unable to generate response.";
  } catch(e){
    if(e.message==="AI_UNAVAILABLE"){
      throw new Error("AI_UNAVAILABLE");
    }
    throw e;
  }
}

const AI_UNAVAILABLE_MSG = "AI reports are not yet configured. Once your Anthropic API key is added to Vercel, reports will generate automatically.";

async function generateAIReport(player, extraNotes=""){
  const gk=isGK(player.position);
  const attrStr=Object.entries(player.attributes).map(([k,v])=>`${k}: ${v}/100`).join(", ");
  const statsStr=gk?`Clean Sheets: ${player.cleanSheets}, Goals Conceded: ${player.goalsConceded}`:`Goals: ${player.goals}, Assists: ${player.assists}, Appearances: ${player.appearances}`;
  const prompt=gk
    ?`You are an elite football scout. Write a professional 300-word, 4-paragraph scouting report for a goalkeeper named ${player.name} (age ${player.age}, ${player.nationality}, currently at ${player.club}, ${player.playingLevel} level). Stats: ${statsStr}. Attributes: ${attrStr}. Scout observations: "${extraNotes||player.scoutNotes||"No additional notes"}". Structure: Para 1 - Shot-stopping ability; Para 2 - Distribution and command of area; Para 3 - Weaknesses and areas for development; Para 4 - Final verdict and recommendation. Write in a professional, analytical tone. Do not use bullet points.`
    :`You are an elite football scout. Write a professional 300-word, 4-paragraph scouting report for ${player.name} (age ${player.age}, ${player.nationality}, ${player.position}, currently at ${player.club}, ${player.playingLevel} level). Stats: ${statsStr}. Attributes: ${attrStr}. Scout observations: "${extraNotes||player.scoutNotes||"No additional notes"}". Structure: Para 1 - Playing style and technical ability; Para 2 - Key strengths; Para 3 - Weaknesses and development areas; Para 4 - Final verdict and recommendation. Write in a professional, analytical tone. Do not use bullet points.`;
  try{
    return await callAI(prompt, 1000);
  } catch(e){
    if(e.message==="AI_UNAVAILABLE") return AI_UNAVAILABLE_MSG;
    return "Unable to generate report. Please try again.";
  }
}

async function generateSquadAnalysis(players, formation, style, budget){
  const playerList=players.map(p=>`${p.name} (${p.position}, age ${p.age}, score ${calcScore(p.attributes)})`).join("; ");
  const prompt=`You are a football analytics director. Analyse this squad for ${formation} formation with ${style} playing style and ${budget} transfer budget. Players: ${playerList||"No players assigned yet"}. Write a 6-section analysis covering: 1) Squad Overview, 2) Positional Gaps, 3) Age Profile, 4) Attribute Deficiencies, 5) Transfer Priorities (suggest 3 specific player profiles with cost estimates and rationale), 6) Quick Wins. Be specific, professional, and data-driven. Use section headers. Keep it under 500 words.`;
  try{
    return await callAI(prompt, 1200);
  } catch(e){
    if(e.message==="AI_UNAVAILABLE") return AI_UNAVAILABLE_MSG;
    return "Unable to generate analysis. Please try again.";
  }
}

// ── Trial Expired — Self-Serve Upgrade Flow ───────────────────────────────
function TrialExpiredUpgrade({user, onActivated, onBack}){
  const PLANS=[
    {id:"starter",  name:"Starter",  monthly:49, yearly:39,  color:"var(--text2)", features:["1 login","Core scouting tools","Player database","AI reports"]},
    {id:"teampro",  name:"Team Pro", monthly:99, yearly:79,  color:"var(--accent)", popular:true, features:["Up to 5 scout logins","Scout leaderboard","Season summaries","All Starter features"]},
    {id:"clubpro",  name:"Club Pro", monthly:199,yearly:159, color:"var(--gold)",   features:["Unlimited logins","Dedicated manager","White-label PDFs","All Team Pro features"]},
  ];
  const fmtCard=v=>v.replace(/\D/g,"").replace(/(.{4})/g,"$1 ").trim().slice(0,19);
  const fmtExp=v=>{const d=v.replace(/\D/g,"");return d.length>=3?`${d.slice(0,2)}/${d.slice(2,4)}`:d};

  const[step,setStep]=useState(1); // 1=plan  2=payment  3=set-password  4=done
  const[billing,setBilling]=useState("monthly");
  const[plan,setPlan]=useState("teampro");
  const[card,setCard]=useState({num:"",expiry:"",cvv:"",name:"",terms:false});
  const[pw,setPw]=useState({newPw:"",confirmPw:""});
  const[errors,setErrors]=useState({});
  const[loading,setLoading]=useState(false);
  const[error,setError]=useState("");

  const selectedPlan = PLANS.find(p=>p.id===plan);
  const price = billing==="monthly" ? selectedPlan?.monthly : selectedPlan?.yearly;

  const validatePayment=()=>{
    const e={};
    if(!card.num||card.num.replace(/\s/g,"").length<16)e.num="Valid card number required";
    if(!card.expiry||card.expiry.length<5)e.expiry="MM/YY required";
    if(!card.cvv||card.cvv.length<3)e.cvv="CVV required";
    if(!card.name)e.name="Name on card required";
    if(!card.terms)e.terms="You must accept the terms";
    setErrors(e);return Object.keys(e).length===0;
  };

  const handlePayment=async()=>{
    if(!validatePayment())return;
    setLoading(true);setError("");
    // Payment processing (Stripe will hook in here later)
    // For now simulate success and update Supabase user metadata
    try{
      const token=supabase.auth.getSession()?.access_token;
      if(token){
        await fetch(`${SUPABASE_URL}/auth/v1/user`,{
          method:"PUT",
          headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${token}`,"Content-Type":"application/json"},
          body:JSON.stringify({data:{
            plan,billing,
            is_trial:false,
            subscribed_at:new Date().toISOString(),
          }})
        });
      }
      setStep(3);
    }catch(e){setError("Payment processing failed. Please try again.");}
    setLoading(false);
  };

  const handleSetPassword=async()=>{
    if(pw.newPw.length<8){setErrors({newPw:"Min 8 characters"});return;}
    if(pw.newPw!==pw.confirmPw){setErrors({confirmPw:"Passwords do not match"});return;}
    setLoading(true);setError("");
    try{
      const token=supabase.auth.getSession()?.access_token;
      const r=await fetch(`${SUPABASE_URL}/auth/v1/user`,{
        method:"PUT",
        headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${token}`,"Content-Type":"application/json"},
        body:JSON.stringify({password:pw.newPw})
      });
      const d=await r.json();
      if(d.error){setErrors({newPw:d.error.message||"Failed to update password"});setLoading(false);return;}
      setStep(4);
    }catch(e){setError("Unable to set password. Please try again.");}
    setLoading(false);
  };

  const handleEnterApp=()=>{
    onActivated({
      ...user,
      plan,billing,
      isTrialExpired:false,
      isDemo:false,
      trialDaysLeft:undefined,
    });
  };

  return(
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",padding:20}}>
      <div style={{width:"100%",maxWidth:step===1?860:520}} className="slide-in">

        {/* Header */}
        <div style={{textAlign:"center",marginBottom:28}}>
          <div style={{fontWeight:900,fontSize:36,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
          <div style={{fontSize:12,color:"var(--text2)",letterSpacing:2,marginTop:4}}>SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div>
        </div>

        {/* Trial ended notice */}
        {step<4&&(
          <div style={{background:"rgba(0,255,135,.06)",border:"1px solid rgba(0,255,135,.18)",borderRadius:10,padding:"12px 16px",marginBottom:20,display:"flex",gap:12,alignItems:"center"}}>
            <div style={{fontSize:20}}>✓</div>
            <div>
              <div style={{fontWeight:700,fontSize:13,color:"var(--accent)"}}>Your data is safe and waiting</div>
              <div style={{fontSize:12,color:"var(--text2)",marginTop:2}}>All players, reports and analysis from your trial are preserved. Subscribe below to continue with the same account.</div>
            </div>
          </div>
        )}

        {/* Step indicator */}
        {step<4&&(
          <div style={{display:"flex",alignItems:"center",justifyContent:"center",gap:8,marginBottom:24}}>
            {["Choose Plan","Payment","Set Password"].map((s,i)=>(
              <div key={i} style={{display:"flex",alignItems:"center",gap:8}}>
                <div style={{width:26,height:26,borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,fontWeight:700,
                  background:step>i+1?"var(--green)":step===i+1?"var(--accent)":"var(--surface3)",
                  color:step>=i+1?"#000":"var(--text3)"}}>
                  {step>i+1?"✓":i+1}
                </div>
                <span style={{fontSize:12,color:step===i+1?"var(--text)":"var(--text3)",fontWeight:step===i+1?600:400}}>{s}</span>
                {i<2&&<div style={{width:28,height:1,background:step>i+1?"var(--green)":"var(--border)"}}/>}
              </div>
            ))}
          </div>
        )}

        {/* Step 1 — Plan selection */}
        {step===1&&(
          <div className="slide-in">
            <div className="card" style={{marginBottom:16}}>
              <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",flexWrap:"wrap",gap:12}}>
                <div style={{fontWeight:900,fontSize:20,color:"var(--text)"}}>YOUR TRIAL HAS ENDED — CHOOSE A PLAN</div>
                <div style={{display:"flex",gap:4,background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:4}}>
                  {["monthly","yearly"].map(b=>(
                    <button key={b} onClick={()=>setBilling(b)} style={{padding:"5px 14px",borderRadius:6,border:"none",cursor:"pointer",fontFamily:"var(--font-body)",fontWeight:700,fontSize:12,
                      background:billing===b?"var(--surface3)":"transparent",color:billing===b?"var(--text)":"var(--text2)"}}>
                      {b==="monthly"?"Monthly":"Yearly"}{b==="yearly"&&<span style={{color:"var(--green)",marginLeft:4,fontSize:10}}>-20%</span>}
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(250px,1fr))",gap:16,marginBottom:20}}>
              {PLANS.map(p=>(
                <div key={p.id} className={`plan-card${plan===p.id?" selected":""}${p.popular?" plan-popular":""}`} onClick={()=>setPlan(p.id)}>
                  <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:4}}>
                    <div style={{width:10,height:10,borderRadius:"50%",background:p.color}}/>
                    <div style={{fontWeight:800,fontSize:17,color:p.color}}>{p.name.toUpperCase()}</div>
                  </div>
                  <div style={{marginBottom:12}}>
                    <span style={{fontWeight:900,fontSize:32,color:p.color}}>£{billing==="monthly"?p.monthly:p.yearly}</span>
                    <span style={{color:"var(--text2)",fontSize:12}}>/mo</span>
                    {billing==="yearly"&&<div style={{fontSize:11,color:"var(--green)",marginTop:2}}>Save £{(p.monthly-p.yearly)*12}/yr</div>}
                  </div>
                  {p.features.map(f=><div key={f} style={{fontSize:12,color:"var(--text2)",padding:"2px 0",display:"flex",gap:6}}><span style={{color:p.color}}>✓</span>{f}</div>)}
                  {plan===p.id&&<div style={{marginTop:10,fontSize:12,color:"var(--accent)",fontWeight:700}}>✓ Selected</div>}
                </div>
              ))}
            </div>
            <div style={{display:"flex",gap:12}}>
              <button className="btn btn-ghost" onClick={onBack}>← Back to Sign In</button>
              <button className="btn btn-primary" style={{flex:1,padding:"12px 20px"}} onClick={()=>setStep(2)}>
                Continue to Payment →
              </button>
            </div>
          </div>
        )}

        {/* Step 2 — Payment */}
        {step===2&&(
          <div style={{display:"grid",gridTemplateColumns:"1fr 300px",gap:20}} className="slide-in">
            <div className="card" style={{borderColor:"var(--border2)"}}>
              <div style={{fontWeight:900,fontSize:20,letterSpacing:.5,marginBottom:20,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>PAYMENT DETAILS</div>
              {error&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{error}</div>}
              <div style={{display:"flex",flexDirection:"column",gap:14}}>
                <div className="form-group">
                  <label className="form-label">Card Number</label>
                  <input className={`form-input${errors.num?" error":""}`} value={card.num} onChange={e=>setCard({...card,num:fmtCard(e.target.value)})} placeholder="4242 4242 4242 4242" maxLength={19} style={{fontFamily:"var(--font-mono)"}}/>
                  {errors.num&&<span className="form-error">{errors.num}</span>}
                </div>
                <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
                  <div className="form-group">
                    <label className="form-label">Expiry MM/YY</label>
                    <input className={`form-input${errors.expiry?" error":""}`} value={card.expiry} onChange={e=>setCard({...card,expiry:fmtExp(e.target.value)})} placeholder="MM/YY" maxLength={5} style={{fontFamily:"var(--font-mono)"}}/>
                    {errors.expiry&&<span className="form-error">{errors.expiry}</span>}
                  </div>
                  <div className="form-group">
                    <label className="form-label">CVV</label>
                    <input className={`form-input${errors.cvv?" error":""}`} value={card.cvv} onChange={e=>setCard({...card,cvv:e.target.value.replace(/\D/g,"").slice(0,4)})} placeholder="•••" style={{fontFamily:"var(--font-mono)"}}/>
                    {errors.cvv&&<span className="form-error">{errors.cvv}</span>}
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Name on Card</label>
                  <input className={`form-input${errors.name?" error":""}`} value={card.name} onChange={e=>setCard({...card,name:e.target.value})} placeholder="JOHN SMITH"/>
                  {errors.name&&<span className="form-error">{errors.name}</span>}
                </div>
                <div style={{display:"flex",gap:8,padding:"10px 12px",background:"var(--surface2)",borderRadius:8,border:"1px solid var(--border)"}}>
                  {["256-bit SSL","PCI Compliant","Cancel Anytime"].map(b=><div key={b} style={{fontSize:11,color:"var(--text2)",flex:1,textAlign:"center",fontWeight:600}}>{b}</div>)}
                </div>
                <label style={{display:"flex",gap:10,alignItems:"flex-start",cursor:"pointer",fontSize:13,color:"var(--text2)"}}>
                  <input type="checkbox" checked={card.terms} onChange={e=>setCard({...card,terms:e.target.checked})} style={{marginTop:2}}/>
                  I agree to the Terms & Conditions and Privacy Policy
                </label>
                {errors.terms&&<span className="form-error">{errors.terms}</span>}
                <div style={{display:"flex",gap:10,marginTop:4}}>
                  <button className="btn btn-ghost" onClick={()=>setStep(1)}>← Back</button>
                  <button className="btn btn-primary" style={{flex:1,padding:"12px 20px"}} onClick={handlePayment} disabled={loading}>
                    {loading?<><span className="spinner"/>Processing…</>:`Pay £${billing==="yearly"?price*12:price} & Subscribe`}
                  </button>
                </div>
              </div>
            </div>
            {/* Order summary */}
            <div className="card" style={{borderColor:"var(--border2)",alignSelf:"start",position:"sticky",top:20}}>
              <div style={{fontWeight:800,fontSize:15,marginBottom:16}}>ORDER SUMMARY</div>
              <div style={{fontSize:13,color:"var(--text2)",marginBottom:4}}>{selectedPlan?.name} Plan</div>
              <div style={{fontWeight:900,fontSize:28,color:selectedPlan?.color,marginBottom:4}}>
                £{price}<span style={{fontSize:12,fontWeight:400,color:"var(--text2)"}}>/mo</span>
              </div>
              {billing==="yearly"&&<div style={{fontSize:12,color:"var(--green)",marginBottom:8}}>Billed £{price*12}/year — saving 20%</div>}
              <div style={{borderTop:"1px solid var(--border)",paddingTop:12,marginTop:8}}>
                <div style={{fontSize:12,color:"var(--accent)",fontWeight:700,marginBottom:4}}>✓ All trial data preserved</div>
                <div style={{fontSize:12,color:"var(--text2)"}}>Billing to: <span style={{color:"var(--text)"}}>{user.email}</span></div>
              </div>
            </div>
          </div>
        )}

        {/* Step 3 — Set password */}
        {step===3&&(
          <div className="card slide-in" style={{borderColor:"var(--accent)",maxWidth:480,margin:"0 auto"}}>
            <div style={{textAlign:"center",marginBottom:20}}>
              <div style={{fontSize:32,marginBottom:8}}>✓</div>
              <div style={{fontWeight:900,fontSize:20,color:"var(--accent)",marginBottom:6}}>SUBSCRIPTION ACTIVATED</div>
              <div style={{fontSize:13,color:"var(--text2)",lineHeight:1.7}}>
                One last step — set a personal password for your account.<br/>
                You'll use this to sign in from now on.
              </div>
            </div>
            {error&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{error}</div>}
            <div style={{background:"rgba(0,255,135,.06)",border:"1px solid rgba(0,255,135,.15)",borderRadius:8,padding:"10px 14px",fontSize:12,color:"var(--text2)",marginBottom:20}}>
              Account: <span style={{color:"var(--accent)",fontWeight:700}}>{user.email}</span>
            </div>
            <div style={{display:"flex",flexDirection:"column",gap:14}}>
              <div className="form-group">
                <label className="form-label">New Password</label>
                <input className={`form-input${errors.newPw?" error":""}`} type="password" value={pw.newPw} onChange={e=>setPw({...pw,newPw:e.target.value})} placeholder="Min 8 characters"/>
                {errors.newPw&&<span className="form-error">{errors.newPw}</span>}
              </div>
              <div className="form-group">
                <label className="form-label">Confirm Password</label>
                <input className={`form-input${errors.confirmPw?" error":""}`} type="password" value={pw.confirmPw} onChange={e=>setPw({...pw,confirmPw:e.target.value})} placeholder="Repeat password"
                  onKeyDown={e=>e.key==="Enter"&&handleSetPassword()}/>
                {errors.confirmPw&&<span className="form-error">{errors.confirmPw}</span>}
              </div>
              <button className="btn btn-primary" style={{width:"100%",padding:"12px 20px"}} onClick={handleSetPassword} disabled={loading}>
                {loading?<><span className="spinner"/>Setting password…</>:"Set Password & Enter SCOUTARA"}
              </button>
            </div>
          </div>
        )}

        {/* Step 4 — All done */}
        {step===4&&(
          <div className="card slide-in" style={{textAlign:"center",borderColor:"var(--accent)",maxWidth:480,margin:"0 auto",padding:40}}>
            <div style={{fontSize:48,marginBottom:16}}>✓</div>
            <div style={{fontWeight:900,fontSize:22,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent",marginBottom:8}}>
              YOU'RE ALL SET
            </div>
            <div style={{fontSize:14,color:"var(--text2)",lineHeight:1.8,marginBottom:24}}>
              <strong style={{color:"var(--text)"}}>{selectedPlan?.name}</strong> plan activated.<br/>
              Password updated. All your trial data is ready and waiting.<br/>
              Welcome to SCOUTARA.
            </div>
            <button className="btn btn-primary" style={{width:"100%",padding:"14px 20px",fontSize:15}} onClick={handleEnterApp}>
              Enter SCOUTARA →
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// ── Change Password Modal ─────────────────────────────────────────────────
function ChangePasswordModal({user, onClose}){
  const[newPw,setNewPw]=useState("");
  const[confirmPw,setConfirmPw]=useState("");
  const[loading,setLoading]=useState(false);
  const[error,setError]=useState("");
  const[success,setSuccess]=useState(false);

  const handleChange=async()=>{
    if(newPw.length<8){setError("Password must be at least 8 characters");return;}
    if(newPw!==confirmPw){setError("Passwords do not match");return;}
    setLoading(true);setError("");
    try{
      const token=supabase.auth.getSession()?.access_token;
      const r=await fetch(`${SUPABASE_URL}/auth/v1/user`,{
        method:"PUT",
        headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${token}`,"Content-Type":"application/json"},
        body:JSON.stringify({password:newPw})
      });
      const d=await r.json();
      if(d.error){setError(d.error.message||"Failed to update password");}
      else{setSuccess(true);}
    }catch(e){setError("Unable to update password. Please try again.");}
    setLoading(false);
  };

  return(
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal" style={{maxWidth:420}}>
        <div style={{padding:"20px 24px",borderBottom:"1px solid var(--border)",display:"flex",alignItems:"center",justifyContent:"space-between"}}>
          <div style={{fontWeight:800,fontSize:18,letterSpacing:.5}}>CHANGE PASSWORD</div>
          <button className="btn btn-ghost" style={{padding:"6px 10px"}} onClick={onClose}>✕</button>
        </div>
        <div style={{padding:24}}>
          {success?(
            <div style={{textAlign:"center",padding:"16px 0"}}>
              <div style={{fontSize:32,marginBottom:12}}>✓</div>
              <div style={{fontWeight:700,fontSize:16,color:"var(--accent)",marginBottom:8}}>Password Updated!</div>
              <div style={{fontSize:13,color:"var(--text2)",marginBottom:20}}>Your new password is active. Use it next time you sign in.</div>
              <button className="btn btn-primary" style={{width:"100%"}} onClick={onClose}>Done</button>
            </div>
          ):(
            <div style={{display:"flex",flexDirection:"column",gap:16}}>
              <div style={{fontSize:13,color:"var(--text2)",lineHeight:1.6}}>
                Set a personal password for your account: <span style={{color:"var(--accent)",fontWeight:600}}>{user.email}</span>
              </div>
              {error&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)"}}>{error}</div>}
              <div className="form-group">
                <label className="form-label">New Password</label>
                <input className="form-input" type="password" value={newPw} onChange={e=>setNewPw(e.target.value)} placeholder="Min 8 characters"/>
              </div>
              <div className="form-group">
                <label className="form-label">Confirm Password</label>
                <input className="form-input" type="password" value={confirmPw} onChange={e=>setConfirmPw(e.target.value)} placeholder="Repeat password"
                  onKeyDown={e=>e.key==="Enter"&&handleChange()}/>
              </div>
              <div style={{display:"flex",gap:10,marginTop:4}}>
                <button className="btn btn-ghost" onClick={onClose}>Cancel</button>
                <button className="btn btn-primary" style={{flex:1}} onClick={handleChange} disabled={loading}>
                  {loading?<><span className="spinner"/>Updating…</>:"Set New Password"}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Terms & Conditions Modal ─────────────────────────────────────────────
function TermsModal({onClose}){
  const today = new Date().toLocaleDateString("en-GB",{day:"numeric",month:"long",year:"numeric"});
  return(
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal" style={{maxWidth:700}}>
        <div style={{padding:"20px 28px",borderBottom:"1px solid var(--border)",display:"flex",alignItems:"center",justifyContent:"space-between",position:"sticky",top:0,background:"var(--surface)",zIndex:10}}>
          <div>
            <div style={{fontWeight:900,fontSize:20,letterSpacing:1,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>TERMS & CONDITIONS</div>
            <div style={{fontSize:11,color:"var(--text2)",marginTop:2}}>SCOUTARA Platform — Last updated {today}</div>
          </div>
          <button className="btn btn-ghost" style={{padding:"6px 12px",fontSize:13}} onClick={onClose}>Close</button>
        </div>
        <div style={{padding:"24px 28px",fontSize:13,lineHeight:1.8,color:"var(--text2)",display:"flex",flexDirection:"column",gap:24}}>

          {/* Intro */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>1. Agreement to Terms</div>
            <p>By creating an account or accessing SCOUTARA ("the Platform"), you agree to be bound by these Terms and Conditions. These terms form a legally binding agreement between you ("the User") and SCOUTARA ("we", "us", "our"). If you do not agree to these terms, you must not use the Platform. We reserve the right to update these terms at any time; continued use of the Platform following any changes constitutes your acceptance of the revised terms.</p>
          </div>

          {/* Data ownership */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>2. Data Ownership & User Responsibility</div>
            <p style={{marginBottom:10}}>You retain full ownership of all player data, scouting reports, notes, and other content you input into the Platform ("User Data"). By submitting User Data, you confirm and warrant that:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>You have the legal right to collect, store and process the personal information of any individual whose data you submit, including but not limited to players, coaches and club staff.</li>
              <li>Your use of the Platform complies with all applicable data protection laws, including the UK General Data Protection Regulation (UK GDPR), the Data Protection Act 2018, and any equivalent legislation in your jurisdiction.</li>
              <li>You have obtained all necessary consents from individuals whose personal data is entered into the Platform, where required by law.</li>
              <li>You will not input any data that is unlawfully obtained, defamatory, discriminatory, or in violation of any third party's rights.</li>
            </ul>
            <p style={{marginTop:10}}>SCOUTARA acts solely as a data processor on your behalf. We do not claim ownership of your User Data and will not share, sell or disclose it to third parties except as required by law or as described in our Privacy Policy. You are solely responsible for the accuracy, legality and appropriateness of all data you submit.</p>
          </div>

          {/* Player data & GDPR */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>3. Player Data & GDPR Compliance</div>
            <p style={{marginBottom:10}}>Player profiles submitted to the Platform contain personal data. As the data controller, you are solely responsible for:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>Ensuring a lawful basis exists for processing each player's personal data under UK GDPR Article 6.</li>
              <li>Providing individuals with appropriate privacy notices and information about how their data is used.</li>
              <li>Responding to any subject access requests, erasure requests or other data subject rights requests relating to data you have submitted.</li>
              <li>Ensuring that minors' data (individuals under 18) is handled in compliance with applicable child data protection requirements.</li>
            </ul>
            <p style={{marginTop:10}}>SCOUTARA will honour reasonable requests to delete your account and associated data. However, you remain responsible for any data you have exported, downloaded or otherwise extracted from the Platform.</p>
          </div>

          {/* AI-generated content */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>4. AI-Generated Content</div>
            <p style={{marginBottom:10}}>SCOUTARA uses artificial intelligence to generate scouting reports and squad analysis ("AI Content"). You acknowledge and agree that:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>AI Content is generated automatically based on data you provide and is for informational and advisory purposes only.</li>
              <li>AI Content does not constitute professional sports, legal, financial or medical advice.</li>
              <li>SCOUTARA makes no warranty as to the accuracy, completeness or fitness for purpose of any AI Content.</li>
              <li>You are solely responsible for any decisions made based on AI Content, including but not limited to player recruitment, contract negotiations, or transfer activity.</li>
              <li>You will not rely solely on AI Content when making decisions that materially affect a player's career or livelihood.</li>
            </ul>
          </div>

          {/* Payments & subscriptions */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>5. Subscriptions & Payments</div>
            <p style={{marginBottom:10}}>By subscribing to a paid plan, you agree to the following:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li><strong style={{color:"var(--text)"}}>Free Trial:</strong> New accounts include a 14-day free trial. You will not be charged during the trial period. If you do not cancel before the trial ends, your chosen subscription will activate and payment will be taken automatically.</li>
              <li><strong style={{color:"var(--text)"}}>Billing Cycle:</strong> Subscriptions are billed monthly or annually depending on your selection at sign-up. Annual plans are billed as a single upfront payment.</li>
              <li><strong style={{color:"var(--text)"}}>Automatic Renewal:</strong> Subscriptions renew automatically at the end of each billing period. You authorise us to charge your payment method on file for each renewal unless you cancel beforehand.</li>
              <li><strong style={{color:"var(--text)"}}>Cancellation:</strong> You may cancel your subscription at any time from your account settings. Cancellation takes effect at the end of the current billing period. No refunds are issued for partial periods unless required by applicable consumer law.</li>
              <li><strong style={{color:"var(--text)"}}>Price Changes:</strong> We reserve the right to change subscription prices. We will provide at least 30 days' notice before any price increase takes effect for existing subscribers.</li>
              <li><strong style={{color:"var(--text)"}}>Failed Payments:</strong> If a payment fails, we may suspend access to your account until payment is resolved. We will notify you of any failed payment and allow a reasonable period to update your payment details.</li>
              <li><strong style={{color:"var(--text)"}}>Refunds:</strong> All payments are non-refundable except where required by law. If you believe you have been charged in error, contact us within 14 days of the charge.</li>
            </ul>
          </div>

          {/* Acceptable use */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>6. Acceptable Use</div>
            <p style={{marginBottom:10}}>You agree not to use the Platform to:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>Submit false, misleading or fabricated player data or scouting reports.</li>
              <li>Harass, defame or discriminate against any individual on the basis of race, gender, age, disability, religion or any other protected characteristic.</li>
              <li>Circumvent, disable or interfere with any security or access control features of the Platform.</li>
              <li>Share your account credentials with individuals outside your authorised plan limit.</li>
              <li>Attempt to reverse-engineer, copy, reproduce or resell any part of the Platform or its AI functionality.</li>
              <li>Use the Platform in any way that violates applicable local, national or international law or regulation.</li>
            </ul>
          </div>

          {/* Intellectual property */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>7. Intellectual Property</div>
            <p>The SCOUTARA name, logo, design, software and all Platform content (excluding User Data) are the exclusive intellectual property of SCOUTARA. You are granted a limited, non-exclusive, non-transferable licence to use the Platform solely for its intended purpose during your active subscription. No rights are granted to copy, reproduce, distribute or create derivative works from any part of the Platform without our prior written consent.</p>
          </div>

          {/* Limitation of liability */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>8. Limitation of Liability</div>
            <p style={{marginBottom:10}}>To the fullest extent permitted by applicable law:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>SCOUTARA shall not be liable for any indirect, incidental, special, consequential or punitive damages arising from your use of the Platform.</li>
              <li>Our total aggregate liability to you in connection with these terms shall not exceed the total subscription fees paid by you in the 12 months preceding the claim.</li>
              <li>We do not guarantee uninterrupted or error-free access to the Platform and accept no liability for any losses arising from downtime, data loss or service interruptions.</li>
              <li>We are not responsible for the conduct of other users or for any third-party services integrated with the Platform.</li>
            </ul>
          </div>

          {/* Termination */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>9. Account Termination</div>
            <p>We reserve the right to suspend or terminate your account immediately, without notice, if we determine in our sole discretion that you have breached these terms, engaged in fraudulent activity, or used the Platform in a manner that causes harm to others or to SCOUTARA. Upon termination, your right to access the Platform ceases immediately. You remain responsible for any outstanding payments due at the time of termination.</p>
          </div>

          {/* Governing law */}
          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>10. Governing Law</div>
            <p>These Terms and Conditions are governed by and construed in accordance with the laws of England and Wales. Any disputes arising under or in connection with these terms shall be subject to the exclusive jurisdiction of the courts of England and Wales. If any provision of these terms is found to be unenforceable, the remaining provisions shall continue in full force and effect.</p>
          </div>

          {/* Contact */}
          <div style={{background:"rgba(0,255,135,.05)",border:"1px solid rgba(0,255,135,.15)",borderRadius:8,padding:"14px 16px"}}>
            <div style={{fontWeight:700,fontSize:13,color:"var(--accent)",marginBottom:4}}>Contact Us</div>
            <p style={{fontSize:12}}>For any questions regarding these Terms and Conditions, data requests, or billing enquiries, please contact us at <span style={{color:"var(--accent)"}}>legal@scoutara.com</span>. We aim to respond to all enquiries within 5 business days.</p>
          </div>

        </div>
        <div style={{padding:"16px 28px",borderTop:"1px solid var(--border)",display:"flex",justifyContent:"flex-end",position:"sticky",bottom:0,background:"var(--surface)"}}>
          <button className="btn btn-primary" style={{padding:"10px 32px"}} onClick={onClose}>I Understand — Close</button>
        </div>
      </div>
    </div>
  );
}

// ── Privacy Policy Modal ───────────────────────────────────────────────────
function PrivacyModal({onClose}){
  const today = new Date().toLocaleDateString("en-GB",{day:"numeric",month:"long",year:"numeric"});
  return(
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal" style={{maxWidth:700}}>
        <div style={{padding:"20px 28px",borderBottom:"1px solid var(--border)",display:"flex",alignItems:"center",justifyContent:"space-between",position:"sticky",top:0,background:"var(--surface)",zIndex:10}}>
          <div>
            <div style={{fontWeight:900,fontSize:20,letterSpacing:1,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>PRIVACY POLICY</div>
            <div style={{fontSize:11,color:"var(--text2)",marginTop:2}}>SCOUTARA Platform — Last updated {today}</div>
          </div>
          <button className="btn btn-ghost" style={{padding:"6px 12px",fontSize:13}} onClick={onClose}>Close</button>
        </div>
        <div style={{padding:"24px 28px",fontSize:13,lineHeight:1.8,color:"var(--text2)",display:"flex",flexDirection:"column",gap:24}}>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>1. Who We Are</div>
            <p>SCOUTARA ("we", "us", "our") operates the SCOUTARA football scouting platform. We are committed to protecting your personal data and handling it in accordance with the UK General Data Protection Regulation (UK GDPR) and the Data Protection Act 2018. For data protection enquiries, contact us at <span style={{color:"var(--accent)"}}>privacy@scoutara.com</span>.</p>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>2. Data We Collect</div>
            <p style={{marginBottom:10}}>We collect and process the following categories of personal data:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li><strong style={{color:"var(--text)"}}>Account Data:</strong> Name, email address, club name, password (encrypted), subscription plan and billing details.</li>
              <li><strong style={{color:"var(--text)"}}>User-Submitted Data:</strong> Player profiles, scouting reports, attribute ratings, scout notes and AI-generated content you create within the Platform.</li>
              <li><strong style={{color:"var(--text)"}}>Usage Data:</strong> Log data, IP addresses, browser type, pages visited, and actions taken within the Platform for security and service improvement purposes.</li>
              <li><strong style={{color:"var(--text)"}}>Payment Data:</strong> Payment is processed via third-party providers. We do not store full card numbers on our servers.</li>
            </ul>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>3. How We Use Your Data</div>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li>To provide, maintain and improve the SCOUTARA Platform and its features.</li>
              <li>To manage your account and process subscription payments.</li>
              <li>To send service-related communications such as billing confirmations and important updates.</li>
              <li>To ensure the security and integrity of the Platform.</li>
              <li>To comply with our legal obligations.</li>
            </ul>
            <p style={{marginTop:10}}>We will never sell your personal data to third parties. We do not use your data for advertising purposes.</p>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>4. Data Retention</div>
            <p>We retain your account data for as long as your account remains active. If you cancel your subscription and delete your account, we will delete your personal data within 30 days, except where we are required to retain it for legal or regulatory purposes (e.g. financial records, which are retained for 7 years under UK law).</p>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>5. Your Rights</div>
            <p style={{marginBottom:10}}>Under UK GDPR, you have the right to:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li><strong style={{color:"var(--text)"}}>Access:</strong> Request a copy of the personal data we hold about you.</li>
              <li><strong style={{color:"var(--text)"}}>Rectification:</strong> Request correction of inaccurate or incomplete data.</li>
              <li><strong style={{color:"var(--text)"}}>Erasure:</strong> Request deletion of your personal data ("right to be forgotten").</li>
              <li><strong style={{color:"var(--text)"}}>Restriction:</strong> Request that we restrict processing of your data in certain circumstances.</li>
              <li><strong style={{color:"var(--text)"}}>Portability:</strong> Request your data in a portable, machine-readable format.</li>
              <li><strong style={{color:"var(--text)"}}>Objection:</strong> Object to processing of your data for certain purposes.</li>
            </ul>
            <p style={{marginTop:10}}>To exercise any of these rights, contact us at <span style={{color:"var(--accent)"}}>privacy@scoutara.com</span>. We will respond within 30 days. You also have the right to lodge a complaint with the Information Commissioner's Office (ICO) at <span style={{color:"var(--accent)"}}>ico.org.uk</span>.</p>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>6. Third-Party Services</div>
            <p>We use the following third-party services to operate the Platform. Each has its own privacy policy and data processing terms:</p>
            <ul style={{paddingLeft:20,display:"flex",flexDirection:"column",gap:6}}>
              <li><strong style={{color:"var(--text)"}}>Supabase:</strong> Provides database and authentication infrastructure. Data is stored on servers in the EU/UK.</li>
              <li><strong style={{color:"var(--text)"}}>Anthropic (Claude AI):</strong> Powers AI scouting reports. Prompts including player data are sent to Anthropic's API. Please review Anthropic's privacy policy at anthropic.com.</li>
              <li><strong style={{color:"var(--text)"}}>Vercel:</strong> Hosts the Platform. May process IP and usage data for performance and security.</li>
            </ul>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>7. Security</div>
            <p>We implement appropriate technical and organisational measures to protect your personal data against unauthorised access, alteration, disclosure or destruction. These include encrypted data transmission (256-bit SSL/TLS), row-level security on our database, and access controls. However, no method of transmission over the internet is 100% secure and we cannot guarantee absolute security.</p>
          </div>

          <div>
            <div style={{fontWeight:800,fontSize:14,color:"var(--text)",marginBottom:8,textTransform:"uppercase",letterSpacing:.5}}>8. Cookies</div>
            <p>We use essential session cookies to keep you logged in and maintain your platform session. We do not use tracking, advertising or analytics cookies. No third-party cookies are placed on your device through the Platform.</p>
          </div>

          <div style={{background:"rgba(0,255,135,.05)",border:"1px solid rgba(0,255,135,.15)",borderRadius:8,padding:"14px 16px"}}>
            <div style={{fontWeight:700,fontSize:13,color:"var(--accent)",marginBottom:4}}>Data Protection Contact</div>
            <p style={{fontSize:12}}>For all data protection matters, subject access requests or privacy concerns, contact us at <span style={{color:"var(--accent)"}}>privacy@scoutara.com</span>. You may also write to us at our registered address. We aim to acknowledge all requests within 72 hours.</p>
          </div>

        </div>
        <div style={{padding:"16px 28px",borderTop:"1px solid var(--border)",display:"flex",justifyContent:"flex-end",position:"sticky",bottom:0,background:"var(--surface)"}}>
          <button className="btn btn-primary" style={{padding:"10px 32px"}} onClick={onClose}>I Understand — Close</button>
        </div>
      </div>
    </div>
  );
}

// ── Auth Pages ─────────────────────────────────────────────────────────────
function AuthPage({onAuth}){
  const[mode,setMode]=useState("signin"); // signin | trial | create
  const[plan,setPlan]=useState(null);
  const[showTerms,setShowTerms]=useState(false);
  const[showPrivacy,setShowPrivacy]=useState(false);
  const[billing,setBilling]=useState("monthly");
  const[step,setStep]=useState(1);
  const[form,setForm]=useState({email:"",password:"",name:"",club:"",cardNum:"",expiry:"",cvv:"",cardName:"",terms:false});
  const[errors,setErrors]=useState({});
  const[loading,setLoading]=useState(false);
  const[authError,setAuthError]=useState("");

  const plans=[
    {id:"starter",name:"Starter",monthly:49,yearly:39,features:["1 login","Core scouting tools","Player database","AI reports","No scout management"],color:"var(--text2)"},
    {id:"teampro",name:"Team Pro",monthly:99,yearly:79,features:["Up to 5 scout logins","Scout leaderboard","Season summaries","All Starter features","Priority support"],color:"var(--accent)",popular:true},
    {id:"clubpro",name:"Club Pro",monthly:199,yearly:159,features:["Unlimited scout logins","Dedicated manager","White-label PDFs","All Team Pro features","Custom branding"],color:"var(--gold)"},
  ];

  const trialEnd=new Date(Date.now()+14*86400000);
  const fmtCard=v=>v.replace(/\D/g,"").replace(/(.{4})/g,"$1 ").trim().slice(0,19);
  const fmtExp=v=>{const d=v.replace(/\D/g,"");return d.length>=3?`${d.slice(0,2)}/${d.slice(2,4)}`:d};

  // ── Master owner credentials ─────────────────────────────────────────────
  const MASTER_EMAIL    = "admin@scoutara.com";
  const MASTER_PASSWORD = "Scoutara@Master2024!";

  const isTrialKey = (pw) => TRIAL_KEYS.includes(pw.trim().toUpperCase());

  const validate=()=>{
    const e={};
    if(!form.email||!form.email.includes("@"))e.email="Valid email required";
    if(!form.password||form.password.length<6)e.password="Min 6 characters";
    if(mode==="create"&&!isTrialKey(form.password)){
      if(!form.name)e.name="Name required";
      if(!form.club)e.club="Club name required";
      if(step===3){
        if(!form.cardNum||form.cardNum.replace(/\s/g,"").length<16)e.cardNum="Valid card number required";
        if(!form.expiry||form.expiry.length<5)e.expiry="MM/YY required";
        if(!form.cvv||form.cvv.length<3)e.cvv="CVV required";
        if(!form.cardName)e.cardName="Name on card required";
        if(!form.terms)e.terms="You must accept the terms";
      }
    }
    setErrors(e);return Object.keys(e).length===0;
  };

  // ── Supabase trial helpers ────────────────────────────────────────────────
  const getTrialRecord = async (email) => {
    const r = await fetch(
      `${SUPABASE_URL}/rest/v1/demo_trials?select=*&email=eq.${encodeURIComponent(email)}`,
      {headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${SUPABASE_KEY}`}}
    );
    const rows = await r.json();
    return Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
  };

  const createTrialRecord = async (email, trialKey) => {
    await fetch(`${SUPABASE_URL}/rest/v1/demo_trials`,{
      method:"POST",
      headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${SUPABASE_KEY}`,"Content-Type":"application/json","Prefer":"return=minimal"},
      body:JSON.stringify({email, trial_key:trialKey, first_login:new Date().toISOString()})
    });
  };

  const calcTrialStatus = (firstLoginISO) => {
    const firstLogin = new Date(firstLoginISO);
    const expiry = new Date(firstLogin.getTime() + TRIAL_DAYS*24*60*60*1000);
    const now = new Date();
    const daysUsed = Math.floor((now - firstLogin)/(1000*60*60*24));
    const daysLeft = Math.max(0, TRIAL_DAYS - daysUsed);
    const expired = now > expiry;
    const expiryStr = expiry.toLocaleDateString("en-GB",{day:"numeric",month:"long",year:"numeric"});
    return {expired, daysLeft, expiryStr, expiry};
  };

  // ── Sign In ───────────────────────────────────────────────────────────────
  const handleSignIn=async()=>{
    if(!form.email||!form.email.includes("@")){setErrors({email:"Valid email required"});return;}
    if(!form.password){setErrors({password:"Password required"});return;}
    setLoading(true);setAuthError("");

    // Master owner
    if(form.email.trim()===MASTER_EMAIL && form.password===MASTER_PASSWORD){
      onAuth({name:"App Owner",club:"SCOUTARA HQ",email:MASTER_EMAIL,plan:"clubpro",billing:"yearly",isMaster:true,
        supabaseUser:{id:"master-owner",user_metadata:{name:"App Owner",club:"SCOUTARA HQ",plan:"clubpro"}}});
      setLoading(false);return;
    }

    // Regular Supabase sign in
    const{data,error}=await supabase.auth.signInWithPassword({email:form.email.trim(),password:form.password});
    if(error){setAuthError(error.message);setLoading(false);return;}
    const u=data.user;

    // Check if this is a trial account
    const trialMeta = u?.user_metadata?.is_trial;
    if(trialMeta){
      try{
        const rec = await getTrialRecord(u.email);
        if(!rec){setAuthError("Trial record not found. Please contact support.");setLoading(false);return;}
        const ts = calcTrialStatus(rec.first_login);
        if(ts.expired){
          // Sign back out — trial over, show upgrade screen
          await supabase.auth.signOut();
          onAuth({
            name:u.user_metadata?.name||u.email.split("@")[0],
            club:u.user_metadata?.club||"",
            email:u.email,
            plan:"teampro",
            billing:"monthly",
            isTrialExpired:true,
            trialExpiry:ts.expiryStr,
            supabaseUser:u,
          });
          setLoading(false);return;
        }
        onAuth({
          name:u.user_metadata?.name||u.email.split("@")[0],
          club:u.user_metadata?.club||"My Club",
          email:u.email,
          plan:"teampro",billing:"monthly",
          isDemo:true,trialDaysLeft:ts.daysLeft,trialExpiry:ts.expiryStr,
          supabaseUser:u,
        });
      } catch(e){setAuthError("Unable to verify trial. Please try again.");setLoading(false);return;}
    } else {
      onAuth({
        name:u?.user_metadata?.name||form.email.split("@")[0],
        club:u?.user_metadata?.club||"My Club",
        email:u.email,
        plan:u?.user_metadata?.plan||"teampro",
        billing:u?.user_metadata?.billing||"monthly",
        supabaseUser:u,
      });
    }
    setLoading(false);
  };

  // ── Trial Sign Up (trial key as password) ─────────────────────────────────
  const handleTrialSignUp=async()=>{
    const e={};
    if(!form.email||!form.email.includes("@"))e.email="Valid email required";
    if(!form.name)e.name="Your name is required";
    if(!form.club)e.club="Club name is required";
    setErrors(e);
    if(Object.keys(e).length)return;
    setLoading(true);setAuthError("");

    const key = form.password.trim().toUpperCase();

    // Check key not already used
    try{
      const r = await fetch(
        `${SUPABASE_URL}/rest/v1/demo_trials?select=*&trial_key=eq.${encodeURIComponent(key)}`,
        {headers:{"apikey":SUPABASE_KEY,"Authorization":`Bearer ${SUPABASE_KEY}`}}
      );
      const rows = await r.json();
      if(Array.isArray(rows) && rows.length > 0){
        setAuthError("This trial key has already been used. Please contact us at hello@scoutara.com for a new key.");
        setLoading(false);return;
      }
    }catch(e){setAuthError("Unable to verify trial key. Please try again.");setLoading(false);return;}

    // Create Supabase account with a temporary password
    const tempPassword = key+"-"+form.email.split("@")[0];
    const{data,error}=await supabase.auth.signUp({
      email:form.email.trim(),
      password:tempPassword,
      options:{data:{name:form.name,club:form.club,plan:"teampro",billing:"monthly",is_trial:true}}
    });
    if(error){setAuthError(error.message);setLoading(false);return;}
    const u=data.user;

    // Record trial start
    await createTrialRecord(form.email.trim(), key);

    // Sign in immediately with the temp password
    await supabase.auth.signInWithPassword({email:form.email.trim(),password:tempPassword});

    const ts = calcTrialStatus(new Date().toISOString());
    onAuth({
      name:form.name,club:form.club,email:form.email.trim(),
      plan:"teampro",billing:"monthly",
      isDemo:true,trialDaysLeft:TRIAL_DAYS,trialExpiry:ts.expiryStr,
      supabaseUser:u,
    });
    setLoading(false);
  };

  // ── Full Account Sign Up ──────────────────────────────────────────────────
  const handleCreateAccount=async()=>{
    if(!validate())return;
    setLoading(true);setAuthError("");
    const{data,error}=await supabase.auth.signUp({
      email:form.email,password:form.password,
      options:{data:{name:form.name,club:form.club,plan:plan||"starter",billing}}
    });
    if(error){setAuthError(error.message);setLoading(false);return;}
    const u=data.user;
    onAuth({name:form.name,club:form.club,email:form.email,plan:plan||"starter",billing,supabaseUser:u});
    setLoading(false);
  };

  const handleNext=()=>{
    if(mode==="trial"){handleTrialSignUp();return;}
    if(step===1&&validate())setStep(2);
    else if(step===2&&plan)setStep(3);
    else if(step===3)handleCreateAccount();
  };

  if(mode==="signin"){
    return(
      <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",background:"transparent",padding:20}}>
        <div style={{width:"100%",maxWidth:440}} className="slide-in">
          <div style={{textAlign:"center",marginBottom:32}}>
            <div style={{fontWeight:900,fontSize:38,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
            <div style={{fontSize:12,color:"var(--text2)",letterSpacing:2,marginTop:4}}>SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div>
          </div>
          <div className="card" style={{borderColor:"var(--border2)"}}>
            <h2 style={{fontWeight:900,fontSize:22,letterSpacing:1,marginBottom:20,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>WELCOME BACK</h2>
            {authError&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{authError}</div>}
            <div style={{display:"flex",flexDirection:"column",gap:16}}>
              <div className="form-group">
                <label className="form-label">Email</label>
                <input className={`form-input${errors.email?" error":""}`} type="email" value={form.email} onChange={e=>setForm({...form,email:e.target.value})} placeholder="you@club.com"/>
                {errors.email&&<span className="form-error">{errors.email}</span>}
              </div>
              <div className="form-group">
                <label className="form-label">Password</label>
                <input className={`form-input${errors.password?" error":""}`} type="password" value={form.password} onChange={e=>setForm({...form,password:e.target.value})} placeholder="••••••••"
                  onKeyDown={e=>e.key==="Enter"&&handleSignIn()}/>
                {errors.password&&<span className="form-error">{errors.password}</span>}
              </div>
              <button className="btn btn-primary" style={{width:"100%",padding:"12px 20px",marginTop:4}} onClick={handleSignIn} disabled={loading}>
                {loading?<><span className="spinner"/>Signing in…</>:"Sign In"}
              </button>
              <div style={{textAlign:"center",fontSize:13,color:"var(--text2)"}}>
                Don't have an account? <span style={{color:"var(--accent)",cursor:"pointer"}} onClick={()=>setMode("create")}>Create one</span>
              </div>
              <div style={{textAlign:"center",fontSize:12,color:"var(--text2)",paddingTop:4,borderTop:"1px solid var(--border)"}}>
                Have a trial key? <span style={{color:"var(--accent2)",cursor:"pointer",fontWeight:700}} onClick={()=>{setMode("trial");setErrors({})}}>Start free trial →</span>
              </div>
            </div>
          </div>

        </div>
        <div style={{textAlign:"center",marginTop:16,fontSize:11,color:"var(--text3)"}}>
          <span style={{color:"var(--accent2)",cursor:"pointer"}} onClick={()=>setShowTerms(true)}>Terms & Conditions</span>
          <span style={{margin:"0 8px",color:"var(--text3)"}}>·</span>
          <span style={{color:"var(--accent2)",cursor:"pointer"}} onClick={()=>setShowPrivacy(true)}>Privacy Policy</span>
        </div>
      </div>
    );
  }

  // ── Trial key sign-up view ───────────────────────────────────────────────
  if(mode==="trial"){
    return(
      <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",padding:20}}>
        <div style={{width:"100%",maxWidth:460}} className="slide-in">
          <div style={{textAlign:"center",marginBottom:32}}>
            <div style={{fontWeight:900,fontSize:38,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
            <div style={{fontSize:12,color:"var(--text2)",letterSpacing:2,marginTop:4}}>SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div>
          </div>
          <div className="card" style={{borderColor:"var(--border2)"}}>
            <h2 style={{fontWeight:900,fontSize:22,letterSpacing:1,marginBottom:6,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>START FREE TRIAL</h2>
            <div style={{fontSize:13,color:"var(--text2)",marginBottom:20}}>Enter your trial key and create your account. Your 14-day Team Pro trial begins now.</div>
            {authError&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{authError}</div>}
            <div style={{display:"flex",flexDirection:"column",gap:14}}>
              <div className="form-group">
                <label className="form-label">Trial Key</label>
                <input className={`form-input${errors.password?" error":""}`} value={form.password}
                  onChange={e=>setForm({...form,password:e.target.value.toUpperCase()})}
                  placeholder="SCOUT-XXXXX-XXXXX" style={{fontFamily:"var(--font-mono)",letterSpacing:2,fontWeight:700}}/>
                {errors.password&&<span className="form-error">{errors.password}</span>}
                <div style={{fontSize:11,color:"var(--text2)",marginTop:4}}>Enter the trial key provided by SCOUTARA</div>
              </div>
              <div style={{borderTop:"1px solid var(--border)",paddingTop:14,display:"flex",flexDirection:"column",gap:14}}>
                <div className="form-group">
                  <label className="form-label">Your Name</label>
                  <input className={`form-input${errors.name?" error":""}`} value={form.name}
                    onChange={e=>setForm({...form,name:e.target.value})} placeholder="John Smith"/>
                  {errors.name&&<span className="form-error">{errors.name}</span>}
                </div>
                <div className="form-group">
                  <label className="form-label">Club Name</label>
                  <input className={`form-input${errors.club?" error":""}`} value={form.club}
                    onChange={e=>setForm({...form,club:e.target.value})} placeholder="FC United"/>
                  {errors.club&&<span className="form-error">{errors.club}</span>}
                </div>
                <div className="form-group">
                  <label className="form-label">Your Email</label>
                  <input className={`form-input${errors.email?" error":""}`} type="email" value={form.email}
                    onChange={e=>setForm({...form,email:e.target.value})} placeholder="you@yourclub.com"/>
                  {errors.email&&<span className="form-error">{errors.email}</span>}
                </div>
              </div>
              <div style={{background:"rgba(0,255,135,.06)",border:"1px solid rgba(0,255,135,.15)",borderRadius:8,padding:"10px 12px",fontSize:12,color:"var(--text2)",lineHeight:1.6}}>
                <span style={{color:"var(--accent)",fontWeight:700}}>14-day Team Pro trial</span> — full access to all features including AI reports, squad analysis, leaderboard and season summary. Your data is saved throughout and carried over when you subscribe.
              </div>
              <button className="btn btn-primary" style={{width:"100%",padding:"12px 20px"}} onClick={handleTrialSignUp} disabled={loading}>
                {loading?<><span className="spinner"/>Activating trial…</>:"Activate Trial"}
              </button>
              <div style={{textAlign:"center",fontSize:13,color:"var(--text2)"}}>
                Already have an account? <span style={{color:"var(--accent)",cursor:"pointer"}} onClick={()=>setMode("signin")}>Sign in</span>
              </div>
            </div>
          </div>
          {showTerms&&<TermsModal onClose={()=>setShowTerms(false)}/>}
          {showPrivacy&&<PrivacyModal onClose={()=>setShowPrivacy(false)}/>}
        </div>
      </div>
    );
  }

  // ── Create Account flow (3 steps) ─────────────────────────────────────────
  const plans=[
    {id:"starter",name:"Starter",monthly:49,yearly:39,features:["1 login","Core scouting tools","Player database","AI reports","No scout management"],color:"var(--text2)"},
    {id:"teampro",name:"Team Pro",monthly:99,yearly:79,features:["Up to 5 scout logins","Scout leaderboard","Season summaries","All Starter features","Priority support"],color:"var(--accent)",popular:true},
    {id:"clubpro",name:"Club Pro",monthly:199,yearly:159,features:["Unlimited scout logins","Dedicated manager","White-label PDFs","All Team Pro features","Custom branding"],color:"var(--gold)"},
  ];
  const trialEnd=new Date(Date.now()+14*86400000);

  return(
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",padding:20}}>
      <div style={{width:"100%",maxWidth:step===2?900:480}} className="slide-in">
        <div style={{textAlign:"center",marginBottom:32}}>
          <div style={{fontWeight:900,fontSize:38,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
          <div style={{fontSize:12,color:"var(--text2)",letterSpacing:2,marginTop:4}}>SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div>
        </div>
        {/* Step indicator */}
        <div style={{display:"flex",alignItems:"center",justifyContent:"center",gap:8,marginBottom:28}}>
          {["Account","Plan","Payment"].map((s,i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:8}}>
              <div style={{width:28,height:28,borderRadius:"50%",display:"flex",alignItems:"center",justifyContent:"center",fontSize:12,fontWeight:700,
                background:step>i+1?"var(--green)":step===i+1?"var(--accent)":"var(--surface3)",
                color:step>=i+1?"#000":"var(--text3)",border:`1px solid ${step>=i+1?"transparent":"var(--border)"}`}}>{step>i+1?"✓":i+1}</div>
              <span style={{fontSize:12,color:step===i+1?"var(--text)":"var(--text3)",fontWeight:step===i+1?600:400}}>{s}</span>
              {i<2&&<div style={{width:32,height:1,background:step>i+1?"var(--green)":"var(--border)"}}/>}
            </div>
          ))}
        </div>

        {step===1&&(
          <div className="card" style={{borderColor:"var(--border2)"}}>
            <h2 style={{fontWeight:900,fontSize:22,letterSpacing:1,marginBottom:20,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>CREATE ACCOUNT</h2>
            {authError&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{authError}</div>}
            <div style={{display:"flex",flexDirection:"column",gap:14}}>
              {[["name","Full Name","text","John Smith"],["club","Club Name","text","FC United"],["email","Email","email","you@club.com"],["password","Password","password","••••••••"]].map(([k,l,t,p])=>(
                <div key={k} className="form-group">
                  <label className="form-label">{l}</label>
                  <input className={`form-input${errors[k]?" error":""}`} type={t} value={form[k]} onChange={e=>setForm({...form,[k]:e.target.value})} placeholder={p}/>
                  {errors[k]&&<span className="form-error">{errors[k]}</span>}
                </div>
              ))}
              <button className="btn btn-primary" style={{width:"100%",padding:"12px 20px",marginTop:4}} onClick={handleNext}>Continue to Plans →</button>
              <div style={{textAlign:"center",fontSize:13,color:"var(--text2)"}}>
                Already have an account? <span style={{color:"var(--accent)",cursor:"pointer"}} onClick={()=>setMode("signin")}>Sign in</span>
              </div>
            </div>
          </div>
        )}

        {step===2&&(
          <div className="slide-in">
            <div className="card" style={{marginBottom:20,borderColor:"var(--border2)"}}>
              <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",flexWrap:"wrap",gap:12}}>
                <h2 style={{fontWeight:900,fontSize:22,letterSpacing:1,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>CHOOSE YOUR PLAN</h2>
                <div style={{display:"flex",gap:4,background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:4}}>
                  {["monthly","yearly"].map(b=>(
                    <button key={b} onClick={()=>setBilling(b)} style={{padding:"6px 16px",borderRadius:6,border:"none",cursor:"pointer",fontFamily:"var(--font-body)",fontWeight:700,fontSize:12,background:billing===b?"var(--surface3)":"transparent",color:billing===b?"var(--text)":"var(--text2)",transition:"all .2s"}}>
                      {b==="monthly"?"Monthly":"Yearly"}{b==="yearly"&&<span style={{color:"var(--green)",marginLeft:4,fontSize:10}}>-20%</span>}
                    </button>
                  ))}
                </div>
              </div>
            </div>
            <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fit,minmax(260px,1fr))",gap:16,marginBottom:20}}>
              {plans.map(p=>(
                <div key={p.id} className={`plan-card${plan===p.id?" selected":""}${p.popular?" plan-popular":""}`} onClick={()=>setPlan(p.id)}>
                  <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:4}}>
                    <div style={{width:10,height:10,borderRadius:"50%",background:p.color}}/>
                    <div style={{fontWeight:800,fontSize:18,color:p.color}}>{p.name.toUpperCase()}</div>
                  </div>
                  <div style={{marginBottom:16}}>
                    <span style={{fontWeight:900,fontSize:34,color:p.color}}>£{billing==="monthly"?p.monthly:p.yearly}</span>
                    <span style={{color:"var(--text2)",fontSize:13}}>/mo</span>
                    {billing==="yearly"&&<div style={{fontSize:11,color:"var(--green)",marginTop:2}}>Save £{(p.monthly-p.yearly)*12}/year</div>}
                  </div>
                  {p.features.map(f=><div key={f} style={{fontSize:12,color:"var(--text2)",padding:"3px 0",display:"flex",gap:6,alignItems:"center"}}><span style={{color:p.color}}>✓</span>{f}</div>)}
                  {plan===p.id&&<div style={{marginTop:12,fontSize:12,color:"var(--accent)",fontWeight:700}}>✓ Selected</div>}
                </div>
              ))}
            </div>
            <div style={{display:"flex",gap:12}}>
              <button className="btn btn-ghost" onClick={()=>setStep(1)}>← Back</button>
              <button className="btn btn-primary" disabled={!plan} style={{flex:1,opacity:plan?1:.5}} onClick={()=>plan&&setStep(3)}>Continue to Payment →</button>
            </div>
          </div>
        )}

        {step===3&&(
          <div style={{display:"grid",gridTemplateColumns:"1fr 320px",gap:20}} className="slide-in">
            <div className="card" style={{borderColor:"var(--border2)"}}>
              <h2 style={{fontWeight:900,fontSize:22,letterSpacing:1,marginBottom:20,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>PAYMENT DETAILS</h2>
              {authError&&<div style={{background:"rgba(255,77,109,.12)",border:"1px solid rgba(255,77,109,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--red)",marginBottom:14}}>{authError}</div>}
              <div style={{display:"flex",flexDirection:"column",gap:14}}>
                <div className="form-group">
                  <label className="form-label">Card Number</label>
                  <input className={`form-input${errors.cardNum?" error":""}`} value={form.cardNum} onChange={e=>setForm({...form,cardNum:fmtCard(e.target.value)})} placeholder="4242 4242 4242 4242" maxLength={19} style={{fontFamily:"var(--font-mono)"}}/>
                  {errors.cardNum&&<span className="form-error">{errors.cardNum}</span>}
                </div>
                <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
                  <div className="form-group">
                    <label className="form-label">Expiry MM/YY</label>
                    <input className={`form-input${errors.expiry?" error":""}`} value={form.expiry} onChange={e=>setForm({...form,expiry:fmtExp(e.target.value)})} placeholder="MM/YY" maxLength={5} style={{fontFamily:"var(--font-mono)"}}/>
                    {errors.expiry&&<span className="form-error">{errors.expiry}</span>}
                  </div>
                  <div className="form-group">
                    <label className="form-label">CVV</label>
                    <input className={`form-input${errors.cvv?" error":""}`} value={form.cvv} onChange={e=>setForm({...form,cvv:e.target.value.replace(/\D/g,"").slice(0,4)})} placeholder="•••" style={{fontFamily:"var(--font-mono)"}}/>
                    {errors.cvv&&<span className="form-error">{errors.cvv}</span>}
                  </div>
                </div>
                <div className="form-group">
                  <label className="form-label">Name on Card</label>
                  <input className={`form-input${errors.cardName?" error":""}`} value={form.cardName} onChange={e=>setForm({...form,cardName:e.target.value})} placeholder="JOHN SMITH"/>
                  {errors.cardName&&<span className="form-error">{errors.cardName}</span>}
                </div>
                <div style={{display:"flex",gap:8,padding:"12px 14px",background:"var(--surface2)",borderRadius:8,border:"1px solid var(--border)"}}>
                  {["256-bit SSL","PCI Compliant","Cancel Anytime"].map(b=><div key={b} style={{fontSize:11,color:"var(--text2)",flex:1,textAlign:"center",fontWeight:600}}>{b}</div>)}
                </div>
                <label style={{display:"flex",gap:10,alignItems:"flex-start",cursor:"pointer",fontSize:13,color:"var(--text2)"}}>
                  <input type="checkbox" checked={form.terms} onChange={e=>setForm({...form,terms:e.target.checked})} style={{marginTop:2}}/>
                  I agree to the <span style={{color:"var(--accent)",cursor:"pointer",textDecoration:"underline"}} onClick={e=>{e.preventDefault();setShowTerms(true)}}>Terms & Conditions</span> and <span style={{color:"var(--accent)",cursor:"pointer",textDecoration:"underline"}} onClick={e=>{e.preventDefault();setShowPrivacy(true)}}>Privacy Policy</span>
                </label>
                {errors.terms&&<span className="form-error">{errors.terms}</span>}
                <div style={{display:"flex",gap:12,marginTop:4}}>
                  <button className="btn btn-ghost" onClick={()=>setStep(2)}>← Back</button>
                  <button className="btn btn-primary" style={{flex:1,padding:"12px 20px"}} onClick={handleNext} disabled={loading}>
                    {loading?<><span className="spinner"/>Creating account…</>:"Start Free Trial"}
                  </button>
                </div>
              </div>
            </div>
            <div>
              <div className="card" style={{borderColor:"var(--border2)",position:"sticky",top:20}}>
                <div style={{fontWeight:800,fontSize:16,letterSpacing:.5,marginBottom:16}}>ORDER SUMMARY</div>
                {plan&&(()=>{const p=plans.find(x=>x.id===plan);return(
                  <>
                    <div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}>
                      <span style={{color:"var(--text2)",fontSize:13}}>{p.name} Plan</span>
                      <span style={{fontWeight:700}}>£{billing==="monthly"?p.monthly:p.yearly}/mo</span>
                    </div>
                    {billing==="yearly"&&<div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}>
                      <span style={{color:"var(--green)",fontSize:12}}>Annual discount</span>
                      <span style={{color:"var(--green)",fontSize:12}}>-20%</span>
                    </div>}
                    <div style={{borderTop:"1px solid var(--border)",padding:"12px 0",marginTop:8}}>
                      <div style={{fontSize:12,color:"var(--text2)",marginBottom:4}}>14-day free trial included</div>
                      <div style={{fontSize:12,color:"var(--text2)"}}>Trial ends: <span style={{color:"var(--accent)",fontWeight:700}}>{trialEnd.toLocaleDateString("en-GB",{day:"numeric",month:"short",year:"numeric"})}</span></div>
                      <div style={{fontSize:12,color:"var(--text2)",marginTop:4}}>First charge: <span style={{color:"var(--text)",fontWeight:700}}>£{billing==="monthly"?p.monthly:p.yearly*12}</span></div>
                    </div>
                  </>
                )})()}
              </div>
            </div>
          </div>
        )}
      </div>
      {showTerms&&<TermsModal onClose={()=>setShowTerms(false)}/>}
      {showPrivacy&&<PrivacyModal onClose={()=>setShowPrivacy(false)}/>}
    </div>
  );
}

// ── Submit Player Wizard ───────────────────────────────────────────────────
function SubmitPlayerWizard({onClose,onSubmit,scoutId,scoutName}){
  const[step,setStep]=useState(1);
  const[errors,setErrors]=useState({});
  const[aiLoading,setAiLoading]=useState(false);
  const[info,setInfo]=useState({name:"",age:"",nationality:"English",position:"Centre-Forward",playingLevel:"Semi-Professional",club:"",appearances:"",goals:"",assists:"",cleanSheets:"",goalsConceded:"",marketValue:""});
  const[attrs,setAttrs]=useState(Object.fromEntries(OUTFIELD_ATTRS.map(a=>[a,65])));
  const[notes,setNotes]=useState("");
  const[aiReport,setAiReport]=useState("");
  const prevPos=useRef(info.position);

  useEffect(()=>{
    if(isGK(info.position)!==isGK(prevPos.current)){
      setAttrs(Object.fromEntries(getAttrs(info.position).map(a=>[a,65])));
    }
    prevPos.current=info.position;
  },[info.position]);

  const validate1=()=>{
    const e={};
    if(!info.name)e.name="Required";
    if(!info.age||info.age<14||info.age>45)e.age="Age 14–45";
    if(!info.club)e.club="Required";
    if(!info.appearances)e.appearances="Required";
    setErrors(e);return!Object.keys(e).length;
  };

  const score=calcScore(attrs);
  const rec=getRecommendation(score);
  const gk=isGK(info.position);

  const handleGenerate=async()=>{
    setAiLoading(true);
    try{const r=await generateAIReport({...info,attributes:attrs,scoutNotes:notes});setAiReport(r);}
    catch{setAiReport("Unable to generate report. Please try again.");}
    setAiLoading(false);
  };

  const handleSubmit=()=>{
    const player={id:generateId(),name:info.name,age:parseInt(info.age),nationality:info.nationality,position:info.position,playingLevel:info.playingLevel,club:info.club,
      appearances:parseInt(info.appearances)||0,goals:parseInt(info.goals)||0,assists:parseInt(info.assists)||0,
      cleanSheets:parseInt(info.cleanSheets)||0,goalsConceded:parseInt(info.goalsConceded)||0,
      marketValue:parseInt((info.marketValue||"0").replace(/[^0-9]/g,""))||0,
      attributes:attrs,scoutNotes:notes,aiReport,status:"No Status",scoutId,scoutName,createdAt:new Date().toISOString()};
    onSubmit(player);onClose();
  };

  const steps=["Player Info","Attributes","Scout Report","Confirm & Submit"];
  return(
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal" style={{maxWidth:780}}>
        <div style={{padding:"20px 24px",borderBottom:"1px solid var(--border)",display:"flex",alignItems:"center",justifyContent:"space-between"}}>
          <div>
            <div style={{fontWeight:800,fontSize:20,letterSpacing:-.3}}>SUBMIT PLAYER</div>
            <div style={{fontSize:12,color:"var(--text2)",marginTop:2}}>Step {step} of 4 — {steps[step-1]}</div>
          </div>
          <button className="btn btn-ghost" style={{padding:"6px 10px"}} onClick={onClose}></button>
        </div>
        {/* Step bar */}
        <div style={{padding:"12px 24px",borderBottom:"1px solid var(--border)",display:"flex",gap:4}}>
          {steps.map((s,i)=>(
            <div key={i} style={{flex:1,height:3,borderRadius:2,background:step>i+1?"var(--green)":step===i+1?"var(--accent)":"var(--border)",transition:"background .3s"}}/>
          ))}
        </div>
        <div style={{padding:24}}>
          {step===1&&(
            <div className="slide-in" style={{display:"flex",flexDirection:"column",gap:14}}>
              {isGK(info.position)&&<div style={{background:"rgba(255,215,0,.1)",border:"1px solid rgba(255,215,0,.3)",borderRadius:8,padding:"10px 14px",fontSize:13,color:"var(--gold)",display:"flex",gap:8,alignItems:"center"}}> <strong>Gold GK Notice:</strong> Goalkeeper-specific attributes and stats will be used for this player.</div>}
              <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
                <div className="form-group" style={{gridColumn:"1/-1"}}>
                  <label className="form-label">Full Name</label>
                  <input className={`form-input${errors.name?" error":""}`} value={info.name} onChange={e=>setInfo({...info,name:e.target.value})} placeholder="Player's full name"/>
                  {errors.name&&<span className="form-error">{errors.name}</span>}
                </div>
                <div className="form-group">
                  <label className="form-label">Age</label>
                  <input className={`form-input${errors.age?" error":""}`} type="number" min={14} max={45} value={info.age} onChange={e=>setInfo({...info,age:e.target.value})} placeholder="22"/>
                  {errors.age&&<span className="form-error">{errors.age}</span>}
                </div>
                <div className="form-group">
                  <label className="form-label">Nationality</label>
                  <select className="form-input" value={info.nationality} onChange={e=>setInfo({...info,nationality:e.target.value})} style={{cursor:"pointer"}}>
                    {NATIONALITIES.map(n=><option key={n}>{n}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Position</label>
                  <select className="form-input" value={info.position} onChange={e=>setInfo({...info,position:e.target.value})} style={{cursor:"pointer"}}>
                    {POSITIONS.map(p=><option key={p}>{p}</option>)}
                  </select>
                </div>
                <div className="form-group">
                  <label className="form-label">Playing Level</label>
                  <select className="form-input" value={info.playingLevel} onChange={e=>setInfo({...info,playingLevel:e.target.value})} style={{cursor:"pointer"}}>
                    {PLAYING_LEVELS.map(l=><option key={l}>{l}</option>)}
                  </select>
                </div>
                <div className="form-group" style={{gridColumn:"1/-1"}}>
                  <label className="form-label">Current Club</label>
                  <input className={`form-input${errors.club?" error":""}`} value={info.club} onChange={e=>setInfo({...info,club:e.target.value})} placeholder="Club name"/>
                  {errors.club&&<span className="form-error">{errors.club}</span>}
                </div>
                <div className="form-group">
                  <label className="form-label">Appearances</label>
                  <input className={`form-input${errors.appearances?" error":""}`} type="number" value={info.appearances} onChange={e=>setInfo({...info,appearances:e.target.value})} placeholder="0"/>
                  {errors.appearances&&<span className="form-error">{errors.appearances}</span>}
                </div>
                {gk?(<>
                  <div className="form-group">
                    <label className="form-label">Clean Sheets</label>
                    <input className="form-input" type="number" value={info.cleanSheets} onChange={e=>setInfo({...info,cleanSheets:e.target.value})} placeholder="0"/>
                  </div>
                  <div className="form-group">
                    <label className="form-label">Goals Conceded</label>
                    <input className="form-input" type="number" value={info.goalsConceded} onChange={e=>setInfo({...info,goalsConceded:e.target.value})} placeholder="0"/>
                  </div>
                  <div className="form-group">
                    <label className="form-label">Assists (GK)</label>
                    <input className="form-input" type="number" value={info.assists} onChange={e=>setInfo({...info,assists:e.target.value})} placeholder="0"/>
                  </div>
                </>):(<>
                  <div className="form-group">
                    <label className="form-label">Goals</label>
                    <input className="form-input" type="number" value={info.goals} onChange={e=>setInfo({...info,goals:e.target.value})} placeholder="0"/>
                  </div>
                  <div className="form-group">
                    <label className="form-label">Assists</label>
                    <input className="form-input" type="number" value={info.assists} onChange={e=>setInfo({...info,assists:e.target.value})} placeholder="0"/>
                  </div>
                </>)}
                <div className="form-group">
                  <label className="form-label">Est. Market Value (£)</label>
                  <input className="form-input" value={info.marketValue} onChange={e=>setInfo({...info,marketValue:e.target.value})} placeholder="e.g. 250000"/>
                </div>
              </div>
            </div>
          )}

          {step===2&&(
            <div className="slide-in" style={{display:"grid",gridTemplateColumns:"1fr 200px",gap:24,alignItems:"start"}}>
              <div style={{display:"flex",flexDirection:"column",gap:12}}>
                <div style={{fontSize:13,color:"var(--text2)",marginBottom:4}}>Drag sliders to rate each attribute. Chart updates live.</div>
                {getAttrs(info.position).map(a=>(
                  <div key={a}>
                    <div style={{display:"flex",justifyContent:"space-between",marginBottom:4}}>
                      <label style={{fontSize:13,fontWeight:500}}>{a}</label>
                      <span style={{fontFamily:"var(--font-mono)",fontSize:13,color:getScoreColor(attrs[a]||65),fontWeight:700}}>{attrs[a]||65}</span>
                    </div>
                    <input type="range" min={1} max={100} value={attrs[a]||65}
                      onChange={e=>setAttrs({...attrs,[a]:parseInt(e.target.value)})}
                      style={{width:"100%",accentColor:getScoreColor(attrs[a]||65)}}/>
                  </div>
                ))}
              </div>
              <div style={{textAlign:"center",position:"sticky",top:0}}>
                <RadarChart attrs={attrs} size={190}/>
                <div style={{marginTop:8,fontWeight:800,fontSize:26,color:getScoreColor(score)}}>{score}</div>
                <div style={{fontSize:11,color:"var(--text2)",marginBottom:6}}>OVERALL</div>
                <span className={`rec-badge ${recClass(rec)}`}>{rec}</span>
              </div>
            </div>
          )}

          {step===3&&(
            <div className="slide-in" style={{display:"flex",flexDirection:"column",gap:16}}>
              <div className="form-group">
                <label className="form-label">Scout Observations</label>
                <textarea className="form-input" rows={5} value={notes} onChange={e=>setNotes(e.target.value)} placeholder="Share your observations... e.g. Outstanding movement off the ball, composed under pressure, strong aerial presence. Could step up a level with the right coaching environment."/>
              </div>
              <div style={{borderTop:"1px solid var(--border)",paddingTop:16}}>
                <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:12}}>
                  <div>
                    <div style={{fontSize:14,fontWeight:600}}>AI Report Generator</div>
                    <div style={{fontSize:12,color:"var(--text2)",marginTop:2}}>Powered by Claude AI — uses all data inputs</div>
                  </div>
                  <button className="btn btn-primary" onClick={handleGenerate} disabled={aiLoading} style={{gap:8}}>
                    {aiLoading?<><span className="spinner"/><span>Generating…</span></>:aiReport?" Regenerate":" Generate AI Report"}
                  </button>
                </div>
                {aiReport&&(
                  <div style={{background:"var(--surface2)",border:"1px solid var(--border2)",borderRadius:10,padding:16,fontSize:13,lineHeight:1.7,color:"var(--text2)"}}>
                    <div style={{fontWeight:700,fontSize:13,letterSpacing:.5,color:"var(--accent)",marginBottom:10}}>AI REPORT PREVIEW</div>
                    {aiReport}
                  </div>
                )}
              </div>
            </div>
          )}

          {step===4&&(
            <div className="slide-in" style={{display:"grid",gridTemplateColumns:"1fr 200px",gap:24}}>
              <div>
                <div style={{fontWeight:800,fontSize:20,letterSpacing:-.3,marginBottom:4}}>{info.name||"—"}</div>
                <div style={{display:"flex",gap:8,flexWrap:"wrap",marginBottom:16}}>
                  <span style={{fontSize:12,color:"var(--text2)"}}>{info.position} • {info.nationality} • Age {info.age}</span>
                </div>
                <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8,marginBottom:16}}>
                  {[
                    ["Club",info.club||"—"],["Level",info.playingLevel],
                    gk?["Clean Sheets",info.cleanSheets||0]:["Goals",info.goals||0],
                    gk?["Conceded",info.goalsConceded||0]:["Assists",info.assists||0],
                    ["Market Value",info.marketValue?`£${parseInt(info.marketValue).toLocaleString()}`:"—"],["Score",score],
                  ].map(([l,v])=>(
                    <div key={l} style={{background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:"10px 12px"}}>
                      <div style={{fontSize:10,color:"var(--text2)",textTransform:"uppercase",letterSpacing:.5,fontWeight:600}}>{l}</div>
                      <div style={{fontFamily:"var(--font-mono)",fontSize:16,fontWeight:700,color:l==="Score"?getScoreColor(score):"var(--text)",marginTop:2}}>{v}</div>
                    </div>
                  ))}
                </div>
                <div style={{display:"flex",gap:8,marginBottom:16}}>
                  <span className={`rec-badge ${recClass(rec)}`}>{rec}</span>
                  {aiReport&&<span style={{fontSize:12,background:"rgba(0,198,255,.12)",color:"var(--accent2)",border:"1px solid rgba(0,198,255,.3)",borderRadius:4,padding:"2px 8px",fontWeight:600}}> AI Report Ready</span>}
                </div>
                {notes&&<div style={{background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:12,fontSize:12,color:"var(--text2)",lineHeight:1.6}}><span style={{fontWeight:600,color:"var(--text)"}}>Scout Notes: </span>{notes.slice(0,200)}{notes.length>200?"…":""}</div>}
              </div>
              <div style={{textAlign:"center"}}>
                <RadarChart attrs={attrs} size={190}/>
                <div style={{fontWeight:800,fontSize:26,color:getScoreColor(score),marginTop:4}}>{score}</div>
              </div>
            </div>
          )}
        </div>
        <div style={{padding:"16px 24px",borderTop:"1px solid var(--border)",display:"flex",justifyContent:"space-between",gap:12}}>
          {step>1?<button className="btn btn-ghost" onClick={()=>setStep(s=>s-1)}>← Back</button>:<div/>}
          {step<4?<button className="btn btn-primary" onClick={()=>{if(step===1&&!validate1())return;setStep(s=>s+1);}}>Continue →</button>
          :<button className="btn btn-primary" onClick={handleSubmit} style={{gap:8}}> Submit Player</button>}
        </div>
      </div>
    </div>
  );
}

// ── AI Scouting Report Modal ───────────────────────────────────────────────
function AIReportModal({player,onClose,onUpdate}){
  const[aiReport,setAiReport]=useState(player.aiReport||"");
  const[loading,setLoading]=useState(false);
  const score=calcScore(player.attributes);
  const rec=getRecommendation(score);
  const gk=isGK(player.position);
  const attrKeys=Object.keys(player.attributes);
  const sorted=[...attrKeys].sort((a,b)=>player.attributes[b]-player.attributes[a]);
  const top=sorted[0],weak=sorted[sorted.length-1];

  const generate=async()=>{
    setLoading(true);
    try{const r=await generateAIReport(player);setAiReport(r);onUpdate({...player,aiReport:r});}
    catch{setAiReport("Unable to generate. Please retry.");}
    setLoading(false);
  };

  const exportPDF=()=>{
    const w=window.open("","_blank");
    w.document.write(`<html><head><title>SCOUTARA — ${player.name}</title><style>body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;padding:40px;color:#1a1a2e;max-width:800px;margin:0 auto}.header{border-bottom:3px solid #00b4cc;padding-bottom:16px;margin-bottom:24px}.brand{font-size:28px;font-weight:900;color:#00b4cc;letter-spacing:3px}.slogan{font-size:10px;color:#666;letter-spacing:2px;margin-top:2px}h1{font-size:24px;margin:0 0 4px}.meta{font-size:13px;color:#666}.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:20px 0}.stat{background:#f0f4f8;border-radius:8px;padding:12px;text-align:center}.stat-val{font-size:22px;font-weight:700;color:#00b4cc}.stat-lbl{font-size:10px;color:#666;text-transform:uppercase;margin-top:2px}.attrs{margin:20px 0}h2{font-size:16px;border-bottom:1px solid #e2e8f0;padding-bottom:8px;margin-bottom:12px}.attr-bar{margin-bottom:8px}.attr-name{font-size:12px;margin-bottom:3px}.bar{height:8px;background:#e2e8f0;border-radius:4px}.fill{height:8px;border-radius:4px}.report{margin-top:20px;line-height:1.7;font-size:14px;color:#333}.footer{margin-top:40px;padding-top:16px;border-top:1px solid #e2e8f0;font-size:11px;color:#999;text-align:center}</style></head><body>
    <div class="header"><div class="brand">SCOUTARA</div><div class="slogan">SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div></div>
    <h1>${player.name}</h1><div class="meta">${player.position} • ${player.nationality} • Age ${player.age} • ${player.club} • ${player.playingLevel}</div>
    <div class="stats">
      <div class="stat"><div class="stat-val">${score}</div><div class="stat-lbl">Score</div></div>
      <div class="stat"><div class="stat-val">${rec}</div><div class="stat-lbl">Recommendation</div></div>
      ${gk?`<div class="stat"><div class="stat-val">${player.cleanSheets}</div><div class="stat-lbl">Clean Sheets</div></div><div class="stat"><div class="stat-val">${player.goalsConceded}</div><div class="stat-lbl">Goals Conceded</div></div>`:
      `<div class="stat"><div class="stat-val">${player.goals}</div><div class="stat-lbl">Goals</div></div><div class="stat"><div class="stat-val">${player.assists}</div><div class="stat-lbl">Assists</div></div>`}
    </div>
    <div class="attrs"><h2>Attributes</h2>${attrKeys.map(k=>`<div class="attr-bar"><div class="attr-name">${k}: ${player.attributes[k]}/100</div><div class="bar"><div class="fill" style="width:${player.attributes[k]}%;background:${getScoreColor(player.attributes[k])}"></div></div></div>`).join("")}</div>
    ${aiReport?`<div class="report"><h2>AI Scouting Report</h2><p>${aiReport.replace(/\n\n/g,"</p><p>")}</p></div>`:""}
    ${player.scoutNotes?`<div class="report"><h2>Scout Observations</h2><p>${player.scoutNotes}</p></div>`:""}
    <div class="footer">Report generated by SCOUTARA — ${new Date().toLocaleDateString("en-GB",{day:"numeric",month:"long",year:"numeric"})} • Scout: ${player.scoutName}</div>
    </body></html>`);w.document.close();w.print();
  };

  return(
    <div className="modal-overlay" onClick={e=>e.target===e.currentTarget&&onClose()}>
      <div className="modal" style={{maxWidth:860}}>
        <div style={{padding:"20px 24px",borderBottom:"1px solid var(--border)",display:"flex",alignItems:"flex-start",justifyContent:"space-between",gap:12}}>
          <div>
            <div style={{fontWeight:800,fontSize:22,letterSpacing:-.3}}>{player.name}</div>
            <div style={{fontSize:13,color:"var(--text2)",marginTop:2}}>{player.position} • {player.nationality} • Age {player.age} • {player.club}</div>
            <div style={{display:"flex",gap:8,marginTop:8}}>
              <span className={`rec-badge ${recClass(rec)}`}>{rec}</span>
              {player.marketValue>0&&<span style={{fontSize:12,color:"var(--gold)",background:"rgba(255,215,0,.1)",border:"1px solid rgba(255,215,0,.2)",borderRadius:4,padding:"2px 8px",fontWeight:600}}>£{player.marketValue.toLocaleString()}</span>}
            </div>
          </div>
          <button className="btn btn-ghost" style={{padding:"6px 10px"}} onClick={onClose}></button>
        </div>
        <div style={{padding:24,display:"grid",gridTemplateColumns:"200px 1fr",gap:24}}>
          <div>
            <RadarChart attrs={player.attributes} size={190}/>
            <div style={{marginTop:12,display:"flex",flexDirection:"column",gap:6}}>
              <div style={{background:"rgba(0,255,135,.1)",border:"1px solid rgba(0,255,135,.2)",borderRadius:6,padding:"6px 10px",fontSize:12}}>
                <div style={{color:"var(--text2)",fontSize:10,textTransform:"uppercase",letterSpacing:.5,fontWeight:600}}>Top Attribute</div>
                <div style={{fontWeight:700,color:"var(--green)",marginTop:1}}>{top} ({player.attributes[top]})</div>
              </div>
              <div style={{background:"rgba(255,77,109,.1)",border:"1px solid rgba(255,77,109,.2)",borderRadius:6,padding:"6px 10px",fontSize:12}}>
                <div style={{color:"var(--text2)",fontSize:10,textTransform:"uppercase",letterSpacing:.5,fontWeight:600}}>Weakest Area</div>
                <div style={{fontWeight:700,color:"var(--red)",marginTop:1}}>{weak} ({player.attributes[weak]})</div>
              </div>
            </div>
          </div>
          <div>
            <div style={{display:"flex",flexDirection:"column",gap:8,marginBottom:20}}>
              {attrKeys.map(k=>(
                <div key={k} style={{display:"grid",gridTemplateColumns:"120px 1fr 36px",gap:8,alignItems:"center"}}>
                  <span style={{fontSize:12,color:"var(--text2)"}}>{k}</span>
                  <div style={{height:6,background:"var(--surface2)",borderRadius:3,overflow:"hidden"}}>
                    <div className="score-bar" style={{width:`${player.attributes[k]}%`,background:getScoreColor(player.attributes[k])}}/>
                  </div>
                  <span style={{fontSize:12,fontFamily:"var(--font-mono)",fontWeight:700,color:getScoreColor(player.attributes[k]),textAlign:"right"}}>{player.attributes[k]}</span>
                </div>
              ))}
            </div>
            <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:8,marginBottom:16}}>
              {[["Overall",score],gk?["Clean Sheets",player.cleanSheets]:["Goals",player.goals],gk?["Conceded",player.goalsConceded]:["Assists",player.assists],["Apps",player.appearances]].map(([l,v])=>(
                <div key={l} style={{background:"var(--surface2)",borderRadius:8,padding:"10px",textAlign:"center",border:"1px solid var(--border)"}}>
                  <div style={{fontFamily:"var(--font-mono)",fontSize:18,fontWeight:700,color:l==="Overall"?getScoreColor(score):"var(--text)"}}>{v}</div>
                  <div style={{fontSize:10,color:"var(--text2)",textTransform:"uppercase",letterSpacing:.5,marginTop:2}}>{l}</div>
                </div>
              ))}
            </div>
            {player.scoutNotes&&<div style={{background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:12,fontSize:13,color:"var(--text2)",lineHeight:1.6,marginBottom:16}}><span style={{fontWeight:600,color:"var(--text)"}}>Scout Notes: </span>{player.scoutNotes}</div>}
            <div style={{display:"flex",gap:8,marginBottom:12}}>
              <button className="btn btn-primary" onClick={generate} disabled={loading} style={{flex:1}}>
                {loading?<><span className="spinner"/>Generating…</>:aiReport?" Regenerate AI Report":" Generate AI Report"}
              </button>
              <button className="btn btn-secondary" onClick={exportPDF}> Export PDF</button>
            </div>
            {aiReport&&(
              <div style={{background:"var(--surface2)",border:"1px solid rgba(0,255,135,.2)",borderRadius:10,padding:16,fontSize:13,lineHeight:1.75,color:"var(--text2)",maxHeight:240,overflowY:"auto"}}>
                <div style={{fontWeight:700,fontSize:12,letterSpacing:.5,color:"var(--accent)",marginBottom:10}}>AI SCOUTING REPORT</div>
                {aiReport.split("\n\n").map((p,i)=><p key={i} style={{marginBottom:10}}>{p}</p>)}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Player Card ────────────────────────────────────────────────────────────
function PlayerCard({player,onViewReport,onStatusChange,isAdmin}){
  const score=calcScore(player.attributes);
  const rec=getRecommendation(score);
  const gk=isGK(player.position);
  const statusColors={Watching:"var(--gold)",Trialling:"var(--accent2)",Signed:"var(--green)",Rejected:"var(--red)","No Status":"var(--text3)"};
  return(
    <div className="card" style={{display:"flex",flexDirection:"column",gap:12,cursor:"pointer",transition:"border-color .2s"}}
      onMouseEnter={e=>e.currentTarget.style.borderColor="var(--border2)"} onMouseLeave={e=>e.currentTarget.style.borderColor="var(--border)"}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start"}}>
        <div>
          <div style={{fontWeight:700,fontSize:15}}>{player.name}</div>
          <div style={{fontSize:12,color:"var(--text2)",marginTop:2}}>{player.position} • {player.nationality} • {player.club}</div>
        </div>
        <div style={{textAlign:"right"}}>
          <div style={{fontWeight:800,fontSize:26,color:getScoreColor(score),lineHeight:1}}>{score}</div>
          <div style={{fontSize:10,color:"var(--text2)"}}>SCORE</div>
        </div>
      </div>
      <div style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:6}}>
        {[gk?["Clean Sheets",player.cleanSheets]:["Goals",player.goals],gk?["Conceded",player.goalsConceded]:["Assists",player.assists],["Apps",player.appearances]].map(([l,v])=>(
          <div key={l} style={{background:"var(--surface2)",borderRadius:6,padding:"6px 8px",textAlign:"center"}}>
            <div style={{fontFamily:"var(--font-mono)",fontSize:14,fontWeight:700}}>{v}</div>
            <div style={{fontSize:9,color:"var(--text2)",textTransform:"uppercase",letterSpacing:.5}}>{l}</div>
          </div>
        ))}
      </div>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <span className={`rec-badge ${recClass(rec)}`}>{rec}</span>
        {isAdmin?(
          <select value={player.status||"No Status"} onChange={e=>{e.stopPropagation();onStatusChange(player.id,e.target.value)}}
            style={{background:"var(--surface2)",border:"1px solid var(--border)",color:statusColors[player.status||"No Status"],borderRadius:6,padding:"3px 8px",fontSize:11,fontWeight:600,cursor:"pointer"}}>
            {STATUSES.map(s=><option key={s} value={s}>{s}</option>)}
          </select>
        ):<span className="status-badge" style={{background:`${statusColors[player.status||"No Status"]}22`,color:statusColors[player.status||"No Status"],border:`1px solid ${statusColors[player.status||"No Status"]}44`}}>{player.status||"No Status"}</span>}
      </div>
      <div style={{display:"flex",gap:8}}>
        <button className="btn btn-primary" style={{flex:1,padding:"8px 12px",fontSize:12}} onClick={()=>onViewReport(player)}> AI Report</button>
        {player.scoutName&&<div style={{fontSize:11,color:"var(--text3)",display:"flex",alignItems:"center"}}>Scout: {player.scoutName}</div>}
      </div>
    </div>
  );
}

// ── Head to Head Compare ───────────────────────────────────────────────────
function HeadToHead({players}){
  const[p1Id,setP1Id]=useState(players[0]?.id||"");
  const[p2Id,setP2Id]=useState(players[1]?.id||"");
  const p1=players.find(p=>p.id===p1Id);
  const p2=players.find(p=>p.id===p2Id);
  const getCommonAttrs=()=>{
    if(!p1||!p2)return[];
    const a1=Object.keys(p1.attributes),a2=Object.keys(p2.attributes);
    return a1.filter(a=>a2.includes(a));
  };
  const common=getCommonAttrs();
  return(
    <div style={{display:"flex",flexDirection:"column",gap:20}}>
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:16}}>
        {[["Player 1",p1Id,setP1Id],[" Player 2",p2Id,setP2Id]].map(([label,val,setVal])=>(
          <div key={label} className="form-group">
            <label className="form-label">{label}</label>
            <select className="form-input" value={val} onChange={e=>setVal(e.target.value)} style={{cursor:"pointer"}}>
              <option value="">Select player…</option>
              {players.map(p=><option key={p.id} value={p.id}>{p.name} — {p.position}</option>)}
            </select>
          </div>
        ))}
      </div>
      {p1&&p2&&(
        <div className="slide-in" style={{display:"grid",gridTemplateColumns:"1fr 80px 1fr",gap:0,background:"var(--surface)",border:"1px solid var(--border)",borderRadius:12,overflow:"hidden"}}>
          {/* Headers */}
          <div style={{padding:"16px 20px",borderRight:"1px solid var(--border)",background:"var(--surface2)"}}>
            <div style={{fontWeight:700,fontSize:16}}>{p1.name}</div>
            <div style={{fontSize:12,color:"var(--text2)"}}>{p1.position} • {p1.nationality}</div>
            <div style={{fontWeight:800,fontSize:30,color:getScoreColor(calcScore(p1.attributes)),marginTop:8}}>{calcScore(p1.attributes)}</div>
            <RadarChart attrs={p1.attributes} size={150}/>
          </div>
          <div style={{display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",background:"var(--surface)",padding:"0 8px"}}>
            <div style={{fontWeight:800,fontSize:20,color:"var(--text2)"}}>VS</div>
          </div>
          <div style={{padding:"16px 20px",borderLeft:"1px solid var(--border)",background:"var(--surface2)",textAlign:"right"}}>
            <div style={{fontWeight:700,fontSize:16}}>{p2.name}</div>
            <div style={{fontSize:12,color:"var(--text2)"}}>{p2.position} • {p2.nationality}</div>
            <div style={{fontWeight:800,fontSize:30,color:getScoreColor(calcScore(p2.attributes)),marginTop:8}}>{calcScore(p2.attributes)}</div>
            <RadarChart attrs={p2.attributes} size={150}/>
          </div>
          {/* Attribute rows */}
          {common.length>0&&<div style={{gridColumn:"1/-1",borderTop:"1px solid var(--border)",padding:"16px 20px"}}>
            <div style={{fontWeight:700,fontSize:13,letterSpacing:.5,color:"var(--text2)",marginBottom:12}}>ATTRIBUTE COMPARISON</div>
            {common.map(a=>{
              const v1=p1.attributes[a],v2=p2.attributes[a];
              const winner=v1>v2?1:v2>v1?2:0;
              return(
                <div key={a} style={{display:"grid",gridTemplateColumns:"1fr 80px 1fr",gap:8,marginBottom:8,alignItems:"center"}}>
                  <div style={{display:"flex",justifyContent:"flex-end",gap:8,alignItems:"center"}}>
                    <span style={{fontSize:12,fontFamily:"var(--font-mono)",fontWeight:700,color:winner===1?"var(--green)":"var(--text2)"}}>{v1}</span>
                    <div style={{width:`${v1*0.9}px`,maxWidth:130,height:8,borderRadius:4,background:winner===1?"var(--green)":"var(--accent)",marginLeft:"auto"}}/>
                  </div>
                  <div style={{textAlign:"center",fontSize:11,color:"var(--text2)",fontWeight:600}}>{a.slice(0,8)}</div>
                  <div style={{display:"flex",gap:8,alignItems:"center"}}>
                    <div style={{width:`${v2*0.9}px`,maxWidth:130,height:8,borderRadius:4,background:winner===2?"var(--green)":"var(--accent2)"}}/>
                    <span style={{fontSize:12,fontFamily:"var(--font-mono)",fontWeight:700,color:winner===2?"var(--green)":"var(--text2)"}}>{v2}</span>
                  </div>
                </div>
              );
            })}
          </div>}
          {common.length===0&&p1.position!==p2.position&&<div style={{gridColumn:"1/-1",padding:"20px",textAlign:"center",color:"var(--text2)",fontSize:13,borderTop:"1px solid var(--border)"}}>
            ℹ Different positions — attribute sets don't overlap for direct comparison.
          </div>}
        </div>
      )}
      {(!p1||!p2)&&<div className="card" style={{textAlign:"center",padding:40,color:"var(--text2)"}}>Select two players to compare them head-to-head.</div>}
    </div>
  );
}

// ── Squad Gap Analyser ─────────────────────────────────────────────────────
function SquadGapAnalyser({players}){
  const[formation,setFormation]=useState("4-3-3");
  const[style,setStyle]=useState("Possession");
  const[budget,setBudget]=useState("£1M–£5M");
  const[slots,setSlots]=useState({});
  const[analysis,setAnalysis]=useState("");
  const[loading,setLoading]=useState(false);

  const getSlotPositions=(f)=>{
    const map={"4-4-2":["GK","RB","CB","CB","LB","RM","CM","CM","LM","ST","ST"], "4-3-3":["GK","RB","CB","CB","LB","CM","CM","CM","RW","ST","LW"], "4-2-3-1":["GK","RB","CB","CB","LB","DM","DM","RAM","CAM","LAM","ST"], "4-5-1":["GK","RB","CB","CB","LB","RM","CM","CM","CM","LM","ST"], "3-5-2":["GK","CB","CB","CB","RWB","CM","CM","CM","LWB","ST","ST"], "5-3-2":["GK","RCB","CB","LCB","RWB","LWB","CM","CM","CM","ST","ST"],
    };
    return map[f]||map["4-3-3"];
  };

  const positions=getSlotPositions(formation);
  const filled=positions.filter((_,i)=>slots[i]).length;

  const runAnalysis=async()=>{
    setLoading(true);
    const assignedPlayers=positions.map((_,i)=>slots[i]?players.find(p=>p.id===slots[i]):null).filter(Boolean);
    try{const r=await generateSquadAnalysis(assignedPlayers,formation,style,budget);setAnalysis(r);}
    catch{setAnalysis("Unable to generate analysis. Please try again.");}
    setLoading(false);
  };

  return(
    <div style={{display:"flex",flexDirection:"column",gap:20}}>
      <div style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:12}}>
        <div className="form-group">
          <label className="form-label">Formation</label>
          <select className="form-input" value={formation} onChange={e=>{setFormation(e.target.value);setSlots({});}} style={{cursor:"pointer"}}>
            {FORMATIONS.map(f=><option key={f}>{f}</option>)}
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Playing Style</label>
          <select className="form-input" value={style} onChange={e=>setStyle(e.target.value)} style={{cursor:"pointer"}}>
            {STYLES.map(s=><option key={s}>{s}</option>)}
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Transfer Budget</label>
          <select className="form-input" value={budget} onChange={e=>setBudget(e.target.value)} style={{cursor:"pointer"}}>
            {BUDGETS.map(b=><option key={b}>{b}</option>)}
          </select>
        </div>
      </div>

      <div style={{background:"var(--surface)",border:"1px solid var(--border)",borderRadius:12,padding:20}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:16}}>
          <div>
            <div style={{fontWeight:800,fontSize:17,letterSpacing:-.2}}>FORMATION SLOTS — {formation}</div>
            <div style={{fontSize:12,color:"var(--text2)",marginTop:2}}>{filled}/{positions.length} slots filled</div>
          </div>
          <div style={{background:"var(--surface2)",border:"1px solid var(--border)",borderRadius:8,padding:"4px 12px",fontSize:12,fontWeight:700}}>
            <span style={{color:filled===positions.length?"var(--green)":filled>5?"var(--gold)":"var(--red)"}}>{filled}</span>/{positions.length}
          </div>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fill,minmax(200px,1fr))",gap:8}}>
          {positions.map((pos,i)=>{
            const assigned=slots[i]?players.find(p=>p.id===slots[i]):null;
            return(
              <div key={i} style={{background:assigned?"rgba(0,255,135,.05)":"rgba(255,77,109,.05)",border:`1px solid ${assigned?"var(--border2)":"rgba(255,77,109,.3)"}`,borderRadius:8,padding:"10px 12px"}}>
                <div style={{fontSize:10,fontWeight:700,textTransform:"uppercase",letterSpacing:.5,color:"var(--text2)",marginBottom:4}}>{pos}</div>
                {assigned?(
                  <div>
                    <div style={{fontSize:13,fontWeight:600}}>{assigned.name}</div>
                    <div style={{fontSize:11,color:"var(--text2)"}}>{assigned.position}</div>
                  </div>
                ):<div style={{fontSize:11,color:"var(--red)",fontWeight:500}}> Vacant slot</div>}
                <select style={{marginTop:6,width:"100%",background:"var(--surface2)",border:"1px solid var(--border)",color:"var(--text)",borderRadius:5,padding:"4px 6px",fontSize:11,cursor:"pointer"}} value={slots[i]||""} onChange={e=>setSlots({...slots,[i]:e.target.value||undefined})}>
                  <option value="">— Assign player —</option>
                  {players.map(p=><option key={p.id} value={p.id}>{p.name}</option>)}
                </select>
              </div>
            );
          })}
        </div>
      </div>

      <div style={{display:"flex",gap:12}}>
        <button className="btn btn-primary" onClick={runAnalysis} disabled={loading} style={{flex:1}}>
          {loading?<><span className="spinner"/>Analysing Squad…</>:" Run AI Squad Analysis"}
        </button>
        <button className="btn btn-ghost" onClick={()=>{setSlots({});setAnalysis("");}}>Reset</button>
      </div>

      {analysis&&(
        <div className="card slide-in" style={{borderColor:"rgba(0,255,135,.2)"}}>
          <div style={{fontWeight:800,fontSize:17,letterSpacing:-.2,color:"var(--accent)",marginBottom:16}}>SQUAD ANALYSIS — {formation} • {style} • {budget}</div>
          {analysis.split("\n").map((line,i)=>{
            if(line.match(/^#+\s/)||line.match(/^\d+\)/)||line.match(/^[A-Z][A-Z\s]+:/))
              return<div key={i} style={{fontWeight:700,fontSize:13,letterSpacing:.5,color:"var(--text)",margin:"14px 0 6px"}}>{line.replace(/^#+\s/,"")}</div>;
            return line.trim()?<p key={i} style={{fontSize:13,color:"var(--text2)",lineHeight:1.7,marginBottom:6}}>{line}</p>:null;
          })}
        </div>
      )}
    </div>
  );
}

// ── Leaderboard ────────────────────────────────────────────────────────────
function Leaderboard({players,scouts,user}){
  const stats=scouts.map(s=>{
    const sp=players.filter(p=>p.scoutId===s.id);
    const signCount=sp.filter(p=>getRecommendation(calcScore(p.attributes))==="SIGN").length;
    const avgScore=sp.length?Math.round(sp.reduce((a,p)=>a+calcScore(p.attributes),0)/sp.length):0;
    const topFind=sp.sort((a,b)=>calcScore(b.attributes)-calcScore(a.attributes))[0];
    const signed=sp.filter(p=>p.status==="Signed").length;
    const trialling=sp.filter(p=>p.status==="Trialling").length;
    return{...s,scouted:sp.length,signCount,avgScore,topFind,signed,trialling};
  }).filter(s=>s.scouted>0).sort((a,b)=>b.signCount-a.signCount||b.avgScore-a.avgScore);

  const medals=["","",""];
  return(
    <div>
      <table>
        <thead><tr>
          <th style={{width:40}}>#</th>
          <th>Scout</th>
          <th style={{textAlign:"center"}}>Scouted</th>
          <th style={{textAlign:"center"}}>SIGN Recs</th>
          <th style={{textAlign:"center"}}>Trialling</th>
          <th style={{textAlign:"center"}}>Signed</th>
          <th style={{textAlign:"center"}}>Avg Score</th>
          <th>Top Find</th>
        </tr></thead>
        <tbody>
          {stats.map((s,i)=>(
            <tr key={s.id}>
              <td style={{fontWeight:800,fontSize:20}}>{medals[i]||i+1}</td>
              <td>
                <div style={{fontWeight:600}}>{s.name}{s.id===user.scoutId&&<span style={{fontSize:11,color:"var(--accent)",marginLeft:6}}>(You)</span>}</div>
                <div style={{fontSize:11,color:"var(--text2)"}}>{s.email}</div>
              </td>
              <td style={{textAlign:"center",fontFamily:"var(--font-mono)",fontWeight:700}}>{s.scouted}</td>
              <td style={{textAlign:"center"}}><span style={{fontFamily:"var(--font-mono)",fontWeight:700,color:"var(--green)"}}>{s.signCount}</span></td>
              <td style={{textAlign:"center",fontFamily:"var(--font-mono)"}}>{s.trialling}</td>
              <td style={{textAlign:"center",fontFamily:"var(--font-mono)"}}>{s.signed}</td>
              <td style={{textAlign:"center"}}><span style={{fontFamily:"var(--font-mono)",fontWeight:700,color:getScoreColor(s.avgScore)}}>{s.avgScore}</span></td>
              <td>{s.topFind?<div><div style={{fontSize:12,fontWeight:600}}>{s.topFind.name}</div><div style={{fontSize:11,color:"var(--text2)"}}>{calcScore(s.topFind.attributes)} score</div></div>:<span style={{color:"var(--text3)",fontSize:12}}>—</span>}</td>
            </tr>
          ))}
          {stats.length===0&&<tr><td colSpan={8} style={{textAlign:"center",padding:40,color:"var(--text2)"}}>No scouts with submitted players yet.</td></tr>}
        </tbody>
      </table>
    </div>
  );
}

// ── Season Summary ─────────────────────────────────────────────────────────
function SeasonSummary({players,scouts}){
  const total=players.length;
  const signed=players.filter(p=>p.status==="Signed").length;
  const trialling=players.filter(p=>p.status==="Trialling").length;
  const watching=players.filter(p=>p.status==="Watching").length;
  const rejected=players.filter(p=>p.status==="Rejected").length;
  const noStatus=players.filter(p=>!p.status||p.status==="No Status").length;
  const signRec=players.filter(p=>getRecommendation(calcScore(p.attributes))==="SIGN").length;
  const hitRate=total>0?Math.round((signed/total)*100):0;
  const avgScore=total>0?Math.round(players.reduce((a,p)=>a+calcScore(p.attributes),0)/total):0;
  const top3=[...players].sort((a,b)=>calcScore(b.attributes)-calcScore(a.attributes)).slice(0,3);
  const pipelineData=[{l:"Watching",v:watching,c:"var(--gold)"},{l:"Trialling",v:trialling,c:"var(--accent2)"},{l:"Signed",v:signed,c:"var(--green)"},{l:"Rejected",v:rejected,c:"var(--red)"},{l:"No Status",v:noStatus,c:"var(--border2)"}];
  const statusColors={Watching:"var(--gold)",Trialling:"var(--accent2)",Signed:"var(--green)",Rejected:"var(--red)","No Status":"var(--text3)"};

  return(
    <div style={{display:"flex",flexDirection:"column",gap:24}}>
      <div style={{display:"grid",gridTemplateColumns:"repeat(5,1fr)",gap:12}}>
        {[["Total Scouted",total,"var(--accent)"],["Signed",signed,"var(--green)"],["Trialling",trialling,"var(--accent2)"],["SIGN Rec'd",`${signRec} (${hitRate}% hit rate)`,"var(--gold)"],["Avg Quality",avgScore,"var(--text)"]].map(([l,v,c])=>(
          <div key={l} className="kpi-card">
            <div className="kpi-value" style={{color:c}}>{v}</div>
            <div className="kpi-label">{l}</div>
          </div>
        ))}
      </div>
      <div className="card">
        <div style={{fontWeight:800,fontSize:15,letterSpacing:-.2,marginBottom:12}}>PIPELINE</div>
        <div className="pipeline-bar">
          {pipelineData.map(({l,v,c})=>total>0&&v>0&&(
            <div key={l} style={{flex:v,background:c,display:"flex",alignItems:"center",justifyContent:"center",fontSize:11,fontWeight:700,color:l==="No Status"||l==="Watching"?"var(--bg)":"var(--bg)",minWidth:v>0?20:0,transition:"flex .5s"}} title={`${l}: ${v}`}>{v>1?v:""}</div>
          ))}
          {total===0&&<div style={{flex:1,background:"var(--surface2)",borderRadius:6}}/>}
        </div>
        <div style={{display:"flex",gap:16,flexWrap:"wrap",marginTop:10}}>
          {pipelineData.map(({l,v,c})=>(
            <div key={l} style={{display:"flex",alignItems:"center",gap:5,fontSize:12}}>
              <div style={{width:10,height:10,borderRadius:2,background:c}}/>
              <span style={{color:"var(--text2)"}}>{l}: </span>
              <span style={{fontWeight:700}}>{v}</span>
            </div>
          ))}
        </div>
      </div>
      {top3.length>0&&(
        <div>
          <div style={{fontWeight:800,fontSize:17,letterSpacing:-.2,marginBottom:12}}>TOP 3 FINDS OF THE SEASON</div>
          <div style={{display:"grid",gridTemplateColumns:"repeat(3,1fr)",gap:12}}>
            {top3.map((p,i)=>{const score=calcScore(p.attributes);const rec=getRecommendation(score);return(
              <div key={p.id} className="card" style={{background:"linear-gradient(135deg,var(--surface),var(--surface2))"}}>
                <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:8}}>
                  <span style={{fontWeight:800,fontSize:24}}>{["","",""][i]}</span>
                  <div style={{fontWeight:800,fontSize:26,color:getScoreColor(score)}}>{score}</div>
                </div>
                <div style={{fontWeight:700,fontSize:14}}>{p.name}</div>
                <div style={{fontSize:12,color:"var(--text2)",marginBottom:8}}>{p.position} • {p.club}</div>
                <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
                  <span className={`rec-badge ${recClass(rec)}`}>{rec}</span>
                  <span className="status-badge" style={{background:`${statusColors[p.status||"No Status"]}22`,color:statusColors[p.status||"No Status"],border:`1px solid ${statusColors[p.status||"No Status"]}44`}}>{p.status||"No Status"}</span>
                </div>
                <div style={{fontSize:11,color:"var(--text3)",marginTop:8}}>Scout: {p.scoutName}</div>
              </div>
            )})}
          </div>
        </div>
      )}
      <div>
        <div style={{fontWeight:800,fontSize:17,letterSpacing:-.2,marginBottom:12}}>PER-SCOUT PERFORMANCE</div>
        <table>
          <thead><tr><th>Scout</th><th style={{textAlign:"center"}}>Scouted</th><th style={{textAlign:"center"}}>SIGN Rec'd</th><th style={{textAlign:"center"}}>Signed</th><th style={{textAlign:"center"}}>Avg Score</th></tr></thead>
          <tbody>
            {scouts.map(s=>{
              const sp=players.filter(p=>p.scoutId===s.id);
              const sigs=sp.filter(p=>getRecommendation(calcScore(p.attributes))==="SIGN").length;
              const signed=sp.filter(p=>p.status==="Signed").length;
              const avg=sp.length?Math.round(sp.reduce((a,p)=>a+calcScore(p.attributes),0)/sp.length):0;
              return sp.length>0&&(
                <tr key={s.id}><td style={{fontWeight:600}}>{s.name}</td><td style={{textAlign:"center",fontFamily:"var(--font-mono)"}}>{sp.length}</td><td style={{textAlign:"center",color:"var(--green)",fontFamily:"var(--font-mono)",fontWeight:700}}>{sigs}</td><td style={{textAlign:"center",fontFamily:"var(--font-mono)"}}>{signed}</td><td style={{textAlign:"center",fontFamily:"var(--font-mono)",color:getScoreColor(avg),fontWeight:700}}>{avg}</td></tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ── DB helpers ─────────────────────────────────────────────────────────────
function dbToPlayer(row){
  return{
    id:row.id,name:row.name,age:row.age,nationality:row.nationality,
    position:row.position,playingLevel:row.playing_level,club:row.club,
    appearances:row.appearances||0,goals:row.goals||0,assists:row.assists||0,
    cleanSheets:row.clean_sheets||0,goalsConceded:row.goals_conceded||0,
    marketValue:row.market_value||0,attributes:row.attributes||{},
    scoutNotes:row.scout_notes||"",aiReport:row.ai_report||"",
    status:row.status||"No Status",scoutId:row.scout_id||"",
    scoutName:row.scout_name||"",createdAt:row.created_at,
  };
}
function playerToDb(p,userId){
  return{
    id:p.id,user_id:userId,name:p.name,age:p.age,nationality:p.nationality,
    position:p.position,playing_level:p.playingLevel,club:p.club,
    appearances:p.appearances,goals:p.goals,assists:p.assists,
    clean_sheets:p.cleanSheets,goals_conceded:p.goalsConceded,
    market_value:p.marketValue,attributes:p.attributes,
    scout_notes:p.scoutNotes,ai_report:p.aiReport,
    status:p.status,scout_id:p.scoutId,scout_name:p.scoutName,
  };
}

// ── Main App ───────────────────────────────────────────────────────────────
export default function App(){
  const[user,setUser]=useState(null);
  const[players,setPlayers]=useState([]);
  const[scouts]=useState(SEED_SCOUTS);
  const[view,setView]=useState("board");
  const[showSubmit,setShowSubmit]=useState(false);
  const[reportPlayer,setReportPlayer]=useState(null);
  const[search,setSearch]=useState("");
  const[filterPos,setFilterPos]=useState("All");
  const[filterStatus,setFilterStatus]=useState("All");
  const[sortBy,setSortBy]=useState("date");
  const[loadingPlayers,setLoadingPlayers]=useState(false);
  const[showLegal,setShowLegal]=useState(null);
  const[showChangePw,setShowChangePw]=useState(false);
  const isPro=user?.plan==="teampro"||user?.plan==="clubpro";

  // ── Restore session on mount ──────────────────────────────────────────────
  useEffect(()=>{
    const session=supabase.auth.getSession();
    if(session?.user){
      const u=session.user;
      setUser({
        name:u.user_metadata?.name||u.email?.split("@")[0],
        club:u.user_metadata?.club||"My Club",
        email:u.email,
        plan:u.user_metadata?.plan||"teampro",
        billing:u.user_metadata?.billing||"monthly",
        supabaseUser:u,
      });
    }
  },[]);

  // ── Load players from Supabase when user is set ───────────────────────────
  useEffect(()=>{
    if(!user?.supabaseUser?.id)return;
    const load=async()=>{
      setLoadingPlayers(true);
      const{data,error}=await supabase.from("players").select("*").eq("user_id",user.supabaseUser.id);
      if(!error&&data){
        setPlayers(data.map(dbToPlayer));
      }
      setLoadingPlayers(false);
    };
    load();
  },[user?.supabaseUser?.id]);

  const handleAuth=async(u)=>{
    setUser(u);
  };

  const handleSubmitPlayer=async(p)=>{
    if(!user?.supabaseUser?.id){setPlayers(prev=>[...prev,p]);return;}
    const row=playerToDb(p,user.supabaseUser.id);
    const{data,error}=await supabase.from("players").insert(row);
    if(!error&&data?.[0]){
      setPlayers(prev=>[...prev,dbToPlayer(data[0])]);
    } else {
      // Fallback: add locally
      setPlayers(prev=>[...prev,p]);
    }
  };

  const handleStatusChange=async(id,status)=>{
    setPlayers(prev=>prev.map(p=>p.id===id?{...p,status}:p));
    if(user?.supabaseUser?.id){
      await supabase.from("players").update({status}).eq("id",id);
    }
  };

  const handleUpdatePlayer=async(updated)=>{
    setPlayers(prev=>prev.map(p=>p.id===updated.id?updated:p));
    if(user?.supabaseUser?.id){
      await supabase.from("players").update({
        ai_report:updated.aiReport,
        scout_notes:updated.scoutNotes,
        status:updated.status,
      }).eq("id",updated.id);
    }
  };

  const handleSignOut=async()=>{
    await supabase.auth.signOut();
    setUser(null);
    setPlayers([]);
  };

  const filteredPlayers=players.filter(p=>{
    if(search&&!p.name.toLowerCase().includes(search.toLowerCase())&&!p.club.toLowerCase().includes(search.toLowerCase()))return false;
    if(filterPos!=="All"&&p.position!==filterPos)return false;
    if(filterStatus!=="All"&&(p.status||"No Status")!==filterStatus)return false;
    return true;
  }).sort((a,b)=>{
    if(sortBy==="score")return calcScore(b.attributes)-calcScore(a.attributes);
    if(sortBy==="name")return a.name.localeCompare(b.name);
    return new Date(b.createdAt)-new Date(a.createdAt);
  });

  if(!user)return(<><GlobalStyles/><AuthPage onAuth={handleAuth}/></>);

  // ── Trial expired — show upgrade wall ──────────────────────────────────
  if(user.isTrialExpired) return(
    <><GlobalStyles/>
    <TrialExpiredUpgrade user={user} onActivated={(upgradedUser)=>setUser(upgradedUser)} onBack={()=>setUser(null)}/>
    </>
  );

  if(loadingPlayers)return(
    <><GlobalStyles/>
    <div style={{minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",flexDirection:"column",gap:16}}>
      <div style={{fontWeight:900,fontSize:28,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
      <span className="spinner" style={{width:32,height:32,borderWidth:3}}/>
      <div style={{fontSize:13,color:"var(--text2)"}}>Loading your scouting data…</div>
    </div></>
  );

  const navItems=[
    {id:"board",icon:"",label:"Scout Board"},
    {id:"h2h",icon:"",label:"Head-to-Head"},
    {id:"gap",icon:"",label:"Squad Gap Analyser"},
    ...(isPro?[{id:"leaderboard",icon:"",label:"Leaderboard"},{id:"summary",icon:"",label:"Season Summary"}]:[]),
  ];

  return(
    <>
      <GlobalStyles/>
      <div style={{display:"flex",minHeight:"100vh"}}>
        {/* Sidebar */}
        <div style={{width:240,background:"rgba(7,11,20,0.92)",borderRight:"1px solid var(--border)",display:"flex",flexDirection:"column",position:"fixed",top:0,left:0,bottom:0,zIndex:100,backdropFilter:"blur(16px)"}}>
          <div style={{padding:"20px 16px 16px",borderBottom:"1px solid var(--border)"}}>
            <div style={{fontWeight:900,fontSize:28,letterSpacing:4,background:"linear-gradient(135deg,var(--accent),var(--accent2))",WebkitBackgroundClip:"text",WebkitTextFillColor:"transparent"}}>SCOUTARA</div>
            <div style={{fontSize:9,color:"var(--text3)",letterSpacing:1.5,lineHeight:1.4,marginTop:2}}>SCOUTING INSTINCTS, POWERED BY AI, BACKED WITH DATA</div>
          </div>
          <div style={{padding:"12px 8px",flex:1,overflowY:"auto"}}>
            {navItems.map(n=>(
              <button key={n.id} className={`nav-item${view===n.id?" active":""}`} onClick={()=>setView(n.id)}>
                <span>{n.icon}</span><span>{n.label}</span>
              </button>
            ))}
            {!isPro&&!user.isDemo&&(
              <div style={{margin:"12px 6px 0",background:"rgba(255,215,0,.08)",border:"1px solid rgba(255,215,0,.2)",borderRadius:8,padding:"10px 12px"}}>
                <div style={{fontSize:11,fontWeight:700,color:"var(--gold)",marginBottom:4}}>Upgrade to Team Pro</div>
                <div style={{fontSize:11,color:"var(--text2)"}}>Unlock Leaderboard & Season Summary</div>
              </div>
            )}
            {user.isDemo&&(
              <div style={{margin:"12px 6px 0",borderRadius:8,padding:"10px 12px",
                background:user.trialDaysLeft<=3?"rgba(255,77,109,.1)":"rgba(0,198,255,.08)",
                border:`1px solid ${user.trialDaysLeft<=3?"rgba(255,77,109,.3)":"rgba(0,198,255,.2)"}`}}>
                <div style={{fontSize:11,fontWeight:800,color:user.trialDaysLeft<=3?"var(--red)":"var(--accent2)",marginBottom:4,textTransform:"uppercase",letterSpacing:.5}}>
                  {user.trialDaysLeft<=0?"Trial Ending Today":user.trialDaysLeft===1?"1 Day Left":`${user.trialDaysLeft} Days Left`}
                </div>
                <div style={{fontSize:11,color:"var(--text2)",lineHeight:1.5}}>Free trial ends<br/><span style={{color:"var(--text)",fontWeight:600}}>{user.trialExpiry}</span></div>
                <div style={{marginTop:8,fontSize:10,color:"var(--accent)",fontWeight:700,lineHeight:1.5}}>
                  Sign out to subscribe — your data will be waiting.
                </div>
              </div>
            )}
          </div>
          <div style={{padding:"12px 8px",borderTop:"1px solid var(--border)"}}>
            <div style={{padding:"10px 12px"}}>
              <div style={{fontSize:12,fontWeight:700}}>{user.name}</div>
              <div style={{fontSize:11,color:"var(--text2)"}}>{user.club}</div>
              {user.isMaster?(
                <div style={{marginTop:4,display:"inline-flex",alignItems:"center",gap:5,background:"linear-gradient(135deg,rgba(0,255,135,.15),rgba(0,198,255,.15))",border:"1px solid rgba(0,255,135,.3)",borderRadius:4,padding:"2px 8px"}}>
                  <div style={{width:6,height:6,borderRadius:"50%",background:"var(--accent)"}}/>
                  <span style={{fontSize:9,fontWeight:800,color:"var(--accent)",letterSpacing:1,textTransform:"uppercase"}}>Master Owner</span>
                </div>
              ):user.isDemo?(
                <div style={{marginTop:4,display:"inline-flex",alignItems:"center",gap:5,background:"rgba(0,198,255,.1)",border:"1px solid rgba(0,198,255,.25)",borderRadius:4,padding:"2px 8px"}}>
                  <div style={{width:6,height:6,borderRadius:"50%",background:"var(--accent2)"}}/>
                  <span style={{fontSize:9,fontWeight:800,color:"var(--accent2)",letterSpacing:1,textTransform:"uppercase"}}>Trial Account</span>
                </div>
              ):(
                <div style={{fontSize:10,color:"var(--accent)",marginTop:2,textTransform:"uppercase",letterSpacing:.5}}>{user.plan}</div>
              )}
            </div>
            {user.isDemo&&(
              <button className="nav-item" onClick={()=>setShowChangePw(true)} style={{color:"var(--accent2)"}}>
                <span>Set My Password</span>
              </button>
            )}
            <button className="nav-item" onClick={handleSignOut} style={{color:"var(--red)"}}>
              <span></span><span>Sign Out</span>
            </button>
            <div style={{padding:"8px 12px",display:"flex",gap:12,flexWrap:"wrap"}}>
              <span style={{fontSize:10,color:"var(--text3)",cursor:"pointer",transition:"color .2s"}}
                onMouseOver={e=>e.target.style.color="var(--accent2)"} onMouseOut={e=>e.target.style.color="var(--text3)"}
                onClick={()=>setShowLegal("terms")}>Terms</span>
              <span style={{fontSize:10,color:"var(--text3)",cursor:"pointer",transition:"color .2s"}}
                onMouseOver={e=>e.target.style.color="var(--accent2)"} onMouseOut={e=>e.target.style.color="var(--text3)"}
                onClick={()=>setShowLegal("privacy")}>Privacy</span>
              <span style={{fontSize:10,color:"var(--text3)",marginLeft:"auto"}}>v1.0.0</span>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div style={{marginLeft:240,flex:1,padding:28,minWidth:0}}>
          {view==="board"&&(
            <div className="fade-in">
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",flexWrap:"wrap",gap:12,marginBottom:24}}>
                <div>
                  <div className="section-title">SCOUT BOARD</div>
                  <div className="section-subtitle">{players.length} players scouted • {players.filter(p=>getRecommendation(calcScore(p.attributes))==="SIGN").length} SIGN recommendations</div>
                </div>
                <button className="btn btn-primary" onClick={()=>setShowSubmit(true)} style={{gap:8}}>+ Submit Player</button>
              </div>
              <div style={{display:"flex",gap:10,flexWrap:"wrap",marginBottom:20}}>
                <input className="form-input" value={search} onChange={e=>setSearch(e.target.value)} placeholder=" Search players or clubs…" style={{width:220}}/>
                <select className="form-input" value={filterPos} onChange={e=>setFilterPos(e.target.value)} style={{cursor:"pointer"}}>
                  <option value="All">All Positions</option>
                  {POSITIONS.map(p=><option key={p}>{p}</option>)}
                </select>
                <select className="form-input" value={filterStatus} onChange={e=>setFilterStatus(e.target.value)} style={{cursor:"pointer"}}>
                  <option value="All">All Statuses</option>
                  {STATUSES.map(s=><option key={s}>{s}</option>)}
                </select>
                <div className="tab-bar">
                  {[["date","Latest"],["score","Score"],["name","A–Z"]].map(([k,l])=>(
                    <button key={k} className={`tab-btn${sortBy===k?" active":""}`} onClick={()=>setSortBy(k)}>{l}</button>
                  ))}
                </div>
              </div>
              {filteredPlayers.length>0?(
                <div style={{display:"grid",gridTemplateColumns:"repeat(auto-fill,minmax(280px,1fr))",gap:16}}>
                  {filteredPlayers.map(p=><PlayerCard key={p.id} player={p} onViewReport={setReportPlayer} onStatusChange={handleStatusChange} isAdmin/>)}
                </div>
              ):(
                <div className="card" style={{textAlign:"center",padding:60,color:"var(--text2)"}}>
                  <div style={{fontSize:40,marginBottom:12}}></div>
                  <div style={{fontSize:16,fontWeight:600}}>No players found</div>
                  <div style={{fontSize:13,marginTop:4}}>Try adjusting your filters or submit a new player</div>
                </div>
              )}
            </div>
          )}

          {view==="h2h"&&(
            <div className="fade-in">
              <div style={{marginBottom:24}}><div className="section-title">HEAD-TO-HEAD</div><div className="section-subtitle">Compare two players side by side</div></div>
              <HeadToHead players={players}/>
            </div>
          )}

          {view==="gap"&&(
            <div className="fade-in">
              <div style={{marginBottom:24}}><div className="section-title">SQUAD GAP ANALYSER</div><div className="section-subtitle">Assign players to formations and identify transfer priorities with AI</div></div>
              <SquadGapAnalyser players={players}/>
            </div>
          )}

          {view==="leaderboard"&&isPro&&(
            <div className="fade-in">
              <div style={{marginBottom:24}}><div className="section-title">SCOUT LEADERBOARD</div><div className="section-subtitle">Ranked by SIGN recommendations then average quality score</div></div>
              <div className="card"><Leaderboard players={players} scouts={scouts} user={user}/></div>
            </div>
          )}

          {view==="summary"&&isPro&&(
            <div className="fade-in">
              <div style={{marginBottom:24}}><div className="section-title">SEASON SUMMARY</div><div className="section-subtitle">Live stats updating as player statuses change</div></div>
              <SeasonSummary players={players} scouts={scouts}/>
            </div>
          )}
        </div>
      </div>

      {showSubmit&&<SubmitPlayerWizard onClose={()=>setShowSubmit(false)} onSubmit={handleSubmitPlayer} scoutId={user.scoutId||"scout1"} scoutName={user.name}/>}
      {reportPlayer&&<AIReportModal player={reportPlayer} onClose={()=>setReportPlayer(null)} onUpdate={handleUpdatePlayer}/>}
      {showChangePw&&<ChangePasswordModal user={user} onClose={()=>setShowChangePw(false)}/>}
      {showLegal==="terms"&&<TermsModal onClose={()=>setShowLegal(null)}/>}
      {showLegal==="privacy"&&<PrivacyModal onClose={()=>setShowLegal(null)}/>}
    </>
  );
}
