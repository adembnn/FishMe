# Notes lecteur A, Caroline du Nord, eaux intérieures (lecture du 2026-11-07)

## Sources lues
- Édition : « 2026-27 North Carolina Inland Fishing, Hunting & Trapping Regulations Digest, Effective August 1, 2026 » (page NCWRC https://www.ncwildlife.gov/hunt/fishing-hunting-trapping-regulations, lue ; le PDF FlippingBook officiel https://online.flippingbook.com/view/424369678/ n'a pas été extrait en texte).
- Texte réellement lu : les pages eRegulations NC du même digest (lien « View Online at eRegulations.com » de la page NCWRC ; robots.txt respecté ; éditeur tiers, pas le domaine de l'agence) : inland-fishing-regulations, warm-water-game-fish-regulations, general-mountain-trout-regulations, nongame-fish-regulations, nongame-fish-size-creel-limits, other-fishing-regulations (mises à jour du 10 et 13 juil. 2026), other-trout-fishing-waters (14 oct. 2025). Brutes : /private/tmp/claude-501/us-regles-nc-a/ (hors git).
- Licence de réutilisation d'eRegulations : [?] (déjà notée dans etats.json).

## Méthode des citations
Les tableaux sont aplatis dans le texte extrait. Une citation de tableau concatène les cellules d'une ligne dans l'ordre de lecture (séparateurs `|` supprimés) ; chaque citation a été vérifiée par programme comme sous-chaîne du texte normalisé.

## Eaux intérieures / côtières
Le digest parle d'eaux « inland, joint, coastal ». Seules les règles « inland » (ou « all public waters » ou « inland and joint ») sont lues ; les zones de gestion côtières (Roanoke, Albemarle, Central-Southern striped bass) et les règles de la Division of Marine Fisheries ne sont pas lues. La limite exacte inland / joint dépend de panneaux et d'une liste sur ncwildlife.gov (non lue) : [?].

## Ambigu ou non retenu
- « None » dans les colonnes taille / limite : enregistré en type « autre », incertain, jamais comme absence de contrainte (crappie, sunfish, spotted bass, yellow perch, channel / blue / flathead catfish hors liste).
- Striped bass hybride : nommé « Hybrid Striped (Bodie) » (le texte dit « Bodie bass (striped bass hybrid) ») ; attention, le normalisateur de consensus_us.py classe tout nom contenant « striped » et « bass » en « striped bass ».
- Sunfish : une seule espèce « Sunfish » (bluegill, redbreast, etc. sont des sunfish selon le texte) ; la règle des 30 est incertaine (listes de rivières avant la valeur dans un tableau aplati).
- Truite : espèce « Trout » (brook, brown, rainbow non distingués par le texte). Les dates 2026-27 sont écrites en AAAA-MM-JJ ; la réouverture Delayed Harvest suit le « first Saturday of June ». La fermeture des Hatchery Supported (mars 2027) est incertaine : liste « no closed season » sur une page non lue.
- Largemouth / smallmouth : règles « toutes eaux publiques sauf listées » ; l'exception de nombreux lacs (Santeetlah, Chatuge, Cammack, Holt, Phelps, etc.) = niveau 3, non écrite.
- Aucune saison de pêche écrite pour les poissons de jeu chauds (hors truite et striped bass sur proclamation) : rien déduit.
- Catfish : limites 7 channel catfish en étangs de parcs listés, blue catfish de Lake Norman, Kerr, Gaston, etc. : niveau 3, non écrites. Muskie, walleye, sauger : exceptions par lac (Lake James, Gaston, Kerr, Linville River) non écrites.
- Striped bass : exceptions (Hyco, Gaston, Roanoke Rapids, Dan River, Kerr, Chatuge) non écrites ; zones côtières non lues.
- Appâts : aucune règle générale d'appât pour les poissons de jeu lue dans ces pages (hors truite, palangres, Roanoke upstream of U.S. 258 barbless hooks 1er avr.-30 juin : niveau 3 non écrit). Nombre de cannes : rien lu.
- Pêche sur terres de chasse (« game lands ») et trout on game lands : section non lue.
- Eastern Band of Cherokee Indians et Great Smoky Mountains NP : le texte renvoie à d'autres agences ; aucune règle d'État tirée.

## Niveau 3 (existence et URL seulement)
- Truites par comté : https://www.eregulations.com/northcarolina/fishing/mountain-trout-regulations-counties-a-m et …-counties-n-z (listes de cours d'eau par classe) ; Catawba River (Muddy Creek à Morganton) et Apalachia Reservoir (Special Regulation) ; Mountain Heritage Trout Waters : …/other-trout-fishing-waters.
- Plans d'eau à règles propres de black bass, crappie, striped bass, walleye, catfish : tableaux de …/warm-water-game-fish-regulations et …/nongame-fish-size-creel-limits.
- Appareils spéciaux par comté (nongame) : …/nongame-fish-regulations.
