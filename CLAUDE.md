# App de pêche (Build Challenge Apple, oct. 2026)

Faits et décisions propres à ce dépôt. À mettre à jour dans la minute qui suit chaque décision.
Le plan complet est dans `docs/` : commencer par `docs/README.md`, puis sa fiche de lot dans `docs/fiches/`. Reprise après l'arrêt du 15 oct. midi : `docs/passation.md`.
Les documents que le plan cite sans chemin (`lots.md`, `fiches/L3.md`, `reports/...`) sont dans `docs/`. `python3 docs/verifier.py` doit afficher « 0 trou ».

## Le produit
- App iPhone de pêche en eau douce : la carte montre où pêcher et quels poissons y vivent (relevés OFB), chaque prise photographiée devient une carte à collectionner dont la rareté dépend du département.
- Nom de l'app : FishMe (Adem, 15 oct. 12h36). « Pescedex » est le nom de la collection dans l'app, jamais celui de l'app.
- Ne jamais écrire « Poké », « Pokémon » ou « Pokédex » dans l'app, ses textes ou sa fiche App Store (marques de Nintendo).
- Règles : socle national partout, plus 75, 92, 93, 94, 77 saisis à la main, chaque règle avec sa source. Hors de ces départements, jamais « tu peux la garder ».
- L'app vise toute la France (Adem, 15 oct. 11h13) : les règles doivent couvrir tous les départements et toutes les espèces, au tronçon. Méthode testée sur 3 départements pilotes (01, 87, 44) ; outils et consigne dans `outils/regles/`. La lecture des arrêtés tourne sur un ordinateur d'Adem, pas dans le cloud (Adem, 15 oct. 12h01 : « tu fais tout en local »).
- Règles lues par l'IA (Adem, 15 oct. 11h34, « c'est pas un sujet ») : l'app montre chaque règle avec sa source et sa citation, sans étiquette « non relue ». Contrôle interne : deux lectures indépendantes par département, comparées sur le fond (type, espèce, dates, nombres, lieu) par `consensus.py` ; seules les règles confirmées par les deux lectures sont chargées, les autres deviennent « vérifie l'arrêté ». Pilote de l'Ain : 205 règles sur 287 confirmées.
- Deux textes qui se contredisent sur une taille : on affiche la plus stricte avec les deux sources (Adem, 15 oct. 11h13). Texte qui fait foi (`reports/qui-est-maitre.md`, 15 oct.) : l'arrêté préfectoral permanent signé ; le Code (R436-18) est le plancher, et seul un arrêté motivé (R436-19) peut le relever. Cas connu : brochet, sandre, black-bass dans 75, 92, 93, 94 (arrêtés 2025 : 50/40/30 cm ; avis 2026 : 60/50/40 cm en « rappel »). La décision d'Adem tient : 60/50/40 affiché avec les deux sources, car relâcher n'est jamais une infraction. Une règle tirée d'un avis 2026 expire le 31/12/2026.
- L'IA ne décide jamais si un poisson peut être gardé : elle propose l'espèce, l'utilisateur confirme, la table sourcée donne le verdict.
- Aucun coin de pêche exact ne quitte l'iPhone. Les photos enregistrées n'ont pas de GPS.
- Aucune fausse donnée : chaque chiffre OFB affiche son nombre de pêches et l'année du dernier relevé.
- Rareté en 4 niveaux (Adem, 12 oct. 18h55) : commun, peu commun, rare, légendaire. Seuils par défaut : commun 50 % des pêches OFB et plus, peu commun 20 à 50 %, rare moins de 20 %, légendaire jamais relevé dans le département (`docs/donnees.md`).
- Collections visibles par les amis invités seulement, jamais en public (Adem, 12 oct. 14h43).
- Prix (Adem, 15 oct. 11h13) : « tarif fondateur ». L'annuel à 34,99 est annoncé comme prix de lancement jusqu'au 31 décembre 2026, puis 49,99 pour les nouveaux abonnés ; les premiers gardent leur prix. Le kit MWM a déjà les deux produits annuels (34,99 et 49,99), et les mensuels 4,99 / 6,99 / 9,99 avec 1 semaine d'essai ; les annuels n'ont pas d'essai. L'« essai 1 mois » du 12 oct. tombe. Prix en euros à lire dans la colonne France d'App Store Connect avant d'écrire le paywall.
- Écrans (Adem, 15 oct. 12h51-12h52) : peu de texte, des images, des icônes et des chiffres ; les poissons toujours en images, jamais en liste de noms ; la source et la citation d'une règle s'ouvrent d'un toucher.
- Navigation (Adem, 15 oct. 11h43, fil Maquettes) : « iOS natif », piste A, la barre d'onglets standard d'Apple pour les 3 volets. Aucune barre de défilement visible, ni à droite ni en bas (`.scrollIndicators(.hidden)`). Style (Adem, 15 oct. 13h08, fil Maquettes) : la piste « Natif » (façon Plans d'Apple, A2 épurée), avec le Pescedex en classeur de cartes de la piste « Pochette » ; palette pas encore choisie.
- Compteur du Pescedex : Adem n'aime pas « 3 sur 14 » ; il veut un compteur par zone (« tu en as trouvé 2 sur N espèces de la zone »). Zone (département, cours d'eau, rayon) en discussion dans le fil Maquettes.
- Spot gratuit (Adem, 15 oct. 12h26) : le gratuit propose UN spot, cercle de 1 km, avec des sessions illimitées sur ce spot ; tronçon ou lac entier dans la mise à jour. La carte, les règles et le Pescedex en lecture restent gratuits pour toujours. Paywall (Adem, 15 oct. 12h28, « les 2 ») : à la fin de la 1re session il s'ouvre et se ferme (on continue gratuitement sur son spot) ; choisir un 2e spot ouvre le paywall, qui bloque. Spot gratuit (Adem, 15 oct. 12h32) : l'app propose le plus proche avec des relevés OFB récents et une espèce ouverte ce jour ; le pêcheur peut en prendre un autre sur la carte avant sa 1re session, puis il est fixé.

