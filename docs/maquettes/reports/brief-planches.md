# Brief commun des planches A/B/C (écran : révélation de la carte de prise)

## L'écran (étapes E5 fin et E6 de build/parcours-demo.md)
Juste après la photo, l'iPhone a reconnu l'espèce. Cet écran montre en une vue :
1. la carte à collectionner (le contenu principal, environ 60 % de la hauteur) ;
2. le verdict « tu peux le garder ? » ;
3. deux actions : ranger dans le Pescedex, partager.

Pescedex = nom de l'onglet collection. Le nom de l'app n'est pas choisi : ne l'écris nulle part. Jamais le mot « Poké ».

## Contenu exact (identique sur les trois planches, exemple fictif)
- Espèce : Brochet, *Esox lucius*
- Longueur : 68 cm, pris le 12 oct. 2026 à 17 h 42, la Marne à Champigny-sur-Marne (94)
- Rareté : palier 2 sur 3, « Peu commun dans le Val-de-Marne », avec la phrase différenciante « Commun en Seine-et-Marne, peu commun ici » et la source « d'après les relevés de l'OFB »
- Numéro : n° 014 dans le Pescedex, « 4 espèces sur les 11 relevées dans le 94 »
- Verdict : GARDER POSSIBLE. Raisons sur deux lignes : « Taille mini 60 cm, le tien : 68 cm. » « Ouvert jusqu'au 25 janv. · 2 brochets max par jour. » Mention « Règle nationale, indicative » et lien « Signaler une erreur ».
- Actions : « Ranger dans le Pescedex » (principale), « Partager » (secondaire).

## Le poisson sur la carte : la photo du pêcheur détourée
Dans l'app, le poisson de la carte est la photo du pêcheur détourée par l'iPhone (VisionKit), pas un dessin. Le style de la planche est donc un traitement appliqué à ce détourage, faisable en SwiftUI / Core Image en quelques heures (filtre encre, papier, trame, cadre). En maquette, l'illustration de `../assets/fish/` tient lieu de détourage ; applique-lui le traitement de ta direction et dis dans notes.md comment on le reproduit sur iPhone.

## Ce qu'on reprend d'apps réelles (voir ecrans-references.md et inspirations.md)
- Pokémon TCG Pocket : une seule carte, rareté lue par un symbole fixe en bas à gauche (forme + couleur, jamais la couleur seule), effet spécial réservé aux raretés hautes. Ici palier 2 = effet discret.
- Reflet piloté par l'inclinaison (méthode du projet pokemon-cards-css de simeydotme, licence GPL : reprendre la méthode, réécrire le code). En maquette : suit le pointeur, et un état figé joli sans mouvement.
- Fish Rules / Fishbrain Rules : verdict en un mot + pictogramme, puis la règle qui le justifie sur deux lignes, réglette de taille (68 posé au-dessus de 60).
- CapWords (ADA 2025, Delight) : le sujet photographié devient un objet détouré.
- Apple HIG Liquid Glass : le verre seulement sur la couche contrôles (boutons flottants, barre du bas), jamais sur la carte, jamais verre sur verre.
- `prefers-reduced-motion` : l'effet devient un fondu.

