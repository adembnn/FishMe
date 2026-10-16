import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget), avec `Widget/Session/EtatSession.swift`.
// C'est tout ce que le widget « Ma session » sait de la session : l'app écrit un `EtatSession?` dans le conteneur
// partagé (App Group), le widget le lit. Foundation seulement : ce fichier compile aussi sous Linux (tests).
// JAMAIS de lieu : ni coordonnées, ni station, ni nom de coin. Le widget est vu par d'autres.
// `nil` = pas de session en cours.

/// Lecture et écriture du fichier partagé entre l'app et le widget « Ma session ».
nonisolated public enum DepotSessionWidget {
    public static let nomFichier = "session-widget.json"
    /// Nom du widget, pour `WidgetCenter.shared.reloadTimelines(ofKind:)` côté app.
    public static let genre = "FishMeSession"

    /// `nil` hors App Group (Linux, tests, capacité absente) : on ne plante jamais.
    public static func url(groupe: String = DepotAquariumWidget.groupe) -> URL? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupe)?
            .appendingPathComponent(nomFichier)
        #else
        nil
        #endif
    }

    /// Fichier absent, vide ou illisible : pas de session (jamais d'erreur, jamais de fausse session).
    public static func lire(depuis url: URL? = url()) -> EtatSession? {
        guard let url, let donnees = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.sessionWidget.decode(EtatSession.self, from: donnees)
    }

    /// `nil` efface le fichier : la session est finie.
    public static func ecrire(_ etat: EtatSession?, vers url: URL? = url()) throws {
        guard let url else { return }
        guard let etat else {
            if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
            return
        }
        let donnees = try JSONEncoder.sessionWidget.encode(etat)
        try donnees.write(to: url, options: [.atomic])
    }
}

/// Ce que le widget montre, et quand il doit être redessiné. Type pur, testé sous Linux.
nonisolated public struct AffichageSessionWidget: Equatable, Sendable {
    nonisolated public enum Contenu: Equatable, Sendable {
        /// Aucune session : invitation sobre.
        case aucuneSession
        /// Le système fait tourner le chrono jusqu'à la fin légale.
        case compteARebours(debut: Date, fin: Date)
        /// La fin légale est passée : heure fixe, en orange.
        case finLegalePassee(Date)
        /// Départ hors de la fenêtre légale.
        case pecheFermee
        /// Pas d'heure de fin : durée écoulée seulement.
        case finInconnue(depuis: Date)
    }

    public var contenu: Contenu
    public var prises: Int

    public init(contenu: Contenu, prises: Int) {
        self.contenu = contenu
        self.prises = prises
    }

    /// Ce qu'il faut montrer à `maintenant`.
    public static func calculer(etat: EtatSession?, maintenant: Date) -> AffichageSessionWidget {
        guard let etat else { return AffichageSessionWidget(contenu: .aucuneSession, prises: 0) }
        let prises = max(etat.prises, 0)
        switch etat.affichage(maintenant: maintenant, perime: false) {
        case .compteARebours(let fin): return .init(contenu: .compteARebours(debut: etat.debut, fin: fin), prises: prises)
        case .finLegale(let fin): return .init(contenu: .finLegalePassee(fin), prises: prises)
        case .pecheFermee: return .init(contenu: .pecheFermee, prises: prises)
        case .finInconnue(let depuis): return .init(contenu: .finInconnue(depuis: depuis), prises: prises)
        }
    }

    /// Dates des entrées de la timeline : maintenant, puis la fin légale si elle est encore à venir ; sinon rien d'autre.
    public static func datesTimeline(etat: EtatSession?, maintenant: Date) -> [Date] {
        guard let etat, let fin = etat.finLegale, fin > etat.debut, fin > maintenant else { return [maintenant] }
        return [maintenant, fin]
    }
}

extension JSONEncoder {
    nonisolated static var sessionWidget: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }
}

extension JSONDecoder {
    nonisolated static var sessionWidget: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
