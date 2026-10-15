# Fiche App Store de FishMe (S1, brouillon avancé par Sullyvan, 15 oct. 2026)

Écrite en avance sur le lot S1 (tenu par Adem), à partir de `CLAUDE.md`, `docs/fiches/S1.md`, `docs/app-store.md` et de la relecture de Sullyvan (`origin/sullyvan/relecture-s1`), qui remplace la fiche « Bredouille » de Titouan. Longueurs comptées par Python (`len()` en caractères, `len(.encode("utf-8"))` en octets), espaces compris.

Légende : **[?]** = non confirmé, à lire dans le build ou à demander. **À TRANCHER** = décision de Sullyvan, voir `a-trancher.md`. Les crochets `[...]` du texte sont à remplir avant l'envoi ; aucun n'est inventé.

Ce qui n'a pas pu être fait ici : `review_store_text`, `get_store_text_rules`, `search_market_apps` et `analyze_market_keywords` sont des outils du serveur MCP de MWM, non branché dans cette session. Les comptes ci-dessous sont donc faits à la main (Python) et les mots-clés ne sont **pas** tirés des chiffres de la boutique française : à refaire avec ces outils avant l'envoi [?].

## Champs

| Champ | Valeur | Longueur |
|---|---|---|
| Nom | `FishMe` | 6 car., 6 octets (limite 30 car.) |
| Sous-titre | `Poissons, règles et Pescedex` | 28 car., 29 octets (limite 30 car.) |
| Catégorie principale | Sports (secondaire : Mode de vie) | par défaut de `fiches/S1.md`, à confirmer par Adem [?] |
| Mots-clés | `pêche,brochet,carpe,truite,sandre,perche,rivière,étang,lac,spot,carnet,réglementation,taille` | 92 car., 96 octets (limite 100 octets) |
| Texte promo | voir ci-dessous | 165 car., 167 octets (limite 170 car.) |
| Nouveautés | voir ci-dessous | 152 car., 157 octets (limite 4000 car.) |
| Description | voir ci-dessous | 2701 car., 2778 octets (limite 4000 car.) |
| Copyright | `© 2026 [ÉDITEUR, à demander à MWM]` | aucun nom inventé |
| URL d'assistance | `[URL_ASSISTANCE, donnée par Adem]` | jamais inventée |
| URL marketing | page web de l'app (`draft_landing_page`), après l'envoi de la fiche | |
| Contact de revue | `[PRÉNOM NOM]`, `[TÉLÉPHONE joignable vendredi]`, `[EMAIL]` | à donner par Adem |
| Connexion requise | Non (pas de compte, pas de compte démo) | |

### Choix de mots-clés
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

### Nouveautés (152 car.)
```
Première version de FishMe : la carte des poissons relevés par l'OFB, les règles sourcées, la session de pêche et tes prises en cartes dans le Pescedex.
```

## Description (2701 car., 2778 octets, sous 4000)

Chaque ligne doit correspondre à un écran vu sur l'iPhone dans le build TestFlight (test 2 de `fiches/S1.md`) : sinon on la retire (refus R7). Les trois blocs entre crochets dépendent de la porte 3 ou d'une décision : ils sont marqués dans le texte.

