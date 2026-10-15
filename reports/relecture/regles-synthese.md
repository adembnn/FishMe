# Relecture D1 : synthèse pour Sullyvan (15 oct. 2026)

Préparé par Claude pour la relecture humaine de S. Rien ici n'est une relecture : `verifie_par` et `remarque_S` sont vides dans tous les CSV, et aucun fichier de règles n'a été modifié.

## Ce qui existe vraiment

| Département | Où | Règles | État |
|---|---|---|---|
| 75 | `origin/lot/donnees`, `regles/75.json` | 31 | 22 `brouillon`, 9 `incertain` |
| 94 | `origin/lot/donnees`, `regles/94.json` | 45 | 21 `brouillon`, 24 `incertain` |
| national | `origin/lot/donnees`, `regles/national.json` | 33 | 33 `brouillon` |
| 93 | seulement en brouillon de D3 : `docs/regles/dep/93.json` sur `origin/claude/push-docs-projet-t0aglk` (pas sur `lot/donnees`, pas dans `index.json`) | 27 | 27 `incertain`, ancien format (`source` au lieu de `textes`) |
| 92 | nulle part | 0 | à saisir |
| 77 | nulle part | 0 | à saisir |

- `regles.json` n'est pas sur `lot/donnees`. Il existe sur `lot/collection`, `lot/premier-pas`, `lot/prise`, `lot/session` : c'est le squelette du 12 oct. (13 règles, « saisi », pas relu). Je ne l'ai pas relu.
- `origin/lot/regles-france` ne contient aucun fichier de règles (seulement la consigne, les outils et les rapports).
- Aucune règle n'a de `verifie_par`. Selon la fiche D1 (test « fini » n°3), le 75 et le 94 ne peuvent pas rester `brouillon` : après ta relecture, chaque règle devient `verifie` (avec ton nom) ou `incertain`.

## Fichiers produits

