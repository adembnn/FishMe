import Core
import Foundation

/// Logique du bloc de règles, sans écran, testable sur Mac. Elle ne prend que des types de `Core`.
/// Elle n'invente ni règle, ni verdict, ni phrase : tout ce qu'elle rend vient des lignes et de la consigne que `controle` de Core a calculées.
enum BlocReglesLogique {
    /// Les deux états de tête (décision 10 du 19 oct.). Il n'y en a jamais trois.
    enum Tete: Equatable {
        /// « Il faut relâcher le poisson » : `raison` est la phrase de Core de la règle la plus forte (ou « Espèce non confirmée »),
        /// `ligne` la ligne de Core qui la porte (pour ouvrir sa source), `nil` quand l'espèce n'est pas confirmée.
        case relacher(raison: String, ligne: LigneControle?)
        /// « Voir la réglementation en vigueur sur ce poisson » : un dépliant fermé. `aVerifier` : une ligne est « à vérifier sur place ».
        case reglementation(aVerifier: Bool)
    }

    /// Les trois groupes du dépliant, dans cet ordre.
    enum Groupe: CaseIterable, Equatable {
        case garderOuRelacher, horaires, materielEtPratique

        var titre: String { titre(locale: Locale(identifier: "fr_FR")) }

        /// Le titre du groupe dans la langue de la région.
        nonisolated func titre(locale: Locale) -> String {
            let textes = TextesBlocRegles(locale: locale)
            switch self {
            case .garderOuRelacher: return textes.garderOuRelacher
            case .horaires: return textes.horaires
            case .materielEtPratique: return textes.materielEtPratique
            }
        }

        var symbole: String {
            switch self {
            case .garderOuRelacher: return "arrow.uturn.down"
            case .horaires: return "clock"
            case .materielEtPratique: return "wrench.and.screwdriver"
            }
        }
    }

    static let titreRelacher = "Il faut relâcher le poisson"
    static let titreReglementation = "Voir la réglementation en vigueur sur ce poisson"
    static let raisonEspeceNonConfirmee = "Espèce non confirmée"
    /// Ligne neutre quand la catégorie piscicole du cours d'eau est inconnue (jamais une alerte).
    static let categorieInconnue = "Catégorie du cours d'eau inconnue : vérifie l'arrêté"
    /// Aucune ligne de règle à montrer pour une espèce confirmée : la consigne de Core, puis cette invitation à lire les textes.
    static let aucuneLigne = "Aucune ligne de règle n'est disponible ici : lis l'arrêté préfectoral."
    static let mentionFoi = "Les textes lus font foi : l'arrêté préfectoral et le Code de l'environnement."

    /// Le groupe d'un type de règle. `autre` (espèce protégée ou toujours relâchée, règle locale à vérifier) va avec « garder ou relâcher ».
    static func groupe(de type: TypeRegle) -> Groupe {
        switch type {
        case .taille, .periode, .quota, .consommation, .autre: return .garderOuRelacher
        case .nuit: return .horaires
        case .modeDePeche, .transportVivant, .reserve: return .materielEtPratique
        }
    }

    /// Les lignes rangées par groupe, dans l'ordre des groupes ; un groupe vide n'existe pas. L'ordre des lignes de Core est gardé.
    static func groupes(_ lignes: [LigneControle]) -> [(groupe: Groupe, lignes: [LigneControle])] {
        Groupe.allCases.compactMap { g in
            let dedans = lignes.filter { groupe(de: $0.type) == g }
            return dedans.isEmpty ? nil : (groupe: g, lignes: dedans)
        }
    }

    /// Une ligne est « à vérifier sur place » (tronçon, réserve, catégorie, désaccord, texte périmé, trop près de la maille, mesure estimée).
    static func aVerifier(_ lignes: [LigneControle]) -> Bool {
        lignes.contains { $0.etat == .aVerifierSurPlace }
    }

    /// Les lignes « à vérifier », la taille d'abord (c'est elle qui demande la toise), puis l'ordre de Core.
    static func lignesAVerifier(_ lignes: [LigneControle]) -> [LigneControle] {
        let a = lignes.filter { $0.etat == .aVerifierSurPlace }
        return a.filter { $0.type == .taille } + a.filter { $0.type != .taille }
    }

    /// Ordre de force d'une règle non respectée : espèce protégée, période, quota, taille, puis le reste.
    private static let ordreDeForce: [TypeRegle] = [.autre, .periode, .quota, .taille, .reserve, .nuit, .modeDePeche,
                                                    .consommation, .transportVivant]

    /// La règle non respectée la plus forte.
    static func plusForte(_ lignes: [LigneControle]) -> LigneControle? {
        let fautives = lignes.filter { $0.etat == .nonRespectee }
        for type in ordreDeForce {
            if let l = fautives.first(where: { $0.type == type }) { return l }
        }
        return fautives.first
    }

    /// L'état de tête. « Relâcher » : une règle non respectée, une espèce protégée (consigne `relacheLa` de Core) ou une espèce non confirmée.
    /// Tous les autres cas : « Voir la réglementation », y compris « à vérifier » (pastille orange).
    static func tete(lignes: [LigneControle], consigne: Consigne, especeConfirmee: Bool) -> Tete {
        if !especeConfirmee { return .relacher(raison: raisonEspeceNonConfirmee, ligne: nil) }
        if let l = plusForte(lignes) { return .relacher(raison: l.phrase, ligne: l) }
        if consigne == .relacheLa { return .relacher(raison: consigne.texte, ligne: nil) }
        return .reglementation(aVerifier: aVerifier(lignes))
    }

    /// La phrase sous le titre fermé quand une ligne est à vérifier : la consigne de Core (« Mesure-la sur une toise », « Vérifie l'arrêté »).
    /// Rien quand aucune ligne n'est à vérifier.
    static func consigneSousLeTitre(lignes: [LigneControle], consigne: Consigne) -> String? {
        aVerifier(lignes) ? consigne.texte : nil
    }

    /// Les deux valeurs par catégorie (« 1re : fermée · 2e : ouverte ») quand la catégorie est inconnue et que Core les donne ; sinon `nil`.
    nonisolated static func valeursParCategorie(_ ligne: LigneControle, categorieInconnue: Bool,
                                                locale: Locale = Locale(identifier: "fr_FR")) -> String? {
        guard categorieInconnue, !ligne.valeursParCategorie.isEmpty else { return nil }
        let textes = TextesBlocRegles(locale: locale)
        let premiere = ligne.valeursParCategorie[.premiere].map { textes.premiereCategorie($0) }
        let deuxieme = ligne.valeursParCategorie[.deuxieme].map { textes.deuxiemeCategorie($0) }
        let texte = [premiere, deuxieme].compactMap { $0 }.joined(separator: " · ")
        return texte.isEmpty ? nil : texte
    }

    /// Le mot court de l'état d'une ligne. Jamais un mot d'autorisation, jamais un feu vert : une ligne lue ne vaut pas un feu vert.
    nonisolated static func motDEtat(_ etat: EtatLigne, locale: Locale = Locale(identifier: "fr_FR")) -> String? {
        let textes = TextesBlocRegles(locale: locale)
        switch etat {
        case .respectee: return textes.regleLue
        case .nonRespectee: return textes.nonRespectee
        case .aVerifierSurPlace: return textes.verifieSurPlace
        case .information: return nil
        }
    }
}
