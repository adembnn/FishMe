(function(){
  const sb=document.querySelector('.sb');
  if(sb){sb.innerHTML='<div class="t">'+sb.dataset.time+'</div><div class="isl"></div><div class="r">'+E.sbIcons+'</div>'}
  document.querySelectorAll('.board-auto').forEach(b=>{b.innerHTML=E.board(393,852)});
  // sprite → canvas dans <canvas data-sp="brochet40" data-cell="2">
  E.mini=function(cv,rows,cell,opt={}){
    const w=rows[0].length,h=rows.length,cols=opt.cols||w,rws=opt.rows||h;
    const l=new E.Lcd(cv,cols,rws,cell);
    l.sprite(Math.floor((cols-w)/2),Math.floor((rws-h)/2),rows);
    l.draw();
    if(opt.sil){ // silhouette : cases de la forme à 28 % d'encre, rien d'allumé
      const g=l.g,c=cell*l.d;l.clear();l.draw();g.fillStyle='rgba(30,36,26,.30)';
      const ox=Math.floor((cols-w)/2),oy=Math.floor((rws-h)/2);
      rows.forEach((r,j)=>[...r].forEach((ch,i)=>{if(ch!==' ')g.fillRect((ox+i)*c+1,(oy+j)*c+1,c-3,c-3)}));
    }
    return l;
  };
  document.querySelectorAll('canvas[data-sp]').forEach(cv=>E.mini(cv,SPRITES[cv.dataset.sp],+cv.dataset.cell||2,{sil:cv.dataset.sil==='1',cols:+cv.dataset.cols||0,rows:+cv.dataset.rows||0}));
})();
