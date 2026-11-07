# WI : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py WI` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 88 règles (20 incertain) ; lecture B : 97 règles (30 incertain).
- Confirmées par les deux : 58, dont 39 sans réserve (chargées dans l'app) et 19 incertaines (non chargées).
- À vérifier : seulement A 49, seulement B 43.
- Désaccords listés : 87 — (i) forme sans conséquence : 23, (ii) conflit de fond : 0, (iii) couverture : 25, (iv) incertain d'un côté : 39.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (23)

1. **A et B seules** — nombres {'nombre': 0.0} / {}; code catch_release_hors_saison / prise_relacher_hors_periode_recolte
   - A : `WI-lmb-relacher` relacher Largemouth Bass (État) {"code": "catch_release_hors_saison", "nombre": 0}
     > All other times of the year. 0 (catch and release only)
   - B : `wi-b-005` relacher Largemouth bass (État) {"code": "prise_relacher_hors_periode_recolte"}
     > LARGEMOUTH and SMALLMOUTH BASS Statewide - all inland waters All other times of the year. 0 (catch and release only)
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
2. **A et B seules** — portée « Northern Zone » / « Northern Bass Management Zone »
   - A : `WI-smb-saison-nord` saison Smallmouth Bass (Northern Zone) 06-20→03-07 {}
     > SMALLMOUTH BASS (SMB) HARVEST Northern Zone (see map on page 12) June 20, 2026 – March 7, 2027
   - B : `wi-b-006` saison Smallmouth bass (Northern Bass Management Zone) 06-20→03-07 {}
     > June 20, 2026 – March 7, 2027 5 in total with LMB 14 inches
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
3. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Southern Bass Management Zone »
   - A : `WI-smb-limite_jour` limite_jour Smallmouth Bass (État) {"nombre": 5}
     > Other inland waters May 2, 2026 – March 7, 2027 5 in total with LMB 14 inches
   - B : `wi-b-009` limite_jour Smallmouth bass (Southern Bass Management Zone) {"nombre": 5}
     > Five largemouth or smallmouth bass in combination may be kept and they must be at least 14”.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
4. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Southern Bass Management Zone »
   - A : `WI-smb-taille_min` taille_min Smallmouth Bass (État) {"pouces": 14}
     > Other inland waters May 2, 2026 – March 7, 2027 5 in total with LMB 14 inches
   - B : `wi-b-008` taille_min Smallmouth bass (Southern Bass Management Zone) {"pouces": 14}
     > Five largemouth or smallmouth bass in combination may be kept and they must be at least 14”.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
5. **A et B seules** — nombres {'nombre': 0.0} / {}; code catch_release_hors_saison / prise_relacher_hors_periode_recolte
   - A : `WI-smb-relacher` relacher Smallmouth Bass (État) {"code": "catch_release_hors_saison", "nombre": 0}
     > LARGEMOUTH and SMALLMOUTH BASS Statewide - all inland waters All other times of the year.
   - B : `wi-b-011` relacher Smallmouth bass (État) {"code": "prise_relacher_hors_periode_recolte"}
     > LARGEMOUTH and SMALLMOUTH BASS Statewide - all inland waters All other times of the year. 0 (catch and release only)
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
6. **A seule (B appariée est confirmée ailleurs)** — type autre / limite_possession; nombres {} / {'nombre': 10.0}
   - A : `WI-bass-total_daily_bag` autre Largemouth Bass (État) {}
     > Largemouth and smallmouth bass 5 in total 10 in total
   - B : `wi-b-004` limite_possession Largemouth bass (État) {"nombre": 10}
     > Largemouth and smallmouth bass 5 in total 10 in total
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
7. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-walleye-saison` saison Walleye (État) 05-02→03-07 {}
     > WALLEYE and SAUGER (INCLUDES HYBRIDS) Most waters in the Ceded Territory (see page 13 for map and further information) May 2, 2026 – March 7, 2027
   - B : `wi-b-012` saison Walleye (Most other inland waters) 05-02→03-07 {}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
8. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-walleye-limite_jour` limite_jour Walleye (État) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-014` limite_jour Walleye (Most other inland waters) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
9. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-sauger-saison` saison Sauger (État) 05-02→03-07 {}
     > WALLEYE and SAUGER (INCLUDES HYBRIDS) Most waters in the Ceded Territory (see page 13 for map and further information) May 2, 2026 – March 7, 2027
   - B : `wi-b-018` saison Sauger (Most other inland waters) 05-02→03-07 {}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
10. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-sauger-limite_jour` limite_jour Sauger (État) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-020` limite_jour Sauger (Most other inland waters) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
11. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `WI-crappie-saison` saison Crappie (État) 01-01→12-31 {}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - B : `wi-b-040` saison White crappie (État) 01-01→12-31 {}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
12. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `WI-crappie-limite_jour` limite_jour Crappie (État) {"nombre": 25}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - B : `wi-b-041` limite_jour White crappie (État) {"nombre": 25}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
13. **A et B seules** — code ferme_toute_annee / fermee_autres_eaux_interieures; portée « État » / « Other inland waters »
   - A : `WI-sturgeon-fermeture-autres` fermeture Lake Sturgeon (État) {"code": "ferme_toute_annee"}
     > Other inland waters Closed all year — no fishing for lake sturgeon
   - B : `wi-b-054` fermeture Lake sturgeon (Other inland waters) {"code": "fermee_autres_eaux_interieures"}
     > Other inland waters Closed all year — no fishing for lake sturgeon
   - Avis sur l'outil : trop strict, sans correction possible sûre : même fermeture des autres eaux intérieures, codes libres différents ; A la met à l'échelle de l'État, ce qui serait faux sur les eaux listées
14. **A et B seules** — code ligne_surveillee_100_yards / ligne_sans_surveillance_100_yards
   - A : `WI-engin-ligne_surveillee` engin toutes (État) {"code": "ligne_surveillee_100_yards"}
     > anglers must remain within 100 yards of their line(s).
   - B : `wi-b-077` engin toutes (État) {"code": "ligne_sans_surveillance_100_yards"}
     > anglers must remain within 100 yards of their line(s).
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
15. **A et B seules** — type engin / interdit; code pas_jug_pas_drone / drone_et_jug_fishing
   - A : `WI-engin-pas_jug_drone` engin toutes (État) {"code": "pas_jug_pas_drone"}
     > to fish with an unmanned aircraft system, such as a drone, or to fish using the technique known as “jug” fishing
   - B : `wi-b-078` interdit toutes (État) {"code": "drone_et_jug_fishing"}
     > to fish with an unmanned aircraft system, such as a drone, or to fish using the technique known as “jug” fishing in all waters of the state.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
16. **A et B seules** — type engin / interdit; code pas_accrochage / peche_accrochage_foulhook
   - A : `WI-engin-pas_accrochage` engin toutes (État) {"code": "pas_accrochage"}
     > to keep foul-hooked, snagged or any fish not hooked in the mouth.
   - B : `wi-b-080` interdit toutes (État) {"code": "peche_accrochage_foulhook"}
     > to keep foul-hooked, snagged or any fish not hooked in the mouth.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
17. **A et B seules** — code trou_glace_max_12_pouces / trou_glace_12_pouces
   - A : `WI-engin-trou_glace_12` engin toutes (État) {"pouces": 12, "code": "trou_glace_max_12_pouces"}
     > Fishing holes cut through the ice cannot measure more than 12” across.
   - B : `wi-b-082` engin toutes (État) {"code": "trou_glace_12_pouces", "pouces": 12}
     > Fishing holes cut through the ice cannot measure more than 12” across.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
18. **A et B seules** — type engin / interdit; code pas_dispositif_largage_plomb / armes_a_feu_et_sinker_release
   - A : `WI-engin-pas_sinker_release` engin toutes (État) {"code": "pas_dispositif_largage_plomb"}
     > to possess or use a sinker release device while fishing.
   - B : `wi-b-081` interdit toutes (État) {"code": "armes_a_feu_et_sinker_release"}
     > to possess or use a sinker release device while fishing.
   - Avis sur l'outil : juste : B a réuni deux alinéas (armes à feu, largage de plomb) en une règle ; rien n'est comparable code à code
19. **A et B seules** — nombres {'taille': 8.0} / {}; code minnow_8_pouces_quick_strike_ou_cercle / minnow_8_pouces_quick_strike
   - A : `WI-appat-minnow_8_pouces` appat toutes (État) {"pouces": 8, "code": "minnow_8_pouces_quick_strike_ou_cercle"}
     > to fish with a minnow 8” or longer unless using a “quick-strike rig” or a “non- offset circle hook.”
   - B : `wi-b-086` appat toutes (État) {"code": "minnow_8_pouces_quick_strike"}
     > to fish with a minnow 8” or longer unless using a “quick-strike rig” or a
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
20. **A et B seules** — type appat / interdit; code pas_ecrevisse_vivante / ecrevisses_vivantes
   - A : `WI-appat-pas_ecrevisse_vivante` appat toutes (État) {"code": "pas_ecrevisse_vivante"}
     > to possess live crayfish while fishing or while possessing angling equipment on any water.
   - B : `wi-b-087` interdit toutes (État) {"code": "ecrevisses_vivantes"}
     > to possess live crayfish while fishing or while possessing angling equipment on any water.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
21. **A et B seules** — type appat / interdit; code pas_goldfish_gobie_alewife / poisson_rouge_gobies_alewife
   - A : `WI-appat-pas_goldfish_gobie_alewife` appat toutes (État) {"code": "pas_goldfish_gobie_alewife"}
     > to use goldfish, gobies or alewife in any form for bait in state waters
   - B : `wi-b-088` interdit toutes (État) {"code": "poisson_rouge_gobies_alewife"}
     > to use goldfish, gobies or alewife in any form for bait in state waters
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
22. **A et B seules** — type appat / interdit; code pas_relacher_appat_inutilise / relache_appat_non_utilise
   - A : `WI-appat-pas_relacher_restes` appat toutes (État) {"code": "pas_relacher_appat_inutilise"}
     > to release unused bait into Wisconsin’s lakes, ponds, rivers and streams.
   - B : `wi-b-093` interdit toutes (État) {"code": "relache_appat_non_utilise"}
     > to release unused bait into Wisconsin’s lakes, ponds, rivers and streams.
   - Avis sur l'outil : trop strict : même valeur classée sous deux types (limite du jour / possession / autre, engin / interdit)
23. **A et B seules** — code poisson_gibier_comme_appat_limite / gibier_comme_appat
   - A : `WI-appat-poisson_gibier` appat toutes (État) {"code": "poisson_gibier_comme_appat_limite"}
     > to use gamefish as bait unless they meet any length restriction for the water body you are fishing and are included in your daily bag limit for that species.
   - B : `wi-b-091` appat toutes (État) {"code": "gibier_comme_appat"}
     > to use gamefish as bait unless they meet any length restriction for the water
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)

