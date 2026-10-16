# Design système FishMe

Tout ce qu'il faut pour montrer le design de FishMe (slides du jury, fiche App Store). Mis à jour le 16 oct. 2026.

- **Toile interactive** (toutes les pages, les 3 directions, les cartes qui nagent) : https://claude.ai/artifact/LuNqsFnnaXbrBb62T6hLgd (privée : Adem la partage depuis le menu Partager).
- **Vue d'ensemble en une image** : [`ecrans-choisis-planche.jpg`](ecrans-choisis-planche.jpg) (les écrans retenus côte à côte).
- **Planche du design système** : [`composants/design-systeme-planche.png`](composants/design-systeme-planche.png) (couleurs, police, boutons, raretés, carte).

## Le style en une phrase
iOS natif, façon Plans d'Apple, épuré : peu de texte, des poissons en images, des chiffres, un seul bouton principal par écran. Palette « Marine », police SF Pro Rounded en gras partout. L'orange sert aux seules alertes.

## Couleurs (mode clair · mode sombre)
| Rôle | Jeton | Clair | Sombre |
|---|---|---|---|
| Couleur principale | `marine` | #0D4A85 | #7FB8EE |
| Texte | `encre` | #0E1A26 | #E7EDF3 |
| Alerte seulement (orage, crue, fermé, sous la taille) | `bouchon` / `alerte` | #E8571C | #FF7A45 |
| Fond | `fond` | #F2F5F9 | #0D1218 |
| Surface (cartes, feuilles) | `surface` | #FFFFFF | #151C24 |
| Nuit (lancement, partage) | `nuit` | #082A4C | #071A2E |
| Eau sur la carte | `eau` | #9CC7EA | #17486A |
| Ouvert aujourd'hui | `ouvert` | #13643B | #6FE0A4 |

### Les 4 raretés (fréquence dans les relevés OFB du département)
| Rareté | Couleur | Forme du badge | Points |
|---|---|---|---|
| Commun (50 % des pêches et plus) | ardoise #6B7780 | rond | 1 |
| Peu commun (20 à 50 %) | vert #23885A | hexagone | 2 |
| Rare (moins de 20 %) | violet #5B4FD0 | losange | 3 |
| Légendaire (jamais relevé dans le département) | or bruni #B07A12 | étoile | 4 |

Badge « Trophée » en plus quand la prise est plus grande que 90 % des prises connues de son espèce. La taille ne change jamais la rareté. Les cartes rares et légendaires ont un reflet holographique, et le poisson nage dans sa carte. Jamais de cadre jaune.

## Police
SF Pro Rounded, gras partout : grand titre (heavy), titre, sous-titre, corps, détail, légende ; chiffres en heavy à chasse fixe.

## Espacements et formes
Espacements 4 · 8 · 12 · 16 · 24 · 32 pt, marge d'écran 16 pt. Arrondis 10 · 16 · 22 pt. Zone tactile 44 pt, bouton principal 54 pt de haut. Carte à collectionner : rapport 69/100.

## Dossiers
- [`tokens/`](tokens) : `Style.swift` (les jetons tels qu'ils sont dans l'app) et `fishme-ds.css` (les mêmes pour les maquettes).
- [`composants/`](composants) : la planche du design système et `kit.md`, les règles de dessin (boutons, feuilles, raretés, interdits).
- [`ecrans/`](ecrans) : les 48 écrans retenus, un PNG par page (390×844 pt, en @2x).
- [`cartes/`](cartes) : la carte à collectionner (anatomie du recto, verso avec la vraie photo, 4 paliers de rareté, nage, Trophée).
- [`widgets/`](widgets) : les 3 widgets d'accueil (Ma carte, Ma session, Mon aquarium) et le widget de l'écran verrouillé.
- [`logo/`](logo) : l'icône « La Lune » (SVG et PNG 1024).

## À ne jamais écrire
« Poké », « Pokémon » ou « Pokédex » (la collection s'appelle le Pescedex), « bon spot », « tu peux la garder ».

Sources : choix d'Adem page par page dans [`docs/design/choix.md`](../design/choix.md), maquettes HTML dans [`docs/design/maquettes/`](../design/maquettes).