## Contraintes techniques
- Un seul fichier `index.html` dans ton dossier `planche-X/`, qui s'affiche à 393 × 852 (iPhone 16/17 Pro) : barre d'état iOS (9:41, réseau, batterie) et Dynamic Island dessinées, indicateur d'accueil en bas.
- Tout est local : polices et bibliothèques depuis `../assets/` (voir `../assets/README.md`). Aucun appel à un CDN, l'ordinateur de capture est hors ligne sauf Google Fonts. Pas d'image inventée en SVG grossier pour le poisson : utilise les illustrations de `../assets/fish/` (sinon dis-le).
- Icônes : une vraie bibliothèque (Phosphor ou équivalent dans `../assets/vendor/`), un seul style de trait. Aucun emoji.
- Interdits (règles d'Adem + impeccable) : Inter, Roboto, Space Grotesk, Fraunces, dégradé violet/bleu, cartes arrondies identiques, texte en dégradé, bordure gauche colorée, ombre décalée dure, étiquette au-dessus d'un titre (kicker), glyphes Unicode en guise d'icônes, verre décoratif.
- Contraste ≥ 4,5:1 pour le texte courant.
- Texte : français naturel, pas de ton promo.

## Vérification qui bloque la livraison
1. `node /tmp/claude-0/-home-claude/712da50a-e7d6-5a83-90bb-bc72b4d3b0cc/scratchpad/shot/shot.mjs <ton index.html> <ton dossier>/capture.png 2500` doit afficher « no console errors ».
2. `node /home/claude/claude-config/.claude/skills/impeccable/scripts/detect.mjs <ton index.html>` : zéro anti-pattern, ou chaque reste justifié dans notes.md.
3. Regarde ta capture (outil Read sur le PNG) et corrige ce qui déborde ou se chevauche. Une passe de correction, une passe de confirmation, puis stop.

## À livrer dans `planche-X/`
`index.html`, `capture.png`, et `notes.md` (30 lignes max) : la direction en une phrase, police et couleurs (hex), l'audace unique, les apps réelles dont chaque élément est tiré, ce que tu n'as pas pu faire.

## Garde-fou anti-slop supplémentaire (skill Refero, references/anti-ai-slop.md, copié dans reports/refero-skill/)
Le nouveau cliché d'IA : fond crème ou ivoire + grand titre serif à fort contraste + un mot en italique + tons olive/terre cuite + beaucoup d'air. Interdit sauf si ta direction le justifie par une référence précise. Pas de mode sombre par défaut. Pas de cartes partout : seule la carte à collectionner est une carte. Lis aussi `reports/refero-skill/references/craft-details.md` et `typography.md` avant de coder.

## Les trois directions (une par planche, chacune ancrée sur des apps réelles)
- **A. Carte de sport brillante** : Pokémon TCG Pocket (révélation, symbole de rareté), cartes Topps NOW / Panini (bandeau du nom, numéro de série, dos imprimé). Fond d'écran blanc froid, carte saturée qui porte toute la couleur, sans-serif grasse et étroite (Bricolage Grotesque condensée 700 ou Big Shoulders si disponible), chiffres en IBM Plex Mono. Couleurs : eau verte #0E6B5C, jaune balise #F2C230, encre #101418. Audace : le foil holographique du palier 2 dessiné comme les reflets d'une surface d'eau (ondulations), pas un arc-en-ciel.
- **B. Guide de terrain précis** : Merlin Bird ID et Seek (identification, fiche espèce), Fish Rules (verdict), AllTrails / IGN (carte). Interface claire, utilitaire, dense et lisible au soleil au bord de l'eau. Hanken Grotesk ou Familjen Grotesk + IBM Plex Mono pour les mesures. Couleurs : blanc #FFFFFF, bleu hydrographie IGN #1F6FB5, une seule couleur de verdict (vert #1E7F4F). Audace : la carte à collectionner porte au dos et en fond la vraie topographie du spot (courbes de niveau et tracé de la rivière en traits fins, d'après assets/geo), comme un extrait de carte IGN.
- **C. Empreinte gyotaku** : tradition japonaise de l'empreinte d'encre du poisson pris, + CapWords (ADA 2025 : la photo devient un objet). Le poisson devient une empreinte noire sumi sur papier, cachet rouge hanko #C8321E qui porte la rareté. Pas de serif éditoriale : titre en sans-serif très grasse (Darker Grotesque 700 ou Bricolage 700), légendes en DM Mono. Fond papier blanc cassé froid #F5F3EE, encre #14110F. Audace : la carte se révèle comme une empreinte qui apparaît par pression (animation de l'encre qui monte), et le tampon rouge tombe en dernier.

