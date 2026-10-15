import Core
import Foundation

/// Ce que l'aquarium lit d'une carte du Pescedex : l'espèce, sa rareté, la taille, la date, gardée ou relâchée.
/// Volontairement sans lieu, même flou : aucun champ de ce type ne porte d'eau, de département ni de coordonnée
/// (un test le vérifie sur les champs du type).
nonisolated struct EntreeAquarium: Sendable, Equatable, Identifiable {
    let id: UUID
    let especeId: String
    let nom: String
    /// Nom de l'illustration de profil dans les ressources (celle de la carte).
    let image: String
    /// Niveau lu dans Core (`rarete`), jamais calculé ici.
    let rarete: NiveauRarete
    let longueurCm: Double?
    let relachee: Bool
    let date: Date

    var estRare: Bool { rarete == .rare }
    var estLegendaire: Bool { rarete == .legendaire }

    /// « Brochet, rare, 62 cm, relâché » : un seul texte pour VoiceOver.
    var texteVoixOff: String {
        var morceaux = [nom]
        switch rarete {
        case .commun: morceaux.append("commun")
        case .peuCommun: morceaux.append("peu commun")
        case .rare: morceaux.append("rare")
        case .legendaire: morceaux.append("légendaire")
        case .nonMesuree: break
        }
        if let longueurCm { morceaux.append("\(Int(longueurCm.rounded())) cm") }
        if relachee { morceaux.append("relâché") }
        return morceaux.joined(separator: ", ")
    }
}

/// Qui nage : les vraies prises seulement. Une carte d'exemple et une carte déclarée (swipe du premier lancement,
/// sans photo) ne nagent pas ; une carte bredouille n'est pas une `Prise`, donc n'arrive jamais ici.
nonisolated enum SelectionAquarium {
    static func nage(_ prise: Prise) -> Bool {
        prise.origine == .priseReelle && !prise.exemple
    }

    /// Construit les entrées. `rareteDe` rend la rareté de Core pour une prise (A la branche sur `ServiceEspeces.rarete`
    /// avec le département de la carte, comme le fait L4) ; le lieu de la prise ne sort jamais de cette fonction.
    static func entrees(depuis prises: [Prise], especes: [EspecePechable],
                        rareteDe: (Prise) -> NiveauRarete) -> [EntreeAquarium] {
        let parId = Dictionary(especes.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        return prises.filter(nage).map { prise in
            let fiche = parId[prise.espece.id]
            return EntreeAquarium(id: prise.id, especeId: prise.espece.id,
                                  nom: fiche?.nom ?? prise.espece.id,
                                  image: fiche?.image ?? prise.espece.id,
                                  rarete: rareteDe(prise), longueurCm: prise.longueurCm,
                                  relachee: !prise.gardee, date: prise.date)
        }
    }

    /// Version qui lit la rareté dans `ServiceEspeces`. `departementDe` donne le département de la carte (A le tire du
    /// même endroit que L4) ; sans département, la rareté n'est pas mesurée et le poisson reste sans effet.
    static func entrees(depuis prises: [Prise], services: any ServiceEspeces,
                        departementDe: (Prise) -> Departement?) -> [EntreeAquarium] {
        entrees(depuis: prises, especes: services.especesPechables()) { prise in
            guard let departement = departementDe(prise) else { return .nonMesuree }
            return services.rarete(espece: prise.espece, departement: departement).niveau
        }
    }
}
