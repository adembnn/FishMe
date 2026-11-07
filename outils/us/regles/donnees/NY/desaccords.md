# NY : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py NY` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 89 règles (18 incertain) ; lecture B : 103 règles (23 incertain).
- Confirmées par les deux : 67, dont 53 sans réserve (chargées dans l'app) et 14 incertaines (non chargées).
- À vérifier : seulement A 38, seulement B 40.
- Désaccords listés : 69 — (i) forme sans conséquence : 21, (ii) conflit de fond : 0, (iii) couverture : 22, (iv) incertain d'un côté : 26.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (21)

1. **A et B seules** — code capture_et_remise_a_l_eau_seulement / prise_relacher_hors_periode_recolte
   - A : `NY-largemouth-bass-relacher-3` relacher Largemouth Bass (État) 12-01→06-14 {"code": "capture_et_remise_a_l_eau_seulement"}
     > Dec 1 - June 14 | Catch and Release only. Artificial lures only
   - B : `b-004` relacher largemouth bass (État) 12-01→06-14 {"code": "prise_relacher_hors_periode_recolte"}
     > Dec 1 - June 14 Catch and Release only. Artificial lures only
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
2. **A et B seules** — code capture_et_remise_a_l_eau_seulement / prise_relacher_hors_periode_recolte
   - A : `NY-smallmouth-bass-relacher-8` relacher Smallmouth Bass (État) 12-01→06-14 {"code": "capture_et_remise_a_l_eau_seulement"}
     > Dec 1 - June 14 | Catch and Release only. Artificial lures only
   - B : `b-009` relacher smallmouth bass (État) 12-01→06-14 {"code": "prise_relacher_hors_periode_recolte"}
     > Dec 1 - June 14 Catch and Release only. Artificial lures only
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
3. **A et B seules** — nombres {'taille': 12.0, 'nombre': 2.0} / {}; code None / max_2_de_plus_de_12_pouces
   - A : `NY-brown-trout-autre-35` autre Brown Trout (État) {"nombre": 2, "pouces": 12}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-030` autre brown trout (État) {"code": "max_2_de_plus_de_12_pouces"}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
4. **A et B seules** — nombres {'taille': 12.0, 'nombre': 2.0} / {}; code None / max_2_de_plus_de_12_pouces
   - A : `NY-rainbow-trout-autre-38` autre Rainbow Trout (État) {"nombre": 2, "pouces": 12}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-033` autre rainbow trout (État) {"code": "max_2_de_plus_de_12_pouces"}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
5. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `NY-crappie-saison-51` saison Crappie (État) 01-01→12-31 {}
     > Crappie (Black and White) | All year | 10" | 25
   - B : `b-055` saison white crappie (État) 01-01→12-31 {}
     > Crappie (Black and White) All year 10" 25
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
6. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `NY-crappie-taille_min-52` taille_min Crappie (État) {"pouces": 10}
     > Crappie (Black and White) | All year | 10" | 25
   - B : `b-056` taille_min white crappie (État) {"pouces": 10}
     > Crappie (Black and White) All year 10" 25
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
7. **A seule (B appariée est confirmée ailleurs)** — espèces ['crappie'] / ['white crappie']
   - A : `NY-crappie-limite_jour-53` limite_jour Crappie (État) {"nombre": 25}
     > Crappie (Black and White) | All year | 10" | 25
   - B : `b-057` limite_jour white crappie (État) {"nombre": 25}
     > Crappie (Black and White) All year 10" 25
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
8. **A seule (B appariée est confirmée ailleurs)** — espèces ['sunfish'] / ['pumpkinseed']
   - A : `NY-sunfish-saison-56` saison Sunfish (État) 01-01→12-31 {}
     > Sunfish (Bluegill, Redbreast, and Pumpkinseed) | All year | None | 25
   - B : `b-064` saison pumpkinseed (État) 01-01→12-31 {}
     > Sunfish (Bluegill, Redbreast, and Pumpkinseed) All year None 25
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
9. **A seule (B appariée est confirmée ailleurs)** — espèces ['sunfish'] / ['pumpkinseed']
   - A : `NY-sunfish-limite_jour-57` limite_jour Sunfish (État) {"nombre": 25}
     > Sunfish (Bluegill, Redbreast, and Pumpkinseed) | All year | None | 25
   - B : `b-065` limite_jour pumpkinseed (État) {"nombre": 25}
     > Sunfish (Bluegill, Redbreast, and Pumpkinseed) All year None 25
   - Avis sur l'outil : juste : espèces écrites différemment (groupe d'un côté)
