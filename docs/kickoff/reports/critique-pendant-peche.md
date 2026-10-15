# Critique des 33 idées « pendant la pêche » (12 oct.)

Sources lues : `6-idees-pendant-peche.md`, `fonctionnalites.md`. Rien d'autre.
Axes notés de 1 à 5 : **O** = originalité face à Fishbrain et aux autres, **F** = faisable en 1,5 jour par des débutants qui codent avec l'IA, **D** = effet dans une démo de 2 min, **A** = adéquation à la cible débutante et aux critères MWM et Apple.
**IA déco** = l'idée marche aussi bien sans IA, donc l'IA ne doit pas être vendue au jury.

Contrainte technique qui tue plusieurs idées : Foundation Models, le modèle d'IA embarqué d'Apple, ne lit que du texte (à revérifier sur iOS 27). Il ne voit ni photo du matériel, ni photo de l'eau. Tout « l'IA regarde ta photo et conseille » demande donc un modèle de vision dédié, ou un appel cloud, et on ne l'aura pas en 1,5 jour.

## Tableau des notes

| # | Idée | O | F | D | A | Total | IA déco | Verdict |
|---|---|---|---|---|---|---|---|---|
| 1 | Montage guidé par caméra | 3 | 1 | 3 | 4 | 11 | | tuée |
| 2 | Nœuds en vidéo ou AR | 1 | 2 | 2 | 3 | 8 | | tuée |
| 3 | « Pourquoi ça ne mord pas ? » | 3 | 4 | 3 | 4 | 14 | oui | réserve |
| 4 | Coach de lancer | 5 | 1 | 4 | 3 | 13 | | tuée |
| 5 | Détecteur de touche (iPhone contre la canne) | 4 | 3 | 5 | 3 | 15 | | **V2** |
| 6 | Mesure du poisson (photo, LiDAR) | 2 | 2 | 4 | 5 | 13 | | **V2** (avec 20) |
| 7 | Chrono 10 s hors de l'eau | 4 | 5 | 3 | 4 | 16 | | détail du cœur |
| 8 | Décrocher sans blesser | 2 | 4 | 1 | 3 | 10 | | tuée |
| 9 | Live Activity de la session | 2→4 | 3 | 4 | 5 | 14-16 | | **vendredi** (recadrée) |
| 10 | Tout à la voix avec Siri | 3 | 3 | 2 | 4 | 12 | | fusion avec 11 |
| 11 | « J'en ai un » sur bouton Action ou Watch | 3 | 4 (Watch : 1) | 3 | 4 | 14 | | réserve |
| 12 | Lire l'eau en photo | 4 | 1 | 5 | 5 | 15 | | tuée |
| 13 | Scan de la boîte à leurres | 2 | 1 | 3 | 3 | 9 | | tuée |
| 14 | Quête du jour | 2 | 4 | 3 | 2 | 11 | | tuée |
| 15 | Duel entre potes en direct | 2 | 1 | 4 | 3 | 10 | | tuée |
| 16 | Carte fantôme (poisson perdu) | 5 | 5 | 3 | 4 | 17 | | fusion avec 17 |
| 17 | Carte de la sortie bredouille | 5 | 5 | 3 | 5 | 18 | | **vendredi** |
| 18 | Pokédex élargi (oiseaux, plantes) | 3 | 2 | 4 | 2 | 11 | | tuée |
| 19 | Pote expert qui suit à distance | 3 | 1 | 3 | 3 | 10 | | tuée |
| 20 | Feu vert ou rouge avant de garder | 1 | 4 | 4 | 5 | 14 | | déjà le cœur |
| 21 | Protocole de remise à l'eau | 2 | 4 | 1 | 3 | 10 | | tuée |
| 22 | Alerte zone interdite (écluse) | 3 | 2 | 3 | 3 | 11 | | tuée |
| 23 | Appâts autorisés selon la période | 2 | 4 | 1 | 3 | 10 | | à fondre dans la règle |
| 24 | Spot téléchargé hors réseau | 1 | 3 | 1 | 2 | 7 | | tuée |
| 25 | Selfie automatique avec le poisson | 4 | 2 | 4 | 4 | 14 | | tuée pour l'instant |
| 26 | Pose guidée pour la photo | 3 | 3 | 2 | 3 | 11 | | tuée |
| 27 | Légende vocale écrite par l'IA | 2 | 4 | 3 | 3 | 12 | oui | tuée |
| 28 | Calendrier lunaire et solunaire | 1 | 4 | 1 | 1 | 7 | | tuée |
| 29 | Signalement anonyme du spot | 2 | 2 | 2 | 3 | 9 | | tuée |
| 30 | Premier lancer en 3 étapes | 2 | 4 | 3 | 4 | 13 | | fusion avec 32 |
| 31 | Record du quai, façon Strava | 4 | 3 | 3 | 4 | 14 | | **V2** |
| 32 | Mission première prise | 4 | 4 | 4 | 5 | 17 | oui si IA | **vendredi** |
| 33 | Carte bonus déchets ramassés | 4 | 3 | 3 | 3 | 13 | | tuée |

## Les idées tuées, une ligne chacune

