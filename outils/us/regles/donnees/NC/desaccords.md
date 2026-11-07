# NC : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py NC` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 49 règles (9 incertain) ; lecture B : 44 règles (22 incertain).
- Confirmées par les deux : 21, dont 10 sans réserve (chargées dans l'app) et 11 incertaines (non chargées).
- À vérifier : seulement A 29, seulement B 29.
- Désaccords listés : 57 — (i) forme sans conséquence : 10, (ii) conflit de fond : 0, (iii) couverture : 21, (iv) incertain d'un côté : 26.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (10)

1. **A et B seules** — portée « Impounded inland waters and their tributaries (hors exceptions listées) » / « Inland impoundments and tributaries »
   - A : `NC-stb-taille_min-impoundments` taille_min Striped Bass (Impounded inland waters and their tributaries (hors exceptions listées)) {"pouces": 20}
     > Impounded inland waters and their tributaries except those listed below: 20-inch minimum 4 in combination
   - B : `nc-b-006` taille_min Striped bass (Inland impoundments and tributaries) {"pouces": 20}
     > Striped Bass And Bodie Bass (Striped Bass Hybrid) | Inland Impoundments And Tributaries | Impounded inland waters and their tributaries except those listed below: | 20-inch minimum | 4 in combination
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
2. **A et B seules** — portée « Impounded inland waters and their tributaries (hors exceptions listées) » / « Inland impoundments and tributaries »
   - A : `NC-stb-limite_jour-impoundments` limite_jour Striped Bass (Impounded inland waters and their tributaries (hors exceptions listées)) {"nombre": 4}
     > Impounded inland waters and their tributaries except those listed below: 20-inch minimum 4 in combination
   - B : `nc-b-007` limite_jour Striped bass (Inland impoundments and tributaries) {"nombre": 4}
     > Striped Bass And Bodie Bass (Striped Bass Hybrid) | Inland Impoundments And Tributaries | Impounded inland waters and their tributaries except those listed below: | 20-inch minimum | 4 in combination
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
3. **A et B seules** — portée « Impounded inland waters and their tributaries (hors exceptions listées) » / « Inland impoundments and tributaries »
   - A : `NC-hyb-taille_min-impoundments` taille_min Hybrid Striped (Bodie) (Impounded inland waters and their tributaries (hors exceptions listées)) {"pouces": 20}
     > Impounded inland waters and their tributaries except those listed below: 20-inch minimum 4 in combination
   - B : `nc-b-008` taille_min Striped bass hybrid (Bodie bass) (Inland impoundments and tributaries) {"pouces": 20}
     > Striped Bass And Bodie Bass (Striped Bass Hybrid) | Inland Impoundments And Tributaries | Impounded inland waters and their tributaries except those listed below: | 20-inch minimum | 4 in combination
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
4. **A et B seules** — portée « Impounded inland waters and their tributaries (hors exceptions listées) » / « Inland impoundments and tributaries »
   - A : `NC-hyb-limite_jour-impoundments` limite_jour Hybrid Striped (Bodie) (Impounded inland waters and their tributaries (hors exceptions listées)) {"nombre": 4}
     > Impounded inland waters and their tributaries except those listed below: 20-inch minimum 4 in combination
   - B : `nc-b-009` limite_jour Striped bass hybrid (Bodie bass) (Inland impoundments and tributaries) {"nombre": 4}
     > Striped Bass And Bodie Bass (Striped Bass Hybrid) | Inland Impoundments And Tributaries | Impounded inland waters and their tributaries except those listed below: | 20-inch minimum | 4 in combination
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
5. **A et B seules** — nombres {'hamecons_max': 1.0} / {}; code leurres_artificiels_hamecon_simple / leurre_artificiel_hamecon_simple
   - A : `NC-trout-wild-appat` engin Trout (Wild Trout Waters (Public Mountain Trout Waters)) {"code": "leurres_artificiels_hamecon_simple", "hamecons_max": 1}
     > Only artificial lures with one single hook may be used.
   - B : `nc-b-030` engin Trout (Wild Trout Waters) {"code": "leurre_artificiel_hamecon_simple"}
     > Only artificial lures with one single hook may be used.
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
6. **A et B seules** — nombres {'hamecons_max': 1.0} / {}; code mouches_leurres_artificiels_hamecon_simple / leurre_artificiel_hamecon_simple; portée « Catch and Release/Artificial Flies and Lures Only Trout Waters (Public Mountain Trout Waters) » / « Wild Trout Waters »
   - A : `NC-trout-cr-engin` engin Trout (Catch and Release/Artificial Flies and Lures Only Trout Waters (Public Mountain Trout Waters)) {"code": "mouches_leurres_artificiels_hamecon_simple", "hamecons_max": 1}
     > may be fished only with artificial flies and lures having one single hook.
   - B : `nc-b-030` engin Trout (Wild Trout Waters) {"code": "leurre_artificiel_hamecon_simple"}
     > Only artificial lures with one single hook may be used.
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
7. **A seule (B appariée est confirmée ailleurs)** — portée « Undesignated waters containing mountain trout » / « Hatchery Supported Trout Waters »
   - A : `NC-trout-nondesignees-limite_jour` limite_jour Trout (Undesignated waters containing mountain trout) {"nombre": 7}
     > there is no size limit or bait restrictions and the creel limit is seven trout per day, with no closed season.
   - B : `nc-b-025` limite_jour Trout (Hatchery Supported Trout Waters) {"nombre": 7}
     > In Hatchery Supported Trout Waters there is no size limit or bait restriction, and the creel limit is seven trout per day.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
8. **A et B seules** — code peche_a_l_arrache / peche_au_harponnage_interdite
   - A : `NC-gen-pas-arrachage` interdit toutes (État) {"code": "peche_a_l_arrache"}
     > It is unlawful to snag fish by pulling or jerking a device equipped with one or more hooks through the water for the purpose of impaling fish.
   - B : `nc-b-039` interdit toutes (État) {"code": "peche_au_harponnage_interdite"}
     > It is unlawful to snag fish by pulling or jerking a device equipped with one or more hooks through the water for the purpose of impaling fish.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
9. **A et B seules** — type appat / interdit; code pas_appat_vivant_palangre_ligne_dormante / appat_vivant_interdit_palangre_flotteur
   - A : `NC-gen-palangre-appat-vivant` appat toutes (État) {"code": "pas_appat_vivant_palangre_ligne_dormante"}
     > It is unlawful to use live bait with trotlines, set-hooks or jug-hooks.
   - B : `nc-b-043` interdit toutes (État) {"code": "appat_vivant_interdit_palangre_flotteur"}
     > It is unlawful to use live bait with trotlines, set-hooks or jug-hooks.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
10. **A et B seules** — portée « Undesignated waters containing mountain trout » / « Undesignated trout waters »
   - A : `NC-trout-nondesignees-limite_jour` limite_jour Trout (Undesignated waters containing mountain trout) {"nombre": 7}
     > there is no size limit or bait restrictions and the creel limit is seven trout per day, with no closed season.
   - B : `nc-b-035` limite_jour Trout (Undesignated trout waters) {"nombre": 7}
     > Undesignated TROUT WATERS | No closed season | None | 7 | None
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée

## (iii) couverture (21)

1. **A seule** — lue par A seulement
   - A : `NC-crappie-8po-ouest-I77` taille_min Crappie (Public waters west of I-77, except Lake Chatuge (Clay Co.)) {"pouces": 8}
     > All public waters west of I-77, except Lake Chatuge (Clay Co.) 8-inch minimum 20 in combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement
   - A : `NC-crappie-20-ouest-I77` limite_jour Crappie (Public waters west of I-77, except Lake Chatuge (Clay Co.)) {"nombre": 20}
     > All public waters west of I-77, except Lake Chatuge (Clay Co.) 8-inch minimum 20 in combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement
   - A : `NC-stb-declaration-recolte` autre Striped Bass (État) {}
     > State law requires any person to report recreational harvests of the following species from inland or joint fishing waters that are adjacent to coastal fishing waters:
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement
   - A : `NC-sauger-taille_min` taille_min Sauger (État) {"pouces": 15}
     > Sauger All public fishing waters 15-inch minimum 8
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement
   - A : `NC-sauger-limite_jour` limite_jour Sauger (État) {"nombre": 8}
     > Sauger All public fishing waters 15-inch minimum 8
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement
   - A : `NC-trout-dh-fermeture-recolte` relacher Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2026-10-01→2027-06-04 {"code": "aucune_truite_possedee"}
     > Oct. 1, 2026 – June 4, 2027 **No trout may be possessed
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement
   - A : `NC-trout-cr-relacher` relacher Trout (Catch and Release/Artificial Flies and Lures Only Trout Waters (Public Mountain Trout Waters)) {"code": "aucune_truite_recoltee_ni_possedee"}
     > No trout may be harvested or possessed while fishing these streams.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement
   - A : `NC-trout-engin-ligne` engin Trout (Public Mountain Trout Waters) {"code": "ligne_et_hamecon_seulement"}
     > Fishing is limited to hook and line only.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement
   - A : `NC-trout-appat-prelevement` appat Trout (Public Mountain Trout Waters) {"code": "pas_de_prelevement_appats_poissons_fourrage"}
     > It is unlawful to take fish bait or bait fish from Public Mountain Trout Waters.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **A seule** — lue par A seulement
   - A : `NC-gen-possession-conforme` autre toutes (État) {}
     > It is unlawful to possess fish whose size, creel or season restrictions are not in compliance with the regulations on the waters being fished.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
11. **A seule** — lue par A seulement
   - A : `NC-gen-mesure` autre toutes (État) {}
     > Fish length is determined by measuring along a straight line (not along the curvature of the body) the distance from the tip of the closed mouth to the tip of the compressed caudal (tail) fin.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
12. **A seule** — lue par A seulement
   - A : `NC-gen-palangre-truite` engin toutes (Public Mountain Trout Waters) {"code": "palangre_interdite_eaux_truite"}
     > No trotlines, set-hooks or jug-hooks may be used in Public Mountain Trout Waters, except impounded waters of power reservoirs and municipal water supply reservoirs open to the public for fishing.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
13. **A seule** — lue par A seulement
   - A : `NC-sturgeon-possession` interdit Sturgeon (État) {"code": "aucun_esturgeon_possede"}
     > Sturgeon All inland fishing waters and joint fishing waters when caught by hook and line No sturgeon may be possessed.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
14. **A seule** — lue par A seulement
   - A : `NC-whiteperch-vivant-ouest` interdit White Perch (In and west of Buncombe, Haywood, and Rutherford counties) {"code": "perche_blanche_vivante_possession_transport_relache"}
     > All public fishing waters in and west of Buncombe, Haywood, and Rutherford counties No live white perch may be possessed, transported or released.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
15. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `nc-b-010` fermeture Striped bass (Central-Southern Striped Bass Management Area (inland and joint waters)) {"code": "striped_bass_aucune_possession_central_sud"} [incertain]
     > No striped bass may be possessed.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
16. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `nc-b-011` saison Striped bass, Striped bass hybrid (Bodie bass) (Tar-Pamlico and Neuse rivers upstream of the defined lines (inland and joint)) 04-01→04-30 {} [incertain]
     > 18-inch minimum, no fish possessed may be between 22 and 27 inches | 1 in combination (April 1 - April 30) Unless Changed by Proclamation
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
17. **B seule** — lue par B seulement
   - A : —
   - B : `nc-b-019` engin Channel catfish, Blue catfish (Game lands ponds) {"code": "ligne_et_hamecon_seulement_etangs_game_lands"}
     > In all game lands ponds, channel, white, and blue catfish may be taken only by hook and line, and the daily creel limit is seven channel catfish and 10 white catfish.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
18. **B seule** — lue par B seulement
   - A : —
   - B : `nc-b-020` limite_jour Channel catfish (Game lands ponds) {"nombre": 7}
     > In all game lands ponds, channel, white, and blue catfish may be taken only by hook and line, and the daily creel limit is seven channel catfish and 10 white catfish.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
19. **B seule** — lue par B seulement
   - A : —
   - B : `nc-b-037` interdit Trout (Catch and Release / Artificial Flies and Lures Only Trout Waters) {"code": "catch_and_release_aucune_truite_possedee"}
     > No closed season **No trout may be possessed
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
20. **B seule** — lue par B seulement
   - A : —
   - B : `nc-b-040` interdit toutes (État) {"code": "vente_interdite_game_fish"}
     > The purchase and sale of inland game fish are unlawful, except from and by licensed commercial trout ponds and fish propagators.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
21. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `nc-b-042` engin toutes (upstream of the U.S. 258 bridge) 04-01→06-30 {"code": "roanoke_circulaire_sans_ardillon"} [incertain]
     > In the inland waters of the Roanoke River upstream of the U.S. 258 bridge, only a single barbless circle hook may be used when fishing with live or natural bait
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (26)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-lmb-taille_min-defaut` taille_min Largemouth Bass (État) {"pouces": 14}
     > Largemouth Bass All public waters except those listed below: 14-inch minimum, except 2 may be less than 14 inches 5, including only 2 less than 14 inches
   - B : `nc-b-001` taille_min Largemouth bass (État) {"pouces": 14} [incertain]
     > Largemouth Bass | All public waters except those listed below: | 14-inch minimum, except 2 may be less than 14 inches | 5, including only 2 less than 14 inches
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-smb-taille_min-defaut` taille_min Smallmouth Bass (État) {"pouces": 14}
     > Smallmouth Bass All public waters except those listed below: 14-inch minimum, except 2 may be less than 14 inches 5, including only 2 less than 14 inches
   - B : `nc-b-003` taille_min Smallmouth bass (État) {"pouces": 14} [incertain]
     > Smallmouth Bass | All public waters except those listed below: | 14-inch minimum, except 2 may be less than 14 inches | 5, including only 2 less than 14 inches
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-spb-defaut-aucune` autre Spotted Bass (État) {} [incertain]
     > Alabama Bass And Spotted Bass All public waters except those listed below: None None
   - B : `nc-b-005` autre Spotted bass, Alabama bass (État) {} [incertain]
     > Alabama Bass And Spotted Bass | All public waters except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-sunfish-defaut-aucune` autre Sunfish (État) {} [incertain]
     > Sunfish (Except Crappie, Rock Bass, & Roanoke Bass) All public fishing waters except those listed below: None None
   - B : `nc-b-015` autre Bluegill, Sunfish (other Centrarchidae) (État) {} [incertain]
     > Sunfish (Except Crappie, Rock Bass, & Roanoke Bass) | All public fishing waters except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-perch-defaut-aucune` autre Yellow Perch (État) {} [incertain]
     > Yellow Perch All inland and joint fishing waters None None
   - B : `nc-b-017` autre Yellow perch (État) {} [incertain]
     > Yellow Perch | All inland and joint fishing waters | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
6. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-channel-defaut-aucune` autre Channel Catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: None None
   - B : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) | All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
7. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-blue-defaut-aucune` autre Blue Catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: None None
   - B : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) | All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
8. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-flathead-defaut-aucune` autre Flathead Catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: None None
   - B : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) | All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
9. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-trout-dh-recolte-ete-2026` limite_jour Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2026-08-01→2026-09-30 {"nombre": 7}
     > Aug. 1, 2026 – Sept. 30, 2026 None 7 None
   - B : `nc-b-034` limite_jour Trout (Delayed Harvest Trout Waters) {"nombre": 7} [incertain]
     > Aug. 1, 2026 - Sept. 30, 2026 | None | 7 | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
10. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NC-trout-dh-recolte-juin-2027` limite_jour Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2027-06-05→2027-07-31 {"nombre": 7}
     > June 5, 2027 – July 31, 2027 (Note: youth under 16 years old only fishing from 6:00 a.m. until noon on June 5, 2027) None 7 None
   - B : `nc-b-034` limite_jour Trout (Delayed Harvest Trout Waters) {"nombre": 7} [incertain]
     > Aug. 1, 2026 - Sept. 30, 2026 | None | 7 | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
11. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `NC-crappie-defaut-aucune` autre Crappie (État) {} [incertain]
     > Crappie (Black And White) All public fishing waters except those listed below: None None
   - B : `nc-b-014` autre Black crappie, White crappie (État) {} [incertain]
     > Crappie (Black And White) | All public fishing waters except those listed below: | None | None
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
12. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['black crappie', 'white crappie']
   - A : `NC-crappie-defaut-aucune` autre Crappie (État) {} [incertain]
     > Crappie (Black And White) All public fishing waters except those listed below: None None
   - B : `nc-b-014` autre Black crappie, White crappie (État) {} [incertain]
     > Crappie (Black And White) | All public fishing waters except those listed below: | None | None
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
13. **A et B seules** — espèces ['sunfish'] / ['bluegill', 'sunfish']; portée « Public waters east of I-95, except Tar River Reservoir (Nash Co.), and listed rivers » / « Eastern rivers and public waters east of I-95 (listed) »
   - A : `NC-sunfish-30-listees` limite_jour Sunfish (Public waters east of I-95, except Tar River Reservoir (Nash Co.), and listed rivers) {"nombre": 30} [incertain]
     > All public waters east of I-95, except Tar River Reservoir (Nash Co.) None 30 in combination, including no more than 12 redbreast sunfish
   - B : `nc-b-016` limite_jour Sunfish (other Centrarchidae), Bluegill (Eastern rivers and public waters east of I-95 (listed)) {"nombre": 30} [incertain]
     > 30 in combination, including no more than 12 redbreast sunfish
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
14. **A et B seules** — code peche_fermee_hs_mars / hatchery_supported_ferme_mars_a_avril; portée « Hatchery Supported Trout Waters not listed below (Public Mountain Trout Waters) » / « Hatchery Supported Trout Waters »
   - A : `NC-trout-hs-fermeture-mars` fermeture Trout (Hatchery Supported Trout Waters not listed below (Public Mountain Trout Waters)) 2027-03-01→2027-04-02 {"code": "peche_fermee_hs_mars"} [incertain]
     > March 1, 2027 – April 2, 2027 **No fishing allowed All Hatchery Supported Trout Waters not listed below
   - B : `nc-b-027` fermeture Trout (Hatchery Supported Trout Waters) 2027-03-01→2027-04-02 {"code": "hatchery_supported_ferme_mars_a_avril"} [incertain]
     > March 1, 2027 - April 2, 2027 **No fishing allowed
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
15. **A et B seules** — type appat / interdit; dates ('10-01', '06-04') / (None, None); code pas_appat_naturel / appat_naturel_interdit_wild_trout; portée « Delayed Harvest Trout Waters (Public Mountain Trout Waters) » / « Wild Trout Waters »
   - A : `NC-trout-dh-appat` appat Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2026-10-01→2027-06-04 {"code": "pas_appat_naturel"}
     > Artificial lures with a single hook. Natural bait may not be possessed.
   - B : `nc-b-031` interdit Trout (Wild Trout Waters) {"code": "appat_naturel_interdit_wild_trout"} [incertain]
     > Artificial lures with a single hook. Natural bait may not be possessed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
