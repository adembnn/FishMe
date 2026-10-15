# Pescedex par zone : le grill

Idée d'Adem (15 oct.) : remplacer « 3 sur 11 espèces » par un compteur par zone de pêche : « dans cette zone, N espèces sont présentes, tu en as trouvé 2 ».

## Ce que disent nos données (vérifié dans build/fiches/D2.md et build/donnees.md)
- Source : les pêches scientifiques de l'OFB (Hub'Eau), **par station** (un point sur une rivière, avec sa position), 14 espèces suivies.
- Le 94 n'a que **3 stations et 29 pêches** depuis 2016. Plus la zone est petite, plus la liste est maigre ou vide.
- Donc toute zone plus fine que le département a besoin d'une solution de repli (zone vide → on élargit au département, puis à la région).

## 7 façons de définir une zone (probabilité qu'un autre LLM la propose)
| # | Zone | Exemple d'écran (chiffres fictifs) | Proba | Pour | Contre |
|---|---|---|---|---|---|
| 1 | Département | « Val-de-Marne · 3 sur 11 » | 70 % | données prêtes | c'est ce qu'Adem n'aime pas |
| 2 | Rivière dans le département | « La Marne (94) · 2 sur 9 » | 35 % | parle au pêcheur, stations rangées par rivière | rivière sans station = vide |
| 3 | Rayon autour de toi (10 km) | « Autour de toi · 2 sur 8 » | 30 % | suit l'utilisateur | la liste change quand on bouge, pas de « zone » à finir |
| 4 | Le coin lui-même | « Coin B · 1 sur 4 » | 20 % | collection très locale, envie de revenir | 1 station au mieux par coin, souvent 0 |
| 5 | Bassin (Seine, Loire, Rhône…) | « Bassin de la Seine · 3 sur 14 » | 15 % | grand album, voyage = nouvelle page | trop grand pour sentir le progrès |
| 6 | **Territoire de l'AAPPMA** (l'association dont tu as la carte de pêche) | « AAPPMA de Saint-Maur · 2 sur 7 » | 10 % | c'est la vraie « zone » d'un pêcheur, liée à sa carte | contours pas disponibles en open data partout [à vérifier] |
| 7 | **Bief** (tronçon entre deux écluses) | « Bief de Joinville · 2 sur 5 » | 8 % | très authentique sur la Marne et les canaux | rien que pour les rivières à écluses, données rares |

À part, valable avec n'importe quelle zone : **compter ce qui est ouvert aujourd'hui** (« 4 ouvertes aujourd'hui, tu en as 2 »), proba 12 %. Le compteur bouge avec les saisons, la collection reste.

## Ce qu'un jury exigeant demandera
- « Disponible » veut dire quoi : vu par l'OFB dans la zone, ou pêchable aujourd'hui ? Les deux ne donnent pas le même chiffre.
- Où va la truite fario (jamais relevée dans le 94) ? Elle ne peut pas être « sur N » puisqu'elle n'est pas dans la liste. Défaut : une ligne à part « Hors liste · 1 » (les légendaires).
- Que se passe-t-il quand on pêche dans une autre zone : le compteur repart à zéro, ou chaque zone a sa page ?
- Que voit un nouveau joueur qui n'a rien : « 0 sur 9 » est décourageant. Défaut : « 9 espèces à trouver ici ».

## Ma recommandation
Zone = **rivière dans le département** (n°2), avec repli sur le département si la rivière n'a pas de station. Compteur = espèces vues par l'OFB dans la zone (11 pour la Marne dans le 94, faute d'autres stations), et « ouvertes aujourd'hui » en option. Collection = un seul Pescedex, avec une page par zone visitée et un tampon quand une zone est complète.
