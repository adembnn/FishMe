---
name: liquid-glass-swiftui
description: Règles Liquid Glass (iOS 26) et accessibilité pour écrire du SwiftUI Bredouille — où mettre du verre, où jamais. Se déclenche dès qu'une vue SwiftUI, une barre, un bouton flottant, une feuille ou la carte à collectionner est écrite ou relue.
---

# Liquid Glass dans Bredouille (source : `peche/08`)

Les signatures d'API viennent de la mémoire du rapport, **toutes à marquer ⚠** tant que non compilées sur Mac.

## Règle de fond [F]
Le verre est la **couche de contrôle** qui flotte au-dessus du contenu : barre d'onglets, barres d'outils, boutons flottants (obturateur, « Ajouter une prise »), feuilles. **La carte à collectionner, les photos, les lignes de liste ne sont jamais en verre.** Pas de verre sur verre.

## À faire
- Laisser le système faire : `TabView`, `NavigationStack`, `.toolbar`, `.sheet` avec `presentationDetents` prennent le verre gratuitement avec le SDK 26. Ne pas redessiner de barre d'onglets.
- `glassEffect` seulement sur de petits contrôles flottants, **après** `.frame`/`.padding` ; groupe de contrôles voisins dans un `GlassEffectContainer` (un par zone de contrôle, jamais un par cellule).
- Une seule action principale teintée par écran (`.tint`, `.glassProminent` : au plus 1).
- `.interactive()` seulement sur ce qui est tappable. `Glass.clear` jamais pour porter du texte.
- Supprimer les `toolbarBackground`, `presentationBackground`, `UIVisualEffectView` hérités.
- Texte >= `.body`, graisse `.medium` ou plus sur verre. Cibles >= 44 pt, >= 56-64 pt pour les actions de terrain.
- Lire `accessibilityReduceTransparency`, `colorSchemeContrast`, `accessibilityReduceMotion`, `accessibilityDifferentiateWithoutColor` pour les composants perso.
- Couleurs depuis l'Asset Catalog / couleurs système ; styles de texte dynamiques ; pas d'emoji.

## Mauvais / bon
```swift
// MAUVAIS : verre sur le contenu, matériau maison, glassEffect avant le layout
CardView(catch: c).background(.ultraThinMaterial).glassEffect().padding()

// BON (⚠ API non compilée) : carte opaque ; verre uniquement sur le bouton flottant
CardView(catch: c)
Button { shoot() } label: { Image(systemName: "camera.fill").font(.title2) }
    .frame(width: 72, height: 72)
    .glassEffect(.regular.interactive(), in: .circle)   // ⚠ glassEffect, Glass
```

## Écrans de terrain (capture, propositions, révélation, sortie en cours)
Pas de texte sur verre translucide ; contraste >= 7:1 sur les actions primaires [I, cible de design] ; actions dans le tiers bas ; mode clair par défaut le jour.

## Rappel
Cible iOS 26 sans API iOS 27 (le code Foundation Models image est sous `#if IOS27_SDK` ⚠). Un `#Preview` ne prouve pas le rendu du verre : seul l'iPhone d'Adem le prouve.
