import Foundation

/// Le videur à la saisie (règle 1.2 d'Apple) : longueur, mots interdits, et tout ce qui ressemble à une position de pêche.
/// Pur Foundation : testable sans iPhone.
nonisolated enum FiltreMessage {
    static let longueurMax = 500

    nonisolated enum Verdict: Equatable, Sendable {
        case accepte(String)
        case vide
        case tropLong
        case motInterdit
        /// Coordonnée, lien de carte : la règle d'or veut qu'aucun coin exact ne sorte de l'iPhone.
        case position
    }

    /// Liste de départ, volontairement courte (mots entiers seulement, jamais de sous-chaîne).
    /// À aligner L23 : une seule liste partagée (R2 `moderation.md`, liste LDNOOBW relue, faux positifs de pêche retirés).
    static let motsInterdits: Set<String> = [
        "connard", "connasse", "salope", "pute", "enculer", "encule", "batard", "fdp", "ntm", "nique", "niquer",
        "negre", "bougnoule", "tapette", "pedophile", "nazi",
    ]

    static func verifier(_ brut: String) -> Verdict {
        let texte = brut.trimmingCharacters(in: .whitespacesAndNewlines)
        if texte.isEmpty { return .vide }
        if texte.count > longueurMax { return .tropLong }
        if contientPosition(texte) { return .position }
        if contientMotInterdit(texte) { return .motInterdit }
        return .accepte(texte)
    }

    // MARK: Mots interdits

    /// Minuscules, sans accents, `0`→`o`, `1`→`i`, `3`→`e`, `@`→`a`, `$`→`s`.
    static func normaliser(_ texte: String) -> String {
        let simple = texte.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
        var sortie = ""
        for c in simple.lowercased() {
            switch c {
            case "0": sortie.append("o")
            case "1": sortie.append("i")
            case "3": sortie.append("e")
            case "@": sortie.append("a")
            case "$": sortie.append("s")
            default: sortie.append(c)
            }
        }
        return sortie
    }

    static func mots(de texte: String) -> [String] {
        normaliser(texte).split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    static func contientMotInterdit(_ texte: String) -> Bool {
        let tous = mots(de: texte)
        if tous.contains(where: { motsInterdits.contains($0) }) { return true }
        // « c o n n a r d » ou « c-o-n-n-a-r-d » : on recolle les suites de lettres isolées.
        var suite = ""
        for mot in tous + [""] {
            if mot.count == 1 {
                suite += mot
            } else {
                if suite.count >= 3, motsInterdits.contains(suite) { return true }
                suite = ""
            }
        }
        return false
    }

    // MARK: Positions

    private static let hotesDeCarte = [
        "google.com/maps", "goo.gl/maps", "maps.app.goo.gl", "maps.apple.com", "maps.apple", "waze.com", "what3words",
        "w3w.co", "openstreetmap.org", "geo:", "geoportail", "comgooglemaps://", "waze://",
    ]

    /// Deux nombres décimaux de 3 chiffres ou plus après la virgule (une latitude et une longitude), un lien de carte,
    /// ou les mots « lat »/« lon »/« gps » avec un nombre. On filtre les formats, pas le sens.
    static func contientPosition(_ texte: String) -> Bool {
        let bas = texte.lowercased()
        if hotesDeCarte.contains(where: { bas.contains($0) }) { return true }
        let decimaux = nombreDeCorrespondances(#"[-+]?\d{1,3}[.,]\d{3,}"#, dans: bas)
        if decimaux >= 2 { return true }
        if decimaux >= 1, bas.range(of: #"\b(lat|lon|lng|gps|latitude|longitude)\b"#, options: .regularExpression) != nil { return true }
        // Degrés minutes : 48°51'
        if bas.range(of: #"\d{1,3}\s*°\s*\d{1,2}\s*['′]"#, options: .regularExpression) != nil { return true }
        return false
    }

    private static func nombreDeCorrespondances(_ motif: String, dans texte: String) -> Int {
        guard let expression = try? NSRegularExpression(pattern: motif) else { return 0 }
        return expression.numberOfMatches(in: texte, range: NSRange(texte.startIndex..., in: texte))
    }
}
