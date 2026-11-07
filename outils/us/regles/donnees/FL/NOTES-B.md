# Floride (FL), lecteur B : notes de lecture (7 nov. 2026)

## Source de départ : le texte de loi, pas le site FWC
- Florida Administrative Code (FAC) lu sur flrules.org (officiel, `www.flrules.org/gateway/RuleNo.asp?id=...`, fichiers .doc de la version finale, convertis par textutil, curl avec User-Agent honnête) : 68A-23.005 (en vigueur 2024-07-01, dernière version finale listée), 68A-23.002 (2022-06-07), .004, .007, .009 (2025-05-28), .0131 (lu, rien écrit), 68A-1.004 (définitions, 2026-07-01), 68A-20.004 (FMA).
- myfwc.com : HTTP 403 (curl et WebFetch), donc pages « freshwater regulations » et pages par espèce NON lues. Alternative officielle utilisée : flrules.org ; recoupement de contexte par Cornell LII (non officiel, texte identique) ; couche FMA ouverte : https://gis.myfwc.com/hosting/rest/services/Open_Data/Fish_Management_Areas_Florida/MapServer (HTTP 200).
- Textes bruts : /private/tmp/claude-501/us-regles-fl-b/ (hors git). Chaque citation est vérifiée comme sous-chaîne du texte extrait.

## Points d'attention
- Un avis de développement de règle (2025-02-19, Vol. 51/34) sur 68A-23.005 (noms largemouth/Florida bass, conservation génétique) est visible ; aucune version finale postérieure à 2024-07-01 listée. À revérifier.
- 68A-23.005(3) : toute règle propre à un plan d'eau remplace la règle générale. Les règles spéciales de plans d'eau (68A-20.005 par FMA ; autres eaux) ne sont pas lues : les règles d'État « black bass » sont en brouillon mais à confronter au niveau 3.
- Saison : le texte dit 1er juillet au 30 juin ; écrit 01-01 à 12-31.
- Espèces nommées comme dans le texte : « black bass » (genre Micropterus, largemouth compris par 68A-1.004), « crappie » (black et white), « panfish » (liste de 9 espèces dans 68A-1.004(33)(c) dont bluegill, redear, redbreast, warmouth, spotted sunfish). Pas de règle propre au largemouth seul hors TrophyCatch/record (non écrit).
- Striped bass nord-ouest : « kill or possess more than 3 » sans « par jour » : possession, incertain.
- Okeechobee crappie 10 pouces : périmètre du lac non repris, incertain.

## Manques
- Channel catfish et white catfish : aucune limite d'État lue (silence non interprété). Seule règle : 6 channel catfish en FMA (incertain).
- Hybrid : seulement les totaux cumulés striped/sunshine/white ; pas de taille minimale propre au sunshine bass.
- Appâts : alinéa 68A-23.002(6) seulement partiel ; autres engins (68A-23.003 commercial, 68A-23.012 Okeechobee) non écrits ; trotlines par plan d'eau non écrites.
- Niveau 3 non écrit (existence seulement) : 68A-23.0131 (Lake Seminole, St. Marys, Lake Jackson Walton, Perdido, avec permis GA/AL), 68A-20.005 (FMA, https://www.flrules.org/gateway/RuleNo.asp?id=68A-20.005), WMA (68A-15.061 à .065). Écrites pour l'exemple car dans 68A-23.005 : Talquin, Chipola, Okeechobee, sources fermées, Wildcat Lake. Non écrits : trois autres sites sans black bass, TrophyCatch et record.
- Unités du texte : pouces, nombre.
