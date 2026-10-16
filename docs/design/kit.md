# Kit FishMe pour dessiner une maquette (artboard .dc.html)

Tu dessines des écrans iPhone de l'app FishMe (pêche en eau douce, France). Chaque écran = un fichier `.dc.html` autonome de 390×844, sur une toile de design. Tout est en français.

## Gabarit obligatoire d'un fichier (copie-le tel quel, change titre et contenu)

```html
<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<title>Carte · A Plans</title>
<script src="./support.js"></script>
<link rel="stylesheet" href="/_blob/69bbcf2d203990410cc97809f5b38487">
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@600;700;800;900&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div class="ecran">
  ... contenu ...
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
renderVals() { return {}; }
}
</script>
</body>
</html>
```

Règles du format (sinon ça casse en silence) :
- Garde la ligne `<script src="./support.js"></script>` EXACTEMENT. Ferme chaque élément, mets des guillemets à chaque attribut. Pas de `{{ }}` (écrans statiques). Pas de `data:` URI, pas d'emoji, pas d'`<iframe>`, pas de JS qui construit l'interface.
- Mise en page en flex ou grid avec `gap`, styles en ligne `style="…"` pour le spécifique ; les classes du design système (ci-dessous) pour le commun. Si tu as besoin d'un peu de CSS en plus, mets-le dans le `<style>` du `<helmet>` (préfixe tes classes par le code de la page, ex. `.p07-…`).
- Positionnement absolu permis à l'intérieur de `.ecran` (390×844, `position:relative`).
- Vrais éléments : `<button>`, `<a href>`, `<input>` + `<label>`. `aria-label` sur les boutons qui n'ont qu'une icône. SVG décoratif : `aria-hidden="true"`.
- Pas de fausse barre d'état : laisse simplement 59 px en haut (classe `.haut`). Pas de cadre de téléphone.
- Images : uniquement les URL ci-dessous, recopiées à l'identique (`/_blob/…`).

## Images (URL à recopier telles quelles)

CSS du design système : /_blob/69bbcf2d203990410cc97809f5b38487

Poissons détourés (fond transparent, profil tourné vers la gauche) :
- brochet `/_blob/325cfac7b539aef705c1b3f944fa8bcf`
- sandre `/_blob/64752134d1301c8ae5245b9230566c2d`
- perche `/_blob/0af5e5e6f274e011d4317ff12600a103`
- truite fario `/_blob/9c9a3e6836050e27289055b62c3d60d5`
- carpe commune `/_blob/aeffa4c02dbb347bade7eabb3ce5d690`
- black-bass `/_blob/822cd2aa2361109755135f4ca4af8f47`
- gardon `/_blob/4799d66fb5fc82ab53e0051d38867b2d`
- chevesne `/_blob/0bd0ad6c0880f28005260ef69b7c6d1a`
- tanche `/_blob/564478d0fb386d33401d90bd869edf60`
- silure `/_blob/5b21e4a573f27bb726bac3b491cd1578`
- brème commune `/_blob/cff7f50887c685b5c9c93aa31f12a4cf`
- rotengle `/_blob/f5858e93409882ef2f174cda8b4da98b`
- barbeau `/_blob/ce0158cafc1778a2a2df962299fd3798`
- ombre `/_blob/77eca25d66c84d7e49521cbb03ad612f`
- ablette `/_blob/5aaaa359aa93c80d89083fad0ae97d77`
- écrevisse signal `/_blob/a5b1637d67446d3038e27de4fb7816ef`
- grenouille verte `/_blob/a23a6e7c33ce242d11971fda23775a2b`

