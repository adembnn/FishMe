# Design système FishMe (16 oct. 2026)

Base retenue par Adem le 15 oct. : piste « Natif » (façon Plans d'Apple) partout, Pescedex en classeur de cartes (piste « Pochette »), palette Marine (18h30), SF Pro Rounded en gras, carte à collectionner « quatre raretés » (planche K, version 9 de la planche Variations), ratio 69/100, une seule taille.
Le 16 oct. (2h), Adem a trouvé que l'app compilée s'en éloigne : ce dossier refixe le design et dessine toutes les pages en 3 directions pour qu'il choisisse.

- Toile de design (42 pages × 3 directions + le design système) : https://claude.ai/artifact/LuNqsFnnaXbrBb62T6hLgd
- `cartographie.md` : les 42 pages, ce que chacune montre, et la vue SwiftUI qui la porte.
- `kit.md` : règles de dessin, images, icônes, les 3 directions, interdits et données d'exemple.
- `fishme-ds.css` : les composants en CSS (miroir des jetons de `App/Style/Style.swift`).
- `maquettes/` : la source de chaque maquette (`P06-carte-A.dc.html`…, planche des cartes `C01` à `C07`) et son aperçu JPG ; `canvas.json` place tout sur la toile.
- `choix.md` : la direction choisie par Adem pour chaque page (à remplir).

## Jetons (identiques à `App/Style/Style.swift`)
| Rôle | Jeton Swift | Valeur |
|---|---|---|
| Marque, boutons, onglet actif, spot | `Palette.marine` | #0D4A85 |
| Texte | `Palette.encre` | #0E1A26 |
| Texte secondaire | `Palette.encreDouce` | #566576 |
| Fond des pages | `Palette.fond` | #F2F5F9 |
| Feuilles, listes | `Palette.surface` | #FFFFFF |
| Fond des vignettes poisson | `Palette.tuile` | #E7EFF8 |
| Séparateurs | `Palette.filet` | #DCE3EB |
| Ouvert, taille atteinte | `Palette.ouvert` | #13643B |
| Alertes seulement (orage, crue, fermé) | `Palette.alerte` | #E8571C |
| Commun · rond · 1 point | `Palette.commun` | #6B7780 |
| Peu commun · hexagone · 2 points | `Palette.peuCommun` | #23885A |
| Rare · losange · 3 points | `Palette.rare` | #5B4FD0 |
| Légendaire · étoile · 4 points | `Palette.legendaire` | #B07A12 |

Typographie (SF Pro Rounded, gras) : grand titre 34 heavy, titre 22, sous-titre et corps 17, détail 15, légende 13, chiffre 34 et 96 heavy à chiffres tabulaires.
Espacements 4, 8, 12, 16, 24, 32 ; marge 16 ; zone tactile 44 ; bouton 54 en pilule ; rayons 10, 16, 22, feuilles 32 à 38.

## Les trois directions
- **A · Plans** : le monde d'abord (carte, photo, viseur ou carte à collectionner en plein écran), le reste dans une feuille blanche en bas et des boutons ronds en verre.
- **B · Réglages** : le natif pur, grand titre et listes groupées en encart, vignette poisson, valeur grise, chevron, aucun décor.
- **C · Sujet** : une seule chose par écran, en très grand sur fond blanc, trois lignes au plus, un bouton.

## Règles qui ne bougent pas
Barre d'onglets standard à 3 volets (Pescedex · Carte · Club), aucune barre de défilement visible, poissons toujours en images, peu de texte, un seul bouton principal par écran, l'orange seulement pour les alertes, le violet seulement pour « rare », aucun cadre jaune, « Choisir un autre spot », un seul bouton « Ajouter au Pescedex », jamais « tu peux la garder », jamais « bon spot », jamais Poké.
