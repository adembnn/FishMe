# Relecture S1 : fiche App Store de Titouan

Relecteur : Sullyvan (lot S1, rôle « relecture »). Préparée le 15 oct. 2026.
Fiche relue : `harnais-titouan/docs/store/fiche-console-mwm.md` sur `origin/titouan/harnais-bredouille`, commits `ee6d5f5` (« Fiche App Store prete a coller dans la console MWM (8 champs, textes comptes) », 15 oct. 10h59) et `4d5860f` (décision Q24 sur Pro, 15 oct. 11h14). Lu aussi pour comparer : `metadata-fr.md` et `review-notes.md` du même dossier.
Référence : `CLAUDE.md`, `docs/fiches/S1.md`, `docs/app-store.md`, `docs/banc/mots-interdits.md`, `docs/parcours-demo.md`.
Aucun dossier `store/` n'existe sur les branches distantes (`claude/project-thread-78e20q`, `claude/push-docs-projet-t0aglk`, `lot/atelier`, `lot/donnees`, `lot/squelette`, `titouan/harnais-bredouille`) : la fiche relue est la seule version écrite.
Longueurs comptées par Python (`len()` en caractères Unicode, `len(encode("utf-8"))` en octets), espaces compris.

## Constat général (à lire d'abord)

La fiche a été écrite le 15 oct. à 10h59, avant les décisions d'Adem de 11h13 à 13h55. Elle décrit **l'ancien produit « Bredouille »** (photo, carte, collection, hors ligne, sans règles), pas FishMe. Elle n'est **pas utilisable telle quelle** : il faut la réécrire sur le produit actuel, pas la corriger à la marge. Les champs mécaniques (catégorie, liens à compléter, contact) restent bons.

Gravité : **Bloquant** = refus d'Apple probable ou contraire à une décision d'Adem ; **Majeur** = promesse fausse ou invérifiable ; **Mineur** = forme, à corriger avant envoi.

## 1. Champ par champ : longueur réelle contre la limite d'Apple

| Champ | Valeur dans la fiche | Longueur réelle | Limite Apple | Verdict |
|---|---|---|---|---|
| Nom | `Bredouille` | 10 car. | 30 car. | Longueur OK, **nom faux** (point B1) |
| Sous-titre | `Une carte par sortie de pêche` | 29 car. (30 octets) | 30 car. | Longueur OK, contenu à revoir (point M5) |
| Mots-clés | `pêche,poisson,carte,collection,rivière,brochet,carpe,truite,sandre,eau douce,sortie,espèces,pêcheur` | 99 car., **103 octets** | **100 octets** (`fiches/S1.md`) | **Dépasse** : la fiche a compté des caractères, pas des octets (les 4 accents comptent double) (point B6) |
| Description | voir la fiche, §3 | 1 840 car. (1 897 octets) | 4 000 car. | Longueur OK, contenu faux (points B1 à B5, M1 à M4) |
| Texte promo | **absent** | 0 | 170 car. | Manque (point M7) ; `fiches/S1.md` le demande |
| Nouveautés | **absent** | 0 | 4 000 car. | Manque (point m3) |
| Copyright | `© 2026 [NOM_DE_L'ÉDITEUR]` | 25 car. (avec le trou) | sans limite utile | Trou à remplir par MWM, correct de ne rien inventer |
| Catégorie | Sports (principale), Mode de vie (secondaire) | sans objet | sans objet | Conforme au défaut de `fiches/S1.md` (« Sports », à confirmer par Adem) ; `metadata-fr.md` dit l'inverse (Style de vie d'abord) : à aligner (point m2) |
| URL d'assistance | `[URL_ASSISTANCE]` | trou | obligatoire | Correct : l'URL vient d'Adem, jamais inventée |
| URL de confidentialité | `[URL_POLITIQUE]` | trou | obligatoire | Correct sur le principe ; réponses au questionnaire fausses (point B7) |
| Captures 6,9 pouces | ordre proposé, 5 écrans | sans objet | sans objet | Écrans de l'ancien produit (point M6) |
| Contact de revue | trous | sans objet | obligatoire | Correct, rien d'inventé |

## 2. Écarts avec CLAUDE.md, mots interdits et promesses fausses