16. **A et B seules** — type autre / limite_possession; nombres {} / {'nombre': 3.0}
   - A : `NC-gen-possession-3jours` autre toutes (État) {}
     > It is unlawful to possess more than the daily creel limit while fishing, boating or afield; or to possess at any place more than three days’ creel limit.
   - B : `nc-b-041` limite_possession toutes (État) {"nombre": 3} [incertain]
     > It is unlawful to possess more than the daily creel limit while fishing, boating or afield; or to possess at any place more than three days' creel limit.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
17. **A et B seules** — nombres {'nombre': 70.0} / {'hamecons_max': 3.0}; code jug_hooks_max_par_bateau / ligne_fixe_ou_flotteur_trois_hamecons
   - A : `NC-gen-jug-hooks-70` engin toutes (État) {"code": "jug_hooks_max_par_bateau", "nombre": 70}
     > The number of jug-hooks that may be fished is limited to 70 per boat.
   - B : `nc-b-044` engin toutes (État) {"hamecons_max": 3, "code": "ligne_fixe_ou_flotteur_trois_hamecons"} [incertain]
     > The number of jug-hooks that may be fished is limited to 70 per boat.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
18. **B seule (A appariée est confirmée ailleurs)** — espèces ['spotted bass'] / ['alabama bass', 'spotted bass']
   - A : `NC-spb-defaut-aucune` autre Spotted Bass (État) {} [incertain]
     > Alabama Bass And Spotted Bass All public waters except those listed below: None None
   - B : `nc-b-005` autre Spotted bass, Alabama bass (État) {} [incertain]
     > Alabama Bass And Spotted Bass | All public waters except those listed below: | None | None
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
19. **B seule (A appariée est confirmée ailleurs)** — type limite_jour / autre; nombres {'nombre': 10.0} / {}
   - A : `NC-wb-limite_jour` limite_jour White Bass (État) {"nombre": 10}
     > White Bass All inland fishing waters and joint fishing waters when caught by hook and line None 10
   - B : `nc-b-013` autre White bass (État) {} [incertain]
     > White Bass | All inland fishing waters and joint fishing waters when caught by hook and line | None | 10
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
20. **B seule (A appariée est confirmée ailleurs)** — espèces ['flathead catfish'] / ['blue catfish', 'channel catfish', 'flathead catfish']
   - A : `NC-flathead-defaut-aucune` autre Flathead Catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: None None
   - B : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
     > Catfish (Blue, Channel, & Flathead) | All inland fishing waters and joint fishing waters when caught by hook and line except those listed below: | None | None
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
21. **B seule (A appariée est confirmée ailleurs)** — type limite_jour / autre; nombres {'nombre': 8.0} / {}
   - A : `NC-walleye-limite_jour-defaut` limite_jour Walleye (État) {"nombre": 8}
     > Walleye All public fishing waters except those listed below: None 8
   - B : `nc-b-022` autre Walleye (État) {} [incertain]
     > Walleye | All public fishing waters except those listed below: | None | 8
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
22. **B seule (A appariée est confirmée ailleurs)** — type limite_jour / autre; nombres {'nombre': 7.0} / {}
   - A : `NC-trout-hs-limite_jour` limite_jour Trout (Hatchery Supported Trout Waters (Public Mountain Trout Waters)) {"nombre": 7}
     > In Hatchery Supported Trout Waters there is no size limit or bait restriction, and the creel limit is seven trout per day.
   - B : `nc-b-026` autre Trout (Hatchery Supported Trout Waters) {} [incertain]
     > In Hatchery Supported Trout Waters there is no size limit or bait restriction, and the creel limit is seven trout per day.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
