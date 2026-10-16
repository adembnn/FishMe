# Fiche App Store de FishMe (S1)

Brouillon avancé par Sullyvan (15 oct. 2026), repris sur `lot/store` par A (Claude) le 15 oct. en fin d'après-midi, puis mis à jour le 16 oct. pour une soumission unique qui contient aussi Amis, le widget et l'écran verrouillé (Adem : tout dans une seule soumission) : description alignée sur `parcours-demo.md` (E1 à E9), sur les décisions d'Adem de 16h et 17h (premier lancement à glisser, 3 propositions plus « Autre », toise et poids estimé) et sur les listes Gratuit / Pro du paywall de L6 (`TextesPaywall.gratuit` et `.pro`, branche `lot/abonnement`).

Écrite en avance sur le lot S1 (tenu par Adem), à partir de `CLAUDE.md`, `docs/fiches/S1.md`, `docs/app-store.md` et de la relecture de Sullyvan (`origin/sullyvan/relecture-s1`), qui remplace la fiche « Bredouille » de Titouan. Code lu le 16 oct. sur `origin/mac/integration` (5780585) : c'est le code soumis ; `claude/finir-app-ud5swp`, `lot/amis` et `lot/ecran-verrouille` y sont déjà (seuls manquent à `mac/integration` des correctifs de `finir-app`, sans effet sur ces textes). Longueurs comptées par Python (`len()` en caractères, `len(.encode("utf-8"))` en octets), espaces compris.

Légende : **[?]** = non confirmé, à lire dans le build ou à demander. **À TRANCHER** : voir `a-trancher.md`, où chaque point porte maintenant le choix par défaut de A, à confirmer par Adem. Les crochets `[...]` du texte sont à remplir avant l'envoi ; aucun n'est inventé.

Outils MWM passés le 15 oct. vers 18h30 (heure de Paris), détail dans `mwm-resultats.md` : limites relues par `get_store_text_rules` (version 2026-10, identiques aux comptes ci-dessous ; les mots-clés se comptent en **caractères**, 100 au plus, pas en octets) ; mots-clés refaits avec `search_market_apps` et `analyze_market_keywords` (boutique française, iPhone) ; `review_store_text` ne relève aucun problème sur les six champs.

## Champs

| Champ | Valeur | Longueur |
|---|---|---|
| Nom | `FishMe` | 6 car., 6 octets (limite 30 car.) |
| Sous-titre | `Poissons, règles et Pescedex` | 28 car., 29 octets (limite 30 car.) |
| Catégorie principale | Sports (secondaire : Mode de vie) | par défaut de `fiches/S1.md`, à confirmer par Adem [?] |
| Mots-clés | `pêche,fishing,brochet,carpe,truite,sandre,perche,rivière,étang,lac,spot,carnet,réglementation` | 93 car. (limite 100 car.) |
| Texte promo | voir ci-dessous | 157 car., 159 octets (limite 170 car.) |
| Nouveautés | voir ci-dessous | 176 car., 181 octets (limite 4000 car.) |
| Description | voir ci-dessous | 3952 car., 4064 octets (limite 4000 car.) |
| Copyright | `© 2026 [ÉDITEUR, à demander à MWM]` | aucun nom inventé |
| URL d'assistance | `[URL_ASSISTANCE, donnée par Adem]` | jamais inventée |
| URL marketing | page web de l'app (`draft_landing_page`), après l'envoi de la fiche | |
| Contact de revue | `[PRÉNOM NOM]`, `[TÉLÉPHONE joignable vendredi]`, `[EMAIL]` | à donner par Adem |
| Connexion requise | Non (pas de compte, pas de compte démo) | |

