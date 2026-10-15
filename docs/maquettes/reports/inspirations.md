# Inspirations visuelles de l'app (nom encore à choisir ; « Pescedex » = la collection de cartes) : cartes + carte d'accueil

Décision débloquée : choisir 3 directions A/B/C pour l'écran de révélation de carte et la carte d'accueil.
Légende : [vérifié] = lu dans une source de la recherche ; [?] = non vérifié, issu de ma mémoire ou d'une déduction.
Les hex proposés dans les directions sont des choix de ma part, pas des couleurs mesurées sur les références.

## 1. Apple Design Awards 2024-2026

- Art of Fauna (ADA 2025 Innovation, jeu) — https://www.screenhub.com.au/news/news/apple-design-awards-2025-winners-2669019
  À voler : « imagerie animalière d'inspiration vintage » + puzzle. Preuve qu'une planche naturaliste illustrée passe en jeu mobile primé. [vérifié pour la description]
- CapWords (ADA 2025 Delight and Fun) — https://developer.apple.com/articles/capwords
  À voler : la photo devient un autocollant détouré (VisionKit), et un vrai son accompagne chaque transition de carte. Notre « photo de prise vers carte » peut passer par un détourage du poisson. [vérifié]
- Balatro (ADA 2025 Delight and Fun, jeu de cartes) — https://developer.apple.com/design/awards/2025/
  À voler : les cartes sont des objets avec des effets d'édition (jokers à capacités). Le détail précis du shader CRT est [?]. [vérifié : description Apple]
- Crouton (ADA 2024 Interaction) — https://www.apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards
  À voler : interactions qui laissent l'attention sur la tâche, pas sur l'écran. Utile pour le Live Activity du décompte de fin de pêche. [vérifié]
- Gentler Streak (ADA 2024 Social Impact) — https://gentlerstories.com/
  À voler : vue mensuelle qui compare à son propre historique, jamais aux autres. Bon ton pour la « sortie bredouille » : pas de honte. Finaliste Visuals and Graphics 2023. [vérifié]
- Lost in Play (ADA 2024 Innovation, jeu) — https://www.apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards
  À voler : le style visuel exact (dessin animé fait main) n'a pas été lu ; ne rien affirmer. [?]
- ADA 2026 (liste existante) — https://developer.apple.com/design/awards
  Winner Delight and Fun app : grug (Ocho, Pays-Bas) ; finaliste cité : Metaballs (Apposite). Je n'ai pas vu leurs écrans. [vérifié pour les noms seulement]
- Non couvert : Flighty (passeport), Finch, (Not)Boring. Aucun résultat lu. [?]

## 2. Liquid Glass (iOS 26)

