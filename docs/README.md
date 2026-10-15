# Plan de construction de l'app

Tout ce qu'il faut pour construire l'app jeudi et vendredi, vérifié par `python3 docs/verifier.py` (doit afficher « 0 trou »). Version du 15 oct., refaite pour la vision d'Adem du 15 oct. (3 volets façon Clash Royale), puis complétée le 15 oct. après-midi (toutes les espèces, conditions, conseils, « tout d'un coup ») ; la version du 12 oct. reste dans git.

## Les fichiers
| Fichier | Ce qu'il dit | Pour qui |
|---|---|---|
| `vision.md` | la vision du 15 oct. challengée point par point : volets, session, « Choisir un autre spot », club, reconnaissance, règles, mer, fraîcheur des règles, carte, rareté, écrans, fusion avec l'atelier de Titouan | Adem, puis toute l'équipe |
| `parcours-demo.md` | les étapes E1 à E9 que voit le pêcheur, chacune avec son test ; l'ordre de la démo | toute l'équipe, le critère commun |
| `lots.md` | qui construit quoi, dans quel dossier, avec quel test, le calendrier tout en parallèle (portes à L0 + 1, 3 et 4 h, envoi à L0 + 5 h), qui fait tourner quoi, et ce qu'on fait si un lot prend du retard | toute l'équipe |
| `fiches/` | une page par lot, avec la consigne à coller dans Claude Code | la personne du lot |
| `architecture.md` | versions, structure du projet, contrats de `Core`, cas réel du démarrage | A, B |
| `donnees.md` | les fichiers embarqués, leurs sources et licences, la politique de la liste de contrôle, les cas d'or | B, S |
| `app-store.md` | la check-list de soumission et les refus probables, avec le lot qui les corrige | A, MWM |
| `banc/` | les profils de faux utilisateurs du banc d'essai et les mots interdits | l'atelier (`/banc`) |
| `atelier.md`, `atelier-mac.md` | l'atelier (harness) et la mise en route d'un Mac | Adem et Titouan (Claude Code), Sullyvan (sans Claude) |
| `passation.md` | où tout est rangé et ce qui attend Adem, après l'arrêt du 15 oct. à midi et la reprise de l'après-midi | la session qui reprend |
| `avant-jeudi.md`, `message-mwm.md` | ce qui devait être prêt avant jeudi, le message envoyé à MWM | pour mémoire |
| `reports/` | les recherches et les évaluations, avec leurs sources (règles du 75 et du 94, texte qui fait foi, prix, reconnaissance, mer, navigation) | pour vérifier un chiffre |

