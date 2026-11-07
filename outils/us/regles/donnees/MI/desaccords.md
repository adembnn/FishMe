# MI : désaccords entre les lectures A et B

Généré par `outils/us/regles/donnees/analyser_desaccords.py MI` (lot us-consensus, 7 nov. 2026), à partir de `consensus.json` (outil `consensus_us.py` corrigé le même jour). Les citations sont tronquées à 200 caractères.

- Lecture A : 70 règles (10 incertain) ; lecture B : 30 règles (30 incertain).
- Confirmées par les deux : 5, dont 0 sans réserve (chargées dans l'app) et 5 incertaines (non chargées).
- À vérifier : seulement A 69, seulement B 25.
- Désaccords listés : 93 — (i) forme sans conséquence : 0, (ii) conflit de fond : 0, (iii) couverture : 76, (iv) incertain d'un côté : 17.

Une ligne = une règle d'une seule lecture (avec la règle la plus proche de l'autre lecture, s'il y en a une), ou une règle confirmée mais incertaine. « Avis sur l'outil » : juste, trop strict (refuse une vraie concordance) ou trop laxiste.

## (iii) couverture (76)

1. **A seule** — lue par A seulement
   - A : `MI-lmb-taille_min-etat` taille_min Largemouth Bass (État) {"pouces": 14}
     > Largemouth Bass Smallmouth Bass (NOTE 2) 14" 5 in any combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
2. **A seule** — lue par A seulement
   - A : `MI-lmb-limite_jour-etat` limite_jour Largemouth Bass (État) {"nombre": 5}
     > Largemouth Bass Smallmouth Bass (NOTE 2) 14" 5 in any combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
3. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-lmb-saison_possession-etat` autre Largemouth Bass (État) {} [incertain]
     > Sat. before Memorial Day – Dec. 31: All other waters including Gr. Lakes (except those listed in NOTE 2)
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
4. **A seule** — lue par A seulement
   - A : `MI-smb-taille_min-etat` taille_min Smallmouth Bass (État) {"pouces": 14}
     > Largemouth Bass Smallmouth Bass (NOTE 2) 14" 5 in any combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
5. **A seule** — lue par A seulement
   - A : `MI-smb-limite_jour-etat` limite_jour Smallmouth Bass (État) {"nombre": 5}
     > Largemouth Bass Smallmouth Bass (NOTE 2) 14" 5 in any combination
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
6. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-smb-saison_possession-etat` autre Smallmouth Bass (État) {} [incertain]
     > Sat. before Memorial Day – Dec. 31: All other waters including Gr. Lakes (except those listed in NOTE 2)
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
7. **A seule** — lue par A seulement
   - A : `MI-walleye-saison-up` saison Walleye (Upper Peninsula) 05-15→03-15 {}
     > May 15 – March 15: Upper Peninsula Gr. Lakes and inland waters, and St. Marys R.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
8. **A seule** — lue par A seulement
   - A : `MI-pike-taille_min-etat` taille_min Northern Pike (État) {"pouces": 24}
     > Northern Pike (NOTE 4) 24" 2
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
9. **A seule** — lue par A seulement
   - A : `MI-pike-saison-up` saison Northern Pike (Upper Peninsula) 05-15→03-15 {}
     > May 15 – March 15: Upper Peninsula Gr. Lakes and inland waters, and St. Marys R.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
10. **A seule** — lue par A seulement
   - A : `MI-muskie-taille_min-etat` taille_min Muskellunge (État) {"pouces": 42}
     > Muskellunge (including Tiger Muskellunge) (NOTE 4) 42" (See NOTE 4 for exceptions)
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
11. **A seule** — lue par A seulement
   - A : `MI-muskie-recolte_annuelle-etat` autre Muskellunge (État) {"nombre": 1}
     > Only 1 per angler per license year (Mandatory Registration)
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
12. **A seule** — lue par A seulement
   - A : `MI-channelcat-taille_min-etat` taille_min Channel Catfish (État) {"pouces": 12}
     > Channel Catfish 12" 10 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
13. **A seule** — lue par A seulement
   - A : `MI-channelcat-limite_jour-etat` limite_jour Channel Catfish (État) {"nombre": 10}
     > Channel Catfish 12" 10 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
14. **A seule** — lue par A seulement
   - A : `MI-channelcat-saison-etat` saison Channel Catfish (État) 01-01→12-31 {}
     > Channel Catfish 12" 10 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
15. **A seule** — lue par A seulement
   - A : `MI-flatheadcat-taille_min-etat` taille_min Flathead Catfish (État) {"pouces": 15}
     > Flathead Catfish 15" 5 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
16. **A seule** — lue par A seulement
   - A : `MI-flatheadcat-limite_jour-etat` limite_jour Flathead Catfish (État) {"nombre": 5}
     > Flathead Catfish 15" 5 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
17. **A seule** — lue par A seulement
   - A : `MI-flatheadcat-saison-etat` saison Flathead Catfish (État) 01-01→12-31 {}
     > Flathead Catfish 15" 5 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
18. **A seule** — lue par A seulement
   - A : `MI-perch-limite_jour-etat` limite_jour Yellow Perch (État) {"nombre": 25}
     > Yellow Perch (NOTE 5) No size limit 25 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
19. **A seule** — lue par A seulement
   - A : `MI-perch-saison-etat` saison Yellow Perch (État) 01-01→12-31 {}
     > Yellow Perch (NOTE 5) No size limit 25 Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
20. **A seule** — lue par A seulement
   - A : `MI-bluegill-limite_jour-etat` limite_jour Bluegill (État) {"nombre": 25}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
21. **A seule** — lue par A seulement
   - A : `MI-bluegill-saison-etat` saison Bluegill (État) 01-01→12-31 {}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
22. **A seule** — lue par A seulement
   - A : `MI-bcrappie-limite_jour-etat` limite_jour Black Crappie (État) {"nombre": 25}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
23. **A seule** — lue par A seulement
   - A : `MI-bcrappie-saison-etat` saison Black Crappie (État) 01-01→12-31 {}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
24. **A seule** — lue par A seulement
   - A : `MI-wcrappie-limite_jour-etat` limite_jour White Crappie (État) {"nombre": 25}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
25. **A seule** — lue par A seulement
   - A : `MI-wcrappie-saison-etat` saison White Crappie (État) 01-01→12-31 {}
     > Sunfishes (NOTE 6) No size limit 25 in any combination of the listed species Open All Year
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
26. **A seule** — lue par A seulement
   - A : `MI-brook-taille_min-lac_non_type` taille_min Brook Trout (État) {"pouces": 8}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
27. **A seule** — lue par A seulement
   - A : `MI-brook-limite_jour-lac_non_type` limite_jour Brook Trout (État) {"nombre": 5}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
28. **A seule** — lue par A seulement
   - A : `MI-brook-saison-lac_non_type` saison Brook Trout (État) 01-01→12-31 {}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
29. **A seule** — lue par A seulement
   - A : `MI-brook-taille_min-cours_eau_non_type` taille_min Brook Trout (État) {"pouces": 7}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
30. **A seule** — lue par A seulement
   - A : `MI-brook-limite_jour-cours_eau_non_type` limite_jour Brook Trout (État) {"nombre": 5}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
31. **A seule** — lue par A seulement
   - A : `MI-brown-taille_min-lac_non_type` taille_min Brown Trout (État) {"pouces": 8}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
32. **A seule** — lue par A seulement
   - A : `MI-brown-limite_jour-lac_non_type` limite_jour Brown Trout (État) {"nombre": 5}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
33. **A seule** — lue par A seulement
   - A : `MI-brown-saison-lac_non_type` saison Brown Trout (État) 01-01→12-31 {}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
34. **A seule** — lue par A seulement
   - A : `MI-brown-taille_min-cours_eau_non_type` taille_min Brown Trout (État) {"pouces": 8}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
35. **A seule** — lue par A seulement
   - A : `MI-brown-limite_jour-cours_eau_non_type` limite_jour Brown Trout (État) {"nombre": 5}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
36. **A seule** — lue par A seulement
   - A : `MI-rainbow-taille_min-lac_non_type` taille_min Rainbow Trout (État) {"pouces": 8}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
37. **A seule** — lue par A seulement
   - A : `MI-rainbow-limite_jour-lac_non_type` limite_jour Rainbow Trout (État) {"nombre": 5}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
38. **A seule** — lue par A seulement
   - A : `MI-rainbow-saison-lac_non_type` saison Rainbow Trout (État) 01-01→12-31 {}
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
39. **A seule** — lue par A seulement
   - A : `MI-rainbow-taille_min-cours_eau_non_type` taille_min Rainbow Trout (État) {"pouces": 8}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
40. **A seule** — lue par A seulement
   - A : `MI-rainbow-limite_jour-cours_eau_non_type` limite_jour Rainbow Trout (État) {"nombre": 5}
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
41. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-laketrout-taille_min-lac_non_type` taille_min Lake Trout (État) {"pouces": 8} [incertain]
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
42. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-laketrout-limite_jour-lac_non_type` limite_jour Lake Trout (État) {"nombre": 5} [incertain]
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
43. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-laketrout-saison-lac_non_type` saison Lake Trout (État) 01-01→12-31 {} [incertain]
     > any other inland lake not classified by Type is open all year to the taking of trout with an 8-inch minimum size limit and 5 fish daily possession limit, no more than 3 of which may be 15" or greater.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
44. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-laketrout-taille_min-cours_eau_non_type` taille_min Lake Trout (État) {"pouces": 8} [incertain]
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
45. **A seule** — lue par A seulement (marquée incertain)
   - A : `MI-laketrout-limite_jour-cours_eau_non_type` limite_jour Lake Trout (État) {"nombre": 5} [incertain]
     > any other inland stream not classified by Type is open to trout fishing all year with an 8" minimum size limit (except 7" for Brook Trout) and a 5 fish daily possession limit
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
46. **A seule** — lue par A seulement
   - A : `MI-sturgeon-fermeture-autres_eaux` fermeture Lake Sturgeon (État) {"code": "pas_de_saison_esturgeon"}
     > All Other Waters NO FISHING SEASON Unlawful to fish for Lake Sturgeon
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
47. **A seule** — lue par A seulement
   - A : `MI-sturgeon-recolte_annuelle-etat` autre Lake Sturgeon (État) {"nombre": 1}
     > Lake Sturgeon harvest is limited to only 1 Lake Sturgeon per angler per year (April 1 – March 31).
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
48. **A seule** — lue par A seulement
   - A : `MI-gen-lignes_max` engin toutes (État) {"lignes_max": 3}
     > No more than 3 lines per person (including tip- ups)
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
49. **A seule** — lue par A seulement
   - A : `MI-gen-hamecons_max` engin toutes (État) {"hamecons_max": 6}
     > or more than 6 hooks or lures may be used
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
50. **A seule** — lue par A seulement
   - A : `MI-gen-hamecon_appate_ou_leurre` engin toutes (État) {"code": "hamecon_appate_perle_ou_leurre"}
     > Hooks must be baited, fished with a bead or attached to an artificial bait.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
