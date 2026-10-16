//
//  ReglesAJour.swift
//  L11 : les règles à jour sans nouvelle version de l'app.
//
//  Au lancement, `MiseAJourRegles` (Core) lit `index.json`, contrôle les sha256 et remplace les fichiers de
//  département changés, un par un. Les copies vivent dans Application Support ; le moteur de règles les lit au
//  lancement suivant (`DonneesMoteur.embarque(reglesTelechargees:)`). Rien de ce qui touche à la position du pêcheur
//  ne part : mêmes fichiers demandés à tout le monde, aucune requête, aucun cookie.
//
//  Adresse de publication : clé Info `ReglesBaseURL` (vide tant qu'Adem n'a pas choisi l'hébergement ; défaut de
//  docs/fiches/L11.md : dépôt GitHub public à part servi par GitHub Pages). Vide : l'app garde ses règles embarquées.
//

import Core
import Foundation

enum ReglesAJour {
    /// Dossier des copies téléchargées. À passer à `DonneesMoteur.embarque(reglesTelechargees:)` dans `ParcoursApp.init`.
    nonisolated static var dossierCopies: URL {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("regles-telechargees", isDirectory: true)
    }

    /// L'adresse de base lue dans Info.plist (`ReglesBaseURL`), ou `nil` si vide ou illisible. Uniquement en https.
    static func adresse(info: [String: Any]? = Bundle.main.infoDictionary) -> URL? {
        guard let texte = (info?["ReglesBaseURL"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !texte.isEmpty, let url = URL(string: texte), url.scheme == "https" else { return nil }
        return url
    }

    /// Une mise à jour au lancement. Ne lève jamais d'erreur et ne bloque rien : à appeler depuis `demarrer()`.
    /// Rend le rapport pour les journaux et les tests.
    @discardableResult
    static func lancer(telechargeur: (any TelechargeFichier)? = nil, embarque: URL? = nil,
                       copies: URL = dossierCopies) async -> RapportMiseAJour {
        let source = telechargeur ?? TelechargeFichierHTTP(base: adresse())
        let maj = MiseAJourRegles(telechargeur: source, embarque: embarque ?? CatalogueRegles.dossierEmbarque, copies: copies)
        return await maj.mettreAJour()
    }
}

#if DEBUG
extension ReglesAJour {
    /// Faux serveur pour les essais : sert les fichiers donnés, rien d'autre. Jamais dans le build envoyé à Apple.
    static func fauxServeur(_ fichiers: [String: Data], enLigne: Bool = true) -> TelechargeFichierFaux {
        TelechargeFichierFaux(fichiers: fichiers, enLigne: enLigne)
    }
}
#endif
