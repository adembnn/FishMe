# Notes du lecteur A : Michigan (MI), eaux intérieures

Date de lecture : 2026-11-07.

## Source lue
- Guide officiel DNR : **2026 Michigan Fishing Regulations** (PDF « web accessible », 76 pages, « Rules apply from April 1, 2026 – March 31, 2027 »). Date de publication : non indiquée dans le PDF.
- michigan.gov répond **403** à l'outil (pages, PDF, robots.txt). Le PDF a été lu dans la **copie Wayback Machine du 2026-10-21** de l'URL officielle (21 Mo, texte extrait avec PDFKit). Ce n'est donc pas une lecture directe du site de l'agence : à garder en tête pour la revue humaine.
- URL officielle du PDF : https://www.michigan.gov/dnr/-/media/Project/Websites/dnr/Documents/LED/digests/2026-Michigan-Fishing-Regulations_web_accessible.pdf
- Bulletin DNR du 2026-04-01 (govdelivery 40febe5) lu en entier : liste des changements 2026 (walleye PSL, burbot, lake trout du Lac Supérieur, perles, esturgeon de la Menominee). Il confirme l'édition 2026.
- eRegulations : ouvert, texte non recopié ni utilisé comme source (page chargée par script ; aucune règle lue là).
- Texte brut : /private/tmp/claude-501/us-regles-mi-a/ (guide.txt, bulletin-40febe5.txt).

## Trois ensembles d'eaux (le guide les distingue)
- Eaux intérieures : lues (tableau général p. 12, notes pp. 13-14, méthodes pp. 10-11, truite intérieure pp. 42-46).
- Grands Lacs et eaux de liaison (Lake St. Clair, St. Clair R., Detroit R., St. Marys R.) : existent (pp. 18-21, saisons différentes) ; **non lus**. Les cellules du tableau p. 12 qui les concernent ne sont pas des règles ici.
- Eaux frontalières Michigan-Wisconsin (pp. 24-25, Menominee, Brule, Montreal) : existent, règles propres ; **non lues**.

## Niveau 3 : existence seulement (aucune règle écrite)
- Exceptions par comté : pp. 28-31 (« Exceptions to General Regulations by County »).
- Listes de plans d'eau : brochets à fenêtre protégée 24-34 pouces et « jusqu'à 5 brochets » (p. 14), tailles minimales de muskellunge 38/46/50 pouces (p. 13), walleye à fenêtre protégée Lake Independence et Teal Lake (Marquette, p. 13), exceptions walleye/yellow perch des notes 3 et 5 (Ontonagon R., Portage/Torch, Lake Gogebic).
- Esturgeon jaune : tableau p. 15 par plan d'eau (Otsego Lake, Black Lake, Menominee R., etc.) : existence seulement.
- Truite intérieure : types de lacs A-F (p. 42), types de cours d'eau 1-4, zones de restauration de l'omble de fontaine, cours d'eau à engins restreints (pp. 43-46), listes par comté (pp. 48-65). Le type d'un plan d'eau précis se lit sur les cartes https://www.michigan.gov/FishingMaps ou le service ArcGIS « DNR Fisheries » (fourni dans etats.json, non lu).
- Walleye des Grands Lacs (Saginaw Bay, Lake Erie, etc.) : hors périmètre.

## Choix de lecture à discuter avec le lecteur B / le consensus
- Les règles d'État du tableau p. 12 sont `brouillon` bien que le tableau renvoie à des exceptions : celles-ci sont des règles de niveau 3 séparées. Marquer toute règle d'État `incertain` aurait vidé le consensus.
- Dates relatives (samedi avant Memorial Day, dernier samedi d'avril, 1er samedi de juin) : impossibles en MM-JJ ; règles de type `autre`, `incertain`, texte dans `valeur.texte`. Seules les saisons à date fixe (walleye et brochet de la Péninsule supérieure : 05-15 au 03-15) sont des `saison`.
- Black-bass : « 5 in any combination » écrit comme 5 par espèce avec `valeur.texte` précisant la limite commune. Même chose pour les « sunfishes » (25 communs ; bluegill, black et white crappie écrits séparément ; autres espèces de la note 6 non écrites).
- Truite : seules les règles des eaux non classées par type (p. 42 lacs, p. 44 cours d'eau) sont écrites ; pour le lake trout, le texte dit « trout » sans le nommer : `incertain`.
- Taille « No size limit » (perchaude, sunfishes) non écrite comme règle (le silence n'est pas une règle ; seules les limites chiffrées le sont).
- Durée de possession (« additional 2 daily possession limits » si transformé) : non écrite (hors espèces listées, définition p. 9).
- Esturgeon : fermeture « All Other Waters NO FISHING SEASON » en `interdit`, portée « autres eaux ».
- Muskellunge et esturgeon : 1 poisson par année, enregistrement sous 24 h : type `autre`.

## Manques
- Burbot (5/jour, p. 12), white bass, cisco et whitefish, smelt : non écrits (hors liste demandée).
- Appâts : règles de lacs de type D et cours d'eau à engins restreints non lues. Pas de lecture des pp. 22-23 (netting) ni 26 (Sylvania).
- Édition du 21 oct. 2026 (Wayback) : changements ultérieurs du DNR éventuels (message 888-367-7060, michigan.gov/Fishing) non vérifiés.
