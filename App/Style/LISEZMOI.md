# Style de FishMe (lot D0)

Un seul fichier, `Style.swift`, sans logique : couleurs, polices, espacements, rayons, deux boutons.
Base « Natif » (façon Plans d'Apple), SF Pro Rounded en gras partout, palette « Marine ».

## La palette Marine
| Rôle | Jeton | Clair | Sombre |
|---|---|---|---|
| Couleur de marque (boutons, onglet, spot) | `Palette.marine` | #0D4A85 | #7FB8EE |
| Texte principal, chiffres | `Palette.encre` | #0E1A26 | #E7EDF3 |
| Alertes seulement (orage, crue, fermé) | `Palette.bouchon` = `Palette.alerte` | #E8571C | #FF7A45 |
| Fond des pages | `Palette.fond` | #F2F5F9 | #0D1218 |
| Cartes, tuiles, feuilles | `Palette.surface` | #FFFFFF | #151C24 |
| Ouvert aujourd'hui | `Palette.ouvert` | #13643B | #6FE0A4 |

Raretés (la couleur aide ; le niveau se lit aussi en noir et blanc par la forme du badge, les 1 à 4 points et le mot) :
| Niveau | Jeton | Clair | Forme |
|---|---|---|---|
| Commun | `Palette.commun` | #6B7780 ardoise | rond, 1 point |
| Peu commun | `Palette.peuCommun` | #23885A vert | hexagone, 2 points |
| Rare | `Palette.rare` | #5B4FD0 violet | losange, 3 points |
| Légendaire | `Palette.legendaire` | #B07A12 or bruni | étoile, 4 points |

Le rare passe du bleu au violet pour ne pas se confondre avec la marine. L'or du légendaire sert au badge, jamais à un cadre de carte (aucun cadre jaune).

## Utiliser le style
- Une fois sur la racine (A, dans `RootView.swift`) : `.styleFishMe()` (police arrondie grasse, teinte marine, aucune barre de défilement).
- Couleurs : `Palette.marine`, polices : `Police.titre`, espaces : `Espace.l`, coins : `Rayon.m`, tailles : `Gabarit.zoneTactile`.
- Boutons : `.buttonStyle(.principal)` et `.buttonStyle(.secondaire)`.
- Coins toujours en `RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)`.

## Remplacer les jetons provisoires de chaque lot
Chaque lot garde son fichier provisoire et le vide en renvoyant vers `Style.swift` (le reste du code ne change pas), puis le supprime quand il veut.

| Lot | Fichier provisoire | Ancien → nouveau |
|---|---|---|
| L2 Carte | `App/Carte/StyleCarte.swift` | `CouleursCarte.accent` → `Palette.marine` ; `encreDouce` → `Palette.encreDouce` ; `filet` → `Palette.filet` ; `alerte`, `attention` → `Palette.alerte` ; `rarete(.commun…)` → `Palette.commun`, `.peuCommun`, `.rare`, `.legendaire` (`.nonMesuree` → `Palette.encreDouce`) ; `PolicesCarte.titre()` → `Police.titre`, `corps()` → `Police.corps`, `detail()` → `Police.detail`, `legende()` → `Police.legende` |
| L3 Prise | `App/Prise/PriseJetons.swift` | `encre` → `Palette.encre` ; `accent`, `mise` → `Palette.marine` ; `papier` → `Palette.surface` ; `fond` → `Palette.fond` ; `discret` → `Palette.encreDouce` ; `rayon` → `Rayon.l` ; `cibleMin` → `Gabarit.zoneTactile` ; `titre()` → `Police.titre` ; `corps()` → `Police.corps` ; `legende()` → `Police.legende` ; `chiffre()` → `Police.chiffre` ; `PriseBoutonPrincipal` → `BoutonPrincipal` ; `PriseBoutonSecondaire` → `BoutonSecondaire` |
| L4 Collection, L8 Amis | `App/Collection/Jetons.swift` | `Jeton.encre` → `Palette.encre` ; `encreDouce`, `ardoise` → `Palette.encreDouce` ; `papier` → `Palette.surface` ; `fondPage` → `Palette.fond` ; `vert` → `Palette.peuCommun` ; `bleu` → `Palette.rare` ; `bordeaux` → `Palette.legendaire` ; `police(t, g)` → `Police.taille(t, g)` ; `zoneTactile` → `Gabarit.zoneTactile` ; `rapportCarte` (5/7) → `Gabarit.rapportCarte` (69/100, décidé le 15 oct. 11h53) |
| L4 Collection | `App/Collection/StyleRarete.swift` | `couleur` : commun → `Palette.commun`, peu commun → `Palette.peuCommun`, rare → `Palette.rare`, légendaire → `Palette.legendaire`. Les formes, points et filets restent dans L4. |
| L5 Session | `App/Session/JetonsSession.swift` | `marine` → `Palette.encre` (texte) ou `Palette.marine` (bouton) ; `vert` → `Palette.marine` ; `papier` → `Palette.surface` ; `alerte` → `Palette.alerte` ; `police(s)` → `Police.titre` ou `Police.corps` |
| L6 Paywall | `App/Abonnement/JetonsAbonnement.swift` | `marine` → `Palette.encre` ; `vert` → `Palette.marine` ; `papier` → `Palette.surface` ; `police(s)` → `Police.titre` ; `texte(s)` → `Police.corps` |
| L12 Conditions | `App/Conditions/JetonsConditions.swift` | `encre` → `Palette.encre` ; `encre2` → `Palette.encreDouce` ; `filet` → `Palette.filet` ; `accent` → `Palette.marine` ; `haut`, `crue` → `Palette.alerte` ; `police(s)` → `Police.corps` (ou `Police.chiffreMoyen` pour un chiffre) |
| L13 Premier lancement | `App/Conseils/JetonsConseils.swift` | `accent` → `Palette.marine` ; `marne` → `Palette.nuit` ; `alerte` → `Palette.alerte` ; `tailleToucher` → `Gabarit.zoneTactile` ; `police(s)` → `Police.corps` |

Le vert « berge » (#1E7F4F, #157A4E) des jetons provisoires disparaît : la marque est bleue. Le vert ne reste que pour « ouvert aujourd'hui » (`Palette.ouvert`) et la rareté peu commun.

## Retoucher la palette
Quand le logo arrive, on change les valeurs hexadécimales de `Palette` dans `Style.swift`, et rien d'autre. Les noms ne bougent pas.
