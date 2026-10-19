import Core
import Foundation

/// Les règles du surnom de pêcheur (décision 3 du 19 oct.) : public, unique, sans accent ni majuscule pour l'unicité.
/// Foundation seulement : tout se teste sans iPhone.
nonisolated enum Surnom {
    static let longueurMin = 3
    static let longueurMax = 20

    nonisolated enum Refus: Error, Equatable, Sendable {
        case tropCourt
        case tropLong
        case caractereInterdit
        case tiretMalPlace
        case motRefuse
    }

    /// Lettres que le pliage des accents ne ramène pas à l'ASCII (« œuf » donne « oeuf », « straße » donne « strasse »).
    private static let translitterations: [Character: String] = [
        "œ": "oe", "æ": "ae", "ß": "ss", "ø": "o", "ł": "l", "đ": "d", "ð": "d", "þ": "th", "ı": "i", "ĳ": "ij",
    ]

    /// « Gros-Brochet » et « gros-brochet » donnent la même clé : minuscules, sans accents, œ æ ß ø ł translittérés.
    /// Le résultat n'est pas toujours ASCII (grec, cyrillique...) : `verifier` refuse ces surnoms, `identifiant` retire le reste.
    static func normaliser(_ brut: String) -> String {
        var sortie = ""
        for c in brut.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            if let remplacement = translitterations[c] { sortie += remplacement } else { sortie.append(c) }
        }
        return sortie
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
    }

    /// Identifiant de l'enregistrement `ProfilPublic` : l'unicité vient de lui (R2, `schema.md`). `p-` + surnom normalisé.
    /// ASCII SEULEMENT : CloudKit refuse un `recordName` non ASCII (exception, donc crash). Tout caractère hors a-z, 0-9 et tiret est retiré ;
    /// un surnom passé par `verifier` n'en perd aucun.
    static func identifiant(pour surnom: String) -> String {
        "p-" + versASCII(normaliser(surnom))
    }

    /// Ne garde que a-z, 0-9 et le tiret.
    static func versASCII(_ texte: String) -> String {
        String(texte.filter { estCaractereDIdentifiant($0) })
    }

    private static func estCaractereDIdentifiant(_ c: Character) -> Bool {
        c.isASCII && (c.isLowercase || c.isNumber || c == "-")
    }

    /// `nil` si le surnom est permis : 3 à 20 caractères, lettres, chiffres, tiret (ni au début, ni à la fin, ni doublé).
    static func verifier(_ brut: String, filtre: any FiltreMots = FiltreCore()) -> Refus? {
        let surnom = brut.trimmingCharacters(in: .whitespacesAndNewlines)
        if surnom.count < longueurMin { return .tropCourt }
        if surnom.count > longueurMax { return .tropLong }
        // Contrôle sur la forme NORMALISÉE : « Éloïse » et « œuf » passent (« eloise », « oeuf »), « Ωμέγα » ou « щука » non (R2 : ASCII seulement).
        if normaliser(surnom).contains(where: { !estCaractereDIdentifiant($0) }) { return .caractereInterdit }
        if surnom.hasPrefix("-") || surnom.hasSuffix("-") || surnom.contains("--") { return .tiretMalPlace }
        if filtre.refuse(surnom) { return .motRefuse }
        return nil
    }

    /// Le texte que la personne lit sous le champ. Court, sans jargon.
    static func phrase(pour refus: Refus) -> String {
        switch refus {
        case .tropCourt: "Au moins 3 caractères."
        case .tropLong: "20 caractères au plus."
        case .caractereInterdit: "Lettres, chiffres et tiret seulement."
        case .tiretMalPlace: "Le tiret va entre deux lettres."
        case .motRefuse: "Ce mot n'est pas accepté."
        }
    }
}

/// Le videur à la saisie (règle 1.2 d'Apple). // R2: `moderation.md` : la liste de mots est fournie par L23 (mot entier, jamais sous-chaîne).
nonisolated protocol FiltreMots: Sendable {
    func refuse(_ texte: String) -> Bool
}

/// Aucun mot refusé : pour les tests et les aperçus seulement.
nonisolated struct AucunFiltre: FiltreMots {
    func refuse(_ texte: String) -> Bool { false }
}

/// Le filtre par défaut : la liste partagée de `Core` (`MotsInterditsFR`, LDNOOBW CC-BY-4.0, attribution dans Sources).
nonisolated struct FiltreCore: FiltreMots {
    func refuse(_ texte: String) -> Bool { MotsInterditsFR.contient(texte) }
}

/// Filtre par liste de mots entiers, avec les astuces d'écriture courantes (0 pour o, 1 pour i, 3 pour e, @ pour a).
nonisolated struct FiltreParListe: FiltreMots {
    let mots: Set<String>

    init(mots: Set<String>) {
        self.mots = Set(mots.map { Self.simplifier($0) })
    }

    func refuse(_ texte: String) -> Bool {
        let morceaux = Surnom.normaliser(texte)
            .split(whereSeparator: { !($0.isLetter || $0.isNumber || $0 == "@") })
            .map { Self.simplifier(String($0)) }
        if morceaux.contains(where: { mots.contains($0) }) { return true }
        // Mots collés par des tirets ou des espaces : « gros-mot » devient « grosmot ».
        return mots.contains(morceaux.joined())
    }

    private static func simplifier(_ mot: String) -> String {
        var sortie = ""
        for c in Surnom.normaliser(mot) {
            switch c {
            case "0": sortie.append("o")
            case "1": sortie.append("i")
            case "3": sortie.append("e")
            case "@": sortie.append("a")
            default: sortie.append(c)
            }
        }
        return sortie
    }
}
