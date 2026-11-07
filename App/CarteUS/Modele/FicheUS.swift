import Foundation
import Core

/// Tous les textes fixes de la carte américaine, au même endroit : le test les passe au crible des mots interdits.
/// Règle du produit : la carte situe des lieux listés par une agence, elle ne dit jamais où la pêche est permise.
nonisolated enum TextesCarteUS {
    static let sansDonneesDebut = "Pas encore de données pour cet État"
    static let choisirEtat = "Choisir mon État"
    static let yAller = "Y aller"
    static let donneeAbsente = "donnée absente"
    static let tropLoin = "Zoome sur la carte pour voir les plans d'eau et les accès publics."
    static let aucunLieu = "Aucun plan d'eau ni accès chargé dans cette zone."
    static let titreAvis = "Avis sur l'eau"
    static let titreSource = "Source de la donnée"
    static let mention = "Ce lieu est listé par l'agence ; la carte ne dit pas si la pêche y est ouverte. À vérifier sur le site de l'agence avant de pêcher."
    static let agenceInconnue = "Site de l'agence de l'État"

    static func lienAgence(_ agence: String) -> String { "Site de l'agence : " + agence }

    static func sansDonnees(nomEtat: String?) -> String {
        guard let nomEtat else { return sansDonneesDebut + ". Choisis ton État pour voir le site de son agence." }
        return sansDonneesDebut + " : " + nomEtat + "."
    }

    /// Tous les textes affichés, pour la recherche des mots interdits.
    static var tous: [String] {
        [sansDonneesDebut, choisirEtat, yAller, donneeAbsente, tropLoin, aucunLieu, titreAvis, titreSource, mention, agenceInconnue,
         lienAgence("X"), sansDonnees(nomEtat: nil), sansDonnees(nomEtat: "X")] + TypeAccesCarteUS.allCases.map { t in t.libelle }
    }
}

/// Un lien n'est gardé que s'il est en https avec un hôte : l'écran n'ouvre rien d'autre.
nonisolated func lienHttpsCarteUS(_ brut: String?) -> URL? {
    guard let brut, let url = URL(string: brut), url.scheme?.lowercased() == "https", url.host?.isEmpty == false else { return nil }
    return url
}

nonisolated struct AvisFicheUS: Sendable, Equatable {
    var texte: String
    var date: String
    var source: String
    var lien: URL?
}

/// Ce que montre la fiche d'un plan d'eau ou d'un accès : nom, État, source datée, lien de l'agence. Jamais un verdict de pêche.
nonisolated struct FicheUS: Sendable, Equatable, Identifiable {
    var id: String
    var titre: String
    var sousTitre: String
    var etat: String
    var nomEtat: String?
    var coordonnee: Coordonnee
    /// La source, ou "donnée absente" si le jeu n'en porte pas.
    var source: String
    var date: String
    var lienAgence: URL?
    var libelleLien: String
    var avis: [AvisFicheUS]
    var mention: String { TextesCarteUS.mention }

    private static func nonVide(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private static func lien(propre: String?, agence: InfoAgenceUS?) -> (URL?, String) {
        if let url = lienHttpsCarteUS(propre) {
            return (url, agence.map { a in TextesCarteUS.lienAgence(a.agence) } ?? TextesCarteUS.agenceInconnue)
        }
        if let a = agence, let url = a.url { return (url, TextesCarteUS.lienAgence(a.agence)) }
        return (nil, TextesCarteUS.agenceInconnue)
    }

    static func pour(point: PointAccesCarteUS, agences: any AgencesCarteUS) -> FicheUS {
        let agence = agences.agence(code: point.etat)
        let (url, libelle) = lien(propre: nil, agence: agence)
        let nomEtat = agence?.nomEtat
        return FicheUS(id: "p-" + point.id, titre: point.nom, sousTitre: point.type.libelle + " · " + (nomEtat ?? point.etat),
                       etat: point.etat, nomEtat: nomEtat, coordonnee: point.coordonnee,
                       source: nonVide(point.source) ?? TextesCarteUS.donneeAbsente,
                       date: nonVide(point.date) ?? TextesCarteUS.donneeAbsente,
                       lienAgence: url, libelleLien: libelle, avis: [])
    }

    static func pour(plan: PlanEauCarteUS, avis: [AvisSanteCarteUS], agences: any AgencesCarteUS) -> FicheUS {
        let agence = agences.agence(code: plan.etat)
        let (url, libelle) = lien(propre: plan.lienAgence, agence: agence)
        let nomEtat = agence?.nomEtat
        let ses = avis.filter { a in a.planEauId == nil || a.planEauId == plan.id }.map { a in
            AvisFicheUS(texte: a.texte, date: a.date, source: nonVide(a.source) ?? TextesCarteUS.donneeAbsente, lien: lienHttpsCarteUS(a.lien))
        }
        return FicheUS(id: "e-" + plan.id, titre: plan.nom, sousTitre: "Plan d'eau · " + (nomEtat ?? plan.etat),
                       etat: plan.etat, nomEtat: nomEtat, coordonnee: plan.coordonnee,
                       source: nonVide(plan.source) ?? TextesCarteUS.donneeAbsente,
                       date: nonVide(plan.date) ?? TextesCarteUS.donneeAbsente,
                       lienAgence: url, libelleLien: libelle, avis: ses)
    }

    /// Tous les textes de la fiche, pour la recherche des mots interdits.
    var textes: [String] {
        [titre, sousTitre, source, date, libelleLien, mention] + avis.flatMap { a in [a.texte, a.date, a.source] }
    }
}

/// Le message quand aucune donnée n'est chargée pour l'État de la zone : honnête, avec le lien de l'agence (niveau 1).
nonisolated struct MessageSansDonneesUS: Sendable, Equatable {
    var texte: String
    var lien: URL?
    var libelleLien: String
    /// Vrai si l'État n'est pas connu : la carte propose alors de le choisir.
    var proposerChoixEtat: Bool

    static func pour(etat: String?, agences: any AgencesCarteUS) -> MessageSansDonneesUS {
        guard let etat, let agence = agences.agence(code: etat) else {
            return MessageSansDonneesUS(texte: TextesCarteUS.sansDonnees(nomEtat: nil), lien: nil,
                                        libelleLien: TextesCarteUS.agenceInconnue, proposerChoixEtat: true)
        }
        return MessageSansDonneesUS(texte: TextesCarteUS.sansDonnees(nomEtat: agence.nomEtat), lien: agence.url,
                                    libelleLien: TextesCarteUS.lienAgence(agence.agence), proposerChoixEtat: false)
    }
}

/// Quelle carte montrer : la carte de France (inchangée) ou celle des États-Unis. Sans région connue (aperçus, tests), la France.
nonisolated enum ModeCarte: Equatable {
    case france
    case etatsUnis

    static func pour(_ region: RegionApp?) -> ModeCarte {
        region == .etatsUnis ? .etatsUnis : .france
    }
}
