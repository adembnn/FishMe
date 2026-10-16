# Retour et fermeture sur chaque écran (16 oct., cloud, non compilé)

Chaque branche ci-dessous part de `lot/design-systeme` (bea70da) et y ajoute un seul commit. Le Mac fusionne ces branches dans `mac/integration`, compile, puis vérifie les écrans listés dans le simulateur.

| Branche | Commit | Ce qui change |
|---|---|---|
| `lot/carte` | a4473c8 | Croix « Fermer » sur la fiche d'un coin (FicheCoinView) |
| `lot/ou-chercher` | 7a14522 | « Fermer » dans la barre d'Où chercher |
| `lot/collection` | fb83510 | Croix sur la fiche d'une espèce, la feuille « Tes conditions » et la révélation de carte (CroixFermer.swift) |
| `lot/amis` | 3389db7 | Croix dans l'en-tête d'Amis et sur la carte d'un ami en grand |
| `lot/prise` | d95a4cd | « Retour » à l'étape d'avant sur toutes les étapes de la prise, croix « Fermer » partout ; test `retourRevientALEtapeDAvant` |
| `lot/abonnement` | ed3b987 | Croix toujours visible sur le paywall (même bloquant), croix sur Réglages et sur la feuille de consentement (fermer = refuser) |
| `lot/premier-pas` | 1dcf91f | Tunnel : « Revenir à la carte d'avant » (sans doublon de carte déclarée) |
| `lot/squelette` | pas poussé | RootView : fermer une ancienne sortie ramène à « Mes sorties » ; « Fermer » sur la feuille Amis vide. Patch : `/mnt/project-files/build/navigation/racine-retour.patch` (en attente de l'accord d'Adem pour pousser sur lot/squelette) |

Ne pas fusionner `claude/navigation-retour-7s97rl` sauf ce fichier : son commit `.fermable()` dans Style n'est utilisé par personne.

## 2e passe : boutons au design système (Adem, 16 oct. 7h27)

Toutes les croix et tous les retours passent par `BoutonRond` (App/Style/Style.swift) : rond 44 pt, en verre avec icône encre pour les écrans en direction A ou C, icône marine sans fond pour la direction B (docs/design/choix.md, kit.md `.rond verre`). Placement du kit : en haut à gauche, à 16 pt ; la fiche d'un coin (P07) en haut à droite ; Retour à gauche et Fermer à droite quand il y a les deux.

À fusionner par-dessus `mac/integration`, **`lot/style` en premier** (les autres en dépendent) :

| Branche | Commit |
|---|---|
| `lot/style` | 9f17c243 (BoutonRond) |
| `lot/carte` | 8b7df83c |
| `lot/ou-chercher` | 443b912d |
| `lot/session` | 3b00fe93 |
| `lot/prise` | 62b2630a |
| `lot/collection` | 581ca1ce |
| `lot/amis` | 2a99e8ec |
| `lot/abonnement` | 2226a80c |
| `lot/premier-pas` | 9509d49a |

Restes connus : la croix d'Amis et celle de « Carte à essayer » sont dans leur en-tête, à droite (pas déplacées) ; `PriseBoutonRond` n'est plus utilisé.

## À vérifier dans le simulateur
- Chaque croix et chaque retour : rond de verre (ou icône marine seule sur Réglages, consentement, fiche d'espèce, règles, filtre, Où chercher, résultat de la prise), 44 pt, rien qui se chevauche.
- Fiche d'un coin : croix visible en medium et large, ne couvre ni le nom de l'eau ni la pastille.
- Où chercher : « Fermer » à chaque étape (grille, chargement, résultats).
- Pescedex : fiche d'espèce et « Tes conditions » se ferment par la croix ; la croix ne masque pas le titre.
- Révélation : la croix range la carte comme « Ranger dans le Pescedex », sans gêner le toucher qui retourne la carte.
- Amis : croix de l'en-tête et de la carte d'un ami.
- Prise : « Retour » (haut gauche) et « Fermer » (haut droite) ne chevauchent rien, y compris grille et stade. Taille → Retour revient à Sosies ou Stade si on y est passé. Résultat → Retour revient à Détails.
- Paywall : croix sans chevauchement avec « FishMe Pro », ferme aussi au 2e spot sans débloquer.
- Réglages : croix alignée avec le titre, ferme la feuille.
- Consentement : la croix éteint la mesure.
- Tunnel : retour à la carte d'avant, puis re-glisser à droite ne double pas la carte au Pescedex.

## Reste ouvert
- Écran « Ta zone » (SansPositionView) : « Choisir ma zone » montre la carte au lieu d'ouvrir le choix de zone (RootView, à brancher).
