import Core
import Foundation
import Observation

/// Le modèle de « Mes records » : appelle `MoteurRecords.bilan` et retient, sur l'iPhone, quels souvenirs ont déjà été vus
/// (pour le ruban « Nouveau »). ⚠ à vérifier : écrit sans compilateur Swift (`@Observable` et `UserDefaults` en Swift 6).
@MainActor
@Observable
final class ModeleRecords {
    static let cleVus = "records.vus"

    private(set) var bilan: BilanRecords
    /// Espèces dont le souvenir n'a jamais été ouvert (ruban « Nouveau »). Vide à la toute première ouverture.
    private(set) var nouveaux: Set<String> = []

    private let infos: [String: EspecePechable]
    private let poids: (Espece, Double) -> PoidsEstime?
    private let defauts: UserDefaults?

    /// - cartes : toutes les cartes du Pescedex ; sorties : les sorties terminées ;
    /// - seuilTropheeCm : `{ _ in nil }` retire seulement l'étiquette « Trophée » ;
    /// - poids : `{ espece, cm in services.poidsEstime(...) }`, ou rien.
    init(cartes: [Prise], sorties: [Sortie], especes: [EspecePechable], seuilTropheeCm: (Espece) -> Double?,
         poids: @escaping (Espece, Double) -> PoidsEstime? = { _, _ in nil }, defauts: UserDefaults? = .standard) {
        self.bilan = MoteurRecords.bilan(prises: cartes, sorties: sorties, seuilTropheeCm: seuilTropheeCm)
        self.infos = Dictionary(especes.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        self.poids = poids
        self.defauts = defauts
        self.nouveaux = calculerNouveaux()
    }

    func info(_ espece: Espece) -> EspecePechable? { infos[espece.id] }

    func nom(_ espece: Espece) -> String { infos[espece.id]?.nom ?? espece.id }

    func poidsKg(_ record: RecordEspece) -> Double? {
        poids(record.espece, record.longueurCm)?.kilos
    }

    var estVide: Bool { bilan.records.isEmpty && bilan.especesSansTaille.isEmpty }

    // MARK: Souvenirs déjà vus

    private func lireVus() -> [String: Double]? {
        guard let d = defauts?.dictionary(forKey: Self.cleVus) else { return nil }
        var vus: [String: Double] = [:]
        for (cle, valeur) in d {
            if let n = valeur as? Double { vus[cle] = n } else if let n = valeur as? NSNumber { vus[cle] = n.doubleValue }
        }
        return vus
    }

    private func calculerNouveaux() -> Set<String> {
        // Première ouverture : rien n'est « nouveau », sinon tout le Pescedex porterait le ruban.
        guard let vus = lireVus() else {
            ecrireVus()
            return []
        }
        return Set(bilan.records.filter { r in
            guard let ancien = vus[r.espece.id] else { return true }
            return MoteurRecords.millimetres(r.longueurCm) != MoteurRecords.millimetres(ancien)
        }.map(\.espece.id))
    }

    /// À appeler quand l'écran se ferme : les souvenirs affichés ne seront plus « nouveaux ».
    func marquerVus() {
        ecrireVus()
        nouveaux = []
    }

    private func ecrireVus() {
        let vus = Dictionary(bilan.records.map { ($0.espece.id, $0.longueurCm) }, uniquingKeysWith: { premier, _ in premier })
        defauts?.set(vus, forKey: Self.cleVus)
    }
}
