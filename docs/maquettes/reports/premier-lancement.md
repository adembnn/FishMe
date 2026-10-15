# Premier lancement : matière brute pour les 30 premières secondes

Décision débloquée : quelle piste d'accueil dessiner (nombre d'écrans avant le premier moment fort, ce qu'on demande au départ, comment on montre qu'on peut glisser entre volets).

## Limites de cette recherche (à lire d'abord)
- Mobbin a refusé les appels : « Mobbin MCP requires a paid plan ». Aucune URL Mobbin, aucune capture vue. Tout ce qui suit vient du web (textes, fiches store, analyses publiées).
- Les comptes d'écrans ne sont mesurés que pour Duolingo et Fishbrain (et pour Fishbrain, c'est un total d'onboarding, pas « jusqu'au premier moment fort »). Pour les autres : non vérifié.
- À refaire avec un abonnement Mobbin si on veut les captures et les comptes exacts.

## 1. Parcours de premier lancement, app par app

### Merlin Bird ID (identification d'oiseaux)
- Écrans avant le premier moment fort : non mesuré (pas de capture accessible).
- Ce que l'app propose d'emblée : quatre portes (questions pas à pas, photo, enregistrement d'un chant, exploration par région) : https://play.google.com/store/apps/details?id=com.labs.merlinbirdid.app&hl=en_CA&gl=US
- Compte : aucun carte bancaire demandé, app gratuite : https://support.ebird.org/en/support/solutions/articles/48000961587-merlin-bird-id-faqs
- Moment fort : une liste d'oiseaux probables autour de toi, tirée de ta position (rayon d'environ 80 km) : https://www.allaboutbirds.org/news/introducing-merlin-photo-id-app-qa-with-jessie-barry
- Collection : « Life List » (liste personnelle d'espèces vues) et « Oiseau du jour » : https://www.merlinbirds.org/ et https://play.google.com/store/apps/details?id=com.labs.merlinbirdid.app&hl=en_CA&gl=US
- Fonctionne hors ligne (Photo ID, Sound ID) : https://www.merlinbirds.org/
- Point faible cité par un utilisateur : trop d'étapes pour enregistrer chaque observation, ce qui freine l'envie de le faire (même page Play Store).

### Seek (iNaturalist)
- Aucun compte, aucune collecte de données par défaut : https://www.inaturalist.org/pages/seek_app
- Demandé : la localisation (floutée, pour suggérer les espèces de la zone) : https://www.inaturalist.org/pages/seek_app
- Caméra : s'ouvre depuis n'importe quel écran ; un message de sécurité s'affiche avant : http://static.inaturalist.org/wiki_page_attachments/SeekUserGuide2020.pdf
- Moment fort : identification en direct à l'écran, sans réseau ; une jauge à 7 niveaux (règne jusqu'à espèce) se remplit, et l'observation ne s'ajoute que quand les 7 points sont pleins : même guide PDF.
- Récompense : badges et défis mensuels : https://www.inaturalist.org/pages/seek_app
- Écrans avant le premier moment fort : non mesuré.

### Pokémon GO
- Ordre documenté : pop-ups (notifications facultatives, localisation nécessaire), date de naissance, nouveau joueur ou joueur de retour, connexion, choix de l'apparence, intro du Professeur Willow, confidentialité puis conditions, bouton Continuer : https://www.lifewire.com/how-to-play-pokemon-go-8665044
- Premier moment fort : choisir un des trois starters et le capturer (glisser-lâcher la Poké Ball) : https://www.lifewire.com/how-to-play-pokemon-go-8665044 ; https://www.imore.com/beginners-guide-pokemon-go-pokemon-lets-go-players
- Caméra : mode AR désactivable dans l'écran de capture, donc non obligatoire : https://www.nme.com/blogs/nme-blogs/pokemon-go-everything-you-need-to-know-1188402
- Pas de vrai tutoriel au-delà de courtes astuces (avis de 2016, peut avoir changé) : https://kotaku.com/how-to-play-pokemon-go-1783354400
- Écrans avant le premier moment fort : une dizaine d'étapes d'après la liste Lifewire ; compte non mesuré sur captures.