10. **A seule (B appariée est confirmée ailleurs)** — nombres {'nombre': 5.0} / {'lignes_max': 3.0}; code cinq_leurres_ou_appats_max_par_ligne / None
   - A : `NY-toutes-engin-64` engin toutes (État) {"code": "cinq_leurres_ou_appats_max_par_ligne", "nombre": 5}
     > Each line is limited to not more than 5 lures or baits or a combination of both.
   - B : `b-071` engin toutes (État) {"lignes_max": 3}
     > An angler may operate no more than 3 lines with or without a rod. Each line is limited to not more than 5 lures or baits or a combination of both.
   - Avis sur l'outil : trop strict : nombre en plus d'un côté (ex. hameçons écrits avec le code)
11. **A et B seules** — code presence_immediate_obligatoire / ligne_sans_surveillance_interdite
   - A : `NY-toutes-engin-66` engin toutes (État) {"code": "presence_immediate_obligatoire"}
     > Anglers must be in immediate attendance when their lines are in the water.The use of set lines where the angler is not in immediate attendance is prohibited.
   - B : `b-073` engin toutes (État) {"code": "ligne_sans_surveillance_interdite"}
     > The use of set lines where the angler is not in immediate attendance is prohibited.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
12. **A et B seules** — code gaffes_interdites / gaffes_interdites_sauf_glace_arbalete
   - A : `NY-toutes-engin-67` engin toutes (État) {"code": "gaffes_interdites"}
     > Use or possession of gaffs or gaff hooks is prohibited when fishing in freshwater, including the Hudson River upstream of the Mario M. Cuomo Bridge, except when ice fishing or while bowfishing.
   - B : `b-076` engin toutes (État) {"code": "gaffes_interdites_sauf_glace_arbalete"}
     > Use or possession of gaffs or gaff hooks is prohibited when fishing in freshwater, including the Hudson River upstream of the Mario M. Cuomo Bridge, except when ice fishing or while bowfishing.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
13. **A et B seules** — code pas_de_peche_en_saison_fermee_remise_a_l_eau_comprise / poisson_hors_saison
   - A : `NY-toutes-fermeture-72` fermeture toutes (État) {"code": "pas_de_peche_en_saison_fermee_remise_a_l_eau_comprise"}
     > A person may not fish for a species (including catch and release) during the closed season for that species on a given water.
   - B : `b-069` fermeture toutes (État) {"code": "poisson_hors_saison"}
     > A person may not fish for a species (including catch and release) during the closed season for that species on a given water.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
14. **A et B seules** — code remise_a_l_eau_sans_garder_dans_contenant / prise_relacher_seulement_en_saison
   - A : `NY-toutes-relacher-73` relacher toutes (État) {"code": "remise_a_l_eau_sans_garder_dans_contenant"}
     > Fish may not be placed in a bucket, tub, livewell, on a string or any other holding device.
   - B : `b-070` relacher toutes (État) {"code": "prise_relacher_seulement_en_saison"}
     > Catch and release angling is only permitted during the open season for a particular fish species.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
15. **A et B seules** — code pas_de_chumming_avec_oeufs / amorcage_oeufs_de_poisson_interdit
   - A : `NY-toutes-appat-81` appat toutes (État) {"code": "pas_de_chumming_avec_oeufs"}
     > No person shall take or attempt to take any fish by means of chumming (see Definitions) with fish eggs.
   - B : `b-102` appat toutes (État) {"code": "amorcage_oeufs_de_poisson_interdit"}
     > No person shall take or attempt to take any fish by means of chumming ( see Definitions ) with fish eggs.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
