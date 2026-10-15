import { chromium } from 'playwright-core';
const D='/mnt/project-files/maquettes/trois-volets/A2/';
const names='A2-pescedex A2-pescedex-spot A2-carte A2-club A2-nouveau'.split(' ');
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const p = await b.newPage({ viewport: { width: 393, height: 852 } });
let total=0, fails=[], small=[];
for (const n of names){
  await p.goto('file://'+D+n+'.html'); await p.waitForTimeout(300);
  const r = await p.evaluate(()=>{
    const t=[...document.querySelectorAll('a,button')].map(e=>{const b=e.getBoundingClientRect();return {t:(e.getAttribute('aria-label')||e.textContent||'').trim().slice(0,30),w:Math.round(b.width*10)/10,h:Math.round(b.height*10)/10}});
    const tx=[...document.querySelectorAll('body *')].filter(e=>[...e.childNodes].some(c=>c.nodeType==3&&c.textContent.trim())&&!e.closest('.status,.tab,svg,.map')).map(e=>({t:e.textContent.trim().slice(0,25),f:parseFloat(getComputedStyle(e).fontSize)})).filter(x=>x.f<13);
    const sb=[...document.querySelectorAll('*')].filter(e=>e.scrollHeight>e.clientHeight+1&&getComputedStyle(e).overflow!='visible'&&e.matches('.scroll')).length;
    return {t,tx,sb}});
  total+=r.t.length;
  for(const e of r.t) if(e.w<44||e.h<44) fails.push(`${n}: "${e.t}" ${e.w}x${e.h}`);
  for(const e of r.tx) small.push(`${n}: "${e.t}" ${e.f}px`);
  console.log(n, r.t.length+' cibles', '| contenu coupé par le bas:', r.sb);
}
console.log(`${total} cibles <button> mesurées, ${fails.length} < 44 pt`); fails.forEach(f=>console.log(' FAIL '+f));
console.log(`${small.length} texte(s) < 13 px hors onglets/barre d'état`); small.forEach(f=>console.log(' '+f));
await b.close();
