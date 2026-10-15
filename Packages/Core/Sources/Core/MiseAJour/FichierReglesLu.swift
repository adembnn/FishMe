import Foundation

/// Pourquoi un fichier de règles est refusé. Le fichier déjà présent reste en place et les autres fichiers passent.
public enum RaisonRefus: Error, Sendable, Equatable {
    /// Le téléchargement a échoué (réseau coupé, fichier absent, adresse non réglée).
    case telechargement
    /// Pas du JSON, ou coupé en route.
    case illisible
    /// L'empreinte ne correspond pas à celle de `index.json`.
    case sha256Different
    /// La forme de `donnees.md` n'est pas respectée (le détail est dans le message).
    case formeInvalide(String)
    /// Le fichier annonce un autre département que celui de l'index.
    case autreDepartement
    /// La `version` n'est pas plus récente que celle de la copie.
    case pasPlusRecent
}

/// Une règle lue dans un fichier, avec ce qu'il faut pour la périmer ou la signaler.
struct RegleLue: Sendable, Equatable {
    var id: String
    var type: String
    var especes: [String]
    var phrase: String
    var citation: String
    var sources: [SourceRegle]
    var expireLe: String?
    var dateLecture: String?
}

/// Ce qu'on retient d'un fichier valide.
struct FichierReglesLu: Sendable, Equatable {
    var version: VersionRegles
    var departement: String
    var niveau: NiveauCouverture
    var regles: [RegleLue]
    var nombreAVerifier: Int
    /// La plus récente des dates `lu_le` de ses textes (« aaaa-mm-jj »).
    var dernierLu: String?

    /// Le plus petit `expire_le` des règles, ou `nil` si aucune n'expire.
    var expireMin: String? { regles.compactMap(\.expireLe).min() }

    /// Lit et contrôle un fichier : JSON lisible, forme de `donnees.md`, chaque règle avec ses textes, sa citation,
    /// et `expire_le` ; chaque texte avec sa date `lu_le`. Une valeur en forme v1 est refusée.
    static func lire(_ data: Data) throws -> FichierReglesLu {
        guard let objet = try? JSONSerialization.jsonObject(with: data), let racine = objet as? [String: Any] else {
            throw RaisonRefus.illisible
        }
        func invalide(_ message: String) -> RaisonRefus { .formeInvalide(message) }

        guard let versionTexte = racine["version"] as? String, let version = VersionRegles(versionTexte) else {
            throw invalide("version absente ou mal formée")
        }
        guard let departement = racine["departement"] as? String, !departement.isEmpty else {
            throw invalide("departement absent")
        }
        guard let niveauTexte = racine["niveau"] as? String, let niveau = NiveauCouverture(rawValue: niveauTexte) else {
            throw invalide("niveau absent ou inconnu")
        }
        guard let textes = racine["textes"] as? [[String: Any]] else { throw invalide("textes absent") }
        guard racine["eaux"] is [Any] else { throw invalide("eaux absent") }
        guard let aVerifier = racine["a_verifier"] as? [Any] else { throw invalide("a_verifier absent") }
        guard let regles = racine["regles"] as? [[String: Any]] else { throw invalide("regles absent") }

        var textesParId: [String: (source: SourceRegle, luLe: String)] = [:]
        for texte in textes {
            guard let id = texte["id"] as? String, !id.isEmpty,
                  let titre = texte["titre"] as? String, !titre.isEmpty,
                  let luLe = texte["lu_le"] as? String, Jours.date(iso: luLe) != nil else {
                throw invalide("un texte sans id, titre ou lu_le")
            }
            guard textesParId[id] == nil else { throw invalide("texte \(id) en double") }
            let url = texte["url"] as? String
            textesParId[id] = (SourceRegle(titre: titre, url: url), luLe)
        }

        let clesV1: Set<String> = ["periodes", "total", "domaine", "secteurs"]
        var lues: [RegleLue] = []
        var ids = Set<String>()
        for regle in regles {
            guard let id = regle["id"] as? String, !id.isEmpty else { throw invalide("une règle sans id") }
            guard ids.insert(id).inserted else { throw invalide("règle \(id) en double") }
            guard let type = regle["type"] as? String, !type.isEmpty else { throw invalide("\(id) : type absent") }
            guard let phrase = regle["phrase"] as? String, !phrase.isEmpty else { throw invalide("\(id) : phrase absente") }
            guard let citation = regle["citation"] as? String,
                  !citation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw invalide("\(id) : citation absente")
            }
            guard let cites = regle["textes"] as? [String], !cites.isEmpty else { throw invalide("\(id) : aucun texte cité") }
            var sources: [SourceRegle] = []
            var lectures: [String] = []
            for cite in cites {
                guard let texte = textesParId[cite] else { throw invalide("\(id) : texte \(cite) inconnu") }
                sources.append(texte.source)
                lectures.append(texte.luLe)
            }
            guard regle.keys.contains("expire_le") else { throw invalide("\(id) : expire_le absent") }
            var expire: String?
            if !(regle["expire_le"] is NSNull) {
                guard let texte = regle["expire_le"] as? String, Jours.date(iso: texte) != nil else {
                    throw invalide("\(id) : expire_le mal formé")
                }
                expire = texte
            }
            if let valeur = regle["valeur"] as? [String: Any], !clesV1.isDisjoint(with: valeur.keys) {
                throw invalide("\(id) : valeur en forme v1")
            }
            let especes = (regle["especes"] as? [Any])?.map { "\($0)" } ?? []
            lues.append(RegleLue(id: id, type: type, especes: especes, phrase: phrase, citation: citation,
                                 sources: sources, expireLe: expire, dateLecture: lectures.max()))
        }

        return FichierReglesLu(version: version, departement: departement, niveau: niveau, regles: lues,
                             nombreAVerifier: aVerifier.count,
                             dernierLu: textesParId.values.map(\.luLe).max())
    }
}