## Passe de correction après critique (critique-jury.md, critique-craft.md)
Communs aux trois planches :
1. Le verdict passe EN HAUT, en bandeau compact, avant la carte : pictogramme + « GARDER POSSIBLE » + réglette graduée avec chiffres (0, 20, 40, 60 mini, 80) et repère 68. La réglette vient de la planche B. Les deux lignes de raisons et « Règle nationale, indicative · Signaler une erreur » restent sous le bandeau, en petit. Le verdict doit avoir un signal de forme ET de couleur qui le distingue de « REMETTRE À L'EAU ».
2. Aucune position exacte sur la carte (elle sera partagée) : lieu = « La Marne, Val-de-Marne (94) ». Pas de coordonnées GPS, pas de repère de spot, pas de nom de commune.
3. Barre d'état iOS fidèle : barres de réseau, Wi-Fi et batterie dessinés comme sur iOS (pas d'icône Phosphor), heure 9:41 en graisse semibold.
4. Chaque info n'apparaît qu'une fois : « Palier 2 sur 3 » et « peu commun » une seule fois chacun.
5. Pas de mono en costume : le mono seulement pour les mesures et le numéro.
6. Pas de césure dans un nom propre ; mesure de texte confortable.
7. Correction données (fil Plan de construction) : remplacer « 12 espèces sur 31 dans le 94 » par « 4 espèces sur les 11 relevées dans le 94 » (barre segmentée 4/11).

## Deuxième série (planches D, E, F) : MINIMALISTE
Adem (15h18) : « fais d'autres styles », puis « fais en sorte que ce soit minimaliste, là c'est encore trop bruyant ». Les planches A, B, C sont jugées trop chargées.

