# Rapport lot us-etats-verif-2 (agent 2/4), lecture du 7 nov. 2026

États traités (positions 2 mod 4 du tri par code USPS) : AR, CT, GA, IL, LA, MI, MT, NH, NY, PA, TN, VT, WY. Un fichier `<USPS>.json` par État dans ce dossier.

## Verifie = true (8) : prix résident et non-résident lus sur la page officielle ce jour
AR 10,50 / 60 ; CT 28 / 55 (eau douce seule, année civile) ; GA 15 / 50 ; IL 15 / 31,50 ; NY 25 / 50 ; PA 27,97 / 60,97 ; VT 28 / 54 (année non écrite sur la page, confiance moyenne) ; WY 27 / 102.

## Verifie = false (5)
LA, MI, NH : pages officielles en 403 (WebFetch et curl, PDF compris). Les montants (LA 17/68, MI 26/76, NH 45/63) ne viennent que d'extraits de recherche de pages officielles, jamais lus : qualité `extrait_de_recherche_page_officielle_non_lue`.
MT, TN : hôtes injoignables depuis ce Mac (DNS pour fwp.mt.gov ; délai dépassé pour tn.gov/twra). MT 21 + 100 (hors licence de conservation et pass AIS) et TN non-résident 49 : non confirmés. TN résident : donnée absente.

## Corrections par rapport à etats.json
- Prix : CT (le 32/63 était « All Waters », eau douce = 28/55), LA (9,5 contredit 17/68 [?]), NH résident (null, 45 [?]), MT (31/117,5 = totaux tiers).
- URL : CT règles et permis étaient des 404 déguisés (200) ; IL règles : 404, redirige vers ifishillinois.org ; AR permis trouvée (plateforme officielle) ; VT permis trouvée (anrweb.vt.gov) ; NY et PA : formes d'URL actualisées ; NH, LA, MI, TN : URL de permis trouvées par recherche, 403 ou injoignable donc non démontrées.
- Timbres officiels relevés : AR trout 10/20, CT trout & salmon 5, IL trout 6,50 et salmon 6,50, PA trout 14,97, Lake Erie 9,97, combo 20,97, WY conservation 21,50 (obligation pour la pêche à confirmer) et réciprocité Flaming Gorge 30.

## Non relevé
Applis officielles (sauf GA : Outdoors GA), réciprocité et eaux tribales, licence de réutilisation des données : aucune page lue ne les donne. Le prix du Trout License de GA et du Habitat Stamp de VT n'a pas été lu.
## Méthode
curl (User-Agent honnête) pour statut HTTP et texte des pages ; WebFetch ; recherche web uniquement pour localiser des pages. Aucun site tiers n'a servi de preuve.
