# FL : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py FL` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 47 règles (16 incertain) ; lecture B : 35 règles (5 incertain).
- Confirmées par les deux : 8, dont 5 sans réserve (chargées dans l'app) et 3 incertaines (non chargées).
- À vérifier : seulement A 39, seulement B 29.
- Désaccords listés : 52 — (i) forme sans conséquence : 18, (ii) conflit de fond : 1, (iii) couverture : 17, (iv) incertain d'un côté : 16.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (i) forme sans conséquence (18)

1. **A et B seules** — dates ('07-01', '06-30') / (None, None)
   - A : `FL-tous-saison-etat` saison toutes (État) 07-01→06-30 {}
     > The open season for fishing shall be from July 1 until June 30 of the following year, except as otherwise provided by these rules.
   - B : `FL-B-01` saison toutes (État) 01-01→12-31 {}
     > The open season for fishing shall be from July 1 until June 30 of the following year, except as otherwise provided by these rules.
   - Avis sur l'outil : juste depuis la correction du 7 nov. : la version datée est confirmée par la même valeur sans date, la version sans date (plus large) reste à vérifier
2. **A et B seules** — code tuer_ou_posseder_interdit / speckled_peacock_ni_tuer_ni_posseder
   - A : `FL-speckledpeacock-interdit-etat` interdit Speckled Peacock Bass (État) {"code": "tuer_ou_posseder_interdit"}
     > No person shall kill or possess any speckled peacock bass.
   - B : `FL-B-08` interdit speckled peacock bass (État) {"code": "speckled_peacock_ni_tuer_ni_posseder"}
     > No person shall kill or possess any speckled peacock bass.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
3. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-suwanneebass-taille_min-nord_ouest` taille_min Suwannee Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - B : `FL-B-09` taille_min Suwannee bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
4. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-shoalbass-taille_min-nord_ouest` taille_min Shoal Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - B : `FL-B-10` taille_min shoal bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
5. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-spottedbass-taille_min-nord_ouest` taille_min Spotted Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - B : `FL-B-11` taille_min spotted bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
6. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-choctawbass-taille_min-nord_ouest` taille_min Choctaw Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - B : `FL-B-12` taille_min Choctaw bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"pouces": 12}
     > no person shall kill or possess any Suwannee Bass, Shoal Bass, Spotted Bass, or Choctaw Bass that is less than 12 inches in total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
7. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) ; toutes zones autres que le bas Ochlockonee en aval du Jackson Bluff Dam » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-stripedbass-taille_min-nord_ouest` taille_min Striped Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries) ; toutes zones autres que le bas Ochlockonee en aval du Jackson Bluff Dam) {"pouces": 18}
     > no person shall kill or possess more than 3 striped bass nor any striped bass less than 18 inches total length.
   - B : `FL-B-13` taille_min striped bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"pouces": 18}
     > no person shall kill or possess more than 3 striped bass nor any striped bass less than 18 inches total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
8. **A et B seules** — portée « South and east of the Suwannee River » / « Sud et est de la rivière Suwannee »
   - A : `FL-bass_rayes-agregat-sud_est` limite_jour Striped Bass, Sunshine Bass (South and east of the Suwannee River) {"nombre": 20}
     > the daily aggregate bag limit of striped bass and sunshine bass shall be 20, no more than 6 of which may be more than 24 inches total length.
   - B : `FL-B-19` limite_jour striped bass, sunshine bass (Sud et est de la rivière Suwannee) {"nombre": 20}
     > the daily aggregate bag limit of striped bass and sunshine bass shall be 20, no more than 6 of which may be more than 24 inches total length.
   - Avis sur l'outil : juste : la portée la plus large n'est pas confirmée ; la plus fine l'est si elle est chiffrée ou datée
9. **A et B seules** — code tuer_ou_posseder_interdit / shoal_bass_chipola_ni_tuer_ni_posseder; portée « Chipola River » / « Chipola River et ses affluents »
   - A : `FL-shoalbass-interdit-chipola` interdit Shoal Bass (Chipola River) {"code": "tuer_ou_posseder_interdit"}
     > No person shall kill or possess any Shoal Bass on the Chipola River or its tributaries.
   - B : `FL-B-18` interdit shoal bass (Chipola River et ses affluents) {"code": "shoal_bass_chipola_ni_tuer_ni_posseder"}
     > No person shall kill or possess any Shoal Bass on the Chipola River or its tributaries. Any Shoal Bass that are caught must be released immediately.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
10. **A et B seules** — code peche_interdite / peche_interdite_silver_glen_salt_springs; portée « Silver Glen Springs » / « Silver Glen Springs »
   - A : `FL-tous-fermeture-silver_glen_springs` fermeture toutes (Silver Glen Springs) {"code": "peche_interdite"}
     > Fishing is prohibited in Silver Glen Springs in Lake and Marion counties and in Salt Springs in Marion County and within 50 yards of the springs.
   - B : `FL-B-20` fermeture toutes (Silver Glen Springs) {"code": "peche_interdite_silver_glen_salt_springs"}
     > Fishing is prohibited in Silver Glen Springs in Lake and Marion counties and in Salt Springs in Marion County and within 50 yards of the springs.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
11. **A et B seules** — code peche_interdite / peche_interdite_silver_glen_salt_springs; portée « Salt Springs » / « Silver Glen Springs »
   - A : `FL-tous-fermeture-salt_springs` fermeture toutes (Salt Springs) {"code": "peche_interdite"}
     > Fishing is prohibited in Silver Glen Springs in Lake and Marion counties and in Salt Springs in Marion County and within 50 yards of the springs.
   - B : `FL-B-20` fermeture toutes (Silver Glen Springs) {"code": "peche_interdite_silver_glen_salt_springs"}
     > Fishing is prohibited in Silver Glen Springs in Lake and Marion counties and in Salt Springs in Marion County and within 50 yards of the springs.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
12. **A et B seules** — code peche_interdite / peche_interdite_rainbow_river_tete; portée « from the headwaters of Rainbow Springs to a point one mile downstream » / « Rainbow River »
   - A : `FL-tous-fermeture-rainbow_river` fermeture toutes (from the headwaters of Rainbow Springs to a point one mile downstream) {"code": "peche_interdite"}
     > Fishing is prohibited from the headwaters of Rainbow Springs to a point one mile downstream on Rainbow River within Marion County.
   - B : `FL-B-21` fermeture toutes (Rainbow River) {"code": "peche_interdite_rainbow_river_tete"}
     > Fishing is prohibited from the headwaters of Rainbow Springs to a point one mile downstream on Rainbow River within Marion County.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
13. **A et B seules** — code epuisette_interdite_sauf_mise_en_epuisette / epuisette_a_main_interdite_sauf_mise_a_terre
   - A : `FL-gibier-engin-epuisette` engin Freshwater Game Fish, Catfish (État) {"code": "epuisette_interdite_sauf_mise_en_epuisette"}
     > The use of dip nets for taking freshwater game fish or catfish is prohibited except that landing nets may be used for boating fish caught by rod and reel or hook and line.
   - B : `FL-B-26` engin freshwater game fish, catfish (État) {"code": "epuisette_a_main_interdite_sauf_mise_a_terre"}
     > The use of dip nets for taking freshwater game fish or catfish is prohibited except that landing nets may be used for boating fish caught by rod and reel or hook and line.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
14. **A et B seules** — espèces ['black bass'] / ['black bass', 'peacock bass']; code black_bass_comme_appat_interdit / black_bass_peacock_bass_interdits_comme_appat
   - A : `FL-blackbass-appat-interdit` appat Black Bass (État) {"code": "black_bass_comme_appat_interdit"}
     > No person shall use any species of black bass, peacock bass or any part thereof as bait.
   - B : `FL-B-32` appat black bass, peacock bass (État) {"code": "black_bass_peacock_bass_interdits_comme_appat"}
     > No person shall use any species of black bass, peacock bass or any part thereof as bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
15. **A et B seules** — espèces ['peacock bass'] / ['black bass', 'peacock bass']; code peacock_bass_comme_appat_interdit / black_bass_peacock_bass_interdits_comme_appat
   - A : `FL-peacockbass-appat-interdit` appat Peacock Bass (État) {"code": "peacock_bass_comme_appat_interdit"}
     > No person shall use any species of black bass, peacock bass or any part thereof as bait.
   - B : `FL-B-32` appat black bass, peacock bass (État) {"code": "black_bass_peacock_bass_interdits_comme_appat"}
     > No person shall use any species of black bass, peacock bass or any part thereof as bait.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
16. **A et B seules** — espèces ['goldfish'] / ['common carp', 'goldfish']; code goldfish_vivant_appat_interdit / goldfish_carpe_vivants_interdits_comme_appat
   - A : `FL-goldfish-appat-vivant_interdit` appat Goldfish (État) {"code": "goldfish_vivant_appat_interdit"}
     > No live goldfish or carp shall be transported into the state for bait purposes or possessed or used for bait for the purpose of taking freshwater fish in any waters.
   - B : `FL-B-33` appat goldfish, carp (État) {"code": "goldfish_carpe_vivants_interdits_comme_appat"}
     > No live goldfish or carp shall be transported into the state for bait purposes or possessed or used for bait for the purpose of taking freshwater fish in any waters.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
17. **A et B seules** — espèces ['common carp'] / ['common carp', 'goldfish']; code carp_vivant_appat_interdit / goldfish_carpe_vivants_interdits_comme_appat
   - A : `FL-carp-appat-vivant_interdit` appat Carp (État) {"code": "carp_vivant_appat_interdit"}
     > No live goldfish or carp shall be transported into the state for bait purposes or possessed or used for bait for the purpose of taking freshwater fish in any waters.
   - B : `FL-B-33` appat goldfish, carp (État) {"code": "goldfish_carpe_vivants_interdits_comme_appat"}
     > No live goldfish or carp shall be transported into the state for bait purposes or possessed or used for bait for the purpose of taking freshwater fish in any waters.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)
18. **A et B seules** — code micropterus_vivants_remis_dans_leur_plan_eau / micropterus_vivant_relache_dans_le_meme_plan_d_eau
   - A : `FL-micropterus-relacher-meme_plan_eau` relacher Black Bass (État) {"code": "micropterus_vivants_remis_dans_leur_plan_eau"}
     > Live Micropterus species may only be released back into the waterbody from which they were caught.
   - B : `FL-B-34` relacher black bass (État) {"code": "micropterus_vivant_relache_dans_le_meme_plan_d_eau"}
     > Live Micropterus species may only be released back into the waterbody from which they were caught.
   - Avis sur l'outil : trop strict : même règle, codes libres différents (limite connue : seul le code court tranche)

## (ii) conflit de fond (1)

1. **A seule (B appariée est confirmée ailleurs)** — nombres {'taille_min': 16.0, 'nombre': 1.0} / {'nombre': 5.0}
   - A : `FL-blackbass-un_grand-etat` limite_jour Black Bass (État) {"nombre": 1, "pouces_min": 16}
     > Five (5) black bass, of which only one may be 16 inches or longer in total length.
   - B : `FL-B-02` limite_jour black bass (État) {"nombre": 5}
     > (a) Five (5) black bass, of which only one may be 16 inches or longer in total length.
   - Avis sur l'outil : juste : deux valeurs différentes

## (iii) couverture (17)

1. **A seule** — lue par A seulement
   - A : `FL-tous-specifiques-prevalent-etat` autre toutes (État) {"code": "regles_specifiques_plan_eau_prevalent"}
     > the specific regulations supersede the general provisions of this rule section.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement
   - A : `FL-americaneel-taille_min-etat` taille_min American Eel (État) {"pouces": 9}
     > American Eels must be nine inches or greater in total length for recreational and commercial harvest.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement
   - A : `FL-americaneel-limite_jour-etat` limite_jour American Eel (État) {"nombre": 25}
     > The recreational bag limit for American Eels is twenty five (25) per angler per day.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement
   - A : `FL-tous-interdit-methodes` interdit toutes (État) {"code": "plongee_explosifs_electricite_poison_armes"}
     > Freshwater fish may not be taken by underwater swimming or diving or by use of any free-floating unattached devices, firearms, explosives, electricity, spear guns; by poison,
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement (marquée incertain)
   - A : `FL-nongame-engin-palangre_25` engin Non-game Fish (État) {"hamecons_max": 25, "code": "palangre_25_hamecons_usage_personnel"} [incertain]
     > A trotline limited to 25 hooks may be used for taking non-game fish for personal use.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement
   - A : `FL-gibier-relacher-palangre` relacher Freshwater Game Fish (État) {"code": "remise_eau_immediate_palangre_ligne_dormante"}
     > All game fish taken by trotlines, bush hooks or set lines shall be immediately returned unharmed to the water
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement (marquée incertain)
   - A : `FL-nongame-engin-piege_nasse` engin Non-game Fish (État) {"code": "une_nasse_lattes_ou_un_piege_fil_usage_personnel"} [incertain]
     > by the use of not more than one slat basket or one wire trap, made as specified in Rule 68A-23.003, F.A.C.,
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement
   - A : `FL-bream-appat-canne_seulement` appat Bream (État) {"code": "bream_appat_par_le_pecheur_canne_seulement"}
     > Whole pickerel or bream or portions thereof may be used for bait purposes by persons catching the fish but in no case shall they be used as bait for trotlines, bush hooks or in any manner other than
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement
   - A : `FL-pickerel-appat-canne_seulement` appat Pickerel (État) {"code": "pickerel_appat_par_le_pecheur_canne_seulement"}
     > Whole pickerel or bream or portions thereof may be used for bait purposes by persons catching the fish but in no case shall they be used as bait for trotlines, bush hooks or in any manner other than
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **A seule** — lue par A seulement (marquée incertain)
   - A : `FL-catfish-donnee_absente-etat` autre Channel Catfish, White Catfish (État) {"code": "aucune_limite_trouvee_pour_catfish"} [incertain]
     > Non-game fish – All freshwater fish species, except grass carp, not listed in subsection 68A-1.004(32), F.A.C., as freshwater game fish.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
11. **A et B seules** — faits différents du même passage : type limite_jour / autre; nombres {'taille_min': 16.0, 'nombre': 1.0} / {'taille': 16.0, 'nombre': 1.0}
   - A : `FL-blackbass-un_grand-etat` limite_jour Black Bass (État) {"nombre": 1, "pouces_min": 16}
     > Five (5) black bass, of which only one may be 16 inches or longer in total length.
   - B : `FL-B-03` autre black bass (État) {"pouces": 16, "nombre": 1}
     > (a) Five (5) black bass, of which only one may be 16 inches or longer in total length.
   - Avis sur l'outil : juste : chaque lecture a codé une partie différente de la ligne (ex. limite totale d'un côté, « 1 de plus de 16 pouces » de l'autre)
12. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `FL-B-27` engin toutes (État) {"code": "engins_prohibes_eau_douce"} [incertain]
     > The use or possession of dynamite, traps, nets, seines, baskets, spear guns, any device capable of producing an electrical current
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
13. **B seule** — lue par B seulement
   - A : —
   - B : `FL-B-28` engin bait minnows (État) {"code": "epuisette_4_pieds_pour_vairons"}
     > (a) By the use of a dip net not over four feet in diameter.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
14. **B seule** — lue par B seulement
   - A : —
   - B : `FL-B-29` engin toutes (Fellsmere Water Management Area (Headwaters Lake et Egan Lake)) {"code": "hamecon_circulaire_appats_naturels_plus_de_3_pouces"}
     > Circle hooks are required to be used on hook and line gear when fishing with natural baits greater than 3
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
15. **B seule** — lue par B seulement
   - A : —
   - B : `FL-B-30` engin freshwater game fish (État) {"code": "trotline_set_line_game_fish_remis_a_l_eau"}
     > All game fish taken by trotlines, bush hooks or set lines shall be immediately returned unharmed to the water
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
16. **B seule** — lue par B seulement
   - A : —
   - B : `FL-B-31` engin nongame fish (État) {"code": "trotline_25_hamecons_usage_personnel", "hamecons_max": 25}
     > A trotline limited to 25 hooks may be used for taking non-game fish for personal use.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
17. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `FL-B-35` limite_jour channel catfish (Fish Management Areas (FMA) de la FWC) {"nombre": 6} [incertain]
     > (a) Channel catfish – six fish, no length limit.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (16)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `FL-panfish-limite_jour-etat` limite_jour Panfish (État) {"nombre": 50} [incertain]
     > Fifty (50) in the aggregate for all other panfish.
   - B : `FL-B-05` limite_jour panfish (État) {"nombre": 50}
     > (c) Fifty (50) in the aggregate for all other panfish.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `FL-crappie-taille_min-lake_talquin` taille_min Crappie (Lake Talquin) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than 10 inches in total length.
   - B : `FL-B-17` taille_min crappie (Lake Talquin) {"pouces": 10}
     > No person shall kill or possess any crappie less than 10 inches in total length.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `FL-crappie-taille_min-lake_okeechobee` taille_min Crappie (Lake Okeechobee) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than ten inches (10'') in total length.
   - B : `FL-B-23` taille_min crappie (Lake Okeechobee) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than ten inches (10'') in total length.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **A seule (B appariée est confirmée ailleurs)** — nombres {'taille_min': 17.0, 'nombre': 1.0} / {'nombre': 2.0}
   - A : `FL-butterflypeacock-un_grand-etat` limite_jour Butterfly Peacock Bass (État) {"nombre": 1, "pouces_min": 17} [incertain]
     > Two (2) butterfly peacock bass, only one (1) of which can be greater than 17 inches total length.
   - B : `FL-B-06` limite_jour butterfly peacock bass (État) {"nombre": 2}
     > (d) Two (2) butterfly peacock bass, only one (1) of which can be greater than 17 inches total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
5. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) ; toutes zones autres que le bas Ochlockonee en aval du Jackson Bluff Dam » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-stripedbass-limite_possession-nord_ouest` limite_possession Striped Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries) ; toutes zones autres que le bas Ochlockonee en aval du Jackson Bluff Dam) {"nombre": 3} [incertain]
     > no person shall kill or possess more than 3 striped bass nor any striped bass less than 18 inches total length.
   - B : `FL-B-14` limite_possession striped bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"nombre": 3} [incertain]
     > no person shall kill or possess more than 3 striped bass nor any striped bass less than 18 inches total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
