import Foundation

/// Les règles de forme de la fiche D4, appliquées à `conseils.json` et au tableau de relecture.
public enum ValidationConseils {
    public static let longueurMax = 80

    /// Formulations de `docs/banc/mots-interdits.md`, en minuscules sans accent, plus ce qu'un conseil ne dit jamais (règle, taille).
    static let motsInterdits: [String] = [
        "poke", "pokemon", "pokedex", "reconnu a", "100 % fiable", "100% fiable", "notre ia", "meilleur coin",
        "bon spot", "meilleures chances", "garanti", "note d'activite", "indice de peche", "sur 100",
        "meilleure heure", "solunaire", "ca va mordre", "vont mordre", "probabilite de capture",
        "droit de garder", "14 especes",
        "quota", "taille minimale", "taille legale", "maille", "fermeture", "fermee",
    ]

    /// Un nombre suivi de « cm », « garde », « garder », « gardé ».
    static let motifsInterdits: [String] = [
        #"\d\s*cm\b"#,
        #"\bgard(e|er|es|ez|é|ée|ées|és)\b"#,
    ]

    public static func normaliser(_ texte: String) -> String {
        texte.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR")).lowercased()
    }

    public static func contientRelache(_ texte: String) -> Bool {
        normaliser(texte).contains("relache")
    }

    public static func estRelacheLa(_ texte: String) -> Bool {
        let n = normaliser(texte).trimmingCharacters(in: CharacterSet(charactersIn: " .!"))
        return n == "relache-la"
    }

    /// Les erreurs d'un conseil seul. `exigerRelecture` : vrai pour `conseils.json`, faux pour le tableau avant la relecture de S.
    public static func erreurs(_ c: ConseilFiche, sources: [SourceLue], exigerRelecture: Bool,
                               statuts: Set<StatutEspece> = []) -> [String] {
        var e: [String] = []
        let t = c.texte
        if t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { e.append("texte vide") }
        if t.count > longueurMax { e.append("texte de \(t.count) caractères (80 au plus)") }
        if t.contains("\n") || t.contains("\r") { e.append("texte sur plusieurs lignes") }
        if !IconesConseils.estAutorisee(c.icone) { e.append("icône « \(c.icone) » hors de la liste fermée") }
        if c.mois.isEmpty { e.append("mois vide") }
        if c.mois.contains(where: { !(1...12).contains($0) }) { e.append("mois hors de 1 à 12") }
        if c.niveaux.isEmpty { e.append("niveaux vides") }
        if c.rang < 1 { e.append("rang inférieur à 1") }
        if c.sources.isEmpty { e.append("aucune source") }
        for id in c.sources {
            guard let s = sources.first(where: { $0.id == id }) else { e.append("source \(id) absente de la liste"); continue }
            if !s.url.hasPrefix("https://") { e.append("source \(id) sans lien https") }
            if s.titre.isEmpty { e.append("source \(id) sans titre") }
            if s.luLe.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) == nil {
                e.append("source \(id) sans date de lecture AAAA-MM-JJ")
            }
        }
        if exigerRelecture && !c.estRelu { e.append("relu_par vide") }
        let n = normaliser(t)
        for mot in motsInterdits where n.contains(mot) { e.append("formulation interdite « \(mot) »") }
        for motif in motifsInterdits where n.range(of: motif, options: .regularExpression) != nil {
            e.append("taille ou « garde » dans le texte (\(motif))")
        }
        if statuts.contains(.protegee) || statuts.contains(.toujoursRelachee) {
            if !estRelacheLa(t) { e.append("espèce protégée : seul conseil permis « relâche-la »") }
        }
        if statuts.contains(.envahissante) {
            if contientRelache(t) { e.append("espèce envahissante : jamais « relâche »") }
            if c.modes.contains(.vif) { e.append("espèce envahissante : jamais en vif") }
        }
        return e
    }

    /// Les erreurs de tout un fichier. `statuts` : espèce → statuts de `especes.json` (D1).
    public static func erreurs(_ f: FichierConseils, exigerRelecture: Bool,
                               statuts: [String: Set<StatutEspece>] = [:]) -> [String] {
        var e: [String] = []
        var vus = Set<String>()
        for c in f.conseils {
            if !vus.insert(c.id).inserted { e.append("\(c.id) : identifiant en double") }
            for m in erreurs(c, sources: f.sources, exigerRelecture: exigerRelecture, statuts: statuts[c.espece] ?? []) {
                e.append("\(c.id) : \(m)")
            }
        }
        for (espece, s) in statuts where s.contains(.protegee) || s.contains(.toujoursRelachee) {
            let n = f.conseils.filter { $0.espece == espece }.count
            if n > 1 { e.append("\(espece) : espèce protégée avec \(n) conseils (un seul permis)") }
        }
        return e
    }
}
