import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget), comme EtatSession.swift.
// C'est tout ce que le widget sait de l'aquarium : l'app l'écrit dans le conteneur partagé (App Group),
// le widget le lit. Foundation seulement : ce fichier compile aussi sous Linux (tests).
// JAMAIS de lieu : ni coordonnées, ni station, ni département, ni nom de coin. Le widget est vu par d'autres.

/// Ce que l'app donne au widget : TOUT le Pescedex (les plus rares d'abord), les rations, l'abonnement.
/// C'est le pêcheur qui choisit, par « Modifier le widget », lesquels nagent (4 ou 5 au plus).
nonisolated public struct InstantaneAquarium: Codable, Hashable, Sendable {
    /// Un poisson du widget. `slug` est le nom de l'image (« brochet », « perche-commune »),
    /// la silhouette s'appelle « <slug>-silhouette ».
    nonisolated public struct Poisson: Codable, Hashable, Sendable, Identifiable {
        public var id: String
        public var slug: String
        /// 0 commun, 1 peu commun, 2 rare, 3 légendaire. Arrive tout fait de la collection, jamais recalculé ici.
        public var rarete: Int
        public var relache: Bool
        /// Prises de la même espèce regroupées dans ce poisson (≥ 1).
        public var nombre: Int
        /// Nom commun de l'espèce (« Brochet »). Sert seulement à la liste de choix de « Modifier le widget » :
        /// jamais affiché dans le widget. Absent des anciens fichiers.
        public var nom: String?

        public init(id: String, slug: String, rarete: Int, relache: Bool, nombre: Int = 1, nom: String? = nil) {
            self.id = id
            self.slug = slug
            self.rarete = min(max(rarete, 0), 3)
            self.relache = relache
            self.nombre = max(nombre, 1)
            self.nom = nom
        }

        private enum CodingKeys: String, CodingKey {
            case id, slug, rarete, relache, nombre, nom
        }

        /// Décodage tolérant : un ancien fichier (sans `nom`, voire sans `nombre`) se lit quand même.
        public init(from decodeur: Decoder) throws {
            let c = try decodeur.container(keyedBy: CodingKeys.self)
            self.init(
                id: try c.decode(String.self, forKey: .id),
                slug: try c.decode(String.self, forKey: .slug),
                rarete: try c.decodeIfPresent(Int.self, forKey: .rarete) ?? 0,
                relache: try c.decodeIfPresent(Bool.self, forKey: .relache) ?? true,
                nombre: try c.decodeIfPresent(Int.self, forKey: .nombre) ?? 1,
                nom: try c.decodeIfPresent(String.self, forKey: .nom)
            )
        }
    }

    /// Au plus `InstantaneAquarium.plafond` poissons (tout le Pescedex), triés : les plus rares d'abord.
    public var poissons: [Poisson]
    /// Nombre d'espèces différentes prises (pour le petit chiffre du widget).
    public var especes: Int
    /// Rations restantes : elles se gagnent en sessions, dans l'app.
    public var rations: Int
    /// Abonnement Pro actif au moment de l'écriture.
    public var estPro: Bool
    /// Dernière ration donnée (depuis l'app ou le widget). Sert à faire monter les poissons.
    public var dernierRepas: Date?
    public var misAJour: Date
    /// Décor d'aquarium (N1) : l'identifiant DÉJÀ corrigé par l'app (`ChoixSkin.affiche` : saison finie ou Pro perdu = repli).
    /// Absent d'un ancien fichier = `riviere` (décor de départ). Le widget ne calcule ni date ni abonnement.
    /// Décodage tolérant : champ optionnel, donc un fichier sans `skin` se lit.
    public var skin: String?

    /// Le décor à dessiner : `skin` s'il est renseigné, sinon le décor de départ.
    public var skinEffectif: String { FondWidget.identifiantSain(skin) }

    /// Le fichier porte tout le Pescedex, jusqu'à 200 entrées. Ce que le widget montre est bien plus petit
    /// (voir `limiteAffichee`) : le reste ne sert qu'à la liste de choix.
    public static let plafond = 200

    /// Combien de poissons nagent dans un widget : 3 dans le petit, 5 dans tous les autres.
    public static func limiteAffichee(petit: Bool) -> Int { petit ? 3 : 5 }

    /// Les poissons qui nagent : ceux choisis, dans l'ordre choisi, qui existent encore ici (un id disparu
    /// est ignoré, un id en double compte une fois) ; rien de choisi → les plus rares d'abord (l'ordre du fichier,
    /// déjà trié par l'app). Jamais plus de `limite`.
    public func retenus(choisis ids: [String]?, limite: Int) -> [Poisson] {
        let limite = max(limite, 0)
        guard let ids, !ids.isEmpty else { return Array(poissons.prefix(limite)) }
        let parId = Dictionary(poissons.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        var vus = Set<String>()
        var resultat: [Poisson] = []
        for id in ids where vus.insert(id).inserted {
            if let poisson = parId[id] { resultat.append(poisson) }
            if resultat.count == limite { break }
        }
        // Tous les choix ont disparu (cartes supprimées) : on retombe sur les plus rares plutôt que sur une eau vide.
        return resultat.isEmpty ? Array(poissons.prefix(limite)) : resultat
    }

    public init(poissons: [Poisson], especes: Int, rations: Int, estPro: Bool, dernierRepas: Date? = nil, misAJour: Date = .now, skin: String? = nil) {
        self.poissons = Array(poissons.prefix(Self.plafond))
        self.especes = max(especes, 0)
        self.rations = max(rations, 0)
        self.estPro = estPro
        self.dernierRepas = dernierRepas
        self.misAJour = misAJour
        self.skin = skin
    }

    /// Avant la première prise : l'aquarium est vide, le widget invite à pêcher.
    public static let vide = InstantaneAquarium(poissons: [], especes: 0, rations: 0, estPro: false, misAJour: .distantPast)

    /// Donne une ration si possible. Rend `false` (et ne change rien) quand il n'y en a plus.
    public mutating func nourrir(maintenant: Date) -> Bool {
        guard rations > 0 else { return false }
        rations -= 1
        dernierRepas = maintenant
        return true
    }
}

/// Lecture et écriture du fichier partagé entre l'app et le widget.
nonisolated public enum DepotAquariumWidget {
    /// À créer sur le Mac (capacité App Groups, sur les deux cibles). Voir docs/mac-a-faire/L15-widget-aquarium.md.
    public static let groupe = "group.ai.mwm.build.challenge.team.01"
    public static let nomFichier = "aquarium-widget.json"
    /// Nom du widget, pour `WidgetCenter.shared.reloadTimelines(ofKind:)` côté app.
    public static let genre = "FishMeAquarium"

    /// `nil` hors App Group (Linux, tests, capacité absente) : on ne plante jamais.
    public static func url(groupe: String = groupe) -> URL? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupe)?
            .appendingPathComponent(nomFichier)
        #else
        nil
        #endif
    }

    public static func lire(depuis url: URL? = url()) -> InstantaneAquarium {
        guard let url, let donnees = try? Data(contentsOf: url),
              let instantane = try? JSONDecoder.aquarium.decode(InstantaneAquarium.self, from: donnees)
        else { return .vide }
        return instantane
    }

    public static func ecrire(_ instantane: InstantaneAquarium, vers url: URL? = url()) throws {
        guard let url else { return }
        let donnees = try JSONEncoder.aquarium.encode(instantane)
        try donnees.write(to: url, options: [.atomic])
    }
}

extension JSONEncoder {
    nonisolated static var aquarium: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }
}

extension JSONDecoder {
    nonisolated static var aquarium: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