## (iii) couverture (25)

1. **A seule** — lue par A seulement
   - A : `WI-walleye-total_daily_bag` autre Walleye (État) {}
     > Walleye, sauger, and hybrids (saugeye) 5 in total 10 in total
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement
   - A : `WI-pumpkinseed-saison` saison Pumpkinseed (État) 01-01→12-31 {}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement
   - A : `WI-pumpkinseed-limite_jour` limite_jour Pumpkinseed (État) {"nombre": 25}
     > PANFISH: BLUEGILL, PUMPKINSEED, SUNFISH, CRAPPIE and YELLOW PERCH Open all year 25 in total None
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement
   - A : `WI-pumpkinseed-limite_possession` limite_possession Pumpkinseed (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement
   - A : `WI-catfish-total_daily_bag` autre Channel Catfish (État) {}
     > However, the total daily bag limit is 25. That means you can combine your catch from multiple waters in a single day
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement (marquée incertain)
   - A : `WI-sturgeon-taille_min-recolte` taille_min Lake Sturgeon (Eaux listées p. 72 (récolte)) {"pouces": 60} [incertain]
     > 1 per season 60 inches
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement
   - A : `WI-trout-appat-artificiel` appat Brook Trout (État) {"code": "leurres_artificiels_seulement_certaines_eaux"}
     > to possess any bait on waters where only the use of artificial lures is authorized.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement
   - A : `WI-engin-pas_arme` engin toutes (État) {"code": "pas_arme_feu_air"}
     > to take fish using a firearm, air gun or similar device.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement
   - A : `WI-engin-pas_tri` relacher toutes (État) {"code": "pas_de_tri_culling"}
     > to sort or cull fish, except as authorized under certain bass fishing tournament permits.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **A seule** — lue par A seulement
   - A : `WI-appat-pas_deplacer_poisson_vivant` appat toutes (État) {"code": "pas_deplacer_poisson_vivant"}
     > to move live fish away from a water, except minnows that were purchased from a bait dealer
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
11. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-049` engin Channel catfish (État) {"code": "arc_ou_main"} [incertain]
     > Channel and flathead catfish may be harvested by bowfishing or by hand.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
12. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-053` engin Flathead catfish (État) {"code": "arc_ou_main"} [incertain]
     > Channel and flathead catfish may be harvested by bowfishing or by hand.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
13. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-062` relacher Brook trout (Early Season Streams And Rivers) 01-03→04-03 {"code": "saison_precoce_prise_relache"} [incertain]
     > All trout caught during this time must be immediately released
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
14. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-067` relacher Brown trout (Early Season Streams And Rivers) 01-03→04-03 {"code": "saison_precoce_prise_relache"} [incertain]
     > All trout caught during this time must be immediately released
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
15. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-072` relacher Rainbow trout (Early Season Streams And Rivers) 01-03→04-03 {"code": "saison_precoce_prise_relache"} [incertain]
     > All trout caught during this time must be immediately released
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
16. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `wi-b-083` engin toutes (État) {"code": "trolling_moteur", "lignes_max": 3, "hamecons_max": 1} [incertain]
     > Motor trolling is legal on all inland waters with either: • One hook, bait or lure/person: maximum of three lines trolled per boat or
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
17. **B seule** — 
   - A : —
   - B : `wi-b-084` engin toutes (État) {"code": "conservation_filets_et_preuve_photo"}
     > to transport fish subject to a length limit, unless the fillets meet the minimum length requirement
   - Avis sur l'outil : juste : règle (conservation des filets, preuve photo) lue par B seulement
18. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-085` interdit toutes (État) {"code": "interdit_tri_culling"}
     > to sort or cull fish, except as authorized under certain bass fishing tournament permits.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
19. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-089` appat toutes (État) {"code": "larves_insectes_ruisseau_truite"}
     > to remove insect larvae from a trout stream, except that a licensed angler may
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
20. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-090` interdit toutes (État) {"code": "oeufs_poisson_sous_taille"}
     > to remove fish eggs for bait from under-sized fish, fish caught during the closed season for that species or fish caught by illegal methods
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
21. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-092` interdit toutes (État) {"code": "appat_sur_eaux_leurres_seuls"}
     > to possess any bait on waters where only the use of artificial lures is authorized.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
22. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-094` fermeture toutes (État) {"code": "poisson_hors_saison"}
     > to fish for a species of fish during the closed season for that species (includes catch and release fishing).
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
23. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-095` fermeture toutes (État) {"code": "pecher_ruisseau_truite_ferme"}
     > to fish in trout streams for any species of fish when the trout season is closed, except that rough fish may be taken by hand.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
24. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-096` fermeture toutes (État) {"code": "refuges_no_fishing"}
     > to fish in fish refuges.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
25. **B seule** — lue par B seulement
   - A : —
   - B : `wi-b-097` fermeture toutes (État) {"code": "200_pieds_barrage_ecluse"}
     > to fish within 200 feet of a fishway, lock or dam, except that fish may be taken
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (39)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-lmb-saison` saison Largemouth Bass (État) 05-02→03-07 {} [incertain]
     > LARGEMOUTH BASS (LMB) HARVEST May 2, 2026 – March 7, 2027 5 14 inches
   - B : `wi-b-001` saison Largemouth bass (État) 05-02→03-07 {}
     > LARGEMOUTH BASS (LMB) HARVEST May 2, 2026 – March 7, 2027 5 14 inches
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-pike-limite_possession-nord` limite_possession Northern Pike (Northern Zone) {"nombre": 10} [incertain]
     > Northern pike All waters north of U.S. Hwy 10 5 in total 10 in total All waters south of U.S. Hwy 10 2 in total
   - B : `wi-b-026` limite_possession Northern pike (Northern Zone (north of US Hwy 10)) {"nombre": 10} [incertain]
     > All waters north of U.S. Hwy 10 5 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-bluegill-limite_possession` limite_possession Bluegill (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : `wi-b-036` limite_possession Bluegill (État) {"nombre": 50} [incertain]
     > 25 in total 50 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-yellow_perch-limite_possession` limite_possession Yellow Perch (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : `wi-b-045` limite_possession Yellow perch (État) {"nombre": 50} [incertain]
     > 25 in total 50 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-channel_catfish-limite_possession` limite_possession Channel Catfish (État) {"nombre": 50}
     > Catfish 25 in total; only one may be a flathead catfish if fishing Winnebago system waters (see page 91). 50 in total
   - B : `wi-b-048` limite_possession Channel catfish (État) {"nombre": 50} [incertain]
     > Catfish 25 in total; only one
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
6. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-flathead_catfish-limite_possession` limite_possession Flathead Catfish (État) {"nombre": 50}
     > Catfish 25 in total; only one may be a flathead catfish if fishing Winnebago system waters (see page 91). 50 in total
   - B : `wi-b-052` limite_possession Flathead catfish (État) {"nombre": 50} [incertain]
     > Catfish 25 in total; only one
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
7. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-sturgeon-limite_jour-recolte` limite_jour Lake Sturgeon (Eaux listées p. 72 (récolte)) {"nombre": 1} [incertain]
     > 1 per season 60 inches
   - B : `wi-b-055` limite_jour Lake sturgeon (État) {"nombre": 1}
     > Lake sturgeon 1 per season 2 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
8. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-brook-saison-cours_d_eau` saison Brook Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain]
     > General inland trout, streams, springs and spring ponds: April 4, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-060` saison Brook trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
9. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-brown-saison-cours_d_eau` saison Brown Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain]
     > General inland trout, streams, springs and spring ponds: April 4, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-065` saison Brown trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
10. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `WI-rainbow-saison-cours_d_eau` saison Rainbow Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain]
     > General inland trout, streams, springs and spring ponds: April 4, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-070` saison Rainbow trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
11. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-walleye-taille_min` taille_min Walleye (État) {"pouces": 15} [incertain]
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-013` taille_min Walleye (Most other inland waters) {"pouces": 15}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
12. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-walleye-limite_jour` limite_jour Walleye (État) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-017` limite_jour Walleye (Ceded Territory (northern Wisconsin)) {"nombre": 3} [incertain]
     > Inland lakes and rivers within the Ceded Territory have a daily bag limit of three
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
13. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-sauger-taille_min` taille_min Sauger (État) {"pouces": 15} [incertain]
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-019` taille_min Sauger (Most other inland waters) {"pouces": 15}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
14. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-sauger-limite_jour` limite_jour Sauger (État) {"nombre": 3}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-023` limite_jour Sauger (Ceded Territory (northern Wisconsin)) {"nombre": 3} [incertain]
     > Inland lakes and rivers within the Ceded Territory have a daily bag limit of three
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
15. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-crappie-limite_possession` limite_possession Crappie (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : `wi-b-039` limite_possession Black crappie (État) {"nombre": 50} [incertain]
     > 25 in total 50 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
16. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-crappie-limite_possession` limite_possession Crappie (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : `wi-b-042` limite_possession White crappie (État) {"nombre": 50} [incertain]
     > 25 in total 50 in total
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
17. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-brook-limite_jour` limite_jour Brook Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-063` limite_jour Brook trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
18. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-brown-limite_jour` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-068` limite_jour Brown trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
19. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `WI-rainbow-limite_jour` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-073` limite_jour Rainbow trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
20. **A et B seules** — portée « Other inland waters (hors Northern Zone) » / « Southern Bass Management Zone »
   - A : `WI-smb-saison-autres` saison Smallmouth Bass (Other inland waters (hors Northern Zone)) 05-02→03-07 {} [incertain]
     > Other inland waters May 2, 2026 – March 7, 2027 5 in total with LMB 14 inches
   - B : `wi-b-007` saison Smallmouth bass (Southern Bass Management Zone) 05-02→03-07 {}
     > Other inland waters May 2, 2026 – March 7, 2027 5 in total with LMB 14 inches
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
21. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-walleye-taille_min` taille_min Walleye (État) {"pouces": 15} [incertain]
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-013` taille_min Walleye (Most other inland waters) {"pouces": 15}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
22. **A et B seules** — nombres {'taille_min': 15.0, 'taille_max': 20.0} / {'taille_min': 20.0, 'taille_max': 24.0}; mode relacher_en_dessous / relacher_entre
   - A : `WI-walleye-fenetre-ceded` fenetre Walleye (Ceded Territory) {"pouces_min": 15, "pouces_max": 20, "mode": "relacher_en_dessous"} [incertain]
     > Most waters in the Ceded Territory (see page 13 for map and further information) May 2, 2026 – March 7, 2027 3 in total 15 inches but less than 20 inches may be kept; with one over 24 inches
   - B : `wi-b-016` fenetre Walleye (Ceded Territory (northern Wisconsin)) {"pouces_min": 20, "pouces_max": 24, "mode": "relacher_entre"} [incertain]
     > sauger from 15” but less than 20” may be kept, except one fish may be over 24”.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
23. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Most other inland waters »
   - A : `WI-sauger-taille_min` taille_min Sauger (État) {"pouces": 15} [incertain]
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - B : `wi-b-019` taille_min Sauger (Most other inland waters) {"pouces": 15}
     > Most other inland waters. May 2, 2026 – March 7, 2027 3 in total 15 inches
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
24. **A et B seules** — nombres {'taille_min': 15.0, 'taille_max': 20.0} / {'taille_min': 20.0, 'taille_max': 24.0}; mode relacher_en_dessous / relacher_entre
   - A : `WI-sauger-fenetre-ceded` fenetre Sauger (Ceded Territory) {"pouces_min": 15, "pouces_max": 20, "mode": "relacher_en_dessous"} [incertain]
     > Most waters in the Ceded Territory (see page 13 for map and further information) May 2, 2026 – March 7, 2027 3 in total 15 inches but less than 20 inches may be kept; with one over 24 inches
   - B : `wi-b-022` fenetre Sauger (Ceded Territory (northern Wisconsin)) {"pouces_min": 20, "pouces_max": 24, "mode": "relacher_entre"} [incertain]
     > sauger from 15” but less than 20” may be kept, except one fish may be over 24”.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
25. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `WI-crappie-limite_possession` limite_possession Crappie (État) {"nombre": 50}
     > Panfish (bluegill, pumpkinseed, yellow perch, white and black crappie) 25 in total 50 in total
   - B : `wi-b-042` limite_possession White crappie (État) {"nombre": 50} [incertain]
     > 25 in total 50 in total
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
26. **A et B seules** — portée « Eaux listées p. 72 (récolte) » / « Listed waters (see table p. 72-73) »
   - A : `WI-sturgeon-saison-recolte` saison Lake Sturgeon (Eaux listées p. 72 (récolte)) 09-05→09-30 {} [incertain]
     > – Sept. 30, 2026 (All Lake
   - B : `wi-b-058` saison Lake sturgeon (Listed waters (see table p. 72-73)) 09-05→09-30 {} [incertain]
     > – Sept. 30, 2026 (All Lake
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
27. **A et B seules** — type saison / relacher; code None / prise_relacher_seulement_eaux_listees; portée « Eaux listées p. 72-73 (remise à l'eau) » / « Listed waters (see table p. 72-73) »
   - A : `WI-sturgeon-relacher-cr` saison Lake Sturgeon (Eaux listées p. 72-73 (remise à l'eau)) 06-06→03-07 {} [incertain]
     > June 6, 2026 – March 7, 2027 0 (catch and release only)
   - B : `wi-b-059` relacher Lake sturgeon (Listed waters (see table p. 72-73)) 06-06→03-07 {"code": "prise_relacher_seulement_eaux_listees"} [incertain]
     > June 6, 2026 – March 7, 2027 0 (catch and release only)
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
28. **A et B seules** — dates ('05-02', '10-15') / ('04-04', '10-15'); portée « Lakes and ponds » / « État »
   - A : `WI-brook-saison-lacs` saison Brook Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-060` saison Brook trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
29. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Counties/waters in base category Green »
   - A : `WI-brook-limite_jour` limite_jour Brook Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-063` limite_jour Brook trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
30. **A et B seules** — dates ('05-02', '10-15') / ('04-04', '10-15'); portée « Lakes and ponds » / « État »
   - A : `WI-brown-saison-lacs` saison Brown Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-065` saison Brown trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
31. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Counties/waters in base category Green »
   - A : `WI-brown-limite_jour` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-068` limite_jour Brown trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
32. **A et B seules** — dates ('05-02', '10-15') / ('04-04', '10-15'); portée « Lakes and ponds » / « État »
   - A : `WI-rainbow-saison-lacs` saison Rainbow Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-070` saison Rainbow trout (État) 04-04→10-15 {} [incertain]
     > General Open Season for trout and salmon in inland streams, springs and spring ponds - First Saturday in April
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
33. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Counties/waters in base category Green »
   - A : `WI-rainbow-limite_jour` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]
     > The total daily bag limit is 5 trout and salmon in total, but only 2 may be lake trout
   - B : `wi-b-073` limite_jour Rainbow trout (Counties/waters in base category Green) {"nombre": 5} [incertain]
     > Daily bag limit and length limit: 5 trout in total of any length
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
34. **A et B seules** — type engin / interdit; code ligne_hamecon_seulement / ligne_et_hamecon_seulement
   - A : `WI-engin-hook_and_line` engin toutes (État) {"code": "ligne_hamecon_seulement"}
     > to take fish by any means other than hook and line unless otherwise allowed.
   - B : `wi-b-076` interdit toutes (État) {"code": "ligne_et_hamecon_seulement"} [incertain]
     > to take fish by any means other than hook and line unless otherwise allowed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