### Bloquants

**B1. Le nom n'est pas FishMe.**
Constat : « Bredouille » partout (nom, première phrase, « BREDOUILLE PRO », réservation INPI). `CLAUDE.md` : « Nom de l'app : FishMe (Adem, 15 oct. 12h36) » ; `fiches/S1.md` interdit « Bredouille » comme nom.
Correction : nom `FishMe` (6 car.) ; remplacer chaque « Bredouille » par « FishMe » et « BREDOUILLE PRO » par « FISHME PRO ». « Bredouille » ne reste qu'au sens de « rentrer bredouille ».

**B2. La fiche dit que l'app ne connaît pas les règles, alors que les règles sont le cœur de FishMe.**
Constat : « Cette application ne connaît pas les règles de pêche locales et ne dit jamais si une prise est légale. Consulte la fédération de pêche de ton département. » `CLAUDE.md` et `parcours-demo.md` (E2) : règles du jour en liste de contrôle, socle national partout plus les départements couverts, chaque règle avec sa source et sa citation. `fiches/S1.md` exige que la description dise la couverture réelle lue dans `regles.json` et que « l'information est indicative et l'arrêté fait foi ».
Correction : « Règles couvertes : le socle national partout, et les règles locales de [DÉPARTEMENTS DU BUILD]. Ailleurs, l'app le dit et donne le lien de la préfecture. » puis « Les règles affichées sont indicatives : l'arrêté préfectoral fait foi. » Liste des départements à lire dans `departementsCouverts()` du build final, jamais « toute la France » si le build ne la couvre pas (R7).

