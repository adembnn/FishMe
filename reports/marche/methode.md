# Comment on étudie un marché d'apps sans se faire avoir

Décision débloquée : la façon de lire les trois rapports de `reports/marche/` (quels chiffres croire, lesquels sont des indices) et les outils qu'on réutilise à chaque veille.
Recherche du 19/10/2026. [?] = non vérifié. « Estimation » = calcul de ma part, pas une mesure.

## 1. Les cinq questions auxquelles une étude de marché répond
1. Combien de gens ont le problème, et combien paient déjà pour le résoudre (pas « combien de pêcheurs », mais « combien ont une app de pêche installée et combien ont payé »).
2. Qui gagne aujourd'hui et pourquoi : quelle fonction, quel canal, quel moment d'entrée (une app qui gagne a souvent eu un moment, pas une liste de fonctions).
3. Ce que les utilisateurs reprochent aux gagnants : c'est là que se loge une entrée, pas dans ce qu'ils aiment.
4. Comment les gagnants ont trouvé leurs 1 000, puis 10 000 premiers utilisateurs : les canaux d'une app à 2 millions d'utilisateurs ne sont pas ceux de son premier mois.
5. Qui est mort, et de quoi : les apps retirées du store disent où le marché ne paie pas.

## 2. Où les chiffres mentent
| Chiffre | Ce qu'il mesure vraiment | Comment le lire |
|---|---|---|
| Note et nombre de notes App Store | Les gens qui ont répondu à la fenêtre « Noter l'app », par pays de store | Le nombre de notes est un ordre de grandeur de la base installée active (rapport 1 note pour 20 à 100 installs selon la façon dont l'app demande la note, estimation), jamais une mesure. Comparer deux apps sur un même pays seulement. |
| Avis écrits | Les extrêmes : très contents ou très fâchés | Un échantillon de plaintes, pas une statistique. Compter les thèmes, pas les étoiles. |
| « Installs » Google Play (le palier « cent mille et plus ») | Un palier de téléchargements cumulés depuis la création | Utile pour l'ordre de grandeur et la croissance entre deux dates (archives), pas pour les actifs. |
| Téléchargements et revenus estimés (Sensor Tower, AppMagic, data.ai) | Un modèle statistique calé sur des apps qui partagent leurs données | Marge d'erreur grande pour une petite app ; utile pour classer, pas pour chiffrer. Toujours écrire « estimé par X ». |
| « 2 millions de prises », « 15 000 spots » | Un compteur cumulé choisi par l'éditeur pour sa page d'accueil | Indice d'ancienneté et d'activité, pas d'utilisateurs. |
| Interview du fondateur sur « comment on a décollé » | Le récit du survivant, réécrit après coup | Croiser avec les archives web : la version du site à l'époque dit ce qu'ils vendaient vraiment. |
| Abonnés YouTube, Instagram, TikTok d'une chaîne pêche | Les abonnements cumulés, dont les dormants | Regarder les vues des 10 dernières vidéos, pas le compteur d'abonnés. |
| Détenteurs de carte de pêche (1,43 M en France en 2025, https://www.lechasseurfrancais.com/peche/plus-de-1-400-000-pecheurs-en-france-en-2025-185724.html) | Les gens qui ont payé un droit de pêcher une fois dans l'année | Plafond du marché, pas marché adressable : la part qui pêche plus de 7 jours par an et a un iPhone est bien plus petite (estimation à faire, jamais à affirmer). |

## 3. Les signaux gratuits qui ne mentent pas (ou peu)
- Rythme des versions (API iTunes lookup, historique des versions sur la fiche) : une app mise à jour chaque mois est vivante ; plus rien depuis 18 mois, elle est en roue libre.
- Croissance du nombre de notes entre deux dates : les archives web (Wayback Machine) gardent les fiches App Store ; la pente dit plus que le niveau.
- Liste et prix des achats intégrés (fiche App Store) : ce que l'éditeur pense pouvoir faire payer, et à quel palier.
- Publicités en cours : la bibliothèque publicitaire de Meta et le centre de transparence de Google montrent gratuitement qui paie de la pub, depuis quand, avec quels visuels. Une app qui n'y est pas pousse en organique.
- Mots-clés de la fiche (titre, sous-titre) : ce que l'éditeur croit que les gens tapent dans le store.
- Comptes d'entreprise (registres publics : Pappers ou societe.com en France, Companies House au Royaume-Uni, KvK aux Pays-Bas) : chiffre d'affaires et effectifs des éditeurs qui ont une société locale.
- Offres d'emploi et effectif LinkedIn : une app qui recrute un « growth » a un budget d'acquisition.
- Levées de fonds et rachats : communiqués de presse d'origine, pas les agrégateurs.
- Partenariats institutionnels (fédérations, offices, administrations) : pages des partenaires, pas celles de l'app.

## 4. Archéologie d'un lancement : comment un concurrent a trouvé ses premiers utilisateurs
Protocole, dans cet ordre, pour chaque app :
1. Première version du site et de la fiche store (archives web) : la promesse d'origine, le prix d'origine, les premiers partenaires affichés.
2. Premières mentions : presse spécialisée (peche.com, Angling Times, Blinker...), forums, Reddit, Product Hunt, avec filtre de date autour de la sortie.
3. Premiers contenus propres : première vidéo YouTube, premier post Instagram ou Facebook de la marque, et qui les a relayés.
4. Pub payante : bibliothèque Meta, transparence Google, aujourd'hui et dans les archives.
5. Institutions : fédérations, offices de tourisme, magasins, guides de pêche qui recommandent l'app, et depuis quand.
6. Mécanique dans l'app : parrainage, partage d'image, classement, tout ce qui fait inviter un ami.
7. Mise en avant par le store (« App du jour », sélection) : repérable dans la presse et les archives de la fiche.
Chaque étape produit une ligne datée avec son lien ; une étape sans trace reste vide et le dit.

## 5. Les apps mortes
- Repérage : fiches sans mise à jour depuis plus de deux ans, apps citées dans la presse de 2016 à 2022 qui n'ont plus de fiche, archives web du site.
- Lecture : la promesse d'origine (étape 1 du protocole) et le dernier signe de vie. Les post-mortems publiés par les fondateurs existent parfois ; les rachats aussi (une app rachetée puis fermée est une app morte pour le marché).
- Ce qu'on en tire : une liste de « ce qui n'a pas payé », à opposer à nos propres hypothèses.

## 6. Les erreurs classiques d'une étude de marché
1. Compter les fonctions : une app n'est pas la somme de ses fonctions ; les avis disent celles qui comptent.
2. Copier le leader : Fishbrain est américain, social, financé ; ses choix ne disent rien d'un marché français d'apps gratuites.
3. Prendre le plafond pour le marché : les détenteurs de carte ne sont pas des utilisateurs d'app.
4. Oublier la saison : les téléchargements d'apps de pêche suivent l'ouverture de la truite (mars) et les carnassiers (fin avril, juin) ; comparer deux apps à des mois différents est faux.
5. Lire un seul store, un seul pays : les Français notent peu ; le store américain d'une app américaine ne dit rien de son usage en France.
6. Croire un résumé : chaque chiffre vient avec sa page d'origine et sa date de lecture ; un chiffre lu dans un résumé de moteur est marqué « résumé moteur ».
7. Confondre « ils l'ont » et « ça marche » : une fonction présente chez tous peut n'être utilisée par personne ; chercher les avis qui la citent.
8. Décider pendant la lecture : la synthèse vient après les trois rapports, pas pendant.

## 7. Gabarit d'une fiche app (utilisé dans `concurrence-fr.md` et `pays.md`)
Nom, éditeur (société, pays, taille), sortie, dernière version, note et nombre de notes (pays, date), paliers de prix et achats intégrés, promesse de la fiche en une phrase, fonctions clés, ce que les avis réclament (thèmes comptés), ce que les avis reprochent, canal d'acquisition visible, partenaires, signe de vie (pub, recrutement, presse de l'année), ce qu'on en garde pour FishMe.

