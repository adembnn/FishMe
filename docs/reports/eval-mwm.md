# Évaluation MWM et Apple : ce qui ne convaincra pas le jury
Décision débloquée : quelles étapes garder, couper ou renforcer pour le jury, et l'ordre de la démo
Lu le 12/10/2026. [?] = non vérifié. « Estimation » = ordre de grandeur de ma part, pas une mesure. Cette lecture n'est pas une validation.

## En deux phrases
L'idée que les autres apps n'ont pas : une carte pour chaque sortie, même bredouille. Ce qui manque au jury MWM : ce qu'on paie, pourquoi on revient, et des chiffres qu'il puisse voir.
Mots utilisés. SDK : kit de code d'un tiers (ici Spark Flash, de MWM) qui mesure l'usage et les achats. Paywall : l'écran qui demande de payer. Activation : le geste qui prouve que l'utilisateur a touché la valeur. Rétention : la part des gens qui reviennent.
Lecture par critère, si le jury notait aujourd'hui : produit moyen (premier moment utile faible sans poisson), monétisation insuffisante (la valeur payée n'est écrite nulle part), acquisition faible (aucune boucle dans la version soumise).

## 1. Premier moment utile (E1, E2) : la donnée est mince et vieille
**Le pêcheur du 75.** Hub'Eau (guichet web des données de l'OFB) donne 36 pêches scientifiques pour Paris, dont 34 au même point (la Seine à Paris 15e), de 1989 à 2011, la dernière le 07/06/2011 (perche 78 %, sandre 25 %, brochet 19 %, carpe 17 %, silure 11 %, black-bass 0 ; [opérations du 75](https://hubeau.eaufrance.fr/api/v1/etat_piscicole/operations?code_departement=75&size=50&fields=code_operation,date_operation,code_station,libelle_station), relu ce jour). Rien depuis quinze ans.
**La salle du jury** (le build est chez MWM à Boulogne-Billancourt, 92 ; le lieu du pitch n'est pas publié [?]) : 5 pêches depuis 2016, toutes au point « La Seine à Suresnes 2 », la dernière le 03/09/2025 ([opérations du 92](https://hubeau.eaufrance.fr/api/v1/etat_piscicole/operations?code_departement=92&date_operation_min=2016-01-01&size=50&fields=date_operation,libelle_station,code_departement)).
**Trou de données trouvé.** Ce même point (code station 03082000) est rangé sous L'Île-Saint-Denis (93) de 2016 à 2020, puis sous Suresnes (92) de 2021 à 2025 : 5 pêches dans chaque département, un seul point de Seine. La rareté du 92 et celle du 93 reposent sur lui. Lu trois fois via WebFetch, à confirmer par le script [?]. Le test « 5 points dans le bon département » de L1 ne le voit pas.
**Verdict.** Le test E1 (un coin et ses espèces en moins de 10 s) passera, car tout est embarqué. Il mesure l'affichage, pas l'utilité : le pêcheur lit « perche 78 %, sandre 25 % » d'une rivière qu'il connaît, d'après un relevé de 2011. Un pêcheur dans le jury le verra. La règle de donnees.md §3 (tout l'historique sous 20 pêches) calculerait la rareté de Paris sur 1989-2011. Un palier de 20 % tient alors à une seule pêche, et l'électropêche (relevé par chocs électriques) sous-compte les gros poissons : « carpe très rare » fera sourire. Les points de la carte parisienne viendront surtout des 30 à 60 coins saisis à la main : OpenStreetMap n'a que 1 624 coins pour toute la France (donnees.md) et son nombre à Paris est inconnu [?].
**Autre frein.** Demander la position au lancement met une fenêtre système avant toute valeur. MWM conseille de différer permissions et paywall : « defer everything that isn't the aha moment » ([guide rétention](https://mwm.ai/guides/how-to-improve-app-retention)). La carte doit s'ouvrir sans demande, la position se demande au toucher sur « Autour de moi ».
Parades honnêtes, sans fausse donnée (proba = chance qu'un autre LLM la propose, estimation ; en gras, sous 20 %) :
| # | Option | Proba | Mon avis |
|---|---|---|---|
| 1 | « N pêches, dernier relevé AAAA » sur la fiche et au dos de la carte | 45 % | Garder, étendre à la carte |
| 2 | Rareté calculée sur la région quand le département a moins de 20 pêches en 10 ans | 40 % | Garder, change la règle pour Paris |
| 3 | **Ouvrir sur la règle du jour et la fin légale (donnée sûre, déjà calculée pour E4), avant les espèces** | **15 %** | Garder : c'est le vrai premier moment utile |
| 4 | **Pastille « première prise enregistrée ici » : le trou des relevés devient la première carte du coin** | **4 %** | Si 1 h libre ; donnée de l'utilisateur, jamais un relevé |
| 5 | **Frise « 34 pêches en 22 ans au même point »** : la minceur racontée comme une histoire | **6 %** | Seulement si le temps le permet |
| 6 | Prêter la Marne à Charenton 2025 (11,9 km) à Paris | 35 % | Écarter : autre rivière, autre faune |

## 2. Raison de revenir : une seule étape la porte, E9
Médiane des apps : 27,3 % de retour au jour 1, 9,2 % au jour 7, 3,9 % au jour 30 ([MWM](https://mwm.ai/guides/how-to-improve-app-retention)). Une app de pêche s'ouvre quand on pêche, 1 à 4 fois par mois (estimation [?]) : la rétention se compte en sorties.
- **2e sortie.** Ce qui ramène : partir avec l'app ouverte. E4 (compte à rebours de fin légale) en fait un rituel ; E9 (carte bredouille) garantit qu'aucune sortie ne finit à vide. E9 porte la rétention, E6 porte l'activation. E9 coûte presque rien (briques de E6) et n'a qu'une phrase dans la démo : à inverser.
- **10e sortie.** Trou. Le parcours ne dit pas ce que devient la 2e perche. Dans le 94, 3 des 14 espèces sont « non relevées » (truites, ombre) : le Pescedex du 94 plafonne à 11. Un Parisien le remplit en quelques sorties, puis plus rien. L'exemple « 12 sur 31 » d'E6 est faux (donnees.md §3).
- **Saison.** La 1re catégorie est fermée du 21/09/2026 au 12/03/2027, réouverture le 13/03/2027 (donnees.md §4). Un essai de 30 jours lancé le 16/10 finit à la mi-novembre, au creux.
- **Pistes à faible coût (2 h, estimation).** Doublon = compteur « x7 » et record de taille par coin (le curseur de E5 existe déjà). Rappel local « le brochet ouvre samedi » (les dates sont dans regles.json), demandé après la fin de la 1re sortie, pas au lancement : MWM dit de déclencher « sur la valeur », pas sur la culpabilité.
- **E8** donnerait une raison sociale, mais lots.md la sort de la version soumise, et trois étudiants et leurs amis ne font pas un réseau [?].

## 3. Valeur payée : le parcours ne dit pas ce qu'on paie
E7 écrit « le paywall propose l'essai gratuit » après la première carte. Il ne dit ni ce qui est bloqué, ni ce qui continue après le 1er mois (Apple l'exige aussi : app-store.md §2.5, règle 3.1.2(a)). Premier trou pour MWM.
**Placement.** Après la 1re carte, c'est « après la valeur », ce que conseille MWM : un paywall dur à la première ouverture sacrifie la conversion durable ([guide monétisation](https://mwm.ai/guides/app-monetization-strategies)). Bon endroit si le premier affichage est souple : MWM décrit un paywall souple (« continuer gratuit ») au début, puis des blocages durs ciblés dans l'app ([glossaire](https://mwm.ai/glossary/paywall)).
Ce qu'on peut bloquer (proba qu'un autre LLM la propose, estimation) :
| # | Bloqué | Proba | Lecture jury |
|---|---|---|---|
| 1 | Cartes à collectionner n°2 et suivantes ; plan, règles et 1re carte gratuits | 70 % | Cohérent avec « après la valeur » ; valeur continue mince, à dire |
| 2 | Conseil du jour (E3) et météo | 45 % | Valeur continue réelle, mais E3 hors build et donnée mince |
| 3 | Amis (E8) et partage | 25 % | Hors build ; tue l'invitation si l'ami doit payer pour voir |
| 4 | 3 cartes gratuites par mois, puis abonnement | 30 % | Souple, mais paywall invisible en démo |
| 5 | **Un pass par département (achat unique), car la rareté est locale** | **8 %** | Aligné sur la promesse ; peu de récurrent, MWM juge sur la LTV (revenu par utilisateur) |
| 6 | **Pass de saison, renouvelé à l'ouverture de la 1re catégorie** | **5 %** | Colle au rythme du pêcheur ; inconnu du jury |
Vaut-il un abonnement ? Pas encore. Ce qui dure (règles à jour, fin légale) se trouve gratuitement ailleurs (HOOKfr, kickoff/fonctionnalites.md ligne 7) ; ce qui est à nous (rareté locale, carte) se consomme en quelques sorties. La valeur continue à écrire : le Pescedex du département qui se remplit, les records, les rappels d'ouverture, la météo.
Mon choix : option 1, avec le verdict « tu peux la garder » toujours gratuit (faire payer la loi nuit au bouche-à-oreille). Le paywall devient la page du Pescedex : la grille des 14 silhouettes (déjà prévues, donnees.md §8), une carte pleine, treize vides (**proba 12 %**). La valeur se voit sans texte.
**Essai.** Un mois sort des repères publiés par MWM, qui comparent 3 et 7 jours. Défendable : MWM écrit d'accorder l'essai à la fenêtre d'habitude, et un pêcheur sort peu. Deux coûts : aucun paiement visible avant le 15/11 au plus tôt (estimation : essai du 16/10 plus 30 jours), et le critère « tester prix, durée, essai » du cadrage reste sans test. Prévoir une variante 7 jours.
**Prix.** Pas fixé (14,99 € par an est l'hypothèse de kickoff/fonctionnalites.md [?]). Estimation : 1,43 M de détenteurs de carte x 1 % = 14 300 installs ; x 6 % de payants (hypothèse de planification MWM) = 858 abonnés ; x 14,99 € = environ 12 900 € bruts par an, avant Apple. Trop peu pour payer de la pub : l'acquisition sera organique (fédérations, image de la carte partagée). Tester deux prix.
**Événements pour Spark Flash.** Les conditions du SDK ([§6 et §8](https://mwm.ai/sdk-terms-of-service)) listent identifiant d'installation, appareil, localisation approximative par IP, achats si activés, et « les événements d'usage que vous définissez ». Les noms d'appels viendront du kit de jeudi [?]. Règles : rien avant le consentement ; jamais de photo, d'espèce, de taille, de coordonnées, de département ni de texte libre ; seulement des compteurs, des durées arrondies et des choix.
| Événement | Étape | Propriétés | Ce que MWM y lit |
|---|---|---|---|
| map_ready | E1 | ms depuis le lancement, nb de coins | premier moment utile (cible 10 s) |
| spot_opened | E2 | origine (osm, maison, ofb) | intérêt pour la fiche |
| capture_started | E5 | voie (ia, manuel, import) | part de l'IA face à la grille |
| card_created | E6, E9 | rang (1 à 10+), type (prise, bredouille), voie | rang 1 = le jalon d'activation unique |
| paywall_viewed, paywall_dismissed, purchase_started, restore_tapped | E7 | variante, offre (1 mois, 7 jours) | fuite avant l'essai (repère MWM : 5 à 15 %) |
| trial_started, paid | E7 | variante | essai vers payant (repère MWM : 40 à 70 %, [glossaire](https://mwm.ai/glossary/paywall)) ; viennent des achats si l'option est activée [?], ne pas doubler |
| session_started, session_ended | E4 | rang de sortie (2 à 10+), avec_prise, durée en tranches | retour à la 2e et à la 10e sortie |
| invite_sent, invite_accepted | E8 | aucune | seulement si E8 est dans le build |
**Consentement.** Une demi-feuille d'une ligne au premier lancement, la carte visible derrière, deux boutons de même poids. Refus = SDK éteint. MWM ne verra alors rien de ce testeur : lire aussi App Store Connect (installs, essais) [?]. Le SDK ne s'active pas pour une app visant les moins de 13 ans (§8(f)) : le dossier met en avant les 373 891 moins de 18 ans et l'usage « via le compte du parent » : MWM regardera où passe la frontière des 13 ans.

## 4. La démo de 2 minutes
parcours-demo.md propose E1, E2, E4, E5, E6, E8, puis une phrase pour E3, E9, E7. Trois défauts : le paywall (un des trois critères MWM) tient en une phrase finale ; E8 prend environ 25 s alors que lots.md la sort de la version soumise ; E9, qui porte la rétention, n'a qu'une phrase.
| Temps | Étape | Ce que le jury doit voir |
|---|---|---|
| 0:00 à 0:15 | E1, E2 | lancement à froid, « règle du jour, fin légale 19:33 », un coin, ses espèces avec « N pêches, AAAA » |
| 0:15 à 0:30 | E4 | « Démarrer la sortie », écran verrouillé, compte à rebours |
| 0:30 à 1:05 | E5 | mode avion visible, photo d'une vraie prise (dite préparée), 3 propositions, curseur, verdict avec source |
| 1:05 à 1:30 | E6 | la carte se révèle, « n sur N dans le 94 » : le moment fort |
| 1:30 à 1:45 | E7 | paywall juste après, achat avec le fichier de test StoreKit |
| 1:45 à 2:00 | E9 | carte bredouille, puis la phrase « [quoi] pour [qui], pour [quand] » |
**Ce qui impressionne** : E5 puis E6 (mode avion, l'iPhone propose, la table tranche, la carte se pose). Deuxième : E4. **Remplissage** : le détail des règles d'E2, E3 (donnée mince, aucun coin testé à la main, hors build), E8.
**Couper en premier jeudi, du point de vue du jury** : 1. E8. 2. E3. 3. les départements 93 et 77 (arrêtés non lus, donnees.md §4), puis E4. Jamais E5, E6, E7, E9.
E3 et E8 : une phrase chacune, en vidéo de 8 s marquée « prochaine version ». Montrer une fonction absente du build publié fait demander « et dans le store ? ». Phrase proposée, à valider : « La règle de pêche du jour et une carte par prise, pour le pêcheur du dimanche en Île-de-France, au moment où il a le poisson dans la main. »
Plan B : démo sur un build TestFlight interne (la relecture App Store a environ une chance sur deux d'arriver à temps, app-store.md §3) ; une vidéo de secours par étape (30 min, estimation), car la carte d'E1 demande du réseau et la salle peut en manquer.

## 5. Goût Apple : un seul moment fort
Ce qu'Apple a primé en 2026 de proche : Tide Guide (app de marées, Visuals and Graphics) pour « the Liquid Glass integration, aquatic theme, and sky-matching palette », grug (Delight and Fun) pour « a small but meaningful moment » ([Apple](https://apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/)). Une app utilitaire sur l'eau a gagné par un thème cohérent. Définitions : Delight and Fun = « memorable, engaging, and satisfying », Interaction = « intuitive interfaces and effortless controls » ([Apple](https://developer.apple.com/design/awards/)).
| # | Moment fort possible | Proba | Mon avis |
|---|---|---|---|
| 1 | Révélation de la carte : le poisson détouré se soulève de la photo, vibration, la carte se pose dans le Pescedex | 55 % | **Retenu** : c'est l'activation |
| 2 | Écran verrouillé : compte à rebours de fin légale | 35 % | Deuxième rang, pas le moment |
| 3 | Reflet holographique qui suit l'inclinaison de l'iPhone | 40 % | Écarter : cliché du jeu de cartes (marque de Nintendo) |
| 4 | **Mode avion basculé devant le jury, puis photo** | **10 %** | Geste de 3 s dans la séquence 1 |
| 5 | **Dos de la carte = contour du département (departements.geojson, déjà embarqué) avec N pêches** | **6 %** | Détail de la séquence 1 : rend visible la rareté locale |
| 6 | **Carte bredouille : même révélation, mais la lune se lève à la place du poisson** | **8 %** | Même animation, deuxième issue : 1 investissement |
**Cible proposée, à valider par Adem** : une police (New York, le serif d'Apple, pour les noms d'espèces ; SF pour le reste), deux couleurs (vert d'eau profond et papier crème, qui suivent l'heure du jour comme chez Tide Guide), une audace (le détourage qui sort du cadre). Coût de la séquence : 3 à 4 h (estimation).
**Ce qui fait « projet étudiant »** : le cadre jaune ou holographique et le dégradé violet ; 14 silhouettes de trait inégal (un seul trait, un seul profil, ou la photo détourée seule) ; les marqueurs par défaut de MapKit, tous pareils ; une Live Activity au gabarit par défaut (le compte à rebours natif existe : `numericText(countsDown:)`, [Apple](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)) ; le texte juridique qui mange l'écran du verdict (une phrase, la source en lien).
**Piège de la Live Activity.** Elle s'arrête après 8 h, et reste au plus 12 h sur l'écran verrouillé ([Apple](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)). Une sortie lancée à 07:39 le 15/10 dépasse 8 h avant la fin légale de 19:33 (donnees.md §6). À tester sur l'iPhone ; afficher « fin légale 19:33 » en texte fixe quand le minuteur s'arrête (30 min, estimation).
**Ce qui fait « pro »** : VoiceOver lisible (« Brochet, rare dans le 94, 62 cm »), Dynamic Type, une version calme de la révélation si « réduire les animations » est actif (1 h, estimation). Le paywall natif `SubscriptionStoreView` a l'air d'Apple mais se teste moins qu'un paywall MWM : à trancher avec le kit [?].

## 6. Les 7 problèmes les plus graves, classés
| # | Problème pour le jury | Correction | Coût (estimation) |
|---|---|---|---|
| 1 | Valeur payée, essai et prix non écrits : MWM ne peut ni juger ni tester | Une phrase gratuit / payant / valeur continue ; paywall = grille des silhouettes ; offre 7 jours et 2 prix prêts | 2 h 30 |
| 2 | Démo : paywall en dernier, E8 hors build, E9 en une phrase, pas de plan B réseau | Ordre du §4, vidéos de secours, 2 répétitions chronométrées | 2 h |
| 3 | Données du 75 et du 92 minces et vieilles, un seul point pour 92 et 93 | Options 1, 2, 3 du §1 ; test dans le script : un même point ne se partage pas entre deux départements | 2 h 30 |
| 4 | Aucune valeur sans poisson (salle, relecteur Apple, canapé) | Import depuis la photothèque, 3 photos de vraies prises, position demandée au toucher | 1 h 30 |
| 5 | Pas de raison de revenir hors E9, plafond de 14 espèces, rien de mesuré | Doublon et record, rappel d'ouverture, 8 événements derrière une seule couche `Analytics.track`, consentement | 4 h |
| 6 | Promesse et build divergent : « toute la France », collections des autres sur la carte, conseil de spot, Siri, « moins de 18 ans » ; le build a 5 départements, ni E8 ni E3 | Réécrire l'oral et la fiche : départements listés, 15 ans et plus, phrase du §4 | 45 min |
| 7 | IA décorative : le cadrage rejette « sans IA ça marche encore » ; avec 14 espèces et un repli manuel obligatoire (app-store.md §2.3), c'est vrai | Vendre le gain de temps et le mode avion, pas l'IA ; mesurer touches IA contre grille (`voie`) ; entrée image « Beta » dans la doc [?] | 1 h |
Total des corrections : environ 14 h, plus 3 à 4 h pour la séquence du §5 (estimation). Environ 2 h sont presque gratuites (ordre de la démo, étiquette N, mots du pitch). L'addition de lots.md dépasse déjà de 2 h par Mac : le plan ne tient pas sur deux Mac. Pour limiter : confier à C, via Claude Code cloud, la couche d'événements et le consentement (Swift sans écran, lots.md) ; retirer 93 et 77 (-2 h, D1) ; garder la séquence du §5 en version simple (1 h). Si rien ne bouge, sacrifier côté jury dans cet ordre : séquence §5 en version simple, rappel d'ouverture, doublon et record, E4. Les corrections 1, 2, 4 et 6 (environ 6 h 45) ne se sacrifient pas.

## Non vérifié [?]
Nombre de coins OSM dans Paris (Overpass refuse les robots) ; noms des appels et ce qu'affiche la Console MWM ; règles exactes de consentement (ePrivacy, CNIL) ; fréquence des sorties ; App Store Connect sans consentement ; lieu du pitch ; confirmation du point de Suresnes par le script.

## Recommandation
1. Écrire la valeur payée avant jeudi : option 1 du §3, paywall souple la 1re fois, bloquant à la 2e capture, verdict légal gratuit, page du Pescedex en silhouettes.
2. Démo dans l'ordre du §4 : paywall à l'écran, E9 visible, E3 et E8 en une phrase. Couper dans l'ordre E8, E3, 93 et 77, E4.
3. Données : N et année partout, rareté sur la région sous 20 pêches, ouverture sur la règle du jour.
4. Mesure : 8 événements du §3, consentement avant le SDK, public 15 ans et plus.
5. Un seul moment fort : la révélation de la carte, même animation pour la prise et la bredouille.
6. Capacité : les corrections 1, 2, 4 et 6 (environ 6 h 45) passent avant tout le reste ; E4 est le dernier sacrifice avant E5, E6, E7 et E9, qui ne se coupent pas.
Option la plus forte écartée : garder E8 en direct dans la démo. C'est la seule boucle sociale pour le critère acquisition, mais elle exige deux iPhones, deux comptes iCloud et le Wi-Fi de la salle, et le jury note le build publié.
Contexte : le paywall est le critère MWM le moins défini du parcours, et la démo en dépend.
Les choix de produit et de prix te reviennent, je ne les prends pas. Défaut si pas de réponse : la lettre recommandée.
1. Que bloque le paywall ? a. Cartes à collectionner n°2 et suivantes payantes, plan, règles et verdict gratuits (recommandé). b. Tout sauf la 1re carte. c. 3 cartes gratuites par mois.
2. Essai et prix ? a. 1 mois seul, comme décidé le 12/10. b. 1 mois plus variante 7 jours et 2 prix, testés dès la 1re semaine (recommandé). c. 7 jours seul.
3. E8 ? a. Hors version soumise, en vidéo « prochaine version » (recommandé). b. En direct dans la démo, avec vidéo de secours. c. Dans la version soumise si prête jeudi 14 h, comme app-store.md.
