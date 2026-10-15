/* Barre d'état iOS partagée : <div class="statut" data-h="17:11"></div> */
(function(){
  document.querySelectorAll('.statut[data-h]').forEach(function(el){
    el.innerHTML='<span>'+el.dataset.h+'</span><div class="ile"></div><span class="droite" aria-hidden="true">'+
    '<svg width="19" height="12" viewBox="0 0 19 12" fill="#fff"><rect x="0" y="8" width="3.2" height="4" rx="1"/><rect x="5" y="5.5" width="3.2" height="6.5" rx="1"/><rect x="10" y="3" width="3.2" height="9" rx="1"/><rect x="15" y="0" width="3.2" height="12" rx="1"/></svg>'+
    '<svg width="17" height="12" viewBox="0 0 17 12" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"><path d="M1.5 4.3a10 10 0 0 1 14 0"/><path d="M4 7a6.5 6.5 0 0 1 9 0"/><circle cx="8.5" cy="10" r="1" fill="#fff" stroke="none"/></svg>'+
    '<svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="#fff" stroke-opacity=".6"/><rect x="2" y="2" width="19" height="9" rx="2.6" fill="#fff"/><path d="M25 4.5v4c.9-.3 1.6-1.1 1.6-2s-.7-1.7-1.6-2z" fill="#fff" fill-opacity=".6"/></svg></span>';
  });
  document.querySelectorAll('[data-fish]').forEach(function(el){
    var a=el.dataset.fish.split(',');
    el.innerHTML=Pate.poisson(a[0],a[1]||'commun');
  });
})();
