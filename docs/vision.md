# Ta vision du 15 oct., challengée

Là où ce texte et `CLAUDE.md` diffèrent, `CLAUDE.md` l'emporte : il porte les décisions prises après ce texte.

Ta demande du 15 oct. (3 volets façon Clash Royale, IA entraînée, réglementation, mers et océans, carte, rareté, écrans) et ta capture « une version plus profonde, pas plus grosse ». Ce qui en sort pour la construction est dans `lots.md` et `parcours-demo.md` ; les recherches sont dans `reports/reconnaissance.md`, `reports/mer.md` et `reports/navigation-communaute.md`. « Estimation » veut dire calcul de Claude, pas mesure.

## 1. Ta capture, appliquée à ta demande

**Ce qu'un pro ferait sans que tu le demandes**
- Il partirait de la relecture d'Apple, pas de la liste des fonctions. Publier vendredi 15 h veut dire une version petite et complète chez Apple ce soir ; tout ce qui vient après devient une mise à jour, montrée depuis TestFlight. « Complet et exhaustif » est l'inverse de ce qu'il ferait en 30 heures.
- Il choisirait un seul moment fort (photo, espèce, verdict, la carte qui se révèle) et couperait ce qui ne le sert pas.
- Il fabriquerait le jeu de test avant le modèle : des photos de vraies prises, jamais vues à l'entraînement, qui notent l'IA.
- Il traiterait le risque juridique dans la conception : le verdict est une recherche dans une table relue et sourcée, jamais une décision de l'IA, et l'app se tait là où la table est vide.
- Il préparerait le chemin du relecteur d'Apple, qui n'a ni poisson, ni carte de pêche, ni ami dans l'app.

**La matière la plus brute, au lieu de ce qui est déjà digéré**
- Les textes : les articles R436-6 à R436-21 du Code de l'environnement sur Légifrance et les arrêtés préfectoraux 2026 des 5 départements, en PDF, pas un résumé de site de pêche.
- Les relevés : chaque pêche électrique de l'OFB (date, station, espèces, effectifs) par Hub'Eau, pas une rareté déjà calculée par quelqu'un.
- Les photos : des prises réelles, mouillées, tenues en main, prises par des pêcheurs, pas des photos de guide sous l'eau.
- Les gestes : l'enregistrement d'écran d'une partie de Clash Royale et d'une prise dans Fishbrain, regardés image par image.
- Les gens : trois pêcheurs sur un quai de la Marne, à qui on tend l'iPhone sans rien expliquer.

