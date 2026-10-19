import Foundation

/// Les skins de l'aquarium. Sept au départ : trois décors gagnés en pêchant, quatre thèmes de saison (Pro).
public enum CatalogueSkins {
    /// Plafond proposé pour les images d'un skin (fond grand 400 Ko, moyen 150, petit 60, objets 100) et pour l'ensemble.
    public static let plafondOctetsParSkin = 710_000
    public static let plafondOctetsTotal = 4_000_000

    public static let tous: [Skin] = [
        Skin(id: .riviere, nom: "Rivière", origine: .gagne(.especesDifferentes(0)), ordre: 0, poidsApproxOctets: 0),
        Skin(id: .etang, nom: "Étang", origine: .gagne(.especesDifferentes(5)), ordre: 1, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 0.35, vert: 0.6, bleu: 0.4, opacite: 0.12),
             objets: ["objet-etang-nenuphar"]),
        Skin(id: .grotte, nom: "Grotte", origine: .gagne(.unLegendaire), ordre: 2, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 0.1, vert: 0.15, bleu: 0.35, opacite: 0.25)),
        Skin(id: .halloween, nom: "Halloween",
             origine: .saison(.halloween, FenetreAnnuelle(moisDebut: 10, jourDebut: 15, moisFin: 11, jourFin: 4)),
             ordre: 10, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 0.9, vert: 0.45, bleu: 0.1, opacite: 0.14),
             objets: ["objet-halloween-citrouille"]),
        Skin(id: .noel, nom: "Noël",
             origine: .saison(.noel, FenetreAnnuelle(moisDebut: 12, jourDebut: 1, moisFin: 1, jourFin: 6)),
             ordre: 11, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 0.8, vert: 0.9, bleu: 1.0, opacite: 0.12),
             objets: ["objet-noel-guirlande"]),
        Skin(id: .ouvertureTruite, nom: "Ouverture",
             origine: .saison(.ouvertureTruite, FenetreAnnuelle(moisDebut: 3, jourDebut: 1, moisFin: 4, jourFin: 30)),
             ordre: 12, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 0.6, vert: 0.85, bleu: 0.5, opacite: 0.1)),
        Skin(id: .ete, nom: "Été",
             origine: .saison(.ete, FenetreAnnuelle(moisDebut: 6, jourDebut: 21, moisFin: 8, jourFin: 31)),
             ordre: 13, poidsApproxOctets: 600_000,
             teinte: TeinteEclairage(rouge: 1.0, vert: 0.85, bleu: 0.4, opacite: 0.1)),
    ]

    public static func skin(_ id: IdentifiantSkin) -> Skin? {
        tous.first { $0.id == id }
    }
}