35. **A et B seules** — type engin / interdit; code pas_harpon_senne_filet_trappe / harpons_filets_pieges_hors_exceptions
   - A : `WI-engin-pas_harpon_filet` engin toutes (État) {"code": "pas_harpon_senne_filet_trappe"}
     > to possess or use spears, snag hooks, gill nets, trammel nets, hoop nets or fish traps (except where authorized)
   - B : `wi-b-079` interdit toutes (État) {"code": "harpons_filets_pieges_hors_exceptions"} [incertain]
     > to possess or use spears, snag hooks, gill nets, trammel nets, hoop nets or fish traps (except where authorized)
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
36. **B seule (A appariée est confirmée ailleurs)** — portée « Eaux listées p. 72 (récolte) » / « État »
   - A : `WI-sturgeon-limite_jour-recolte` limite_jour Lake Sturgeon (Eaux listées p. 72 (récolte)) {"nombre": 1} [incertain]
     > 1 per season 60 inches
   - B : `wi-b-055` limite_jour Lake sturgeon (État) {"nombre": 1}
     > Lake sturgeon 1 per season 2 in total
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
37. **A et B seules** — dates ('05-02', '10-15') / ('05-02', '03-07'); portée « Lakes and ponds » / « État »
   - A : `WI-brook-saison-lacs` saison Brook Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-061` saison Brook trout (État) 05-02→03-07 {} [incertain]
     > May 2, 2026 – March 7, 2027
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
38. **A et B seules** — dates ('05-02', '10-15') / ('05-02', '03-07'); portée « Lakes and ponds » / « État »
   - A : `WI-brown-saison-lacs` saison Brown Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-066` saison Brown trout (État) 05-02→03-07 {} [incertain]
     > May 2, 2026 – March 7, 2027
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
39. **A et B seules** — dates ('05-02', '10-15') / ('05-02', '03-07'); portée « Lakes and ponds » / « État »
   - A : `WI-rainbow-saison-lacs` saison Rainbow Trout (Lakes and ponds) 05-02→10-15 {} [incertain]
     > General inland trout, lakes and ponds: May 2, 2026 (5 a.m.) - Oct. 15, 2026
   - B : `wi-b-071` saison Rainbow trout (État) 05-02→03-07 {} [incertain]
     > May 2, 2026 – March 7, 2027
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (23)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. portée plus fine — gardée : `wi-b-008` taille_min Smallmouth bass (Southern Bass Management Zone) {"pouces": 14} ; appui : `WI-smb-taille_min` taille_min Smallmouth Bass (État) {"pouces": 14}
2. portée plus fine — gardée : `wi-b-009` limite_jour Smallmouth bass (Southern Bass Management Zone) {"nombre": 5} ; appui : `WI-smb-limite_jour` limite_jour Smallmouth Bass (État) {"nombre": 5}
3. portée plus fine — gardée : `wi-b-012` saison Walleye (Most other inland waters) 05-02→03-07 {} ; appui : `WI-walleye-saison` saison Walleye (État) 05-02→03-07 {}
4. portée plus fine — gardée : `wi-b-014` limite_jour Walleye (Most other inland waters) {"nombre": 3} ; appui : `WI-walleye-limite_jour` limite_jour Walleye (État) {"nombre": 3}
5. portée plus fine — gardée : `wi-b-018` saison Sauger (Most other inland waters) 05-02→03-07 {} ; appui : `WI-sauger-saison` saison Sauger (État) 05-02→03-07 {}
6. portée plus fine — gardée : `wi-b-020` limite_jour Sauger (Most other inland waters) {"nombre": 3} ; appui : `WI-sauger-limite_jour` limite_jour Sauger (État) {"nombre": 3}
7. espèce d'un groupe — gardée : `wi-b-037` saison Black crappie (État) 01-01→12-31 {} ; appui : `WI-crappie-saison` saison Crappie (État) 01-01→12-31 {}
8. espèce d'un groupe — gardée : `wi-b-038` limite_jour Black crappie (État) {"nombre": 25} ; appui : `WI-crappie-limite_jour` limite_jour Crappie (État) {"nombre": 25}
9. espèce d'un groupe — gardée : `wi-b-040` saison White crappie (État) 01-01→12-31 {} ; appui : `WI-crappie-saison` saison Crappie (État) 01-01→12-31 {}
10. espèce d'un groupe — gardée : `wi-b-041` limite_jour White crappie (État) {"nombre": 25} ; appui : `WI-crappie-limite_jour` limite_jour Crappie (État) {"nombre": 25}
11. portée plus fine — gardée : `WI-sturgeon-limite_jour-recolte` limite_jour Lake Sturgeon (Eaux listées p. 72 (récolte)) {"nombre": 1} [incertain] ; appui : `wi-b-055` limite_jour Lake sturgeon (État) {"nombre": 1}
12. portée plus fine — gardée : `WI-brook-saison-cours_d_eau` saison Brook Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain] ; appui : `wi-b-060` saison Brook trout (État) 04-04→10-15 {} [incertain]
13. portée plus fine — gardée : `WI-brown-saison-cours_d_eau` saison Brown Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain] ; appui : `wi-b-065` saison Brown trout (État) 04-04→10-15 {} [incertain]
14. portée plus fine — gardée : `WI-rainbow-saison-cours_d_eau` saison Rainbow Trout (Streams, springs and spring ponds) 04-04→10-15 {} [incertain] ; appui : `wi-b-070` saison Rainbow trout (État) 04-04→10-15 {} [incertain]
15. portée plus fine — gardée : `wi-b-013` taille_min Walleye (Most other inland waters) {"pouces": 15} [incertain] ; appui : `WI-walleye-taille_min` taille_min Walleye (État) {"pouces": 15} [incertain]
16. portée plus fine — gardée : `wi-b-017` limite_jour Walleye (Ceded Territory (northern Wisconsin)) {"nombre": 3} [incertain] ; appui : `WI-walleye-limite_jour` limite_jour Walleye (État) {"nombre": 3}
17. portée plus fine — gardée : `wi-b-019` taille_min Sauger (Most other inland waters) {"pouces": 15} [incertain] ; appui : `WI-sauger-taille_min` taille_min Sauger (État) {"pouces": 15} [incertain]
18. portée plus fine — gardée : `wi-b-023` limite_jour Sauger (Ceded Territory (northern Wisconsin)) {"nombre": 3} [incertain] ; appui : `WI-sauger-limite_jour` limite_jour Sauger (État) {"nombre": 3}
19. espèce d'un groupe — gardée : `wi-b-039` limite_possession Black crappie (État) {"nombre": 50} [incertain] ; appui : `WI-crappie-limite_possession` limite_possession Crappie (État) {"nombre": 50}
20. espèce d'un groupe — gardée : `wi-b-042` limite_possession White crappie (État) {"nombre": 50} [incertain] ; appui : `WI-crappie-limite_possession` limite_possession Crappie (État) {"nombre": 50}
21. portée plus fine — gardée : `wi-b-063` limite_jour Brook trout (Counties/waters in base category Green) {"nombre": 5} [incertain] ; appui : `WI-brook-limite_jour` limite_jour Brook Trout (État) {"nombre": 5} [incertain]
22. portée plus fine — gardée : `wi-b-068` limite_jour Brown trout (Counties/waters in base category Green) {"nombre": 5} [incertain] ; appui : `WI-brown-limite_jour` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
23. portée plus fine — gardée : `wi-b-073` limite_jour Rainbow trout (Counties/waters in base category Green) {"nombre": 5} [incertain] ; appui : `WI-rainbow-limite_jour` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]

Relecture : les règles de zone de B (« Most other inland waters », « Southern Bass Management Zone ») confirmées par des règles d'État de A ont la même valeur dans le livret : appuis justes. Les espèces de crapet (black, white) confirmées par « Crappie » de A : justes (le livret donne une seule ligne crappie).
