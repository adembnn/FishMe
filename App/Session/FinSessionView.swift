import SwiftUI
import UIKit
import Core

/// Formats communs de la fin de session (P16) et de « Mes sorties » (P17).
enum FormatSortie {
    private static let francais = Locale(identifier: "fr_FR")

    /// « 1 h 24 », « 2 h », « 35 min ».
    static func duree(_ sortie: Sortie) -> String {
        guard let fin = sortie.fin else { return "" }
        let minutes = max(0, Int(fin.timeIntervalSince(sortie.debut) / 60))
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(m)"
    }

    /// « 12 oct. »
    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(francais))
    }

    /// Les prises de la sortie sans les cartes d'exemple.
    static func prises(_ sortie: Sortie) -> [Prise] { sortie.prises.filter { !$0.exemple } }
}

/// Fin de session : la page récap « La pêche du jour » (voir `RecapSortieView`). Les cartes que la sortie a créées en carrousel,
/// ou la carte « Eau calme » quand rien n'a mordu, et un seul bouton « Terminer ». Aucun chargement, aucune carte géographique.
///
/// À brancher par A : `FinSessionView(fin: moteur.derniereFin, infosEspece: …, lieu: …) { moteur.acquitterFin() ; … }`.
struct FinSessionView: View {
    let fin: FinDeSession
    /// Nom, image et latin d'une espèce (le catalogue de L1 vit hors du dossier Session).
    let infosEspece: (Espece) -> EspecePechable?
    /// « la Marne » : l'eau, jamais le point exact. `nil` : rien n'est écrit.
    let lieu: String?
    /// Conseil « La prochaine fois » (cas bredouille). `nil` : le bloc n'est pas montré.
    let conseil: String?
    let surTerminer: () -> Void
    /// La croix en haut à gauche. `nil` : pas de croix (elle ne termine jamais la session : seul « Terminer » le fait).
    let surFermer: (() -> Void)?
    /// Poids estimé d'après la formule longueur-poids de Core. Sert au poids affiché sur la carte.
    let poidsEstime: (Espece, Double) -> PoidsEstime?
    /// Photo de soi pour la carte « Eau calme » (sortie sans prise). `nil` : le bouton n'est pas montré.
    let surPhotoSortie: ((Data) -> Void)?
    /// Rareté d'une prise dans son département (Core). Par défaut `nil` : la carte s'affiche « rareté non mesurée », jamais inventée.
    let rarete: (Prise) -> ResultatRarete?
    /// Vrai quand l'espèce entre dans le Pescedex avec cette sortie. Par défaut : jamais annoncé.
    let estNouvelleEspece: (Espece) -> Bool

    init(fin: FinDeSession, infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, lieu: String? = nil,
         conseil: String? = nil, surTerminer: @escaping () -> Void, surFermer: (() -> Void)? = nil,
         poidsEstime: @escaping (Espece, Double) -> PoidsEstime? = { _, _ in nil },
         surPhotoSortie: ((Data) -> Void)? = nil,
         rarete: @escaping (Prise) -> ResultatRarete? = { _ in nil },
         estNouvelleEspece: @escaping (Espece) -> Bool = { _ in false }) {
        self.surPhotoSortie = surPhotoSortie
        self.poidsEstime = poidsEstime
        self.conseil = conseil
        self.fin = fin
        self.infosEspece = infosEspece
        self.lieu = lieu
        self.surTerminer = surTerminer
        self.surFermer = surFermer
        self.rarete = rarete
        self.estNouvelleEspece = estNouvelleEspece
    }

    var body: some View {
        RecapSortieView(fin: fin, infosEspece: infosEspece, lieu: lieu, conseil: conseil, surTerminer: surTerminer,
                        surFermer: surFermer, poidsEstime: poidsEstime, surPhotoSortie: surPhotoSortie, rarete: rarete,
                        estNouvelleEspece: estNouvelleEspece)
    }
}

extension EtatRiviere {
    /// Mot court pour une case de conditions.
    var libelle: String {
        switch self {
        case .normal: "normal"
        case .haut: "haut"
        case .crue: "crue"
        case .inconnu: "inconnu"
        }
    }
}

#if DEBUG
#Preview("Fin de session") {
    let brochet = EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet")
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let prise = Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: debut)
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(5_040), prises: [prise],
                        conditions: [Conditions(heure: debut, ventKmh: 12, pressionHPa: 1016, etatRiviere: .normal)])
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .aucun), infosEspece: { _ in brochet },
                   lieu: "la Marne", surTerminer: {})
}

#Preview("Fin de session bredouille") {
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(7_200))
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .quiSeFerme), lieu: "la Marne", surTerminer: {})
}
#endif