23. **A et B seules** — dates ('03-01', '04-02') / ('10-01', None); code peche_fermee_hs_mars / delayed_harvest_recolte_ferme_oct_a_juin; portée « Hatchery Supported Trout Waters not listed below (Public Mountain Trout Waters) » / « Delayed Harvest Trout Waters »
   - A : `NC-trout-hs-fermeture-mars` fermeture Trout (Hatchery Supported Trout Waters not listed below (Public Mountain Trout Waters)) 2027-03-01→2027-04-02 {"code": "peche_fermee_hs_mars"} [incertain]
     > March 1, 2027 – April 2, 2027 **No fishing allowed All Hatchery Supported Trout Waters not listed below
   - B : `nc-b-032` fermeture Trout (Delayed Harvest Trout Waters) 10-01→None {"code": "delayed_harvest_recolte_ferme_oct_a_juin"} [incertain]
     > no trout may be harvested or possessed while fishing these waters between Oct. 1 and 30 minutes after sunset on the Friday before the first Saturday of the following June.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
24. **A et B seules** — dates (None, None) / ('10-01', None); nombres {'hamecons_max': 1.0} / {}; code leurres_artificiels_hamecon_simple / leurre_artificiel_hamecon_simple; portée « Wild Trout Waters (Public Mountain Trout Waters) » / « Delayed Harvest Trout Waters »
   - A : `NC-trout-wild-appat` engin Trout (Wild Trout Waters (Public Mountain Trout Waters)) {"code": "leurres_artificiels_hamecon_simple", "hamecons_max": 1}
     > Only artificial lures with one single hook may be used.
   - B : `nc-b-033` engin Trout (Delayed Harvest Trout Waters) 10-01→None {"code": "leurre_artificiel_hamecon_simple"} [incertain]
     > Delayed Harvest Trout Waters, excluding tributaries except as noted, may be fished only with artificial lures with one single hook, no natural bait may be possessed
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
25. **B seule (A appariée est confirmée ailleurs)** — dates ('08-01', '09-30') / (None, None)
   - A : `NC-trout-dh-recolte-ete-2026` limite_jour Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2026-08-01→2026-09-30 {"nombre": 7}
     > Aug. 1, 2026 – Sept. 30, 2026 None 7 None
   - B : `nc-b-034` limite_jour Trout (Delayed Harvest Trout Waters) {"nombre": 7} [incertain]
     > Aug. 1, 2026 - Sept. 30, 2026 | None | 7 | None
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
26. **B seule (A appariée est confirmée ailleurs)** — nombres {'taille': 7.0} / {'taille': 14.0}; portée « Wild Trout Waters (Public Mountain Trout Waters) » / « from Muddy Creek to Morganton water intake dam »
   - A : `NC-trout-wild-taille_min` taille_min Trout (Wild Trout Waters (Public Mountain Trout Waters)) {"pouces": 7}
     > In all Wild Trout Waters, the minimum length limit is seven inches and the creel limit is four trout per day.
   - B : `nc-b-036` taille_min Trout (from Muddy Creek to Morganton water intake dam) {"pouces": 14} [incertain]
     > Catawba River from Muddy Creek to Morganton water intake dam | 14 inches | 2
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (8)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. espèce d'un groupe — gardée : `NC-spb-defaut-aucune` autre Spotted Bass (État) {} [incertain] ; appui : `nc-b-005` autre Spotted bass, Alabama bass (État) {} [incertain]
2. espèce d'un groupe — gardée : `NC-sunfish-defaut-aucune` autre Sunfish (État) {} [incertain] ; appui : `nc-b-015` autre Bluegill, Sunfish (other Centrarchidae) (État) {} [incertain]
3. espèce d'un groupe — gardée : `NC-channel-defaut-aucune` autre Channel Catfish (État) {} [incertain] ; appui : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
4. espèce d'un groupe — gardée : `NC-blue-defaut-aucune` autre Blue Catfish (État) {} [incertain] ; appui : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
5. espèce d'un groupe — gardée : `NC-flathead-defaut-aucune` autre Flathead Catfish (État) {} [incertain] ; appui : `nc-b-018` autre Channel catfish, Blue catfish, Flathead catfish (État) {} [incertain]
6. valeur datée — gardée : `NC-trout-dh-recolte-ete-2026` limite_jour Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2026-08-01→2026-09-30 {"nombre": 7} [incertain] ; appui : `nc-b-034` limite_jour Trout (Delayed Harvest Trout Waters) {"nombre": 7} [incertain]
7. valeur datée — gardée : `NC-trout-dh-recolte-juin-2027` limite_jour Trout (Delayed Harvest Trout Waters (Public Mountain Trout Waters)) 2027-06-05→2027-07-31 {"nombre": 7} [incertain] ; appui : `nc-b-034` limite_jour Trout (Delayed Harvest Trout Waters) {"nombre": 7} [incertain]
8. espèce d'un groupe — gardée : `nc-b-014` autre Black crappie, White crappie (État) {} [incertain] ; appui : `NC-crappie-defaut-aucune` autre Crappie (État) {} [incertain]