### Pokémon Sleep (cas voisin : le jeu ne démarre qu'avec une permission)
- Le joueur reçoit un Ronflex dès le début : https://en.wikipedia.org/wiki/Pok%C3%A9mon_Sleep
- Le micro est requis pour suivre le sommeil, même avec l'enregistrement audio coupé : https://support.pokemon.com/hc/en-us/articles/17264561707796-Pok%C3%A9mon-Sleep-Gameplay-FAQ
- Le premier gain (un Pokémon) dépend d'une nuit entière : l'exemple inverse de notre objectif de 30 secondes. Déduction de notre part, non sourcée.

### Duolingo
- Le seul parcours chiffré proprement. Séquence : écran « Apprends gratuitement. Pour toujours. », choix de la langue, questionnaire mené par la mascotte (source, raison, niveau, objectif quotidien), puis la première leçon, sans compte ni paywall : https://www.botsi.com/resources/flows/apps/duolingo ; https://screenrove.com/duolingo/flows
- Compte demandé après la leçon, avec un bouton « Plus tard » : https://screenrove.com/duolingo/flows
- Chiffres : le teardown de Botsi compte 33 écrans enregistrés en déc. 2024, et place le début de la leçon vers l'écran 38 et la création de compte vers l'écran 134 (numérotation de leur enregistrement, pas un nombre d'écrans vus par l'utilisateur) : https://www.botsi.com/resources/flows/apps/duolingo. Analyse plus ancienne : 7 étapes, leçon à l'étape 6 : https://github.com/sanklp-dev/cram/blob/main/duolingo-ux-research.md. Les deux chiffres divergent : prendre l'ordre des étapes, pas le nombre.
- Récompense de fin de leçon : XP, série (streak), gemmes : https://screenrove.com/duolingo/flows

### Fishbrain (le concurrent direct)
- Onboarding de 12 écrans capturés : https://theappfuel.com/examples/fishbrain_onboarding (contenu des écrans non lisible en texte).
- Version gratuite limitée : un aperçu 7 jours des meilleurs moments et appâts, le reste en Pro : https://fishbrain.com/
- Le paywall bloque des fonctions de base : cité dans 40 % des avis négatifs sur 500 avis lus (86 sur 216) : https://glotier.com/apps/fishbrain-fishing-app
- Un utilisateur voulait un carnet privé et trouve une app orientée réseau social : https://play.google.com/store/apps/details?id=com.fishbrain.app&hl=en_US
- Le niveau de confidentialité d'une prise se choisit parmi trois (position exacte, nom du plan d'eau, rien) : https://fishbrain.com/
- Les empty states (écrans vides qui guident) font partie de leur travail d'onboarding : https://www.inesjoao.me/fishbrain-app
- Moment fort au lancement : non vérifié.

### App à volets glissés : Snapchat
- S'ouvre toujours sur la caméra, le volet central : https://help.snapchat.com/hc/en-gb/articles/7012332815508-How-to-Use-Snapchat
- Glisser vers la droite : Chat ; vers la gauche : Stories : même page d'aide.
- Refonte de sept. 2024 : de cinq à trois onglets (messages, caméra, flux vidéo) : https://www.theverge.com/2024/9/17/24246999/snapchat-redesign-three-tabs-stories-spotlight
- Le compte se crée avant (Bitmoji ensuite), contrairement à Duolingo : https://assets.ctfassets.net/gqgsr8avay9x/60HGeq7lGysoFlH8bucYUs/d960401de74378dddf62dc48d6e49d9f/GuidetoSnapchat_English.pdf
- Écrans d'onboarding Snapchat : non mesuré.

## 2. Volet central encadré par deux voisins

