import Foundation

/// Règle 1.2 d'Apple : signaler un contenu, vers le contact publié dans Mon club. Un e-mail prérempli, sans texte libre de l'ami.
nonisolated enum Signalement {
    /// Seuls l'identifiant de la carte et celui de l'ami partent : jamais de coordonnée.
    static func url(contact: String, ami: Ami, carte: CartePartagee? = nil, motif: MotifSignalement? = nil) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        var corps = "Ami : \(ami.id)"
        if let carte { corps += "\nCarte : \(carte.id.uuidString)" }
        if let motif { corps += "\nMotif : \(motif.titre)" }
        composants.queryItems = [
            URLQueryItem(name: "subject", value: carte == nil ? "Signalement d'un ami" : "Signalement d'une carte"),
            URLQueryItem(name: "body", value: corps),
        ]
        return composants.url
    }

    /// Signaler un profil : l'identifiant public du profil et le motif (liste fermée). Rien d'autre ne part.
    static func url(contact: String, profilID: String, motif: MotifSignalement) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        composants.queryItems = [
            URLQueryItem(name: "subject", value: "Signalement d'un profil"),
            URLQueryItem(name: "body", value: "Profil : \(profilID)\nMotif : \(motif.titre)"),
        ]
        return composants.url
    }
}
