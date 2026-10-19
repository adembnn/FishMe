import Core
import Foundation

/// D'où vient le lieu proposé au pêcheur au moment de publier. Aucune coordonnée.
nonisolated struct ContexteLieu: Sendable, Equatable {
    var eauNom: String?
    /// Vrai pour un lac, un étang, un plan d'eau, et aussi quand on ne sait pas (le nom d'un lac vaut un coin exact).
    var planDEau: Bool
    /// Code du département (« 94 »), `nil` s'il est inconnu.
    var departement: String?

    init(eauNom: String?, planDEau: Bool, departement: String?) {
        self.eauNom = eauNom
        self.planDEau = planDEau
        self.departement = departement
    }

    /// Depuis le `Lieu` de Core : seule une rivière permet le choix « cours d'eau ».
    init(lieu: Lieu) {
        self.init(eauNom: lieu.eau?.nom, planDEau: lieu.eau?.type != .riviere,
                  departement: lieu.departement.estInconnu ? nil : lieu.departement.code)
    }

    /// Depuis le `lieuFlou` d'une carte (« La Marne · 94 » ou « Département 94 »). `typeEau` inconnu : on suppose un plan d'eau.
    init(lieuFlou: String?, typeEau: TypeEau?) {
        let texte = lieuFlou ?? ""
        if let separateur = texte.range(of: " · ") {
            let nom = String(texte[..<separateur.lowerBound])
            let code = String(texte[separateur.upperBound...])
            self.init(eauNom: nom.isEmpty ? nil : nom, planDEau: typeEau != .riviere, departement: code.isEmpty ? nil : code)
        } else if texte.hasPrefix("Département ") {
            self.init(eauNom: nil, planDEau: true, departement: String(texte.dropFirst("Département ".count)))
        } else {
            self.init(eauNom: nil, planDEau: true, departement: nil)
        }
    }

    static let inconnu = ContexteLieu(eauNom: nil, planDEau: true, departement: nil)
}

/// Le lieu qui part avec la publication : trois champs, rien d'autre. Seul `LieuPublication.choisir` en fabrique.
nonisolated struct LieuChoisi: Sendable, Equatable {
    let mode: ModeLieu
    let lieuTexte: String
    let departement: String
}

nonisolated enum LieuPublication {
    /// Les choix offerts, dans l'ordre. Plan d'eau, eau inconnue ou département inconnu : « cours d'eau » n'existe pas.
    static func options(_ contexte: ContexteLieu) -> [ModeLieu] {
        var choix: [ModeLieu] = []
        if let nom = contexte.eauNom, !nom.isEmpty, !contexte.planDEau, departementValide(contexte) { choix.append(.coursEau) }
        if departementValide(contexte) { choix.append(.departement) }
        choix.append(.aucun)
        return choix
    }

    /// Décision de Titouan (19 oct.) : « département seul » par défaut. « Cours d'eau + département » reste possible, jamais par défaut.
    /// Département inconnu : « aucun lieu ».
    static func parDefaut(_ contexte: ContexteLieu) -> ModeLieu {
        let choix = options(contexte)
        return choix.contains(.departement) ? .departement : (choix.first ?? .aucun)
    }

    /// Ce que le pêcheur lit sur le bouton : « La Marne · 94 », « 94 », « Aucun lieu ».
    static func etiquette(_ mode: ModeLieu, _ contexte: ContexteLieu) -> String {
        switch mode {
        case .coursEau: "\(contexte.eauNom ?? "") · \(contexte.departement ?? "")"
        case .departement: contexte.departement ?? ""
        case .aucun: "Aucun lieu"
        }
    }

    /// Ce que les autres verront, au mot près.
    static func apercu(_ mode: ModeLieu, _ contexte: ContexteLieu) -> String {
        switch mode {
        case .coursEau: etiquette(.coursEau, contexte)
        case .departement: "Département \(contexte.departement ?? "")"
        case .aucun: "Aucun lieu ne sera montré."
        }
    }

    /// `nil` si ce choix n'est pas permis ici (plan d'eau nommé, par exemple).
    static func choisir(_ mode: ModeLieu, _ contexte: ContexteLieu) -> LieuChoisi? {
        guard options(contexte).contains(mode) else { return nil }
        let code = contexte.departement ?? ""
        switch mode {
        case .coursEau: return LieuChoisi(mode: mode, lieuTexte: etiquette(.coursEau, contexte), departement: code)
        case .departement: return LieuChoisi(mode: mode, lieuTexte: "", departement: code)
        // R2: « aucun lieu » ne publie aucun département : la publication n'entre pas dans « Dans ta région » (décision de Titouan).
        case .aucun: return LieuChoisi(mode: mode, lieuTexte: "", departement: "")
        }
    }

    private static func departementValide(_ contexte: ContexteLieu) -> Bool {
        guard let code = contexte.departement else { return false }
        return !code.isEmpty && code != Departement.inconnu.code
    }
}
