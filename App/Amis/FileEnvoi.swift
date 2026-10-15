import Foundation

/// La file d'envoi : ce qui n'est pas encore parti vers iCloud, gardé sur disque pour être rejoué (hors ligne, app tuée).
/// Garde aussi l'état du partage : actif ou non, et les cartes déjà envoyées.
actor FileEnvoi {
    nonisolated struct Etat: Codable, Equatable, Sendable {
        var partageActif = false
        var envoyees: Set<UUID> = []
        var enAttente: [CartePartagee] = []
    }

    private let dossier: URL
    private var etat: Etat

    init(dossier: URL) {
        self.dossier = dossier
        try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let donnees = try? Data(contentsOf: dossier.appendingPathComponent("etat.json"))
        self.etat = donnees.flatMap { try? JSONDecoder().decode(Etat.self, from: $0) } ?? Etat()
    }

    static func dossierParDefaut() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Amis", isDirectory: true)
    }

    var partageActif: Bool { etat.partageActif }
    var envoyees: Set<UUID> { etat.envoyees }
    var nombreEnAttente: Int { etat.enAttente.count }

    func activerPartage() {
        etat.partageActif = true
        sauvegarder()
    }

    /// Ajoute des cartes à envoyer. Une carte déjà envoyée ou déjà en attente n'est pas ajoutée deux fois.
    func mettreEnAttente(_ cartes: [CartePartagee]) {
        let connues = etat.envoyees.union(etat.enAttente.map(\.id))
        for carte in cartes where !connues.contains(carte.id) {
            if let image = carte.image {
                try? image.write(to: fichierImage(carte.id), options: [.atomic, .completeFileProtection])
            }
            etat.enAttente.append(carte)
        }
        sauvegarder()
    }

    /// Les cartes à envoyer, avec leur image relue du disque.
    func enAttente() -> [CartePartagee] {
        etat.enAttente.map { carte in
            var avecImage = carte
            avecImage.image = try? Data(contentsOf: fichierImage(carte.id))
            return avecImage
        }
    }

    func marquerEnvoyees(_ ids: [UUID]) {
        etat.envoyees.formUnion(ids)
        etat.enAttente.removeAll { ids.contains($0.id) }
        for id in ids { try? FileManager.default.removeItem(at: fichierImage(id)) }
        sauvegarder()
    }

    /// « Supprimer mes cartes partagées » : le partage s'arrête, la file et la mémoire des envois sont vidées.
    func toutOublier() {
        for carte in etat.enAttente { try? FileManager.default.removeItem(at: fichierImage(carte.id)) }
        etat = Etat()
        sauvegarder()
    }

    private func fichierImage(_ id: UUID) -> URL {
        dossier.appendingPathComponent("\(id.uuidString).png")
    }

    private func sauvegarder() {
        guard let donnees = try? JSONEncoder().encode(etat) else { return }
        try? donnees.write(to: dossier.appendingPathComponent("etat.json"), options: [.atomic, .completeFileProtection])
    }
}