51. **A seule** — lue par A seulement
   - A : `MI-gen-poisson_non_accroche_bouche` relacher toutes (État) {"code": "poisson_non_accroche_bouche"}
     > Fish not hooked in the mouth must be returned to the water immediately.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
52. **A seule** — lue par A seulement
   - A : `MI-gen-arrache` interdit toutes (État) {"code": "pas_de_peche_a_l_arrache"}
     > Snag a fish, attempt to snag a fish, or possess a fish that was snagged.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
53. **A seule** — lue par A seulement
   - A : `MI-gen-epuisette_filet_lance_eaux_interieures` interdit toutes (État) {"code": "pas_d_epervier_eaux_interieures"}
     > Use cast nets in any inland water.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
54. **A seule** — lue par A seulement
   - A : `MI-gen-hamecons_cours_eau_taille` interdit toutes (État) 08-01→05-31 {"code": "hamecon_taille_max_cours_eau_aout_mai"}
     > Use multi-pointed hooks exceeding 3⁄8" between point and shank and/or single-pointed hooks exceeding ½" between point and shank on all streams
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
55. **A seule** — lue par A seulement
   - A : `MI-gen-leurres_1_once_cours_eau` interdit toutes (État) 08-01→05-31 {"code": "leurre_max_1_once_cours_eau_aout_mai"}
     > Use lures exceeding one ounce on all streams from Aug. 1 – May 31 except when fishing in the Detroit R., St. Clair R., and St. Marys R.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