## Ce qui a changé le 15 oct.
- L'app a 3 volets (Pescedex, Carte, Mon club), avec la barre d'onglets standard d'iOS 27.
- La session entre dans la version soumise ; l'écran verrouillé reste pour la mise à jour.
- Les règles visent toute la France (D3), affichées en liste de contrôle sourcée par défaut.
- La reconnaissance a son lot (R1) : un jeu de test fixé avant l'entraînement, et un seuil à passer pour entrer dans l'app.
- Le projet Xcode et les abonnements sont ceux du kit MWM. Tarif fondateur décidé par Adem : 34,99 jusqu'au 31 décembre, puis 49,99 pour les nouveaux.
- Un banc d'essai de 9 faux utilisateurs ultra critiques passe sur chaque lot qui touche l'app ; il signale, il ne valide jamais.
- L'après-midi (Adem, 13h21, « tout d'un coup ») : toutes les espèces pêchables de France, en images, au lieu de 14 ; la version soumise ajoute la météo du jour et sur 7 jours (WeatherKit, marque Apple Weather), le niveau de la rivière (Hub'Eau), la vigilance orage et crue, « préviens-moi », l'historique des conditions de ses sorties, les conseils par espèce et une seule question au premier lancement, le niveau du pêcheur. Trois lots de plus : L12 Conditions (A), L13 Conseils et premier lancement (B), D4 Conseils par espèce (S). Tout cela part dans la version soumise : rien n'est coupé, `lots.md` donne le calendrier tout en parallèle.
- 14h26 (Adem) : plus de « C » ; chaque lot va à Adem, Titouan ou Sullyvan, les plus gros à Titouan et Adem.
- 14h42 (Adem) : « on va tout paralléliser ». Une session Claude Code par lot, toutes en même temps ; un agent `codeur` (Sonnet) par morceau, `petites-mains` (Haiku) pour le mécanique, la session principale en Opus. Envoi visé à L0 + 4 à 5 h au lieu de L0 + 10 à 11 h, et plus aucun ordre de coupe : si un lot traîne, on ajoute des codeurs ou une session (`lots.md`, « Si un lot prend du retard »).

## Choix pris par défaut (dis-moi si tu veux en changer un)
- Qui (après la décision d'Adem de 14h26, « plus de C ») : A = Adem sur le Mac A et son PC, B = Titouan sur le Mac B (celui de Sullyvan) avec Claude Code, S = Sullyvan, sans Claude ni Mac (`lots.md`). A porte L0, L2, L6, L9, L12, S1 et D3 ; B porte `Core` (C0, L1), D1, L3, L4, L5, L13 et R1 ; S porte D2, relit les conseils de D4 (une session cloud lancée par A les rédige), relit les règles d'Île-de-France et la fiche, et trie les photos de R1. Mise à jour : L10, L11 et L14 Aquarium à A, L7 et L8 à B.
- Version soumise : les 9 étapes avec les fonctions de l'après-midi (conditions, conseils, niveau, toutes les espèces) ; mise à jour vendredi : écran verrouillé, coins publics, amis, règles téléchargées, aquarium (`parcours-demo.md`). Tout en parallèle (Adem, 15 oct. 14h42) : envoi visé à L0 + 4 à 5 h (estimation), portes à L0 + 1, 3 et 4 h. Rien n'est coupé : si un lot traîne, on ajoute des codeurs ou une session (`lots.md`, « Si un lot prend du retard »).
- Gratuit et Pro des nouvelles fonctions (question 5 du 15 oct.) : gratuit = la météo du jour et la jauge de la rivière sur son spot, la vigilance orage et crue partout, le 1er conseil de chaque espèce ; Pro = 7 jours, autres spots, « préviens-moi », courbe de la rivière et normale, tous les conseils, « tes conditions » après 10 sorties. Un toucher sur une fonction Pro ouvre le paywall, qui nomme la fonction et se ferme (`fiches/L6.md`).
- Pas de note d'activité « sur 100 » ni d'heure solunaire (question 6 du 15 oct.) : des chiffres mesurés, chacun avec sa source et son heure.
- Premier lancement : la position, puis la question du niveau (sautable, « occasionnel » si on passe), puis le consentement à la mesure ; jamais deux à la fois.
- Xcode 27.0, iOS 27.0, iPhone seul en portrait ; un paquet `Core` + un dossier par lot ; fusion par script local (`architecture.md`).
- Deux textes qui se contredisent : la valeur la plus stricte, avec les deux sources (décidé par Adem le 15 oct.). Le texte qui fait foi est l'arrêté permanent signé (`reports/qui-est-maitre.md`) ; la valeur la plus stricte reste affichée, car relâcher n'est jamais une infraction.
- Règles lues par l'IA (décidé par Adem le 15 oct.) : l'app montre chaque règle avec sa source et sa citation, sans étiquette « non relue ». En coulisse, deux lectures indépendantes par département ; une ligne où elles divergent devient « vérifie l'arrêté ».
- Rareté sur 10 ans en 4 niveaux (commun, peu commun, rare, légendaire) ; sous 20 pêches dans le département, calculée sur la région, et l'écran le dit.
- Au premier lancement, l'app demande la position et la carte s'y centre ; refusée, le pêcheur choisit son département. Les poissons sont montrés en images, jamais en liste de noms (Adem, 15 oct. 12h51).
- Après la liste de contrôle, le pêcheur déclare « je la relâche » ou « je la garde » (ça compte pour le quota du jour) ; quand aucune ligne ne l'interdit, l'app écrit « aucune règle saisie ne l'interdit ; l'arrêté fait foi », jamais « tu peux la garder ».
- Reconnaissance : le modèle maison s'il passe son test, l'IA d'Apple seulement si elle passe le même test, sinon la grille d'images de toutes les espèces. Si le modèle ne passe pas son examen avant la porte 3, la version soumise part avec la grille, et le modèle entre dans une mise à jour dès qu'il passe.
- Les fichiers fabriqués par script restent hors de git : publiés en pièce jointe d'une release privée.

## Questions pour Adem
Le jury attaquera d'abord ce que l'app affiche sur la loi et ce qu'elle fait payer. Ces deux choix changent des écrans et des tests ; chacun a un défaut, et le travail avance sur ce défaut en attendant ta réponse.

**1.** Sous quelle forme l'app montre-t-elle la règle pour une prise ?
a. Un verdict : « tu peux la garder », « relâche-la », « vérifie l'arrêté »
b. Une liste de contrôle sourcée : taille, période, quota, réserve possible (« regarde le panneau »), sans jamais écrire « tu peux la garder »
c. Aucune règle appliquée : un texte et le lien de la fédération
Ma reco : b, l'app montre la loi au lieu d'accorder une permission. Par défaut : b.

**Tranché : que bloque le paywall ?** Adem, 15 oct. (12h26 et 12h28) : le gratuit garde UN spot (cercle de 1 km) avec des sessions illimitées ; la fin de la 1re session ouvre le paywall, qui se ferme ; choisir un 2e spot ouvre le paywall, qui bloque. La carte, les règles et le Pescedex en lecture restent gratuits pour toujours.

**Tranché : qui choisit le spot gratuit ?** Adem, 15 oct. 12h32 : l'app propose le plus proche avec des relevés OFB récents et une espèce ouverte ce jour ; le pêcheur peut en prendre un autre sur la carte avant sa 1re session, puis il est fixé.
