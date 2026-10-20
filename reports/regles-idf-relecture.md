# Relecture des règles d'Île-de-France (75, 77, 92, 93, 94)

Décision débloquée : les règles saisies à la main de ces 5 départements peuvent-elles partir « relues par une personne », ou faut-il passer des lignes à « vérifie l'arrêté » ? Fait le 20 oct. 2026 par l'agent E. Lecture seule : aucun JSON modifié.

## Réponse courte
- Aucune des 330 règles n'est « relue par une personne » aujourd'hui : `verifie_par` est vide partout, statut `brouillon` (252) ou `incertain` (78). Le validateur (`outils/regles/valider.py`) n'accepte même pas d'autre statut. Dire « relues par une personne » serait faux tant qu'Adem ou quelqu'un n'a pas signé.
- Cette relecture par script compare chaque citation au texte réel : 276 règles sur 330 (84 %) ont une citation retrouvée à plus de 85 %, les 54 autres ont été revues à la main ; les écarts restants viennent de la lecture optique (OCR), pas du JSON (vérifiés à l'image, voir section 3). Aucune citation inventée trouvée.
- Les vrais risques sont ailleurs : (1) 6 règles du 77 périmées, (2) une règle temporaire du 77 sans date de fin, (3) la taille du brochet en 93, (4) les avis 2026 qui expirent le 31/12/2026, (5) le doute que les arrêtés permanents 2025 de 75/92/93/94 aient été remplacés en 2026.
- Le moteur (`MoteurRegles.swift`) protège déjà : une règle expirée devient « vérifie l'arrêté », une règle `incertain` sans candidats aussi. Pour les tailles à deux textes, il prend la plus haute (60/50/40, relâche en dessous), ce qui est l'option b de `qui-est-maitre.md`, pas la zone « vérifie » entre 50 et 60.

## 1. Méthode et limites
- Script : `scratchpad/e/check.py` (couverture des suites de 4 mots de la citation dans le texte source) et `numcheck.py` (dates et tailles du JSON contre la citation). Sources téléchargées en public (23 URL citées par les JSON, toutes ont répondu 200), PDF numérisés passés en OCR, doutes revérifiés sur l'image.
- Non vérifiable en ligne : existence d'un arrêté permanent 2026 signé pour 75/92/93/94 (consultation du 10/02 au 03/03/2026). Recherche web du 20/10 : rien trouvé ; DRIEAT refuse la page (403). Statut : SOURCE INTROUVABLE, donc non exclu.
- Non relu à la main : le contenu des cases « modes de pêche », « carpe de nuit » ligne par ligne (contrôle par script seulement).

## 2. Nombre de règles
| Dép. | Règles | brouillon / incertain | Tailles | Fermetures, interdits, réserves | Expirent 31/12/2026 | Déjà périmées |
|---|---|---|---|---|---|---|
| 75 | 31 | 22 / 9 | 3 | 9 | 15 | 0 |
| 77 | 100 | 80 / 20 | 4 | 31 | 12 | 6 |
| 92 | 69 | 54 / 15 | 3 | 26 | 18 | 0 |
| 93 | 85 | 75 / 10 | 13 | 40 | 11 | 0 |
| 94 | 45 | 21 / 24 | 3 | 25 | 15 | 0 |

Les « expirent » sont les règles tirées d'un avis annuel 2026. Les 14 réserves du 77 (31/12/2027) et les règles migrateurs 92/93 (31/12/2027, arrêté IDF-2026-01-19-00001 « valables 2026 à 2027 ») sont dans les délais.

## 3. Lignes à problème, par département
Chemin des fichiers : `Packages/Core/Sources/Core/Resources/regles/<dép>.json`.

### 75 (Paris)
| Fichier : id | Ce que dit le JSON | Ce que dit la source | Verdict |
|---|---|---|---|
| 75.json : 75-bro-taille, 75-san-taille, 75-bla-taille | candidats 50/60, 40/50, 30/40, « vérifie l'arrêté » | AP 75-2025-02-26-00012 art. 9 : « 0,50 mètre pour le brochet… » (recueil 75-2025-126, URL ci-dessous) ; avis 2026 : « 0,40 m pour le black-bass, 0,50 m pour le sandre et 0,60 m pour le brochet » | DIFFÉRENTE (deux textes, assumé dans le JSON) |
| 75.json : 15 règles issues de l'avis (t4, t5, t7) dont 75-bro-ouv-2026, 75-bro-ferme-2026, 75-omb-*, 75-fario-*, 75-interdit-migrateurs, 75-interdit-ecrevisses | version « avis fait à Paris le 16/01/2026 » | l'avis porte « Fait à Paris, le 15 JAN. 2026 » (image page 2) | DIFFÉRENTE (date de métadonnée fausse d'un jour, règle exacte) |
| même 15 règles | `expire_le` 2026-12-31 | avis annuel 2026 | EXPIRE (31/12/2026, voulu) |
| 75.json : 75-fario-ouv-2026, 75-fario-ferme-2026-automne, -hiver | début 14 ou 21 mars | avis : « Truites fario Du 21 mars au 20 septembre 2026 inclus » ; Code et AP : 2e samedi de mars = 14 mars | DIFFÉRENTE (juste signalé « incertain ») |
| 75.json : 75-consom-canaux-st-martin-st-denis, 75-res-bassin-arsenal | consommation interdite aux canaux ; réserve Arsenal | seule la page fédération le dit ; l'avis ne cite que « la Seine et le canal de l'Ourcq » | SOURCE INTROUVABLE (arrêté de 2010 et de réserves non lus) |
| 75.json : 75-car-nuit-ailleurs | « autorise : non » | l'AP art. 8 ne dit pas « ailleurs interdit » ; c'est une déduction | SOURCE INTROUVABLE |
Confirmées par le texte : quotas 3 dont 2 brochets, 10 salmonidés, zone de 50 m des ouvrages, remise à l'eau du brochet 14/03-24/04, carpe de nuit îles Saint-Louis, Cité et aux Cygnes, horaires, anguille.
URL AP : https://www.prefectures-regions.gouv.fr/irecontenu/telechargement/125632/928907/file/recueil-75-2025-126-recueil-des-actes-administratifs-special%20du%2027.02.2025.pdf ; avis : http://www.federation-peche-paris.fr/cms_viewFile.php?idtf=54984&path=Avis-annuel-75-2026.pdf

### 77 (Seine-et-Marne)
| Fichier : id | Ce que dit le JSON | Ce que dit la source | Verdict |
|---|---|---|---|
| 77.json : 77-carpe-carpe-nuit-seine-lot-s-1, -lot-s-2, 77-carpe-nuit-seine-autres-especes-interdit, -remise-eau, -embarcation-sans-feu, -aval-ecluses | `expire_le` 2026-06-27 (enduro Voulzie 20 au 27 juin) | AP 2026/DDT/SEPR/181 du 02/06/2026 (même période) | EXPIRE (périmées depuis le 27/06 ; le moteur les passe en « vérifie ») : à retirer du paquet |
| 77.json : 77-toutes-especes-interdit-etangs-communaux-liverdy | interdit « depuis le 21 août 2026, jusqu'à nouvel ordre », pas de `expire_le` | arrêté municipal 2026 A 14 AG : « La pratique de la pêche interdite jusqu'à nouvel ordre » (canicule, art. 1 et 3) | EXPIRE (mesure temporaire de canicule, 2 mois après, levée probable non vérifiable ; reste « interdit » à vie dans l'app) |
| 77.json : 77-brochet/sandre/perche/black-bass/carpe-no-kill-loing-bourgogne-moret | `no_kill` « remise à l'eau obligatoire » | guide fédération 2026 : « Parcours no-kill entre les écluses de Bourgogne et de Moret. Remise à l'eau des brochets, sandres, perches, black-bass et carpes. » | CONFIRMÉE (citation) mais source non réglementaire : l'obligation légale n'est pas démontrée |
| 77.json : 77-categorie-2-coupvray | 2e catégorie | avis annuel de la fédération « non signé » | SOURCE INTROUVABLE (aucun arrêté) |
| 77.json : 12 règles de l'arrêté 2025/DDT/SEPR/262 (quotas 6 salmonidés, 3 carnassiers dont 1 brochet, sandre ouvert 1-25/01 et 25/04-31/12) | `expire_le` 2026-12-31 | arrêté signé le 22/12/2025, « Vaux-le-Pénil, le 22 DEC. 2025 » | EXPIRE (31/12/2026, voulu) |
Confirmées : tailles 60 / 50 / 40 (AP 2023/DDT/SEPR/297 art. 8 : « 0,60 m pour le brochet… en première et deuxième catégorie », lu, 0,40 black-bass après OCR), 14 réserves valables du 01/01/2023 au 31/12/2027, saumon, alose, civelle.
Remarque : 77 est le seul département où 60/50/40 est écrit dans un arrêté signé : ces tailles sont fondées en droit.
URL : https://www.federationpeche77.fr/cms_viewFile.php?idtf=41351&path=AP-reglementation-permanente-2024.pdf (AP 2023) ; ...idtf=55786&path=ARP_DDT-181-OPEN-VOULZIE_2026.pdf ; ...idtf=57068&path=AM-Interdiction-peche-liverdy.pdf ; ...idtf=52176&path=guide-de-peche-2026.pdf

### 92 (Hauts-de-Seine)
| Fichier : id | Ce que dit le JSON | Ce que dit la source | Verdict |
|---|---|---|---|
| 92.json : 92-brochet-taille-min-ap, 92-sandre-taille-min-ap, 92-black-bass-taille-min-ap | candidats 50/60, 40/50, 30/40 | AP DCL/BEICEP 2025-87 art. 9 : « 0,50 mètre pour le brochet », « 0,40 mètre pour le sandre dans les eaux de la 2e catégorie », « 0,30 mètre pour le black - bass » (lu) ; avis 2026 « 0,40 m pour le black-bass, 0,50m pour le sandre et 0,60m pour le brochet » | DIFFÉRENTE (deux textes, assumé) |
| 92.json : 92-toutes-reserve-barrage-suresnes | réserve « arrêté n° 2016-166 du 26 septembre 2016 » | AP art. 4 : réserves « pour une durée de cinq ans » ; la fédération cite « n°2017-256 du 06/12/2017 » | DIFFÉRENTE (deux arrêtés cités ; une réserve de 2016 ou 2017 a pu expirer ; restriction, donc risque faible) |
| 92.json : 92-toutes-reserve-fede-port-nanterre, -port-gennevilliers | réserve de pêche | extrait fédération : « - Port de Nanterre ; » sans arrêté | SOURCE INTROUVABLE (aucun texte légal) |
| 92.json : 92-truite-fario-ouverture-avis / -ap (et omble ×4) | 21 mars (avis) ou 14 mars (AP) | AP : « deuxième samedi de mars… »; avis : « Du 21 mars au 20 septembre 2026 inclus » | DIFFÉRENTE (signalée) |
| 92.json : 18 règles issues de l'avis (13/01/2026, confirmé) | `expire_le` 2026-12-31 | avis annuel | EXPIRE (31/12/2026, voulu) |
| 92.json : 92-grande-alose / alose-feinte (-ap et -avis) | AP : interdite « jusqu'au barrage de Suresnes » ; avis : toute l'année | les deux textes lus | DIFFÉRENTE (deux règles coexistent, la plus stricte gagne) |
Confirmées : brochet 1er/01-dernier dimanche de janvier (25/01/2026) et dernier samedi d'avril (25/04), ombre 3e samedi de mai (16/05), quotas 3 et 2, interdictions d'introduction, 50 m des ouvrages.
URL : https://www.hauts-de-seine.gouv.fr/contenu/telechargement/26427/184827/file/a-+AP+permanent+peche+2025_92.pdf ; avis https://www.hauts-de-seine.gouv.fr/contenu/telechargement/27963/193592/file/Avis+annuelle+p%C3%AAche+2026_92.pdf

### 93 (Seine-Saint-Denis)
| Fichier : id | Ce que dit le JSON | Ce que dit la source | Verdict |
|---|---|---|---|
| 93.json : 93-2151-taille_min-avis | brochet `cm: 60` seul, statut incertain, aucune règle 50 cm | AP 2025-0988 art. 9 : « 0,50 mètre pour le brochet » (image) ; avis : « 0,60m pour le brochet » | DIFFÉRENTE (75, 92, 94 ont `candidats_cm` 50/60, pas 93 ; ici le moteur affiche « vérifie » pour tout brochet, même de 70 cm : prudent mais incohérent) |
| 93.json : 93-2195-taille_min-arrete, 93-2053-taille_min-arrete | candidats 40/50 et 30/40 | AP : « 0,40 mètre pour le sandre… », « 0,30 mètre pour le black – bass » | DIFFÉRENTE (deux textes, assumé) |
| 93.json : 11 règles issues de l'avis (15/01/2026, confirmé) | `expire_le` 2026-12-31 | avis annuel | EXPIRE (31/12/2026, voulu) |
| 93.json : 93-ecrevisse-taille-min-ap | 9 cm | AP image : « 0,09 mètre pour les écrevisses » (l'OCR lisait 0,08, erreur de lecture) | CONFIRMÉE |
Confirmées : les 13 tailles (huchon 70, cristivomer 35, ombre et corégone 30, lamproies 20/40, mulet 20, grenouilles 8), quotas, réserves.
URL : https://web.archive.org/web/20250708031705id_/https://www.drieat.ile-de-france.developpement-durable.gouv.fr/IMG/pdf/93_ap_2025-0988_du_03_mars_2025.pdf ; avis http://www.federation-peche-paris.fr/cms_viewFile.php?idtf=54986&path=Avis-annuel-93-2026.pdf
Note : l'avis 93 cite pour la consommation « arrêté préfectoral n°2010-1334 du 7 juin 2010 » (Seine et canal de l'Ourcq) ; non relu dans le JSON ligne par ligne.

### 94 (Val-de-Marne)
| Fichier : id | Ce que dit le JSON | Ce que dit la source | Verdict |
|---|---|---|---|
| 94.json : 94-bro-taille, 94-san-taille, 94-bla-taille | candidats 50/60, 40/50, 30/40 | AP 2025/00727 art. 9 (OCR, recopie de R436-18) ; avis : « 0,40 m pour le black-bass, 0,50m pour le sandre et 0,60m pour le brochet » | DIFFÉRENTE (deux textes, assumé) |
| 94.json : 15 règles issues de l'avis | avis « vers le 10/02/2026 » ; expire 2026-12-31 | image : « Fait à Créteil, le 10 FEV. 2026 » | CONFIRMÉE (date) ; EXPIRE le 31/12/2026 (voulu) |
| 94.json : 94-fario-* | 14 ou 21 mars | idem 75 | DIFFÉRENTE (signalée) |
| 94.json : 94-cat-plans-eau-canaux, 94-car-nuit-lac-creteil, réserves (liste fédération) | plans d'eau et canaux en 2e catégorie ; lac de Créteil | seule la fédération le dit ; l'arrêté ne classe que les cours d'eau, parties du lac « dans les parties du plan d'eau autorisées » | SOURCE INTROUVABLE (règlement de la base de loisirs non lu) |
URL : https://www.drieat.ile-de-france.developpement-durable.gouv.fr/IMG/pdf/94_ap_peche_permanente_no2025_00727_du_25_02_25.pdf ; avis http://www.federation-peche-paris.fr/cms_viewFile.php?idtf=54987&path=Avis-annuel-94-2026.pdf
Note : 24 des 45 règles du 94 sont `incertain` (18 réserves de la fédération, sans arrêté).

## 4. Total des lignes à problème (hors les « voulu »)
- EXPIRE : 6 (77 enduro, déjà périmées) + 1 (77 Liverdy, temporaire sans fin) ; plus 71 règles d'avis 2026 qui expirent le 31/12/2026 (voulu, 15+12+18+11+15).
- DIFFÉRENTE : tailles brochet/sandre/black-bass dans 75, 92, 93, 94 (12 règles, assumé) ; 93 brochet incohérent (1) ; fario 14/21 mars (75, 92, 94, 93) ; réserve Suresnes (2) ; dates d'avis du 75 (15 règles, métadonnée).
- SOURCE INTROUVABLE : 75 (3), 77 (1 + 5 no-kill de source non réglementaire), 92 (2), 94 (3), plus l'arrêté permanent 2026 éventuel.
- CONFIRMÉE : toutes les autres (le reste).

## 5. Recommandation par département
- 75 : partir tel quel, sauf passer à « vérifie l'arrêté » 75-consom-canaux-st-martin-st-denis, 75-res-bassin-arsenal, 75-car-nuit-ailleurs (déjà `incertain`). Corriger la date de l'avis (15/01).
- 77 : partir après retrait des 6 règles enduro, et passer Liverdy, les 5 no-kill et 77-categorie-2-coupvray à « vérifie l'arrêté ». Le reste (tailles 60/50/40, réserves, quotas) tient.
- 92 : partir tel quel, sauf 92-toutes-reserve-barrage-suresnes (deux arrêtés cités, durée de 5 ans) et les 2 réserves de port (fédération seule) à « vérifie l'arrêté ».
- 93 : passer 93-2151-taille_min-avis à `candidats_cm` 50/60 comme les autres départements (aujourd'hui « vérifie » pour tout brochet) ; le reste part tel quel.
- 94 : partir tel quel, sauf les 3 lignes plans d'eau/lac/réserves de la fédération à « vérifie l'arrêté ».
- Tous : tant qu'on n'a pas retrouvé (ou écarté) un arrêté permanent signé en 2026, afficher en base « source : arrêté de 2025 » ; l'expiration 31/12/2026 des avis est déjà gérée par le moteur. Pour écrire « relue par une personne », il faut que quelqu'un remplisse `verifie_par` : cette relecture est faite par script et lecture, pas par une personne nommée.

Décision pour Adem : option a (recommandée, défaut) partir avec les corrections ci-dessus et la mention « relue par script, pas par une personne » ; option b : attendre qu'une personne signe `verifie_par` (écartée : bloque tout pour des lignes déjà confirmées par le texte).