56. **A seule** — lue par A seulement
   - A : `MI-gen-drop_shot_cours_eau` interdit toutes (État) {"code": "drop_shot_pas_sur_cours_eau"}
     > This gear may not be used on rivers or streams.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
57. **A seule** — lue par A seulement
   - A : `MI-gen-gaffe_cours_eau_truite` interdit toutes (État) {"code": "gaffe_pas_sur_cours_eau_truite_designe"}
     > Gaffs may be used to help land lawfully hooked fish on all waters EXCEPT on a designated trout stream.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
58. **A seule** — lue par A seulement
   - A : `MI-gen-amorcage_cours_eau` interdit toutes (État) {"code": "pas_d_amorcage_organique_cours_eau"}
     > Chum with organic material in all stream Types as indicated on p. 43.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
59. **A seule** — lue par A seulement
   - A : `MI-gen-appat_poissons_eau_de_capture` appat toutes (État) {"code": "poissons_appat_dans_eau_de_capture_seulement"}
     > Baitfish may only be used in the waters where collected.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
60. **A seule** — lue par A seulement
   - A : `MI-gen-appat_carpe_poisson_rouge_lamproie` interdit toutes (État) {"code": "pas_appat_carpe_vivante_goldfish_lamproie"}
     > EXCEPT lampreys, live carp or Goldfish.
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
61. **A seule** — lue par A seulement
   - A : `MI-gen-appat_ecrevisses_non_natives` interdit toutes (État) {"code": "pas_appat_ecrevisse_non_native"}
     > Possess or use for bait any live crayfish species not native to Michigan waters, including (but not limited to) Red Swamp Crayfish and Rusty Crayfish, whether alive or dead
   - B : —
   - Avis sur l'outil : juste : rien à comparer dans la lecture B
62. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-wae-independence-slot` fenetre walleye (Lake Independence) {"pouces_min": 18, "pouces_max": 23, "mode": "relacher_entre"} [incertain]
     > walleye from 18.0 inches to 23.0 inches must be released.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
63. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-wae-independence-big` autre walleye (Lake Independence) {} [incertain]
     > only one of those five walleye can be more than 23 inches long.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
64. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-wae-teal-slot` fenetre walleye (Teal Lake) {"pouces_min": 18, "pouces_max": 23, "mode": "relacher_entre"} [incertain]
     > walleye from 18.0 inches to 23.0 inches must be released.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
65. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-wae-teal-big` autre walleye (Teal Lake) {} [incertain]
     > only one of those five walleye can be more than 23 inches long.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
66. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-pike-ausablelake-big` autre northern pike (Au Sable Lake) {} [incertain]
     > only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
67. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-pike-clearlake-big` autre northern pike (Clear Lake) {} [incertain]
     > only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
68. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-pike-gibsonlake-big` autre northern pike (Gibson Lake) {} [incertain]
     > only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
69. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-pike-hanburylake-big` autre northern pike (Hanbury Lake) {} [incertain]
     > only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
70. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-wae-up-open` autre walleye (Upper Peninsula) 2026-05-15→None {} [incertain]
     > in Upper Peninsula waters, the walleye and northern pike possession seasons open May 15
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
71. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-pike-up-open` autre northern pike (Upper Peninsula) 2026-05-15→None {} [incertain]
     > in Upper Peninsula waters, the walleye and northern pike possession seasons open May 15
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
72. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-lmb-open` autre largemouth bass (État) 2026-05-23→None {} [incertain]
     > The possession season for bass opens statewide Saturday, May 23
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
73. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-smb-open` autre smallmouth bass (État) 2026-05-23→None {} [incertain]
     > The possession season for bass opens statewide Saturday, May 23
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
74. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-burbot-bag` limite_jour burbot (État) {"nombre": 5} [incertain]
     > A possession limit of five per day has been placed on burbot.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
75. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-bead` autre trout, salmon (État) {} [incertain]
     > has been defined as an artificial lure for clarification purposes
   - Avis sur l'outil : juste : rien à comparer dans la lecture A
76. **B seule** — lue par B seulement (marquée incertain)
   - A : —
   - B : `b-sturgeon-reg` autre lake sturgeon (État) {} [incertain]
     > If you harvest a lake sturgeon or muskellunge, you must report it within 24 hours.
   - Avis sur l'outil : juste : rien à comparer dans la lecture A

## (iv) incertain d'un côté (17)

1. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain »
   - A : `MI-muskie-saison-etat` autre Muskellunge (État) {} [incertain]
     > 1st Sat. in June – March 15: All Gr. Lakes and inland waters and St. Marys R.
   - B : `b-musky-reg` autre muskellunge (État) {} [incertain]
     > If you harvest a lake sturgeon or muskellunge, you must report it within 24 hours.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
2. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MI-walleye-taille_min-etat` taille_min Walleye (État) {"pouces": 15}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-independence-min` taille_min walleye (Lake Independence) {"pouces": 15} [incertain]
     > The minimum size limit for possession remains at 15 inches.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
3. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MI-walleye-limite_jour-etat` limite_jour Walleye (État) {"nombre": 5}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-independence-bag` limite_jour walleye (Lake Independence) {"nombre": 5} [incertain]
     > The daily possession limit for walleye on these waters also remains at five fish
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
4. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MI-walleye-taille_min-etat` taille_min Walleye (État) {"pouces": 15}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-teal-min` taille_min walleye (Teal Lake) {"pouces": 15} [incertain]
     > The minimum size limit for possession remains at 15 inches.
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
5. **confirmée incertaine** — valeurs concordantes, mais un lecteur a écrit « incertain » (la règle confirmée est celle de B, plus fine)
   - A : `MI-walleye-limite_jour-etat` limite_jour Walleye (État) {"nombre": 5}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-teal-bag` limite_jour walleye (Teal Lake) {"nombre": 5} [incertain]
     > The daily possession limit for walleye on these waters also remains at five fish
   - Avis sur l'outil : juste : concordance gardée hors du chargement (incertaine)
6. **A et B seules** — code cir_toute_annee / capture_relache_toute_annee
   - A : `MI-lmb-capture_remise-etat` relacher Largemouth Bass (État) 01-01→12-31 {"code": "cir_toute_annee"}
     > CIR fishing for bass is allowed all year on all waters, unless otherwise closed to fishing. All bass caught must be immediately returned to the water
   - B : `b-lmb-cir` relacher largemouth bass (État) 01-01→12-31 {"code": "capture_relache_toute_annee"} [incertain]
     > The catch-and-immediate-release season for largemouth and smallmouth bass is open all year on nearly all waters
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
7. **A et B seules** — code cir_toute_annee / capture_relache_toute_annee
   - A : `MI-smb-capture_remise-etat` relacher Smallmouth Bass (État) 01-01→12-31 {"code": "cir_toute_annee"}
     > CIR fishing for bass is allowed all year on all waters, unless otherwise closed to fishing. All bass caught must be immediately returned to the water
   - B : `b-smb-cir` relacher smallmouth bass (État) 01-01→12-31 {"code": "capture_relache_toute_annee"} [incertain]
     > The catch-and-immediate-release season for largemouth and smallmouth bass is open all year on nearly all waters
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
8. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Teal Lake »
   - A : `MI-walleye-taille_min-etat` taille_min Walleye (État) {"pouces": 15}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-teal-min` taille_min walleye (Teal Lake) {"pouces": 15} [incertain]
     > The minimum size limit for possession remains at 15 inches.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
9. **A seule (B appariée est confirmée ailleurs)** — portée « État » / « Teal Lake »
   - A : `MI-walleye-limite_jour-etat` limite_jour Walleye (État) {"nombre": 5}
     > Walleye (NOTE 3) 15" 5
   - B : `b-wae-teal-bag` limite_jour walleye (Teal Lake) {"nombre": 5} [incertain]
     > The daily possession limit for walleye on these waters also remains at five fish
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
10. **A et B seules** — dates (None, None) / ('04-25', None)
   - A : `MI-walleye-saison-lp` autre Walleye (Lower Peninsula) {} [incertain]
     > Last Sat. in April – March 15: Lower Peninsula inland waters
   - B : `b-wae-lp-open` autre walleye (Lower Peninsula) 2026-04-25→None {} [incertain]
     > Lower Peninsula inland walleye and northern pike seasons open Saturday, April 25.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
11. **A et B seules** — nombres {'nombre': 2.0} / {'nombre': 5.0}; portée « État » / « Hanbury Lake »
   - A : `MI-pike-limite_jour-etat` limite_jour Northern Pike (État) {"nombre": 2}
     > Northern Pike (NOTE 4) 24" 2
   - B : `b-pike-hanburylake-bag` limite_jour northern pike (Hanbury Lake) {"nombre": 5} [incertain]
     > a daily possession limit of up to five northern pike, with only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
12. **A et B seules** — dates (None, None) / ('04-25', None)
   - A : `MI-pike-saison-lp` autre Northern Pike (Lower Peninsula) {} [incertain]
     > Last Sat. in April – March 15: Lower Peninsula inland waters
   - B : `b-pike-lp-open` autre northern pike (Lower Peninsula) 2026-04-25→None {} [incertain]
     > Lower Peninsula inland walleye and northern pike seasons open Saturday, April 25.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
