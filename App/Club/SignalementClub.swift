import Foundation

/// Signaler une carte de club (règle 1.2 d'Apple, décision 5) : un e-mail prérempli à l'adresse publiée, plus un `Signalement` en base publique.
/// Seuls l'identifiant de la carte, celui de son auteur, celui du club et le motif (liste fermée) partent. Jamais de coordonnée, jamais de texte libre.
/// ⚠ L'e-mail n'est pas automatique (R2, `moderation.md`) : la personne doit l'envoyer ; l'enregistrement `Signalement` est la trace sûre.
nonisolated enum SignalementClub {
    static func url(contact: String = ContactClub.adresse, carte: CartePartageeClub, motif: MotifSignalement) -> URL? {
        guard !contact.isEmpty else { return nil }
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        let corps = "Carte : \(carte.id)\nAuteur : \(carte.auteur)\nClub : \(carte.club)\nMotif : \(motif.titre)"
        composants.queryItems = [
            URLQueryItem(name: "subject", value: "Signalement d'une carte de club"),
            URLQueryItem(name: "body", value: corps),
        ]
        return composants.url
    }

    /// Signaler le club lui-même (nom ou image).
    static func url(contact: String = ContactClub.adresse, club: Club, motif: MotifSignalement) -> URL? {
        guard !contact.isEmpty else { return nil }
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = contact
        composants.queryItems = [
            URLQueryItem(name: "subject", value: "Signalement d'un club"),
            URLQueryItem(name: "body", value: "Club : \(club.id)\nFondateur : \(club.fondateur)\nMotif : \(motif.titre)"),
        ]
        return composants.url
    }
}

/// Les cartes que j'ai signalées : masquées chez moi tout de suite (étape 2 du circuit de `moderation.md`).
/// Un filtre local, sur l'iPhone ; le profil de l'auteur, lui, se masque ou se bloque par `BlocagesProfils` (L21).
nonisolated struct CartesMasquees: Sendable {
    var cle: String = "club.cartesMasquees"

    func ids() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: cle) ?? []) }
    func estMasquee(_ id: String) -> Bool { ids().contains(id) }

    func masquer(_ id: String) {
        UserDefaults.standard.set(Array(ids().union([id])).sorted(), forKey: cle)
    }
}
