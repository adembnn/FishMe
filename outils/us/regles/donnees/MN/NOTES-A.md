# Notes du lecteur A, Minnesota (lu le 2026-11-07)

## Source lue
Livret officiel « 2026 Minnesota Fishing Regulations », PDF du DNR, mention « Updated 6.4.26 », en vigueur de mars 2026 au 28 février 2027 : https://files.dnr.state.mn.us/rlp/regulations/fishing/fishing_regs.pdf (101 pages, texte extrait avec PDFKit, copie dans /private/tmp/claude-501/us-regles-mn-a/regs.txt). Lu : pp. 13, 20, 29-33, 37-40, 45 et recherche des passages sturgeon. Le livret dit lui-même n'être qu'un résumé, pas un texte juridique.

## Accès
- www.dnr.state.mn.us (pages, robots.txt, PDF) : 403 (Cloudflare) pour curl et WebFetch. Rien lu là.
- files.dnr.state.mn.us (PDF ci-dessus) : 200, robots.txt sans interdiction de ce chemin.
- eRegulations : défi Cloudflare, non lu. Revisor.mn.gov (statuts, règlements) téléchargé mais non utilisé.

## Couvert (64 règles, toutes eaux intérieures niveau 2)
Walleye, sauger, muskie et tiger muskie, largemouth et smallmouth (zones Sud/Centre-Nord et Nord-Est), grand brochet par zone, crapet, sunfish, perchaude, barbues de rivière et à tête plate, esturgeon jaune (remise à l'eau seulement), truites de ruisseau (mouchetée, brune, arc-en-ciel) en cours d'eau et en lacs, touladi, engins (lignes, hameçons), appâts.
Les citations sont vérifiées par programme comme sous-chaînes exactes du texte extrait (espaces et retours à la ligne ramenés à un espace).

## Incertain (statut incertain)
Brochet : les trois lignes de zones sont mêlées dans l'extraction PDF ; rattachements Nord-Est et Centre-Nord à relire sur la page 31. Walleye « 1 de plus de 20 pouces » (codage ambigu). Touladi d'hiver (dates 2027 différentes, BWCAW distinct). Méthodes interdites (regroupées). Épervier pour appâts.

## Choix de codage
- Limite de jour et limite de possession : le livret dit qu'elles sont identiques sauf mention ; seule la limite de possession est écrite (sauf perchaude : 20 par jour, 40 en possession). Pas de règle limite_jour dérivée.
- Limites « combinées » (walleye+sauger, black-bass, truites) : une règle par espèce, la combinaison dite dans valeur.texte.
- Sunfish : catégorie du livret (bluegill, pumpkinseed, etc.), pas de ligne « bluegill » seule.
- Dates : MM-JJ, saisons à cheval sur l'année gardées du > au. Les ouvertures changent chaque année (page 13 : walleye et brochet 9 mai 2026, 15 mai 2027 ; muskie 6 juin 2026, 5 juin 2027 ; truite de ruisseau 11 avril 2026, 10 avril 2027). Règles valides du 2026-03-01 au 2027-02-28.

## Non lu ou hors mission
- Plus de 90 plans d'eau à règles spéciales sur le brochet (niveau 3) : existence seulement ; le livret les liste pp. 45-64 et renvoie à https://www.dnr.state.mn.us/pike/index.html (non lue, 403 attendu). Je n'ai pas compté ces eaux moi-même : le chiffre « plus de 90 » vient de la mission.
- Mille Lacs, Red Lake supérieur, eaux frontalières (pp. 66-77), lac Supérieur (pp. 34-36), exceptions de truite du Sud-Est (p. 33), esturgeon des eaux frontalières et étiquette (p. 67, règles 2026 « not final » selon le livret), eaux fermées saisonnières, hameçons de truite, permis et timbres, tailles de crapet/sunfish en eaux spéciales, tableau des permis de conservation (p. 28).