## L'atelier (harness, décidé le 13 oct.)
- Adem veut un atelier qui fait construire vite et juste, pas un plan à lire. Il a le droit d'être préparé avant jeudi (Adem, 13 oct. 13h28) ; c'est le lot H0.
- Claude Code : utilisé par Adem et Titouan ; Sullyvan code sans Claude, donc chaque règle existe aussi en crochet de git (`.githooks/`).
- Outils gratuits autorisés sans redemander (Adem, 13 oct.) : XcodeBuildMCP, fastlane, et d'autres outils gratuits utiles. Un outil payant, une API ou un modèle se demandent toujours.
- `docs/lots.md` est la seule source des règles de l'atelier (branche et dossiers de chaque lot) : on corrige le tableau, jamais un script.
- Dans le cloud, Swift passe par Docker : `sudo dockerd &` puis l'image `swift:6.4` (vérifié le 13 oct. : Swift 6.4, Swift Testing et `swift format` tournent).

## La construction
- Critère commun : `docs/parcours-demo.md` (étapes E1 à E9). Lots et calendrier : `docs/lots.md`.
- Aucune ligne de code de l'app avant le jeudi 15 oct. 2026. Build jeudi et vendredi matin.
- Xcode 27.0, iOS 27.0 minimum, iPhone seulement. 2 Mac (A et B) ; C travaille sans Mac, dans le cloud.
- Structure : un seul paquet `Packages/Core` (Foundation seulement, testable sous Linux) + la cible app en dossiers synchronisés, un dossier par lot dans `App/`.
- Un dossier de l'app n'importe que `Core` et lui-même. A seul touche au `.xcodeproj`, aux capacités, aux clés Info et à `App/RootView.swift`. C seul touche à `Packages/Core`.
- Un lot = un dossier = une personne = une branche `lot/<nom>`. On rejoint `main` seulement par `scripts/fusionner.sh`, qui lance `scripts/verif.sh`.
- Les faux services sont sous `#if DEBUG` : rien de factice dans le build envoyé à Apple.
- Les fichiers de données fabriqués par script (stations, raretés) ne sont jamais commités : `scripts/donnees.sh` les télécharge.
- Compte App Store Connect, iPhone de test, fichier StoreKit et SDK Spark Flash fournis par MWM.
- Kit MWM reçu le 15 oct. (`/mnt/project-files/.notes/inputs.md`) : équipe « Frétille » n°01, trois personnes (Adem, Sullyvan, Titouan). Projet `BuildChallenge.xcodeproj` déjà signé chez MWM, identifiant `ai.mwm.build.challenge.team.01` (les abonnements y sont liés, ne pas le changer), SDK Spark par chemin relatif `../mwm-spark-flash-sdk/local-spm-repo`. Le projet sort réglé iPhone + iPad et paysage : à passer en iPhone seul, portrait.
- Le README du kit contient le mot de passe du compte MWM : jamais dans git. Le serveur MCP de MWM (`https://mcp.mwm.ai/mcp`) sait publier politique de confidentialité et conditions, générer captures et textes, et soumettre ; la soumission à Apple reste un clic humain.
- Jeudi, `main` part de la branche `claude/project-thread-78e20q` (le plan seul, sans code) ; A la crée à L0 et la met par défaut sur GitHub.
