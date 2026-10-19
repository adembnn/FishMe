# Fiche App Store de FishMe (S1)

> **S2, 19 oct. 2026 :** pour la version qui porte le réseau social, voir `fiche-reseau.md` (description, nouveautés). « Aucun compte » et « ni amis, ni coins publics » ne valent plus pour cette version.

Brouillon avancé par Sullyvan (15 oct. 2026), repris sur `lot/store` par A (Claude) le 15 oct. en fin d'après-midi : description alignée sur `parcours-demo.md` (E1 à E9), sur les décisions d'Adem de 16h et 17h (premier lancement à glisser, 3 propositions plus « Autre », toise et poids estimé) et sur les listes Gratuit / Pro du paywall de L6 (`TextesPaywall.gratuit` et `.pro`, branche `lot/abonnement`).

Écrite en avance sur le lot S1 (tenu par Adem), à partir de `CLAUDE.md`, `docs/fiches/S1.md`, `docs/app-store.md` et de la relecture de Sullyvan (`origin/sullyvan/relecture-s1`), qui remplace la fiche « Bredouille » de Titouan. Longueurs comptées par Python (`len()` en caractères, `len(.encode("utf-8"))` en octets), espaces compris.

Légende : **[?]** = non confirmé, à lire dans le build ou à demander. **À TRANCHER** : voir `a-trancher.md`, où chaque point porte maintenant le choix par défaut de A, à confirmer par Adem. Les crochets `[...]` du texte sont à remplir avant l'envoi ; aucun n'est inventé.

Outils MWM passés le 15 oct. vers 18h30 (heure de Paris), détail dans `mwm-resultats.md` : limites relues par `get_store_text_rules` (version 2026-10, identiques aux comptes ci-dessous ; les mots-clés se comptent en **caractères**, 100 au plus, pas en octets) ; mots-clés refaits avec `search_market_apps` et `analyze_market_keywords` (boutique française, iPhone) ; `review_store_text` ne relève aucun problème sur les six champs.

## Champs

| Champ | Valeur | Longueur |
|---|---|---|
| Nom | `FishMe` | 6 car., 6 octets (limite 30 car.) |
| Sous-titre | `Poissons, règles et Pescedex` | 28 car., 29 octets (limite 30 car.) |
| Catégorie principale | Sports (secondaire : Mode de vie) | par défaut de `fiches/S1.md`, à confirmer par Adem [?] |
| Mots-clés | `pêche,fishing,brochet,carpe,truite,sandre,perche,rivière,étang,lac,spot,carnet,réglementation` | 93 car. (limite 100 car.) |
| Texte promo | voir ci-dessous | 165 car., 167 octets (limite 170 car.) |
| Nouveautés | voir ci-dessous | 174 car., 181 octets (limite 4000 car.) |
| Description | voir ci-dessous | 3231 car., 3324 octets (limite 4000 car.) |
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
- Aucun mot ne dit « météo », « conseils » ou « alertes » : ils n'entrent dans les mots-clés qu'après la porte 3, si le build les a.
- Liste de repli si un mot est refusé ou peu demandé : `écrevisse`, `black-bass`, `silure`, `truite fario` (ajouter seulement ce que les 100 octets permettent, recompter).

### Nom et sous-titre
- Nom `FishMe` : décidé par Adem le 15 oct. à 12h36. « Pescedex » n'est jamais le nom de l'app.
- Sous-titre proposé `Poissons, règles et Pescedex` : dit les trois piliers (poissons relevés, règles sourcées, collection). Remplace « Une carte par sortie de pêche » (ancien produit). Alternatives (aussi comptées) : `Où pêcher et quoi y prendre` (27 car.), `Pêche : spots, règles, cartes` (29 car.). La première suggère une promesse de prise, la seconde confond avec la carte de pêche : recommandation, garder le sous-titre proposé. Choix final à Sullyvan ou Adem.

