# Finitions de cartes : la logique de la rareté, et une spec originale pour 4 paliers

Décision débloquée : quelle matière, quel foil, quel cadre, quelle numérotation, quel verso, quel mouvement par palier (commun, peu commun, rare, légendaire), en CSS (maquette) et SwiftUI/Metal (app).
Sources : recherche web du 12/10/2026 (liens en fin de fichier). [?] = non vérifié ou issu de ma mémoire.

## 0. Version simple
Une carte de collection raconte la rareté par la matière, pas par un badge. Plus c'est rare, plus il y a de surface qui brille, plus le motif est compliqué, plus ça bouge, plus l'image sort du cadre, et plus le tirage est petit. Le joueur doit pouvoir classer deux cartes les yeux mi-clos, sans lire le mot « rare ».

Constat sur raretes.png : les 4 cartes ont déjà la bonne intuition (vert mat, bleu-canard, argent, or), mais les paliers se distinguent surtout par la couleur. Une couleur n'est pas une matière : en niveaux de gris, commun et peu commun se confondent, rare et légendaire aussi. C'est ce que la spec corrige.

## 1. Ce que font les références (faits sourcés)

### Pokémon TCG (papier)
- Échelle des symboles : rond noir (commun), losange (peu commun), étoile (rare), puis étoiles d'argent/or. Les formes ne changent pas avec le foil : « un Reverse Holo ≠ un Reverse Masterball, même symbole, valeur très différente » (PokéFolio, TCGplayer). Le symbole dit la rareté du tirage, la finition dit le prestige.
- Non-holo : tout mat. Holo : seule la fenêtre d'illustration brille, le reste est mat. Reverse holo : l'inverse, tout brille sauf l'illustration (rarecards.nl, TCGplayer). Deux logiques de zone de foil, utiles pour un palier intermédiaire.
- Motifs de foil nommés : Cosmos/Galaxy (points et cercles de tailles variées), Starlight, Tinsel, Sheen, Water Web ; promos : Cracked Ice, Crosshatch, Sequin, Confetti (Bulbapedia). Le motif est un signe d'époque ou de produit, pas un palier.
- Full art : l'illustration mange cadre et zones de texte ; la texture gravée (étching) se sent au doigt : « si on sent des stries, c'est au moins Ultra Rare ; les holos classiques sont lisses » (pokemonlist). Les fausses cartes sont lisses (PokéFolio).
- Illustration Rare : brillance « glossy » sans gravure ; Special Illustration Rare et Ultra Rare : gravure ; Hyper Rare : or gravé, 3 étoiles dorées, numéro > total du set (ex. 198/193) (Bill's Archive, pokemonlist). Dernier venu : « Futuristic Rare », opalescent à décalage holographique, sans étoile [?: une seule source].
- Règle déduite : chaque marche ajoute une couche physique (foil, puis zone plus grande, puis relief, puis métal précieux, puis numéro hors série).

### Cartes de sport
- Topps Chrome : base chromée, puis « Refractor » (arc-en-ciel au mouvement), puis une échelle de couleurs numérotées. Exemple 2018 : Purple /299, Blue /150, Green /99, Gold /50, Orange /25, Red /5, SuperFractor 1/1 (Cardboard Connection). Le SuperFractor a un fond or en spirale (Wikipedia). Variantes de motif au même niveau : Wave, X-Fractor (damier), Pulsar, Shimmer (checklistcenter, Wikipedia).
- Les tirages suivent une quasi-échelle géométrique : 299/250 → 150 → 99 → 75 → 50 → 25 → 10 → 5 → 1. La couleur code le tirage, le numéro tamponné le prouve.
- Panini Prizm : Silver (non numéroté, la référence du marché), couleurs (Red, Blue, Green), puis motifs numérotés (Mojo /25, Shimmer /5 à /35, Cracked Ice /25, Hyper /175), Gold /10, Gold Vinyl 1/1, Black Finite 1/1 (PSA, baseballcardpedia, sportcardscanner). Le noir est le sommet : le contraire du « plus brillant ».
- Autographes et patchs : la rareté devient contenu physique (signature, morceau de maillot). Pour nous : l'équivalent est la donnée unique de la prise (date, heure, lumière, lieu).
- EA FC Ultimate Team : bronze/argent/or comme matériaux, puis cartes spéciales à design propre, dont dynamiques [?: non confirmé par mes sources, seulement la page FC « designs dynamiques »].

### Magic, Lorcana, One Piece
- Magic : foil classique (tout noir bordé), etched foil (finition mate gravée, rétro), textured, confetti, galaxy, surge, double rainbow, gilded (wiki fandom) ; en plus : borderless, showcase, serialized. La finition est un catalogue horizontal ; le prestige vient du cadre et du numéro.
- Lorcana : symboles métalliques croissants (cercle gris, livre blanc, triangle bronze, losange argent, pentagone or, hexagone arc-en-ciel) ; Enchanted : sans bordure, plein cadre, foil arc-en-ciel, numéroté au-dessus du set ; environ 1 sur 96-100 boosters ; Iconic au-dessus (lorcanacardlist, dicebreaker, lorcanaplayer).
- One Piece : Manga Rare = noir et blanc type planche, trame et encrage ; la rareté passe par un changement de langage graphique, pas par plus de brillance. Cartes sérialisées < 2 000 exemplaires (tcgtalk, samuraisword).

### Numérique
- Pokémon TCG Pocket : losanges ◆ à ◆◆◆◆, puis étoiles ★ (plein cadre), ★★ avec bordure arc-en-ciel animée, ★★★ « immersive » (tenir la carte : elle s'ouvre en scène animée avec musique, bordure noire tourbillonnante), couronne = or, bordure holo dorée, spirale dorée, effets CGI. Tirages : couronne 0,04 %/0,16 %, immersive ~0,22 %/0,89 % (gamevika, pokebeach, cbr).
- Marvel Snap (système d'upgrade, wiki fandom, ancienne grille) : gris → vert « Frame Break » (la carte sort du cadre) → bleu 3D → violet animée → or logo brillant → rouge bordure animée → multicolore. Finitions (Foil, Prism, Ink, Gold), « flares » (Tone, Stardust, Glimmer, Krackle) ; Ink = noir et blanc, Gold = fond or ; Gold/Ink et Krackle seulement après 4-6 splits (marvelsnap.com, snap.fan). Leçon : on peut combiner fond (finition) et particules (flare) comme deux axes indépendants.
- Sorare : 5 paliers, couleurs liées (Common gris, Limited jaune 1 000, Rare rouge 100, Super Rare bleu 10, Unique noir 1) par joueur et par saison (sorare.com, sorareceo). Puissances de dix = lisible d'un coup.
- NBA Top Shot : Common (10 000+), Fandom, Rare (500-2 022, coins néon), Legendary (≤ 125), Ultimate (≤ 10) ; numéro de série par exemplaire, tirage limité affiché (/49, /299) (support.nbatopshot.com).

### Vocabulaire d'impression
- Hot foil (dorure à chaud) : matrice métal, chaleur et pression ; miroir très brillant, opaque, bords nets, combinable avec relief ; plutôt aplats, logos, texte (lihyangfoil, duplo).
- Cold foil (dorure à froid) : colle UV imprimée, le foil se pose dessous l'encre CMJN ; permet dégradés et illustrations brillantes ; c'est la méthode du « full art » moderne (vnkplayingcard, coldfoilstamping).
- Spot UV : vernis brillant local sur fond mat, très économique, effet « l'écran brille, le métal reste mat » (vnk).
- Embossage/débossage : relief en creux ou en bosse ; tactile ; hot foil + relief = signal « cher ».
- Lenticulaire, Cracked Ice, Mojo, Shimmer, Wave : vocabulaire de motifs ; seuls Cracked Ice, Wave, Shimmer, Mojo, Pulsar sont confirmés comme noms de parallèles ; leur dessin exact varie [?].
- Ce qui fait premium : un seul foil bien placé, du relief, des bords nets, le contraste mat/brillant sur la même carte, un numéro tamponné. Ce qui fait cheap : arc-en-ciel uniforme sur tout, paillettes aléatoires, fond holo sans zone mate, motif répété visible comme un papier cadeau [?: jugement de design, pas une source].

## 2. La grammaire (ce qui monte, et les règles de lisibilité)

Sept axes montent avec la rareté. On les active un par un, dans cet ordre de coût :
1. Surface de foil : 0 → éléments (symbole, filets) → fond hors illustration → plein cadre.
2. Complexité du motif : aucun → trame unie → motif à échelle unique → motif multi-échelles avec profondeur.
3. Relief physique : plat → vernis → gravure légère → gravure + dorure à chaud.
4. Perte de cadre : cadre complet → poisson qui mord le cadre → plein cadre sans bordure.
5. Mouvement : statique → reflet qui suit l'inclinaison → motif qui défile avec parallaxe → scène/animation à l'ouverture.
6. Matériau : papier → argent → nacre → or (le noir, dernier cran, comme Black Finite/Ultimate).
7. Numérotation : n° de collection → rang dans la série → tirage fini tamponné → exemplaire unique.

Règles pour garder 4 paliers lisibles :
- R1. Test niveaux de gris : à 80 px de large, en noir et blanc, les 4 cartes doivent se classer sans erreur (surface brillante et contraste, pas la teinte).
- R2. Une seule règle ajoutée par marche, jamais deux changements non liés (Pokémon ajoute une couche à la fois).
- R3. Le symbole (plomb, bouchon, cuiller, mouche) ne change jamais de forme avec la finition ; il porte le tirage, la finition porte le prestige.
- R4. Le motif ne dépasse pas 2 couleurs de base + le chatoiement ; sinon bruit (voir « arc-en-ciel uniforme » = cheap).
- R5. Toujours une zone mate sur la carte, même au sommet : la brillance n'existe que par contraste. Texte et chiffres restent lisibles à tout angle.
- R6. Le poisson reste la source d'émotion ; le foil habille le décor, jamais l'écaille de la photo/illustration (sauf légendaire : reflet fin, 15 % max).
- R7. Un palier = un signal tactile ou animé qui n'existe pas au palier d'en dessous (gravure, bordure animée, scène).
- R8. Les tirages suivent des puissances, pas des nombres fins (Sorare 1000/100/10/1 est plus lisible que 299/150/99/75).
- R9. Pas d'échelle de 12 couleurs : Topps et Panini en ont, mais ce sont des produits de chasse ; avec 4 paliers, on ajoute de la profondeur par variantes plus tard (voir §5).

## 3. Spec originale par palier
Fil conducteur : l'eau. Du sec (papier) au lumineux (surface de l'eau au soleil bas). Les noms sont à valider.
Données K existantes (raretes.png) : fond vert/bleu/argent/or, filets de ride en gravure, bandeau blanc incliné, symbole + n° 003.

### Commun : « Mat de berge »
- Matière : papier mat sans foil, grain fin de papier, teinte vert sous-bois. Aucun reflet.
- Foil : aucune. Seule marque : un filet de ride gravé à plat (encre un peu plus claire).
- Cadre : cadre simple, 1 filet fin, coins arrondis, ombre portée douce.
- Texture : grain papier (SVG feTurbulence très faible).
- Numérotation : « n° 003 » imprimé en encre ; mention « 24 pêches sur 29 » en texte.
- Verso : papier uni, motif de lignes de ride monochrome, symbole plomb en filigrane ; pas de foil.
- Mouvement : aucun reflet ; seulement l'ombre bouge au tilt (inertie).
- CSS : fond `linear-gradient`, `::before` avec `filter:url(#grain)` (feTurbulence baseFrequency .8, opacity .06).
- SwiftUI : aucune shader ; `.shadow` + `.rotation3DEffect` léger piloté par CoreMotion.

### Peu commun : « Reflet »  (logique spot UV / reverse holo)
- Matière : papier mat ; le décor reste mat, mais les filets de ride, le symbole bouchon et le numéro sont en vernis brillant (spot UV).
- Foil : zone = uniquement les éléments graphiques, pas le poisson ni le fond. Pattern : cercles concentriques de rides qui captent la lumière sur un axe (reflet blanc-bleuté).
- Cadre : filet doublé (1 clair, 1 sombre), liseré brillant sur le bandeau.
- Texture : vernis en relief imperceptible (ombre portée interne 1 px).
- Numérotation : « n° 014 » + mini-jauge de rareté (arc de 50 %).
- Verso : fond mat teinté, rides en vernis brillant, bouchon en filigrane brillant.
- Mouvement : un balayage de lumière diagonale qui suit l'inclinaison (une seule bande).
- CSS : couches des rides en `mask-image` (le tracé SVG des filets) ; au-dessus `background: linear-gradient(115deg, transparent 40%, rgba(255,255,255,.7) 50%, transparent 60%)`, `background-size:300%`, `background-position` lié à `--mx`; `mix-blend-mode: soft-light`.
- SwiftUI : `.colorEffect` mat/brillant avec masque du tracé ; bande lumineuse à partir de `attitude.roll/pitch`.

### Rare : « Nacre »  (logique full holo + gravure légère)
- Matière : argent nacré, texture « écailles » (mailles de losanges en quinconce), type foil à froid sous l'illustration.
- Foil : zone = tout le fond hors bandeau de données (le bandeau reste mat, R5). Pattern : écailles de poisson en tessellation, ~18 px, chatoiement dans deux teintes (bleu glacier + rose pâle) qui glissent au tilt.
- Cadre : filet gravé (guilloché de ligne de pêche : 2-3 courbes sinusoïdales entrelacées) en relief, bords biseautés.
- Texture : gravure fine sur les écailles (relief lu au toucher sur la carte physique) ; le poisson reste lisse.
- Numérotation : tampon « 021 / 094 » en dorure argent, avec le rang de la prise (« 3e sandre du 94 »).
- Verso : argent nacré avec guilloché de ligne, le symbole feuille/mouche en dorure à chaud.
- Mouvement : chatoiement piloté par l'angle ; un point lumineux ponctue les écailles lentement (5 s).
- CSS : `repeating-conic-gradient` ou `radial-gradient` en quinconce (background-size 18px 18px) pour les écailles, + `linear-gradient(var(--angle), #8fd3ff, #ffd6f1, #a6f3d9, #8fd3ff)` en `background-blend-mode: color-dodge` + `mix-blend-mode: overlay`; `filter: brightness(.9) contrast(1.3) saturate(.8)` (méthode de la collection pokemon-cards-css de simeydotme).
- SwiftUI : `.layerEffect` Metal : `fract(uv*scale)` pour la cellule d'écaille, `hue = fract(dot(tilt, uv)*k + ecaille_id*0.07)`, rendu en palette limitée ; `distortionEffect` léger pour le relief.

### Légendaire : « Cuiller d'or »  (logique plein cadre + gravure + or)
- Matière : or martelé (chrome de cuiller de pêche : surface de petites facettes concaves), le poisson sort du cadre (nageoires et queue débordent sur la bordure).
- Foil : zone = plein cadre, sauf bandeau mat crème. Pattern : caustiques d'eau (réseau lumineux de la surface au soleil) en or sur or, deux échelles (8 px et 40 px) qui se déplacent à vitesses différentes ; en plus un reflet nacre fin sur le poisson (15 %, R6).
- Cadre : disparaît ; remplacé par un filet de ligne de pêche qui boucle autour du poisson ; frame-break (queue qui passe devant le filet).
- Texture : martelage gravé (relief doux, lumière rasante), signature du palier.
- Numérotation : tirage fini tamponné « 009 / 029 » ou « 1er du 94 » en dorure à chaud, avec date et lumière de la prise (soleil est-nord-est, 4°). Rareté vraie : « 0 pêche sur 29 ».
- Verso : or martelé intégral, cuiller en filigrane gravé ; tranche dorée (en physique).
- Mouvement : caustiques animées en continu (lent), parallaxe en 3 couches (fond, poisson, avant-plan), tenir la carte 1 s = « ouverture » à la manière d'une carte immersive : le cadre disparaît et la scène de la prise se déroule (3-4 s).
- CSS : couche 1 `background: radial-gradient(...)` pour le martelage ; couche 2 caustiques : SVG `feTurbulence type="fractalNoise"` baseFrequency .012 + `feDisplacementMap` + `feSpecularLighting`/`feDiffuseLighting` (lumière or) animé par `<animate>` sur `baseFrequency` ou `seed` ; `mix-blend-mode: color-dodge` ; parallaxe : trois `translate3d` selon `--mx/--my`.
- SwiftUI : `.layerEffect` Metal : bruit de Worley ou 2 octaves de bruit pour les caustiques (`pow(min_dist,2)`), normale dérivée d'un height-map du martelage, éclairage Blinn-Phong or ; `TimelineView(.animation)` pour le temps ; CoreMotion pour la direction de lumière.

## 4. Récap comparatif
| Axe | Commun | Peu commun | Rare | Légendaire |
|---|---|---|---|---|
| Matière | papier mat | mat + vernis local | argent nacré | or martelé |
| Surface brillante | 0 % | ~10 % (éléments) | ~65 % (fond) | ~85 % (plein cadre) |
| Motif | aucun | rides vernies | écailles | caustiques 2 échelles |
| Relief | plat | vernis | gravure fine | gravure + martelage |
| Cadre | 1 filet | filet doublé | guilloché gravé | cadre brisé |
| Numérotation | n° | n° + jauge | /94 + rang | /29 + « 1er » |
| Mouvement | ombre | 1 bande | chatoiement | caustiques + parallaxe + ouverture |
Test R1 : en gris, 0 / 10 / 65 / 85 % de surface brillante et nombre de couches de motif = 0 / 1 / 2 / 3, donc classement net.

## 5. Mise en œuvre (priorités et pièges)
- Un seul composant `Carte(finition: .commun|.peuCommun|.rare|.legendaire)` ; les 4 finitions = jeux de couches empilées (base, brillance, motif, tampon) + paramètres (`--hue`, `--scale`, `--relief`). Une couche de plus par palier.
- Variables CSS communes : `--mx --my` (pointeur), `--angle`, `--hyp` (distance au centre), `--o` (opacité de la brillance).
- Chaque palier ajoute une couche : 0, +vernis, +écailles+gravure, +caustiques+parallaxe. Ainsi R2 est tenue par construction.
- Performances : un shader plein cadre par carte dans une liste est coûteux [?] ; en grille, finition statique (image pré-rendue) ; shader vivant seulement sur la carte ouverte. `prefers-reduced-motion` : on fige le motif, on garde la lumière statique.
- Accessibilité : le palier doit aussi être donné en texte (« Légendaire ») ; ne pas coder le palier seulement par la couleur.
- Capteurs : CoreMotion `CMMotionManager.deviceMotion.attitude` filtré (passe-bas) pour éviter le tremblement ; sur desktop, fallback au pointeur ; sur iOS 17+, `colorEffect`/`layerEffect`/`distortionEffect` (ShaderLibrary) [?: version exacte à confirmer pour votre cible].
- Extensions plus tard (pas dans le périmètre actuel) : variantes numérotées par palier (comme Topps) : « Étang », « Rivière », « Océan » en teintes, tirage /99, /25, /5 ; édition « Noir » 1/1 comme Black Finite/Ultimate : un poisson hors norme, finition encre et blanc.

## 6. Points non vérifiés ou à trancher
- [?] Noms de motifs de Topps/Panini (Cracked Ice, Mojo, Shimmer) : confirmés comme noms de parallèles, mais leur rendu exact varie ; nous ne les copions pas.
- [?] Rendu exact des écailles et caustiques : à tester en navigateur sur un vrai écran (règle d'Adem : vérifier à l'écran).
- [?] Combien de couches en SwiftUI sur de vieux iPhone : à mesurer.
- À trancher par Adem (design/produit) : (a) noms des 4 finitions ; (b) le légendaire garde-t-il un cadre brisé, ou un plein cadre sans bordure ; (c) numérotation « /29 » (nombre de pêches) ou « 1er du 94 » ; (d) l'ouverture animée du légendaire est-elle dans le périmètre de la version 1.

## Sources principales
- Bulbapedia, Cosmos Holofoil : https://bulbapedia.bulbagarden.net/wiki/Cosmos_Holofoil_(TCG)
- Pokémon officiel, product guide : https://tcg.pokemon.com/en-us/product-guide/
- TCGplayer, raretés Pokémon : https://help.tcgplayer.com/hc/en-us/articles/360025636074
- Bill's Archive (textures par rareté) : https://billsarchive.com/articles/pokemon-tcg-rarities.html
- PokéFolio (motifs de holo) : https://www.pokefolio.eu/en/blog/pokemon-holo-patterns-guide-masterball-cosmos
- Wikipedia, Refractor card : https://en.wikipedia.org/wiki/Refractor_card
- Cardboard Connection, Topps Chrome 2018 : https://www.cardboardconnection.com/2018-topps-chrome-baseball-cards
- baseballcardpedia, Prizm 2022 : https://baseballcardpedia.com/index.php/2022_Panini_Prizm
- sportcardscanner, hiérarchie Prizm : https://sportcardscanner.com/panini-prizm-cards-value.php
- MTG wiki, foils : https://mtg.fandom.com/wiki/Foil_card ; TCGplayer, etched foil
- Lorcana : https://lorcanacardlist.com/guides/lorcana-card-rarity-list ; https://www.dicebreaker.com/games/disney-lorcana/how-to/disney-lorcana-card-rarity-explained
- One Piece : https://tcgtalk.com/guides/one-piece-tcg-rarity-guide
- Pokémon TCG Pocket : https://gamevika.com/en/ptcgp/wiki/rarity-guide ; https://www.cbr.com/pokemon-tcg-pocket-get-immersive-cards
- Marvel Snap : https://marvelsnap.fandom.com/en/wiki/Infinity_Splits ; https://snap.fan/guides/infinity-splits-and-frame-breaks-guide
- Sorare : https://sorare.com/help/a/4406429217053/understanding-sorare-cards-pro-set-and-scarcity-levels
- NBA Top Shot : https://support.nbatopshot.com/hc/en-us/articles/4404373783827-Moment-Tiers
- Impression : https://coldfoilstamping.com/blog/hot-vs-cold-foil-stamping ; https://vnkplayingcard.com/the-2026-guide-to-custom-tcg-printing-mastering-cold-foil-holographics-and-full-art-styles
- CSS holo : https://poke-holo.simey.me/ ; https://css-tricks.com/holographic-trading-card-effect
