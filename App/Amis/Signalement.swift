import Foundation

/// Règle 1.2 d'Apple : signaler un contenu, vers le contact publié dans Mon club. Un e-mail prérempli, sans texte libre de l'ami.
nonisolated enum Signalement {
    /// Seuls l'identifiant de la carte et celui de l'ami partent : jamais de coordonnée.
    static func url(contact: String, ami: Ami, carte: CartePartagee? = nil) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        var corps = "Ami : \(ami.id)"
        if let carte { corps += "\nCarte : \(carte.id.uuidString)" }
        composants.queryItems = [
            URLQueryItem(name: "subject", value: carte == nil ? "Signalement d'un ami" : "Signalement d'une carte"),
            URLQueryItem(name: "body", value: corps),
        ]
        return composants.url
    }
}