6. **A et B seules** — portée « North and west of the Suwannee River (including the Suwannee River and its tributaries) » / « Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent) »
   - A : `FL-bass_rayes-agregat-nord_ouest` limite_jour Striped Bass, White Bass, Sunshine Bass (North and west of the Suwannee River (including the Suwannee River and its tributaries)) {"nombre": 20} [incertain]
     > The daily aggregate bag limit of white bass, striped bass and sunshine bass shall be 20.
   - B : `FL-B-16` limite_jour white bass, striped bass, sunshine bass (Nord et ouest de la rivière Suwannee (Suwannee River comprise, ainsi que tout affluent)) {"nombre": 20}
     > The daily aggregate bag limit of white bass, striped bass and sunshine bass shall be 20.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
7. **A et B seules** — portée « lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam » / « Basse Ochlockonee et affluents en aval de Jackson Bluff Dam »
   - A : `FL-stripedbass-limite_possession-ochlockonee_bas` limite_possession Striped Bass (lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam) {"nombre": 3} [incertain]
     > On the lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam, no person shall kill or possess more than 3 striped bass only one of which may be greater than 24 inches.
   - B : `FL-B-15` limite_possession striped bass (Basse Ochlockonee et affluents en aval de Jackson Bluff Dam) {"nombre": 3} [incertain]
     > On the lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam, no person shall kill or possess more than 3 striped bass only one of which may be greater than 24 inches.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