- HIG Materials — https://developer.apple.com/design/human-interface-guidelines/materials
  Règle : le verre = couche de contrôles et navigation (barres d'onglets, barres latérales) qui flotte au-dessus du contenu. « Ne pas utiliser Liquid Glass dans la couche contenu », fonds d'app en matériaux standard. Exception : curseurs et interrupteurs prennent l'aspect verre quand on les active. [vérifié]
- WWDC25 « Meet Liquid Glass » — https://developer.apple.com/videos/play/wwdc2025/219
  Deux variantes, Regular et Clear, à ne jamais mélanger ; Clear exige du contenu riche dessous et un calque d'assombrissement. Pas de verre sur du verre. [vérifié]
- Adopting Liquid Glass — https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
  Retirer les fonds personnalisés des barres, usage parcimonieux sur les contrôles custom, espacements standards. [vérifié]
- Conséquence pour l'app : la CARTE (contenu) ne doit pas être en verre. Seuls la barre d'onglets, le bouton d'appareil photo et la pastille de décompte le sont. Le papier, le foil et l'encre portent la personnalité.
- Exemples tiers de Liquid Glass réussis : non trouvés dans cette recherche. [?]

## 3. Cartes à collectionner et révélations

- simeydotme/pokemon-cards-css — https://github.com/simeydotme/pokemon-cards-css , démo https://poke-holo.simey.me/ , explication https://simey.me/projects/pokemon-holo
  Technique [vérifié] : variables CSS (--pointer-x, --pointer-from-left, --rotate-x/y, --card-opacity) pilotées par un ressort (spring) sur le pointeur/gyroscope ; calques de dégradés (rainbow + barres diagonales) avec mix-blend-mode: color-dodge, filter brightness/contrast/saturate, masques clip-path par zone ; background-position lié au curseur. Licence GPL-3.0 : s'inspirer de la méthode, ne pas copier le code. Composant plus léger du même auteur : https://github.com/simeydotme/hover-tilt
  Équivalent natif iOS : CoreMotion + shader Metal (SwiftUI colorEffect) [?, déduction].
- Pokémon TCG Pocket (ouverture) — https://www.polygon.com/pokemon/452814/pokemon-trading-card-game-pocket-opening-pack-feel
  À voler : un geste unique qui imite le réel (tracer un trait pour déchirer le paquet). [vérifié]
- Pocket, séquence détaillée — https://60fps.design/shots/poke-mon-tcg-pocket-swipe-packet-to-reveal-card-interaction
  Trace lumineuse, déchirure, carte qui glisse vers le haut et s'agrandit, éclat + badge NEW. Flip : reflet holographique balayant l'illustration, étoile rebondissante en bas à gauche (ressort), puis « Tap to proceed ». [vérifié]
- Critique Pocket — https://www.ixd.prattsi.org/2025/09/design-critique-pokemon-tcg-pocket-android-app
  Défaut à éviter : rien n'indique qu'on peut incliner la carte. Ajouter un indice visible. [vérifié]
- Animal Crossing Critterpedia, Marvel Snap, Hearthstone, Sorare, Topps, NBA Top Shot, Panini, Pikmin Bloom, Seek : aucune source lue sur la mise en page. [?]
- Seek by iNaturalist — https://apps.apple.com/gb/app/seek-by-inaturalist/id1353224144
  Badges par groupes (oiseaux, amphibiens, plantes, champignons) et défis mensuels. Idée : badges par famille (carnassiers, cyprinidés, salmonidés). [vérifié pour le principe]

## 4. Références pêche et nature

- Marcus Élieser Bloch, Naturgeschichte der Fische (1782-1795, 432 planches cuivre coloriées à la main) — https://de.wikipedia.org/wiki/Marcus_%C3%89lieser_Bloch
  Traduction française « Ichthyologie » (Laveaux, 1785-97). Chaque planche porte le nom de son mécène imprimé : idée pour une carte « signée » du pêcheur. [vérifié]
- Scans libres : BHL https://www.biodiversitylibrary.org/bibliography/46381 (statut domaine public indiqué) ; Wikimedia « Ichtyologie ou Histoire naturelle… (Pl. LXIII) » 6128 x 3304 px ; Picryl https://picryl.com/collections/marcus-elieser-bloch-17231799-680851 . [vérifié]
  À voler : poisson de profil, pleine largeur, légende en bas. Les tons exacts du papier sont [?], à échantillonner sur un scan.
- Gyotaku — https://en.wikipedia.org/wiki/Gyotaku
  Encre sumi sur papier washi ; les pêcheurs enregistraient leurs prises ainsi, et les prints pendent encore dans les boutiques d'appâts au Japon. À voler : la carte « sortie bredouille » = une empreinte vide, ou le contour au sumi d'un poisson non pris. [vérifié]
- Deyrolle — https://deyrolle.com/ (institution depuis 1831, cabinet de curiosités). Planches pédagogiques : aucune mise en page lue, [?]. À voler probable : fond crème, légende numérotée, bordure fine.
- IGN Scan 25 — https://www.data.gouv.fr/datasets/scan-25-r-touristique ; spécifications https://geographie.ipt.univ-paris8.fr/rubriks/carto/journalGR/photos/l%C3%A9gendeIGN25_2000.pdf
  Images raster de la série 1:25 000 ; courbes de niveau, hydrographie. Conditions d'usage IGN à vérifier avant d'utiliser le fond tel quel (https://geoservices.ign.fr/cgu-licences#cgu). Couleurs exactes de l'hydrographie : [?].
- Fédération nationale de la pêche — https://www.cartedepeche.fr/ : cartes Découverte -12 ans, Femme, Journalière, Hebdomadaire. À voler : le vocabulaire (« carte journalière ») pour nommer les raretés ou les éditions. L'identité visuelle n'a pas été analysée. [?]
- Fishbrain — https://fishbrain.com/ : 20 M de prises, 14 M d'emplacements, cartes bathymétriques Garmin. C'est le produit-repère à ne pas imiter (carte utilitaire dense, sombre). Capture d'écran non analysée. [vérifié pour les chiffres]
- Catchdex — https://play.google.com/store/apps/details?hl=en_US&id=com.findex.app : identification par photo + journal. Concurrent direct ; mise en page non vue. [?]
- VISDEX, emballages d'appâts vintage, Sibley/Peterson : rien lu. [?]

## 5. Polices (toutes vérifiées sur Google Fonts / Fontsource)

- Fraunces — axes opsz 9-144, wght 100-900, SOFT, WONK ; « soft-serif old style » inspiré de Windsor, Souvenir, Cooper. https://fonts.google.com/specimen/Fraunces · @fontsource-variable/fraunces
- Instrument Serif — condensée, pour grandes tailles. https://fonts.google.com/specimen/Instrument+Serif · @fontsource/instrument-serif
- Bricolage Grotesque — axes poids, chasse, optical size ; pièges d'encre exagérés en petit corps. Conçue par Jérémy Landes (France). https://fonts.google.com/specimen/Bricolage+Grotesque · @fontsource-variable/bricolage-grotesque
- Big Shoulders Display — gothique américain condensé, variable, variante Stencil. https://fontsource.org/fonts/big-shoulders-display · @fontsource-variable/big-shoulders-display [nom du paquet npm : ?]
- Young Serif — old style très gras (Plantin Infant). https://fonts.google.com/specimen/Young+Serif
- Gloock — serif à fort contraste, une graisse. https://fontsource.org/fonts/gloock
- Newsreader — serif à axe optical size. https://fonts.google.com/ (page non lue) [?]
- IBM Plex Mono — chiffres techniques. https://fonts.google.com/specimen/IBM+Plex+Mono

## 6. Directions candidates

Probabilité = mon estimation qu'un autre LLM la propose, non mesurée. Aucune n'utilise Inter, dégradé violet ni héros centré.

1. PLANCHE BLOCH (probabilité ~25 %)
   Polices : Fraunces (titres, opsz 144, SOFT 50) + IBM Plex Mono (légendes numérotées).
   Couleurs : papier #EDE3CC, encre cuivre #2B3A2F [teintes à vérifier sur un scan].
   Audace : le poisson occupe toute la largeur en profil, la carte est horizontale ; on tourne le téléphone en paysage pour la révélation.
2. EMPREINTE GYOTAKU (probabilité ~8 %)  < 20 %
   Polices : Gloock (nom du poisson) + Bricolage Grotesque (données).
   Couleurs : washi #F4EFE6, sumi #14110F, un tampon rouge hanko #C8321E.
   Audace : la carte se révèle par une empreinte d'encre qu'on frotte du doigt ; la rareté = la netteté des écailles imprimées. Bredouille = feuille vierge avec un seul tampon.
3. CARTE IGN, RÉVÉLATION PAR COURBES DE NIVEAU (probabilité ~12 %)  < 20 %
   Polices : Bricolage Grotesque (condensée, majuscules) + IBM Plex Mono.
   Couleurs : bleu hydro #1F6FB5 [?], fond orange-crème #F3E6C8 [?].
   Audace : l'accueil est une vraie carte topo ; le fond de la carte-poisson est le relief du spot où il a été pris, et la rareté se lit en nombre de courbes.
4. BOÎTE D'APPÂTS 1960 (probabilité ~15 %)  < 20 %
   Polices : Big Shoulders Display (Stencil pour les numéros de lot) + Young Serif.
   Couleurs : jaune carton #E8B422, vert sapin #1E3B2C.
   Audace : un collage de couvercle de boîte à leurres ; les cartes sont des étiquettes numérotées collées dans une boîte compartimentée en grille irrégulière.
5. PASSEPORT / LICENCE (probabilité ~30 %)
   Polices : Instrument Serif + IBM Plex Mono.
   Couleurs : bleu-vert fédération #0F5C5A [?], crème #F6F1E4.
   Audace : chaque prise est un tampon dans un livret ; l'animation de révélation est un coup de tampon avec léger décalage.
6. SPÉCIMEN ÉPINGLÉ (probabilité ~10 %)  < 20 %
   Polices : Newsreader (opsz élevé) + Big Shoulders Display (numéros).
   Couleurs : noir de vitrine #121816, laiton #B8903D.
   Audace : sous verre, un poisson sur fond sombre éclairé par le gyroscope (méthode simey : lumière suivant l'inclinaison) ; le foil est un reflet de vitrine, pas un arc-en-ciel.

## 7. Reco pour la planche A/B/C
Prendre trois directions éloignées entre elles : 2 (gyotaku), 3 (IGN) et 1 (Bloch) ou 4 (boîte d'appâts). Chaque verre Liquid Glass reste limité à la barre d'onglets, au bouton photo et au décompte.
Question à Adem avant maquette : quelles 2-3 références à lui (règle CLAUDE.md sur le design) et lequel de ces 3 mondes lui parle ?