Règles de cette série (elles priment sur le contenu exact plus haut) :
- Un seul héros : le poisson, grand. Tout le reste se tait.
- Recto de la carte : nom, 68 cm, marque de rareté, n° 014. Rien d'autre. Date, lieu (« La Marne, Val-de-Marne (94) »), phrase de rareté départementale (« Commun en Seine-et-Marne, peu commun ici · relevés OFB ») et « 4 sur les 11 relevées dans le 94 » passent sur UNE ligne discrète sous la carte, ou au verso (indique « Toucher pour retourner »).
- Verdict : une seule ligne en haut (pictogramme + « Garder possible » + « 68 / 60 cm mini »), puis une réglette fine sans hachures. Les raisons détaillées et « Règle nationale, indicative · Signaler une erreur » derrière un bouton info discret ou en une ligne de 12 px.
- Au plus 2 tailles de texte sur la carte, 3 sur l'écran. Une seule couleur d'accent. Pas de texture, pas de trame, pas de bordure décorative, pas de tampon. Un seul effet de lumière, très discret, réservé à la rareté.
- Actions : « Ranger dans le Pescedex » (principale) et « Partager » dans la barre de verre ; « Je le relâche » en lien texte discret (réponse d'Adem en attente, défaut oui).
- Minimaliste ne veut pas dire générique : pas de cartes blanches arrondies identiques façon SaaS. La retenue doit venir d'une idée.

Les trois directions :
- **D. Couleur prélevée** : comme Apple Music et Flighty (ADA), le fond de la carte est un aplat unique de la couleur dominante du poisson (calculée sur la photo, en SwiftUI c'est une moyenne de couleur ; ici prélève-la sur brochet.png), le poisson détouré énorme qui déborde du cadre, nom et taille en très grand, rien d'autre. Écran blanc autour. Hanken Grotesk. ~15 % de chances qu'un autre LLM la propose.
- **E. Étiquette de muséum** : comme les tiroirs de collection d'histoire naturelle : fond blanc pur, le poisson posé seul sans cadre, et une petite étiquette rectangulaire (n° d'inventaire, nom, taille, palier) reliée au poisson par un fil fin. Une seule famille de caractères : Familjen Grotesk, chiffres en IBM Plex Mono. ~10 %.
- **F. Vitrine noire** : fond noir profond #0A0B0B, le poisson éclairé par une seule source de lumière chaude qui suit l'inclinaison, texte blanc cassé, un seul point de couleur pour la rareté. C'est le seul style sombre, justifié par la vitrine éclairée et la photo de nuit au bord de l'eau. Hanken Grotesk. ~12 %.

## Troisième série (planches G, H, I) : anatomie des cartes Pokémon
Adem (16h37) : « inspire toi des cartes pokemon etc bro ». Garder l'acquis de la série minimaliste (peu de bruit autour de la carte, verdict en haut sur une ligne + réglette fine, barre de verre en bas, « Je le relâche » en lien), mais la CARTE elle-même reprend l'anatomie d'une vraie carte du jeu de cartes Pokémon, traduite pour la pêche :
- en haut : nom à gauche, et à la place des PV la taille « 68 cm » à droite, avec le pictogramme du « type » d'eau (eau calme / eau vive / étang) ;
- fenêtre d'illustration : le poisson détouré (../assets/fish/brochet.png) ;
- sous l'illustration, la petite ligne d'info (Pokémon : « N° 0025 · Souris · 0,4 m ») → « Esox lucius · Carnassier · pris le 12 oct. 2026 » ;
- deux « attaques » qui sont de vraies infos de pêche utiles : « Leurre souple · Bordures d'herbiers » et « Meilleure heure · Aube et crépuscule » (avec un coût en petits ronds = difficulté) ;
- la rangée « faiblesse / résistance / retraite » devient la règle : « Mini 60 cm · Ouvert jusqu'au 25 janv. · 2 / jour » ;
- en bas : texte d'ambiance façon Pokédex en une phrase vraie (« Chasseur à l'affût, il attend immobile dans les herbiers avant de jaillir. »), la rareté départementale (« Peu commun dans le 94 · relevés OFB »), le symbole de rareté et le numéro de série « 06/14 » (6e des 14 espèces jouables) avec le symbole de la collection Pescedex ;
- palier 2 = effet holographique discret au pointeur (méthode simeydotme, réécrite) ; jamais d'arc-en-ciel criard.
Propriété intellectuelle : s'inspirer de la structure, ne pas copier l'habillage (pas de cadre jaune Pokémon, pas de symboles d'énergie, pas de police Pokémon, jamais le mot « Poké »). La carte doit se reconnaître comme « carte de jeu » sans être confondue avec une carte Pokémon. Recherche web autorisée pour vérifier l'anatomie exacte d'une carte (load mcp__Parallel_Search__web_search via ToolSearch).

Les trois variantes, chacune d'après une génération réelle de cartes :
- **G. Carte classique** : d'après les cartes standard (série Écarlate et Violet) : cadre plein d'une couleur de type (vert d'eau calme #2F7F6F), fenêtre d'illustration encadrée, zone de texte claire. Bricolage Grotesque 700 pour le nom, Hanken Grotesk pour le texte. Hologramme limité à la fenêtre d'illustration.
- **H. Pleine illustration** : d'après les cartes « Illustration rare » : l'illustration occupe toute la carte, le poisson dans son milieu (eau sombre et lumière qui traverse, faite de dégradés et de caustiques en SVG ou CSS, pas d'image inventée), le texte posé en bas sur un voile. Hologramme sur toute la carte, texturé.
- **I. Carte numérique épurée** : d'après Pokémon TCG Pocket : carte blanche très propre, grandes marges, typographie fine, symboles de rareté en petites formes géométriques, la carte flotte légèrement en 3D et s'incline au pointeur. Hanken Grotesk seul.
Mise à jour (Adem, 16h41 : « pas que pokemon, y a plein de cartes à collectionner ») : G reste la carte classique façon Pokémon ; H devient **carte EA FC Ultimate Team** (note globale = rareté dans le département, 6 statistiques, matière argent pour le palier 2) ; I devient **vignette Panini** (la prise se colle dans sa case numérotée de l'album Pescedex, cases vides grises).

## Quatrième série (planches J, K) : NOTRE carte, quatre raretés
Adem (16h53) : « G et H sont pas mal du tout, mais tu peux mieux faire » ; (16h55) « il faut une certaine originalité par rapport aux autres ; classifier : commun, peu commun, rare, légendaire ; puis créer notre propre design ». Lire `reports/critique-g-h.md` (critique d'art direction) avant de coder. On repart DE ZÉRO (pas de retouche de G/H), en gardant l'écran calme (verdict sur une ligne en haut, barre de verre, « Je le relâche »).

Système de rareté maison (forme lisible à 13 px sans couleur, matière qui monte avec le palier) :
| Palier | Symbole (pictogramme dessiné en SVG) | Matière de la carte |
|---|---|---|
| Commun | Plomb (petit disque plein) | papier mat, aucun reflet |
| Peu commun | Bouchon (flotteur bicolore) | nacre irisée sur l'illustration seule, intensité ≤ 0,35 |
| Rare | Cuiller (leurre ovale) | chrome miroir sur toute la carte, lignes prismatiques |
| Légendaire | Mouche (mouche de pêche à plumes, dessinée finement) | or chaud + l'illustration casse le cadre + lumière animée permanente |
Le brochet du 94 est « peu commun ». Jamais de losanges, d'étoiles ou de couronnes.

Livrables par planche : `index.html` (l'écran iPhone, brochet peu commun) + `raretes.html` (planche large 1600×900 : la même carte en commun / peu commun / rare / légendaire côte à côte, avec quatre espèces du 94 : gardon commun, brochet peu commun, sandre rare, black-bass légendaire) + leurs captures (`capture.png`, `raretes.png` ; pour raretes.html, adapte la taille de fenêtre en copiant shot.mjs dans ton dossier) + notes.md.

- **J. La toise** (lignée G, signature à ~8 %) : le cadre de la carte EST une toise de pêcheur : le museau calé contre la butée à gauche, la queue tombe sur le trait 68, le trait de taille mini 60 a un cran. La réglette du haut disparaît de l'écran (le verdict reste en une ligne). Illustration ≥ 55 % de la hauteur de carte, poisson ≥ 30 % de la surface, une nageoire déborde du cadre de 10-14 px. Nom 30 px, « 68 » 32 px, puis 2 tailles. Une seule info de pêche au recto. Carte ≈ 361 px de large.
- **K. La lumière de l'heure de prise** (lignée H, signature à ~4 %) : le reflet de la carte suit la vraie position du soleil au moment et au lieu de la prise (17 h 42 le 12 oct. dans le 94 : soleil bas, chaud, venant de l'ouest-sud-ouest) ; une prise de nuit aurait un reflet de lune froid (montre-le sur une des quatre cartes de raretes.html). Stats honnêtes seulement, en unités réelles, valeurs marquées « exemple » dans notes.md : TAI 68 cm (mesurée), CEN (centile de taille parmi les brochets mesurés par l'OFB dans le 94) en grand nombre, FRQ (part des stations OFB du 94 où l'espèce est relevée), ÂGE ≈ (estimé depuis la taille), SAI (jours ouverts dans l'année), EAU (température de l'eau, relevé le plus proche). Lignes de profondeur de la rivière gravées en motif de fond, pas de chevrons. Plaque de stats lisse, contraste ≥ 7:1, stats en 26 px. La tête dépasse du haut de la carte de 16 px avec son ombre.
Pour les deux : le poisson comme vrai sujet (liseré de lumière côté soleil, ombre de contact + ombre longue, +8 % de contraste, un plan qui passe devant lui), 3 plans en parallaxe à l'inclinaison, révélation ≈ 1,4-1,6 s puis état final, reduced-motion = fondu.
Correction données (fil Plan de construction, 16h56) : seuils par défaut commun ≥ 50 % des pêches OFB, peu commun 20-50 %, rare < 20 %, légendaire = jamais relevé dans le département. Dans le 94 (29 pêches depuis 2016) : gardon commun, brochet peu commun, sandre rare, truite fario légendaire (« 0 pêche sur 29 »). Le black-bass est rare, pas légendaire.
