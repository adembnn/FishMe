# MN : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py MN` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 64 règles (8 incertain) ; lecture B : 180 règles (6 incertain).
- Confirmées par les deux : 72, dont 67 sans réserve (chargées dans l'app) et 5 incertaines (non chargées).
- À vérifier : seulement A 37, seulement B 108.
- Désaccords listés : 143 — (i) forme sans conséquence : 66, (ii) conflit de fond : 0, (iii) couverture : 61, (iv) incertain d'un côté : 16.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (66)

1. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('06-06', '11-30')
   - A : `MN-muskie-possession` limite_possession Muskellunge (État) {"nombre": 1}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - B : `b-muskie-possession` limite_possession muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
2. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('06-06', '11-30')
   - A : `MN-muskie-taille-min` taille_min Muskellunge (État) {"pouces": 54}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - B : `b-muskie-min` taille_min muskellunge (État) 2026-06-06→2026-11-30 {"pouces": 54}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
3. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('06-06', '11-30')
   - A : `MN-tigermuskie-possession` limite_possession Tiger Muskellunge (État) {"nombre": 1}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - B : `b-tiger-possession` limite_possession tiger muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
4. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('06-06', '11-30')
   - A : `MN-tigermuskie-taille-min` taille_min Tiger Muskellunge (État) {"pouces": 40}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - B : `b-tiger-min` taille_min tiger muskellunge (État) 2026-06-06→2026-11-30 {"pouces": 40}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
5. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Southern Zone »
   - A : `MN-pike-saison` saison Northern Pike (État) 05-09→02-28 {}
     > Northern pike May 9, 2026 - Feb. 28, 2027
   - B : `b-pike-s-saison` saison northern pike (Southern Zone) 2026-05-09→2027-02-28 {}
     > Northern pike May 9, 2026 - Feb. 28, 2027
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
6. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '02-28')
   - A : `MN-pike-s-taille-min` taille_min Northern Pike (Southern Zone) {"pouces": 24}
     > Southern Zone: 2 (minimum size 24")
   - B : `b-pike-s-min` taille_min northern pike (Southern Zone) 2026-05-09→2027-02-28 {"pouces": 24}
     > Southern Zone: 2 (minimum size 24")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
7. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `MN-crappie-possession` limite_possession Crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - B : `b-white-crappie-possession` limite_possession white crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
8. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `MN-crappie-saison` saison Crappie (État) 01-01→12-31 {}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - B : `b-white-crappie-saison` saison white crappie (État) 01-01→12-31 {}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
9. **A seule (B appariée est confirmée ailleurs)** — espèces ['sunfish'] / ['orangespotted sunfish']
   - A : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-orangespotted-possession` limite_possession orangespotted sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
10. **A seule (B appariée est confirmée ailleurs)** — espèces ['sunfish'] / ['orangespotted sunfish']
   - A : `MN-sunfish-saison` saison Sunfish (État) 01-01→12-31 {}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-orangespotted-saison` saison orangespotted sunfish (État) 01-01→12-31 {}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
11. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('04-01', '11-30')
   - A : `MN-flatheadcat-possession` limite_possession Flathead Catfish (État) {"nombre": 2}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - B : `b-flathead-possession` limite_possession flathead catfish (État) 2026-04-01→2026-11-30 {"nombre": 2}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
12. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brook-ruisseau-saison` saison Brook Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-ruis-saison` saison brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
13. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-ruis-possession` limite_possession brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
14. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Lakes statewide, summer »
   - A : `MN-brook-lac-saison` saison Brook Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-saison` saison brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
15. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-brook-lac-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-possession` limite_possession brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
16. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brown-ruisseau-saison` saison Brown Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-ruis-saison` saison brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
17. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-ruis-possession` limite_possession brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
18. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Lakes statewide, summer »
   - A : `MN-brown-lac-saison` saison Brown Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-saison` saison brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
19. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-brown-lac-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-possession` limite_possession brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
20. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-rainbow-ruisseau-saison` saison Rainbow Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-ruis-saison` saison rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
21. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-ruis-possession` limite_possession rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
22. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Lakes statewide, summer »
   - A : `MN-rainbow-lac-saison` saison Rainbow Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-saison` saison rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
23. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-rainbow-lac-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-possession` limite_possession rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
24. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '09-30')
   - A : `MN-laketrout-limite-ete` limite_possession Lake Trout (État) {"nombre": 2}
     > Lake trout (SUMMER)Statewide May 9 - Sept. 30 2
   - B : `b-lt-ete-possession` limite_possession lake trout (État) 2026-05-09→2026-09-30 {"nombre": 2}
     > Lake trout (SUMMER)Statewide May 9 - Sept. 30 2
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
25. **A et B seules** — code une_ligne_eau_libre / lines_open_water
   - A : `MN-engin-lignes-eau-libre` engin toutes (État) {"lignes_max": 1, "code": "une_ligne_eau_libre"}
     > You may use only 1 line during the open water season except 2 lines may be used in the Minnesota River downstream of the Granite Falls Dam and in the Mississippi River downstream of St. Anthony Falls.
   - B : `b-lignes-eau-libre` engin toutes (État) {"lignes_max": 1, "code": "lines_open_water"}
     > You may use only 1 line during the open water season except 2 lines may be used in the Minnesota River downstream of the Granite Falls Dam
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
26. **A et B seules** — code deux_lignes_glace / lines_ice
   - A : `MN-engin-lignes-glace` engin toutes (État) {"lignes_max": 2, "code": "deux_lignes_glace"}
     > You may use 2 lines through the ice except on designated trout lakes and streams.
   - B : `b-lignes-glace` engin toutes (État) {"lignes_max": 2, "code": "lines_ice"}
     > You may use 2 lines through the ice except on designated trout lakes and streams.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
27. **A et B seules** — code une_ligne_truite_designee / lines_open_water
   - A : `MN-engin-lignes-truite` engin toutes (État) {"lignes_max": 1, "code": "une_ligne_truite_designee"}
     > On designated trout lakes and streams, only 1 line is allowed at any time.
   - B : `b-lignes-eau-libre` engin toutes (État) {"lignes_max": 1, "code": "lines_open_water"}
     > You may use only 1 line during the open water season except 2 lines may be used in the Minnesota River downstream of the Granite Falls Dam
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
28. **A et B seules** — code trois_hamecons_18_pouces / tackle_three_hooks_18in
   - A : `MN-engin-hamecons` engin toutes (État) {"hamecons_max": 3, "code": "trois_hamecons_18_pouces"}
     > Up to 3 single- or multiple-pronged hooks may be used as a single tackle configuration. The total distance between hooks cannot exceed 18" measured along the line.
   - B : `b-hamecons-3` engin toutes (État) {"hamecons_max": 3, "code": "tackle_three_hooks_18in"}
     > Up to 3 single- or multiple-pronged hooks may be used as a single tackle configuration. The total distance between hooks cannot exceed 18" measured along the line.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
29. **A et B seules** — code appat_gibier_carpe_interdit / bait_game_fish_goldfish_carp_salamander
   - A : `MN-appat-poissons-interdits` interdit toutes (État) {"code": "appat_gibier_carpe_interdit"}
     > You can’t use whole or parts of game fish, goldfish, carp, or salamanders (including mudpuppies) for bait.
   - B : `b-appat-poissons` interdit toutes (État) {"code": "bait_game_fish_goldfish_carp_salamander"}
     > You can’t use whole or parts of game fish, goldfish, carp, or salamanders (including mudpuppies) for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
30. **A et B seules** — code import_vifs_interdit / import_live_minnows_leeches
   - A : `MN-appat-import-vifs` interdit toutes (État) {"code": "import_vifs_interdit"}
     > You can't import live minnows or leeches into Minnesota.
   - B : `b-appat-import` interdit toutes (État) {"code": "import_live_minnows_leeches"}
     > You can't import live minnows or leeches into Minnesota.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
31. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-walleye-possession` limite_possession Walleye (État) {"nombre": 6}
     > Walleye and sauger (and their hybrid) May 9, 2026 - Feb. 28, 2027 6 combined total (only 1 walleye over 20" in possession)
   - B : `b-walleye-jour` limite_jour walleye (État) {"nombre": 6}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
32. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-sauger-possession` limite_possession Sauger (État) {"nombre": 6}
     > Walleye and sauger (and their hybrid) May 9, 2026 - Feb. 28, 2027 6 combined total (only 1 walleye over 20" in possession)
   - B : `b-sauger-jour` limite_jour sauger (État) {"nombre": 6}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
33. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-lmb-sn-limite` limite_possession Largemouth Bass (Southern and North-central Zones) 05-23→02-28 {"nombre": 6}
     > May 23, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass (when smallmouth season is open)
   - B : `b-lmb-sud-jour` limite_jour largemouth bass (Southern and North-central Zones) 2026-05-23→2027-02-28 {"nombre": 6}
     > 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
34. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-smb-sn-limite` limite_possession Smallmouth Bass (Southern and North-central Zones) 05-23→09-13 {"nombre": 6}
     > May 23 - Sept. 13 6 combined total largemouth or smallmouth bass
   - B : `b-smb-sud-jour` limite_jour smallmouth bass (Southern and North-central Zones) 2026-05-23→2026-09-13 {"nombre": 6}
     > 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
35. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-lmb-ne-limite` limite_possession Largemouth Bass (Northeast Zone) 05-09→02-28 {"nombre": 6}
     > May 9, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass
   - B : `b-lmb-ne-jour` limite_jour largemouth bass (Northeast Zone) 2026-05-09→2027-02-28 {"nombre": 6}
     > 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
36. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-smb-ne-limite` limite_possession Smallmouth Bass (Northeast Zone) 05-09→02-28 {"nombre": 6}
     > May 9, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass
   - B : `b-smb-ne-jour` limite_jour smallmouth bass (Northeast Zone) 2026-05-09→2027-02-28 {"nombre": 6}
     > 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
37. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-pike-s-possession` limite_possession Northern Pike (Southern Zone) {"nombre": 2}
     > Southern Zone: 2 (minimum size 24")
   - B : `b-pike-s-jour` limite_jour northern pike (Southern Zone) {"nombre": 2}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
38. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('06-06', '11-30')
   - A : `MN-muskie-possession` limite_possession Muskellunge (État) {"nombre": 1}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - B : `b-muskie-jour` limite_jour muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1}
     > Muskellunge June 6 - Nov. 30 1 (minimum size 54")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
39. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('06-06', '11-30')
   - A : `MN-tigermuskie-possession` limite_possession Tiger Muskellunge (État) {"nombre": 1}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - B : `b-tiger-jour` limite_jour tiger muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1}
     > Tiger (hybrid) muskellunge (see page 85 for identification guide) June 6 - Nov. 30 1 (minimum size 40")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
40. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-ruis-jour` limite_jour brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
41. **A et B seules** — dates ('04-11', '09-30') / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-brook-ruisseau-saison` saison Brook Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-se-saison` saison brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
42. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-se-jour` limite_jour brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
43. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-brook-lac-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-jour` limite_jour brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
44. **A et B seules** — dates ('05-09', '10-31') / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-brook-lac-saison` saison Brook Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-hiver` saison brook trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
45. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-brook-lac-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-hiver-jour` limite_jour brook trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
46. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-ruis-jour` limite_jour brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
47. **A et B seules** — dates ('04-11', '09-30') / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-brown-ruisseau-saison` saison Brown Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-se-saison` saison brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
48. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-se-jour` limite_jour brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
49. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-brown-lac-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-jour` limite_jour brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
50. **A et B seules** — dates ('05-09', '10-31') / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-brown-lac-saison` saison Brown Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-hiver` saison brown trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
51. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-brown-lac-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-hiver-jour` limite_jour brown trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
52. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-30'); portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-ruis-jour` limite_jour rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
53. **A et B seules** — dates ('04-11', '09-30') / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-rainbow-ruisseau-saison` saison Rainbow Trout (État) 04-11→09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-se-saison` saison rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
54. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-11', '09-14'); portée « État » / « Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties) »
   - A : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-se-jour` limite_jour rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
55. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('05-09', '10-31'); portée « État » / « Lakes statewide, summer »
   - A : `MN-rainbow-lac-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-jour` limite_jour rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
56. **A et B seules** — dates ('05-09', '10-31') / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-rainbow-lac-saison` saison Rainbow Trout (État) 05-09→10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-hiver` saison rainbow trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
57. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('01-17', '03-31'); portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-rainbow-lac-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-hiver-jour` limite_jour rainbow trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
58. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('05-09', '09-30')
   - A : `MN-laketrout-limite-ete` limite_possession Lake Trout (État) {"nombre": 2}
     > Lake trout (SUMMER)Statewide May 9 - Sept. 30 2
   - B : `b-lt-ete-jour` limite_jour lake trout (État) 2026-05-09→2026-09-30 {"nombre": 2}
     > Lake trout (SUMMER)Statewide May 9 - Sept. 30 2
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
59. **A et B seules** — type limite_possession / limite_jour; espèces ['crappie'] / ['black crappie']
   - A : `MN-crappie-possession` limite_possession Crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - B : `b-black-crappie-jour` limite_jour black crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
60. **A et B seules** — type limite_possession / limite_jour; espèces ['crappie'] / ['white crappie']
   - A : `MN-crappie-possession` limite_possession Crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - B : `b-white-crappie-jour` limite_jour white crappie (État) {"nombre": 10}
     > Crappie (white or black and their hybrids) Continuous 10 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
61. **A et B seules** — type limite_possession / limite_jour; espèces ['sunfish'] / ['bluegill']
   - A : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-bluegill-jour` limite_jour bluegill (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
62. **A et B seules** — type limite_possession / limite_jour; espèces ['sunfish'] / ['pumpkinseed']
   - A : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-pumpkinseed-jour` limite_jour pumpkinseed (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
63. **A et B seules** — type limite_possession / limite_jour; espèces ['sunfish'] / ['green sunfish']
   - A : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-green-jour` limite_jour green sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
64. **A et B seules** — type limite_possession / limite_jour; espèces ['sunfish'] / ['orangespotted sunfish']
   - A : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - B : `b-orangespotted-jour` limite_jour orangespotted sunfish (État) {"nombre": 20}
     > Sunfish (bluegill, pumpkinseed, green, orangespotted, northern, warmouth, and their hybrids) Continuous 20 combined total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
65. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-channelcat-possession` limite_possession Channel Catfish (État) {"nombre": 5}
     > Channel Catfish Continuous 5 (only 1 over 24")
   - B : `b-channel-jour` limite_jour channel catfish (État) {"nombre": 5}
     > Channel Catfish Continuous 5 (only 1 over 24")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
66. **A et B seules** — type limite_possession / limite_jour; dates (None, None) / ('04-01', '11-30')
   - A : `MN-flatheadcat-possession` limite_possession Flathead Catfish (État) {"nombre": 2}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - B : `b-flathead-jour` limite_jour flathead catfish (État) 2026-04-01→2026-11-30 {"nombre": 2}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)

## (iii) couverture (61)

1. **A seule** — lue par A seulement
   - A : `MN-appat-truite-vairons` interdit toutes (État) {"code": "vairons_vivants_lacs_truite"}
     > Possessing live minnows or using them for bait on designated stream trout lakes is prohibited.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement (marquée incertain)
   - A : `MN-appat-lancer-filet` engin toutes (État) {"code": "epervier_permis_dnr"} [incertain]
     > You cannot use throw nets (cast nets) without a DNR permit (see page 38).
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **B seule** — lue par B seulement
   - A : —
   - B : `b-lmb-sud-saison` saison largemouth bass (Southern and North-central Zones) 2026-05-23→2027-02-28 {}
     > May 23, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass (when smallmouth season is open)
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
4. **B seule** — lue par B seulement
   - A : —
   - B : `b-smb-sud-saison` saison smallmouth bass (Southern and North-central Zones) 2026-05-23→2026-09-13 {}
     > May 23 - Sept. 13 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
5. **B seule** — lue par B seulement
   - A : —
   - B : `b-lmb-ne-saison` saison largemouth bass (Northeast Zone) 2026-05-09→2027-02-28 {}
     > May 9, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
6. **B seule** — lue par B seulement
   - A : —
   - B : `b-smb-ne-saison` saison smallmouth bass (Northeast Zone) 2026-05-09→2027-02-28 {}
     > May 9, 2026 - Feb. 28, 2027 6 combined total largemouth or smallmouth bass
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
7. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('04-11', '09-30'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 1.0}; portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brook-trout-ruis-over16` autre brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 1, "pouces": 16}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
8. **B seule** — lue par B seulement
   - A : —
   - B : `b-brook-trout-se-cr1` relacher brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-01-01→2026-04-10 {"code": "catch_and_release_only"}
     > Jan. 1 - April 10 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
9. **B seule** — lue par B seulement
   - A : —
   - B : `b-brook-trout-se-over16` autre brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 1, "pouces": 16}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
10. **B seule** — lue par B seulement
   - A : —
   - B : `b-brook-trout-se-cr2` relacher brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-09-15→2026-10-15 {"code": "catch_and_release_only"}
     > Sept. 15 - Oct. 15 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
11. **B seule** — lue par B seulement
   - A : —
   - B : `b-brook-trout-se-ferme` fermeture brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-10-16→2026-12-31 {"code": "closed_to_fishing"}
     > Oct. 16 - Dec. 31 Closed to fishing
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
12. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('05-09', '10-31'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 3.0}; portée « État » / « Lakes statewide, summer »
   - A : `MN-brook-lac-limite` limite_possession Brook Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brook-trout-lac-over16` autre brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 3, "pouces": 16}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
13. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('04-11', '09-30'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 1.0}; portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-brown-trout-ruis-over16` autre brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 1, "pouces": 16}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
14. **B seule** — lue par B seulement
   - A : —
   - B : `b-brown-trout-se-cr1` relacher brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-01-01→2026-04-10 {"code": "catch_and_release_only"}
     > Jan. 1 - April 10 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
15. **B seule** — lue par B seulement
   - A : —
   - B : `b-brown-trout-se-over16` autre brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 1, "pouces": 16}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
16. **B seule** — lue par B seulement
   - A : —
   - B : `b-brown-trout-se-cr2` relacher brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-09-15→2026-10-15 {"code": "catch_and_release_only"}
     > Sept. 15 - Oct. 15 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
17. **B seule** — lue par B seulement
   - A : —
   - B : `b-brown-trout-se-ferme` fermeture brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-10-16→2026-12-31 {"code": "closed_to_fishing"}
     > Oct. 16 - Dec. 31 Closed to fishing
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
18. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('05-09', '10-31'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 3.0}; portée « État » / « Lakes statewide, summer »
   - A : `MN-brown-lac-limite` limite_possession Brown Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-brown-trout-lac-over16` autre brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 3, "pouces": 16}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
19. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('04-11', '09-30'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 1.0}; portée « État » / « Streams statewide except Southeast Minnesota »
   - A : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - B : `b-rainbow-trout-ruis-over16` autre rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 1, "pouces": 16}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
20. **B seule** — lue par B seulement
   - A : —
   - B : `b-rainbow-trout-se-cr1` relacher rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-01-01→2026-04-10 {"code": "catch_and_release_only"}
     > Jan. 1 - April 10 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
21. **B seule** — lue par B seulement
   - A : —
   - B : `b-rainbow-trout-se-over16` autre rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 1, "pouces": 16}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
22. **B seule** — lue par B seulement
   - A : —
   - B : `b-rainbow-trout-se-cr2` relacher rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-09-15→2026-10-15 {"code": "catch_and_release_only"}
     > Sept. 15 - Oct. 15 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
23. **B seule** — lue par B seulement
   - A : —
   - B : `b-rainbow-trout-se-ferme` fermeture rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-10-16→2026-12-31 {"code": "closed_to_fishing"}
     > Oct. 16 - Dec. 31 Closed to fishing
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
24. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('05-09', '10-31'); nombres {'nombre': 5.0} / {'taille': 16.0, 'nombre': 3.0}; portée « État » / « Lakes statewide, summer »
   - A : `MN-rainbow-lac-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - B : `b-rainbow-trout-lac-over16` autre rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 3, "pouces": 16}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
25. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-ruis-saison` saison splake (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
26. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-ruis-jour` limite_jour splake (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
27. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-ruis-possession` limite_possession splake (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
28. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-ruis-over16` autre splake (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 1, "pouces": 16}
     > Streams — Statewide except listed below April 11 - Sept. 30 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
29. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-cr1` relacher splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-01-01→2026-04-10 {"code": "catch_and_release_only"}
     > Jan. 1 - April 10 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
30. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-saison` saison splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
31. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-jour` limite_jour splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
32. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-possession` limite_possession splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
33. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-over16` autre splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 1, "pouces": 16}
     > April 11 - Sept. 14 5 combined total (only 1 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
34. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-cr2` relacher splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-09-15→2026-10-15 {"code": "catch_and_release_only"}
     > Sept. 15 - Oct. 15 Catch-and-release only
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
35. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-se-ferme` fermeture splake (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-10-16→2026-12-31 {"code": "closed_to_fishing"}
     > Oct. 16 - Dec. 31 Closed to fishing
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
36. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-saison` saison splake (Lakes statewide, summer) 2026-05-09→2026-10-31 {}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
37. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-jour` limite_jour splake (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
38. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-possession` limite_possession splake (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
39. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-over16` autre splake (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 3, "pouces": 16}
     > Lakes (SUMMER) Statewide May 9 - Oct. 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
40. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-hiver` saison splake (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
41. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-hiver-jour` limite_jour splake (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
42. **B seule** — lue par B seulement
   - A : —
   - B : `b-splake-lac-hiver-possession` limite_possession splake (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5}
     > Lakes (WINTER) Outside or partly outside the BWCAW 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 5 combined total (not more than 3 over 16")
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
43. **B seule** — lue par B seulement
   - A : —
   - B : `b-trout-lines` engin brook trout (Designated trout lakes and streams) {"lignes_max": 1, "code": "trout_waters_one_line"}
     > On designated trout lakes and streams, only 1 line is allowed at any time.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
44. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-trout-hours` autre brook trout (État) {} [incertain]
     > Fishing hours for stream trout on inland waters are from 1 hour before sunrise to 11 p.m.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
45. **B seule** — lue par B seulement
   - A : —
   - B : `b-trout-minnows` interdit brook trout (Designated stream trout lakes) {"code": "live_minnows_designated_trout_lakes"}
     > Possessing live minnows or using them for bait on designated stream trout lakes is prohibited.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
46. **B seule** — lue par B seulement
   - A : —
   - B : `b-lt-hiver-jour` limite_jour lake trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 2}
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
47. **B seule** — lue par B seulement
   - A : —
   - B : `b-lt-bwcaw-jour` limite_jour lake trout (Lakes entirely within the BWCAW, winter) 2026-01-01→2026-03-31 {"nombre": 2}
     > Lake trout (WINTER) Lakes entirely within the BWCAW. 2026 Season: Jan. 1 - March 31 2027 Season: Jan. 1 - March 31 2
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
48. **B seule (A appariée est confirmée ailleurs)** — faits différents du même passage : type limite_possession / autre; nombres {'nombre': 5.0} / {'taille': 24.0, 'nombre': 1.0}
   - A : `MN-channelcat-possession` limite_possession Channel Catfish (État) {"nombre": 5}
     > Channel Catfish Continuous 5 (only 1 over 24")
   - B : `b-channel-over24` autre channel catfish (État) {"nombre": 1, "pouces": 24}
     > Channel Catfish Continuous 5 (only 1 over 24")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
49. **A et B seules** — faits différents du même passage : type limite_possession / autre; dates (None, None) / ('04-01', '11-30'); nombres {'nombre': 2.0} / {'taille': 24.0, 'nombre': 1.0}
   - A : `MN-flatheadcat-possession` limite_possession Flathead Catfish (État) {"nombre": 2}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - B : `b-flathead-over24` autre flathead catfish (État) 2026-04-01→2026-11-30 {"nombre": 1, "pouces": 24}
     > Flathead Catfish April 1 - Nov. 30 2 (only 1 over 24")
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
50. **B seule** — lue par B seulement
   - A : —
   - B : `b-sturgeon-ferme` fermeture lake sturgeon (État) {"code": "closed_april15_june15"}
     > Closed April 15 through 11:59 p.m. June 15.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
51. **B seule** — lue par B seulement
   - A : —
   - B : `b-paddlefish` fermeture paddlefish (État) {"code": "no_open_season"}
     > Paddlefish No open season
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
52. **B seule** — lue par B seulement
   - A : —
   - B : `b-appat-un-seul` appat toutes (État) {"nombre": 1, "code": "one_bait_per_line"}
     > Only 1 live, artificial, preserved or dead bait is allowed per line.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
53. **B seule** — lue par B seulement
   - A : —
   - B : `b-stinger` engin toutes (État) {"hamecons_max": 1, "code": "stinger_hook_artificial_3in"}
     > Unless fishing on a designated trout stream or lake, you may add 1 additional “stinger” hook on a line as part of a single artificial bait/lure.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
54. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-mouches-3` engin largemouth bass (État) {"nombre": 3, "code": "flies_three_per_line"} [incertain]
     > Up to 3 artificial flies are allowed on 1 fishing line with no restrictions on distance between flies when fishing for bass, crappie, rock bass, sunfish, or trout.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
55. **B seule** — lue par B seulement
   - A : —
   - B : `b-appat-relache` interdit toutes (État) {"code": "release_bait"}
     > It is illegal to release bait into Minnesota lakes and rivers.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
56. **B seule** — lue par B seulement
   - A : —
   - B : `b-appat-12-douzaines` appat toutes (État) {"nombre": 12, "code": "minnows_transport_12_dozen"}
     > you may not transport more than 12 dozen at a time without a commercial minnow license.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
57. **B seule** — lue par B seulement
   - A : —
   - B : `b-ligne-sans-surveillance` interdit toutes (État) {"code": "line_unattended"}
     > Leaving your fishing line with hooks attached in the water unattended.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
58. **B seule** — lue par B seulement
   - A : —
   - B : `b-lumiere-attractive` interdit toutes (État) {"code": "artificial_light_lure"}
     > Using an artificial light to lure, attract or spot fish.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
59. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-mille-lacs` autre toutes (Mille Lacs Lake) {} [incertain]
     > Regulations for walleye, northern pike, smallmouth bass, tullibee, and other fish species will be posted at public access sites and the DNR website at mndnr.gov/millelacslake.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
60. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-red-lake` autre toutes (Upper Red Lake) {} [incertain]
     > Those portions of Red Lake located within the Red Lake Indian Reservation are closed to non-band members except by special authorization of the tribal council.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
61. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-speciales-existence` autre toutes (État) {} [incertain]
     > These regulations differ from statewide or border water regulations and take precedence.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (16)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `MN-pike-ne-possession` limite_possession Northern Pike (Northeast Zone) {"nombre": 2} [incertain]
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - B : `b-pike-ne-possession` limite_possession northern pike (Northeast Zone) {"nombre": 2}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `MN-pike-nc-possession` limite_possession Northern Pike (North-central Zone) {"nombre": 10} [incertain]
     > 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - B : `b-pike-nc-possession` limite_possession northern pike (North-central Zone) {"nombre": 10}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MN-pike-ne-fenetre` fenetre Northern Pike (Northeast Zone) {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"} [incertain]
     > all from 30-40" must be immediately released
   - B : `b-pike-ne-fenetre` fenetre northern pike (Northeast Zone) 2026-05-09→2027-02-28 {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"}
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MN-pike-nc-fenetre` fenetre Northern Pike (North-central Zone) {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"} [incertain]
     > all from 22-26" must be immediately released
   - B : `b-pike-nc-fenetre` fenetre northern pike (North-central Zone) 2026-05-09→2027-02-28 {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"}
     > North-central Zone: 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MN-laketrout-saison-hiver` saison Lake Trout (État) 01-17→03-31 {} [incertain]
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - B : `b-lt-saison-hiver` saison lake trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
6. **A et B seules** — type taille_max / autre
   - A : `MN-walleye-un-grand` taille_max Walleye (État) {"nombre": 1, "pouces": 20} [incertain]
     > Walleye and sauger (and their hybrid) May 9, 2026 - Feb. 28, 2027 6 combined total (only 1 walleye over 20" in possession)
   - B : `b-walleye-1-over-20` autre walleye (État) {"nombre": 1, "pouces": 20} [incertain]
     > Walleye and sauger (and their hybrid) May 9, 2026 - Feb. 28, 2027 6 combined total (only 1 walleye over 20" in possession)
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
7. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '02-28')
   - A : `MN-pike-ne-fenetre` fenetre Northern Pike (Northeast Zone) {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"} [incertain]
     > all from 30-40" must be immediately released
   - B : `b-pike-ne-fenetre` fenetre northern pike (Northeast Zone) 2026-05-09→2027-02-28 {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"}
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
8. **A seule (B appariée est confirmée ailleurs)** — dates (None, None) / ('05-09', '02-28')
   - A : `MN-pike-nc-fenetre` fenetre Northern Pike (North-central Zone) {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"} [incertain]
     > all from 22-26" must be immediately released
   - B : `b-pike-nc-fenetre` fenetre northern pike (North-central Zone) 2026-05-09→2027-02-28 {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"}
     > North-central Zone: 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
9. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Lakes outside or partly outside the BWCAW, winter »
   - A : `MN-laketrout-saison-hiver` saison Lake Trout (État) 01-17→03-31 {} [incertain]
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - B : `b-lt-saison-hiver` saison lake trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {}
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
10. **A et B seules** — code methodes_interdites / snagging_noodling
   - A : `MN-engin-interdits` interdit toutes (État) {"code": "methodes_interdites"} [incertain]
     > Taking fish by hand (noodling) or by snagging.
   - B : `b-harponnage-main` interdit toutes (État) {"code": "snagging_noodling"}
     > Taking fish by hand (noodling) or by snagging.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
11. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-pike-ne-possession` limite_possession Northern Pike (Northeast Zone) {"nombre": 2} [incertain]
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - B : `b-pike-ne-jour` limite_jour northern pike (Northeast Zone) {"nombre": 2}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
12. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / limite_jour
   - A : `MN-pike-nc-possession` limite_possession Northern Pike (North-central Zone) {"nombre": 10} [incertain]
     > 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - B : `b-pike-nc-jour` limite_jour northern pike (North-central Zone) {"nombre": 10}
     > Daily and possession limits are the same unless otherwise noted.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
13. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / autre; dates (None, None) / ('05-09', '02-28'); nombres {'nombre': 2.0} / {'taille': 40.0, 'nombre': 1.0}
   - A : `MN-pike-ne-possession` limite_possession Northern Pike (Northeast Zone) {"nombre": 2} [incertain]
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - B : `b-pike-ne-over40` autre northern pike (Northeast Zone) 2026-05-09→2027-02-28 {"nombre": 1, "pouces": 40}
     > Northeast Zone: 2 (only 1 over 40" in possession, all from 30-40" must be immediately released
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
14. **B seule (A appariée est confirmée ailleurs)** — type limite_possession / autre; dates (None, None) / ('05-09', '02-28'); nombres {'nombre': 10.0} / {'taille': 26.0, 'nombre': 2.0}
   - A : `MN-pike-nc-possession` limite_possession Northern Pike (North-central Zone) {"nombre": 10} [incertain]
     > 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - B : `b-pike-nc-over26` autre northern pike (North-central Zone) 2026-05-09→2027-02-28 {"nombre": 2, "pouces": 26}
     > North-central Zone: 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
15. **B seule (A appariée est confirmée ailleurs)** — portée « North-central Zone » / « État »
   - A : `MN-pike-nc-possession` limite_possession Northern Pike (North-central Zone) {"nombre": 10} [incertain]
     > 10 (not more than 2 over 26", all from 22-26" must be immediately released)
   - B : `b-pike-possession-max` limite_possession northern pike (État) {"nombre": 10}
     > The maximum number of northern pike that you may possess is 10 fish.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
16. **A et B seules** — dates ('01-17', '03-31') / ('01-01', '03-31'); portée « État » / « Lakes entirely within the BWCAW, winter »
   - A : `MN-laketrout-saison-hiver` saison Lake Trout (État) 01-17→03-31 {} [incertain]
     > Lake trout (WINTER) Outside or partly outside the Boundary Waters Canoe Area Wilderness. 2026 Season: Jan. 17 - March 31 2027 Season: Jan. 16 - March 31 2
   - B : `b-lt-saison-bwcaw` saison lake trout (Lakes entirely within the BWCAW, winter) 2026-01-01→2026-03-31 {}
     > Lake trout (WINTER) Lakes entirely within the BWCAW. 2026 Season: Jan. 1 - March 31 2027 Season: Jan. 1 - March 31 2
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (45)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. portée plus fine — gardée : `b-pike-ne-saison` saison northern pike (Northeast Zone) 2026-05-09→2027-02-28 {} ; appui : `MN-pike-saison` saison Northern Pike (État) 05-09→02-28 {}
2. portée plus fine — gardée : `b-pike-nc-saison` saison northern pike (North-central Zone) 2026-05-09→2027-02-28 {} ; appui : `MN-pike-saison` saison Northern Pike (État) 05-09→02-28 {}
3. portée plus fine — gardée : `b-pike-s-saison` saison northern pike (Southern Zone) 2026-05-09→2027-02-28 {} ; appui : `MN-pike-saison` saison Northern Pike (État) 05-09→02-28 {}
4. valeur datée — gardée : `b-pike-s-min` taille_min northern pike (Southern Zone) 2026-05-09→2027-02-28 {"pouces": 24} ; appui : `MN-pike-s-taille-min` taille_min Northern Pike (Southern Zone) {"pouces": 24}
5. valeur datée — gardée : `b-muskie-possession` limite_possession muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1} ; appui : `MN-muskie-possession` limite_possession Muskellunge (État) {"nombre": 1}
6. valeur datée — gardée : `b-muskie-min` taille_min muskellunge (État) 2026-06-06→2026-11-30 {"pouces": 54} ; appui : `MN-muskie-taille-min` taille_min Muskellunge (État) {"pouces": 54}
7. valeur datée — gardée : `b-tiger-possession` limite_possession tiger muskellunge (État) 2026-06-06→2026-11-30 {"nombre": 1} ; appui : `MN-tigermuskie-possession` limite_possession Tiger Muskellunge (État) {"nombre": 1}
8. valeur datée — gardée : `b-tiger-min` taille_min tiger muskellunge (État) 2026-06-06→2026-11-30 {"pouces": 40} ; appui : `MN-tigermuskie-taille-min` taille_min Tiger Muskellunge (État) {"pouces": 40}
9. portée plus fine — gardée : `b-brook-trout-ruis-saison` saison brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {} ; appui : `MN-brook-ruisseau-saison` saison Brook Trout (État) 04-11→09-30 {}
10. portée plus fine, valeur datée — gardée : `b-brook-trout-ruis-possession` limite_possession brook trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5} ; appui : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
11. portée plus fine, valeur datée — gardée : `b-brook-trout-se-possession` limite_possession brook trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5} ; appui : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
12. portée plus fine — gardée : `b-brook-trout-lac-saison` saison brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {} ; appui : `MN-brook-lac-saison` saison Brook Trout (État) 05-09→10-31 {}
13. portée plus fine, valeur datée — gardée : `b-brook-trout-lac-possession` limite_possession brook trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5} ; appui : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
14. portée plus fine, valeur datée — gardée : `b-brook-trout-lac-hiver-possession` limite_possession brook trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5} ; appui : `MN-brook-ruisseau-limite` limite_possession Brook Trout (État) {"nombre": 5}
15. portée plus fine — gardée : `b-brown-trout-ruis-saison` saison brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {} ; appui : `MN-brown-ruisseau-saison` saison Brown Trout (État) 04-11→09-30 {}
16. portée plus fine, valeur datée — gardée : `b-brown-trout-ruis-possession` limite_possession brown trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5} ; appui : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
17. portée plus fine, valeur datée — gardée : `b-brown-trout-se-possession` limite_possession brown trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5} ; appui : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
18. portée plus fine — gardée : `b-brown-trout-lac-saison` saison brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {} ; appui : `MN-brown-lac-saison` saison Brown Trout (État) 05-09→10-31 {}
19. portée plus fine, valeur datée — gardée : `b-brown-trout-lac-possession` limite_possession brown trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5} ; appui : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
20. portée plus fine, valeur datée — gardée : `b-brown-trout-lac-hiver-possession` limite_possession brown trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5} ; appui : `MN-brown-ruisseau-limite` limite_possession Brown Trout (État) {"nombre": 5}
21. portée plus fine — gardée : `b-rainbow-trout-ruis-saison` saison rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {} ; appui : `MN-rainbow-ruisseau-saison` saison Rainbow Trout (État) 04-11→09-30 {}
22. portée plus fine, valeur datée — gardée : `b-rainbow-trout-ruis-possession` limite_possession rainbow trout (Streams statewide except Southeast Minnesota) 2026-04-11→2026-09-30 {"nombre": 5} ; appui : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
23. portée plus fine, valeur datée — gardée : `b-rainbow-trout-se-possession` limite_possession rainbow trout (Streams Southeast Minnesota (Houston, Fillmore, Mower, Dodge, Olmsted, Winona, Wabasha, Dakota, Goodhue counties)) 2026-04-11→2026-09-14 {"nombre": 5} ; appui : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
24. portée plus fine — gardée : `b-rainbow-trout-lac-saison` saison rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {} ; appui : `MN-rainbow-lac-saison` saison Rainbow Trout (État) 05-09→10-31 {}
25. portée plus fine, valeur datée — gardée : `b-rainbow-trout-lac-possession` limite_possession rainbow trout (Lakes statewide, summer) 2026-05-09→2026-10-31 {"nombre": 5} ; appui : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
26. portée plus fine, valeur datée — gardée : `b-rainbow-trout-lac-hiver-possession` limite_possession rainbow trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 5} ; appui : `MN-rainbow-ruisseau-limite` limite_possession Rainbow Trout (État) {"nombre": 5}
27. valeur datée — gardée : `b-lt-ete-possession` limite_possession lake trout (État) 2026-05-09→2026-09-30 {"nombre": 2} ; appui : `MN-laketrout-limite-ete` limite_possession Lake Trout (État) {"nombre": 2}
28. portée plus fine, valeur datée — gardée : `b-lt-hiver-possession` limite_possession lake trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {"nombre": 2} ; appui : `MN-laketrout-limite-ete` limite_possession Lake Trout (État) {"nombre": 2}
29. portée plus fine, valeur datée — gardée : `b-lt-bwcaw-possession` limite_possession lake trout (Lakes entirely within the BWCAW, winter) 2026-01-01→2026-03-31 {"nombre": 2} ; appui : `MN-laketrout-limite-ete` limite_possession Lake Trout (État) {"nombre": 2}
30. espèce d'un groupe — gardée : `b-black-crappie-saison` saison black crappie (État) 01-01→12-31 {} ; appui : `MN-crappie-saison` saison Crappie (État) 01-01→12-31 {}
31. espèce d'un groupe — gardée : `b-black-crappie-possession` limite_possession black crappie (État) {"nombre": 10} ; appui : `MN-crappie-possession` limite_possession Crappie (État) {"nombre": 10}
32. espèce d'un groupe — gardée : `b-white-crappie-saison` saison white crappie (État) 01-01→12-31 {} ; appui : `MN-crappie-saison` saison Crappie (État) 01-01→12-31 {}
33. espèce d'un groupe — gardée : `b-white-crappie-possession` limite_possession white crappie (État) {"nombre": 10} ; appui : `MN-crappie-possession` limite_possession Crappie (État) {"nombre": 10}
34. espèce d'un groupe — gardée : `b-bluegill-saison` saison bluegill (État) 01-01→12-31 {} ; appui : `MN-sunfish-saison` saison Sunfish (État) 01-01→12-31 {}
35. espèce d'un groupe — gardée : `b-bluegill-possession` limite_possession bluegill (État) {"nombre": 20} ; appui : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
36. espèce d'un groupe — gardée : `b-pumpkinseed-saison` saison pumpkinseed (État) 01-01→12-31 {} ; appui : `MN-sunfish-saison` saison Sunfish (État) 01-01→12-31 {}
37. espèce d'un groupe — gardée : `b-pumpkinseed-possession` limite_possession pumpkinseed (État) {"nombre": 20} ; appui : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
38. espèce d'un groupe — gardée : `b-green-saison` saison green sunfish (État) 01-01→12-31 {} ; appui : `MN-sunfish-saison` saison Sunfish (État) 01-01→12-31 {}
39. espèce d'un groupe — gardée : `b-green-possession` limite_possession green sunfish (État) {"nombre": 20} ; appui : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
40. espèce d'un groupe — gardée : `b-orangespotted-saison` saison orangespotted sunfish (État) 01-01→12-31 {} ; appui : `MN-sunfish-saison` saison Sunfish (État) 01-01→12-31 {}
41. espèce d'un groupe — gardée : `b-orangespotted-possession` limite_possession orangespotted sunfish (État) {"nombre": 20} ; appui : `MN-sunfish-possession` limite_possession Sunfish (État) {"nombre": 20}
42. valeur datée — gardée : `b-flathead-possession` limite_possession flathead catfish (État) 2026-04-01→2026-11-30 {"nombre": 2} ; appui : `MN-flatheadcat-possession` limite_possession Flathead Catfish (État) {"nombre": 2}
43. valeur datée — gardée : `b-pike-ne-fenetre` fenetre northern pike (Northeast Zone) 2026-05-09→2027-02-28 {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"} [incertain] ; appui : `MN-pike-ne-fenetre` fenetre Northern Pike (Northeast Zone) {"pouces_min": 30, "pouces_max": 40, "mode": "relacher_entre"} [incertain]
44. valeur datée — gardée : `b-pike-nc-fenetre` fenetre northern pike (North-central Zone) 2026-05-09→2027-02-28 {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"} [incertain] ; appui : `MN-pike-nc-fenetre` fenetre Northern Pike (North-central Zone) {"pouces_min": 22, "pouces_max": 26, "mode": "relacher_entre"} [incertain]
45. portée plus fine — gardée : `b-lt-saison-hiver` saison lake trout (Lakes outside or partly outside the BWCAW, winter) 2026-01-17→2026-03-31 {} [incertain] ; appui : `MN-laketrout-saison-hiver` saison Lake Trout (État) 01-17→03-31 {} [incertain]

Relecture : les limites de truite de B (lacs l'été et l'hiver, ruisseaux du Sud-Est : 5) sont confirmées par `MN-brook-ruisseau-limite` de A, écrite à l'échelle de l'État alors que A parle des ruisseaux (le mot n'est que dans l'identifiant). La valeur est juste partout (5 dans le livret, cité par B), mais l'appui est fortuit : **trop laxiste en principe**, sans erreur ici. Même chose pour le touladi d'hiver (2) confirmé par la limite d'été de A (2).