8. **A et B seules** — nombres {'taille_min': 24.0, 'nombre': 1.0} / {'nombre': 3.0}; portée « lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam » / « Basse Ochlockonee et affluents en aval de Jackson Bluff Dam »
   - A : `FL-stripedbass-un_grand-ochlockonee_bas` limite_possession Striped Bass (lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam) {"nombre": 1, "pouces_min": 24} [incertain]
     > On the lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam, no person shall kill or possess more than 3 striped bass only one of which may be greater than 24 inches.
   - B : `FL-B-15` limite_possession striped bass (Basse Ochlockonee et affluents en aval de Jackson Bluff Dam) {"nombre": 3} [incertain]
     > On the lower Ochlockonee and associated tributaries downstream of the Jackson Bluff Dam, no person shall kill or possess more than 3 striped bass only one of which may be greater than 24 inches.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
9. **A et B seules** — nombres {'taille_min': 24.0, 'nombre': 6.0} / {'nombre': 20.0}; portée « South and east of the Suwannee River » / « Sud et est de la rivière Suwannee »
   - A : `FL-bass_rayes-grands-sud_est` limite_jour Striped Bass, Sunshine Bass (South and east of the Suwannee River) {"nombre": 6, "pouces_min": 24} [incertain]
     > the daily aggregate bag limit of striped bass and sunshine bass shall be 20, no more than 6 of which may be more than 24 inches total length.
   - B : `FL-B-19` limite_jour striped bass, sunshine bass (Sud et est de la rivière Suwannee) {"nombre": 20}
     > the daily aggregate bag limit of striped bass and sunshine bass shall be 20, no more than 6 of which may be more than 24 inches total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
