---
name: ecrire-swift-sans-compiler
description: Conventions pour écrire du Swift/SwiftUI sans pouvoir le compiler (Titouan sous Windows) — fichiers autonomes, #Preview, API conservatrices, marquage ⚠, PecheCore sans import Apple. Se déclenche dès qu'un fichier .swift est créé ou modifié par quelqu'un qui n'a pas de Mac.
---

# Écrire du Swift sans compiler

Le dépôt est vérifié par la CI macOS et par Adem, pas par vous. Objectif : que votre fichier compile du premier coup sur le Mac, ou échoue avec une erreur évidente.

## Règles
1. **Un fichier = une vue ou un type, autonome, avec un `#Preview`** contenant ses données factices **en dur dans le fichier** (pas de dépendance à `AppEnvironment.live`, pas de réseau, pas de caméra).
2. **Dépendances par protocole** : une vue prend des types de `PecheCore` ou un protocole du contrat, jamais un service Apple concret. Titouan écrit contre `.demo` (mocks), Adem fournit `.live`.
3. **`PecheCore` : `import Foundation` uniquement.** Interdits : `SwiftUI`, `Combine`, `Observation`, `os`, `CoreLocation`, `FoundationModels`, `UIKit`. Types `Codable`, `Sendable`, `Hashable`. Tests purs XCTest, sans API Apple, exécutables sous Windows avec `swift test` si la toolchain est installée.
4. **API conservatrices** : SwiftUI stable (`VStack`, `List`, `NavigationStack`, `Button`, `Text`, `Image(systemName:)`, `.sheet`, `@State`, `@Binding`). Pas de nouveauté iOS 26/27 sans besoin ; si nécessaire, **marquer `// ⚠ à vérifier sur Mac : <symbole>`** et isoler dans une petite vue. Le verre : suivre `liquid-glass-swiftui`.
5. **Marquage ⚠** sur tout nom d'API ou nombre Apple non vérifié (signature, nom de modificateur, valeur de seuil, taille de point).
6. **Ne jamais modifier `project.pbxproj`, `*.xcodeproj`, `project.yml`, `Info.plist`, `.storekit`, workflows** : propriété d'Adem. Un nouveau fichier Swift dans un dossier du périmètre suffit (XcodeGen le prend au `generate`).
7. **Code simple et explicite** : types annotés quand l'inférence est douteuse, pas d'expressions SwiftUI imbriquées trop longues (le compilateur dit « too complex »), `private` par défaut, pas de macros ni de property wrappers exotiques, pas de concurrence stricte avancée (l'app utilise Swift 5 mode minimal ⚠).
8. **Aucun emoji, aucun texte de verdict** (voir `wording-interdits-bredouille`) ; textes dans des constantes ou un String Catalog, pas éparpillés.
9. **Accessibilité d'office** : `accessibilityLabel` sur les icônes, styles de texte dynamiques, cible >= 44 pt.
10. À la fin : relire le fichier comme le ferait le compilateur (imports, accolades, labels d'arguments, `let`/`var`), puis le rapport « Écrit, non compilé ; à compiler sur Mac : ce fichier, ces ⚠ ».

## Exemple
```swift
import SwiftUI
import PecheCore

struct RarityBadge: View {
    let label: String            // ex. "Présent sur 4 % des stations scientifiques de l'OFB du Loiret"
    var body: some View {
        Text(label)
            .font(.footnote.weight(.medium))
            .accessibilityLabel(label)
    }
}

#Preview {
    RarityBadge(label: "Présent sur 4 % des stations scientifiques de l'OFB du Loiret")
}
```
- Mauvais : `RarityBadge` qui lit `AppEnvironment.live.store`, et un `#Preview` qui appelle la caméra.
- Mauvais : `import CoreLocation` dans `PecheCore` ; `Date.now.formatted(.iso8601)` utilisé sans vérifier ⚠.
