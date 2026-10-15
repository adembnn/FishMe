# Assets maquettes Pescedex (licences + sources)

Tout est local (aucun CDN). Chemins relatifs à ce dossier.

## fish/ (25 espèces, domaine public)
Chaque espèce : `fish/<slug>.png` (détourée, PNG transparent, max 1400 px de large) et
`fish/plates/<slug>-plate.jpg` (planche d'origine sur papier, 1600 px). Détourage fait en Python
(OpenCV + scipy, fond papier estimé puis seuillé) : léger liseré papier possible sur ablette et aspe.
- Source principale : Bloch, "Ichthyologie ou Histoire naturelle des poissons" (1785-97), planches
  enluminées, noms latin/allemand/français/anglais sur la planche. BHL item 26748
  (Harvard MCZ). Domaine public. Image : jpg/ichthyologieouhi01bloc/ichthyologieouhi01bloc_NNNN.jpg
  du bucket S3 BHL (page NNNN entre parenthèses). Source: https://www.biodiversitylibrary.org/item/26748
- black-bass : Cuvier & Valenciennes, Histoire naturelle des poissons, planches couleur 9-140,
  "Growler salmoide / Grystes salmoides" (BHL item 31437, page 0077, pivotée + miroir). Domaine public.
  Source: https://www.biodiversitylibrary.org/item/31437
- Accès : bucket BHL Open Data (CC0) https://bhl-open-data.s3.us-east-2.amazonaws.com/ (jpg/, data/item.txt.gz)

Slug (page Bloch) : brochet (65), perche (105), gardon (7, "La Rosse"), sandre (103), carpe-commune (35),
truite-fario (47, "Truite brune"), truite-fario-etang (45), silure (69), chevesne (13, Döbel),
ide-melanote (15, Aland), breme-commune (29), breme-bordeliere (23), breme-bleue (21, Zope), tanche (31),
rotengle (5), barbeau (39), aspe (17), hotu (9, Nase), vimbe (11), gibele (27), carassin (25),
ombre (49), lavaret (51), lotte (141), ablette (19, fig. 4 recadrée), black-bass (CV).
Manquants : aucun de la liste demandée. Pas obtenus : vairon/goujon/bouvière/épinoche (présents sur
planches multi-poissons p.19 et p.107, non découpés), écrevisse, anguille, saumon (planche p.43 = truite de mer, non traitée).

## geo/ (tout en WGS84 GeoJSON)
- departements-simplifie.geojson (96 dép.), regions-simplifie.geojson, france-metropole-simplifie.geojson :
  gregoiredavid/france-geojson (versions simplifiées), données IGN Admin Express, Licence Ouverte Etalab.
  https://github.com/gregoiredavid/france-geojson
- rivieres-france-ne10m.geojson (147 lignes : Seine, Loire, Marne, Rhône, Garonne...), lacs-france-ne10m.geojson
  (31 : Annecy, Bourget, Orient, Léman...) : Natural Earth 10m rivers_lake_centerlines + rivers_europe + lakes,
  recadrés sur la France, domaine public. https://github.com/nvkelso/natural-earth-vector
- demo/communes-{75-paris,74-haute-savoie,77-seine-et-marne}.geojson : contours communaux, même source que ci-dessus.
- Limite : pas de géométrie fine des rivières/lacs (BD Carthage/TOPAGE, Overpass, data.gouv, Sandre sont bloqués
  dans ce conteneur). Pour une zone détaillée, utiliser un style de tuiles vectorielles côté navigateur de l'utilisateur
  ou refaire l'extraction depuis le PC. Tuiles OSM aussi bloquées : prévoir un fond sans tuiles (aplats + GeoJSON).

## vendor/
- maplibre-gl/ v5.9.0 (maplibre-gl.js UMD + .css), BSD-3-Clause. npm maplibre-gl (la v6 n'est qu'en ESM).
- d3/ d3.min.js v7.9.0, ISC.
- gsap/ v3.15.0 (gsap, ScrollTrigger, Flip, Draggable, CustomEase), licence GreenSock "no charge" (gratuite, usage standard).
  https://gsap.com/standard-license
- phosphor/ @phosphor-icons/web v2.1.2 : regular/bold/fill (style.css + .woff2), MIT.
  Usage : <link rel=stylesheet href="vendor/phosphor/regular/style.css"> puis <i class="ph ph-fish">.
- lucide/ lucide-static v1.55.0 : icons/*.svg (+ sprite.svg), ISC.
- pokemon-cards-css/ : css/ (cards.css, base.css, cards/*.css, global.css), img/ (textures holo), foils.txt.
  simeydotme/pokemon-cards-css, GPL-3.0 (copie pour référence : ne pas l'embarquer telle quelle dans une app
  distribuée sans en réécrire la technique). Les CSS référencent `/img/...` en absolu : servir `vendor/pokemon-cards-css/`
  à la racine ou réécrire les url(). https://github.com/simeydotme/pokemon-cards-css

## fonts/ (@fontsource 5.3.0, latin, woff2, OFL-1.1) + fonts.css (déclarations @font-face prêtes)
Fraunces 400/600/700 + italiques ; Instrument Serif 400 + italique ; Bricolage Grotesque 400/600/700 ;
DM Mono 400 + italique (pas de 600/700 chez DM Mono sur npm) ; IBM Plex Mono 400/600/700 + italiques ;
Young Serif 400 ; Gloock 400 ; Familjen Grotesk 400/600/700 + italiques ; Hanken Grotesk 400/600/700 + italiques ;
Syne 400/600/700 ; Unbounded 400/600/700 ; Darker Grotesque 400/600/700 ; Newsreader 400/600/700 + italiques ;
Libre Caslon Text 400/700 + italique 400 ; Libre Caslon Display 400. Space Mono volontairement omise. Tout existe sur npm.
Sources : https://www.npmjs.com/package/@fontsource/<nom-en-minuscules-tirets>

## fonts/sf/
SF Pro Display (Regular, Medium, Semibold, Bold), woff2, from the npm package `sf-font` 1.0.0 (third-party copy of Apple's font; the official Apple CDN devimages-cdn.apple.com is blocked from the cloud). For mockups only, never shipped in the app (the app uses the system font natively). Licence: Apple's SF font licence restricts use to mockups of software for Apple platforms.

## bezels/
iPhone 17 portrait frames (5 colours, 1350x2760 PNG), extracted from Apple's Bezel-iPhone-17.dmg (Apple Design Resources) uploaded by Adem to /mnt/project-files/. Extraction in the cloud: npm `7z-wasm` (7-Zip 24.09 in WebAssembly; the npm `7zip-bin` 7za cannot open DMG). Framing script: assets/bezels/cadre.py (python3 cadre.py capture.png out.png [Black, White, Sage, Mist Blue, Lavender]) (screen hole 1206x2622 at x=72, y=69).