10. **A et B seules** — code tuer_ou_posseder_interdit / black_bass_ni_tuer_ni_posseder_wildcat; portée « Wildcat Lake within the boundaries of the Ocala National Forest » / « Wildcat Lake »
   - A : `FL-blackbass-interdit-wildcat_lake` interdit Black Bass (Wildcat Lake within the boundaries of the Ocala National Forest) {"code": "tuer_ou_posseder_interdit"} [incertain]
     > No person shall kill or possess any black bass in the following areas:
   - B : `FL-B-22` interdit black bass (Wildcat Lake) {"code": "black_bass_ni_tuer_ni_posseder_wildcat"}
     > No person shall kill or possess any black bass in the following areas: 1. In Wildcat Lake within the boundaries of the Ocala National Forest.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
11. **A et B seules** — code tuer_ou_posseder_interdit / black_bass_ni_tuer_ni_posseder_wildcat; portée « St. Johns River Water Management Area » / « Wildcat Lake »
   - A : `FL-blackbass-interdit-farm13_stickmarsh` interdit Black Bass (St. Johns River Water Management Area) {"code": "tuer_ou_posseder_interdit"} [incertain]
     > No person shall kill or possess any black bass in the following areas:
   - B : `FL-B-22` interdit black bass (Wildcat Lake) {"code": "black_bass_ni_tuer_ni_posseder_wildcat"}
     > No person shall kill or possess any black bass in the following areas: 1. In Wildcat Lake within the boundaries of the Ocala National Forest.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