13. **A et B seules** — code cir_toute_annee / capture_relache_toute_annee
   - A : `MI-muskie-capture_remise-etat` relacher Muskellunge (État) 01-01→12-31 {"code": "cir_toute_annee"}
     > CIR fishing for Muskellunge is allowed all year on all waters, unless otherwise closed to fishing. All Muskellunge caught must be immediately returned to the water
   - B : `b-musky-cir` relacher muskellunge (État) 01-01→12-31 {"code": "capture_relache_toute_annee"} [incertain]
     > catch-and-immediate-release fishing for muskellunge is open all year
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
14. **A et B seules** — nombres {'nombre': 2.0} / {'nombre': 5.0}; portée « État » / « Au Sable Lake »
   - A : `MI-pike-limite_jour-etat` limite_jour Northern Pike (État) {"nombre": 2}
     > Northern Pike (NOTE 4) 24" 2
   - B : `b-pike-ausablelake-bag` limite_jour northern pike (Au Sable Lake) {"nombre": 5} [incertain]
     > a daily possession limit of up to five northern pike, with only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
15. **A et B seules** — nombres {'nombre': 2.0} / {'nombre': 5.0}; portée « État » / « Clear Lake »
   - A : `MI-pike-limite_jour-etat` limite_jour Northern Pike (État) {"nombre": 2}
     > Northern Pike (NOTE 4) 24" 2
   - B : `b-pike-clearlake-bag` limite_jour northern pike (Clear Lake) {"nombre": 5} [incertain]
     > a daily possession limit of up to five northern pike, with only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
16. **A et B seules** — nombres {'nombre': 2.0} / {'nombre': 5.0}; portée « État » / « Gibson Lake »
   - A : `MI-pike-limite_jour-etat` limite_jour Northern Pike (État) {"nombre": 2}
     > Northern Pike (NOTE 4) 24" 2
   - B : `b-pike-gibsonlake-bag` limite_jour northern pike (Gibson Lake) {"nombre": 5} [incertain]
     > a daily possession limit of up to five northern pike, with only one of these fish 24 inches or greater allowed.
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »
17. **B seule (A appariée est confirmée ailleurs)** — dates (None, None) / ('06-06', None)
   - A : `MI-muskie-saison-etat` autre Muskellunge (État) {} [incertain]
     > 1st Sat. in June – March 15: All Gr. Lakes and inland waters and St. Marys R.
   - B : `b-musky-open` autre muskellunge (État) 2026-06-06→None {} [incertain]
     > muskellunge possession season on all Great Lakes, inland waters, the St. Marys River, Lake St. Clair, and the St. Clair and Detroit rivers opens Saturday, June 6
   - Avis sur l'outil : juste : une lecture incertaine ne fonde jamais « interdit »

## Concordances à surveiller : règle confirmée par une règle plus large de l'autre lecture (4)

Ce ne sont pas des désaccords : l'outil confirme une règle fine (zone, période, espèce d'un groupe) par la même valeur écrite plus largement par l'autre lecteur. C'est voulu, mais c'est le point où l'outil peut être trop laxiste : si la règle large était fausse ailleurs (lecteur qui écrit « État » pour « ruisseaux »), elle confirme quand même. Relu à la main ci-dessous.

1. portée plus fine — gardée : `b-wae-independence-min` taille_min walleye (Lake Independence) {"pouces": 15} [incertain] ; appui : `MI-walleye-taille_min-etat` taille_min Walleye (État) {"pouces": 15}
2. portée plus fine — gardée : `b-wae-independence-bag` limite_jour walleye (Lake Independence) {"nombre": 5} [incertain] ; appui : `MI-walleye-limite_jour-etat` limite_jour Walleye (État) {"nombre": 5}
3. portée plus fine — gardée : `b-wae-teal-min` taille_min walleye (Teal Lake) {"pouces": 15} [incertain] ; appui : `MI-walleye-taille_min-etat` taille_min Walleye (État) {"pouces": 15}
4. portée plus fine — gardée : `b-wae-teal-bag` limite_jour walleye (Teal Lake) {"nombre": 5} [incertain] ; appui : `MI-walleye-limite_jour-etat` limite_jour Walleye (État) {"nombre": 5}
