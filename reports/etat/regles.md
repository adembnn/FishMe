# État réel des règles de pêche embarquées (mesure du 16 oct. 2026)

Mesuré sur `origin/mac/integration` (db62680, 16 oct. 04h01) pour l'app, et sur `origin/regles/local` (dernier commit : le 40, 16 oct. 04h14) pour les lectures confirmées. Lecture et calcul seulement, rien n'a été modifié dans le dépôt. Les 188 tests Core ont été rejoués sous Docker (swift:6.4) : tous verts, avec 1 écart connu.

## Résumé

- Dans l'app : 95 départements, **18 151 règles confirmées**, **8 379 à vérifier** (taux de confirmation global 68,4 %, médiane des départements 70,6 %). Plus le socle national : 33 règles et 1 à vérifier.
- Sur regles/local : 96 départements. Le seul absent de l'app est le **49** (152 règles confirmées, 38 à vérifier au chargement).
- Dans l'app, 5 départements sont en retard sur regles/local : **59, 63, 72, 40, 41**. Les recharger donne **18 782 règles confirmées (+631)** et 8 728 à vérifier, en 96 départements. Vérifié : les 188 tests restent verts avec ces fichiers.
- Les 10 départements sous 50 % sont bien : 05, 09, 18, 28, 32, 47, 85, 91, 92, 93. Les deux pires : 85 (14,9 %) et 28 (18,3 %).
- **Aucun département n'est « complet »** : les 95 fichiers sont `niveau: partiel`. Donc l'app ne dit jamais « aucune règle saisie ne l'interdit », seulement « vérifie l'arrêté » (donnees.md, points 64 et 121).
- **1 562 règles (8,6 %) visent une espèce que le moteur ne sait pas retrouver** (ex. `omble-fontaine` au lieu de `omble-de-fontaine`, `salmonides`, `truite`, `autre:...`). Elles touchent surtout les tailles (358), ouvertures (262), interdictions (238) et quotas (204). 1 412 se réparent par une table de correspondance.
- Qualité de forme : 0 règle sans citation, 0 sans texte source, 0 sans phrase, 0 phrase avec « tu peux la garder », 0 type inconnu, 0 identifiant en double, index.json cohérent (empreintes et nombres).
- 10 852 règles (60 %) expirent le **31/12/2026** ; 6 règles du socle national aussi. Au 1er janvier 2027, une grande partie des ouvertures et tailles disparaît tant qu'on n'a pas rechargé les textes 2027.
- Cas d'or : 13 cas lus, 12 passent, 1 écart connu (cas-09, anguille jaune sans stade : le cas attend « relâche-la », le moteur rend « vérifie l'arrêté »).

## 1. Tableau par département (app, mac/integration)

Taux = confirmées / (confirmées + à vérifier). Espèces = nombre de codes ou noms d'espèces cités par les règles confirmées (les règles sans espèce, valables pour toutes, ne comptent pas). Date = date du texte source le plus récent (ISO si le texte donne un jour, année seule sinon). Expirent = règles confirmées dont `expire_le` vaut 2026-12-31. Le CSV `regles-par-departement.csv` ajoute les chiffres de regles/local, les dates de commit et l'action à faire.