12. **A et B seules** — code tuer_ou_posseder_interdit / black_bass_ni_tuer_ni_posseder_wildcat; portée « St. Johns River Water Management-owned area formerly known as the S.N. Knight Farm » / « Wildcat Lake »
   - A : `FL-blackbass-interdit-kenansville` interdit Black Bass (St. Johns River Water Management-owned area formerly known as the S.N. Knight Farm) {"code": "tuer_ou_posseder_interdit"} [incertain]
     > No person shall kill or possess any black bass in the following areas:
   - B : `FL-B-22` interdit black bass (Wildcat Lake) {"code": "black_bass_ni_tuer_ni_posseder_wildcat"}
     > No person shall kill or possess any black bass in the following areas: 1. In Wildcat Lake within the boundaries of the Ocala National Forest.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
13. **A et B seules** — code tuer_ou_posseder_interdit / black_bass_ni_tuer_ni_posseder_wildcat; portée « Fellsmere Water Management Area » / « Wildcat Lake »
   - A : `FL-blackbass-interdit-fellsmere` interdit Black Bass (Fellsmere Water Management Area) {"code": "tuer_ou_posseder_interdit"} [incertain]
     > No person shall kill or possess any black bass in the following areas:
   - B : `FL-B-22` interdit black bass (Wildcat Lake) {"code": "black_bass_ni_tuer_ni_posseder_wildcat"}
     > No person shall kill or possess any black bass in the following areas: 1. In Wildcat Lake within the boundaries of the Ocala National Forest.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
14. **A et B seules** — type limite_jour / autre; nombres {'taille_min': 17.0, 'nombre': 1.0} / {'taille': 17.0, 'nombre': 1.0}
   - A : `FL-butterflypeacock-un_grand-etat` limite_jour Butterfly Peacock Bass (État) {"nombre": 1, "pouces_min": 17} [incertain]
     > Two (2) butterfly peacock bass, only one (1) of which can be greater than 17 inches total length.
   - B : `FL-B-07` autre butterfly peacock bass (État) {"pouces": 17, "nombre": 1}
     > (d) Two (2) butterfly peacock bass, only one (1) of which can be greater than 17 inches total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
15. **B seule (A appariée est confirmée ailleurs)** — portée « Lake Talquin » / « Lake Talquin »
   - A : `FL-crappie-taille_min-lake_talquin` taille_min Crappie (Lake Talquin) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than 10 inches in total length.
   - B : `FL-B-17` taille_min crappie (Lake Talquin) {"pouces": 10}
     > No person shall kill or possess any crappie less than 10 inches in total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
16. **B seule (A appariée est confirmée ailleurs)** — portée « Lake Okeechobee » / « Lake Okeechobee »
   - A : `FL-crappie-taille_min-lake_okeechobee` taille_min Crappie (Lake Okeechobee) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than ten inches (10'') in total length.
   - B : `FL-B-23` taille_min crappie (Lake Okeechobee) {"pouces": 10} [incertain]
     > No person shall kill or possess any crappie less than ten inches (10'') in total length.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (0)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

