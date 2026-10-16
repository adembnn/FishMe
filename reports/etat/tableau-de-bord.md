# FishMe : tableau de bord (16 oct., ~2h45 UTC)

Branche des corrections : `claude/finir-app-ud5swp` (commits acc2598, ec69c1c, 5a2d5f4, 6c39581, 539e51d), transmise au fil Xcode pour intégration dans `mac/integration`.

## Les chiffres

| Mesure | Chiffre | Source |
|---|---|---|
| Avancement vers « soumis à 100 % » | **~62 %** (estimation) | [fonctions.md](fonctions.md) |
| Fonctions de la version soumise | 15 vues, 13 codées, 10 partielles, 1 absente | [fonctions.md](fonctions.md) |
| Conformité Apple (check-list) | 9/24 avant la nuit, ~15/24 après la vague 1 | `docs/app-store.md` |
| Tests Core (Linux) | **201 verts**, 1 problème connu (cas d'or 09) | [tests-core.md](tests-core.md) |
| Règles chargées dans l'app | **19 402 confirmées**, 9 107 « vérifie l'arrêté », 96 départements | [regles.md](regles.md), [CSV](regles-par-departement.csv) |
| Départements sous 50 % confirmé | 10 (05, 09, 18, 28, 32, 47, 85, 91, 92, 93 ; pire : 85 à 15 %) | [regles.md](regles.md) |
| Règles qui expirent le 31/12/2026 | ~60 % | [regles.md](regles.md) |
| Modèle de reconnaissance | v2, 55 classes, 22 Mo, seuil 0,4 | [reconnaissance.md](reconnaissance.md) |
| Bonne espèce en 1er / dans les 3 | **72,8 % / 86,0 %** (tout le jeu) ; **82,5 / 91,6** sur des prises de pêcheurs | [reconnaissance.md](reconnaissance.md) |
| Espèces de la démo (1er / 3) | sandre 88/94, black-bass 88/92, brochet 77/86, carpe 72/87, perche 65/75, truite fario 60/75 | idem |
| « Pas un poisson » | 79 % bien nommés, 93 % ouvrent la grille | idem |
| Espèces couvertes | 99 : 33 ont leur classe, 37 dans un groupe, 29 par « Autre » seulement | idem |
| Conseils par espèce | 53 espèces sur 99 | D4 |

## Fait cette nuit

- Banc d'essai : 9 faux utilisateurs (débutant, passionné, garde-pêche, designer, juré MWM…) × 2 passages, critiques gardées si 2 passages sur 3 s'accordent.
- Vague 1 (acc2598) : textes d'autorisation caméra et photos, WeatherKit dans les capacités, fichier de confidentialité Apple, chiffrement déclaré, carte allégée (2 actions + « Plus », cibles 44 pt), bandeau de session avec la fin légale, Pescedex plus lisible, Club (« Trouver mon association »), paywall (Restaurer, liens légaux).
- Verdict de prise : chaque source s'ouvre d'un toucher, et la phrase « l'arrêté préfectoral fait foi » sous la liste (ec69c1c).
- « Choisir un autre spot » rétabli (5a2d5f4).
- Règles : 49 ajouté, 40 41 54 59 63 66 71 72 74 82 88 95 rechargés, 81 chargé avec le correctif de portée ; 93 garde sa version saisie à la main ; 75 et 94 non rechargés.
- Moteur de règles (539e51d) : groupes d'espèces (une règle « salmonidés » vise bien la truite), cours d'eau séparés, truite fario 14 mars – 20 sept., réserves regroupées, libellés en français, 7 phrases qui disaient « garder » reformulées.

## Ce qui manque pour 100 %, et qui s'en occupe

### Bloquant pour Apple
| Manque | Qui |
|---|---|
| Cocher WeatherKit, iCloud et App Group sur l'identifiant MWM | Adem (portail développeur) |
| Vraie page de confidentialité (le paywall pointe vers celle d'Apple) | fil « Fiche App Store avec MWM », après le oui d'Adem |
| Fiche App Store : textes provisoires, captures | fil « Fiche App Store avec MWM » (attend la clé API ou MWM) |
| Amis, widget, Live Activity restent dans la version soumise (Adem, 15 oct. : tout d'un coup) : les finir et les annoncer dans la fiche | fil Xcode et fil « Fiche App Store avec MWM » |
| Repli `ConseilsFaux` hors DEBUG (`RootView.swift:97`) | fil Xcode |
| `stations-hydro.json` à télécharger par `scripts/donnees.sh` avant chaque build | fil Xcode (Mac) |
| Crédit de la photo d'exemple (CC BY-SA, SpinfisherCRO) | ce fil, dans Sources des données |
| Mensuel du paywall pas choisi (4,99 / 6,99 / 9,99) | Adem |

### Bloquant pour la démo
| Manque | Qui |
|---|---|
| Écran de révélation de la carte (E6) absent | ce fil (lot L4), puis Mac |
| Lancement de 15 à 20 s (moteur et SwiftData construits dans `RootView.init`, images rendues au démarrage) | ce fil : plan dans [lancement-lent.md](lancement-lent.md) |
| Mesure de la taille en réalité augmentée sur l'écran Prise | fil « Photos et modèle » (spec `build/reconnaissance/mesure-taille.md`) |
| Modèle v2 pas encore revérifié avec Vision sur le Mac | fil « Photos et modèle » |
| Truite de mer et poisson rouge non séparés ; tuiles de groupe avec noms bruts ; 13 espèces sans image | fil « Photos et modèle » et « Écrans prêts pour le Mac » |

### Le reste (critiques du banc encore ouvertes)
- Verdict calculé au centre du spot, pas là où le poisson est pris (`RootView.swift:332`).
- Catégorie piscicole « inconnue » pas montrée sur le verdict.
- Contrôles de la carpe de nuit.
- Curseur de taille qui part de 40 cm.
- Carte partagée qui montre la rivière et la date exacte.
- Heure de chaque valeur dans la rangée « maintenant ».
- Lien « Signaler une erreur de règle » : il faut l'adresse de contact d'Adem.
- Adresse du club vide (`ContactClub`) : à remplir par Adem.
- Règles : socle national incomplet (écrevisses, anguille, esturgeon, lamproies, aloses, saumon), 10 départements sous 50 %, 2A/17/26 surtout « vérifie l'arrêté ».
- Branches pas encore fusionnées : `lot/store` (26 commits), `lot/style` (palette Marine absente de l'app), `lot/images-poissons` (8), `sullyvan/aquarium`.

## Décisions qui n'attendent qu'Adem
1. Le mensuel du paywall (4,99, 6,99 ou 9,99).
2. L'adresse de contact (club, signalement d'erreur de règle), donnée à 9h.
3. Cocher les 3 capacités sur l'identifiant MWM.
