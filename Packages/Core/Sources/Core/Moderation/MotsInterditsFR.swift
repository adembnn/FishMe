import Foundation

/// Mots et expressions refusés à la saisie (surnoms, publications, commentaires, messages) : règle 1.2 d'Apple.
///
/// Origine : « List of Dirty, Naughty, Obscene, and Otherwise Bad Words » (LDNOOBW), fichier français,
/// licence CC BY 4.0, https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words
/// ⚠ L'attribution doit apparaître dans l'app (Profil, Sources). Ajouts de FishMe : insultes et haines courantes sur un réseau.
///
/// Retirés volontairement, parce que ce sont des mots de pêche ou de langage courant : tanche, bite, bitte (la touche),
/// gueule (du poisson), gerbe (d'eau), suce, pédale, turlutte (leurre), cul, folle, bander, pipi, caca, pisser, péter,
/// étron, baiser, jouir, zizi, trique, emmerder. Aucun mot n'est refusé par sous-chaîne : « concours » ne contient pas « con ».
/// Les lettres répétées ne sont pas réduites des deux côtés (« coule » ne doit pas devenir « couille ») : seules les suites de
/// trois lettres identiques ou plus sont ramenées à une (« connaaard » devient « connard »).
public enum MotsInterditsFR {
    /// Mots entiers, sans accents, en minuscules.
    public static let mots: Set<String> = [
        "brackmard", "branlage", "branler", "branlette", "branleur", "branleuse", "chatte", "chiasse", "chiottes", "clito",
        "con", "conne", "connard", "connasse", "couille", "couilles", "cramouille", "encule", "enculee", "enculer", "enculeur",
        "enculeurs", "enfoire", "enfoiree", "gouine", "grogniasse", "malpt", "merde", "merdeuse", "merdeux", "merdique",
        "negre", "negro", "palucher", "pede", "pouffiasse", "putain", "pute", "putes", "salaud", "salope", "salopard",
        "tapette", "teuch", "tringler", "troncher", "batard", "bordel", "nique", "niquer", "ntm", "fdp", "pd", "pedophile",
        "pedo", "violeur", "nazi", "bougnoule", "youpin", "petasse", "trouduc",
    ]

    /// Suites de mots (mots entiers consécutifs), sans accents, en minuscules.
    public static let expressions: [[String]] = [
        ["fille", "de", "pute"], ["fils", "de", "pute"], ["nique", "ta", "mere"], ["nique", "ta", "race"],
        ["trou", "du", "cul"], ["sac", "a", "foutre"], ["sac", "a", "merde"], ["brouter", "le", "cresson"],
        ["la", "putain", "de", "ta", "mere"],
    ]

    /// Vrai si le texte contient un mot ou une expression de la liste, en mot entier.
    /// Gère les majuscules, les accents, les chiffres à la place des lettres (0, 1, 3, @, $), les lettres espacées
    /// (« c o n n a r d », « c-o-n-n-a-r-d ») et les lettres étirées (« connaaard »).
    public static func contient(_ texte: String) -> Bool {
        let tous = decouper(texte)
        if tous.contains(where: { mots.contains($0) }) { return true }

        // Lettres isolées recollées : « c o n n a r d ».
        var suite = ""
        for mot in tous + [""] {
            if mot.count == 1 {
                suite += mot
            } else {
                if suite.count >= 3, mots.contains(suite) { return true }
                suite = ""
            }
        }

        // Expressions : mots consécutifs.
        for expression in expressions where tous.count >= expression.count {
            for debut in 0...(tous.count - expression.count) {
                if Array(tous[debut..<(debut + expression.count)]) == expression { return true }
            }
        }
        return false
    }

    /// Minuscules, sans accents, 0 devient o, 1 devient i, 3 devient e, @ devient a, $ devient s ;
    /// coupe à tout caractère qui n'est pas une lettre ; ramène une suite de 3 lettres identiques ou plus à une seule.
    static func decouper(_ texte: String) -> [String] {
        let simple = texte.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        var remplace = ""
        for c in simple {
            switch c {
            case "0": remplace.append("o")
            case "1": remplace.append("i")
            case "3": remplace.append("e")
            case "@": remplace.append("a")
            case "$": remplace.append("s")
            default: remplace.append(c)
            }
        }
        return remplace
            .split(whereSeparator: { !$0.isLetter })
            .map { etirement(String($0)) }
    }

    /// « connaaard » devient « connard » : seules les suites de 3 lettres identiques ou plus sont ramenées à une.
    static func etirement(_ mot: String) -> String {
        var sortie = ""
        var courant: Character?
        var longueur = 0
        for c in mot {
            if c == courant {
                longueur += 1
            } else {
                sortie += ajouter(courant, longueur)
                courant = c
                longueur = 1
            }
        }
        sortie += ajouter(courant, longueur)
        return sortie
    }

    private static func ajouter(_ lettre: Character?, _ longueur: Int) -> String {
        guard let lettre else { return "" }
        return String(repeating: String(lettre), count: longueur >= 3 ? 1 : longueur)
    }
}