### Choix de mots-clés
- Refaits le 15 oct. avec les chiffres MWM (`mwm-resultats.md`) : « fishing » entre (demande 4,2 sur 10, difficulté 6,3, le mot le plus partagé par les apps de pêche en France) ; « taille » sort pour lui faire la place. « spot » reste (demande 4,2). Les mots français (« pêche », espèces, « rivière »…) ne sont pas suivis par MWM en France : « pas relevé », gardés par jugement.
- Aucun nom de concurrent ni de marque : la liste des concurrents a été passée à `review_store_text`.
- Ni le nom de l'app, ni « Sports », ni de marque. « poisson » et « règles » sont déjà dans le sous-titre : Apple les indexe, inutile de les répéter ici.
- « spot » : mot de pêcheur, sans promesse de « bon spot ». « carte » est évité (confusion avec la carte de pêche, le permis).
- Mots-clés inchangés : « amis », « widget » ou « aquarium » ne sont pas ajoutés (93 car., il en reste 7 ; aucun chiffre MWM ne les soutient, et « widget » viserait la fonction plutôt que le sujet de l'app).
- Aucun mot ne dit « météo », « conseils » ou « alertes » : ils n'entrent dans les mots-clés qu'après la porte 3, si le build les a.
- Liste de repli si un mot est refusé ou peu demandé : `écrevisse`, `black-bass`, `silure`, `truite fario` (ajouter seulement ce que les 100 octets permettent, recompter).

### Nom et sous-titre
- Nom `FishMe` : décidé par Adem le 15 oct. à 12h36. « Pescedex » n'est jamais le nom de l'app.
- Sous-titre proposé `Poissons, règles et Pescedex` : dit les trois piliers (poissons relevés, règles sourcées, collection). Remplace « Une carte par sortie de pêche » (ancien produit). Alternatives (aussi comptées) : `Où pêcher et quoi y prendre` (27 car.), `Pêche : spots, règles, cartes` (29 car.). La première suggère une promesse de prise, la seconde confond avec la carte de pêche : recommandation, garder le sous-titre proposé. Choix final à Sullyvan ou Adem.

### Texte promo (157 car.)
```
Photographie ta prise, confirme l'espèce, et ta carte rejoint le Pescedex. Partage-la avec tes amis. La carte, les règles et ta collection restent gratuites.
```

### Nouveautés (176 car.)
```
Nouveau dans FishMe : tes amis voient ta collection si tu les invites, ta session s'affiche sur l'écran verrouillé et le widget « Mon aquarium » arrive sur ton écran d'accueil.
```

## Description (3952 car., 4064 octets, sous 4000)

Chaque ligne doit correspondre à un écran vu sur l'iPhone dans le build TestFlight (test 2 de `fiches/S1.md`) : sinon on la retire (refus R7). Il reste un seul trou dans le texte, `[COUVERTURE]` (départements lus dans le build), plus les deux URL. La phrase « l'app reconnaît N espèces » n'est pas écrite : elle ne s'ajoute que si N est lu dans le modèle livré par R1 (77 visées, repli sur 6).

```
FishMe est l'app de pêche en eau douce qui te montre où pêcher, quels poissons y vivent et quelles règles s'y appliquent, puis transforme chacune de tes prises en carte à collectionner.

LA CARTE
- Autour de toi, les poissons relevés par l'Office français de la biodiversité (OFB), en images, avec le nombre de pêches et l'année du dernier relevé.
- Touche un coin : ses espèces et leur rareté dans le département, les conditions du moment (vent, pluie, pression) et la jauge de la rivière.
- Les règles du jour en lignes courtes : taille, quota, ouverture. La source et la citation de chaque règle s'ouvrent d'un toucher.
- Règles couvertes : le socle national partout, et les règles locales de [COUVERTURE]. Ailleurs, l'app le dit et donne le lien de la préfecture.
- Une vigilance orage ou crue s'affiche en haut de la carte.

LA SESSION
- Lance une session : chrono, heure de fin légale, tes prises du jour, et une carte « à essayer » (appât, hameçon, technique) pour les espèces ouvertes.
- Photographie ta prise : l'app propose 3 espèces en images, sans aucun pourcentage, et c'est toi qui choisis. « Autre espèce » ouvre toutes les espèces de France en images ; « Pas un poisson » est toujours là.
- Pose ton poisson sur ta toise : l'app lit la graduation et tu confirmes la taille. Le poids est estimé à partir de la longueur, et marqué comme tel.

LE PESCEDEX
- Chaque prise confirmée devient une carte : au recto le poisson, sa rareté (commune, peu commune, rare, légendaire) et sa taille ; au dos ta vraie photo et les conditions du moment.
- Les cartes rares et légendaires ont un reflet qui suit l'inclinaison de ton iPhone.
- Toutes les espèces pêchables en France, en images, avec ton compteur pour ta zone.
- Au premier lancement, glisse les espèces que tu as déjà pêchées : elles entrent au Pescedex comme cartes déclarées, à part de tes vraies prises.
- Rentré bredouille ? Tu reçois quand même ta carte de sortie.
- Partage une image de ta carte : jamais ton coin exact.

AMIS
- Invite un ami depuis « Mes amis » : il voit ta collection en lecture seule, et tu vois la sienne s'il t'invite aussi. Seules les personnes invitées y ont accès, jamais le public.
- Le lieu d'une carte s'arrête au département. Tu peux supprimer tes cartes partagées et signaler une carte.
- Pas de compte FishMe : les amis passent par ton compte iCloud.

ÉCRAN VERROUILLÉ ET WIDGET
- Pendant ta session, l'écran verrouillé et la Dynamic Island affichent le compte à rebours jusqu'à la fin légale et ton nombre de prises, sans nom de coin.
- Le widget « Mon aquarium » fait nager les poissons de ton Pescedex sur ton écran d'accueil.

GRATUIT POUR TOUJOURS
La carte, les règles et ton Pescedex. Un spot gratuit (un cercle de 1 km) avec des sessions illimitées, et sur ce spot la météo du jour et le niveau de l'eau. Le premier conseil de chaque espèce. Les alertes orage et crue, partout. Les amis, la session sur l'écran verrouillé et le petit widget.

FISHME PRO
Des sessions sur d'autres spots, la météo sur 7 jours heure par heure, la courbe de la rivière sur 48 h, « Préviens-moi », tous les conseils de chaque espèce et « Tes conditions » après 10 sorties. Les grands widgets.
L'abonnement se renouvelle automatiquement, sauf résiliation au moins 24 heures avant la fin de la période, dans les réglages de ton compte Apple. Tu peux restaurer tes achats dans l'app.

RESPECTUEUX
- Aucun compte FishMe, aucune publicité. Tes coins de pêche exacts ne quittent jamais ton iPhone, et tes photos sont enregistrées sans position GPS.
- L'IA ne décide jamais si un poisson peut être gardé : elle propose l'espèce, tu confirmes, la règle sourcée s'affiche.

IMPORTANT
Les règles affichées sont indicatives : l'arrêté préfectoral fait foi. Vérifie aussi les panneaux sur place. En cas de doute, relâche.

Données : OFB et Hub'Eau (Licence Ouverte 2.0). Météo : Apple Weather.
Conditions d'utilisation : [URL_CONDITIONS]
Confidentialité : [URL_CONFIDENTIALITE]
```

### Qui prouve quoi (chaque phrase contre le plan ; à revoir sur le build TestFlight de la porte 3)

Une phrase dont la fonction n'est pas à l'écran à la porte 3 sort de la description, des notes et des captures (R7). Rien n'est écrit au futur.

| Phrase de la description | Source dans le plan | État |
|---|---|---|
| Poissons relevés par l'OFB, « N pêches, dernier relevé AAAA » | E1, `CLAUDE.md` | à voir à l'écran [?] |
| Conditions du moment et jauge de la rivière dans la fiche d'un coin | E2, L12 | à voir [?] ; gratuit sur son spot seulement |
| Règles du jour, source et citation d'un toucher | E2 | à voir [?] |
| Règles locales de `[COUVERTURE]` | `departementsCouverts()` de `Core` ; IDF (75, 92, 93, 94, 77) par D1, le reste par D3 | **liste à lire dans le build**, jamais « toute la France » si le build ne la couvre pas [?] |
| Vigilance orage ou crue en haut de la carte | E1, L12 | à voir [?] |
| Session : chrono, fin légale, prises, carte « à essayer » | E4, D4 | à voir [?] |
| 3 espèces en images, « Autre » sur les espèces de France, « Pas un poisson », sans pourcentage | E5, `CLAUDE.md` (17h) | à voir [?] ; marche aussi avec la seule grille si le modèle ne passe pas l'examen |
| Toise lue, taille confirmée, poids estimé marqué comme tel | E5, `CLAUDE.md` (17h) | à voir [?] |
| Carte : recto poisson, rareté à 4 niveaux, taille ; dos photo et conditions | E6 | à voir [?] |
| Reflet sur les cartes rares et légendaires seulement | `CLAUDE.md` (13h52), L4 | à voir [?] |
| Toutes les espèces pêchables en images, compteur par zone | E6, `CLAUDE.md` | à voir [?] ; « zone » reste vague tant que sa forme n'est pas tranchée |
| Cartes déclarées au premier lancement | `CLAUDE.md` (tunnel de 16h), L13 | **ajout du 15 oct. 16h, pas encore dans `parcours-demo.md`** : à voir [?] |
| Carte de sortie quand on rentre bredouille | E9 | à voir [?] |
| Partage d'une image sans le coin exact | E8 | à voir [?] |
| Gratuit et Pro | `TextesPaywall.swift:56-71` (`gratuit`, `pro`), `mac/integration`, même découpage que la description | identiques au paywall écrit ; **le paywall ne cite ni Amis ni les widgets** (voir remarque ci-dessous) ; à voir sur l'iPhone [?] |
| Amis : bouton « Mes amis » dans Mon club | `RootView.swift:619-636` | code présent, aucun test de Pro autour (`git grep` Pro/abonne dans `App/Amis` : rien) ; à voir [?] |
| Invitation, ami en lecture seule, personnes invitées seulement | `AmisView.swift:13-14` (`.readOnly`, `.specifiedRecipientsOnly`), `:133` (« Inviter un ami »), `:142-147` (« Inviter en retour »), `ServiceAmisCloudKit.swift:13,21,69` (zone `Pescedex` de la base privée, une seule `CKShare`) | à voir à deux iPhone, deux comptes iCloud [?] |
| Jamais en public ; lieu limité au département ; image sans GPS | `ServiceAmisCloudKit.swift:21-22` (bases privée et partagée seulement, aucun `publicCloudDatabase` dans `App/`), `ConstructeurCartes.swift:20,23-26`, `PngSansGPS.swift`, `AmisView.swift:51` | exact selon le code [?] |
| Supprimer ses cartes partagées, signaler une carte | `AmisView.swift:204-212`, `PescedexAmiView.swift:70,107,160`, `Signalement.swift` | à voir [?] |
| Pas de compte FishMe, iCloud | `Config/BuildChallenge.entitlements:5-12` (conteneur CloudKit), `AmisView.swift:86` (message si iCloud absent), `Config/BuildChallenge-Info.plist:22` (`CKSharingSupported`) | la capacité iCloud doit être cochée sur l'identifiant MWM (Adem) [?] |
| Écran verrouillé et Dynamic Island : compte à rebours jusqu'à la fin légale, nombre de prises, sans nom de coin | `SessionLiveActivity.swift:61-107`, `EtatSession.swift:11-22,37-42`, démarrage `RootView.swift:338`, reprise `:161`, prise `:386`, fin `:352`, `project.pbxproj:550,585` (`NSSupportsLiveActivities`) | à voir sur un iPhone avec Live Activities actives [?] ; aucune erreur si elles sont coupées (`PilotageActivite.swift:19`) |
| Widget « Mon aquarium » : poissons du Pescedex sur l'écran d'accueil et l'écran verrouillé | `AquariumWidget.swift:36-45` (familles), `FishMeWidgetBundle.swift:8-9`, publication `RootView.swift:218-237` | à voir [?] ; état vide (pas de faux poisson) tant que le Pescedex est vide |
| Widget aquarium : petit gratuit, moyen/grand/très grand Pro | `VuesAquariumWidget.swift:301-308` (`systemSmall` libre ; défaut verrouillé sans `estPro`), `RootView.swift:244` (lien `pro?source=widget` ouvre le paywall) | à voir [?] |
| Renouvellement automatique, restauration | `TextesPaywall.renouvellement`, règle 3.1.2 | à voir [?] |
| Aucun compte, aucune publicité ; coins exacts et GPS des photos | E1, `CLAUDE.md` | exact selon le plan ; on n'écrit pas « sans mesure » (Spark Flash) |
| Météo : Apple Weather | obligation de WeatherKit (R6) | seulement si la météo est dans le build |

Ce qui n'est pas écrit, exprès : aucun prix (option B de `a-trancher.md`, point 2), aucun nombre d'espèces reconnues, ni coins publics, ni tronçons (mise à jour), ni aquarium dans l'app (le bouton « Voir mon aquarium » est absent du code : `RootView.swift:239` note « L14 absent » et le lien du widget ouvre le Pescedex), ni widget « Ma carte » (sur `lot/widget-aquarium` seulement, absent de `mac/integration`, `FishMeWidgetBundle.swift` n'a que la session et l'aquarium), ni cartes de bredouille dans les amis (`ConstructeurCartes.swift:26`, `bredouille: false`).

### Remarques pour Adem (16 oct.)
- **Gratuit / Pro** : `TextesPaywall.gratuit` et `.pro` ne nomment ni Amis ni les widgets. Le code ne met Amis derrière aucun Pro ; le widget aquarium est gratuit en petit et sur l'écran verrouillé, Pro en moyen, grand et très grand (`VuesAquariumWidget.swift:291-308`) ; la Live Activity n'est pas limitée. La description l'écrit tel quel. Si la décision est autre, il faut changer le code ET les trois lignes « GRATUIT POUR TOUJOURS » / « FISHME PRO » ; et le paywall devrait citer les grands widgets, sinon un relecteur trouve une fonction Pro non annoncée.
- **Couverture** : `[COUVERTURE]` reste à remplir par la liste que le build donne. Le tableau de bord du 16 oct. compte 96 départements chargés (19 402 règles confirmées, 9 107 « vérifie l'arrêté », 10 départements sous 50 % confirmé) : cela ne permet pas d'écrire « toute la France ».
- **Photo d'exemple** (brochet, SpinfisherCRO, CC BY-SA 4.0) : le crédit est dans l'app (Mon club, sources, branche `finir-app`) mais **pas ajouté à la ligne « Données »**, car aucune capture n'existe encore. Si une capture montre la photo (étape 4 du parcours), ajouter « Photo d'exemple : SpinfisherCRO, CC BY-SA » à la ligne Données (≈ 50 car. de plus, la description a 48 car. de marge) ou retirer la photo de la capture.
- **Mots-clés** : inchangés (voir « Choix de mots-clés »).
- **Fonction à cocher** : Amis marche seulement avec deux comptes iCloud réels et les capacités iCloud, App Group et WeatherKit cochées sur l'identifiant MWM (tableau de bord, « Bloquant pour Apple »). Si l'un manque à la porte 3, la section AMIS sort de la description.

## Mots à ne pas écrire
La liste est dans `docs/banc/mots-interdits.md` (non recopiée ici pour que les `grep` du test 5 de `fiches/S1.md` restent vides sur `store/`). Rappels : aucune marque de Nintendo, aucun verdict « tu peux la garder », aucun pourcentage de l'IA, aucune promesse de prise ni de « bon spot », aucune note chiffrée de la pêche ni heure miracle, pas de nombre d'espèces figé, pas de « toute la France » tant que le build ne la couvre pas, pas d'essai d'un mois ; ni coins publics, ni aquarium dans l'app, ni widget « Ma carte », ni collections visibles en public (hors du build soumis) ; amis, écran verrouillé et widget aquarium sont dans le build et peuvent s'écrire, dans les limites du tableau ci-dessus ; rien qui vise les enfants.
