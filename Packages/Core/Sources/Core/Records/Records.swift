import Foundation

// N4 : records et statistiques de base. Un record est un souvenir, pas un objectif : rien ici ne rend de points,
// de niveau ni de rang. Foundation seulement. ⚠ à vérifier : écrit sans compilateur Swift.

/// Le souvenir d'une espèce : la plus grande prise mesurée.
public struct RecordEspece: Sendable, Equatable, Hashable, Codable, Identifiable {
    public var espece: Espece
    /// La prise qui tient le souvenir.
    public var priseID: UUID
    public var longueurCm: Double
    public var mesure: MethodeMesure?
    public var date: Date
    public var lieuFlou: String?
    /// Vraies prises de l'espèce, avec ou sans taille.
    public var nombreDePrises: Int
    /// Longueur strictement supérieure au seuil de l'espèce (faux sans seuil).
    public var estTrophee: Bool
    public var id: String { espece.id }

    public init(espece: Espece, priseID: UUID, longueurCm: Double, mesure: MethodeMesure? = nil, date: Date,
                lieuFlou: String? = nil, nombreDePrises: Int, estTrophee: Bool) {
        self.espece = espece
        self.priseID = priseID
        self.longueurCm = longueurCm
        self.mesure = mesure
        self.date = date
        self.lieuFlou = lieuFlou
        self.nombreDePrises = nombreDePrises
        self.estTrophee = estTrophee
    }
}

public struct CompteursPersonnels: Sendable, Equatable, Hashable, Codable {
    /// Sorties terminées (`fin != nil`).
    public var sorties: Int
    /// Espèces distinctes ayant une carte qui n'est pas un exemple, cartes déclarées comprises.
    public var especesTrouvees: Int
    /// Sorties terminées sans vraie prise.
    public var bredouilles: Int

    public init(sorties: Int = 0, especesTrouvees: Int = 0, bredouilles: Int = 0) {
        self.sorties = sorties
        self.especesTrouvees = especesTrouvees
        self.bredouilles = bredouilles
    }
}

public struct BilanRecords: Sendable, Equatable, Hashable, Codable {
    /// Triés par date décroissante, puis par identifiant d'espèce.
    public var records: [RecordEspece]
    /// Vraies prises, mais aucune longueur valide.
    public var especesSansTaille: [Espece]
    public var compteurs: CompteursPersonnels

    public init(records: [RecordEspece] = [], especesSansTaille: [Espece] = [], compteurs: CompteursPersonnels = CompteursPersonnels()) {
        self.records = records
        self.especesSansTaille = especesSansTaille
        self.compteurs = compteurs
    }
}

public enum EvenementRecord: Sendable, Equatable, Hashable {
    case aucun
    /// Première longueur valide de l'espèce : pas de bandeau.
    case premiereTaille
    case nouveauSouvenir(ancienCm: Double, nouveauCm: Double)
}

public enum MoteurRecords {
    /// Une prise compte pour un record si c'est une vraie prise, pas un exemple, avec une longueur finie et positive.
    static func longueurCompteuse(_ prise: Prise) -> Double? {
        guard prise.origine == .priseReelle, !prise.exemple, let l = prise.longueurCm, l.isFinite, l > 0 else { return nil }
        return l
    }

    static func estVraiePrise(_ prise: Prise) -> Bool { prise.origine == .priseReelle && !prise.exemple }

    /// Longueur au millimètre (0,1 cm) : 72,04 et 72,0 sont égales.
    public static func millimetres(_ cm: Double) -> Double { (cm * 10).rounded() }

    public static func bilan(prises: [Prise], sorties: [Sortie], seuilTropheeCm: (Espece) -> Double?) -> BilanRecords {
        let vraies = prises.filter(estVraiePrise)

        var parEspece: [String: [Prise]] = [:]
        for p in vraies { parEspece[p.espece.id, default: []].append(p) }

        var records: [RecordEspece] = []
        var sansTaille: [Espece] = []
        for (_, groupe) in parEspece {
            // Plus grande longueur au mm ; à égalité, la prise la plus ancienne (puis l'identifiant, pour un ordre stable).
            let plusGrandeDuGroupe = groupe
                .filter { longueurCompteuse($0) != nil }
                .min { a, b in
                    let la = millimetres(longueurCompteuse(a) ?? 0), lb = millimetres(longueurCompteuse(b) ?? 0)
                    if la != lb { return la > lb }
                    if a.date != b.date { return a.date < b.date }
                    return a.id.uuidString < b.id.uuidString
                }
            if let m = plusGrandeDuGroupe, let l = longueurCompteuse(m) {
                let seuil = seuilTropheeCm(m.espece)
                let trophee = seuil.map { $0.isFinite && millimetres(l) > millimetres($0) } ?? false
                records.append(RecordEspece(espece: m.espece, priseID: m.id, longueurCm: l, mesure: m.mesure, date: m.date,
                                            lieuFlou: m.lieuFlou, nombreDePrises: groupe.count, estTrophee: trophee))
            } else if let premiere = groupe.first {
                sansTaille.append(premiere.espece)
            }
        }
        records.sort { a, b in a.date != b.date ? a.date > b.date : a.espece.id < b.espece.id }
        sansTaille.sort { $0.id < $1.id }

        let terminees = sorties.filter { $0.fin != nil }
        let bredouilles = terminees.filter { s in !s.prises.contains(where: estVraiePrise) }.count
        let trouvees = Set(prises.filter { !$0.exemple }.map { $0.espece.id }).count

        return BilanRecords(records: records, especesSansTaille: sansTaille,
                            compteurs: CompteursPersonnels(sorties: terminees.count, especesTrouvees: trouvees, bredouilles: bredouilles))
    }

    /// À appeler AVANT d'insérer la carte de `prise` dans le Pescedex. Si `autres` la contient déjà, elle est ignorée (même `id`).
    public static func evenement(pour prise: Prise, parmi autres: [Prise]) -> EvenementRecord {
        guard let nouvelle = longueurCompteuse(prise) else { return .aucun }
        let anciennes = autres.compactMap { p -> Double? in
            guard p.id != prise.id, p.espece.id == prise.espece.id else { return nil }
            return longueurCompteuse(p)
        }
        guard let plusGrande = anciennes.max(by: { millimetres($0) < millimetres($1) }) else { return .premiereTaille }
        // En cas d'égalité au mm, `max` garde la première rencontrée ; seule la valeur au mm compte ici.
        return millimetres(nouvelle) > millimetres(plusGrande) ? .nouveauSouvenir(ancienCm: plusGrande, nouveauCm: nouvelle) : .aucun
    }
}
