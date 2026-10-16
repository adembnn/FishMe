# Mouvement : animations, sons et vibrations

## Contenu
- `Sons.swift` : `MomentSonore` (la liste des instants), `Sons` (lit les fichiers `.caf`) et `Vibrations` (Core Haptics).
- `Sons/` : un fichier `.caf` par instant, nommé comme la valeur texte de `MomentSonore`.
- Les autres fichiers de ce dossier sont les animations.

## Ajouter un son
1. Ajouter un cas dans `MomentSonore` (la valeur texte = le nom du fichier).
2. Poser `<nom>.caf` dans `Sons/` (le dossier est synchronisé avec Xcode, rien d'autre à faire).
3. Si besoin, donner un motif de vibration dans `Vibrations.motif(pour:)`.
4. Appeler `Sons.jouer(.nom)` et `Vibrations.jouer(.nom)` au bon instant.

## Licence
Tous les sons sont synthétisés par nous. Aucun audio de tiers, aucune bibliothèque de sons.
