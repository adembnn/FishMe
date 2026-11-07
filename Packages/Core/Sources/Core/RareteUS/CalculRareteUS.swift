import Foundation

/// Le calcul de rareté américaine : fréquence par HUC8, repli HUC6 puis État, classes par quantiles.
/// Même algorithme que `outils/us/rarete/rarete_us.py` (comparé sur un CSV commun).
struct MoteurRareteUS: Sendable {
    /// Comptes d'un échelon (un HUC8, un HUC6 ou un État) dans une strate.
    struct Compte: Sendable {
        var n = 0
        var especes: [String: Int] = [:]
        var derniere: [String: Int] = [:]
        var sources: Set<String> = []
        var etats: [String: Int] = [:]
    }

    let parametres: ParametresRareteUS
    /// Événements gardés (doublons fusionnés, fenêtre appliquée).
    let nEvenements: Int
    /// Événements écartés : identifiant vide, HUC8 qui n'a pas 8 chiffres.
    let nRejetes: Int
    private var parHuc8: [StrateUS: [String: Compte]] = [:]
    private var parHuc6: [StrateUS: [String: Compte]] = [:]
    private var parEtat: [StrateUS: [String: Compte]] = [:]
    /// Fréquences triées des cellules fiables, par strate.
    private var distributions: [StrateUS: [Double]] = [:]

    init(evenements: [EvenementEchantillonnageUS], parametres: ParametresRareteUS = ParametresRareteUS()) {
        self.parametres = parametres
        // Doublons : un même identifiant revient (une ligne par espèce dans beaucoup de sources) ; on garde les premières métadonnées et on réunit les espèces.
        var ordre: [String] = []
        var uniques: [String: EvenementEchantillonnageUS] = [:]
        var rejetes = 0
        for e in evenements {
            guard !e.id.isEmpty, e.huc8.count == 8, e.huc8.allSatisfy({ $0.isASCII && $0.isNumber }) else { rejetes += 1; continue }
            if var deja = uniques[e.id] {
                deja.especes.formUnion(e.especes)
                uniques[e.id] = deja
            } else {
                uniques[e.id] = e
                ordre.append(e.id)
            }
        }
        nRejetes = rejetes
        var gardes = 0
        for id in ordre {
            guard let e = uniques[id] else { continue }
            if let min = parametres.anneeMinimum, e.annee < min { continue }
            gardes += 1
            let strate = StrateUS(milieu: parametres.separerParMilieu ? e.milieu.rawValue : StrateUS.tous,
                                  engin: parametres.separerParEngin ? e.engin : StrateUS.tous)
            Self.ajouter(e, dans: &parHuc8[strate, default: [:]][e.huc8, default: Compte()], etat: true)
            Self.ajouter(e, dans: &parHuc6[strate, default: [:]][e.huc6, default: Compte()], etat: false)
            Self.ajouter(e, dans: &parEtat[strate, default: [:]][e.etat, default: Compte()], etat: false)
        }
        nEvenements = gardes
        for (strate, cases) in parHuc8 {
            var freqs: [Double] = []
            for c in cases.values where c.n >= parametres.minimumEvenements {
                for (_, k) in c.especes { freqs.append(Double(k) / Double(c.n)) }
            }
            distributions[strate] = freqs.sorted()
        }
    }

    private static func ajouter(_ e: EvenementEchantillonnageUS, dans c: inout Compte, etat: Bool) {
        c.n += 1
        c.sources.insert(e.source)
        if etat { c.etats[e.etat, default: 0] += 1 }
        for sp in e.especes {
            c.especes[sp, default: 0] += 1
            c.derniere[sp] = max(c.derniere[sp] ?? e.annee, e.annee)
        }
    }

    var strates: [StrateUS] { parHuc8.keys.sorted() }

    /// Quantile de type 7 (interpolation linéaire) d'une liste triée.
    static func quantile(_ triee: [Double], _ p: Double) -> Double {
        guard !triee.isEmpty else { return 0 }
        let h = Double(triee.count - 1) * p
        let bas = Int(h.rounded(.down))
        let haut = min(bas + 1, triee.count - 1)
        return triee[bas] + (h - Double(bas)) * (triee[haut] - triee[bas])
    }