16. **A et B seules** — code pas_de_salamandres_serpents_indigenes / salamandres_serpents_interdits
   - A : `NY-toutes-appat-82` appat toutes (État) {"code": "pas_de_salamandres_serpents_indigenes"}
     > Native salamanders and snakes cannot be collected or used as bait.
   - B : `b-100` appat toutes (État) {"code": "salamandres_serpents_interdits"}
     > Native salamanders and snakes cannot be collected or used as bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
17. **A et B seules** — code especes_interdites_comme_appat / appat_interdit_european_rudd
   - A : `NY-toutes-appat-85` appat toutes (État) {"code": "especes_interdites_comme_appat"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - B : `b-098` appat toutes (État) {"code": "appat_interdit_european_rudd"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
18. **A et B seules** — code especes_interdites_comme_appat / appat_interdit_carp
   - A : `NY-toutes-appat-85` appat toutes (État) {"code": "especes_interdites_comme_appat"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - B : `b-094` appat toutes (État) {"code": "appat_interdit_carp"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
19. **A et B seules** — code especes_interdites_comme_appat / appat_interdit_goldfish
   - A : `NY-toutes-appat-85` appat toutes (État) {"code": "especes_interdites_comme_appat"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - B : `b-095` appat toutes (État) {"code": "appat_interdit_goldfish"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
20. **A et B seules** — code especes_interdites_comme_appat / appat_interdit_lamprey_larvae
   - A : `NY-toutes-appat-85` appat toutes (État) {"code": "especes_interdites_comme_appat"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - B : `b-096` appat toutes (État) {"code": "appat_interdit_lamprey_larvae"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
21. **A et B seules** — code especes_interdites_comme_appat / appat_interdit_round_goby
   - A : `NY-toutes-appat-85` appat toutes (État) {"code": "especes_interdites_comme_appat"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - B : `b-097` appat toutes (État) {"code": "appat_interdit_round_goby"}
     > Carp, goldfish, lamprey larvae, round goby, European rudd as well as species listed as endangered or threatened in New York State may not be used for bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)

## (iii) couverture (22)

1. **A seule** — lue par A seulement (marquée incertain)
   - A : `NY-lake-sturgeon-interdit-59` interdit Lake Sturgeon (État) {"code": "espece_menacee"} [incertain]
     > It is illegal to fish for, or possess fish that are officially listed by DEC as endangered or threatened:
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement
   - A : `NY-paddlefish-fermeture-61` fermeture Paddlefish (État) {"code": "peche_et_possession_interdites"}
     > Paddlefish, Sauger | Closed | Fishing for (including Catch and Release) or possession prohibited
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement (marquée incertain)
   - A : `NY-channel-catfish-saison-62` saison Channel Catfish (État) 01-01→12-31 {} [incertain]
     > Bullhead, Catfish, Carp, Cisco, Rock Bass, Sucker, White Bass, White Perch, and all other fishes not listed in this table | All year | Any size | Any number
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement (marquée incertain)
   - A : `NY-toutes-autre-69` autre toutes (État) {} [incertain]
     > Ice fishing is permitted for most waters in New York, except for those waters where Special Regulations specifically prohibit this activity and for waters within Essex, Franklin, Fulton, Hamilton,
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement
   - A : `NY-toutes-autre-71` autre toutes (État) {"code": "mesure_longueur_totale_bouche_ouverte_ou_fermee"}
     > Minimum length means the greatest possible length measured from the tip of the fish's snout to the tip of the tail.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement
   - A : `NY-toutes-autre-80` autre toutes (État) {"nombre": 1}
     > No person shall possess more than one quart total of fish eggs from trout, lake trout, or Atlantic salmon while on the waters of the state or the shores thereof.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement
   - A : `NY-toutes-appat-83` appat toutes (État) {"code": "pas_d_insectes_aquatiques_eaux_a_truites"}
     > No aquatic insect (or any insect that lives in the water during any of its life stages) shall be taken from waters inhabited by trout, or from the banks of those waters at any time.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement
   - A : `NY-toutes-appat-87` appat toutes (État) {"code": "pas_de_transport_routier_appat_collecte"}
     > Transportation of personally harvested baitfish overland by a motorized vehicle is prohibited except within a designated overland transportation corridor.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement (marquée incertain)
   - A : `NY-toutes-appat-88` appat toutes (État) {"code": "poissons_appats_eaux_interdites_voir_regions"} [incertain]
     > Select a DEC Region to view the list of waters where baitfish is prohibited:
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-068` autre channel catfish (État) {"code": "sans_taille_ni_limite_chiffrees"} [incertain]
     > Bullhead, Catfish, Carp, Cisco, Rock Bass, Sucker, White Bass, White Perch, and all other fishes not listed in this table All year Any size Any number
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
11. **B seule** — lue par B seulement
   - A : —
   - B : `b-075` engin toutes (État) 05-01→11-14 {"code": "canne_ou_ligne_a_main_seulement"}
     > Between May 1 and November 14, only hand lines (including rod and reels) may be used while ice fishing.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
12. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-077` interdit toutes (Essex County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
13. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-078` interdit toutes (Franklin County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
14. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-079` interdit toutes (Fulton County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
15. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-080` interdit toutes (Hamilton County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
16. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-081` interdit toutes (Herkimer County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
17. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-082` interdit toutes (Lewis County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
18. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-083` interdit toutes (St. Lawrence County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
19. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-084` interdit toutes (Warren County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
20. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-085` interdit toutes (Washington County) {"code": "peche_sur_glace_interdite"} [incertain]
     > and for waters within Essex, Franklin, Fulton, Hamilton, Herkimer, Lewis, St. Lawrence, Warren, and Washington counties.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
21. **B seule** — lue par B seulement
   - A : —
   - B : `b-086` saison common carp (État) 05-15→09-30 {"code": "arc_arbalete_seulement"}
     > Carp may be taken by a longbow (recurve or compound) or crossbow in any number or size from May 15-September 30 from any water where fishing and the discharge of a bow is permitted.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
22. **B seule** — lue par B seulement
   - A : —
   - B : `b-093` relacher snakehead (État) {"code": "remise_a_l_eau_interdite"}
     > Any snakehead caught while angling cannot be released back into the water. They must be immediately killed and reported to DEC.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (26)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brown-trout-limite_jour-34` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-029` limite_jour brown trout (État) {"nombre": 5}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-rainbow-trout-limite_jour-37` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-032` limite_jour rainbow trout (État) {"nombre": 5}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brook-trout-limite_jour-40` limite_jour Brook Trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams (see Definitions) | April 1 - Oct 15 | None | 5 with only 2 longer than 12"
   - B : `b-027` limite_jour brook trout (État) {"nombre": 5}
     > Brook Trout (in lakes and ponds) April 1 - Oct 15 None 5
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brook-trout-engin-42` engin Brook Trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-037` engin brook trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brown-trout-saison-43` saison Brown Trout (État) 04-01→10-15 {}
     > Trout in inland trout streams (see Definitions) | April 1 - Oct 15 | None | 5 with only 2 longer than 12"
   - B : `b-038` saison brown trout (État) 04-01→10-15 {} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
6. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brown-trout-limite_jour-44` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams (see Definitions) | April 1 - Oct 15 | None | 5 with only 2 longer than 12"
   - B : `b-029` limite_jour brown trout (État) {"nombre": 5}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
7. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-brown-trout-engin-46` engin Brown Trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-041` engin brown trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
8. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-rainbow-trout-saison-47` saison Rainbow Trout (État) 04-01→10-15 {}
     > Trout in inland trout streams (see Definitions) | April 1 - Oct 15 | None | 5 with only 2 longer than 12"
   - B : `b-042` saison rainbow trout (État) 04-01→10-15 {} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
9. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-rainbow-trout-limite_jour-48` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams (see Definitions) | April 1 - Oct 15 | None | 5 with only 2 longer than 12"
   - B : `b-032` limite_jour rainbow trout (État) {"nombre": 5}
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) All year None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
10. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `NY-rainbow-trout-engin-50` engin Rainbow Trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-045` engin rainbow trout (État) 10-16→03-31 {"code": "leurres_artificiels_seulement"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
11. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `NY-brook-trout-saison-31` saison Brook Trout (État) 04-01→10-15 {}
     > Brook Trout (in lakes and ponds) | April 1 - Oct 15 | None | 5
   - B : `b-034` saison brook trout (État) 04-01→10-15 {} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
12. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `NY-brook-trout-limite_jour-32` limite_jour Brook Trout (État) {"nombre": 5}
     > Brook Trout (in lakes and ponds) | April 1 - Oct 15 | None | 5
   - B : `b-035` limite_jour brook trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
13. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `NY-brown-trout-limite_jour-34` limite_jour Brown Trout (État) {"nombre": 5} [incertain]
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-039` limite_jour brown trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
14. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `NY-rainbow-trout-limite_jour-37` limite_jour Rainbow Trout (État) {"nombre": 5} [incertain]
     > Brown Trout, Rainbow Trout, and Splake (in lakes and ponds) | All year | None | 5 with only 2 longer than 12"
   - B : `b-043` limite_jour rainbow trout (État) {"nombre": 5} [incertain]
     > Trout in inland trout streams ( see Definitions ) April 1 - Oct 15 None 5 with only 2 longer than 12"
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
15. **A et B seules** — code capture_et_remise_a_l_eau_seulement / prise_relacher_hors_periode_recolte
   - A : `NY-brook-trout-relacher-41` relacher Brook Trout (État) 10-16→03-31 {"code": "capture_et_remise_a_l_eau_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-036` relacher brook trout (État) 10-16→03-31 {"code": "prise_relacher_hors_periode_recolte"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
16. **A et B seules** — code capture_et_remise_a_l_eau_seulement / prise_relacher_hors_periode_recolte
   - A : `NY-brown-trout-relacher-45` relacher Brown Trout (État) 10-16→03-31 {"code": "capture_et_remise_a_l_eau_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-040` relacher brown trout (État) 10-16→03-31 {"code": "prise_relacher_hors_periode_recolte"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
17. **A et B seules** — code capture_et_remise_a_l_eau_seulement / prise_relacher_hors_periode_recolte
   - A : `NY-rainbow-trout-relacher-49` relacher Rainbow Trout (État) 10-16→03-31 {"code": "capture_et_remise_a_l_eau_seulement"}
     > Oct 16 - Mar 31 | Catch and Release only. Artificial lures only
   - B : `b-044` relacher rainbow trout (État) 10-16→03-31 {"code": "prise_relacher_hors_periode_recolte"} [incertain]
     > Oct 16 - Mar 31 Catch and Release only. Artificial lures only
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
18. **A et B seules** — code hamecon_circle_non_decale_obligatoire_avec_poisson_appat / hamecons_circulaires_non_decales_exiges
   - A : `NY-toutes-engin-70` engin toutes (État) {"code": "hamecon_circle_non_decale_obligatoire_avec_poisson_appat"} [incertain]
     > Non-offset (in-line) circle hooks must be used when recreationally fishing for striped bass or when using baitfish.
   - B : `b-103` engin toutes (État) {"code": "hamecons_circulaires_non_decales_exiges"} [incertain]
     > Non-offset (in-line) circle hooks must be used when recreationally fishing for striped bass or when using baitfish.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
19. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-walleye-autre-74` autre Walleye (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-087` autre walleye (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
20. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-largemouth-bass-autre-75` autre Largemouth Bass (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-088` autre largemouth bass (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
21. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-brook-trout-autre-76` autre Brook Trout (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-090` autre brook trout (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
22. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-lake-trout-autre-77` autre Lake Trout (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-091` autre lake trout (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
23. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-atlantic-salmon-autre-78` autre Atlantic Salmon (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-092` autre landlocked salmon (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
24. **A et B seules** — code pas_de_decoupe_possession / poisson_entier_pour_mesure
   - A : `NY-smallmouth-bass-autre-79` autre Smallmouth Bass (État) {"code": "pas_de_decoupe_possession"} [incertain]
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - B : `b-089` autre smallmouth bass (État) {"code": "poisson_entier_pour_mesure"}
     > Possession of the following fish that have been cut, dismembered, filleted, skinned, or otherwise altered so that the species and total length of such fish cannot be easily determined is prohibited:
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
25. **A et B seules** — code pas_d_ecrevisse_rouille_comme_appat / ecrevisse_rouille_interdite
   - A : `NY-toutes-appat-84` appat toutes (État) {"code": "pas_d_ecrevisse_rouille_comme_appat"} [incertain]
     > Rusty crayfish may not be purchased and/or transported to a waterbody for use as bait or to be released (See definition of waterbody for baitfish purposes).
   - B : `b-101` appat toutes (État) {"code": "ecrevisse_rouille_interdite"}
     > Rusty crayfish may not be purchased and/or transported to a waterbody for use as bait or to be released
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
26. **A et B seules** — code appat_poisson_collecte_meme_plan_eau_seulement / appat_poisson_meme_plan_eau
   - A : `NY-toutes-appat-86` appat toutes (État) {"code": "appat_poisson_collecte_meme_plan_eau_seulement"} [incertain]
     > Baitfish or other legally taken fish species intended to be used as bait may only be used in the same waterbody from which they were caught for bait in hook-and-line fishing.
   - B : `b-099` appat toutes (État) {"code": "appat_poisson_meme_plan_eau"}
     > Baitfish or other legally taken fish species intended to be used as bait may only be used in the same waterbody from which they were caught for bait in hook-and-line fishing.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (12)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. espèce d'un groupe — gardée : `b-052` saison black crappie (État) 01-01→12-31 {} ; appui : `NY-crappie-saison-51` saison Crappie (État) 01-01→12-31 {}
2. espèce d'un groupe — gardée : `b-053` taille_min black crappie (État) {"pouces": 10} ; appui : `NY-crappie-taille_min-52` taille_min Crappie (État) {"pouces": 10}
3. espèce d'un groupe — gardée : `b-054` limite_jour black crappie (État) {"nombre": 25} ; appui : `NY-crappie-limite_jour-53` limite_jour Crappie (État) {"nombre": 25}
4. espèce d'un groupe — gardée : `b-055` saison white crappie (État) 01-01→12-31 {} ; appui : `NY-crappie-saison-51` saison Crappie (État) 01-01→12-31 {}
5. espèce d'un groupe — gardée : `b-056` taille_min white crappie (État) {"pouces": 10} ; appui : `NY-crappie-taille_min-52` taille_min Crappie (État) {"pouces": 10}
6. espèce d'un groupe — gardée : `b-057` limite_jour white crappie (État) {"nombre": 25} ; appui : `NY-crappie-limite_jour-53` limite_jour Crappie (État) {"nombre": 25}
7. espèce d'un groupe — gardée : `b-060` saison bluegill (État) 01-01→12-31 {} ; appui : `NY-sunfish-saison-56` saison Sunfish (État) 01-01→12-31 {}
8. espèce d'un groupe — gardée : `b-061` limite_jour bluegill (État) {"nombre": 25} ; appui : `NY-sunfish-limite_jour-57` limite_jour Sunfish (État) {"nombre": 25}
9. espèce d'un groupe — gardée : `b-062` saison redbreast sunfish (État) 01-01→12-31 {} ; appui : `NY-sunfish-saison-56` saison Sunfish (État) 01-01→12-31 {}
10. espèce d'un groupe — gardée : `b-063` limite_jour redbreast sunfish (État) {"nombre": 25} ; appui : `NY-sunfish-limite_jour-57` limite_jour Sunfish (État) {"nombre": 25}
11. espèce d'un groupe — gardée : `b-064` saison pumpkinseed (État) 01-01→12-31 {} ; appui : `NY-sunfish-saison-56` saison Sunfish (État) 01-01→12-31 {}
12. espèce d'un groupe — gardée : `b-065` limite_jour pumpkinseed (État) {"nombre": 25} ; appui : `NY-sunfish-limite_jour-57` limite_jour Sunfish (État) {"nombre": 25}