| Dép. | Confirmées | À vérifier | Taux % | Espèces | Textes | Texte le + récent | Expirent 31/12/26 |
|---|---:|---:|---:|---:|---:|---|---:|
| 01 | 320 | 94 | 77.3 | 26 | 63 | 2025-12-16 | 311 |
| 02 | 304 | 127 | 70.5 | 17 | 29 | 2026-04-08 | 223 |
| 03 | 309 | 85 | 78.4 | 24 | 68 | 2026 | 272 |
| 04 | 210 | 181 | 53.7 | 17 | 78 | 2026-07-29 | 12 |
| 05 | 116 | 162 | 41.7 | 14 | 75 | 2026-05-26 | 12 |
| 06 | 113 | 38 | 74.8 | 25 | 30 | 2026-01-08 | 12 |
| 07 | 295 | 104 | 73.9 | 37 | 54 | 2026-07-29 | 0 |
| 08 | 32 | 31 | 50.8 | 6 | 16 | 2026 | 26 |
| 09 | 142 | 166 | 46.1 | 20 | 37 | 2026-03-13 | 6 |
| 10 | 174 | 72 | 70.7 | 17 | 30 | 2026-01-19 | 34 |
| 11 | 234 | 106 | 68.8 | 28 | 50 | 2026-01-07 | 184 |
| 12 | 228 | 194 | 54.0 | 17 | 38 | 2025-12-03 | 228 |
| 13 | 93 | 49 | 65.5 | 31 | 27 | 2025-12-22 | 68 |
| 14 | 188 | 97 | 66.0 | 35 | 23 | 2026-03-13 | 0 |
| 15 | 291 | 48 | 85.8 | 13 | 33 | 2026 | 107 |
| 16 | 196 | 64 | 75.4 | 29 | 29 | 2026-07-22 | 38 |
| 17 | 128 | 85 | 60.1 | 31 | 30 | 2026 | 128 |
| 18 | 77 | 105 | 42.3 | 22 | 45 | 2026-07-21 | 38 |
| 19 | 257 | 82 | 75.8 | 24 | 24 | 2025-11-19 | 2 |
| 21 | 262 | 122 | 68.2 | 15 | 23 | 2025-12-18 | 180 |
| 22 | 269 | 47 | 85.1 | 22 | 34 | 2026-03-13 | 269 |
| 23 | 157 | 95 | 62.3 | 27 | 39 | 2026-07-08 | 119 |
| 24 | 334 | 66 | 83.5 | 26 | 41 | 2026-01-07 | 333 |
| 25 | 314 | 226 | 58.1 | 32 | 64 | 2025-12-18 | 314 |
| 26 | 110 | 82 | 57.3 | 7 | 16 | 2025-12-15 | 93 |
| 27 | 178 | 36 | 83.2 | 31 | 45 | 2026-01-23 | 0 |
| 28 | 57 | 254 | 18.3 | 18 | 14 | 2025-12-30 | 57 |
| 29 | 209 | 34 | 86.0 | 20 | 56 | 2026-03-13 | 170 |
| 2A | 77 | 20 | 79.4 | 22 | 12 | 2026-02-23 | 77 |
| 2B | 62 | 19 | 76.5 | 16 | 17 | 2026-03-23 | 62 |
| 30 | 228 | 81 | 73.8 | 18 | 44 | 2026-01-05 | 228 |
| 31 | 255 | 85 | 75.0 | 32 | 47 | 2026 | 255 |
| 32 | 245 | 263 | 48.2 | 28 | 38 | 2026-02-18 | 245 |
| 33 | 272 | 134 | 67.0 | 29 | 55 | 2026-02-10 | 259 |
| 34 | 235 | 38 | 86.1 | 27 | 24 | 2025-12-26 | 0 |
| 35 | 299 | 88 | 77.3 | 21 | 25 | 2026-06-12 | 297 |
| 36 | 199 | 80 | 71.3 | 25 | 33 | 2026-06-19 | 156 |
| 37 | 270 | 49 | 84.6 | 22 | 40 | 2026-06-18 | 179 |
| 38 | 236 | 82 | 74.2 | 23 | 63 | 2026-02-10 | 218 |
| 39 | 159 | 132 | 54.6 | 20 | 23 | 2026-04-23 | 129 |
| 40 | 318 | 70 | 82.0 | 29 | 30 | 2026-05-04 | 318 |
| 41 | 132 | 43 | 75.4 | 20 | 19 | 2026-10-15 | 132 |
| 42 | 278 | 138 | 66.8 | 26 | 29 | 2026-07-08 | 220 |
| 43 | 173 | 138 | 55.6 | 16 | 27 | 2025-12-30 | 170 |
| 44 | 335 | 77 | 81.3 | 22 | 82 | 2026-02-20 | 112 |
| 45 | 142 | 72 | 66.4 | 25 | 66 | 2025-12-19 | 27 |
| 46 | 210 | 125 | 62.7 | 26 | 37 | 2025-12-15 | 210 |
| 47 | 157 | 201 | 43.9 | 23 | 50 | 2026-01-29 | 66 |
| 48 | 306 | 54 | 85.0 | 17 | 27 | 2026-08-13 | 306 |
| 50 | 186 | 104 | 64.1 | 11 | 63 | 2026-02-19 | 2 |
| 51 | 137 | 29 | 82.5 | 25 | 25 | 2026-03-12 | 36 |
| 52 | 117 | 30 | 79.6 | 21 | 37 | 2025-12-01 | 0 |
| 53 | 212 | 39 | 84.5 | 22 | 42 | 2025-12-17 | 212 |
| 54 | 184 | 28 | 86.8 | 17 | 15 | 2025-12-18 | 165 |
| 55 | 148 | 48 | 75.5 | 16 | 88 | 2025-12-01 | 0 |
| 56 | 264 | 106 | 71.4 | 30 | 41 | 2026-06-25 | 0 |
| 57 | 257 | 50 | 83.7 | 38 | 20 | 2026-03-19 | 132 |
| 58 | 295 | 87 | 77.2 | 22 | 62 | 2026-04-22 | 127 |
| 59 | 166 | 74 | 69.2 | 32 | 47 | 2026-07-20 | 101 |
| 60 | 169 | 45 | 79.0 | 25 | 25 | 2025-12-22 | 143 |
| 61 | 127 | 53 | 70.6 | 23 | 41 | 2026 | 25 |
| 62 | 160 | 54 | 74.8 | 30 | 45 | 2025-12-30 | 160 |
| 63 | 202 | 201 | 50.1 | 25 | 41 | 2025-12-15 | 200 |
| 64 | 287 | 107 | 72.8 | 27 | 62 | 2026-07-08 | 108 |
| 65 | 265 | 139 | 65.6 | 24 | 45 | 2026-07-15 | 143 |
| 66 | 184 | 98 | 65.2 | 35 | 23 | 2025-12-16 | 184 |
| 67 | 124 | 50 | 71.3 | 19 | 23 | 2026 | 31 |
| 68 | 141 | 105 | 57.3 | 27 | 38 | 2026 | 4 |
| 69 | 187 | 16 | 92.1 | 20 | 20 | 2026-01-08 | 187 |
| 70 | 160 | 74 | 68.4 | 30 | 44 | 2025-12-01 | 160 |
| 71 | 341 | 56 | 85.9 | 18 | 27 | 2026-02-20 | 148 |
| 72 | 394 | 153 | 72.0 | 24 | 29 | 2025-12-31 | 0 |
| 73 | 426 | 159 | 72.8 | 27 | 63 | 2026-01-30 | 125 |
| 74 | 229 | 131 | 63.6 | 31 | 59 | 2026-06-16 | 66 |
| 75 | 31 | 0 | 100.0 | 14 | 15 | 2026-10-15 | 15 |
| 76 | 138 | 59 | 70.1 | 28 | 31 | 2025-12-29 | 76 |
| 77 | 100 | 80 | 55.6 | 31 | 39 | 2026-08-21 | 12 |
| 78 | 90 | 25 | 78.3 | 25 | 25 | 2026-03-15 | 25 |
| 79 | 189 | 94 | 66.8 | 22 | 58 | 2026-08-13 | 165 |
| 80 | 202 | 85 | 70.4 | 27 | 48 | 2026-01-19 | 200 |
| 81 | 235 | 98 | 70.6 | 27 | 71 | 2026-07-09 | 162 |
| 82 | 158 | 89 | 64.0 | 19 | 25 | 2025-11-20 | 102 |
| 83 | 229 | 107 | 68.2 | 26 | 84 | 2026-04-20 | 2 |
| 84 | 88 | 75 | 54.0 | 14 | 62 | 2026 | 11 |
| 85 | 28 | 160 | 14.9 | 0 | 39 | 2025-12-15 | 3 |
| 86 | 194 | 134 | 59.1 | 19 | 32 | 2025-11-25 | 194 |
| 87 | 190 | 33 | 85.2 | 25 | 35 | 2025-11-20 | 148 |
| 88 | 233 | 122 | 65.6 | 26 | 51 | 2026 | 176 |
| 89 | 92 | 84 | 52.3 | 24 | 25 | 2026 | 92 |
| 90 | 77 | 29 | 72.6 | 30 | 22 | 2025-12-22 | 0 |
| 91 | 80 | 101 | 44.2 | 30 | 32 | 2026-01-19 | 2 |
| 92 | 25 | 60 | 29.4 | 12 | 24 | 2026-01-13 | 14 |
| 93 | 28 | 37 | 43.1 | 19 | 23 | 2026-01-19 | 6 |
| 94 | 45 | 0 | 100.0 | 14 | 15 | 2026-10-15 | 15 |
| 95 | 152 | 30 | 83.5 | 27 | 35 | 2026-02-04 | 71 |
| **France (95 dép.)** | **18151** | **8379** | **68.4** | | **3715** | | **10852** |
| 49 (absent de l'app) | 0 | 0 | | | | | |

Autres totaux : 1 343 règles expirent à une autre date (31/12/2027 : 731, 31/12/2028 : 341, 31/12/2030 : 177 ; surtout des réserves, de la carpe de nuit, du no-kill), 5 956 n'ont aucune date d'expiration. 1 362 règles sont `incertain`, toutes les autres `brouillon` (aucune `verifie` : personne n'a relu à la main, y compris pour 75, 77, 92, 93, 94). 105 textes sur 3 715 sont des projets, avis non signés ou sans date de signature (17 : 30 textes, 26 : 14, 05 : 12, 82 : 9). 28 départements n'ont comme texte le plus récent qu'un texte de fin 2025 : normal pour la saison 2026.

## 2. Écart entre regles/local et l'app

Méthode : j'ai rejoué `outils/verifier_donnees.py --charger <dep>` (version de lot/donnees, identique à celle de mac/integration) sur les fichiers de regles/local, dans un dossier temporaire, et comparé aux fichiers de l'app.

| Dép. | Dans l'app (conf/à vérif.) | Rechargement donnerait | Dernier commit regles/local | Commentaire |
|---|---|---|---|---|
| 49 | absent | 152/38 | 2026-10-16 01:13 | absent de l'app : à charger |
| 59 | 166/74 | 428/93 | 2026-10-16 04:06 | app = ancienne lecture (166). Gros écart : +262, dont 202 carpe de nuit en tronçons |
| 63 | 202/201 | 309/252 | 2026-10-16 04:06 | +107 (tailles 28, interdictions 26, réserves 22) |
| 72 | 394/153 | 446/369 | 2026-10-16 04:07 | +52 |
| 40 | 318/70 | 375/99 | 2026-10-16 04:14 | +57 ; poussé à 04h14, après le chargement de 22h57 UTC |
| 41 | 132/43 | 134/44 | 2026-10-16 04:13 | +2 (anguille jaune) |
| 95 | 152/30 | 151/27 | 2026-10-15 19:56 | -1 règle, -3 à vérifier : ids différents ; écart sans effet de fond |
| 81 | 235/98 | refus | 2026-10-15 21:45 | le chargeur refuse la règle 81-anguille-jaune-mode_peche-bosselles-c2 (portée « domaine public fluvial ») ; l'app garde sa version écrite à la main (235/98) : rien à faire sauf corriger le chargeur |

Écarts qui ne sont pas un retard : 07 (321 sur regles/local, 295 dans l'app), 28 (229 contre 57), 15, 92, 93. Le chargeur renvoie en « à vérifier » les règles confirmées sans citation (28 : 172 règles, toutes sans citation ; 07 : 26 règles de carpe de nuit sans citation, PK lus sur un scan flou) et fusionne les tailles contradictoires (15, 92, 93 : brochet 50/60, sandre 40/50). Le rechargement du 28 ne change donc rien : il faut une meilleure lecture. 75 et 94 sont protégés (relus à la main, le chargeur refuse) : l'app a 31 et 45 règles écrites à la main, regles/local en a 39 et 40 avec d'autres identifiants. 77, 92 et 93 sont aussi saisis à la main puis complétés.

Dates : tous les fichiers de l'app portent `version 2026-10-15.1`, donc la version ne dit rien ; seuls les commits comptent. Les départements chargés dans l'app l'ont été le 15 oct. entre 17h56 et 22h58 UTC. Sur regles/local, les départements poussés après (40, 41, 59, 63, 72 à 04h06 à 04h14 le 16 oct., puis 17, 2A, 47, 76, 83, 84 entre 23h49 et 00h56) : 17, 2A, 47, 76, 83, 84 sont identiques à l'app (même nombre et mêmes identifiants), seuls 40, 41, 59, 63, 72 ont changé de contenu.

## 3. Couverture des espèces

La liste des 77 espèces `especes-national.json` n'est pas dans le dépôt ; j'ai pris les 77 entrées de la liste de reconnaissance dont `source_liste` vaut `national` (73) ou `national (note)` (4). Les 101 entrées sont celles de `especes-reconnaissance.json`.

Trois lectures du même chiffre (nombre de départements, sur 95, avec au moins une règle confirmée **propre à l'espèce**) :
- **Moteur** : seulement les règles que `MoteurRegles.vise` retrouve (identifiant exact de `especes.json` ou code Sandre). C'est ce que le pêcheur voit aujourd'hui.
- **Avec correspondances** : après réparation des noms évidents (`omble-fontaine`, `carpe`, `breme`, `coregone`...).
- **Avec groupes** : plus les règles de groupe (`salmonides`, `truite`, `anguille`, `ecrevisse`).

Les règles d'ouverture sans espèce (valables pour toutes) existent dans 77 départements ; taille et quota sans espèce : 1 et 3 départements seulement.

| Espèce | Liste | Moteur (toutes) | Taille | Ouverture | Quota | Avec groupes |
|---|---|---:|---:|---:|---:|---:|
| truite-fario | 77 | 82 | 69 | 62 | 41 | 93 |
| truite-arc-en-ciel | 77 | 81 | 57 | 58 | 17 | 91 |
| truite-de-mer | 77 | 9 | 6 | 7 | 4 | 76 |
| saumon-atlantique | 77 | 1 | 1 | 0 | 0 | 70 |
| omble-de-fontaine | 77 | 0 | 56 | 47 | 10 | 84 |
| omble-chevalier | 77 | 39 | 23 | 32 | 7 | 76 |
| cristivomer | 77 | 33 | 15 | 27 | 4 | 76 |
| ombre-commun | 77 | 58 | 40 | 57 | 25 | 83 |
| huchon | 77 | 0 | 0 | 0 | 0 | 70 |
| coregones | 77 | 0 | 14 | 11 | 10 | 17 |
| brochet | 77 | 90 | 77 | 81 | 78 | 90 |
| sandre | 77 | 90 | 89 | 75 | 77 | 90 |
| perche-commune | 77 | 17 | 2 | 15 | 3 | 17 |
| gremille | 77 | 0 | 0 | 0 | 0 | 0 |
| black-bass | 77 | 82 | 64 | 57 | 63 | 82 |
| perche-soleil | 77 | 0 | 0 | 0 | 0 | 0 |
| silure-glane | 77 | 4 | 0 | 4 | 0 | 4 |
| poisson-chat | 77 | 0 | 0 | 0 | 0 | 0 |
| carpe-commune | 77 | 6 | 0 | 4 | 2 | 6 |
| carpe-amour | 77 | 0 | 0 | 0 | 0 | 0 |
| carpe-argentee | 77 | 0 | 0 | 0 | 0 | 0 |
| carpe-grosse-tete | 77 | 0 | 0 | 0 | 0 | 0 |
| gardon | 77 | 2 | 0 | 2 | 0 | 2 |
| rotengle | 77 | 0 | 0 | 0 | 0 | 0 |
| breme-commune | 77 | 2 | 0 | 2 | 0 | 2 |
| breme-bordeliere | 77 | 0 | 0 | 0 | 0 | 0 |
| chevesne | 77 | 2 | 0 | 2 | 0 | 2 |
| tanche | 77 | 2 | 0 | 2 | 0 | 2 |
| barbeau-fluviatile | 77 | 2 | 0 | 2 | 0 | 2 |
| vandoise | 77 | 0 | 0 | 0 | 0 | 0 |
| ide-melanote | 77 | 0 | 0 | 0 | 0 | 0 |
| hotu | 77 | 0 | 0 | 0 | 0 | 0 |
| ablette | 77 | 0 | 0 | 0 | 0 | 0 |
| goujon | 77 | 0 | 0 | 0 | 0 | 0 |
| spirlin | 77 | 0 | 0 | 0 | 0 | 0 |
| able-de-heckel | 77 | 0 | 0 | 0 | 0 | 0 |
| bouviere | 77 | 0 | 0 | 0 | 0 | 0 |
| carassin-commun | 77 | 0 | 0 | 0 | 0 | 0 |
| carassin-argente | 77 | 0 | 0 | 0 | 0 | 0 |
| aspe | 77 | 0 | 0 | 0 | 0 | 0 |
| pseudorasbora | 77 | 0 | 0 | 0 | 0 | 0 |
| goujon-de-l-amour | 77 | 0 | 0 | 0 | 0 | 0 |
| vairon | 77 | 0 | 0 | 0 | 0 | 0 |
| gambusie | 77 | 0 | 0 | 0 | 0 | 0 |
| loche-franche | 77 | 0 | 0 | 0 | 0 | 0 |
| loche-de-riviere | 77 | 0 | 0 | 0 | 0 | 0 |
| loche-d-etang | 77 | 0 | 0 | 0 | 0 | 0 |
| chabot | 77 | 0 | 0 | 0 | 0 | 0 |
| lotte | 77 | 0 | 0 | 0 | 0 | 0 |
| epinoche | 77 | 0 | 0 | 0 | 0 | 0 |
| flet | 77 | 0 | 1 | 0 | 0 | 1 |
| mulet | 77 | 14 | 13 | 2 | 0 | 14 |
| anguille-jaune | 77 | 46 | 13 | 46 | 0 | 47 |
| anguille-argentee | 77 | 0 | 0 | 0 | 0 | 5 |
| civelle | 77 | 0 | 0 | 0 | 0 | 5 |
| grande-alose | 77 | 15 | 14 | 7 | 3 | 15 |
| alose-feinte | 77 | 14 | 11 | 8 | 4 | 14 |
| lamproie-marine | 77 | 6 | 3 | 3 | 0 | 6 |
| lamproie-fluviatile | 77 | 8 | 5 | 3 | 0 | 8 |
| lamproie-de-planer | 77 | 0 | 0 | 0 | 0 | 0 |
| esturgeon-europeen | 77 | 0 | 0 | 0 | 0 | 0 |
| apron-du-rhone | 77 | 0 | 0 | 0 | 0 | 0 |
| ecrevisse-pattes-blanches | 77 | 3 | 2 | 3 | 0 | 17 |
| ecrevisse-pattes-rouges | 77 | 8 | 4 | 8 | 0 | 20 |
| ecrevisse-des-torrents | 77 | 0 | 2 | 6 | 0 | 19 |
| ecrevisse-pattes-greles | 77 | 17 | 9 | 16 | 0 | 26 |
| ecrevisse-americaine | 77 | 23 | 0 | 23 | 0 | 37 |
| ecrevisse-de-louisiane | 77 | 0 | 0 | 18 | 0 | 32 |
| ecrevisse-signal | 77 | 0 | 0 | 13 | 0 | 28 |
| ecrevisse-virile | 77 | 0 | 0 | 0 | 0 | 15 |
| ecrevisse-marbree | 77 | 0 | 0 | 1 | 0 | 16 |
| ecrevisse-a-taches-rouges | 77 | 0 | 0 | 1 | 0 | 16 |
| crabe-chinois | 77 | 0 | 0 | 0 | 0 | 0 |
| grenouille-verte | 77 | 64 | 28 | 63 | 0 | 64 |
| grenouille-rousse | 77 | 55 | 21 | 54 | 0 | 55 |
| grenouille-taureau | 77 | 0 | 0 | 0 | 0 | 0 |
| hybrides | 77 | 0 | 0 | 0 | 0 | 0 |
| truite-tigre | autre | 0 | 0 | 0 | 0 | 0 |
| carpe-koi | autre | 0 | 0 | 0 | 0 | 0 |
| poisson-rouge | autre | 0 | 0 | 0 | 0 | 0 |
| brochet-aquitain | autre | 0 | 0 | 0 | 0 | 0 |
| black-bass-petite-bouche | autre | 0 | 0 | 0 | 0 | 0 |
| crapet-de-roche | autre | 0 | 0 | 0 | 0 | 0 |
| barbue-de-riviere | autre | 0 | 0 | 0 | 0 | 0 |
| barbeau-meridional | autre | 0 | 0 | 0 | 0 | 0 |
| toxostome | autre | 0 | 0 | 0 | 0 | 0 |
| blageon | autre | 0 | 0 | 0 | 0 | 0 |
| vandoise-rostree | autre | 0 | 0 | 0 | 0 | 0 |
| vandoise-du-bearn | autre | 0 | 0 | 0 | 0 | 0 |
| gobie-a-taches-noires | autre | 0 | 0 | 0 | 0 | 0 |
| gobie-de-kessler | autre | 0 | 0 | 0 | 0 | 0 |
| epinochette | autre | 0 | 0 | 0 | 0 | 0 |
| esturgeon-siberien | autre | 0 | 0 | 0 | 0 | 0 |
| sterlet | autre | 0 | 0 | 0 | 0 | 0 |
| esturgeon-oscietre | autre | 0 | 0 | 0 | 0 | 0 |
| bar | autre | 0 | 0 | 0 | 0 | 0 |
| raye-hybride | autre | 0 | 0 | 0 | 0 | 0 |
| ecrevisse-calicot | autre | 0 | 0 | 0 | 0 | 15 |
| grenouille-rieuse | autre | 0 | 0 | 0 | 0 | 0 |
| classe-autre-poisson | classe | 0 | 0 | 0 | 0 | 0 |
| classe-pas-un-poisson | classe | 0 | 0 | 0 | 0 | 0 |

Les colonnes Taille, Ouverture et Quota sont « avec correspondances ». La colonne Liste donne 77 pour les espèces du fichier national.

**Sans aucune règle locale, même en comptant les groupes : 56 espèces sur 99** (dont 35 des 77 nationales). Les 2 classes spéciales (autre poisson, pas un poisson) n'ont pas de règle, c'est normal. Pour ces espèces, c'est le socle national ou le texte général du département qui répond (ouverture générale dans 77 départements).

Espèces nationales sans règle locale : gremille, perche-soleil, poisson-chat, carpe-amour, carpe-argentee, carpe-grosse-tete, rotengle, breme-bordeliere, vandoise, ide-melanote, hotu, ablette, goujon, spirlin, able-de-heckel, bouviere, carassin-commun, carassin-argente, aspe, pseudorasbora, goujon-de-l-amour, vairon, gambusie, loche-franche, loche-de-riviere, loche-d-etang, chabot, lotte, epinoche, lamproie-de-planer, esturgeon-europeen, apron-du-rhone, crabe-chinois, grenouille-taureau, hybrides.

Sans correspondance (lecture moteur stricte), 69 espèces sur 99 n'ont aucune règle retrouvée : en plus de ci-dessus, huchon, omble-de-fontaine, coregones, anguille-argentee, civelle, ecrevisse-des-torrents, ecrevisse-de-louisiane, ecrevisse-signal... n'ont des règles que sous un autre nom.
Les espèces bien couvertes : brochet 90 départements, sandre 90, truite fario 82, black-bass 82, truite arc-en-ciel 81, grenouille verte 64, ombre commun 58, grenouille rousse 55, anguille jaune 46. Perche commune, carpe commune, brème commune, silure : environ 95 départements après correspondance, mais 0 à 10 sous leur nom exact (perche, carpe, breme, silure).

## 4. Le socle national (national.json)

33 règles confirmées, 1 à vérifier, 12 textes, tous `brouillon` (aucune relue), aucun département `complet`. Textes : Code de l'environnement R436-6, R436-7, R436-13, R436-14 5°, R436-18, R436-21, R436-23 I, R436-71, L436-16 II, décret 2019-352, arrêté du 14 février 2018 (espèces envahissantes, art. 3 I : début lu seulement, suite non lue).

| Sujet | Contenu | Source |
|---|---|---|
| Horaire | 30 min avant le lever, 30 min après le coucher | R436-13 |
| Taille minimale | brochet 50, sandre 40 (2e cat.), black-bass 30 (2e cat.), ombre commun 30, truites fario et arc-en-ciel 23 ; 8 espèces « aucune taille écrite » (perche, silure, carpe, gardon, brème, chevesne, tanche, barbeau) | R436-18 |
| Quota | salmonidés 10 par jour (fario, arc-en-ciel, ombre) ; 3 carnassiers en 2e cat. dont 2 brochets ; 8 espèces « aucune limite écrite » | R436-21 |
| Ouverture | 2e cat. toute l'année pour 11 espèces ; brochet (fermé fin janvier à fin avril 2026) ; ombre ; fario ; 1re cat. du 2e samedi de mars au 3e dimanche de septembre | R436-6, R436-7 |
| Carpe de nuit | seulement sur parcours fixés par arrêté préfectoral ; pas de captivité ni transport de nuit | R436-14 5° |
| Transport vivant | carpe de plus de 60 cm (22 500 euros) ; 10 espèces envahissantes (perche soleil, pseudorasbora, goujon de l'Amour, 5 écrevisses, crabe chinois, grenouille taureau) | L436-16, arrêté 14/02/2018 |
| Modes et réserves | 4 lignes en 2e cat. (2 hameçons par ligne) ; interdit sur les ouvrages et 50 m en aval | R436-23, R436-71 |

**Est-ce complet ? Non.** Manques constatés :
1. **Espèces protégées et interdictions nationales absentes** : aucune règle nationale pour les écrevisses indigènes (pattes blanches, pattes rouges, des torrents, pattes grêles), l'anguille argentée et la civelle, l'esturgeon, les lamproies, l'apron, le huchon, les aloses, le saumon. Ces interdictions ne sont aujourd'hui que dans les fichiers départementaux (« interdit » avec nom d'espèce), donc absentes dans un département mal lu. Le cas d'or 09 (anguille jaune) l'illustre.
2. **Tailles R436-18 incomplètes** : omble de fontaine, cristivomer, saumon, écrevisses et grenouilles n'ont pas de ligne nationale. À relire contre le texte de R436-18 (par S).
3. **Périodes nationales datées 2026** : les 6 règles brochet, ombre et fario (ouvertures et fermetures) ont `du 2026-01-01 au 2026-12-31` et `expire_le 2026-12-31`. Ce sont des règles du Code, valables chaque année : au 1er janvier 2027 elles tombent.
4. **Aucune règle nationale de remise à l'eau, de no-kill, de consommation (PCB, mercure), de pêche à la main, ni d'ouverture pour les écrevisses, grenouilles, anguille, aloses, lamproies.**
5. **Arrêté du 14/02/2018 lu à moitié** (« début lu ; suite non lue ») et décret 2019-352 « lu par recoupement ».
6. 1 règle à vérifier : quota du brochet en 1re catégorie.

## 5. Qualité

| Contrôle (18 184 règles : 18 151 + 33) | Résultat |
|---|---|
| Sans citation | 0 |
| Sans texte source (champ `textes` vide ou id inconnu du fichier) | 0 |
| Sans phrase | 0 |
| Ouverture sans dates `du` et `au` | 227 (surtout le 33 : 47, le 82 : 20, le 24 : 11). Ce sont des formules en texte sans date calculée |
| Espèce que le moteur ne retrouve pas | 1 562 règles (8,6 %), 42 noms distincts hors table de correspondance (voir plus bas) |
| Type inconnu | 0 (les 16 types sont tous dans la liste du chargeur) ; mais `no_kill` (2 119 règles), `categorie` (1 099), `remise_eau` (370), `limite_eau_douce` (22) et `autre` (339) tombent dans la ligne « autre » du moteur |
| Phrases ou citations avec « tu peux la garder » | 0 (le moteur le dit en commentaire : jamais) |
| Identifiants en double | 0 |
| Statut | 16 822 brouillon, 1 362 incertain, 0 vérifié |
| Index.json | cohérent : 95 empreintes sha256 et nombres justes |
| Taille max d'un fichier | 73.json 367 Ko (limite 400 Ko) ; 71 et 72 près de 345 Ko |

**Espèces non retrouvées (1 562 règles).** Noms les plus fréquents : omble-fontaine 355, salmonides 262, truite 157, ecrevisse 117, anguille 99, coregone 75, ecrevisse-louisiane 74, ecrevisse-torrents 55, ecrevisse-californie 54, grenouilles-autres 38, anguille-civelle 34, carpe 28. Les départements les plus touchés : 57 (79 règles), 73 (56), 01 (54), 31 (48), 43 (43). Le moteur (`MoteurRegles.vise`, ligne 122) compare avec l'identifiant exact ou le code Sandre ; `docs/donnees.md` dit « codes Sandre, ou le nom quand l'espèce n'a pas de code », mais les noms écrits par les lectures ne sont pas ceux de `especes.json`. Les 150 règles restantes sont des `autre:<nom libre>` (pseudorasbora, crabe chinois, esturgeon, bar...) : 70 de ces noms correspondent à une espèce de la liste après nettoyage.

**Cas d'or** (`Resources/cas-verdicts.json`, 13 cas) : testés par `Packages/Core/Tests/CoreTests/Moteur/CasVerdictsReelsTests.swift`, qui rejoue les 13 cas dans le vrai moteur sur les vrais fichiers de l'app. Résultat de mon exécution : 12 cas sur 13 passent ; **cas-09** (variante anguille jaune sans stade) est un écart connu marqué `withKnownIssue` : le moteur rend « vérifie l'arrêté », le cas attend « relâche-la » (divergence notée dans `reports/l1-divergences.md`). Les autres cas (brochet, sandre, truites, perche, écrevisse protégée, civelle, perche soleil, hors de France, règles périmées) passent. Aucun cas ne teste un département chargé par la machine (01 à 95 sauf 75, 94) : la qualité de ces 18 000 règles n'est pas couverte par un cas d'or.

Avec les fichiers rechargés (40, 41, 49, 59, 63, 72, 95), les 188 tests passent encore, cas-09 mis à part.

## 6. Départements faibles (taux sous 50 %)

| Dép. | Taux | Lecture A seule / B seule | Cause probable (rapports) |
|---|---:|---|---|
| 05 | 41.7 | 142 / 87 | Avis annuel 2026 non daté, lu sur l'image d'une affiche (pages 2 à 4 vides, tableau mal rendu par le texte) ; liste des cours d'eau par catégorie introuvable ; 53 modes de pêche et 23 no-kill non confirmés. |
| 09 | 46.1 | 129 / 68 | Arrêté permanent de 2023 scanné (OCR), lacs de montagne (annexe I, 150 noms, OCR bruité) ; tailles de la grenouille rousse illisibles ; lectures A (271 règles) et B très différentes. |
| 18 | 42.3 | 48 / 75 | Permanent de 2019 en OCR (tableaux relus sur l'image) ; 31 interdictions et 21 modes de pêche non confirmés ; une modification du 06/07/2026 sur l'anguille jaune. |
| 28 | 18.3 | 73 / 66 | PDF du .gouv.fr non lus par les outils de recherche (scans probables), arrêté de classement piscicole introuvable, guide fédération en images JPG. 172 règles confirmées ont perdu leur citation (texte « recomposé par le collecteur »). |
| 32 | 48.2 | 116 / 245 | Annexes 2 à 8 en pages tournées, couche OCR illisible, relues sur images ; citations de tableaux non mot pour mot ; 86 interdictions et 63 modes de pêche non confirmés. |
| 47 | 43.9 | 210 / 179 | Arrêté de 2023 peut-être abrogé, copie fédération en OCR ; 132 lignes de « lans » avec noms en double ; 90 modes de pêche non confirmés. |
| 85 | 14.9 | 114 / 112 | Tableau de l'annuel 2026 : les colonnes de tailles ont disparu à l'OCR ; affiche fédération illisible (page tournée) ; arrêté 2016 des tailles brochet et sandre introuvable ; arrêtés des frayères et des 55 plans d'eau non trouvés. Aucune espèce dans les règles confirmées. |
| 91 | 44.2 | 24 / 101 | Annexes illisibles des arrêtés frayères, plusieurs secteurs de carpe de nuit sans arrêté trouvé ; la lecture A n'a confirmé que peu de règles (24 seulement vues par A, 101 par B). |
| 92 | 29.4 | 52 / 34 | Désaccord de fond permanent 2025 (50/40/30) et avis 2026 (60/50/40) : tailles fusionnées en 2 valeurs ; OCR de l'avis (0,40 contre 0,50 m du sandre) ; 32 interdictions à vérifier. |
| 93 | 43.1 | 26 / 17 | Permanent 2025 en OCR, projet 2026 non signé, arrêtés des réserves et de la consommation introuvables ; 27 ouvertures à vérifier. |

Constat commun : l'OCR de PDF scannés et les tableaux en image sont la première cause. La deuxième est que, pour les modes de pêche, no-kill, réserves et carpe de nuit, les deux lectures ne s'accordent pas sur le fond. À noter : même les départements à 50 à 60 % (04, 08, 12, 39, 43, 63, 77, 84, 89) ont les mêmes causes. 92, 93 et 77 sont aussi des départements saisis à la main : leur taux bas est une conséquence du désaccord entre arrêté permanent et avis.

Autres trous de contenu critiques (verdict de taille) : pas de taille du brochet en règle confirmée dans 18 départements (02, 05, 08, 09, 12, 13, 26, 2A, 32, 33, 40, 50, 56, 59, 76, 81, 85, 87), dont 12 ont au moins une ligne à vérifier et 6 n'ont **rien du tout** (05, 33, 40, 76, 81, 87) ; pas de taille du sandre dans 6 (04, 05, 12, 26, 50, 85), dont 04 et 05 sans rien. Le 85 n'a aucune règle de taille. Le 12 n'a aucune règle d'ouverture.

## 7. Ce qui manque pour que les règles soient « finies » (par priorité)

1. **Recharger 59, 63, 72, 40, 41 et charger 49** (une commande par département : `REGLES_DIR=<regles-local> python3 outils/verifier_donnees.py --charger 59`, sur lot/donnees). +631 règles, tests verts vérifiés. Facultatif : 95 (-1).
2. **Corriger le vocabulaire des espèces** : 1 562 règles ne sont pas retrouvées par le moteur. Deux voies : table de correspondance dans `MoteurRegles.vise` (Packages/Core, B) ou normalisation dans `outils/verifier_donnees.py` (`construire_regle`) puis rechargement des 96 fichiers. Règle de nom : `omble-fontaine` vers `omble-de-fontaine`, `carpe` vers `carpe-commune`, `breme`, `perche`, `silure`, `coregone`, `anguille-civelle`, `ecrevisse-louisiane`, `ecrevisse-torrents`, `ecrevisse-californie`. Prévoir un vrai sens pour `salmonides`, `truite`, `anguille`, `ecrevisse` (groupes) et pour `autre:<nom>`.
3. **Passer le socle national en règle permanente** : retirer `expire_le 2026-12-31` et les dates 2026 des 6 règles brochet, ombre et fario de `regles/national.json`, avant le 1er janvier 2027.
4. **Prévoir l'après 31/12/2026** : 10 852 règles expirent ce jour-là. Plan : relire les arrêtés et avis 2027 en décembre, ou décider que les règles à date de saison se prolongent avec la mention « saison précédente, vérifie l'arrêté ». Le cas d'or 13 le teste déjà pour 75.
5. **Compléter le socle national** : écrevisses indigènes, anguille (argentée, civelle), esturgeon, lamproies, apron, huchon, aloses, saumon ; tailles R436-18 manquantes ; lire la suite de l'arrêté du 14/02/2018 ; relire R436-18 en entier.
6. **Relire les 10 départements sous 50 %**, dans l'ordre 85, 28, 92, 05, 93, 18, 47, 91, 09, 32 : renvoyer les PDF scannés à une lecture sur image (tailles, tableaux), et trouver les textes manquants (85 : arrêté 2016 des tailles ; 28 : classement piscicole ; 93 : arrêtés 2022-2376 et 2010-1334). Corriger d'abord le 28 : 172 règles sans citation.
7. **Tailles brochet et sandre** manquantes en règle confirmée : 05, 33, 40, 76, 81, 87 (brochet), 04, 05 (sandre), 85 (aucune taille), 12 (aucune ouverture).
8. **Relecture humaine** : tous les fichiers sont `brouillon` ou `incertain`, aucun `verifie`. La relecture de S était prévue pour 75, 92, 93, 94, 77 : à faire ou à écarter de la promesse.
9. **Cas d'or sur la machine** : ajouter quelques cas sur les départements lus par l'IA (par exemple 01, 33, 59, 69), car aujourd'hui les 13 cas ne testent que 75, 94 et le socle national.
10. **Écart cas-09** (anguille jaune sans stade) : décider si « relâche-la » est voulu ; le socle national n'a pas de ligne d'anguille.
11. **Passer des départements en `complet`** quand ils le méritent (critère du chargeur : deux lectures v2, textes lus en entier, 60 % de règles sans réserve) ; aujourd'hui 95 sur 95 sont `partiel` parce que regles/local ne livre pas les en-têtes de lecture.
12. **Dates des ouvertures** : 227 ouvertures n'ont que du texte (33 : 47 règles).
13. **Garde-fou taille de fichier** : 73.json fait 367 Ko sur 400 Ko autorisés ; 71 et 72 aussi près de la limite.
