// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Niveau d'accès. L'achat réel (StoreKit) vit côté App ; le Core ne connaît que le résultat.
public enum Plan: String, Codable, Hashable, Sendable, CaseIterable {
    case free
    case pro
}

/// Limites du plan gratuit. Valeurs PARAMÉTRABLES : la grille Free/Pro n'est pas tranchée
/// (descriptif : 15 cartes ; plan 04 : 1 département et 30 prises). Aucune valeur n'est figée dans le code.
public struct EntitlementLimits: Codable, Hashable, Sendable {
    /// Plafond de cartes de prise pour Free. nil = illimité.
    public var freeCardLimit: Int?
    /// Les cartes « bredouille » comptent-elles dans le plafond ? Décision actuelle : non (illimitées).
    public var bredouilleCountsTowardLimit: Bool

    public init(freeCardLimit: Int? = 15, bredouilleCountsTowardLimit: Bool = false) {
        self.freeCardLimit = freeCardLimit
        self.bredouilleCountsTowardLimit = bredouilleCountsTowardLimit
    }

    public static let `default` = EntitlementLimits()
}

/// Droits courants de l'utilisateur.
public struct Entitlements: Codable, Hashable, Sendable {
    public var plan: Plan
    public var limits: EntitlementLimits

    public init(plan: Plan = .free, limits: EntitlementLimits = .default) {
        self.plan = plan
        self.limits = limits
    }

    public var isPro: Bool { plan == .pro }

    /// Nombre de cartes de ce type restant à créer avant le plafond ; nil = illimité.
    public func remainingCards(existingCards: [CatchCard]) -> Int? {
        guard plan == .free, let limit = limits.freeCardLimit else { return nil }
        let used = existingCards.filter { limits.bredouilleCountsTowardLimit || $0.kind != .bredouille }.count
        return max(limit - used, 0)
    }

    /// Une nouvelle carte de ce type peut-elle être ajoutée ?
    public func canAddCard(kind: CardKind, existingCards: [CatchCard]) -> Bool {
        if kind == .bredouille && !limits.bredouilleCountsTowardLimit { return true }
        guard let remaining = remainingCards(existingCards: existingCards) else { return true }
        return remaining > 0
    }
}

/// Interrupteurs de fonctionnalités (repli, démo, mode relecteur Apple).
public struct FeatureFlags: Codable, Hashable, Sendable {
    /// Moteur Foundation Models (iOS 27). Désactivable si le go/no-go identification est négatif.
    public var foundationModelsIdentification: Bool
    /// Moteur Core ML (seulement si le modèle est embarqué et validé).
    public var coreMLIdentification: Bool
    /// Bouton « Photo d'exemple » (obligatoire pour le relecteur d'Apple).
    public var samplePhotoEnabled: Bool
    /// Écran debug caché (journal des replis d'identification).
    public var debugScreenEnabled: Bool
    /// Effet holographique piloté par Core Motion.
    public var holoEffectEnabled: Bool

    public init(
        foundationModelsIdentification: Bool = true,
        coreMLIdentification: Bool = false,
        samplePhotoEnabled: Bool = true,
        debugScreenEnabled: Bool = false,
        holoEffectEnabled: Bool = true
    ) {
        self.foundationModelsIdentification = foundationModelsIdentification
        self.coreMLIdentification = coreMLIdentification
        self.samplePhotoEnabled = samplePhotoEnabled
        self.debugScreenEnabled = debugScreenEnabled
        self.holoEffectEnabled = holoEffectEnabled
    }

    public static let `default` = FeatureFlags()
}
