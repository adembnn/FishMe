import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget), comme InstantaneAquarium.swift.
// C'est tout ce que le widget « Ma carte » sait de la collection : l'app l'écrit dans le conteneur partagé (App Group),
// le widget le lit. Foundation seulement : ce fichier compile aussi sous Linux (tests).
// JAMAIS de lieu : ni coordonnées, ni station, ni département, ni nom de coin, ni date. Le widget est vu par d'autres.
// Les photos du verso sont ré-encodées sans métadonnées (donc sans GPS) par `PontCartesWidget.enregistrerPhoto`.

/// Ce que l'app donne au widget : les cartes du Pescedex que le pêcheur peut choisir, et la face montrée de chacune.
nonisolated public struct InstantaneCartes: Codable, Hashable, Sendable {
    /// Une carte du Pescedex. `slug` est le nom de l'image du poisson (« brochet », « perche-commune »).
    nonisolated public struct Carte: Codable, Hashable, Sendable, Identifiable {
        public var id: String
        public var slug: String
        /// 0 commun, 1 peu commun, 2 rare, 3 légendaire. Arrive tout fait de la collection, jamais recalculé ici.
        public var rarete: Int
        /// Nom de l'espèce, pour la liste de choix du widget SEULEMENT : il n'est jamais dessiné sur la carte.
        public var nom: String?
        /// Vrai si une photo du verso a été enregistrée (`cartes-photos/<id>.jpg`).
        public var aPhoto: Bool

        public init(id: String, slug: String, rarete: Int, nom: String? = nil, aPhoto: Bool = false) {
            self.id = id
            self.slug = slug
            self.rarete = min(max(rarete, 0), 3)
            self.nom = nom
            self.aPhoto = aPhoto
        }
    }

    /// Au plus `InstantaneCartes.plafond` cartes, les plus récentes d'abord.
    public var cartes: [Carte]
    /// id de la carte → vrai quand c'est le verso qui est montré. Absent = recto.
    public var faceVisible: [String: Bool]

    /// Plafond de la liste de choix : au-delà, la liste serait illisible et le fichier inutilement gros.
    public static let plafond = 60

    public init(cartes: [Carte], faceVisible: [String: Bool] = [:]) {
        let gardees = Array(cartes.prefix(Self.plafond))
        self.cartes = gardees
        let ids = Set(gardees.map(\.id))
        self.faceVisible = faceVisible.filter { ids.contains($0.key) }
    }

    /// Avant la première prise : aucune carte, le widget montre un emplacement vide.
    public static let vide = InstantaneCartes(cartes: [])

    public func carte(id: String) -> Carte? {
        cartes.first { $0.id == id }
    }

    /// Rien de choisi : la plus rare ; à rareté égale, la plus récente (la liste est triée du plus récent au plus ancien).
    public var laPlusRare: Carte? {
        var meilleure: Carte?
        for carte in cartes where carte.rarete > (meilleure?.rarete ?? -1) {
            meilleure = carte
        }
        return meilleure
    }

    public func verso(id: String) -> Bool {
        faceVisible[id] ?? false
    }
}

/// Lecture et écriture du fichier et des photos partagés entre l'app et le widget.
nonisolated public enum DepotCartesWidget {
    /// Même groupe que l'aquarium : une seule capacité App Groups.
    public static let groupe = DepotAquariumWidget.groupe
    public static let nomFichier = "cartes-widget.json"
    public static let nomDossierPhotos = "cartes-photos"
    /// Nom du widget, pour `WidgetCenter.shared.reloadTimelines(ofKind:)` côté app.
    public static let genre = "FishMeCarte"

    /// `nil` hors App Group (Linux, tests, capacité absente) : on ne plante jamais.
    public static func racine(groupe: String = groupe) -> URL? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupe)
        #else
        nil
        #endif
    }

    public static func url(groupe: String = groupe) -> URL? {
        racine(groupe: groupe)?.appendingPathComponent(nomFichier)
    }

    public static func dossierPhotos(groupe: String = groupe) -> URL? {
        racine(groupe: groupe)?.appendingPathComponent(nomDossierPhotos, isDirectory: true)
    }

    /// L'id ne sert qu'à nommer un fichier : on refuse tout ce qui pourrait sortir du dossier.
    private static func idSur(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 80 && id.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    public static func urlPhoto(id: String, dossier: URL? = dossierPhotos()) -> URL? {
        guard idSur(id) else { return nil }
        return dossier?.appendingPathComponent("\(id).jpg")
    }

    public static func lire(depuis url: URL? = url()) -> InstantaneCartes {
        guard let url, let donnees = try? Data(contentsOf: url),
              let instantane = try? JSONDecoder().decode(InstantaneCartes.self, from: donnees)
        else { return .vide }
        return instantane
    }

    public static func ecrire(_ instantane: InstantaneCartes, vers url: URL? = url()) throws {
        guard let url else { return }
        let encodeur = JSONEncoder()
        encodeur.outputFormatting = [.sortedKeys]
        try encodeur.encode(instantane).write(to: url, options: [.atomic])
    }

    /// Écrit une photo déjà nettoyée (JPEG sans métadonnées). Crée le dossier au besoin.
    public static func ecrirePhoto(_ jpeg: Data, id: String, dossier: URL? = dossierPhotos()) throws {
        guard let dossier, let cible = urlPhoto(id: id, dossier: dossier) else { return }
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try jpeg.write(to: cible, options: [.atomic])
    }

    public static func supprimerPhoto(id: String, dossier: URL? = dossierPhotos()) {
        guard let cible = urlPhoto(id: id, dossier: dossier) else { return }
        try? FileManager.default.removeItem(at: cible)
    }

    /// Les ids dont une photo existe sur le disque (pour ranger les photos orphelines).
    public static func idsDesPhotos(dossier: URL? = dossierPhotos()) -> [String] {
        guard let dossier,
              let fichiers = try? FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
        else { return [] }
        return fichiers.filter { $0.pathExtension == "jpg" }.map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Montre l'autre face de la carte. Ne fait rien si le fichier est illisible ou si la carte n'existe plus.
    @discardableResult
    public static func retourner(id: String, depuis url: URL? = url()) -> Bool {
        var instantane = lire(depuis: url)
        guard instantane.carte(id: id) != nil else { return false }
        instantane.faceVisible[id] = !(instantane.faceVisible[id] ?? false)
        do {
            try ecrire(instantane, vers: url)
            return true
        } catch {
            return false
        }
    }
}
