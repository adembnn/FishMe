import Foundation
@testable import Core

/// Ce que les tests savent des règles nationales et des statuts, en attendant `regles/national.json` et `especes.json` (D1).
/// Copié de `docs/regles/especes-national.json` (15 oct. 2026) ; à remplacer par la lecture des vrais fichiers quand D1 sera fusionné.
enum RegleDuLot {
    // MARK: - Lecture des vrais fichiers de D1 (ressources de Core), sinon repli sur une copie à la main

    private static func json(_ nom: String, sousDossier: String? = nil) -> Any? {
        guard let url = Bundle.module.url(forResource: nom, withExtension: "json", subdirectory: sousDossier),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    /// `especes.json` (D1), vide ou absent : `nil`.
    nonisolated(unsafe) static let especes: [[String: Any]]? = {
        guard let l = json("especes") as? [[String: Any]], !l.isEmpty else { return nil }
        return l
    }()

    /// `regles/national.json` (D1), absent ou sans règles : `nil`.
    nonisolated(unsafe) static let regles: [[String: Any]]? = {
        guard let d = json("national", sousDossier: "regles") as? [String: Any],
              let r = d["regles"] as? [[String: Any]], !r.isEmpty else { return nil }
        return r
    }()

    static var lesFichiersDeD1SontLa: Bool { especes != nil && regles != nil }

    static var idsConnus: Set<String> {
        if let especes { return Set(especes.compactMap { $0["id"] as? String }) }
        return Set(Espece.identifiantsNationaux)
    }

    /// Repli si `especes.json` n'est pas encore là (copie de `docs/regles/especes-national.json`, 15 oct. 2026).
    private static let protegeesDeRepli: Set<String> = ["esturgeon-europeen", "apron-du-rhone"]
    private static let envahissantesDeRepli: Set<String> = [
        "perche-soleil", "poisson-chat", "ecrevisse-americaine", "ecrevisse-de-louisiane", "ecrevisse-signal",
        "ecrevisse-virile", "ecrevisse-marbree", "ecrevisse-a-taches-rouges", "grenouille-taureau",
    ]

    static func statuts(_ espece: String) -> Set<StatutEspece> {
        if let especes {
            guard let e = especes.first(where: { $0["id"] as? String == espece }) else { return [] }
            let valeurs = (e["statut"] as? [[String: Any]] ?? []).compactMap { $0["valeur"] as? String }
            return Set(valeurs.compactMap(statut))
        }
        if protegeesDeRepli.contains(espece) { return [.protegee, .toujoursRelachee] }
        if envahissantesDeRepli.contains(espece) { return [.envahissante] }
        return []
    }

    private static func statut(_ valeur: String) -> StatutEspece? {
        switch valeur {
        case "protegee": return .protegee
        case "envahissante": return .envahissante
        case "stade_a_demander": return .stadeADemander
        case "toujours_relachee": return .toujoursRelachee
        default: return nil
        }
    }

    static func estProtegee(_ espece: String) -> Bool {
        let s = statuts(espece)
        return s.contains(.protegee) || s.contains(.toujoursRelachee)
    }

    // MARK: - Mois fermés

    private static func moisTouchesHorsDe(du: String, au: String) -> Set<Int> {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let f = DateFormatter(); f.calendar = cal; f.timeZone = cal.timeZone; f.dateFormat = "yyyy-MM-dd"
        guard let debut = f.date(from: du), let fin = f.date(from: au) else { return [] }
        let annee = cal.component(.year, from: debut)
        var fermes = Set<Int>()
        for m in 1...12 {
            let jours = cal.range(of: .day, in: .month, for: cal.date(from: DateComponents(year: annee, month: m, day: 1))!)!
            for j in jours {
                let d = cal.date(from: DateComponents(year: annee, month: m, day: j))!
                if d < debut || d > fin { fermes.insert(m); break }
            }
        }
        return fermes
    }

    /// Les mois que touche l'intervalle (lecture prudente), dans une même année.
    private static func moisDansLIntervalle(du: String, au: String) -> Set<Int> {
        let a = Int(du.dropFirst(5).prefix(2)) ?? 1, b = Int(au.dropFirst(5).prefix(2)) ?? 12
        return a <= b ? Set(a...b) : []
    }

    /// Mois fermés déduits de `regles/national.json` : la fenêtre ouverte de la 1re catégorie, et les lignes `interdit` par espèce.
    private static func moisFermesDuFichier(espece: String, categorie: Categorie) -> Set<Int> {
        guard let regles, let especes else { return [] }
        let code = especes.first(where: { $0["id"] as? String == espece })?["code_sandre"] as? String
        var fermes = Set<Int>()
        for r in regles {
            let cat = r["categorie"] as? String ?? ""
            let concerne = cat == "toutes" || (cat == "1" && categorie == .premiere) || (cat == "2" && categorie == .deuxieme)
            guard concerne, let du = r["du"] as? String, let au = r["au"] as? String else { continue }
            let type = r["type"] as? String
            let codes = r["especes"] as? [String] ?? []
            if type == "ouverture", codes.isEmpty, categorie == .premiere {
                fermes.formUnion(moisTouchesHorsDe(du: du, au: au))
            } else if type == "interdit", let code, codes.contains(code) {
                fermes.formUnion(moisDansLIntervalle(du: du, au: au))
            }
        }
        return fermes
    }

    /// Lecture prudente : un mois est « fermé » dès qu'un seul de ses jours l'est.
    /// 1re catégorie : du 2e samedi de mars au 3e dimanche de septembre (brochet : dernier samedi d'avril ; ombre : 3e samedi de mai).
    /// 2e catégorie : ouvert toute l'année, sauf le brochet (fermé du dernier dimanche de janvier au dernier samedi d'avril),
    /// l'ombre (ouvert du 3e samedi de mai au 31 décembre) et la truite fario (comme la 1re catégorie).
    static func moisFermes(espece: String, categorie: Categorie) -> Set<Int> {
        moisFermesAMain(espece: espece, categorie: categorie).union(moisFermesDuFichier(espece: espece, categorie: categorie))
    }

    /// Copie à la main de `especes-national.json` : garde le brochet et l'ombre en 1re catégorie, que `national.json` ne saisit pas encore.
    static func moisFermesAMain(espece: String, categorie: Categorie) -> Set<Int> {
        let premiere: Set<Int> = [1, 2, 3, 9, 10, 11, 12]
        switch (espece, categorie) {
        case ("brochet", .premiere): return [1, 2, 3, 4, 9, 10, 11, 12]
        case ("brochet", .deuxieme): return [1, 2, 3, 4]
        case ("ombre-commun", .premiere): return [1, 2, 3, 4, 5, 9, 10, 11, 12]
        case ("ombre-commun", .deuxieme): return [1, 2, 3, 4, 5]
        case ("truite-fario", _): return premiere
        case (_, .premiere): return premiere
        default: return []
        }
    }

    /// Pendant la fermeture du brochet en 2e catégorie, le vif, le poisson mort ou artificiel et les leurres sont interdits
    /// (arrêtés 75 et 94 ; la FNPF le présente comme national, non lu dans le Code [?]) : mois 1 à 4, lecture prudente.
    static let modesFermesAvecLeBrochet: Set<ModeConseil> = [.vif, .poissonMort, .leurre]
    static let moisFermetureBrochet: Set<Int> = [1, 2, 3, 4]

    /// Erreurs d'un conseil contre ces règles ; vide pour une espèce protégée (« relâche-la » vaut toute l'année).
    static func erreurs(_ c: ConseilFiche) -> [String] {
        guard !estProtegee(c.espece) else { return [] }
        var e: [String] = []
        let cats: [Categorie] = switch c.categorie {
        case .premiere: [.premiere]
        case .deuxieme: [.deuxieme]
        case .toutes: [.premiere, .deuxieme]
        }
        for cat in cats {
            let touches = Set(c.mois).intersection(moisFermes(espece: c.espece, categorie: cat))
            if !touches.isEmpty { e.append("mois \(touches.sorted()) dans une fermeture nationale (catégorie \(cat))") }
        }
        if c.categorie != .premiere, !Set(c.modes).isDisjoint(with: modesFermesAvecLeBrochet),
           !Set(c.mois).isDisjoint(with: moisFermetureBrochet) {
            e.append("mode interdit pendant la fermeture du brochet (mois 1 à 4)")
        }
        return e
    }
}