```
FishMe est l'app de pêche en eau douce qui te montre où pêcher, quels poissons y vivent et quelles règles s'y appliquent, puis transforme chacune de tes prises en carte à collectionner.

LA CARTE
- Autour de toi, les poissons relevés par l'Office français de la biodiversité (OFB), en images, avec le nombre de pêches et l'année du dernier relevé.
- Touche un coin : ses espèces, leur rareté dans le département et les règles du jour en lignes courtes (taille, quota, ouverture). La source et la citation de chaque règle s'ouvrent d'un toucher.
- Règles couvertes : le socle national partout, et les règles locales de [COUVERTURE : liste des départements lue dans le build]. Ailleurs, l'app le dit et donne le lien de la préfecture.

LA SESSION
- Lance une session : chrono, heure de fin légale, tes prises du jour.
- Photographie ta prise : l'app propose des espèces, sans aucun pourcentage, et c'est toi qui confirmes. « Pas un poisson » et « Autre » sont toujours là. [N : « L'app reconnaît N espèces » seulement si N est lu dans le modèle livré.]

LE PESCEDEX
- Chaque prise confirmée devient une carte : au recto le poisson et sa rareté (commune, peu commune, rare, légendaire), au dos ta vraie photo.
- Rentré bredouille ? Tu reçois quand même ta carte de sortie.
- Partage une image de ta carte : jamais ton coin exact.

GRATUIT POUR TOUJOURS
La carte, les règles et ton Pescedex en lecture. Tu choisis aussi un spot gratuit (un cercle de 1 km) où tes sessions sont illimitées. L'alerte orage et crue reste gratuite.

FISHME PRO
[À TRANCHER : liste des fonctions Pro, voir a-trancher.md, point 3. Proposition, chaque fonction seulement si elle est à l'écran dans le build de la porte 3 :] d'autres spots, la météo du jour et sur 7 jours, le niveau de la rivière, « préviens-moi », l'historique des conditions de tes sorties et des conseils de pêche pour chaque espèce.
[À TRANCHER : ligne de prix, voir a-trancher.md, point 2.]
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

### Qui prouve quoi (lecture de chaque ligne contre les documents du dépôt, pas contre le build)

| Phrase de la description | Source dans le plan | État |
|---|---|---|
| Poissons relevés par l'OFB, « N pêches, dernier relevé AAAA » | `parcours-demo.md` E1, `CLAUDE.md` | à voir à l'écran [?] |
| Règles du jour avec source et citation d'un toucher | E2, `CLAUDE.md` | à voir à l'écran [?] |
| Règles locales de tels départements | `CLAUDE.md` : socle national + 75, 92, 93, 94, 77 saisis ; D3 vise toute la France ; pilotes 01, 87, 44 | **couverture réelle du build inconnue** : lire `departementsCouverts()` / les fichiers chargés par D1 [?] |
| Session : chrono, fin légale, prises | E4 | à voir [?] |
| Photo : propose des espèces sans pourcentage, « Pas un poisson », « Autre » | E5, `CLAUDE.md` (3 meilleures + « Autre ») | à voir [?] |
| « Reconnaît N espèces » | modèle R1 : visé 77 espèces, repli 6 (`CLAUDE.md`, 15 oct. 17h) | N inconnu, ligne retirée tant que N n'est pas lu [?] |
| Carte : recto poisson + rareté à 4 niveaux, dos = vraie photo | `CLAUDE.md` (13h24) | à voir [?] |
| Carte de sortie quand on rentre bredouille | E9 | à voir [?] |
| Partage d'une image sans le coin exact | E8 | à voir [?] |
| Gratuit : carte, règles, Pescedex en lecture, 1 spot (1 km) à sessions illimitées | `CLAUDE.md` (12h26) ; textes de paywall présents sur `origin/lot/abonnement` (non fusionné, non vu sur iPhone) | [?] |
| Alerte orage et crue gratuite | `parcours-demo.md` « règles qui ne bougent pas » | à voir [?] |
| Pro : autres spots, météo 7 jours, niveau de rivière, « préviens-moi », historique, conseils | `CLAUDE.md` (13h21, « tout d'un coup ») | **À confirmer après la porte 3** ; voir `a-trancher.md` point 3 |
| Renouvellement automatique, restauration des achats | règle 3.1.2, `TextesPaywall.renouvellement` | à voir sur le paywall [?] |
| Aucun compte, aucune publicité | E1 (pas de compte) ; Spark Flash mesure des interactions : on ne dit pas « sans mesure » | exact |
| Coins exacts jamais hors de l'iPhone, photos sans GPS | `CLAUDE.md` | exact selon le plan ; à vérifier dans le build [?] |
| Météo : Apple Weather | obligation WeatherKit | seulement si la météo est dans le build |

## Mots à ne pas écrire
La liste est dans `docs/banc/mots-interdits.md` (non recopiée ici pour que les `grep` du test 5 de `fiches/S1.md` restent vides sur `store/`). Rappels : aucune marque de Nintendo, aucun verdict « tu peux la garder », aucun pourcentage de l'IA, aucune promesse de prise ni de « bon spot », aucune note chiffrée de la pêche ni heure miracle, pas de nombre d'espèces figé, pas de « toute la France » tant que le build ne la couvre pas, pas d'essai d'un mois ; ni amis, ni aquarium, ni écran verrouillé, ni coins publics (hors du build soumis) ; rien qui vise les enfants.
