import CloudKit
import Foundation

/// Retrouver le compte iCloud d'un membre qui n'a pas (encore) d'`idCloudKit` : le chat de club (L24) en a besoin pour l'admettre
/// dans la zone partagée. // ⚠ à vérifier sur le Mac (écrit sans compilation).
///
/// Principe : le `ProfilPublic` d'un membre a pour `recordName` son identifiant de profil (`p-<surnom normalisé>`, L21), donc la
/// recherche « par surnom » est une lecture directe de cet enregistrement, sans les 20 résultats ni l'ambiguïté d'un préfixe.
/// Le compte retenu est le CRÉATEUR de l'enregistrement (`creatorUserRecordID`, posé par iCloud) : jamais un champ écrit par un
/// autre iPhone. Profil introuvable (pas encore créé, ou supprimé) : `nil`, ce n'est pas une erreur, le membre est « en attente ».
nonisolated protocol ResolveurIdentite: Sendable {
    /// Le compte iCloud propriétaire du profil public `profil`, ou `nil` s'il n'existe pas (encore) ou n'a pas de créateur lisible.
    /// Lève `ErreurClub.reseau` ou `.iCloudIndisponible` : l'appelant réessaiera plus tard, sans rien conclure.
    func idCloudKit(deProfil profil: String) async throws -> String?
}

/// Règles sur l'identité d'un membre, sans réseau.
nonisolated enum IdentiteMembre {
    /// Les membres de la démo locale (`DemoClub`, identifiants `demo-…`) ne sont pas des personnes : jamais admis dans une zone
    /// partagée. Un vrai profil commence toujours par `p-` (L21), donc aucune collision avec un vrai surnom.
    static func estExemple(_ profil: String) -> Bool { profil.hasPrefix("demo-") }

    /// L'identifiant retenu pour un `Membre` : celui lu par CloudKit sur son adhésion, sinon celui déjà vérifié via son profil.
    /// Vide ou absent : `nil`.
    static func idCloudKit(de membre: Membre, verifies: [String: String]) -> String? {
        if let direct = membre.idCloudKit, !direct.isEmpty { return direct }
        if let verifie = verifies[membre.profil], !verifie.isEmpty { return verifie }
        return nil
    }

    /// Un identifiant de créateur utilisable : non vide, et pas l'alias du propriétaire (`__defaultOwner__`), qui ne désigne personne ici.
    static func createurUtilisable(_ nom: String?) -> String? {
        guard let nom, !nom.isEmpty, nom != CKCurrentUserDefaultName else { return nil }
        return nom
    }
}

/// Le vrai résolveur : lit `ProfilPublic/<id>` en base publique.
actor ResolveurIdentiteCloudKit: ResolveurIdentite {
    private let conteneurPermis: CKContainer?

    init(conteneur: String = ConfigurationAmis.conteneurParDefaut) {
        self.conteneurPermis = CloudKitPermis.actif ? CKContainer(identifier: conteneur) : nil
    }

    func idCloudKit(deProfil profil: String) async throws -> String? {
        guard let conteneurPermis else { throw ErreurClub.iCloudIndisponible }
        do {
            let record = try await conteneurPermis.publicCloudDatabase.record(for: CKRecord.ID(recordName: profil))
            guard record.recordType == FabriqueProfil.typeProfil, record.recordID.recordName == profil else { return nil }
            return IdentiteMembre.createurUtilisable(record.creatorUserRecordID?.recordName)
        } catch let erreur as CKError where erreur.code == .unknownItem {
            return nil
        } catch {
            throw ServiceClubsCloudKit.traduire(error)
        }
    }
}

#if DEBUG
/// Faux résolveur pour les tests : une table profil -> compte, des profils « pas encore créés », un réseau qui tombe.
actor FauxResolveurIdentite: ResolveurIdentite {
    private var comptes: [String: String]
    private var horsLigne: Bool
    private(set) var appels: [String] = []

    init(comptes: [String: String] = [:], horsLigne: Bool = false) {
        self.comptes = comptes
        self.horsLigne = horsLigne
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }
    /// Le profil vient d'être créé.
    func creer(profil: String, compte: String) { comptes[profil] = compte }

    func idCloudKit(deProfil profil: String) async throws -> String? {
        appels.append(profil)
        if horsLigne { throw ErreurClub.reseau }
        return comptes[profil]
    }
}
#endif
