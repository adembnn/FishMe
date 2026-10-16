import Foundation

/// Réécrit les phrases de règles qui disent « se garde à partir de N cm », « gardé », « on garde » en formulation neutre de la loi
/// (« taille minimale N cm »). L'app ne dit jamais à quelqu'un qu'il peut garder un poisson : elle montre la loi.
/// Les formes négatives (« ne se garde pas », « interdit de garder », « gardée en captivité ni transportée ») gardent leur sens et ne bougent pas.
public enum PhrasesNeutres {
    private static let regles: [(NSRegularExpression, String)] = {
        let liste: [(String, String)] = [
            // Taille minimale.
            (#" se garde à partir de (\d+(?:, \d+)*(?:,? ou \d+)?) cm"#, ", taille minimale $1 cm"),
            (#" se garde à partir de (\d+(?:,\d+)?) cm"#, ", taille minimale $1 cm"),
            (#" gardée? à partir de (\d+(?:,\d+)?) cm"#, ", taille minimale $1 cm"),
            (#"(\d+(?:,\d+)?) cm minimum pour le garder"#, "taille minimale $1 cm"),
            (#"on garde seulement celles de (\d+(?:,\d+)?) cm et plus"#, "taille minimale $1 cm"),
            // Fenêtre de taille.
            (#"on ne garde que les ([\p{L}]+) de (\d+) à (\d+) cm"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#"on garde seulement les ([\p{L}]+) de (\d+) à (\d+) cm"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#"on garde (?:seulement )?les ([\p{L}]+) de (\d+) à (\d+) cm"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#"on garde un ([\p{L}]+) seulement entre (\d+) et (\d+) cm"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#"on garde seulement entre (\d+) et (\d+) cm"#, "taille encadrée : de $1 à $2 cm seulement"),
            (#"on garde entre (\d+) et (\d+) cm"#, "taille encadrée : de $1 à $2 cm seulement"),
            (#"seuls les ([\p{L}]+) de (\d+) à (\d+) cm(?: inclus)? peuvent être gardés"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#"un ([\p{L}]+) entre (\d+) et (\d+) cm peut être gardé"#, "taille encadrée : $1 de $2 à $3 cm seulement"),
            (#" gardé seulement entre (\d+) et (\d+) cm"#, ", taille encadrée : de $1 à $2 cm seulement"),
            // Quotas.
            (#"(\d+) ([\p{L}]+) à garder par jour"#, "quota $1 $2 par jour"),
            (#"(\d+) à garder par jour"#, "quota $1 par jour"),
            (#"(\d+) (?:seul )?([\p{L}]+) gardé par jour"#, "quota $1 $2 par jour"),
            (#"aucune prise gardée"#, "aucune prise"),
            (#"pas de poisson gardé"#, "pas de prise"),
        ]
        return liste.compactMap { motif, modele in
            (try? NSRegularExpression(pattern: motif)).map { ($0, modele) }
        }
    }()

    /// Phrase neutre. Idempotente : une phrase déjà neutre revient telle quelle.
    public static func neutre(_ phrase: String) -> String {
        var texte = phrase
        for (regle, modele) in regles {
            let plage = NSRange(texte.startIndex..., in: texte)
            texte = regle.stringByReplacingMatches(in: texte, range: plage, withTemplate: modele)
        }
        return texte
    }
}
