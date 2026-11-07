# Rapport us-etats-verif-1 (7 nov. 2026)

13 États (position 0-based ≡ 1 mod 4 par code USPS) : AL, CO, FL, ID, KY, ME, MS, NE, NV, OR, SD, VA, WV. Un JSON par État dans ce dossier. Lecture : curl avec User-Agent honnête (FishMeBot, contact), WebFetch, extraction de texte local des PDF officiels. Aucun contournement de blocage.

## Vérifiés (prix résident et non-résident lus aujourd'hui sur source officielle) : 8
- AL 17,45 / 68,20 ; CO 44,87 / 124,01 (+ timbre habitat 12,76) ; FL 17 / 47 (plateforme officielle gooutdoorsflorida.com, myfwc.com étant en 403) ; NV 40 / 80 ; OR 50 / 138 (barème PDF ODFW, colonne 2026) ; SD 31 / 80 (+ Habitat Stamp 10 / 25) ; VA 28 / 72 ; WV 19 / 37 (livret PDF 2026, + timbre conservation 5 / 13).

## Partiels (verifie = false) : 2
- ME : 30 / 83 lus dans la loi (Title 12 §12501), pas sur la page de l'agence (403).
- MS : non-résident 68 $ ; le prix résident (10 $) est celui d'une licence combinée chasse + pêche, aucune licence de pêche seule listée.

## Bloqués : 3
- ID : idfg.idaho.gov refuse la connexion. KY, NE : 403 sur tout. Aucun prix retenu ; indices de moteur de recherche (non lus) notés dans `notes`. KY : le règlement 301 KAR 5:022 donne 23 / 55 $ comme montants de base ajustés à l'inflation.

## Corrections pour lot/us-etats
- Prix : AL 17 -> 17,45 ; NV (40/80 confirmés) ; OR 44/110,50 -> 50/138 ; SD 28/67 -> 31/80 ; WV 29/53 -> 19/37 ; MS 12,29/64,29 -> 10 (combiné)/68 ; ME non-résident ajouté 83 ; CO totaux 44,87/124,01 (base 42,12/121,26).
- Timbres : CO habitat 12,76 ; SD habitat 10/25 ; WV 5/13, truite 10/16 ; OR tags et ocean endorsement.
- URL : NV règles -> /rules-regulations/ et permis -> /apply-buy/fishing/ (les anciennes en 404) ; SD règles -> /fish/ et permis -> /license-types/ ; OR agence -> myodfw.com, permis -> /fishing/licensing-info ; CO permis -> /activities/fishing-licenses-and-dates ; WV permis -> /buy-a-license/ ; AL permis -> /licenses/freshwater-fishing-licenses ; MS permis -> .../licenses-permits/hunting-and-fishing-license-prices ; FL permis -> license.gooutdoorsflorida.com ; ID, KY, ME, NE : URL de tarifs candidates (non lues).
- Applis : CO myColorado ; ID Go Outdoors ID ; MS MDWFP HuntFish.
- Licence de réutilisation : aucune page trouvée pour ces États. Réciprocité : AL page ALA-MISS-TENN (non lue).