### Texte promo (165 car.)
```
Photographie ta prise : l'app propose l'espèce, tu confirmes, et ta carte rejoint le Pescedex. La carte, les règles et ta collection restent gratuites pour toujours.
```

### Nouveautés (174 car.)
```
Première version de FishMe : la carte des poissons relevés par l'OFB, les règles sourcées, la session de pêche, la météo de ton spot et tes prises en cartes dans le Pescedex.
```

## Description (3231 car., 3324 octets, sous 4000)

Chaque ligne doit correspondre à un écran vu sur l'iPhone dans le build TestFlight (test 2 de `fiches/S1.md`) : sinon on la retire (refus R7). Il reste un seul trou dans le texte, `[COUVERTURE]` (départements lus dans le build), plus les deux URL. La phrase « l'app reconnaît N espèces » n'est pas écrite : elle ne s'ajoute que si N est lu dans le modèle livré par R1 (77 visées, repli sur 6).

```
FishMe est l'app de pêche en eau douce qui te montre où pêcher, quels poissons y vivent et quelles règles s'y appliquent, puis transforme chacune de tes prises en carte à collectionner.

LA CARTE
- Autour de toi, les poissons relevés par l'Office français de la biodiversité (OFB), en images, avec le nombre de pêches et l'année du dernier relevé.
- Touche un coin : ses espèces et leur rareté dans le département, les conditions du moment (vent, pluie, pression, aube, crépuscule) et la jauge de la rivière.
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

GRATUIT POUR TOUJOURS
La carte, les règles et ton Pescedex. Un spot gratuit (un cercle de 1 km) avec des sessions illimitées, et sur ce spot la météo du jour et le niveau de l'eau. Le premier conseil de chaque espèce. Les alertes orage et crue, partout.

FISHME PRO
Des sessions sur d'autres spots, la météo sur 7 jours heure par heure, la courbe de la rivière sur 48 h, « Préviens-moi », tous les conseils de chaque espèce et « Tes conditions » après 10 sorties.
L'abonnement se renouvelle automatiquement, sauf résiliation au moins 24 heures avant la fin de la période, dans les réglages de ton compte Apple. Tu peux restaurer tes achats dans l'app.

RESPECTUEUX
- Aucun compte, aucune publicité. Tes coins de pêche exacts ne quittent jamais ton iPhone, et tes photos sont enregistrées sans position GPS.
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
| Gratuit et Pro | listes `TextesPaywall.gratuit` et `.pro` de `lot/abonnement` (même découpage), E2, E7 | identiques au paywall écrit ; à voir sur l'iPhone [?] |
| Renouvellement automatique, restauration | `TextesPaywall.renouvellement`, règle 3.1.2 | à voir [?] |
| Aucun compte, aucune publicité ; coins exacts et GPS des photos | E1, `CLAUDE.md` | exact selon le plan ; on n'écrit pas « sans mesure » (Spark Flash) |
| Météo : Apple Weather | obligation de WeatherKit (R6) | seulement si la météo est dans le build |

Ce qui n'est pas écrit, exprès : aucun prix (option B de `a-trancher.md`, point 2), aucun nombre d'espèces reconnues, ni amis, ni aquarium, ni écran verrouillé, ni coins publics, ni tronçons (mise à jour).

## Mots à ne pas écrire
La liste est dans `docs/banc/mots-interdits.md` (non recopiée ici pour que les `grep` du test 5 de `fiches/S1.md` restent vides sur `store/`). Rappels : aucune marque de Nintendo, aucun verdict « tu peux la garder », aucun pourcentage de l'IA, aucune promesse de prise ni de « bon spot », aucune note chiffrée de la pêche ni heure miracle, pas de nombre d'espèces figé, pas de « toute la France » tant que le build ne la couvre pas, pas d'essai d'un mois ; ni amis, ni aquarium, ni écran verrouillé, ni coins publics (hors du build soumis) ; rien qui vise les enfants.