`regles-75.csv` (31), `regles-94.csv` (45), `regles-93.csv` (27, brouillon hors `lot/donnees`), `regles-national.csv` (33, en bonus : les règles locales s'appuient dessus). Colonnes : id, departement, espece, type, categorie, valeur_saisie, du, au, lieu, citation, url_source, etat, `ce_que_dit_la_source`, `ecart`, `verifie_par` (vide), `remarque_S` (vide).

Bilan de `ecart` : 75 = 26 identique / 5 différent ; 94 = 41 / 4 ; 93 = 17 / 9 différent / 1 source illisible ; national = 33 identique (Légifrance lu par résumé, voir limites). « Identique » veut dire : ce que la règle dit est dans la source que j'ai lue. Cela ne veut pas dire que la règle est juste (voir écarts n°1 et n°2).

## Comment j'ai lu, et ce qui a bloqué

Lecture faite depuis ton Mac, pas depuis le cloud.

| Source | Résultat |
|---|---|
| Arrêté de Paris, recueil 75-2025-126 (prefectures-regions.gouv.fr) | PDF avec texte : lu en entier via PDFKit |
| Arrêtés 94 (n°2025/00727) et 93 (n°2025-0988), avis annuels 2026 75, 93, 94, 92 (DRIEAT et fédération) | PDF scannés sans texte : lus par l'OCR de macOS (Vision). **Une erreur d'OCR est possible sur un chiffre ou une date : recontrôle à l'œil sur le PDF les valeurs qui comptent.** |
| DRIEAT (PDF) via WebFetch | 403 ; accessible avec `curl` |
| federation-peche-paris.fr via WebFetch | refusé : le certificat du site ne correspond pas à ce nom de domaine ; accessible avec `curl` en http |
| Légifrance via `curl` | 403 (page « Just a moment », anti-robot) |
| Légifrance via WebFetch | accessible, mais c'est un **résumé** rédigé par un petit modèle, pas le texte : à reconfirmer sur legifrance.gouv.fr pour R436-6, 7, 13, 14, 18, 21, 23, 71 et L436-16 |
| Arrêté ministériel du 14/02/2018 (saone-et-loire.gouv.fr) | lu en entier (PDF avec texte) après une redirection |
| Arrêtés préfectoraux de 2010 sur la consommation (2010-555, 2010-5378, 2010-1334) | **jamais trouvés ni lus** |
| Arrêtés de réserves (5 ans) et cahiers des charges 2023-2027 (75-2022-08-19-00008, 2022-2376) | **non trouvés** |
| Arrêté ministériel annuel anguille jaune 2026 | non cherché |
| Arrêtés et avis du 92 et du 77 | non lus : aucune règle n'existe pour eux (j'ai seulement vu en passant que l'avis 92 2026 écrit les mêmes tailles 0,40 / 0,50 / 0,60) |

## Écarts trouvés

1. **Tailles brochet / sandre / black-bass (75, 93, 94, et sans doute 92).** Les trois arrêtés permanents de 2025 (art. 9) écrivent 0,50 m brochet, 0,40 m sandre, 0,30 m black-bass en 2e catégorie, comme R436-18 (lecture WebFetch). Les avis annuels 2026 des mêmes préfectures et la fédération écrivent 0,60 / 0,50 / 0,40. Deux textes de la même préfecture se contredisent et aucune source lue ne dit lequel s'applique. Le brouillon du 93 retient 60/50/40 en le disant « fédération seule » : c'est inexact, l'avis le dit aussi, et l'arrêté dit 50/40/30. Les règles 75 et 94 gardent bien les deux candidats.
2. **Truite fario, début d'ouverture 2026 (75, 93, 94).** L'arrêté donne « deuxième samedi de mars » = 14/03/2026, les avis disent « 21 mars » (qui est le troisième samedi). La fin (20/09) est la même partout. Les règles 75 et 94 le signalent déjà.
3. **93, consommation : mauvais numéro d'arrêté.** L'arrêté 93 et l'avis 93 2026 citent l'arrêté n°2010-1334 du 7 juin 2010 (Seine, Marne, Ourcq). Le brouillon 93 cite 2010-555, qui est celui de Paris. Les numéros sont différents par département : 75 = 2010-555, 94 = 2010-5378, 93 = 2010-1334. Aucun de ces textes de 2010 n'a été lu. Le canal Saint-Denis (et Saint-Martin à Paris) n'est cité que par la fédération.
4. **93, écrevisses à pattes grêles.** Le brouillon dit « interdite toute l'année » (fédération). L'arrêté art. 5.2 et l'avis 2026 l'ouvrent dix jours (25/07 au 03/08/2026). À corriger, ou à trancher avec la fédération.
5. **93, le brouillon se croyait sans texte.** Il écrit que l'arrêté 2025-0988 est illisible et que l'avis 2026 du 93 est introuvable. Les deux sont lisibles (OCR) : l'avis 93 2026 est sur la page de la fédération (`Avis-annuel-93-2026.pdf`, fait à Bobigny, 15 janv. 2026). Plusieurs règles 93 « fédération seule » (saumon, truite de mer, anguille de nuit, carnet, vif/leurres) sont en fait confirmées par l'arrêté.
6. **94, carpe de nuit.** L'arrêté 2025 autorise la carpe de nuit « dans tous les cours d'eau de deuxième catégorie ». La page de la fédération liste des secteurs précis (arrêté 2017/4688 du 28/12/2017). Les deux ne disent pas la même chose ; la règle `94-car-nuit-cours-eau` suit l'arrêté.
7. **Réserves de pêche : une seule source, la fédération.** 17 réserves du 94, le bassin de l'Arsenal (75) et 7 réserves du 93 viennent de la page de la fédération. Les arrêtés lus ne contiennent que la règle générale de 50 m (art. 4) et disent que les réserves durent 5 ans au plus : date de fin et limites exactes inconnues. Le brouillon 93 range Gennevilliers (semoulerie) sous la Seine-Saint-Denis comme la fédération, alors que c'est le 92.
8. **Aloses et écrevisses à pattes blanches.** Interdites dans les avis 2026 (75, 94, 93) mais pas nommées dans l'art. 5.3 des arrêtés 75 et 94 (l'arrêté 93 interdit les aloses « jusqu'au barrage de Suresnes »).
9. **Anguille jaune.** Aucun texte préfectoral ne donne de dates (renvoi à l'arrêté ministériel annuel). Le 15/02 au 15/07 vient de la fédération seule. Seule règle classée « source illisible » (93-anguille-jaune-ouverture-2026).
10. **Détails de l'avis 75 2026 à regarder sur le PDF** : il renvoie la carpe de nuit à « l'article 9 » de l'arrêté (c'est l'art. 8 ; l'art. 9 = tailles) ; l'OCR lit la grenouille « du 1er juillet au 8 mars » (l'arrêté dit 1er janvier au 2e dimanche de mars) ; la date de signature lue est « 15 JAN. 2026 » alors que les textes de `75.json` disent 16/01/2026. Même doute sur la date de l'avis 94 (« 0 FEV. 2026 »).
11. Le texte de la fédération pour « ver manié autorisé pendant la fermeture du brochet » n'est dans aucun arrêté lu.
12. Libellé de `75-cat-cours-eau` : « (Seine, Marne, Yerres, etc.) » est une glose du brouillon, l'arrêté ne nomme aucun cours d'eau (et la Marne et l'Yerres ne sont pas à Paris).

## À vérifier à la main en priorité

1. Les tailles (écart n°1) : la valeur affichée à un pêcheur est la plus risquée (une prise gardée à 55 cm est une infraction avec 60 cm, légale avec 50 cm). Regarder les PDF des arrêtés (art. 9) et des avis, puis appeler la fédération.
2. Les trois arrêtés de 2010 sur la consommation : les trouver et les lire. Ils déterminent « tu peux manger ce poisson » pour la Seine et la Marne.
3. Les réserves : trouver les arrêtés qui les instituent, leur date de fin (5 ans), les cartes interactives de la fédération.
4. Le début d'ouverture de la truite fario (14 ou 21 mars).
5. Recontrôler à l'œil les chiffres lus par OCR (arrêtés 94 et 93, avis) sur les valeurs retenues : 50/40/30, 25 janvier, 25 avril, 16 mai, 20 septembre, 4 lignes, 10 salmonidés, 3 dont 2 brochets, 50 m.
6. Recontrôler sur legifrance.gouv.fr R436-7, R436-18, R436-21, R436-71 (les lectures du national sont des résumés).
7. Le 93 : décider de le recopier de `docs/regles/dep/93.json` vers `Resources/regles/93.json` en corrigeant les écarts 3, 4 et 5, puis le relire.
8. Le 92 et le 77 : tout est à faire. Pour le 92, les sources sont les mêmes (fédération 75/92/93/94, DRIEAT). Pour le 77, c'est une autre fédération (site federationpeche77.fr) et d'autres arrêtés ; ils sont à lire à la main, les PDF étant refusés aux robots d'après la fiche D1.

## Questions à poser à la fédération 75/92/93/94 (01 53 14 19 80)

Je n'écris aucune valeur à leur place : ce sont des questions ouvertes.

1. Quelle taille minimale s'applique réellement, aujourd'hui, pour le brochet, le sandre et le black-bass dans chacun des départements 75, 92, 93 et 94 ? Pourquoi l'arrêté permanent de 2025 (art. 9) et l'avis annuel 2026 donnent-ils des valeurs différentes pour le même département ?
2. Existe-t-il un arrêté ou un texte signé qui fixe ces tailles, et peut-on en avoir la référence et le lien ?
3. Les tailles sont-elles les mêmes pour les quatre départements ? Y a-t-il des exceptions par cours d'eau (Seine, Marne, canaux, plans d'eau) ?
4. Pour la truite fario, l'ouverture 2026 commence-t-elle le deuxième samedi de mars ou à la date de l'avis annuel ?
5. Quelles tailles s'appliquent aux autres espèces (ombre commun, truites, écrevisses, grenouilles) : la page de la fédération donne 30 / 23 / 9 / 8 cm, sont-elles toutes en vigueur ?
6. Où trouver les arrêtés de 2010 sur la consommation et la commercialisation du poisson (Paris, Hauts-de-Seine, Seine-Saint-Denis, Val-de-Marne) ? Sont-ils toujours en vigueur ? Visent-ils aussi les canaux Saint-Denis et Saint-Martin ?
7. Quels arrêtés instituent chaque réserve de pêche de la liste (limites exactes, date de fin, 5 ans au plus) ? Existe-t-il une version téléchargeable de la carte interactive ?
8. Carpe de nuit dans le Val-de-Marne : l'arrêté 2025 autorise tous les cours d'eau de 2e catégorie, la page de la fédération liste des secteurs (arrêté 2017/4688). Lequel s'applique ?
9. Quelles sont les dates 2026 de l'anguille jaune (arrêté ministériel) ?
10. Les écrevisses à pattes grêles sont-elles bien ouvertes dix jours en 2026 (avis) ou interdites (page de la fédération) ?
11. Les arrêtés de réserves et les arrêtés de classement des plans d'eau et canaux (hors cours d'eau) existent-ils, et où ?
12. Pour le 92 : quelle est la référence de l'arrêté permanent 2025 et de l'avis annuel 2026 (les PDF ne se lisent pas par les robots) ?

## Pour continuer

Les CSV s'ouvrent dans un tableur (UTF-8 avec BOM). Remplis `verifie_par` avec ton nom seulement pour les lignes que tu as relues sur l'arrêté lui-même, `remarque_S` pour tes notes.