    /// Seuils (peu commun, commun) en fréquence pour une strate ; nil si les quantiles ne se calibrent pas.
    func seuils(strate: StrateUS) -> (peuCommun: Double, commun: Double)? {
        switch parametres.seuils {
        case let .fixes(p, c):
            return (p, c)
        case let .quantiles(p, c):
            let d = distributions[strate] ?? []
            guard d.count >= parametres.minimumCellulesCalibrage else { return nil }
            return (Self.quantile(d, p), Self.quantile(d, c))
        }
    }

    /// L'échelon retenu : le plus fin qui atteint le minimum ; sinon le plus fin qui a des événements, en `aucune`.
    private func choisir(strate: StrateUS, huc8: String, etat: String?) -> (EchelleUS, String, Compte)? {
        let minimum = parametres.minimumEvenements
        let c8 = parHuc8[strate]?[huc8]
        let c6 = parHuc6[strate]?[String(huc8.prefix(6))]
        let codeEtat = etat ?? c8?.etats.sorted { ($0.value, $1.key) > ($1.value, $0.key) }.first?.key
        let ce = codeEtat.flatMap { code in parEtat[strate]?[code].map { (code, $0) } }
        if let c = c8, c.n >= minimum { return (.huc8, huc8, c) }
        if let c = c6, c.n >= minimum { return (.huc6, String(huc8.prefix(6)), c) }
        if let (code, c) = ce, c.n >= minimum { return (.etat, code, c) }
        if let c = c8, c.n > 0 { return (.aucune, huc8, c) }
        if let c = c6, c.n > 0 { return (.aucune, String(huc8.prefix(6)), c) }
        if let (code, c) = ce, c.n > 0 { return (.aucune, code, c) }
        return nil
    }

    /// Résultat pour une espèce dans un HUC8. `etat` sert au repli ; sans lui, l'État dominant des événements du HUC8.
    func evaluer(espece: String, huc8: String, etat: String? = nil, strate: StrateUS) -> ResultatRareteUS {
        let affichage = parametres.revueBiologisteValidee
        guard let (echelle, code, c) = choisir(strate: strate, huc8: huc8, etat: etat) else {
            return ResultatRareteUS(espece: espece, huc8: huc8, strate: strate, classe: .donneeInsuffisante, motif: .pasAssezEvenements,
                                    frequence: nil, nEspece: 0, nTotal: 0, derniereAnnee: nil, echelle: .aucune, codeEchelle: "",
                                    sources: [], affichageRarete: false)
        }
        let k = c.especes[espece] ?? 0
        let freq = Double(c.n) > 0 ? Double(k) / Double(c.n) : nil
        var classe = ClasseRareteUS.donneeInsuffisante
        var motif: MotifInsuffisantUS?
        if echelle == .aucune {
            motif = .pasAssezEvenements
        } else if k == 0 {
            motif = .nonObservee
        } else if let s = seuils(strate: strate), let f = freq {
            classe = f >= s.commun ? .commun : (f >= s.peuCommun ? .peuCommun : .rare)
        } else {
            motif = .seuilsNonCalibres
        }
        return ResultatRareteUS(espece: espece, huc8: huc8, strate: strate, classe: classe, motif: motif, frequence: freq,
                                nEspece: k, nTotal: c.n, derniereAnnee: c.derniere[espece], echelle: echelle, codeEchelle: code,
                                sources: c.sources.sorted(), affichageRarete: affichage && classe != .donneeInsuffisante)
    }

    /// Toutes les lignes : par strate, par HUC8 avec des événements, par espèce vue dans l'échelon retenu.
    func toutes() -> [ResultatRareteUS] {
        var sortie: [ResultatRareteUS] = []
        for strate in strates {
            for huc8 in (parHuc8[strate] ?? [:]).keys.sorted() {
                guard let (_, _, c) = choisir(strate: strate, huc8: huc8, etat: nil) else { continue }
                for sp in c.especes.keys.sorted() {
                    sortie.append(evaluer(espece: sp, huc8: huc8, strate: strate))
                }
            }
        }
        return sortie
    }
}
