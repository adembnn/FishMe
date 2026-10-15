import { chromium } from 'playwright-core';
import path from 'node:path';
const D='/mnt/project-files/maquettes/niveau-1/';
const names='accueil carte fiche sortie photo verdict prise paywall pescedex bredouille verdict-rouge espece-protegee live-activity live-island partage'.split(' ');
const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
const p = await b.newPage({ viewport: { width: 393, height: 852 } });
let total=0, fails=[];
for (const n of names){
  await p.goto('file://'+D+n+'.html'); await p.waitForTimeout(300);
  const r = await p.evaluate(()=>[...document.querySelectorAll('a,button')].map(e=>{const b=e.getBoundingClientRect();return {t:(e.getAttribute('aria-label')||e.textContent||'').trim().slice(0,30),w:Math.round(b.width*10)/10,h:Math.round(b.height*10)/10}}));
  total+=r.length;
  for(const e of r) if(e.w<44||e.h<44) fails.push(`${n}: "${e.t}" ${e.w}x${e.h}`);
}
console.log(`${total} cibles <a>/<button> mesurées, ${fails.length} échec(s)`); fails.forEach(f=>console.log(' FAIL '+f));
await b.close();
