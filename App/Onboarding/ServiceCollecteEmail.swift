import Foundation

/// Envoie (ou retire) l'e-mail qu'un pêcheur a consenti à donner. L'implémentation de production vise un point de terminaison
/// HTTPS lu dans la clé Info `FishMeCollecteURL` ; clé vide : rien n'est envoyé et rien n'est simulé.
nonisolated protocol ServiceCollecteEmail: Sendable {
    /// Vrai si le serveur a reçu l'adresse. Faux (sans erreur) quand aucun point de terminaison n'est configuré.
    func envoyer(email: String, langue: String) async -> Bool
    /// Demande au serveur d'effacer l'adresse (Apple 5.1.1(v)). Même règle : sans point de terminaison, rien ne part.
    func supprimer(email: String) async -> Bool
}

/// La clé Info `FishMeCollecteURL` : https obligatoire, jamais d'adresse en dur dans le code.
nonisolated enum ConfigCollecteEmail {
    static let cle = "FishMeCollecteURL"

    static func url(bundle: Bundle = .main) -> URL? { url(brute: bundle.object(forInfoDictionaryKey: cle) as? String) }

    static func url(brute: String?) -> URL? {
        guard let texte = brute?.trimmingCharacters(in: .whitespacesAndNewlines), !texte.isEmpty,
              let url = URL(string: texte), url.scheme?.lowercased() == "https", url.host?.isEmpty == false else { return nil }
        return url
    }
}

/// La production : un POST JSON vers l'adresse configurée. Aucune autre donnée que l'e-mail et la langue.
nonisolated struct CollecteEmailHTTP: ServiceCollecteEmail {
    var url: URL?
    var envoyeur: @Sendable (URLRequest) async -> Bool = { requete in
        guard let (_, reponse) = try? await URLSession.shared.data(for: requete),
              let http = reponse as? HTTPURLResponse else { return false }
        return (200..<300).contains(http.statusCode)
    }

    init(url: URL? = ConfigCollecteEmail.url(), envoyeur: (@Sendable (URLRequest) async -> Bool)? = nil) {
        self.url = url
        if let envoyeur { self.envoyeur = envoyeur }
    }

    func envoyer(email: String, langue: String) async -> Bool {
        await poster(["action": "inscription", "email": email, "langue": langue])
    }

    func supprimer(email: String) async -> Bool {
        await poster(["action": "suppression", "email": email])
    }

    private func poster(_ corps: [String: String]) async -> Bool {
        guard let url, let donnees = try? JSONSerialization.data(withJSONObject: corps) else { return false }
        var requete = URLRequest(url: url, timeoutInterval: 15)
        requete.httpMethod = "POST"
        requete.setValue("application/json", forHTTPHeaderField: "Content-Type")
        requete.httpBody = donnees
        return await envoyeur(requete)
    }
}