**B3. « Tout fonctionne sans réseau » est faux.**
Constat : ligne « Tout fonctionne sans réseau, et tes cartes restent sur ton iPhone ». `parcours-demo.md` : « La carte de E1 peut demander du réseau » ; la météo (WeatherKit) et le niveau des rivières (Hub'Eau) sont en ligne par nature.
Correction : supprimer « Tout fonctionne sans réseau ». Si on veut garder l'argument, écrire seulement ce qui est vrai : « Les règles, la session et tes cartes marchent sans réseau. » (E2, E4, E5, E6, E9), à vérifier sur l'iPhone en mode avion.

**B4. Le modèle gratuit / Pro décrit n'est pas celui d'Adem.**
Constat : « Les premières cartes sont offertes. Un abonnement facultatif débloque la suite. » (grille « 15 cartes », décision Q10 de Titouan) et Pro selon Q24 (bestiaire de tous les départements, finitions, bilan, iCloud, mode Préparer). `CLAUDE.md` : gratuit = un spot (cercle de 1 km) avec sessions illimitées ; la carte, les règles et le Pescedex en lecture gratuits pour toujours ; Pro = autres spots (tronçons), météo du jour et 7 jours, niveau de la rivière, alertes orage et crue, historique des conditions, conseils de pêche. Toute prise confirmée entre au Pescedex : aucune limite de cartes.
Correction : paragraphe « CE QUI EST GRATUIT POUR TOUJOURS : la carte, les règles et ton Pescedex. Tu choisis aussi un spot gratuit (un cercle de 1 km) où tes sessions sont illimitées. » et « FISHME PRO : d'autres spots, la météo du jour et sur 7 jours, le niveau de la rivière, les alertes orage et crue, l'historique des conditions de tes sorties et des conseils de pêche pour chaque espèce. » Chaque élément seulement s'il est à l'écran dans le build TestFlight. **Q24 ne vaut pas pour FishMe** : c'est une décision de Titouan sur l'ancien produit, contredite par `CLAUDE.md` ; aucun de ses cinq leviers n'est à écrire (point à trancher 1).

**B5. Le tarif fondateur et ses mentions manquent.**
Constat : aucun prix, aucune durée, aucune mention de l'essai. `CLAUDE.md` : annuel 34,99 annoncé comme prix de lancement jusqu'au 31 décembre 2026 (puis 49,99 pour les nouveaux abonnés), mensuel avec 1 semaine d'essai, annuel sans essai. `fiches/S1.md` : le tarif n'est écrit que s'il est identique au paywall de L6. À noter : `metadata-fr.md` (même dossier) donne 24,99 €/an avec 7 jours d'essai et 3,99 €/mois, des prix qui n'existent pas dans le kit MWM : ce fichier ne doit servir à rien.
Correction : ligne prête, à coller seulement après avoir vu le paywall : « Abonnement annuel au tarif fondateur de 34,99 € jusqu'au 31 décembre 2026 ; abonnement mensuel à [PRIX] € avec 1 semaine d'essai. » Prix en euros lus dans la colonne France d'App Store Connect. Ne pas écrire « 49,99 à partir du 1er janvier » tant que ce produit n'est pas joint (il l'est en décembre) ; le paywall, lui, le montre (R4).

**B6. Les mots-clés dépassent 100 octets.**
Constat : 103 octets (99 caractères). La fiche dit « limite 100 » en comptant des caractères. De plus « carte » (le permis de pêche s'appelle aussi « carte de pêche », confusion déjà notée par Titouan dans `metadata-fr.md`), « sortie » et « pêcheur » ne servent guère.
Correction proposée : `pêche,poisson,brochet,carpe,truite,sandre,perche,rivière,spot,règlement,carnet,collection,lac` (93 car., 96 octets). Aucun nom d'app, aucune marque. `fiches/S1.md` veut des mots-clés tirés de `search_market_apps` et `analyze_market_keywords` : cette liste reste une proposition tant que ces chiffres ne sont pas lus, et `review_store_text` fait le compte final.

**B7. Réponses au questionnaire de confidentialité contraires au produit.**
Constat : « localisation approximative facultative ». `parcours-demo.md` (E1) : la position précise est demandée au lancement (elle sert sur l'iPhone, aucun coin exact n'en sort). `fiches/S1.md` exige 5 clauses : position précise sur l'iPhone seulement, photos sans GPS, Spark Flash nommé et non lié à l'identité, collections montrées aux amis invités seulement, France et UE. La fiche donne bien les 7 types de Spark Flash, mais oublie la « localisation approximative » tirée de l'adresse IP à déclarer si MWM la confirme (`app-store.md` ligne 6). Par ailleurs `review-notes.md` du même dossier affirme « no third-party SDK, no analytics » : faux avec Spark Flash, refus probable (5.1.1, R9).
Correction : réponses à refaire sur les 5 clauses de `fiches/S1.md` ; ajouter « localisation approximative (Spark Flash, adresse IP) » si MWM la confirme ; les notes pour le relecteur sont à réécrire entièrement (hors champ de cette relecture, à signaler à C).

### Majeurs (promesses fausses ou invérifiables)

**M1. « Aucun compte, aucune publicité » : vrai, mais « sans suivi » n'est vrai que si le consentement de L6 est en place.** Le paragraphe peut rester (« Aucun compte, aucune publicité. »). Ne pas écrire « aucun outil de mesure » (Spark Flash collecte des interactions).

**M2. Fonctions absentes du build vendues comme présentes.** « bestiaire de ton département », « mode débutant pour savoir quelles espèces rencontrer ce mois-ci », carte « Eau calme » : ce ne sont pas les écrans de FishMe. La carte bredouille existe (E9) mais s'appelle « carte de sortie » / « carte bredouille ». Le mode débutant ressemble aux conseils de pêche, qui sont dans Pro. Correction : « Rentré bredouille ? Tu reçois quand même ta carte de sortie. » ; supprimer bestiaire et mode débutant.

**M3. La fiche ne dit rien de ce qui fait FishMe** : la carte des poissons relevés par l'OFB avec « N pêches, dernier relevé AAAA », la session (chrono, fin légale), les 4 raretés, le Pescedex. Correction : sections « LA CARTE », « LA SESSION », « LE PESCEDEX » de la proposition du §3.

**M4. « Une rareté par espèce, calculée d'après les relevés… de l'OFB »** : juste sur le fond, mais `CLAUDE.md` veut que tout chiffre OFB porte son nombre de pêches et son année ; la fiche n'a pas de chiffre, donc pas d'écart, mais ne pas en ajouter un sans N et l'année. La phrase « Elle ne mesure pas ce que les pêcheurs prennent » est bonne, à garder.

**M5. Sous-titre « Une carte par sortie de pêche »** : promet l'ancien concept et le mot « carte » prête à confusion avec la carte (le volet central) et la carte de pêche. Proposition : `Où pêcher et quoi y prendre` (27 car.) ou `Pêche : spots, règles, cartes` (29 car.). Attention : « spot » ne doit pas suggérer un « bon spot » (`CLAUDE.md`).

**M6. Captures prévues sur des écrans qui n'existent plus** (carte « Eau calme », bestiaire). Ordre proposé, à prendre sur le build en Release (B) : 1. la carte avec les poissons en images et « N pêches, AAAA » ; 2. la fiche d'un coin et ses règles avec source ; 3. la session (chrono, fin légale) ; 4. les espèces proposées, sans pourcentage ; 5. la carte révélée (recto, puis verso avec la photo) ; 6. le Pescedex. Ne pas montrer le reflet holographique sur une carte commune, ni « Pokédex », ni un cadre jaune.

**M7. Texte promo absent.** Proposition (165 car., 167 octets) : « Photographie ta prise : l'app propose l'espèce, tu confirmes, et ta carte rejoint le Pescedex. La carte, les règles et ta collection restent gratuites pour toujours. »

### Mineurs

**m1. Liens conditions et confidentialité absents de la description** (`app-store.md` ligne 2, règle 3.1.2). Ajouter en fin de description `Conditions d'utilisation : [URL_CONDITIONS]` et `Confidentialité : [URL_CONFIDENTIALITE]`.

**m2. Catégorie** : la fiche dit Sports d'abord, `metadata-fr.md` dit Style de vie d'abord. Garder Sports (défaut de `fiches/S1.md`), à confirmer par Adem.

**m3. Nouveautés absentes.** Proposition (152 car.) : « Première version de FishMe : la carte des poissons relevés par l'OFB, les règles sourcées, la session de pêche et tes prises en cartes dans le Pescedex. »

**m4. Sources** : « Données de rareté : OFB, Hub'Eau, Licence Ouverte 2.0. » à étendre, car la météo de WeatherKit impose la marque : « Données : OFB, Hub'Eau (Licence Ouverte 2.0). Météo : Apple Weather. »

**m5. « Pescedex »** n'apparaît pas dans la fiche : pas d'écart, mais il peut y entrer comme nom de la collection (jamais comme nom de l'app).

### Ce qui est conforme (rien à corriger)

- Aucune occurrence de « Poké », « Pokémon », « Pokédex » dans les textes à coller (la fiche ne les cite que dans ses consignes).
- Aucun « bientôt », « prochainement », « viendra ».
- Aucun mot de `docs/banc/mots-interdits.md` : ni pourcentage de l'IA, ni « 100 % fiable », ni « meilleur coin », « meilleures chances », « garanti », ni « probabilité de capture », ni « tu as le droit de garder » / « tu peux la garder », ni 373 891, 1,39 million, 22,5 %.
- « L'app propose, tu confirmes » et « En cas de doute, relâche » : conformes à la règle « l'IA propose, l'humain confirme, la table décide ».
- Aucun contact, aucune URL, aucun éditeur inventés : les trous sont signalés.
- Aucun mot de passe dans la fiche.
- Mention du renouvellement automatique et de la restauration des achats : à garder.

## 3. Description corrigée proposée (2 471 car., 2 540 octets, sous 4 000)

Les crochets sont à remplir depuis le build ; chaque ligne doit correspondre à un écran vu sur l'iPhone (`fiches/S1.md`, test 2), sinon on la retire. Passer le texte final par `review_store_text`.

```
FishMe est l'app de pêche en eau douce qui te montre où pêcher, quels poissons y vivent et quelles règles s'y appliquent, puis transforme chacune de tes prises en carte à collectionner.

LA CARTE
- Autour de toi, les poissons relevés par l'Office français de la biodiversité (OFB), en images, avec le nombre de pêches et l'année du dernier relevé.
- Touche un coin : ses espèces, leur rareté dans le département et les règles du jour en lignes courtes (taille, quota, ouverture). La source et la citation de chaque règle s'ouvrent d'un toucher.
- Règles couvertes : le socle national partout, et les règles locales de [DÉPARTEMENTS DU BUILD]. Ailleurs, l'app le dit et donne le lien de la préfecture.

LA SESSION
- Lance une session : chrono, heure de fin légale, tes prises du jour.
- Photographie ta prise : l'app propose des espèces, sans aucun pourcentage, et c'est toi qui confirmes. « Pas un poisson » et « je ne sais pas » sont toujours là.

LE PESCEDEX
- Chaque prise confirmée devient une carte : au recto le poisson et sa rareté (commun, peu commun, rare, légendaire), au dos ta vraie photo.
- Rentré bredouille ? Tu reçois quand même ta carte de sortie.
- Partage une image de ta carte : jamais ton coin exact.

CE QUI EST GRATUIT POUR TOUJOURS
La carte, les règles et ton Pescedex. Tu choisis aussi un spot gratuit (un cercle de 1 km) où tes sessions sont illimitées.

FISHME PRO
D'autres spots, la météo du jour et sur 7 jours, le niveau de la rivière, les alertes orage et crue, l'historique des conditions de tes sorties et des conseils de pêche pour chaque espèce.
[LIGNE PRIX, seulement si identique au paywall : abonnement annuel au tarif fondateur de 34,99 € jusqu'au 31 décembre 2026 ; abonnement mensuel à [PRIX] € avec 1 semaine d'essai.]
L'abonnement se renouvelle automatiquement sauf résiliation au moins 24 heures avant la fin de la période, dans les réglages de ton compte Apple.

RESPECTUEUX
- Aucun compte, aucune publicité. Tes cartes et tes coins restent sur ton iPhone ; tes photos sont enregistrées sans position GPS.
- L'IA ne décide jamais si un poisson peut être gardé : elle propose l'espèce, tu confirmes, la règle sourcée s'affiche.

IMPORTANT
Les règles affichées sont indicatives : l'arrêté préfectoral fait foi. Vérifie aussi les panneaux sur place. En cas de doute, relâche.

Données : OFB, Hub'Eau (Licence Ouverte 2.0). Météo : Apple Weather.
Conditions d'utilisation : [URL_CONDITIONS]
Confidentialité : [URL_CONFIDENTIALITE]
```

Récapitulatif des champs proposés :

| Champ | Proposition | Longueur | Limite |
|---|---|---|---|
| Nom | `FishMe` | 6 car. | 30 |
| Sous-titre | `Où pêcher et quoi y prendre` | 27 car. | 30 |
| Mots-clés | `pêche,poisson,brochet,carpe,truite,sandre,perche,rivière,spot,règlement,carnet,collection,lac` | 96 octets | 100 octets |
| Texte promo | voir M7 | 165 car. | 170 |
| Description | ci-dessus | 2 471 car. | 4 000 |
| Nouveautés | voir m3 | 152 car. | 4 000 |
| Catégorie | Sports (secondaire : Mode de vie) | | |
| Copyright | `© 2026 [ÉDITEUR, donné par MWM]` | | |

## 4. Points que Sullyvan doit trancher lui-même

1. **Q24 de Titouan contre `CLAUDE.md`** : la relecture écarte entièrement Q24 (cinq leviers Pro, grille « 15 cartes ») au profit de la décision d'Adem (spot gratuit, Pro = spots, météo, rivière, alertes, conseils). Confirmer ce choix avec Titouan avant qu'il ne réécrive, ou le faire trancher par Adem si Titouan y tient.
2. **Ligne de prix dans la description** : l'écrire (34,99 € tarif fondateur jusqu'au 31/12/2026 + mensuel avec 1 semaine d'essai) dès que le paywall de L6 est vu sur l'iPhone, ou la laisser hors de la description (le paywall et App Store Connect affichent déjà les prix) pour ne pas risquer un écart. Le mensuel n'est pas encore choisi.
3. **Fonctions Pro citées** : ne garder dans « FISHME PRO » que celles que tu as vues dans le build TestFlight (météo, niveau de la rivière, alertes, historique, conseils sont décidés « tout d'un coup » mais rien ne prouve qu'ils seront finis jeudi soir) ; chaque fonction absente est un refus R7.
