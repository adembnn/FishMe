# État réel de la reconnaissance des poissons (16 oct. 2026)

Mesure en lecture seule. Branche compilée : `mac/integration` (db62680, identique à la branche locale `claude/finir-app-ud5swp`). Scripts de calcul : `/tmp/claude-0/reco-mesure/` (mapping.py, calc.py, classes.py).

## 1. Le modèle embarqué

| Point | Valeur | Source |
|---|---|---|
| Fichier | `App/Prise/Modele/PoissonsDino-int8.mlpackage` (DINOv2-small + régression logistique, int8) | dossier |
| Taille | 21,8 Mo de poids + 0,16 Mo de spécification, soit environ 22 Mo (limite 30 Mo) | `ls -la` |
| Version | **v2, 55 classes**. Empreintes sha256 de `weight.bin` et `model.mlmodel` identiques à celles de `reports/reconnaissance/modele/` sur `origin/claude/project-thread-1vgm3n` (b0dc0fa) ; les 55 étiquettes de `labels.txt` sont toutes présentes dans le modèle | calcul |
| Étiquettes | lues dans le modèle par Vision (pas de fichier d'étiquettes dans l'app) ; seules 16 étiquettes sont traduites à la main | `IdentificationDino.swift:48-56` |
| Seuil de confiance | **0,4**, appliqué à la meilleure étiquette brute (sans température) ; en dessous, la grille s'ouvre | `IdentificationDino.swift:13,16,26-28` |
| Chaîne | photo entière, carré à bord neutre, Vision `.scaleFit`, pas de détourage | `IdentificationDino.swift:107-111` |
| Branchement | `IdentificationDino()` dans `RootView.swift:95` (la version "absente" n'est plus utilisée) | grep |

Les 55 étiquettes : 52 espèces ou groupes, plus `autre-poisson`, `pas-un-poisson`, `gambusie` (traitée comme "autre", écartée par l'app).

## 2. Couverture des espèces pêchables

Chiffre à corriger : `especes-reconnaissance.json` a 101 entrées, mais 2 sont des pseudo-classes (`classe-autre-poisson`, `classe-pas-un-poisson`). La table de l'app (`Packages/Core/Sources/Core/Resources/especes.json`) a **99 espèces** : 82 poissons, 11 écrevisses, 4 grenouilles, 1 crabe, 1 hybride.

| Cas | Espèces | Part |
|---|--:|--:|
| Classe propre (1 espèce = 1 classe du modèle) | 33 | 33 % |
| Classe de groupe (le modèle donne la classe, le pêcheur choisit dans la grille filtrée) | 37, en 15 groupes | 37 % |
| Grille "Autre" seulement | 29 | 29 % |
| Total | 99 | |

Les 15 groupes : brochet (2 espèces), black-bass (2), poisson-chat (2), carpe (2), hotu/toxostome (2), ablette (2), carassin (2), épinoche (2), alose (2), vandoise (3), loche (3), anguille (3), lamproie (3), gobies (3), esturgeon (4).

**Les 29 espèces qui passent par la grille seulement** :
- Poissons (12) : apron du Rhône, bar, barbeau méridional, blageon, crapet de roche, gambusie, poisson rouge, pseudorasbora, rayé hybride, spirlin, truite de mer, truite tigre.
- Écrevisses (11) : à taches rouges, américaine, calicot, de Louisiane, des torrents, marbrée, pattes blanches, pattes grêles, pattes rouges, signal, virile.
- Grenouilles (4) : rieuse, rousse, taureau, verte. Crabe chinois (1). Hybrides (1).

Classes de l'app couvertes par le modèle : 33 + 15 = 48 (les 29 autres espèces n'ont aucune classe dans le modèle).

## 3. Scores du v2 (eval8, bloc `dinov2-s` de `scores.json`)

Les figures `seuils.json` et le README de la branche (93 %, 98 %, 96,7 % de refus, seuil 0,37) sont celles du modèle Fishial + DINOv2 du cloud, **pas** celles du modèle embarqué. Seul le bloc `dinov2-s` est le modèle de l'app.

| Jeu | Photos | Top-1 | Top-3 | Source du chiffre |
|---|--:|--:|--:|---|
| Tout le test | 10 452 | 72,8 % | 86,0 % | recalculé depuis `par_classe` : 72,77 % / 86,04 % |
| Prises AFFiNe (pêcheurs néerlandais) | 1 847 | 87,7 % | 96,4 % | `par_source` |
| Prises de pêcheurs hors AFFiNe (Allemagne, Tchéquie, Hongrie, Europe, Amérique) | 5 215 | 80,7 % | 89,9 % | `par_source` |
| **Toutes les prises de pêcheurs** (les deux lignes ci-dessus) | 7 062 | **82,5 %** | **91,6 %** | recalcul pondéré |
| Photos de terrain GBIF | 2 837 | 47,9 % | 70,3 % | `par_source` |
| 20 espèces les plus pêchées (`classes.tsv`, colonne top20) | 7 019 | 72,3 % | 84,9 % | recalcul pondéré (n = 7 019, comme `seuils.json`) |
| "Pas un poisson" | 368 | 79,1 % reconnu | 97,6 % | `par_classe` |

**Refus des "pas un poisson"** : 79,1 % sont étiquetés "pas un poisson" ; 13,9 % (51 photos) sont étiquetés "autre poisson", ce qui ouvre aussi la grille dans l'app. Au moins **92,9 %** (342 sur 368) ne donnent donc aucune espèce proposée. Les autres confusions (lamproie fluviatile 8, grande alose 4, autres) ne sont pas toutes listées : ce sont des fausses espèces possibles si la confiance dépasse 0,4.

Limites de la mesure : `scores.json` ne contient pas de score par photo. On ne peut donc pas recalculer l'effet du seuil 0,4 sur le v2. Le 0,4 vient de la mesure v1 sur Mac (confiance moyenne 0,68 si juste, 0,35 si faux). Le v2 n'a pas été revérifié sur Mac avec Vision (le LISEZMOI du modèle le dit) ; seul un test sur la photo d'exemple (un brochet) existe : `AppTests/Prise/IdentificationDinoTests.swift:8-17`.

### Par classe (55 classes, tout le test ; confusions = les 3 premières)

Classes triées du plus faible au plus fort sur le top-1. Effectif de test = n.

| Classe | n | Top-1 | Top-3 | Confusions principales |
|---|--:|--:|--:|---|
| lamproie-fluviatile | 17 | 29,4 | 47,1 | anguille 7 |
| lamproie-planer | 64 | 31,2 | 79,7 | anguille 26, vairon 6, lamproie-fluviatile 4 |
| ablette | 49 | 32,7 | 59,2 | gambusie 5, able-heckel 5, vandoise 5 |
| loche-franche | 20 | 40,0 | 65,0 | vairon 3, gobie-invasif 2, lotte 2 |
| gardon | 230 | 44,8 | 70,4 | rotengle 20, vandoise 10, ide 9 |
| grande-alose | 12 | 50,0 | 50,0 | mulet, omble-chevalier, épinoche (1 chacun) |
| mulet | 76 | 53,9 | 75,0 | flet 3, ablette 3, poisson-chat 3 |
| rotengle | 210 | 56,2 | 81,0 | gardon 28, gambusie 13, able-heckel 5 |
| saumon | 91 | 57,1 | 80,2 | truite-commune 10, vairon 5, cristivomer 5 |
| chabot | 59 | 57,6 | 79,7 | gobie-invasif 7, lotte 5, gambusie 5 |
| able-heckel | 26 | 57,7 | 80,8 | gambusie 5, ablette 3 |
| carpe-argentee | 27 | 59,3 | 85,2 | carpe-grosse-tete 7 |
| carassin-commun | 115 | 60,0 | 82,6 | carassin-argente 23, carpe-commune 3 |
| truite-commune | 777 | 60,0 | 75,4 | saumon 46, truite-arc-en-ciel 32, vairon 26 |
| truite-arc-en-ciel | 368 | 62,8 | 79,9 | saumon 21, cristivomer 14, huchon 13 |
| carassin-argente | 170 | 62,9 | 87,6 | carassin-commun 28, rotengle 8 |
| vairon | 65 | 63,1 | 84,6 | gambusie 6, lamproie-planer 4 |
| epinoche | 212 | 63,2 | 84,9 | gambusie 20, able-heckel 9 |
| omble-fontaine | 204 | 63,2 | 82,4 | truite-arc-en-ciel 18, cristivomer 12 |
| perche | 398 | 65,3 | 75,1 | poisson-chat 21, épinoche 15, autre-poisson 12 |
| anguille | 380 | 66,6 | 86,3 | lamproie-planer 53 |
| chevesne | 177 | 67,2 | 84,7 | vandoise 9, gardon 8, ide 8 |
| lotte | 96 | 67,7 | 81,2 | anguille 6 |
| hotu | 75 | 68,0 | 88,0 | barbeau 6 |
| gambusie | 68 | 69,1 | 86,8 | vairon 6 |
| autre-poisson | 167 | 69,5 | 89,8 | pas-un-poisson 26 |
| goujon | 112 | 71,4 | 82,1 | vairon 8, épinoche 6 |
| carpe-commune | 1 176 | 71,9 | 87,0 | carpe-amour 49, chevesne 43, carassin-argente 38 |
| aspe | 206 | 72,3 | 85,0 | silure 11 |
| carpe-grosse-tete | 41 | 73,2 | 92,7 | carpe-argentee 8 |
| omble-chevalier | 41 | 73,2 | 87,8 | omble-fontaine 5 |
| vandoise | 27 | 74,1 | 77,8 | chevesne 2 |
| ide | 160 | 74,4 | 84,4 | chevesne 8 |
| ombre | 36 | 75,0 | 80,6 | ide 2, able-heckel 2 |
| loche-riviere | 13 | 76,9 | 84,6 | épinoche, perche, gambusie (1) |
| brochet | 856 | 77,1 | 86,0 | cristivomer 14, silure 13, vairon 13 |
| pas-un-poisson | 368 | 79,1 | 97,6 | autre-poisson 51 |
| breme-commune | 227 | 80,2 | 90,3 | breme-bordeliere 22 |
| silure | 402 | 82,1 | 89,6 | grande-alose 8, lamproie-fluviatile 7 |
| barbeau | 176 | 82,4 | 89,8 | carpe-amour 6 |
| flet | 64 | 82,8 | 85,9 | silure 4 |
| coregones | 82 | 82,9 | 90,2 | aspe 3 |
| breme-bordeliere | 91 | 84,6 | 97,8 | breme-commune 9 |
| cristivomer | 283 | 86,2 | 93,3 | omble-fontaine 9 |
| carpe-amour | 187 | 86,6 | 91,4 | chevesne 8 |
| poisson-chat | 142 | 86,6 | 93,0 | perche-soleil 3, silure 3 |
| huchon | 48 | 87,5 | 91,7 | carpe-grosse-tete 2 |
| black-bass | 466 | 87,6 | 92,3 | poisson-chat 15, perche 6 |
| perche-soleil | 296 | 87,8 | 92,2 | gremille 3 |
| sandre | 318 | 88,1 | 94,0 | perche 5, truite-arc-en-ciel 4 |
| gobie-invasif | 106 | 89,6 | 97,2 | chabot 5 |
| tanche | 195 | 92,8 | 95,4 | breme-commune 2, carassin-commun 2 |
| gremille | 100 | 93,0 | 98,0 | chabot 2, goujon 2 |
| esturgeon | 71 | 98,6 | 98,6 | anguille 1 |
| bouviere | 9 | 100 | 100 | aucune |

**Les 10 classes les plus faibles (top-1)** : lamproie fluviatile (29 %), lamproie de Planer (31 %), ablette (33 %), loche franche (40 %), gardon (45 %), grande alose (50 %), mulet (54 %), rotengle (56 %), saumon (57 %), chabot (58 %). Seuls 8 effectifs sont sous 30 photos (able-heckel, bouvière, carpe argentée, grande alose, lamproie fluviatile, loche franche, loche de rivière, vandoise) : leurs pourcentages sont fragiles.

Confusions qui ne comptent pas dans l'app car les deux étiquettes partagent une classe : ablette/able-heckel, carassin commun/argenté, loches, lamproies, bien que la liste des confusions soit tronquée aux 3 premières. Le score "au niveau de la classe app" est donc un peu meilleur que ci-dessus pour ces classes (non recalculable sans scores par photo).

## 4. Les 6 espèces de la démo

Le test fixe ne donne les scores par classe que sur toutes les sources mélangées (terrain GBIF compris). Les scores sur les seules prises de pêcheurs par classe n'existent pas dans eval8.

| Espèce | Classe du modèle | n test | Top-1 | Top-3 | Confusions | R1 (70 / 90) |
|---|---|--:|--:|--:|---|---|
| Brochet | brochet | 856 | 77,1 | 86,0 | cristivomer 14, silure 13, vairon 13 | top-3 sous 90 |
| Sandre | sandre | 318 | 88,1 | 94,0 | perche 5, arc-en-ciel 4 | passe |
| Perche | perche | 398 | 65,3 | 75,1 | poisson-chat 21, épinoche 15, autre-poisson 12 | échoue les deux |
| Truite fario | truite-commune | 777 | 60,0 | 75,4 | saumon 46, arc-en-ciel 32, vairon 26 | échoue les deux |
| Carpe | carpe-commune | 1 176 | 71,9 | 87,0 | carpe-amour 49, chevesne 43, carassin argenté 38 | top-3 sous 90 |
| Black-bass | black-bass | 466 | 87,6 | 92,3 | poisson-chat 15, perche 6 | passe |

Réserve black-bass : l'ancien score de 95 % venait de photos texanes "ShareLunker" au même badge ; elles sont exclues depuis, mais le README du banc note 53 % hors ShareLunker sur 19 photos. Le 87,6 % actuel repose sur 466 photos de test et doit être revu à la main.

## 5. Ce qui manque pour "fini" (seuils R1)

| Critère R1 | Seuil | Mesure du v2 | Verdict |
|---|--:|--:|---|
| Top-3, toutes photos du test | 90 % | 86,0 % | échoue |
| Top-3, prises de pêcheurs (7 062) | 90 % | 91,6 % | passe |
| Top-1, tout le test | 70 % | 72,8 % | passe |
| Top-1, prises de pêcheurs | 70 % | 82,5 % | passe |
| "Pas un poisson" refusés | 90 % | 79,1 % strict ; au moins 92,9 % avec "autre poisson" | passe seulement si "autre poisson" compte comme refus |
| 20 espèces les plus pêchées | (non fixé) | 72,3 % / 84,9 % | top-3 sous 90 |

Par classe sous le seuil : **24 classes d'espèces sous 70 % en top-1** (les 26 de la liste ci-dessus moins `autre-poisson` et `gambusie`, hors espèces) et **36 sur 52 sous 90 % en top-3**. Parmi les 20 espèces les plus pêchées, sous 70 % en top-1 : truite commune, truite arc-en-ciel, perche, gardon, rotengle, ablette, carassin argenté, anguille. Seules 16 classes d'espèces atteignent 90 % en top-3.

Si R1 exige les seuils sur le test entier, il manque environ 4 points de top-3 (86,0 contre 90). Si R1 exige les seuils sur les prises de pêcheurs (le cas de l'app), ils sont tenus au niveau global mais pas par classe.

**Quand le modèle doute, l'app fait ceci** :
1. Meilleure étiquette sous 0,4, ou étiquette "pas un poisson" / "autre poisson" / "gambusie" en tête : la grille de toutes les espèces s'ouvre directement (`IdentificationDino.swift:26-29`).
2. Sinon 3 propositions (une tuile par espèce ou par groupe), plus "Autre espèce" (grille complète) et "Pas un poisson" (ferme sans prise), toujours visibles (`MoteurEspeces.swift:203-209`, `PriseVuesEspece.swift:99-105`).
3. Une classe de groupe ouvre la grille limitée aux membres du groupe (`PriseLogique.swift:15-19`).
4. L'espèce relevée près du coin garde son score ; les autres sont multipliées par 0,3 (`MoteurEspeces.swift:72,197`). Une vraie prise d'une espèce rare dans la zone peut donc descendre sous le rang 3.
5. Il n'existe pas de message "ce n'est pas un poisson" : un "pas un poisson" du modèle ouvre la grille, c'est le pêcheur qui touche "Pas un poisson".

## 6. Incohérences étiquettes du modèle et table de Core

Pas de classe du modèle sans espèce : les 52 classes d'espèces donnent toutes une `classe_modele` existante dans `especes.json` (vérifié par script). Les problèmes sont les suivants.

| # | Problème | Où | Effet |
|---|---|---|---|
| 1 | 29 espèces sur 99 n'ont aucune classe dans le modèle (liste au point 2) | `especes.json` | grille seulement |
| 2 | **Truite de mer et poisson rouge** sont dans les données d'entraînement (`classes.tsv` : "truite commune (fario, de mer)", "carassin argenté et poisson rouge") mais Core leur donne des classes séparées (`truite_de_mer`, `poisson_rouge`) | `especes.json`, `IdentificationDino.swift:48-56` | une truite de mer est proposée comme truite fario, un poisson rouge comme carassin |
| 3 | `gambusie` : classe entraînée (68 photos de test) mais écartée par l'app ; Core la met dans `autre_poisson` | `IdentificationDino.swift:45` | un score fort de gambusie ouvre la grille au lieu d'une proposition ; acceptable mais invisible |
| 4 | **Nom brut affiché sur les tuiles de groupe** : la tuile prend la première espèce du groupe, avec ses annotations ("Poisson-chat (Ameiurus melas ; Ameiurus nebulosus [?])", "Carpe commune (miroir, cuir)", "Anguille européenne, stade jaune", "Goujon de l'Amour" pour la classe des gobies, "Lamproie marine" pour la classe lamproie, "Black-bass à grande bouche") | `PriseVuesEspece.swift:64,94-95` | le nom montré ne désigne pas le groupe ; 24 noms de `especes.json` portent une parenthèse |
| 5 | Repli sur le nom de classe brut (`nom.split("_")...`) si aucune espèce n'a la classe : pas atteint aujourd'hui (toutes les classes viennent du catalogue) mais affiche "Hotu ou toxostome" style technique | `PriseVuesEspece.swift:97-99` | à supprimer ou à tester |
| 6 | **13 espèces sans image** (repli SF Symbol "fish", "ant" ou "hare") : spirlin, lamproie de Planer, écrevisse pattes rouges, écrevisse virile, écrevisse à taches rouges, grenouille verte, grenouille rousse, hybrides, truite tigre, carpe koï, vandoise rostrée, vandoise du Béarn, rayé hybride. 86 espèces sur 99 ont image et silhouette | `App/Assets.xcassets/Especes/` | images absentes de `Assets.xcassets/Especes/` (à vérifier sur `lot/images-poissons`) ; la règle "poissons toujours en images" n'est pas tenue pour ces 13 |
| 7 | Le commentaire de `ResultatIdentification` parle d'une température de `reglages.json` ; ce fichier n'existe pas dans `Core/Resources/` et l'app utilise les probabilités brutes | `Prise.swift:103` | commentaire faux |
| 8 | Le LISEZMOI du modèle demande le poisson détouré ; l'app envoie la photo entière (choix assumé, vérifié à 86 % sur v1). Le v2 n'a pas de vérification Mac avec Vision | `IdentificationDino.swift:9,107` | risque de score réel différent du banc |
| 9 | Le seuil 0,4 est testé sur l'étiquette brute la plus haute, pas sur la classe fusionnée : carassin argenté 0,3 + commun 0,3 (classe "carassin" à 0,6) ouvre la grille | `IdentificationDino.swift:26-28` | grille trop fréquente pour les groupes à plusieurs étiquettes (ablette, carassin, loche, lamproie) |
| 10 | Les chiffres du README et de `seuils.json` de la branche `project-thread-1vgm3n` (93,5 %, 98,2 %, 96,7 % de refus, seuil 0,37) décrivent Fishial + DINOv2, pas le modèle de l'app | `reports/reconnaissance/README.md` | confusion possible avec le modèle embarqué |

## Fichiers utiles
- `App/Prise/IdentificationDino.swift`, `App/Prise/PriseModele.swift`, `App/Prise/PriseVuesEspece.swift`, `App/Prise/PriseLogique.swift`
- `Packages/Core/Sources/Core/Especes/MoteurEspeces.swift`, `Packages/Core/Sources/Core/Resources/especes.json`
- `/mnt/project-files/build/reconnaissance/banc-essai/eval8/scores.json`, `jeu-test.csv`, `classes.tsv`
