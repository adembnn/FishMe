import Foundation
import Observation
import StoreKit

/// Charge les produits montrés et prépare les deux phrases qui dépendent de StoreKit : le prix qui suit le prix de lancement,
/// et l'essai du mensuel (seulement si le compte y a droit). Rien n'est écrit en dur : tout est lu dans `Product`.
@MainActor @Observable
final class ModeleOffres {
    enum Etat: Equatable { case chargement, pret, indisponible }

    private(set) var etat: Etat = .chargement
    private(set) var phraseLancement: String?
    private(set) var phraseEssai: String?

    @ObservationIgnored let produits: ProduitsMontres

    init(produits: ProduitsMontres) { self.produits = produits }

    func charger() async {
        etat = .chargement
        var demandes = produits.identifiants
        // Le produit à 49,99 n'est joint qu'en décembre : s'il manque, on n'affiche pas « Ensuite X ».
        demandes.append(IdentifiantsProduits.annuelApres)
        let trouves: [Product]
        do { trouves = try await Product.products(for: demandes) } catch { trouves = [] }

        guard trouves.contains(where: { $0.id == produits.annuel }) else {
            etat = .indisponible
            return
        }

        if produits.tarifFondateur {
            let prixApres = trouves.first(where: { $0.id == IdentifiantsProduits.annuelApres })?.displayPrice
            phraseLancement = TextesPaywall.phraseLancement(prixApres: prixApres)
        } else {
            phraseLancement = nil
        }

        phraseEssai = nil
        if let idMensuel = produits.mensuel, let mensuel = trouves.first(where: { $0.id == idMensuel }),
           let abonnement = mensuel.subscription, let offre = abonnement.introductoryOffer, offre.paymentMode == .freeTrial {
            let eligible = await abonnement.isEligibleForIntroOffer
            phraseEssai = TextesPaywall.essaiMensuel(valeur: offre.period.value, unite: Self.unite(offre.period.unit),
                                                     prixParMois: mensuel.displayPrice, eligible: eligible)
        }
        etat = .pret
    }

    private static func unite(_ unite: Product.SubscriptionPeriod.Unit) -> UniteDuree {
        switch unite {
        case .day: return .jour
        case .week: return .semaine
        case .month: return .mois
        case .year: return .an
        @unknown default: return .jour
        }
    }
}
