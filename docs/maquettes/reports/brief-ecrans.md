# Brief : écrans du parcours de démo, style K

Critère unique : le parcours de démo `/mnt/project-files/build/parcours-demo.md` (E1 à E9), écran par écran, tel que décrit dans `/mnt/project-files/maquettes/carte-ecrans.md` (ids A1, C1, K1…). Lire les deux avant de dessiner. Le parcours fait foi ; en cas d'écart, le noter dans notes.md sans trancher.

## Style (source unique : planche-k)
- Reprendre les jetons de `/mnt/project-files/maquettes/planche-k/index.html` : polices, couleurs, barre d'état fidèle, barre de commande en verre (Liquid Glass seulement sur la couche des contrôles), vert d'action, encre, fond clair.
- La carte à collectionner se réutilise telle quelle (copier le markup et le CSS de planche-k, ne pas la redessiner). En grille (Pescedex), finition figée, sans animation.
- iPhone 393x852, assets locaux uniquement (`/mnt/project-files/maquettes/assets/`, CDN bloqués). Pas de nouvelle police.
- Ton minimaliste (Adem : « trop bruyant » sur les premières séries). Une information une seule fois par écran.
- Inspiration réelle : `reports/inspirations.md`, `reports/ecrans-references.md` (apps iOS qui fonctionnent : Apple Plans, Fishbrain, Merlin Bird ID, Seek, etc.). Citer dans notes.md l'app de référence de chaque écran.

## Contenu et données (ne pas inventer)
- Lieu affiché « La Marne, Val-de-Marne (94) » ; jamais de point exact ni de commune sur une carte partagée.
- Raretés 94 : gardon commun (≥50 % des pêches OFB), brochet peu commun (20-50 %), sandre rare (<20 %), truite fario légendaire (« 0 pêche sur 29 »). Compteur « 4 espèces sur les 11 relevées dans le 94 ».
- Le mot « Poké » n'apparaît jamais. Le nom de l'app n'est pas décidé : ne pas en écrire un (mettre un emplacement neutre si nécessaire). « Pescedex » = la collection seulement.
- Paywall : essai affiché « 1 mois », prix « à fixer » (emplacement gris), restauration des achats et fermeture visibles.
- Amis : seulement les collections des amis, jamais d'inconnus ; Signaler / Bloquer présents (règle Apple 1.2).
- Verdict : la règle vient d'une table sourcée, jamais de l'IA ; citer la source en petit.

## Interdits (anti-slop, skills impeccable + creatif-anti-slop + avoid-ai-writing)
Chatbot, dashboard, dégradé violet, hero centré, cartes identiques en série, Inter, emojis décoratifs, textes promo, « ce n'est pas X, c'est Y », triplets.

## Livrable par lot (dossier propre, rien hors de ce dossier)
- Un fichier `<id>.html` par écran (ex. `C1-carte.html`), sa capture `<id>.png`, une planche `planche.png` (captures côte à côte, PIL), `notes.md` (référence par écran, écarts, faiblesses).

## Vérification bloquante (avant le rapport, un tour de correction puis confirmation)
1. Capture : `cd /tmp/claude-0/-home-claude/712da50a-e7d6-5a83-90bb-bc72b4d3b0cc/scratchpad/shot && node shot.mjs <html> <png> 2500` doit afficher « no console errors ».
2. Détecteur : `node /home/claude/claude-config/.claude/skills/impeccable/scripts/detect.mjs <html>` ; corriger ou justifier chaque constat dans notes.md.
3. Ouvrir chaque PNG avec l'outil Read et vérifier : textes lisibles, rien ne déborde, cohérence avec la carte K, une information une fois.

## Passe 2 (après reports/critique-ecrans.md) : règles communes aux 3 lots
- Appliquer la critique (sections 2 et 3) à son lot. Table de cohérence de la section 3 = valeurs obligatoires (titres 34/46/56 pt, boutons Hanken 15 semibold, retour = rond de verre 44 pt, un seul vert #1E7F4F + menthe seulement sur fond sombre, marges 16/24 pt, durées « 1 h 12 », Plex Mono réservé aux mesures, sortie = flotteur, prise = poisson, rareté = pictogrammes de K, barre d'onglets du lot 3 sur C1, K2, X1, F1, F3 avec segment « Les miens / Amis »).
- Heure de la barre d'état qui avance : A1/A2 17:05, C1 17:10, C2 17:11, M1/M3 17:12, S1 17:42 (S2 lock 17:42), P1 17:43, P2/P3 17:43, K 17:44, V1 17:44, K2/X1 17:45, F1/F3 17:46, K3 18:55 (après la fin légale, autre jour possible : garder 12 oct. 18:55), K4 17:45.
- Données d'exemple UNIQUES (celles de la carte K, figée) : gardon 24/29 (83 %, commun), brochet 10/29 (34 %, peu commun), sandre 3/29 (10 %, rare), truite fario 0/29 (légendaire, « jamais relevée ici »). Amis : Léa, Malo, Inès. Coins nommés par lettre (Coin A à E) ; la prise de la démo est au Coin B. Mission : « Lun. 12 oct., 17 h à 18 h 54 ».
- Décisions par défaut (en attente d'Adem) : compteur « 3 espèces sur les 11 relevées dans le 94 » + ligne « Légendaires · 1 sur 3 » ; paywall ne vend que ce qui est livré (raretés et règles de tous les départements, cartes illimitées), pas les amis ; A1 hors version soumise (garder le fichier, bandeau gris « hors parcours » en haut de notes seulement, pas sur l'écran) ; P4 atteint par « Aucune de ces espèces » puis choix manuel.
- C1 : chaque épingle devient une carte K posée face cachée (24 × 32 pt, rayon 4, fond #17403F, liseré 1 pt #E4ECE9, nombre d'espèces Bricolage 13 pt), la sélectionnée soulevée 36 × 48 pt ; Marne #17403F 5 pt.
- La carte K (planche-k) reste figée : ne pas modifier son bandeau. En grille seulement (K2, F3), version « mini » = même carte, bloc de stats caché.
- Re-vérification bloquante identique (capture sans erreur console, détecteur, lecture de chaque PNG), planche.png et notes.md à jour.
