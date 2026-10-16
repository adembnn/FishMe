# FishMe : plan d'exécution pour finir à 100 % (16 oct., 3h15 UTC)

Base : [tableau-de-bord.md](tableau-de-bord.md) et [fonctions.md](fonctions.md). Chaque manque a un seul fil responsable. Tout part en même temps ; le Mac (fil Xcode) est le seul à compiler, il prend les branches dans l'ordre de la colonne « Mac ».

## 1. Fils déjà en ligne

| Fil | Ce qu'il reçoit | Livre sur |
|---|---|---|
| **Design système et maquettes** | Écrans encore sans dessin validé : révélation de la carte (E6, code de base dans `App/Collection/RevelationCarteView.swift`), écran de lancement marine, états vides (Pescedex vide, carte sans spot, pas de réseau), bredouille (E9), image partagée, paywall sur petit iPhone (pas de défilement aujourd'hui), compteur du Pescedex (« Département 94 » quand aucune eau). Puis, page par page après le choix d'Adem : brancher la palette Marine (`lot/style`) et remplacer les jetons provisoires de chaque dossier (`Collection/Jetons.swift`, `Carte/StyleCarte.swift`, `Prise/PriseJetons.swift`, `Conditions/JetonsConditions.swift`, `Session/JetonsSession.swift`, `Conseils/JetonsConseils.swift`, `Abonnement/JetonsAbonnement.swift`, `Amis/JetonsAmis.swift`). Animations : poisson qui nage dans la carte, reflet holographique, retournement de la carte. | `lot/design-systeme` |
| **Photos et modèle de reconnaissance** | Mesure de la taille en réalité augmentée (fourchette « 52 à 56 cm », poids aux deux bornes, toise et curseur en secours) ; compte rendu de l'examen du modèle v2 dans le dépôt (règle : le modèle n'entre que s'il passe l'examen) ; v2 revérifié avec Vision sur le Mac ; séparer truite de mer et poisson rouge ; seuils de la toise mesurés sur 10 photos ; noms bruts des tuiles de groupe (« Poisson-chat (Ameiurus…) ») ; « Brochet aquitain » rangé dans les Cyprinidés. | sa branche, puis Mac |
| **Widget aquarium** | Finir et vérifier les 3 widgets et l'écran verrouillé (Live Activity : boutons Prise et Pause, choix P15) puisqu'ils partent dans la version soumise ; App Group à vérifier sur le profil MWM. | sa branche, puis Mac |
| **Xcode sur le Mac** | Compiler `claude/finir-app-ud5swp` (acc2598 → 3088bab) ; fusionner `lot/images-poissons` (13 espèces sans image, 2 tests rouges), `lot/store` ; lancer `scripts/donnees.sh` avant chaque build ; build Release lancé une fois ; schéma Run sur `TestConfig.storekit` ; parcours « position refusée » ; mesurer le lancement avec Instruments ; passer les tests rouges (abonnement expiré, adresse du club). Puis le banc d'essai au simulateur sur la version corrigée. | `mac/integration` |
| **Fiche App Store avec MWM** | Préparer (sans publier) confidentialité et conditions, textes de la fiche qui annoncent Amis, widgets et écran verrouillé, notes du relecteur, captures après le choix du design. Tout envoi attend le oui d'Adem. | `lot/store` |
| **Aquarium 3D des prises** | Rien de neuf (l'aquarium reste dans la mise à jour). | |

## 2. Nouveaux fils à ouvrir

| Titre | Brief court |
|---|---|
| **Conseils des 46 espèces manquantes** | Lot D4 (`Packages/Core/Sources/Core/Conseils/`, données `conseils.json`) : 161 conseils couvrent 53 espèces sur 99 ; écrire appât, hameçon et technique pour les 46 autres (liste : `build/reconnaissance/especes-reconnaissance.json`), avec la même validation (`ValidationConseils`), jamais « tu peux la garder ». Tests Core sous Docker, pousser sur `lot/conseils`, donner le commit au fil Xcode. |
| **Règles : socle national et départements faibles** | `national.json` n'a que 33 règles : ajouter écrevisses, anguille (stades, dates), esturgeon (interdit), lamproies, aloses, saumon et toutes les tailles de R436-18, chacune avec sa source Légifrance. Puis relire en double lecture les départements sous 50 % confirmés (05, 09, 18, 28, 32, 47, 85, 91) et 2A, 17, 26, par la méthode de `lot/regles-france` ; ne jamais toucher 75, 77, 92, 93, 94. Pousser sur `regles/local`, puis le fil « Finir l'app à 100 % » les charge. |

## 3. Ce que ce fil fait lui-même (code, sur `claude/finir-app-ud5swp`)

- Verdict calculé là où le poisson est pris, pas au centre du spot (`RootView.swift`).
- Repli `ConseilsFaux` sous `#if DEBUG` seulement (`RootView.swift:97`).
- Ordre du tunnel selon le coin (truites d'abord à Charenton aujourd'hui, `EspecesDuTunnel.choisir`).
- Carte née de la photo d'exemple : prévenir qu'elle ne compte pas au Pescedex.
- Mon club : lien de confidentialité, crédit de la photo d'exemple (CC BY-SA, SpinfisherCRO) dans Sources.
- Contrôles de la carpe de nuit sur le verdict.
- Écran de lancement (clé `UILaunchScreen`) et clé d'orientation iPad retirée.
- Charger chaque nouveau département de `regles/local` dès qu'il arrive.
- Boucle de test : critiques du banc → correcteurs → relecteurs (`relecteur-apple`, `relecteur-regles`, `verificateur-wording`) avant chaque envoi au Mac.

## 4. Ce qui n'attend qu'Adem
1. Le prix mensuel (4,99, 6,99 ou 9,99).
2. L'adresse de contact (prévue à 9h).
3. Cocher WeatherKit, iCloud et App Group sur l'identifiant MWM.
4. Choisir la direction de design page par page sur la toile.
5. Le oui pour publier confidentialité, conditions et fiche chez MWM.
