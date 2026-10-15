# Brief : 6 univers de jeu, plus enfantins (série U)

Demande d'Adem (12 oct., 22:50) : « un design inspiré d'un jeu, comme Pokémon, plus enfantin, moins pro. Va trouver des inspirations un peu partout, propose des choses d'un autre univers complètement, garde le style liquid glass, explore plein d'univers, et fais des choses cohérentes. » La série K (carte « lumière de l'heure ») est gardée de côté, pas jetée.

Source des univers : `reports/univers-jeux.md` (lire la section de ton univers et les références qu'elle cite). Les hex et polices y sont des points de départ ; échantillonne et vérifie.

## Ce que chaque univers livre (dossier `maquettes/univers/<lettre>-<nom>/`, rien hors de ce dossier)
1. `carte.html` + `carte.png` : l'écran d'accueil, la carte des coins de pêche autour de soi (E1). La Marne dans le Val-de-Marne (94), 5 coins nommés A à E, un coin sélectionné avec sa fiche courte (« Coin B · 2,4 km · 3 espèces relevées »), barre d'onglets Carte / Pescedex / Moi + bouton central Sortie.
2. `prise.html` + `prise.png` : la révélation de la carte de prise (E6) : un brochet de 68 cm, peu commun dans le 94 (10 pêches sur 29), « Garder possible · 68 / 60 cm mini », bouton « Ranger dans le Pescedex » et « Partager ». Une seule animation signée (état final à 2,5 s, prefers-reduced-motion = fondu).
3. `raretes.html` + `raretes.png` (vue large 1600x900) : les 4 raretés côte à côte, gardon commun, brochet peu commun, sandre rare, truite fario légendaire (« jamais relevée ici »). Les 4 se distinguent en noir et blanc, pas seulement par la couleur.
4. `notes.md` : références réelles utilisées (liens), palette, police, ce qui rend l'univers enfantin, risques, et la probabilité qu'un autre LLM propose cet univers.

## Règles communes
- iPhone 393x852, barre d'état fidèle (17:10 sur la carte, 17:44 sur la prise). Assets locaux uniquement (CDN bloqués) : installer la police avec `npm i --no-save @fontsource/<nom>` dans un dossier du scratchpad puis copier le .woff2 dans ton dossier. Une seule police d'univers (+ éventuellement une police système pour les petits textes).
- Liquid Glass (matière iOS 26) seulement sur la couche des contrôles : barre d'onglets, boutons, feuilles. Le décor reste dans l'univers.
- Le poisson doit être dessiné DANS le langage de l'univers (SVG ou CSS à toi, ou une illustration de `maquettes/assets/fish/` transformée de façon cohérente : contour, aplats, pixels…). Pas de photo réaliste collée dans un décor enfantin. Le poisson reste entièrement dans sa carte.
- Enfantin ne veut pas dire bâclé : formes nettes, une seule audace par écran, texte lisible (≥ 13 pt), contraste AA.
- Mots : « Pescedex » pour la collection ; jamais « Poké » ; pas de nom d'app (emplacement neutre si besoin). Lieu partagé arrondi à « La Marne, Val-de-Marne (94) ».
- Pas de copie de propriété Nintendo/Pokémon : inspiration de codes, pas de personnages, logos ou formes déposées (pas de Poké Ball).
- Interdits : dégradé violet, Inter, hero centré, cartes identiques en série, emojis décoratifs, ton promo.

## Vérification bloquante (avant le rapport : un tour de correction puis confirmation)
1. `cd /tmp/claude-0/-home-claude/712da50a-e7d6-5a83-90bb-bc72b4d3b0cc/scratchpad/shot && node shot.mjs <html> <png> 2500` affiche « no console errors » (pour raretes.html, écris ton propre script de capture 1600x900 dans le scratchpad, pas dans le dossier).
2. `node /home/claude/claude-config/.claude/skills/impeccable/scripts/detect.mjs <html>` : corriger ou justifier chaque constat dans notes.md.
3. Ouvrir chaque PNG avec l'outil Read : lisible, rien ne déborde, le poisson dans sa carte, l'univers reconnaissable au premier coup d'œil.
Rapport final : 10 lignes max, lignes de console collées, constats du détecteur, faiblesses honnêtes.

## Passe 2 : tout le parcours (Adem, 23:05 : « fais tout »)
Décliner son univers sur les écrans du parcours de démo (`build/parcours-demo.md`, ids de `maquettes/carte-ecrans.md`), en plus de carte et prise déjà faits. Mêmes règles, même dossier, même vérification bloquante. Fichiers :
- `fiche.html` (C2, E2) : Coin B, espèces relevées par l'OFB avec leur rareté (gardon 24/29 commun, brochet 10/29 peu commun, sandre 3/29 rare ; truite fario « à chercher, jamais relevée ici »), règle en une phrase + source en petit (« Brochet ouvert, 60 cm minimum, 2 par jour · règle nationale, indicative »), amis ici (Léa, Malo), bouton « Commencer une sortie ».
- `sortie.html` (S1, E4) : sortie en cours au Coin B, « 1 h 12 avant la fin légale de pêche (18 h 54) », « 0 prise · depuis 17 h 16 », gros bouton « J'ai une prise », « Terminer ».
- `photo.html` (P1+P2, E5) : identification : 3 espèces proposées (brochet coché, sandre, perche), liens « Aucune de ces espèces » · « Pas un poisson », taille 68 cm au curseur (10 à 120).
- `verdict.html` (P3, E5) : « Garder possible », 68 / 60 cm mini, ouvert jusqu'au 25 janv., 2 brochets max par jour, source en petit. Un seul bouton « Voir ma carte ».
- `pescedex.html` (K2, E6) : la collection : 3 espèces sur les 11 relevées dans le 94, « Légendaires · 1 sur 3 », « Sorties · 1 », cartes gagnées (gardon, brochet, sandre, truite fario) en petit format de l'univers, silhouettes pour le reste (perche, chevesne, brème, silure, tanche, carpe, barbeau…). Segment « Les miens / Amis ».
- `paywall.html` (V1, E7) : « 1 mois d'essai gratuit », prix « à fixer » en emplacement gris, bénéfices : raretés et règles de tous les départements, cartes illimitées (pas les amis), restaurer les achats, fermeture visible.
- `bredouille.html` (K3, E9) : carte de la sortie sans poisson, qui donne quand même envie de la garder : La Marne, Val-de-Marne (94), 12 oct. 18 h 55, 14 °C, lune 2 %, « Rien n'a mordu. La sortie compte quand même. », « Ranger avec mes sorties ».
Heures de barre d'état : fiche 17:11, sortie 17:42, photo 17:43, verdict 17:43, pescedex 17:45, paywall 17:44, bredouille 18:55.
Puis `planche.png` : les 9 écrans dans l'ordre du parcours (carte, fiche, sortie, photo, verdict, prise, paywall, pescedex, bredouille), côte à côte, PIL. Données de carte/prise/raretés : harmoniser sur les chiffres ci-dessus (gardon 24/29, sandre 3/29) si elles diffèrent.
Rapport : 10 lignes max, lignes de console collées pour chaque fichier, faiblesses.
