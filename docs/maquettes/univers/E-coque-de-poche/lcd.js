/* LCD à une seule couleur : pixels allumés = encre, pixels éteints = fantôme à 7 %. Aucun dégradé. */
(function(){
const LCD='#9EA88A', INK='#1E241A';
class Lcd{
  constructor(cv,cols,rows,cell){
    this.cv=cv;this.cols=cols;this.rows=rows;this.cell=cell;
    const d=3;this.d=d;cv.width=cols*cell*d;cv.height=rows*cell*d;
    cv.style.width=cols*cell+'px';cv.style.height=rows*cell+'px';
    this.g=cv.getContext('2d');this.buf=new Uint8Array(cols*rows);
  }
  clear(){this.buf.fill(0)}
  set(x,y,v=1){if(x>=0&&y>=0&&x<this.cols&&y<this.rows)this.buf[y*this.cols+x]=v}
  get(x,y){return(x>=0&&y>=0&&x<this.cols&&y<this.rows)?this.buf[y*this.cols+x]:0}
  snapshot(){return this.buf.slice()}
  restore(s){this.buf.set(s)}
  glyph(x,y,rows,v=1){rows.forEach((r,j)=>[...r].forEach((c,i)=>{if(c==='#')this.set(x+i,y+j,v)}))}
  sprite(x,y,rows,opt={}){
    const {flip=false,shiftTail=0,maxCol=1e9,glitch=null}=opt;
    const w=rows[0].length;
    rows.forEach((r,j)=>{
      let off=0;
      if(glitch&&glitch[j])off=glitch[j];
      for(let i=0;i<w;i++){
        const c=r[i];if(c===' ')continue;
        if(i>maxCol)continue;
        let yy=y+j+(shiftTail&&i<w*0.24?shiftTail:0);
        // 'c' : '#' encre, '.' fond de silhouette (reste éteint)
        if(c==='#')this.set(x+(flip?w-1-i:i)+off,yy,1);
      }
    });
  }
  draw(){
    const g=this.g,c=this.cell*this.d,s=(this.cell-1)*this.d;
    g.fillStyle=LCD;g.fillRect(0,0,this.cv.width,this.cv.height);
    for(let y=0;y<this.rows;y++)for(let x=0;x<this.cols;x++){
      g.fillStyle=this.buf[y*this.cols+x]?INK:'rgba(30,36,26,.075)';
      g.fillRect(x*c+(this.d>>1),y*c+(this.d>>1),s,s);
    }
  }
}
function rng(seed){let s=seed>>>0;return()=>{s=(s*1664525+1013904223)>>>0;return s/4294967296}}

/* intérieur vu à travers le plastique : carte, puce, pile, vis */
function board(w,h,opt={}){
  const k=opt.dark||'#0E6E82';
  return `<svg viewBox="0 0 ${w} ${h}" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
  <g fill="none" stroke="${k}" stroke-opacity=".42" stroke-width="2.4" stroke-linecap="square">
    <path d="M${w*.08} ${h*.62}H${w*.3}V${h*.72}H${w*.52}"/><path d="M${w*.92} ${h*.55}H${w*.74}V${h*.66}H${w*.6}"/>
    <path d="M${w*.2} ${h*.9}V${h*.8}H${w*.42}"/><path d="M${w*.8} ${h*.92}V${h*.8}H${w*.62}V${h*.74}"/>
    <path d="M${w*.5} ${h*.82}V${h*.95}"/>
  </g>
  <g fill="${k}" fill-opacity=".30" stroke="${k}" stroke-opacity=".5" stroke-width="2">
    <rect x="${w*.36}" y="${h*.74}" width="${w*.26}" height="${h*.075}" rx="4"/>
    <circle cx="${w*.14}" cy="${h*.88}" r="9"/><circle cx="${w*.87}" cy="${h*.88}" r="9"/>
  </g>
  <rect x="${w*.22}" y="${h*.84}" width="${w*.56}" height="${h*.08}" rx="${h*.03}" fill="#fff" fill-opacity=".18" stroke="#FF6FA8" stroke-opacity=".7" stroke-width="2"/>
  <g stroke="${k}" stroke-opacity=".55" stroke-width="2"><path d="M${w*.37} ${h*.74}v-5M${w*.43} ${h*.74}v-5M${w*.49} ${h*.74}v-5M${w*.55} ${h*.74}v-5"/></g>
  </svg>`;
}

/* bip : 2 notes carrées, comme un buzzer piézo (déclenché au toucher, les navigateurs bloquent l'autoplay) */
let ac=null;
function beep(seq=[[880,.07],[1320,.09]]){
  try{
    ac=ac||new (window.AudioContext||window.webkitAudioContext)();
    let t=ac.currentTime;
    seq.forEach(([f,d])=>{const o=ac.createOscillator(),g=ac.createGain();o.type='square';o.frequency.value=f;g.gain.value=.05;o.connect(g);g.connect(ac.destination);o.start(t);o.stop(t+d);t+=d+.02});
  }catch(e){}
}

const sbIcons=`<svg width="19" height="12" viewBox="0 0 19 12"><rect x="0" y="8" width="3" height="4" rx="1" fill="currentColor"/><rect x="5" y="5.5" width="3" height="6.5" rx="1" fill="currentColor"/><rect x="10" y="3" width="3" height="9" rx="1" fill="currentColor"/><rect x="15" y="0" width="3" height="12" rx="1" fill="currentColor"/></svg>
<svg width="17" height="12" viewBox="0 0 17 12"><path d="M8.5 2.2c2.3 0 4.4.9 6 2.4l1.1-1.2A10.4 10.4 0 0 0 8.5.5C5.7.5 3.1 1.6 1.4 3.4l1.1 1.2a8.6 8.6 0 0 1 6-2.4Zm0 3.7c1.3 0 2.5.5 3.4 1.3l1.1-1.2a7 7 0 0 0-9 0l1.1 1.2c.9-.8 2.1-1.3 3.4-1.3Zm0 3.6c.6 0 1.1.2 1.5.6L8.5 11.5 7 10.1c.4-.4.9-.6 1.5-.6Z" fill="currentColor"/></svg>
<svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/><rect x="2" y="2" width="17" height="9" rx="2.4" fill="currentColor"/><path d="M25 4.4v4.2c.8-.3 1.5-1.2 1.5-2.1S25.800 4.700 25 4.400Z" fill="currentColor" opacity=".45"/></svg>`;

window.E={Lcd,rng,board,beep,sbIcons,LCD,INK};
})();
