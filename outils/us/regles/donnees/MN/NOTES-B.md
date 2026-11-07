# Notes du lecteur B : Minnesota (lu le 2026-11-07)

## Sources lues
- www.dnr.state.mn.us et www.mndnr.gov : défi Cloudflare (403) sur robots.txt et toutes les pages ; aucun contournement tenté.
- Lu : livret officiel « 2026 Minnesota Fishing Regulations », mis à jour le 4 juin 2026, valable de mars 2026 au 28 févr. 2027 (101 pages, 10,7 Mo, `files.dnr.state.mn.us/rlp/regulations/fishing/fishing_regs`, robots.txt de ce domaine sans objection). Le livret dit lui-même qu'il n'est pas un texte juridique. Pages 11, 13-14, 20, 29-33, 37-46 lues.
- Lu pour croiser : Minnesota Rules 6262.0200 (revisor.mn.gov, publié le 8 avr. 2026) : saisons, limites, brochet, bass, truite, esturgeon concordent avec le livret, sauf walleye (voir plus bas). Aussi les PDF de projets de règles `walleye-202601.pdf`, `bass-season-202509.pdf`, `inland-waters-rule-202408.pdf` (propositions, non en vigueur : cités comme contexte seulement).
- Revisor 6262.0300, 0400, 0500, 0575 et statuts 97C.001, .081, .315, .345, .375, .395, .805 téléchargés mais non exploités (pas de règle en tirée).
- Texte brut : /private/tmp/claude-501/us-regles-mn-b/ (non versionné).

## Divergence à trancher
- Walleye « only 1 walleye over 20" in possession » : dans le livret 2026, absent de 6262.0200 publié le 8 avr. 2026 (« 6 in aggregate » seulement). Un projet (RD4929, effet 1er mars 2027) l'ajoute. Règle écrite `incertain`.

## Choix d'écriture
- Dates 2026 écrites avec années (ex. 2026-05-09 au 2027-02-28) : ce sont les dates du livret 2026 ; la plupart sont « flottantes » (samedi avant Memorial Day, etc.) et changent chaque année.
- Limite journalière et limite de possession émises toutes deux ; la journalière cite la phrase du livret « Daily and possession limits are the same unless otherwise noted. ».
- Limite « 6 combined » walleye+sauger, largemouth+smallmouth : une règle par espèce, la combinaison est dans `valeur.texte`.
- Les « 1 over X » et « au plus N over X » sont de type `autre` (nombre + pouces), pas de type propre dans le schéma.
- Pike : 3 zones en `niveau_portee: zone`. Esturgeon jaune : le livret ne donne que 16 juin au 14 avril (remise à l'eau seule) ; la fermeture du 15 avril au 15 juin vient de 6262.0200 (citation de la règle).
- Règles `incertain` : walleye over 20", heures de pêche de la truite, mouches (règle multi-espèces), Mille Lacs, Upper Red Lake, existence des règles spéciales.

## Manques (non lus)
- Plans d'eau à règles spéciales (livret pp. 46-64, LakeFinder https://www.dnr.state.mn.us/lakefind/) : existence seulement.
- Eaux frontalières (pp. 66-77), Lake Superior (pp. 34-36), pêche à la dark house (p. 81), pêche sur glace (p. 82), arcs/harpons (pp. 78-80).
- Truite : cours d'eau dans les parcs et villes du Sud-Est (p. 33), liste des lacs à truite désignés ; saisons fermées saisonnières (publiées chaque printemps sur mndnr.gov/regulations/fishing, bloqué).
- Permis de pêche non lus ici ; saisons 2027 (dates différentes) non écrites ; shovelnose sturgeon, burbot, carpe, bullhead, rock/white/yellow bass non écrits sauf mention.
- Les citations ont été vérifiées par script contre le texte extrait (180 sur 180 présentes) ; les 2 colonnes des tableaux du livret sont recomposées par PDFKit, l'ordre peut différer de la mise en page.
