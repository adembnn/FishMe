# Contrat central de PecheCore

NON COMPILÉ : écrit sans compilateur Swift (Windows). Source de vérité : `PecheCore/Sources/PecheCore/Contracts/`.
Ce fichier est le « bus » du projet : types et protocoles décidés une fois, que chaque module implémente ou consomme sans appeler les autres directement.

## Règle d'or : jamais de changement silencieux du contrat

Toute modification d'un fichier de `Contracts/` (ajout, renommage, suppression, changement de sémantique) :
1. est écrite dans ce fichier (section « Journal des versions ») dans le même commit ;
2. est annoncée aux propriétaires des implémentations (tableau plus bas) ;
3. incrémente `CollectionSnapshot.currentSchemaVersion` si elle touche ce qui est écrit dans `collection.json`.

Un module qui a besoin d'un type manquant peut l'ajouter, à condition de le documenter ici. `PecheCore` n'importe que Foundation.

## Types (données)

| Type | Fichier | Rôle |
|---|---|---|
| `Species`, `ProtectionStatus`, `IdentificationTrait`, `TraitAnswer` | Species.swift | Catalogue d'espèces, critères du manuel assisté |
| `Department`, `DepartmentProfile`, `SpeciesPresence` | Department.swift | Présence par département (relevés OFB) |
| `RarityTier`, `RarityInfo` | Rarity.swift | 5 classes + libellé exact imposé |
| `CatchCard`, `CardKind`, `PhotoRef`, `FuzzyPlace` | CatchCard.swift | La carte (prise, bredouille, observation) |
| `Trip`, `TripOutcome` | Trip.swift | Sortie de pêche |
| `Achievement` | Achievement.swift | Succès |
| `CollectionSnapshot` | CollectionSnapshot.swift | Tout `collection.json`, avec `schemaVersion` |
| `IdentificationSource`, `IdentificationConfidence`, `IdentificationRequest`, `IdentificationCandidate`, `IdentificationResult`, `IdentificationFailure`, `IdentificationError`, `IdentifierChain` | Identification.swift | Identification et repli |
| `Plan`, `EntitlementLimits`, `Entitlements`, `FeatureFlags` | Entitlements.swift | Free/Pro, plafond configurable, interrupteurs |
| `LocalRulesInfo` | LocalRulesInfo.swift | Lien fédération + avertissement fixe |

Principes : tout est `Codable`/`Hashable`/`Sendable` ; la confiance d'identification est qualitative (`probable`/`possible`), le `score` est interne et jamais affiché ; `LocalRulesInfo` ne porte aucun verdict.

## Protocoles

| Protocole | Méthodes | Fichier |
|---|---|---|
| `SpeciesIdentifier` | `source`, `isAvailable()`, `identify(_:)` -> `IdentificationResult` (0 à 3, jamais hors `candidates`) | Identification.swift |
| `CollectionStore` | `load()`, `save(_:)` | Stores.swift |
| `RarityProvider` | `rarity(of:in:)` -> `RarityInfo?` | Stores.swift |
| `DepartmentResolver` | `departmentCode(latitude:longitude:)` | Stores.swift |
| `SpeciesCatalog` | `allSpecies`, `species(id:)`, `allDepartments`, `profile(departmentCode:)`, `candidates(in:)` | Stores.swift |
| `ClockProviding` | `now()` (+ `SystemClock` fourni) | Stores.swift |

Ordre de repli (`IdentifierChain.defaultOrder`) : `foundationModels` -> `coreML` -> `manual` -> `priorOnly`. Le premier moteur disponible qui renvoie au moins une proposition gagne ; les moteurs écartés sont listés dans `IdentificationResult.fallbacks` (écran debug).

## Versions

- Contrat : `1` (13 octobre 2026). Données utilisateur : `CollectionSnapshot.currentSchemaVersion = 1`.

### Journal des versions
- 1 : contrat initial.

## Comment ajouter un champ

1. Ajouter la propriété avec une **valeur par défaut** dans l'`init` et le type **optionnel** (`var x: T?`) : les anciens JSON restent décodables.
2. Ne jamais renommer ni changer le type d'un champ existant : en ajouter un nouveau et déprécier l'ancien.
3. Ajouter un test d'encodage/décodage dans `Tests/PecheCoreTests`.
4. Mettre à jour ce fichier (journal) ; si le champ est dans `collection.json` et non optionnel, incrémenter `schemaVersion` et décrire la migration.
5. Prévenir les propriétaires du tableau ci-dessous.

## Qui implémente quoi

| Contrat | Implémenté par | Mock (PecheCore) |
|---|---|---|
| `SpeciesIdentifier` : Foundation Models, Core ML | PecheApple (Adem) | `MockIdentifier` |
| `SpeciesIdentifier` : manuel assisté, priorOnly | PecheCore (Titouan) | `MockIdentifier` |
| `IdentifierChain` | PecheCore (fourni dans le contrat) | -- |
| `CollectionStore` (JSON atomique) | PecheCore ou App (à confirmer, voir doute) | `InMemoryCollectionStore` |
| `RarityProvider` | PecheCore (Titouan) | à écrire par le lot rareté |
| `DepartmentResolver` (polygones embarqués) | PecheCore (Titouan) | à écrire |
| `SpeciesCatalog` (Bundle.module) | PecheCore (Titouan) | à écrire |
| `ClockProviding` | `SystemClock` (contrat) | `FixedClock` |
| `Entitlements` : valeur Free/Pro réelle | App (Adem, StoreKit) | valeurs par défaut |
| `FeatureFlags` | App (Adem) | `FeatureFlags.default` |
| `LocalRulesInfo` : construction | PecheCore ; ouverture du lien : App (Titouan, Legal) | -- |

## Doutes ouverts (à ne pas trancher en silence)

- Plafond Free : 15 cartes (descriptif) ou 1 département et 30 prises (plan 04) : `EntitlementLimits.freeCardLimit` est paramétrable ; défaut 15.
- Seuils de rareté : voir `CLAUDE.md` du dépôt.
- Noms de protocoles : le plan 04 §1.3 écrit `CollectionStoring`, `DepartmentResolving`, `RarityComputing` ; le contrat retient `CollectionStore`, `DepartmentResolver`, `RarityProvider`.