- **1** : Foundation Models ne voit pas l'image, et reconnaître une canne ou un moulinet demande un modèle qu'on n'a pas.
- **2** : YouTube le fait mieux et gratuitement ; l'AR d'un nœud est un projet à elle seule.
- **4** : sans mesures réelles de bons lancers pour comparer, le « coach » invente ses corrections.
- **8, 21** : des fiches statiques, invisibles en démo, que n'importe quel site fédéral publie déjà.
- **12** : la meilleure démo de la liste et la plus mensongère : aucun modèle à notre portée ne sait lire un herbier sur une photo, il inventerait.
- **13** : même mur que 1, avec en plus des centaines de leurres à reconnaître.
- **14** : pour un débutant, une quête ratée ajoute un échec de plus le jour où il est déjà bredouille.
- **15, 19, 29** : il faut un serveur temps réel et des utilisateurs, on n'a ni l'un ni les autres vendredi.
- **18** : dilue le message (Seek d'iNaturalist le fait) et demande un classifieur par famille.
- **22** : aucune donnée propre des zones interdites autour des écluses ; une erreur expose le joueur à une amende.
- **24** : à Paris le réseau passe partout ; ça règle un problème que la cible n'a pas.
- **25** : le seul modèle de vision qu'on aura reconnaît l'espèce d'une photo posée, pas un poisson qui bouge dans un flux vidéo ; à revoir après.
- **26** : un texte en surimpression suffit, ce n'est pas une fonctionnalité.
- **27** : IA décorative, taper trois mots fait aussi bien, et le jury Apple le verra.
- **28** : science douteuse, déjà dans Fishbrain et dix autres apps.
- **33** : impossible de prouver le ramassage, donc on récompense une déclaration ; joli mais creux.

Fusions : **10** dans **11** (un seul raccourci Siri sert la voix et le bouton Action), **16** dans **17**, **30** dans **32**, **23** dans la règle locale, **7** dans l'écran photo existant (un anneau de 10 s, une heure de travail, ce n'est pas une fonctionnalité à part).
**20** n'est pas une idée nouvelle : c'est le cœur déjà décidé.

## IA décorative, à ne pas survendre

- **3** : un tableau de règles simples (eau trouble = leurre voyant) donne le même conseil ; le petit modèle embarqué connaît mal la pêche et inventera.
- **27** : voir plus haut.
- **32** : le choix du spot, de l'heure et du montage est un calcul sur les relevés OFB et la météo, pas de l'IA. Le présenter comme tel, c'est plus honnête et plus solide.

## Version de vendredi : 3 idées

**1. Mission première prise (32, avec 30).** Au premier lancement, l'app choisit le spot proche où l'OFB a relevé des gardons, l'heure et un montage au pain, en 3 écrans.
- Pourquoi elle gagne : c'est le « premier moment utile en quelques secondes » du jury MWM, et elle se sert de la seule donnée que personne d'autre n'exploite (les relevés OFB).
- Risque principal : un relevé OFB est une pêche scientifique à l'électricité ; un gardon présent ne veut pas dire un gardon attrapable depuis la berge. Choisir 3 ou 4 spots testés à la main plutôt que tout calculer.

**2. Carte de la sortie bredouille (17, avec 16).** Rentrer sans poisson donne quand même une carte : lieu, météo, lune, heure, et une case « touche ratée » qui la grise.
- Pourquoi elle gagne : le débutant abandonne après deux sorties vides ; c'est la vraie « raison de revenir », et aucun concurrent ne récompense l'échec. Une journée de travail au plus, sans IA.
- Risque principal : abîmer la valeur de la collection. La carte bredouille doit avoir son propre dos, jamais une rareté.

**3. Live Activity de la session, recadrée sur l'heure légale (9).** La pêche est autorisée de 30 min avant le lever à 30 min après le coucher du soleil (à confirmer par département, la carpe de nuit fait exception). La Dynamic Island affiche « fin légale dans 38 min » et le compte des prises.
- Pourquoi elle gagne : elle coche une techno citée par Apple tout en prolongeant notre atout unique, la règle locale, au lieu d'un simple chrono.
- Risque principal : ActivityKit demande une extension de widget, piège classique pour des débutants ; prévoir une demi-journée et faire tourner une Live Activity vide dès jeudi midi.

En réserve si les trois sont finies : **11**, le raccourci « J'en ai un » (App Intent, environ 1 h), qui ouvre l'appareil photo avec l'anneau de 10 s.

## Version 2 : 3 idées

**1. Mesure du poisson reliée au feu vert ou rouge (6 + 20).** L'espèce reconnue plus la taille mesurée donnent le verdict sans rien taper.
- Pourquoi elle gagne : c'est la valeur la plus claire pour justifier 14,99 €/an, et la chaîne espèce, taille, règle n'existe nulle part.
- Risque principal : une erreur de 2 cm sur un brochet fait garder un poisson sous la taille légale ; il faut afficher une marge, et le LiDAR n'existe que sur les modèles Pro.

**2. Détecteur de touche (5).** L'iPhone posé contre la canne lit les secousses du bout de canne et sonne.
- Pourquoi elle gagne : la démo la plus physique de la liste (on tapote la canne, l'iPhone sonne), sans IA, et proposée par 7 % des LLM seulement.
- Risque principal : iOS coupe les capteurs quand l'écran se verrouille, et le vent déclenche de fausses alertes ; à tester au bord de l'eau avant d'en parler.

**3. Record du quai (31).** Le plus gros poisson par tronçon de berge, comme un segment Strava.
- Pourquoi elle gagne : la raison de revenir la plus forte pour des jeunes qui se comparent, et elle s'ancre dans le quartier.
- Risque principal : au lancement, chaque tronçon est vide, et la triche sur la taille est triviale ; la lier à la mesure de la V2 n°1.

## Ce qui reste fragile dans ce classement

- Les notes de faisabilité supposent qu'une Live Activity et un App Intent tournent en quelques heures avec l'aide de l'IA ; personne ne l'a vérifié dans le projet.
- La règle des heures légales est de mémoire ; elle doit être confirmée sur le texte avant d'être affichée.
- Mes probabilités et mes notes restent celles d'un seul LLM : à confronter à un vrai débutant au bord de l'eau, pas à un autre agent.