Silhouettes (espèces pas encore trouvées ; noires, à utiliser avec la classe `.silh` qui les grise) :
- perche `/_blob/eccef0c68e8215e3f026211d80c01507` · chevesne `/_blob/9d2c1cf79736071fa8f8a75e8d5bfb82` · brème `/_blob/37840cffcb8d5b09b4e8792e91788083` · tanche `/_blob/cbb801f7063c77c79f62cf719bb26956` · carpe `/_blob/5bc5742808831bfeb9ea9f6d4e226842` · silure `/_blob/1b1de020c47968290c1c43144861a39a` · barbeau `/_blob/b94428e0231f599ca79a95b77a7a80dd` · rotengle `/_blob/37c27e8338ea1bbf58ed48996ac09594` · black-bass `/_blob/ee3890058e90407c37d065ea03d1e32a` · ombre `/_blob/76d87158f5008e70c40366b68180b1c6` · truite fario `/_blob/b1e4b71a29726b13c2d34e2adfcfef68` · sandre `/_blob/057a9ce505900d4d834edfa7cc3ccd76` · brochet `/_blob/43a6a26a33145dfb814690ff8bc29d3a`

Autres :
- Fond de carte de la Marne (Val-de-Marne), 393×852, sans épingle : `/_blob/358f1ded92a9e441995d46a2c2f81624` → `<img class="fond-carte" src="…" alt="">`. La rivière passe à peu près par (200,270), (258,450), (168,640). Le spot gratuit (cercle de 1 km, rayon ~86 px) est centré vers (262,452).
- Vraie photo d'un pêcheur avec son brochet (verso de carte, fond de l'appareil photo) : `/_blob/084d443133499a1c8e783fc6ededce32` (paysage 1200×728).
- Icône de l'app (lune et poisson qui bondit, bleu nuit) : `/_blob/7667ed4766b13859a7e0245c1b4db27c` (png carré 1024) ; ne jamais la retoucher.

## Design système (classes du CSS, valeurs = App/Style/Style.swift)

Couleurs (variables CSS) : `--marine #0D4A85` (marque, boutons, onglet actif, spot) · `--encre #0E1A26` (texte) · `--encre-douce #566576` · `--fond #F2F5F9` · `--surface #FFF` · `--tuile #E7EFF8` (fond de vignette poisson) · `--filet #DCE3EB` · `--ouvert #13643B` / `--ouvert-doux` (pêche ouverte, taille OK) · `--alerte #E8571C` orange bouchon, UNIQUEMENT pour orage, crue, fermé, interdit · `--nuit #082A4C`.
Raretés : commun `--commun` ardoise, rond, 1 point · peu commun `--peu-commun` vert, hexagone, 2 points · rare `--rare` violet, losange, 3 points · légendaire `--legendaire` or bruni, étoile, 4 points. La rareté se lit toujours forme + mot, pas couleur seule. Jamais de cadre jaune.
Police : SF Pro Rounded en gras partout (déjà dans `.ecran`). Tailles : `.t-grand` 34 · `.t-titre` 22 · `.t-sous` 17 · `.t-corps` 17 · `.t-detail` 15 · `.t-legende` 13 · `.t-chiffre` 34 · `.t-geant` 96 (avec `<span class="t-unite">cm</span>`) · `.t-mesure` mono 13 pour les valeurs techniques.
Espacements : 4, 8, 12, 16, 24, 32 ; marge latérale 16 (`.zone`) ; haut 59 (`.haut`). Rayons : 10, 16, 22 ; feuilles 32 à 38 ; boutons en pilule. Zone tactile ≥ 44. Bouton = 54 de haut.
Composants :
- Boutons : `<button class="btn pri">`, `.btn sec`, `.btn doux`, `.btn alerte` ; lien texte `.lien` ; bouton rond `.rond verre` (44).
- Barre d'onglets (3 volets, toujours dans cet ordre) : voir SVG plus bas ; `<nav class="onglets verre">` avec 3 `<a class="onglet">`, l'actif a `on`.
- Feuille du bas façon Plans : `<div class="feuille"><div class="poignee"></div>…</div>` ; ajoute `au-dessus` si la barre d'onglets est visible.
- Liste groupée façon Réglages : `.entete-groupe` puis `.groupe` contenant des `.ligne` (ajoute `avec-image` si `.vignette` avec un poisson) ; `.texte`, `.valeur`, chevron SVG.
- Rareté : `<span class="rar pc">SVG hexagone<span>Peu commun</span></span>`.
- Pastilles `.puce` / `.puce on`, segments `.seg` avec `<span class="on">`.
- Verdict : `<div class="verdict ok">SVG coche<span>Taille légale</span><span class="src">68 / 60 cm</span></div>` ; `.verdict non` (orange, interdit), `.verdict neutre`.
- Alerte : `<div class="alerte-bandeau">SVG éclair<span>Orage à 18 h</span></div>`.
- Carte : `.fond-carte` (img), `.spot-cercle` (div rond posé en absolu), `.moi` (point bleu de position), `.station` (station OFB).
- Carte à collectionner (validée, NE PAS la redessiner) : voir le bloc ci-dessous. Une seule taille partout : ratio 69/100, on change seulement sa largeur.

