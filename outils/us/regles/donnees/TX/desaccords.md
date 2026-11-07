# TX : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py TX` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 68 règles (18 incertain) ; lecture B : 64 règles (5 incertain).
- Confirmées par les deux : 37, dont 33 sans réserve (chargées dans l'app) et 4 incertaines (non chargées).
- À vérifier : seulement A 37, seulement B 27.
- Désaccords listés : 59 — (i) forme sans conséquence : 9, (ii) conflit de fond : 1, (iii) couverture : 40, (iv) incertain d'un côté : 9.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (9)

1. **A et B seules** — nombres {} / {'taille_min': 20.0, 'nombre': 10.0}
   - A : `TX-channel_catfish-autre-etat` autre Channel Catfish (État) {}
     > Catfish: Channel, blue, their hybrids & subspecies Daily Bag: 25 (in any combination - only 10 can be 20 inches or greater in length)
   - B : `b-tx-channelcat-gros` autre channel catfish (État) {"nombre": 10, "pouces_min": 20}
     > Catfish: Channel, blue, their hybrids & subspecies Daily Bag: 25 (in any combination - only 10 can be 20 inches or greater in length)
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
2. **A et B seules** — nombres {} / {'taille_min': 20.0, 'nombre': 10.0}
   - A : `TX-blue_catfish-autre-etat` autre Blue Catfish (État) {}
     > Catfish: Channel, blue, their hybrids & subspecies Daily Bag: 25 (in any combination - only 10 can be 20 inches or greater in length)
   - B : `b-tx-bluecat-gros` autre blue catfish (État) {"nombre": 10, "pouces_min": 20}
     > Catfish: Channel, blue, their hybrids & subspecies Daily Bag: 25 (in any combination - only 10 can be 20 inches or greater in length)
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
3. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['black crappie']
   - A : `TX-crappie-limite_jour-etat` limite_jour Crappie (État) {"nombre": 25}
     > Crappie: White, black, their hybrids & subspecies Daily Bag: 25 (in any combination) Minimum Length: 10 inches
   - B : `b-tx-blackcrap-bag` limite_jour black crappie (État) {"nombre": 25}
     > Crappie: White, black, their hybrids & subspecies Daily Bag: 25 (in any combination) Minimum Length: 10 inches
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
4. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['black crappie']
   - A : `TX-crappie-taille_min-etat` taille_min Crappie (État) {"pouces": 10}
     > Crappie: White, black, their hybrids & subspecies Daily Bag: 25 (in any combination) Minimum Length: 10 inches
   - B : `b-tx-blackcrap-min` taille_min black crappie (État) {"pouces": 10}
     > Crappie: White, black, their hybrids & subspecies Daily Bag: 25 (in any combination) Minimum Length: 10 inches
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
5. **A seule (B appariée est confirmée ailleurs)** — type autre / limite_jour; nombres {} / {'nombre': 5.0}
   - A : `TX-walleye-autre-etat` autre Walleye (État) {}
     > Walleye Daily Bag: 5 (only 2 can be less than 16 inches in length) Minimum Length: None
   - B : `b-tx-walleye-bag` limite_jour walleye (État) {"nombre": 5}
     > Walleye Daily Bag: 5 (only 2 can be less than 16 inches in length)
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
6. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['black crappie']
   - A : `TX-crappie-limite_possession-etat` limite_possession Crappie (État) {"nombre": 50}
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - B : `b-tx-blackcrappie-poss` limite_possession black crappie (État) {"nombre": 50}
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
7. **A et B seules** — code hooks_all_devices_fresh_water / max_100_hamecons_eau_douce
   - A : `TX-engin-hamecons_max-100` engin toutes (État) {"hamecons_max": 100, "code": "hooks_all_devices_fresh_water"}
     > In fresh water, it is unlawful to fish with more than 100 hooks on all devices combined.
   - B : `b-tx-100hooks` engin toutes (État) {"hamecons_max": 100, "code": "max_100_hamecons_eau_douce"}
     > In fresh water, it is unlawful to fish with more than 100 hooks on all devices combined.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
8. **A et B seules** — code foul_hooking_snagging_jerking / accrochage_foul_hooking_interdit
   - A : `TX-engin-accrochage` engin toutes (État) {"code": "foul_hooking_snagging_jerking"}
     > It is unlawful to use a pole and line to take, attempt to take, or retain a fish by foul-hooking, snagging, or jerking.
   - B : `b-tx-snag` engin toutes (État) {"code": "accrochage_foul_hooking_interdit"}
     > It is unlawful to use a pole and line to take, attempt to take, or retain a fish by foul-hooking, snagging, or jerking.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
9. **A et B seules** — code bait_fish_west_texas_counties / appats_ouest_liste_fermee; portée « West Texas counties (18 counties) » / « 18 comtés de l'Ouest (Brewster à Winkler) »
   - A : `TX-appat-ouest_texas` appat toutes (West Texas counties (18 counties)) {"code": "bait_fish_west_texas_counties"}
     > the only fishes that may be used or possessed for bait while fishing are common carp, fathead minnows, gizzard and threadfin shad, golden shiners, goldfish, Mexican tetra, Rio Grande cichlid,
   - B : `b-tx-bait-ouest` appat toutes (18 comtés de l'Ouest (Brewster à Winkler)) {"code": "appats_ouest_liste_fermee"}
     > the only fishes that may be used or possessed for bait while fishing are common carp, fathead minnows, gizzard and threadfin shad, golden shiners, goldfish, Mexican tetra, Rio Grande cichlid
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)

## (ii) conflit de fond (1)

1. **A et B seules** — nombres {'hamecons_max': 100.0} / {'hamecons_max': 50.0}; code hooks_all_devices_fresh_water / palangre_max_50_hamecons
   - A : `TX-engin-hamecons_max-100` engin toutes (État) {"hamecons_max": 100, "code": "hooks_all_devices_fresh_water"}
     > In fresh water, it is unlawful to fish with more than 100 hooks on all devices combined.
   - B : `b-tx-trotline-hooks` engin toutes (État) {"hamecons_max": 50, "code": "palangre_max_50_hamecons"}
     > Trotlines in fresh water may not have more than 50 hooks on any one trotline.
   - Avis sur l'outil : juste : deux valeurs différentes

## (iii) couverture (40)

1. **A seule** — lue par A seulement
   - A : `TX-alabama-limite_jour-etat` limite_jour Alabama Bass (État) {"nombre": 5}
     > Spotted, Guadalupe & Alabama bass Daily Bag: 5 fish for any combination of largemouth, smallmouth, Alabama, Guadalupe, and spotted bass.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-sunfish-limite_jour-etat` autre Sunfish (État) {} [incertain]
     > Sunfish: various including bluegill, redear, green, warmouth & longear Daily Bag: No limit Minimum Length: None
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement
   - A : `TX-brown_trout-limite_jour-etat` limite_jour Brown Trout (État) {"nombre": 5}
     > Trout: Rainbow & brown Daily Bag: 5 in any combination Minimum Length: None
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-alligator_gar-limite_jour-etat` limite_jour Alligator Gar (État) {"nombre": 1} [incertain]
     > Gar: Alligator Daily Bag: 1 Minimum Length: None
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-alligator_gar-fermeture-etat` fermeture Alligator Gar (État) {"code": "temporary_spawning_closure"} [incertain]
     > the TPWD Executive Director may temporarily prohibit taking or attempting to take alligator gar in a specified area for a period up to 30 days.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement
   - A : `TX-game_fish-engin-pole_and_line` engin Game fish (État) {"code": "pole_and_line_game_fish"}
     > Game fish may be taken only by pole and line, except as otherwise provided in this guide.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement
   - A : `TX-engin-appareil_main_immerge` engin toutes (État) {"code": "hand_operated_underwater_device_fresh_water"}
     > In fresh water, it is unlawful to take fish with a hand-operated device held underwater except that a spear or spear gun may be used to take nongame fish.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-trotline-hamecons` engin Channel Catfish, Blue Catfish, Flathead Catfish (État) {"code": "trotline_fresh_water", "hamecons_max": 50} [incertain]
     > Trotlines in fresh water may not have more than 50 hooks on any one trotline.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement
   - A : `TX-engin-trotline-longueur` engin toutes (État) {"code": "trotline_mainline_600_ft_spacing_3_ft"}
     > Trotlines may not be used with: a mainline length exceeding 600 feet; hooks spaced less than 3 horizontal feet apart;
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **A seule** — lue par A seulement
   - A : `TX-engin-arc` engin Game fish (État) {"code": "archery_nongame_only"}
     > Lawful archery equipment includes longbow, recurved bow, compound bow and crossbow. May be used to take NONGAME fish only.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
11. **A seule** — lue par A seulement
   - A : `TX-engin-gaff` engin toutes (État) {"code": "gaff_landing_only"}
     > May only be used to aid in the landing of fish caught on other legal devices, means or methods.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
12. **A seule** — lue par A seulement
   - A : `TX-engin-epuisette-lance` engin toutes (État) {"code": "spear_nongame_only"}
     > Spear Any shaft with single or multiple points, barbed or barbless, which may be propelled by any means, but does not include arrows. May be used to take nongame fish only.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
13. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-cast_net` engin toutes (État) {"code": "cast_net_nongame"} [incertain]
     > Cast Net A cast net is a net that can be hand-thrown over an area. Legal only for taking nongame fish and other aquatic animal life including crabs, crayfish, and shrimp.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
14. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-seine` engin toutes (État) {"code": "seine_nongame"} [incertain]
     > Seine A seine is a section of non-metallic mesh webbing, with the top edge buoyed upwards by a floatline and the bottom edge weighted (includes a push net).
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
15. **A seule** — lue par A seulement
   - A : `TX-engin-nasse_vairons` engin toutes (État) {"code": "minnow_trap"}
     > Trap may not exceed 24 inches in length. The throat may not exceed 1 inch by 3 inches.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
16. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-CFL-deux_cannes` engin toutes (Community Fishing Lakes and state park structures) {"code": "two_poles_max_cfl_state_park", "lignes_max": 2} [incertain]
     > Anglers may use no more than two poles while fishing on Deputy Darren Goforth Park Lake, Community Fishing Lakes, and any dock, pier, jetty, or other manmade structure within a state park.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
17. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-trotline-eaux_exclues` engin toutes (Community Fishing Lakes, Lake Bryan and other listed waters) {"code": "trotline_excluded_waters"} [incertain]
     > Trotlines may not be used in the following: Community Fishing Lakes Lake Bryan in Brazos County Reservoirs or sections of rivers lying totally within theboundaries of state park
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
18. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-jugline-eaux_exclues` engin toutes (Community Fishing Lakes, Lake Bryan and other listed waters) {"code": "jugline_excluded_waters"} [incertain]
     > Juglines may not be used in the following: Community Fishing Lakes Lake Bryan in Brazos County Reservoirs or sections of rivers lying totally within theboundaries of state park
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
19. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-throwline-eaux_exclues` engin toutes (Community Fishing Lakes, Lake Bryan and other listed waters) {"code": "throwline_excluded_waters"} [incertain]
     > Throwlines may not be used in the following: Community Fishing Lakes Lake Bryan in Brazos County Reservoirs or sections of rivers lying totally within theboundaries of state park
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
20. **A seule** — lue par A seulement (marquée incertain)
   - A : `TX-engin-guadalupe-truite_leurres` engin Rainbow Trout, Brown Trout (800 yards downstream from the Canyon Dam release to the second bridge crossing on River Road) {"code": "artificial_lures_only_trout_retention"} [incertain]
     > In the Guadalupe River in Comal County starting 800 yards downstream from the Canyon Dam release and extending downstream to the second bridge crossing on River Road,
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
21. **A seule** — lue par A seulement
   - A : `TX-appat-game_fish` appat Game fish (État) {"code": "game_fish_as_bait"}
     > It is unlawful to use any game fish, or part of a game fish, as bait.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
22. **A seule** — lue par A seulement
   - A : `TX-appat-crevettes` appat toutes (État) {"code": "shrimp_native_gulf_only"}
     > only shrimp native to the Gulf of Mexico may be used in Texas waters.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
23. **A seule** — lue par A seulement
   - A : `TX-appat-red_river-possession` appat toutes (Red River below Lake Texoma, Big Cypress Bayou below Lake O' the Pines, Sulphur River below Lake Wright Patman) {"code": "live_bait_fish_possession_leaving_red_river_etc"}
     > It is unlawful to leave the following water bodies in possession of live bait fish caught in those waters: Red River and all tributary waters downstream of Lake Texoma,
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
24. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-largemouthbass-canne` engin largemouth bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
25. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-smallmouthbass-canne` engin smallmouth bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
26. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-spottedbass-canne` engin spotted bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
27. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-guadalupebass-canne` engin guadalupe bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
28. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-whitebass-canne` engin white bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
29. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-stripedbass-canne` engin striped bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
30. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-hybridstripedbass-canne` engin hybrid striped bass (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
31. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-whitecrappie-canne` engin white crappie (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
32. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-blackcrappie-canne` engin black crappie (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
33. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-channelcatfish-canne` engin channel catfish (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
34. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-bluecatfish-canne` engin blue catfish (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
35. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-flatheadcatfish-canne` engin flathead catfish (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
36. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-rainbowtrout-canne` engin rainbow trout (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
37. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-walleye-canne` engin walleye (État) {"code": "canne_et_ligne_seulement"}
     > Game fish may be taken only by pole and line (which includes rod and reel), except as otherwise provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
38. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-tx-multicannes` engin toutes (État) {"code": "plusieurs_cannes"} [incertain]
     > A person may fish with multiple poles or other devices, except as provided in this guide.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
39. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-arc` engin toutes (État) {"code": "arc_poissons_non_gibier_seulement"}
     > Lawful archery equipment includes longbow, recurved bow, compound bow and crossbow. May be used to take NONGAME fish only.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
40. **B seule** — lue par B seulement
   - A : —
   - B : `b-tx-bait-game` appat toutes (État) {"code": "pas_poisson_de_jeu_comme_appat"}
     > It is unlawful to use any game fish, or part of a game fish, as bait.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (9)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `TX-striped-limite_possession-etat` limite_possession Striped Bass (État) {"nombre": 10} [incertain]
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - B : `b-tx-stripedbass-poss` limite_possession striped bass (État) {"nombre": 10} [incertain]
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `TX-hybrid-limite_possession-etat` limite_possession Hybrid Striped Bass (État) {"nombre": 10} [incertain]
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - B : `b-tx-hybridstripedbass-poss` limite_possession hybrid striped bass (État) {"nombre": 10}
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `TX-channel_catfish-limite_possession-etat` limite_possession Channel Catfish (État) {"nombre": 50} [incertain]
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - B : `b-tx-channelcatfish-poss` limite_possession channel catfish (État) {"nombre": 50}
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `TX-blue_catfish-limite_possession-etat` limite_possession Blue Catfish (État) {"nombre": 50} [incertain]
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - B : `b-tx-bluecatfish-poss` limite_possession blue catfish (État) {"nombre": 50}
     > Possession limits are twice the statewide daily bag limits except for striped bass from Lake Texoma and alligator gar from Falcon International Reservoir.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **A et B seules** — code jugline / jugline_max_5_hamecons
   - A : `TX-engin-jugline` engin toutes (État) {"code": "jugline", "hamecons_max": 5} [incertain]
     > A fishing line with five or less hooks and a gear tag tied to a free-floating device.
   - B : `b-tx-jugline-hooks` engin toutes (État) {"hamecons_max": 5, "code": "jugline_max_5_hamecons"}
     > Jugline A fishing line with five or less hooks and a gear tag tied to a free-floating device.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
6. **A et B seules** — code throwline / jugline_max_5_hamecons
   - A : `TX-engin-throwline` engin toutes (État) {"code": "throwline", "hamecons_max": 5} [incertain]
     > A fishing line with five or less hooks and with one end attached to a permanent fixture, a float attached at or above the water line, and a gear tag.
   - B : `b-tx-jugline-hooks` engin toutes (État) {"hamecons_max": 5, "code": "jugline_max_5_hamecons"}
     > Jugline A fishing line with five or less hooks and a gear tag tied to a free-floating device.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
7. **A et B seules** — espèces ['blue catfish', 'channel catfish', 'flathead catfish'] / ['channel catfish']; code handfishing_catfish / pechemains_main_nue_eau_douce_seulement
   - A : `TX-engin-handfishing` engin Channel Catfish, Blue Catfish, Flathead Catfish (État) {"code": "handfishing_catfish"} [incertain]
     > May be used to take channel, blue and flathead catfish in fresh water only.
   - B : `b-tx-handfish` engin channel catfish (État) {"code": "pechemains_main_nue_eau_douce_seulement"} [incertain]
     > May be used to take channel, blue and flathead catfish in fresh water only.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
8. **A et B seules** — code bait_species_list / appats_poisson_liste_fermee
   - A : `TX-appat-liste` appat toutes (État) {"code": "bait_species_list"}
     > Only the following fish/shellfish may be used as bait: goldfish, common carp, native shrimp, crabs, crawfish, and nongame fish. Some counties have additional regulations.
   - B : `b-tx-bait-liste` appat toutes (État) {"code": "appats_poisson_liste_fermee"} [incertain]
     > Only the following fish/shellfish may be used as bait: goldfish, common carp, native shrimp, crabs, crawfish, and nongame fish. Some counties have additional regulations.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
9. **A et B seules** — code live_bait_transport_lake_water / transport_appat_vivant_hors_plan_eau_limite
   - A : `TX-appat-transport` appat toutes (État) {"code": "live_bait_transport_lake_water"}
     > Live bait may not be transported from the water body where the fish were caught, in or aboard a vessel, in water from the water body where the fish were caught.
   - B : `b-tx-bait-transport` appat toutes (État) {"code": "transport_appat_vivant_hors_plan_eau_limite"} [incertain]
     > Live bait may not be transported from the water body where the fish were caught, in or aboard a vessel, in water from the water body where the fish were caught.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (6)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. espèce d'un groupe — gardée : `b-tx-whitecrap-bag` limite_jour white crappie (État) {"nombre": 25} ; appui : `TX-crappie-limite_jour-etat` limite_jour Crappie (État) {"nombre": 25}
2. espèce d'un groupe — gardée : `b-tx-whitecrap-min` taille_min white crappie (État) {"pouces": 10} ; appui : `TX-crappie-taille_min-etat` taille_min Crappie (État) {"pouces": 10}
3. espèce d'un groupe — gardée : `b-tx-blackcrap-bag` limite_jour black crappie (État) {"nombre": 25} ; appui : `TX-crappie-limite_jour-etat` limite_jour Crappie (État) {"nombre": 25}
4. espèce d'un groupe — gardée : `b-tx-blackcrap-min` taille_min black crappie (État) {"pouces": 10} ; appui : `TX-crappie-taille_min-etat` taille_min Crappie (État) {"pouces": 10}
5. espèce d'un groupe — gardée : `b-tx-whitecrappie-poss` limite_possession white crappie (État) {"nombre": 50} ; appui : `TX-crappie-limite_possession-etat` limite_possession Crappie (État) {"nombre": 50}
6. espèce d'un groupe — gardée : `b-tx-blackcrappie-poss` limite_possession black crappie (État) {"nombre": 50} ; appui : `TX-crappie-limite_possession-etat` limite_possession Crappie (État) {"nombre": 50}
