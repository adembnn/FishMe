# Contrat commun — page « FishMe en mouvement »

Une seule page HTML (artefact claude.ai) qui montre à Adem des VARIATIONS d'animations de chargement et d'effets sonores pour FishMe (app iOS de pêche en eau douce, SwiftUI). Il choisira ensuite. Plusieurs agents écrivent chacun un fichier JS ; je (la session principale) les assemble dans `index.html`. Dossier : celui de ce fichier.

## Règles absolues
- JS pur, navigateur moderne, aucune bibliothèque, aucun fetch réseau. Pas d'`alert`.
- Chaque fichier est une IIFE ; ne pollue que les globals autorisés ci-dessous.
- CSS : si tu en as besoin, injecte UNE balise `<style>` depuis ton JS, toutes tes classes préfixées par ton préfixe (ex. `.fmL-`). Jamais de style global (pas de `body`, `*`, `div`…).
- Canvas : net sur écran Retina (devicePixelRatio, max 2), redimensionné avec ResizeObserver. 60 fps max, et l'animation s'arrête quand la scène n'est pas visible (IntersectionObserver) — la page en montre ~20 à la fois.
- Qualité : Adem rejette tout « AI slop » (formes grossières, effets génériques, dégradés violets, emoji). On vise le niveau d'une app Apple : mouvement en ressorts, courbes douces, timings précis, peu d'éléments mais justes. Physique crédible de l'eau (ondes concentriques qui s'élargissent ET s'atténuent, gouttes en parabole, bulles qui oscillent en montant et grossissent).
- Pas de texte « Pokémon/Poké », pas de cadre jaune sur les cartes.
- `ctx.reduit === true` (Réduire les animations) : pas de mouvement ample, pas de boucle ; un fondu ou un état fixe lisible, mais jamais une page vide.

## Palette Marine (seules couleurs permises)
marine #0D4A85 · marine foncé #0B3D6B · nuit #082A4C · fond icône dégradé #0B3A86 → #05173A · ombre eau #04122B
encre #0E1A26 · encre douce #566576 · fond page #F2F5F9 · surface #FFFFFF · tuile #E7EFF8 · filet #DCE3EB · silhouette #B9C8D8
eau #9CC7EA · eau claire #C7DFF3 · lune #F4FBFF→#BFE6FF→#8FD0FF, halo #6FC3FF
bouchon (orange, alertes SEULEMENT, plus le haut d'un bouchon de pêche) #E8571C
raretés : commun #6B7780 (badge rond, 1 point) · peu commun #23885A (hexagone, 2 points) · rare #5B4FD0 (losange, 3 points) · légendaire #B07A12 or bruni (étoile, 4 points)
Police : `ui-rounded, "SF Pro Rounded", "Nunito", system-ui, sans-serif`, gras (700–800).

## Assets (déjà chargés avant ton fichier)
`window.FMAssets = { logoSVG, poissonPath, poissons }`
- `logoSVG` : le logo validé F1 « La Lune » (viewBox 0 0 100 100 : fond dégradé bleu nuit, halo, lune cx50 cy48 r32, eau sombre en bas `M0,74 C20,70 34,72 50,76 C66,72 80,70 100,74 L100,100 L0,100 Z`, poisson qui bondit en ombre chinoise : `<g transform="translate(50 46) rotate(-28) scale(.76 .46) translate(-50 -50)">` + `poissonPath` + œil cx74 cy45 r3.6 couleur lune, 3 gouttes). NE JAMAIS modifier la silhouette du logo (Adem l'a validée telle quelle) ; on peut l'animer (le poisson qui bondit, la lune, l'eau).
- `poissonPath` : le contour du poisson du logo (repère 0–100, tête à droite).
- `poissons` : { brochet, 'truite-fario', sandre, 'carpe-commune', 'black-bass', perche } → data URI webp, planche de Bloch détourée, tête à droite, 520 px de large.

## Le moteur de la page
Avant ton fichier, la page définit :
```js
window.FM = {
  anims: [],                       // tu pousses tes animations ici
  son(id) {},                      // joue un son du catalogue si le son est activé (ne fait rien sinon)
  sonChoisi(moment) {},            // renvoie l'id du son choisi par Adem pour ce moment (ex. 'carte-rare'), ou null
};
```
Une animation :
```js
FM.anims.push({
  id: 'lancement-lune',            // unique, kebab-case
  groupe: 'lancement' | 'attente' | 'carte' | 'reconnaissance' | 'arrivee',
  lettre: 'A',                     // A, B, C… dans son groupe
  nom: 'Lever de lune',            // 2–4 mots, français
  resume: 'Une phrase simple : ce qu’on voit.',
  ou: 'Où dans l’app (écran précis).',
  duree: '1,2 s puis la carte',    // ou 'boucle 1,4 s'
  swiftui: 'Deux ou trois phrases : comment la faire en SwiftUI iOS 27 (PhaseAnimator, KeyframeAnimator, TimelineView + Canvas, shader .layerEffect, matchedGeometryEffect, sensoryFeedback…), et ce qu’elle devient avec Réduire les animations.',
  format: 'telephone' | 'tuile',   // telephone = 390×844 (ratio), tuile = carré
  fond: 'nuit' | 'clair',          // couleur de la scène derrière (nuit = #082A4C, clair = #F2F5F9)
  options: [{ cle:'rarete', valeurs:['commun','peu-commun','rare','legendaire'] }], // facultatif (seulement groupe arrivee)
  monter(el, ctx) {                // el : div vide déjà dimensionnée (position:relative; overflow:hidden), fond déjà peint
    // ctx = { reduit: bool, son: (moment)=>void, option: { rarete:'rare' } }
    // ctx.son(moment) joue le son choisi pour ce moment au bon temps de l'animation
    return { rejouer(){}, arreter(){} };   // rejouer : repart de zéro ; arreter : nettoie tout (timers, rAF, observers, DOM)
  }
});
```
Les moments sonores que tu peux appeler avec `ctx.son(...)` : 'lancement', 'toucher', 'retournement', 'carte-commun', 'carte-peu-commun', 'carte-rare', 'carte-legendaire', 'montee' (tension avant une révélation), 'plouf', 'bulles', 'moulinet', 'succes', 'alerte'.
Une animation non-boucle (lancement, arrivée) se rejoue seule toutes les ~6 s si personne ne touche, et `rejouer()` est appelé par le bouton « Rejouer ». Les sons ne partent que quand l'utilisateur appuie sur « Rejouer » ou touche la scène (la page gère : `ctx.son` est muet pendant les boucles automatiques), donc appelle toujours `ctx.son` au bon temps, sans te soucier du reste.

## Pour te vérifier
Tu peux ouvrir ton fichier dans Chromium headless (Playwright est installé, `executablePath: '/opt/pw-browsers/chromium'` si besoin) avec un petit harness HTML à toi (dans un sous-dossier `test-<prefixe>/`, que tu effaces à la fin), et regarder des captures à plusieurs instants. Fais-le : le rendu doit être beau, pas juste « marcher ». Aucune erreur console.
Ne touche à AUCUN fichier hors de ton fichier livré (et de ton dossier de test). N'appelle aucun outil mcp__hearthbot__. Pas de git.
