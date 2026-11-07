# Notes lecteur A, New York (lecture du 2026-11-07)

## Ce qui a marché
Le guide PDF (https://extapps.dec.ny.gov/docs/fish_marine_pdf/fishguide.pdf, 8,4 Mo) se télécharge avec curl, mais son en-tête indique « Last-Modified: 24 mars 2023 » : édition ancienne, NON utilisée (pas de pdftotext sur la machine, non lu). Les règles viennent des pages officielles DEC, récupérées avec curl (User-Agent honnête, robots.txt consulté, pages non interdites) :
- Statewide Seasons, Sizes, and Catch Limits : https://dec.ny.gov/things-to-do/freshwater-fishing/regulations/statewide-season-sizes-catch-limits . Tableau « Statewide Regulations Effective April 1, 2026 » (édition courante ; pas d'autre date de publication affichée). Lu en entier.
- General Freshwater Fishing Regulations (/regulations/general) : lu en entier (définitions, engins, glace, découpe, appâts naturels).
- Baitfish Regulations (/regulations/baitfish) : lu ; listes de plans d'eau interdits (Régions 3 à 6) survolées, non reprises.
- Inland Trout Stream Special Regulations (/regulations/inland-trout-stream-regulations) : seules les 4 catégories de gestion lues ; tableaux de tronçons non lus.
- 6 NYCRR 10.1, copie Cornell LII (non officielle, dernière modification citée 2024-09-18) : Table A utilisée comme recoupement (identique à la page DEC pour les espèces communes) et pour la ligne « Catfish ».
Texte brut : /private/tmp/claude-501/us-regles-ny-a/*.txt (hors git). Les citations sont vérifiées par script comme sous-chaînes du texte extrait ; dans les lignes de tableau, « | » marque une frontière de cellule (ajout de l'extraction).

## Choix et limites
- Le tableau statewide est le régime d'État ; la page dit « Exceptions may apply ... Check the Special Regulations ». Les règles d'État claires sont `brouillon` ; aucune exception de plan d'eau n'a été lue. Le chargeur devra donc croiser avec le niveau 3.
- Saisons à cheval sur deux années (walleye, pike, pickerel, tiger muskie : « May 1 - Mar 15 ») écrites 05-01 au 03-15 : c'est la saison ouverte du texte (fermée du 16 mars au 30 avril), pas une période de fermeture.
- Bass : largemouth et smallmouth répétés séparément (une espèce par règle) ; 1er déc.-14 juin : remise à l'eau seulement et leurres artificiels seulement, deux règles.
- Trout : brook / brown / rainbow en lacs et étangs, et en « inland trout streams » (catégorie Wild and Stocked). Les catégories Stocked-Extended, Wild-Premier, Catch and Release et les tronçons ont des règles propres (niveau 3). Limite « 5 with only 2 longer than 12" » : incertaine (deux nombres), sous-limite à part. Splake non écrit séparément.
- Lake trout 21 po / 3 ; landlocked salmon 15 po / 3 (« Atlantic Salmon (Landlocked) »). Coho et Chinook renvoient aux règles Grands Lacs (non lues).
- Crappie (noir et blanc) et Sunfish (bluegill, redbreast, pumpkinseed) : noms de groupe du texte.
- Lake sturgeon : fermeture statewide explicite (pêche, remise à l'eau et possession interdites) ; sauger et paddlefish idem. Silence sur les autres esturgeons (Atlantic, shortnose : même ligne, non dupliquées).
- Channel catfish : non nommé sur la page DEC (ligne « All other species »). Seule la ligne regroupée « Catfish » de la copie LII sert : saison toute l'année, `incertain`. Aucune limite écrite (« Any number » non converti en nombre ; ce n'est pas une règle de prise). Rien déduit du silence.
- Tailles minimales : mesure du museau au bout de la queue, bouche ouverte ou fermée (règle `autre`).
- Engins : 3 lignes, 5 leurres/appâts par ligne, 15 pointes, présence immédiate, gaffes, glace (7 lignes). Pêche sur glace exclue dans 9 comtés : `incertain` (exceptions imbriquées).
- Appâts : poissons-appâts achetés (liste « Green List »), certification, corridors, tailles de filets : non repris (hors besoin ; lire la page Baitfish). Repris : espèces interdites comme appât, même plan d'eau, transport, oeufs, amphibiens/serpents, insectes aquatiques, listes de plans d'eau interdits (renvoi seulement).
- Le guide dit « Closed season ... may not fish ... including catch and release » : règle générale sans verdict (pas d'espèce).

## Niveau 3 (existence et URL seulement)
Grands Lacs et affluents : /regulations/great-lakes-tributaries ; Finger Lakes : /finger-lakes-tributaries-special-regulations ; Hudson tidal : /tidal-hudson-river-special-regulations ; eaux frontalières : /border-waters-special-regulations ; Régions 1 à 9 : /regulations/region-N-special-fishing ; carte interactive des cours d'eau à truites (page trout stream). Tous sous https://dec.ny.gov/things-to-do/freshwater-fishing/regulations . Une consultation de rulemaking sur les étangs à ombles de fontaine des Adirondacks a été annoncée (communiqué d'octobre 2026, non lu) : les règles de ces étangs peuvent changer.

## Non vérifié
Pas de relecture par un second moyen des pages Régions ni Grands Lacs ; pas de lecture du guide PDF 2026 (le PDF accessible est de 2023) ; pas d'accès à la version officielle de 6 NYCRR (copie LII).
