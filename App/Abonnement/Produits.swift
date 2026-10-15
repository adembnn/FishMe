import Foundation
import Core

/// Les identifiants du kit MWM (abonnements du groupe « Premium Plan », identifiant d'app `ai.mwm.build.challenge.team.01`).
/// Seuls des identifiants : nom, durée, prix et essai sont lus depuis StoreKit, jamais écrits ici.
nonisolated enum IdentifiantsProduits {
    private static let base = "ai.mwm.build.challenge.team.01"

    static let annuelFondateur = "\(base).yearly.00.ft.34.99"
    static let annuelApres = "\(base).yearly.00.ft.49.99"
    static let mensuel499 = "\(base).monthly.07.ft.04.99"
    static let mensuel699 = "\(base).monthly.07.ft.06.99"
    static let mensuel999 = "\(base).monthly.07.ft.09.99"

    /// Les produits qui donnent accès. Le 69,99 n'est ni montré ni joint, mais un éventuel abonné reste abonné.
    static let tousLesAbonnements: Set<String> = [
        annuelFondateur, annuelApres, mensuel499, mensuel699, mensuel999, "\(base).yearly.00.ft.69.99",
    ]
}

/// Le mensuel retenu n'est PAS ENCORE CHOISI (4,99 / 6,99 / 9,99, décision d'Adem). Une seule ligne à changer, ici.
/// Tant qu'il vaut `nil`, le paywall montre seulement l'annuel.
nonisolated enum ChoixOffres {
    static let mensuelRetenu: String? = nil
}

/// Les deux produits que le paywall liste, annuel en premier (présélectionné).
nonisolated struct ProduitsMontres: Sendable, Equatable {
    let annuel: String
    let mensuel: String?
    let tarifFondateur: Bool

    var identifiants: [String] { [annuel] + (mensuel.map { [$0] } ?? []) }

    /// `offre` vient de `offreAffichee(date:)` de Core : aucune date n'est recalculée ici. `offre.produit` est l'identifiant du produit annuel à montrer.
    init(offre: OffreAffichee, mensuel: String? = ChoixOffres.mensuelRetenu) {
        self.annuel = offre.produit
        self.mensuel = mensuel
        self.tarifFondateur = offre.tarifFondateur
    }
}
