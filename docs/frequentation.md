# Fréquentation des spots et pêche éthique

Décisions d'Adem du 16 oct. 2026 (fil « fréquentation des spots », 08h06 à 09h39 UTC), puis ce qu'il faut construire.
« Par défaut » = choix de Claude, à confirmer par Adem. Faits relevés et sources : `/mnt/project-files/build/frequentation/faits.md`.

## Version simple
FishMe protège le poisson d'abord, le confort du pêcheur ensuite. L'app ne pousse personne vers le même coin : chacun reçoit son spot parmi les bonnes stations proches, les débutants vont là où le poisson tient le mieux, et un compteur anonyme signale un tronçon chargé pour proposer un coin calme à côté. Une espèce rare n'est jamais un appât, et une réserve n'est jamais proposée. Tout cela est gratuit.

## Ce que fait l'app aujourd'hui (`mac/integration`)
- Spot proposé : la station OFB la plus proche (30 km au plus) avec un relevé de moins de 10 ans et une espèce ouverte ce jour (`Packages/Core/Sources/Core/Session/MoteurSession.swift`, `spotPropose`). Tout le monde au même endroit reçoit donc la même station.
- Où chercher : 3 coins OSM, du plus proche au plus loin, jamais classés par chance de prise.
- Aucune notion de fréquentation, de pression ou de rotation. Rien de précis ne quitte l'iPhone et il n'y a pas de serveur FishMe.
- Aucune donnée publique de fréquentation par coin n'existe en France (ni OFB ni fédérations).

## Décisions
| # | Question | Décision d'Adem |
|---|---|---|
| Q1 | Ce qui passe en premier | Protéger le poisson, puis le confort des pêcheurs |
| Q2 | Comment savoir qu'un coin est trop pêché | Compteur anonyme dans iCloud : +1 par session sur le tronçon et la semaine, affiché calme / normal / chargé, seulement au-delà de quelques pêcheurs |
| Q3 | En attendant que le compteur se remplisse | Répartir dès le premier jour : chacun reçoit un spot à lui parmi les bonnes stations proches |
| Q4 | Un coin chargé | Affiché « chargé », l'app propose à côté un coin calme sur la même rivière, sans rien interdire |
| Q5 | Le niveau du pêcheur | Change le spot : débutant vers des coins robustes (espèces communes, accès facile), confirmé peut aller plus loin ou plus sauvage |
| Q6 | Les espèces rares | L'app ne propose jamais un spot à cause d'une espèce rare ; « Ton spot » met en vedette le poisson le plus pêché ; les rares restent visibles dans la liste (envoyé au fil Design) |
| Q7 | Réserves et zones fermées | Jamais proposées ; si le pêcheur y pose son cercle : « Réserve : pêche interdite ici » avec la source. Frayères dans la mise à jour |
| Q8 | Récompenser la remise à l'eau | Non : ni compteur, ni carte spéciale, ni points |
| Q9 | Gratuit ou Pro | Gratuit pour tous (c'est de la protection) |
| Q10 | Réglages du compteur | Oui : par tronçon, une fois par pêcheur et par jour avec un code tiré au hasard chaque jour, 7 derniers jours, rien sous 5 pêcheurs différents, affiché en mots |

## Règles qui en découlent
1. **Répartition.** Le spot proposé est tiré parmi les 5 stations éligibles les plus proches (par défaut), avec une graine propre à l'iPhone (nombre au hasard gardé dans le trousseau) : le même pêcheur retrouve le même spot, deux pêcheurs voisins en reçoivent souvent des différents.
2. **Éligible** = relevé de moins de 10 ans, au moins une espèce ouverte ce jour, et aucune règle `reserve` chargée pour ce cours d'eau dans le département quand une autre station sans réserve est disponible (par défaut, voir « Limite » ci-dessous).
3. **Débutant** (par défaut) : rayon de 15 km, et seulement des stations dont l'espèce la plus vue est « commune » dans le département. S'il n'y en a aucune, on retombe sur la règle générale. **Confirmé** : rayon de 30 km, toutes les stations éligibles.
4. **Rareté.** Le choix d'un spot n'utilise jamais la rareté. L'écran « Ton spot » met en vedette le poisson le plus pêché.
5. **Réserve.** Si une règle `reserve` existe pour le cours d'eau du cercle, la fiche affiche « Réserve listée sur ce cours d'eau » avec la citation de l'arrêté, en tête des règles. Le mot « interdit » n'apparaît que si la citation situe la réserve sans ambiguïté.
6. **Compteur.** Au début d'une session, l'iPhone écrit un passage anonyme : tronçon, jour, code du jour. Il lit le nombre de codes différents sur 7 jours. Sous 5, rien ne s'affiche. Au-delà, le niveau se compare à la moyenne du même tronçon sur les 8 semaines précédentes (par défaut) : en dessous « calme », jusqu'à 1,5 fois « normal », au-delà « chargé ».
7. **Coin calme.** Si le tronçon est « chargé », la fiche propose la station éligible la plus proche sur le même cours d'eau dont le tronçon n'est pas chargé, sinon sur un autre cours d'eau à 15 km au plus. Le pêcheur garde le choix.
8. **Mots.** Jamais « bon spot », jamais un nombre de pêcheurs, jamais « surpêché » (on ne le mesure pas).

## Limites à connaître
- **Les réserves n'ont pas de tracé.** Les arrêtés lus contiennent environ 4 300 règles `reserve` et 3 000 `no_kill`, chacune rattachée à un cours d'eau par son nom, pas à un tracé. L'app sait qu'une réserve existe sur la rivière, pas si le cercle est dedans. D'où la règle 5 : citation de l'arrêté affichée, « interdit » seulement quand c'est sûr.
- **Les tronçons n'existent pas encore dans le code.** En attendant, le compteur utilise la station OFB la plus proche comme tronçon (par défaut) : un point public, déjà affiché sur la carte.
- **iCloud attache un identifiant à chaque écriture.** La base publique CloudKit garde, pour chaque passage, un identifiant d'utilisateur propre à l'app, stable. On ne le lit jamais et on ne s'en sert pas, mais la politique de confidentialité doit le dire, et l'étiquette de confidentialité App Store doit déclarer « localisation approximative, non liée à l'identité ».
- **Sans compte iCloud, pas de passage écrit.** Le pêcheur lit quand même les niveaux des autres.
- **Participation** (par défaut) : active, avec un interrupteur « Compteur de fréquentation » dans Réglages et une phrase d'explication à la première session.

## À construire
| Morceau | Où | Qui | Contenu |
|---|---|---|---|
| 1. Répartition et filtres | `Packages/Core/Sources/Core/Session/` (`spotPropose` reçoit le niveau et la graine) + tests Swift Testing | B (Core) | règles 1 à 4, testé sous Linux |
| 2. Compteur | `App/Frequentation/` (nouveau dossier) : service CloudKit base publique, type `Passage` {troncon, jour, jeton}, calcul du niveau dans Core (`NiveauFrequentation`) | A (capacités iCloud) + B (calcul) | règles 6 et 7, faux service sous `#if DEBUG` pour la démo |
| 3. Fiche et « Ton spot » | `App/Carte/` | A + fil Design | badge calme / normal / chargé, bouton « Coin plus calme », vedette = plus pêché, réserve en tête |
| 4. Réglages et textes | `App/Compte/`, politique de confidentialité, étiquette App Store | A + S1 | interrupteur, phrase d'explication, déclaration |
| 5. Pitch | `docs/parcours-demo.md` | A | une étape démo : deux iPhones voisins reçoivent deux spots différents, un tronçon « chargé » propose un coin calme |