1. Snapchat (3 volets) : caméra au centre, flanquée de Chat à gauche et Stories à droite ; la barre du bas ne montre que Chat, Caméra, Discover, caméra agrandie. Sources : https://www.standard.co.uk/news/tech/snapchat-new-app-design-2024-b1183001.html ; https://uxdesign.cc/how-to-improve-the-snapchat-navigation-fb9d3786ba2a
2. Clash Royale : on change de vue en glissant gauche-droite ou en touchant l'icône du bas (deux chemins pour le même résultat) : https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale. Cinq vues dont Battle, au bas de l'écran. Une étude de cas confirme « horizontal swipe-based navigation between screens » : https://karimmuhtar.com/ux-design/clash-royale
3. Pas d'exemple trouvé avec les deux voisins visibles en bord d'écran. Le seul principe sourcé : montrer des moitiés d'images ou des mots coupés signale qu'on peut glisser (FilmStruck, OpenTable), et les points seuls sont un mauvais signal sur mobile : https://www.nngroup.com/articles/mobile-carousels/ ; https://www.nngroup.com/articles/designing-effective-carousels/

## 3. Cinq constats transposables

1. Donner la première victoire avant le compte. Duolingo lance la leçon sans compte et le demande ensuite avec « Plus tard » (https://screenrove.com/duolingo/flows) ; Seek n'en demande jamais par défaut (https://www.inaturalist.org/pages/seek_app). Pour nous : première carte de prise avant toute inscription.
2. Demander une permission au moment où elle sert. Seek explique la localisation par l'usage (suggestions de la zone, https://www.inaturalist.org/pages/seek_app) ; Pokémon GO classe les notifications en facultatif et la localisation en nécessaire (https://www.lifewire.com/how-to-play-pokemon-go-8665044). Pour nous : localisation au bouton « Trouver le meilleur spot », caméra au premier scan de poisson.
3. Une jauge qui se remplit rend l'attente jouable. Seek : 7 points à remplir avant d'ajouter l'observation (guide PDF cité plus haut). Idée pour la carte de prise : révélation par paliers (famille, genre, espèce).
4. Un guide à voix de personnage allège les questions. Duolingo (Duo) et Pokémon GO (Professeur Willow) : https://www.botsi.com/resources/flows/apps/duolingo ; https://www.imore.com/beginners-guide-pokemon-go-pokemon-lets-go-players. À décider par vous : si un personnage-guide existe dans notre univers.
5. Deux chemins vers le même volet. Clash Royale : glisser ou toucher l'icône (https://www.therookies.co/blog/education/game-design-ux-best-practices-detailed-breakdown-of-clash-royale). Pour nous : le glissement est un bonus, jamais le seul moyen.

## Trois pièges

1. Un geste caché que personne ne trouve. Les carrousels mobiles souffrent d'une faible découvrabilité, et des points sous le contenu sont peu remarqués : https://www.nngroup.com/articles/mobile-carousels/. Il faut un indice visible (bord du voisin, ou micro-animation de rebond au premier lancement ; cette dernière est notre idée, non sourcée).
2. L'ambiguïté du glissement : un balayage près du bord peut déclencher un retour système ou changer de volet. NN/g recommande une marge (« page gutter ») : https://www.nngroup.com/articles/mobile-carousels/. Vigilance si une carte ou une liste scrolle horizontalement dans le volet central (carte des spots).
3. Le mur payant sur les fonctions de base. Fishbrain en souffre (40 % des avis négatifs lus, https://glotier.com/apps/fishbrain-fishing-app). Le sommeil de Pokémon Sleep montre l'autre piège : un premier gain retardé hors de portée de 30 secondes (déduction de notre part).

## Pistes pour dessiner (à trancher par vous)
- Combien d'écrans avant la première carte : l'ordre Duolingo (valeur d'abord, compte ensuite) est le mieux documenté ; le nombre exact reste à fixer.
- Indice de glissement : bord du voisin visible ou rebond au démarrage.
- Compte : après la première carte, avec « Plus tard ».