**Les méthodes et les outils**
- Create ML, l'app d'Apple qui entraîne un modèle en glissant des dossiers de photos, sans code. On le note sur un jeu de test tenu à part : la bonne espèce en n°1 (top-1), parmi les 3 proposées (top-3), et le tableau des confusions (« quand c'était un gardon, il a dit brème N fois »).
- Des photos d'entraînement CC0 ou CC-BY prises hors d'iNaturalist (sur GBIF), parce que les conditions d'iNaturalist interdisent d'entraîner une IA à usage commercial (`reports/reconnaissance.md` §2).
- Les règles écrites en données (un fichier où chaque ligne porte sa source et sa date de lecture), et des cas d'or : des situations dont un humain écrit la réponse d'après l'arrêté, que les tests rejouent à chaque fusion.
- La barre d'onglets native d'iOS 27, TestFlight, et la relecture accélérée demandée par MWM.

**Ce qui prouvera que c'est juste, en dehors de toi et moi**
- Le score du modèle sur des photos qu'il n'a jamais vues, fixé avant l'entraînement.
- La fédération de pêche du 94 ou un garde-pêche qui confirme nos cas de verdict, par mail ou par téléphone aujourd'hui.
- L'e-mail d'Apple qui dit que l'app est prête à la publication.
- Trois pêcheurs qui vont de la photo à la carte, sur TestFlight, sans aide.

**Ton prompt, réécrit**
```text
Voici ma vision de l'app : 3 volets façon Clash Royale, la carte au centre avec « commencer une session » et
« trouver le meilleur spot », le Pescedex à gauche, le club et la communauté à droite. Avant de planifier :
1. Pars de la publication de vendredi 15 h et de la relecture d'Apple : dis ce qui part ce soir et ce qui devient une mise à jour.
2. Pour chaque fonction, dis ce qu'en verront le relecteur d'Apple et un pêcheur qui ne nous connaît pas ; coupe ce qu'aucun des deux ne verra.
3. Reconnaissance : pars de vraies photos de prises et des licences ; fixe le score qui autorise la publication avant
   d'entraîner quoi que ce soit, et compare notre modèle à l'IA d'Apple sur les mêmes photos.
4. Réglementation : pars des articles de Légifrance et des arrêtés 2026, montre chaque règle avec sa source, dis où l'app
   doit se taire, et dis qui, hors de l'équipe, peut valider nos cas.
5. Mers et océans : dis précisément ce qui manque (données, règles, espèces) et ce que ça coûterait.
6. Définis la carte, la rareté et les écrans au plus court, puis découpe en lots pour Adem, Titouan et Sullyvan,
   chacun avec le test qui bloque sa fusion.
```

## 2. Le challenge, point par point

### Les 3 volets
Ce qui tient : ton schéma est celui de Clash Royale (la collection d'un côté, le combat au centre, le clan de l'autre), et il se fait avec la barre d'onglets standard d'iOS 27 : 3 boutons en verre, toujours visibles, l'app s'ouvre sur le centre (`reports/navigation-communaute.md`).
Ce qui coince :
- Le glissement d'un volet à l'autre se bat avec la carte, qui se déplace elle aussi au doigt. Les règles d'Apple (HIG) demandent que le glissement ne soit jamais le seul chemin.
- Une barre faite maison perd la lecture d'écran pour les aveugles (VoiceOver ne dit plus « onglet 1 sur 3 ») ; la barre standard l'a gratuitement.
Recommandation : la barre standard ce soir (1 h, estimation) ; le glissement par les bords de l'écran (bandes de 24 points) seulement si la base est déjà fusionnée, avec un test sur iPhone : un doigt qui déplace la carte ne change jamais de volet.

### « Commencer une session »
Une session, c'est une sortie de pêche qui a un début et une fin : chrono, heure de fin légale (coucher du soleil plus 30 minutes), nombre de prises. Elle ne mérite sa place ce soir que pour deux raisons, et les deux sont fortes :
- elle compte les poissons gardés contre le quota du jour (3 carnassiers en 2e catégorie, dont 2 brochets au plus) : c'est de la réglementation utile, pas un gadget ;
- elle donne sa carte au pêcheur bredouille, qui sinon n'a rien.
Ce qui coince : le compte à rebours sur l'écran verrouillé (Live Activity) demande une extension à part dans le projet Xcode. Recommandation : ce soir, la session vit dans l'app (un bandeau sur la carte) ; l'écran verrouillé vient dans la mise à jour.

### « Trouver le meilleur spot »
Ce qui coince : aucune donnée ne dit où est le « meilleur » coin. L'OFB dit où une espèce a été relevée lors d'une pêche électrique, combien de fois et quand ; ses stations sont des points de mesure, souvent sans accès public. Promettre « le meilleur » et laisser un pêcheur bredouille, c'est la critique qu'un juré pêcheur fera en premier.
Recommandation : le bouton devient « Choisir un autre spot ». On choisit une espèce (ou aucune) ; l'app montre les 3 coins publics les plus proches (OpenStreetMap et la fédération) près desquels l'OFB l'a relevée, chacun avec « N pêches, dernier relevé AAAA » et « ouvert aujourd'hui » ou « fermé ». Le calcul existe déjà dans `Core` (`especesProches`).

### Le volet droit : club et communauté
Ce qui coince :
- Une vraie communauté (voir les prises d'inconnus, commenter) déclenche la règle 1.2 d'Apple : filtrer, signaler, bloquer, publier un contact. Aucun serveur ni aucune modération n'existe aujourd'hui.
- Game Center (classements d'Apple) n'est interdit par aucun texte lu, mais tout y est écrit pour les jeux, il passe par une relecture à part, et un classement par rareté pousserait vers les espèces protégées ou trop petites.
- L'annuaire des associations de pêche (AAPPMA) de cartedepeche.fr interdit toute réutilisation sans accord écrit de la fédération nationale. On peut y renvoyer par un lien, pas le copier.
- Titouan avait classé l'onglet « Communauté » comme une mauvaise idée pour cette semaine (son skill `anti-sur-ingenierie`).

Options (probabilité qu'un autre LLM la propose, estimation) :
| Option | Ce soir | Autre LLM |
|---|---|---|
| a. Fil communautaire public | impossible sans modération | 70 % |
| b. Amis par invitation, cartes partagées par iCloud (CloudKit) | 10 à 18 h et la règle 1.2 par prudence : version suivante | 45 % |
| c. Classements et succès Game Center | 4 à 7 h et une relecture à part : version suivante | 40 % |
| d. « Mon club » : ma fédération et mon association (lien), « j'ai ma carte de pêche 2026 », confidentialité et contact | 3 à 5 h, rien à modérer | 15 % |
| e. Partage d'une carte en image (Messages, Instagram) depuis chaque carte du Pescedex | 1 à 2 h, rien à modérer | 50 % |
| f. Objectifs de saison personnels (« 5 espèces avant la fermeture du brochet ») | 2 h, calculés sur l'iPhone | 12 % |
Recommandation : d + e ce soir, b dans la mise à jour. Option la plus forte écartée : c, qui donne amis et notifications gratuitement mais dépend d'une relecture à part.

### Entraîner un algorithme de reconnaissance
Ce qui coince (`reports/reconnaissance.md`) :
- La source de photos évidente, iNaturalist, interdit l'entraînement d'une IA commerciale. Un juré technique peut le relever.
- Hors d'iNaturalist, il reste moins de 160 observations libres pour le sandre, le silure, le barbeau et l'ombre, et presque aucune montre un poisson tenu en main.
- Aucun chiffre publié ne dit si une IA distingue un gardon d'une brème, ou une fario d'une arc-en-ciel, sur une photo de pêcheur. Il faut le mesurer nous-mêmes.
- L'IA d'Apple sans entraînement (Foundation Models) ne tourne que sur iPhone 15 Pro et plus, avec Apple Intelligence activé : l'iPhone du relecteur peut ne pas l'avoir.
- Le reproche ne viendra pas d'une erreur d'espèce. Il viendra d'un verdict faux affiché comme sûr.

Recommandation :
- La grille des 14 espèces reste le chemin qui marche toujours, avec pour chaque espèce sa silhouette et son critère distinctif.
- On entraîne un modèle Create ML sur les photos libres hors iNaturalist et sur nos propres photos. Il n'entre dans l'app que s'il passe le test fixé avant l'entraînement, sur des photos tenues à part : bonne espèce parmi les 3 proposées dans 90 % des cas au moins, en n°1 dans 70 % des cas au moins (seuils proposés). Sinon, la version de ce soir propose l'IA d'Apple sur les iPhone qui l'ont, seulement si elle passe le même test, et la grille partout ailleurs ; le modèle arrive dans la mise à jour.
- Pour les paires proches (gardon, brème, chevesne ; fario, arc-en-ciel), l'écran de confirmation montre le critère qui les sépare, et « je ne sais pas » reste toujours visible.
- Tant que l'espèce n'est pas confirmée, l'app affiche le verdict le plus prudent des espèces encore possibles : « relâche-la ».
Option la plus forte écartée : l'IA d'Apple comme aide principale. Elle reste valable si, sur le même jeu de test, elle bat notre modèle (une heure pour le mesurer, estimation).

### Appliquer la réglementation sans qu'on vous le reproche
Ce qu'on peut vous reprocher, du plus grave au moins grave :
1. Dire « tu peux la garder » à tort : taille, période, quota, réserve de pêche, espèce protégée.
2. Laisser croire qu'un poisson gardé se mange, alors que la Seine et la Marne sont sous interdiction de consommation (PCB, arrêté 2010-555).
3. Afficher une règle sans dire d'où elle vient ni de quand.

Ce que le plan fait déjà : l'IA propose, le pêcheur confirme, la table décide ; chaque verdict porte sa source, sa date de lecture et « l'arrêté préfectoral fait foi, en cas de doute, relâche » ; hors des départements saisis, jamais « tu peux la garder ».

Ce que j'ajoute :
- L'app n'accorde jamais la permission de garder, même dans un département relu : une liste de contrôle sourcée, puis « relâche-la », « vérifie l'arrêté » ou « aucune règle saisie ne l'interdit ; l'arrêté fait foi » (`CLAUDE.md`). La liste des départements couverts vient des données : si le 77 n'est pas chargé ce soir, l'app dit « vérifie l'arrêté » dans le 77, sans une ligne de code de plus.
- La session compte les poissons gardés : au troisième carnassier du jour, « quota du jour atteint ».
- Une validation hors de l'équipe : on envoie nos cas de verdict à la fédération du 94 aujourd'hui, et on dit au jury qui les a confirmés.
- Aujourd'hui, les règles ne sont qu'un brouillon (6 tailles nationales et 3 règles du 94, rien de relu) : leur saisie et leur relecture passent en tête de journée.

### Mers et océans
Réponse courte : rien ne l'interdit, mais trois choses le rendent impossible à faire juste d'ici demain (`reports/mer.md`).
- Pas de rareté honnête : Hub'Eau ne couvre pas la mer, et les campagnes de l'Ifremer (chalut de fond au large, une fois par automne) ne voient ni le bar de digue ni le mulet. Une rareté côtière serait inventée.
- Des règles d'une autre nature : la clé n'est plus le département mais la zone en mer (au nord ou au sud du 48e parallèle pour le bar), avec des quotas qui expirent chaque année (le quota de bar vaut du 1er avril au 31 décembre 2026), le marquage de la caudale, et l'enregistrement RecFishing ouvert le 12 février 2026. Les pages officielles se contredisent sur certains délais, et l'annexe consolidée de Légifrance n'est pas à jour.
- D'autres poissons à reconnaître, avec des confusions qui changent le verdict : bar et bar moucheté (42 cm contre 30 cm), lieu jaune et lieu noir.
Coût estimé : 55 à 65 h pour 10 espèces sur une seule façade. Recommandation : la mer dans une version suivante, en commençant par Manche et Atlantique après les mesures 2027. Phrase pour le jury : « On a commencé par l'eau douce, là où il existe des relevés officiels et une table de règles relue ligne par ligne. En mer, les règles changent chaque année et dépendent de la zone : on préfère ne rien afficher plutôt que dire à quelqu'un qu'il peut garder un poisson qui lui vaudrait une amende. »

### Garder les règles à jour, pour une app qui dure
Les règles bougent à quatre rythmes :
| Niveau | Texte | Rythme |
|---|---|---|
| National | Code de l'environnement, articles R436 | rare, par décret |
| Département | arrêté permanent (plusieurs années) et arrêté annuel (les dates de l'année, publié en fin d'année) | chaque année |
| Tronçon | réserves, parcours no-kill, pêche de nuit de la carpe | quelques fois par an, dans les arrêtés |
| Temporaire | sécheresse, pollution, travaux | n'importe quand, pour quelques jours ou semaines |

Le mécanisme, en cinq pièces :
1. Les règles sont des données, hors du code. L'app embarque une copie (pour marcher sans réseau) et télécharge au lancement la dernière version publiée. Corriger une règle ne passe plus par la relecture d'Apple, qui accepte des données téléchargées (pas du code).
2. Chaque règle porte une date de péremption : l'arrêté annuel 2026 expire le 31 décembre. Passé cette date, l'app dit « vérifie l'arrêté 2027 » ; une règle périmée ne donne jamais un faux feu vert.
3. Une veille automatique : chaque nuit, un robot GitHub (Actions, gratuit) regarde si les sources ont changé (la version des articles sur Légifrance par son API officielle PISTE, l'empreinte des pages des préfectures et des fédérations) et ouvre une alerte « l'arrêté du 94 a peut-être changé ».
4. Une mise à jour à deux paires d'yeux : Claude fait le premier jet depuis le nouveau texte, un humain le relit, les cas d'or rejouent, puis on publie.
5. Sous chaque règle, « signaler une erreur », qui arrive dans la même alerte.
À terme, les fédérations départementales publient déjà leur guide chaque année : un accord avec elles, ou avec la fédération nationale, ferait de l'app leur canal numérique et rendrait la mise à jour contractuelle. Pour la France entière, compter environ 100 arrêtés par an, 1 à 2 h chacun avec premier jet et relecture (estimation).
Ce soir : les règles en données embarquées et leur date de péremption (pièce 2), 2 à 3 h (estimation). Le téléchargement (pièce 1), la veille (3) et le signalement (5) viennent dans la mise à jour (lot L11). L'endroit où publier le fichier est un choix de fournisseur, donc une question pour toi.

## 6. La fusion avec l'atelier de Titouan
Titouan a écrit le 13 oct. un atelier complet dans `harnais-titouan/` (branche `titouan/harnais-bredouille`), rien compilé, crochets décrits mais pas installés ; son fichier `LISEZ-MOI-FUSION.md` demande la fusion. Ce que je propose, ligne par ligne :
| Sujet | Titouan | Toi | Par défaut |
|---|---|---|---|
| Base de l'atelier | crochets décrits, non installés | crochets installés, 180 essais sur 180 | ton atelier, dans lequel on importe ses pièces |
| Projet Xcode | XcodeGen (`project.yml`) | projet Xcode commité, dossiers synchronisés | le projet Xcode : rien à installer. Écartée : XcodeGen, zéro conflit de projet |
| iOS minimum | 26 | 27 (12 oct.), l'IA photo l'exige | 27 |
| Ouverture | l'appareil photo, 4 onglets | la carte au centre, 3 volets (ta vision) | 3 volets |
| Rareté | 5 classes, seuils 30/12/4/1 % | 4 niveaux, seuils 50/20 % (12 oct.) | 4 niveaux |
| Espèces | 48 au catalogue | 14 jouables | 14 ce soir ; son catalogue sert la mise à jour |
| Verdict | aucun : texte fixe et lien vers la fédération (sa règle A1) | garde, relâche, vérifie, sur table relue | question 2 |
| Communauté | aucune, partage d'image (son L38) | amis par lien (version suivante) | « Mon club » et partage d'image |
| Paywall | à la 16e carte, essai 1 semaine, 3,99 € et 24,99 € | à la 2e carte, essai 1 mois (12 oct., tombé) | tranché le 15 oct. (`CLAUDE.md`) : un spot gratuit ; paywall qui se ferme à la fin de la 1re session, qui bloque au choix d'un 2e spot ; mensuel avec 1 semaine d'essai, annuels sans essai |
| Nom | « Bredouille » | pas choisi | question d'une prochaine série |
| Données OFB | script Hub'Eau déjà lancé (75, 78, 92, 95), fichiers commités | script, jamais commité (ta règle) | son script devient le lot D2, ses fichiers sortent de git |
| Photos d'essai | 60 photos iNaturalist | aucune | iNaturalist interdit l'entraînement commercial : aucune ne sert à entraîner, nos photos servent au test |
| Relecteurs | 20 agents, 17 en Opus | 5 relecteurs, Opus pour la revue finale (ta règle) | on fusionne dans les tiens ses meilleurs (`testeur-identification`, `revue-ux-2taps`, `coupeur`, `verificateur-wording`), en Sonnet |
| Skills | 9, dont `anti-sur-ingenierie`, `liquid-glass-swiftui`, `zero-friction-2-taps` | 5 commandes | on reprend ces trois et sa liste de mots interdits |
| Équipe | 4 avec Alexandre ; Titouan sur PC Windows ; Sullyvan et Alexandre profils business avec un Mac | 3 (mémoire du projet) | question 1 |

## 3. Ce qu'on met sur une carte
Le recto porte 6 éléments, pas un de plus :
1. le poisson : l'illustration de l'espèce, ou le poisson détouré de la photo s'il marche ;
2. le nom de l'espèce (le nom latin en petit) ;
3. la rareté : la couleur du cadre et le mot (commun, peu commun, rare, légendaire) ;
4. la taille en centimètres ;
5. le lieu flouté : le cours d'eau et le département (« La Marne · 94 »), jamais le point exact ;
6. la date et son rang dans la zone (compteur par zone voulu par Adem le 15 oct., forme en discussion dans le fil Maquettes).

Le verso montre la vraie photo que le pêcheur a prise, souvent lui avec son poisson (Adem, 15 oct.), avec une bande courte :
- « Rareté dans les relevés OFB du 94 : relevée dans 9 pêches sur 29, dernier relevé 2023 » ; pour un légendaire, « aucune pêche OFB ne l'a relevée dans le 94 depuis 2016 » ;
- la consigne du moment avec sa source (une prise relâchée entre au Pescedex comme une prise gardée) ;
- l'heure, la phase de lune et, si la prise vient d'une session, sa durée.

La carte bredouille garde son dos à elle : lieu flouté, date, lune, durée de la session, et aucune rareté.
Une carte ne naît que d'une photo prise dans l'app (pas d'import), pour qu'une truite du poissonnier ne devienne pas légendaire. La photo d'exemple du relecteur donne une carte marquée « exemple », hors du compte du Pescedex.

## 4. La rareté
Ta base reste : 4 niveaux par département, calculés sur 10 ans de pêches électriques de l'OFB (commun 50 % des pêches et plus, peu commun 20 à 50 %, rare moins de 20 %, légendaire jamais relevé), avec la région quand le département a moins de 20 pêches.
Ce qui coince :
- La pêche électrique sous-compte les gros poissons et ne passe pas dans les étangs : la carpe sort « rare » dans le 94 (1 pêche sur 29), alors que tous les pêcheurs en prennent. Un juré pêcheur le verra.
- « Légendaire » veut dire « jamais relevé » : une truite arc-en-ciel lâchée dans un étang payant devient légendaire.
- Une carte se triche avec une photo trouvée en ligne. D'où la règle de la photo prise dans l'app.

Options (probabilité qu'un autre LLM la propose, estimation) :
| Option | Ce que ça change | Autre LLM |
|---|---|---|
| a. Tes 4 niveaux tels quels | rien ; le verso dit « dans les relevés OFB », ce qui reste vrai | 60 % |
| b. a + carte « trophée » au-dessus d'une taille par espèce (brochet 90 cm et plus, etc.) | une carte brillante, comme les cartes dorées des jeux | 35 % |
| c. a + tampon « relâchée », et une espèce menacée en France ne prend son cadre doré que relâchée | la collection récompense le geste que la réglementation demande | 8 % |
| d. Rareté personnelle : ta première prise de l'espèce compte double | simple, mais sans lien avec la nature | 25 % |
| e. Rareté selon les prises de la communauté | impossible au premier jour, aucune prise | 40 % |
| f. Légendaire renommé « première mention » : ta prise est la première donnée de l'espèce dans le département depuis 10 ans | même calcul, phrase plus juste et plus fière | 10 % |
Par défaut : a, sans changement. Le c et le f sont les plus originaux et coûtent moins d'une heure chacun (estimation) ; ils demandent ton accord, car c'est du design de produit.

## 5. Les écrans, au plus court
| # | Écran | Ce qu'il contient |
|---|---|---|
| 1 | Volet central : la carte | les coins, « Autour de moi », « Commencer une session », « Choisir un autre spot », le bandeau de session en cours |
| 2 | Feuille d'un coin | espèces relevées avec « N pêches, dernier relevé AAAA », la règle du jour avec sa source, « Y aller » (ouvre Plans) |
| 3 | Feuille de prise, en 3 temps | photo (ou photo d'exemple), puis 3 propositions ou la grille, puis la taille au curseur et le verdict |
| 4 | Révélation de la carte | la carte se retourne, puis rejoint le Pescedex |
| 5 | Volet gauche : le Pescedex | les 14 espèces (silhouettes pour celles pas encore prises), « 4 sur les 11 relevées dans le 94 », une carte s'ouvre au toucher (recto et verso) |
| 6 | Volet droit : Mon club | ma fédération et mon association (liens), « j'ai ma carte de pêche 2026 », Sources, confidentialité et contact |
| 7 | Paywall | à la fin de la 1re session, après la carte (il se ferme), et au choix d'un 2e spot (il bloque) ; mensuel avec 1 semaine d'essai, annuels sans essai ; « Restaurer », conditions et confidentialité |
Pas d'écran d'accueil : la position est demandée au premier lancement et la carte s'y adapte (Adem, 15 oct. 12h51), et la phrase légale vit sous chaque verdict. La page Sources (crédits OFB, OpenStreetMap, IGN, photos d'entraînement) s'ouvre depuis le volet droit.
