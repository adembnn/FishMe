# Échelle K (0) → cartoon A (5) · écran E6, révélation de la prise

Même contenu partout : brochet 68 cm, peu commun (10 pêches sur 29 dans le 94), « Garder possible · 68 / 60 cm mini », 3 sur 11 espèces, 17:44. Matériau Liquid Glass sur les contrôles seulement. Polices en local (`fonts/`), poisson `img/brochet.png`.

## Ce qui change par niveau
| Niv. | Poisson | Typo | Couleur / décor | Rareté | Mouvement (final < 2,5 s) |
|---|---|---|---|---|---|
| 1 | gravure réaliste, inchangée | Quicksand (titres), Hanken (texte) | structure K : carte vert sapin, panneau papier ; fond lavé d'eau pâle | hexagone facetté à 2 points + « Peu commun » | carte qui monte, gravure révélée de la queue vers la tête, reflet de lumière, tampon rareté, 3e pastille de la barre 3/11 |
| 2 | même illustration détourée, lueur + ombre portée | Nunito 800/900 | dégradé eau clair → profond, rayons, bulles, carte blanche | pastille verte pleine + échelle à 5 couleurs (gris, vert, bleu, orange, or) | le poisson jaillit de l'eau avec ondes, carte rebondit, bulle de rareté qui pop |
| 3 | même illustration posterisée (flou + 4 paliers par canal, SVG filter) + contour crème | Baloo 2 | décor aplat « aube » pêche/sarcelle, carte crème sans trait | médaille autocollant festonnée + ruban | carte qui tombe et rebondit, poisson qui nage, médaille tamponnée, boutons qui rebondissent |
| 4 | poisson vectoriel dessiné, ombrages doux, sans contour noir | Fredoka | lagune menthe, carte inclinée de 1,6°, poisson qui déborde | goutte verte | poisson qui saute, éclaboussures, confettis, jauge d'eau 10 / 29 |

## Références par niveau
1 : cartes de collection sobres, fiche espèce de livre de poche, barre de progression de journal de jeu.
2 : Pokémon GO (grand « PC » centré, fond de décor, boutons pilule), Pokémon Sleep (douceur, dégradés pastel).
3 : Alto's Odyssey (aplats de lumière), Monument Valley (formes simples), menus Pokémon Sleep, autocollants.
4 : jeux casual Apple Arcade colorés, sans cadre noir. Écarté volontairement : traits épais, rayons bleus, jauge à capsules (propres à A).

## Détecteur impeccable (justifications)
- Niv. 1 : contraste 4,3 corrigé (vert assombri à #176B42). Reste : « bordure fine + ombre large » et « lueur sombre » = le matériau Liquid Glass (bord de 1 px + ombre) sur la barre de boutons, voulu.
- Niv. 2, 3, 4 : mêmes deux alertes verre, voulues. « side-tab » = rebord inférieur biseauté du bouton principal (relief de bouton de jeu), pas une bordure latérale de carte. « clipped-overflow » niv. 2 : `overflow:hidden` du cadre d'écran d'iPhone, voulu.
- Niv. 2, contraste signalé 2,3 / 1,8 : le détecteur lit le bas du dégradé de fond ; le titre et le sous-titre réels sont posés sur la partie claire du dégradé (bleu clair, > 7:1 vérifié à l'œil). « Partager » (marine sur verre clair) mesure environ 8:1 sur le rendu.
- Pas vérifié par outil : ratio exact du texte sur les verres (valeurs lues sur capture, non mesurées).

## Limites
- La posterisation du niv. 3 garde un peu de bruit sur le dos du poisson (hachures de la gravure) ; un 4e palier de couleur par canal donne environ 6 à 10 teintes visibles, pas exactement 6.
- Animations vérifiées sur capture à 2,8 s seulement (état final), pas en vidéo.