### Carte à collectionner (recto), copier tel quel
Classes de palier : `c` commun (ardoise), `pc` peu commun (vert foncé), `r` rare (argent irisé), `l` légendaire (or). Ajoute `mini` pour les grilles (n'affiche que chiffre, poisson, nom, palier).
```html
<div class="fc pc" style="width:345px">
  <div class="win"></div>
  <div class="fish"><img src="/_blob/325cfac7b539aef705c1b3f944fa8bcf" alt="Brochet"></div>
  <div class="cen">84<i>e</i></div>
  <div class="cenl">CEN · centile de taille</div>
  <div class="pl">
    <div class="nm"><b>Brochet</b><em>Esox lucius</em></div>
    <svg class="rkm pc" viewBox="0 0 16 16" aria-hidden="true"><path fill="currentColor" d="M8 1.5 13.6 4.75v6.5L8 14.5 2.4 11.25v-6.5Z"/></svg>
    <div class="st">
      <div><b>68<small> cm</small></b><span>TAI</span></div>
      <div><b>34<small> %</small></b><span>FRQ</span></div>
      <div class="rk pc"><svg viewBox="0 0 16 16" aria-hidden="true"><path fill="currentColor" d="M8 1.5 13.6 4.75v6.5L8 14.5 2.4 11.25v-6.5Z"/></svg><span>PEU COMMUN</span></div>
    </div>
    <div class="fo"><span>10 pêches sur 29 dans le 94 · OFB</span><u>n° 014</u></div>
  </div>
  <i class="in"></i>
</div>
```
Dos (espèce pas encore trouvée) : `<div class="fc dos" style="width:110px"><div class="win"></div><img class="sil" src="SILHOUETTE" alt=""><div class="nmdos">Perche</div><i class="in"></i></div>`
Verso (ta vraie photo) : `<div class="fc verso pc" style="width:345px"><div class="ph"><img src="/_blob/084d443133499a1c8e783fc6ededce32" alt="Adem et son brochet"></div><div class="bp"><b>Adem</b><span>12 oct.<br>17:42</span></div><i class="in"></i></div>`

## Icônes (SVG en ligne, trait 2, `currentColor`)
Onglets :
- Pescedex : `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><rect x="5" y="8" width="14" height="12" rx="2.5"/><path d="M7.5 5h9M9.5 2.5h5" stroke-linecap="round"/></svg>`
- Carte : `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true"><path d="M3 6.5 9 4l6 2.5L21 4v13.5L15 20l-6-2.5L3 20Z"/><path d="M9 4v13.5M15 6.5V20"/></svg>`
- Club : `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.6-3.6 3.3-5.5 6.5-5.5s5.9 1.9 6.5 5.5"/><circle cx="17" cy="9" r="2.6"/><path d="M17 14.4c2.4.2 4 1.8 4.5 4.6"/></svg>`
Barre d'onglets complète (Carte active) :
```html
<nav class="onglets verre" aria-label="Volets"><a class="onglet" href="#">SVG_PESCEDEX<span>Pescedex</span></a><a class="onglet on" href="#">SVG_CARTE<span>Carte</span></a><a class="onglet" href="#">SVG_CLUB<span>Club</span></a></nav>
```
Autres (viewBox 0 0 24 24) :
- position `<path fill="currentColor" d="M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7Zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5Z"/>`
- me localiser `<path fill="currentColor" d="M21 3 3 10.5l7.5 2.9L13.4 21Z"/>`
- filtre `<path fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" d="M4 7h16M7 12h10M10 17h4"/>`
- lecture `<path fill="currentColor" d="M7 4.5v15a1 1 0 0 0 1.5.86l12.5-7.5a1 1 0 0 0 0-1.72L8.5 3.64A1 1 0 0 0 7 4.5Z"/>`
- loupe `<g fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 4.5 4.5"/></g>`
- coche ronde `<path fill="currentColor" d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm-1.3 14.2-4-4 1.4-1.4 2.6 2.6 5.6-5.6 1.4 1.4Z"/>`
- appareil photo `<g fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M4 8h3l2-3h6l2 3h3v11H4Z"/><circle cx="12" cy="13" r="3.6"/></g>`
- partager `<path fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" d="M12 3v12M7.5 7.5 12 3l4.5 4.5M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7"/>`
- retourner la carte `<path fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" d="M4 12a8 8 0 0 1 13.7-5.6L20 8.5M20 4v4.5h-4.5M20 12a8 8 0 0 1-13.7 5.6L4 15.5M4 20v-4.5h4.5"/>`
- fermer `<path fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" d="M6 6l12 12M18 6 6 18"/>`
- retour `<path fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" d="M15 5l-7 7 7 7"/>`
- chevron de liste (viewBox 0 0 8 14, classe `chevron`) `<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="m1.5 1.5 5 5.5-5 5.5"/>`
- plus `<path fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" d="M12 5v14M5 12h14"/>`
- éclair (orage) `<path fill="currentColor" d="M13 2 4 14h7l-1 8 9-12h-7Z"/>`
- vague (rivière, crue) `<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="M2 9c2.5-2 5-2 7.5 0s5 2 7.5 0 3.5-1.5 5 0M2 15c2.5-2 5-2 7.5 0s5 2 7.5 0 3.5-1.5 5 0"/>`
- soleil `<g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></g>`
- nuage `<path fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" d="M7 18h10.5a4 4 0 0 0 .4-8A6 6 0 0 0 6.3 11 3.5 3.5 0 0 0 7 18Z"/>`
- horloge `<g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></g>`
- cadenas `<path fill="currentColor" d="M17 10V8A5 5 0 0 0 7 8v2a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-8a2 2 0 0 0-2-2Zm-8-2a3 3 0 0 1 6 0v2H9Z"/>`
- règle (toise) `<g fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><rect x="2" y="8" width="20" height="8" rx="2"/><path d="M6 8v3M10 8v4M14 8v3M18 8v4"/></g>`
- document (source) `<g fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><path d="M6 3h8l4 4v14H6Z"/><path d="M14 3v4h4M9 12h6M9 16h6" stroke-linecap="round"/></g>`
Raretés (viewBox 0 0 16 16, `fill="currentColor"`) :
- commun (rond) `<circle cx="8" cy="8" r="6"/>`
- peu commun (hexagone) `<path d="M8 1.5 13.6 4.75v6.5L8 14.5 2.4 11.25v-6.5Z"/>`
- rare (losange) `<path d="M8 1 15 8 8 15 1 8Z"/>`
- légendaire (étoile) `<path d="m8 1 2.1 4.4 4.9.6-3.6 3.4.9 4.8L8 11.9l-4.3 2.3.9-4.8L1 6l4.9-.6Z"/>`

## Les trois directions (le même design système, trois façons de composer un écran)
Toutes : sobres, minimalistes, claires (fond clair), peu de texte, des images, des icônes et des chiffres ; les poissons toujours en images, jamais une liste de noms seuls ; une information une seule fois par écran ; un seul bouton principal par écran.
- **A · Plans** — « Le monde d'abord ». Le fond plein écran est la chose réelle : la carte, la photo, le viseur, ou la carte à collectionner. Tout le reste tient dans UNE feuille blanche en bas (`.feuille`, poignée) et dans des boutons ronds en verre (`.rond verre`). Réf. : Apple Plans, Flighty, Apple Photos. Si l'écran n'a pas de « monde », la carte de la Marne floutée/estompée sert de fond et le contenu vient en feuille.
- **B · Réglages** — « Le natif pur ». Grand titre iOS (`.t-grand`) en haut à gauche, puis des listes groupées en encart (`.groupe` + `.ligne`) sur fond `--fond`, avec vignette poisson à gauche, valeur grise à droite et chevron. Aucune ombre, aucune image décorative, aucun dégradé. Réf. : Réglages, Santé, Rappels, Fish Rules.
- **C · Sujet** — « Une seule chose par écran ». Fond blanc pur (`.ecran blanc`), UN sujet énorme au centre (poisson détouré de ~300 px, chiffre `.t-geant`, carte à collectionner, ou jauge), au plus 3 lignes de texte, un bouton en bas. Beaucoup de vide. Réf. : Merlin Bird ID (fiche espèce), Apple Fitness (récompenses), Pokémon TCG Pocket (révélation), Tide Guide (un chiffre).

## Interdits (règles anti-slop d'Adem : skills impeccable, creatif-anti-slop, avoid-ai-writing)
- Règles de pêche (Adem, 16 oct. 2h24) : jamais de liste de règles ni de défilement sans fin. Sur un spot, une rangée de poissons en images avec la taille minimale et une pastille ouvert/fermé ; une espèce = un grand chiffre et deux puces ; source, citation et règles particulières derrière un toucher.
- Pas de cartes arrondies identiques en série « parce que », pas de boîte autour de ce qui n'est pas cliquable, pas de bordure gauche colorée, pas d'ombre décalée dure, pas de dégradé violet/bleu, pas de texte en dégradé, pas d'étiquette en capitales au-dessus d'un titre, pas d'emoji, pas de glyphe Unicode en icône, pas de verre décoratif (le verre seulement sur les contrôles posés sur la carte/photo), pas de mode sombre par défaut, pas de hero centré type site web, pas de tableau de bord.
- Textes : courts, concrets, tutoiement. Pas de « ce n'est pas X, c'est Y », pas de triplets, pas de promo. Jamais « Poké », « Pokémon », « Pokédex ». Jamais « tu peux la garder » ; jamais « bon spot ». « Pescedex » = la collection, l'app s'appelle FishMe.
- Le violet ne sert qu'à la rareté « rare ». L'orange ne sert qu'aux alertes.

## Données d'exemple (les mêmes partout, ne pas en inventer d'autres)
- Lieu : la Marne, Val-de-Marne (94). Spot gratuit : cercle de 1 km sur la Marne, près de Saint-Maur, « Ton spot », à 2,4 km. Station OFB la plus proche : 29 pêches, dernier relevé 2024.
- Raretés dans le 94 : gardon commun (24 pêches sur 29, 83 %), perche commun (16 sur 29, 55 %), brochet peu commun (10 sur 29, 34 %), sandre rare (3 sur 29, 10 %), truite fario légendaire (0 sur 29, jamais relevée ici). 11 espèces relevées sur la station ; tu en as trouvé 3 sur 11.
- Prise de démo : brochet 68 cm, ~2,1 kg « estimé », CEN 84e, n° 014, le 12 oct. à 17:42, par Adem. Règle : brochet taille minimale 60 cm dans le 94 (arrêté préfectoral 2025 : 50 cm ; avis 2026 : 60 cm ; on affiche la plus stricte, 60 cm, avec les deux sources). Ouvert du 1er janv. au dernier dimanche de janv. puis du 1er mai au 31 déc. ; 3 carnassiers par jour.
- Session : 1:24:10 en cours, fin légale 19:29 (une demi-heure après le coucher du soleil).
- Météo : 14°, nuageux, vent 12 km/h ; Marne à Créteil 1,42 m, stable ; 7 jours de prévisions. Marque Apple Weather obligatoire sur les données météo («  Météo » + lien Sources). Alerte : orage à 18 h (vigilance jaune Météo-France).
- Amis : Léa, Malo, Inès. Paywall : abonnement annuel 34,99 € « tarif fondateur » jusqu'au 31 décembre 2026 (puis 49,99 €), mensuel [prix à fixer] avec 1 semaine d'essai ; « Restaurer les achats », conditions, confidentialité, bouton fermer. Gratuit : la carte, les règles, le Pescedex en lecture et un spot ; Pro : tous les spots (tronçons entre deux confluences), météo, rivière, alertes, conseils.