## 8. Les outils de `outils/marche/`
| Script | Ce qu'il tire | Source | Limite |
|---|---|---|---|
| `fiche_appstore.py` | fiche d'une app par pays | API iTunes lookup, gratuite, sans clé | pas d'historique |
| `avis_appstore.py` | avis récents par pays (jusqu'à 10 pages) | flux RSS JSON de l'App Store | la pagination s'arrête à la page 10, parfois vide pour un pays |
| `avis_play.py` | fiche et avis Google Play | `google-play-scraper` | non officiel, peut casser |
| `reddit.py` | fils par requête ou sous-forum | API JSON publique de Reddit | surtout anglophone |
| `classer_avis.py` | tri des avis par thème | mots-clés multilingues | tri grossier, pour orienter la lecture |
| `verifier.py` | contrôle des rapports : 200 lignes, date, chiffres sourcés, liens vivants | local | un lien « bloqué » (403, 429) n'est pas vérifié |
Pas de clé, pas d'abonnement. Les données tirées vont dans `reports/marche/donnees/`, jamais dans git.

## Recommandation
- Lire les trois rapports avec le tableau du §2 sous les yeux : un chiffre sans lien ni « estimation » est un trou, et `verifier.py` le refuse (§8).
- Pour chaque concurrent, c'est le protocole du §4 qui fait foi sur l'acquisition, pas le récit de l'éditeur (§2, ligne « interview du fondateur »).
- Rejouer les scripts (§8) une fois par mois après la sortie de FishMe : c'est la veille, et elle coûte zéro.
