import CloudKit
import Core
import Foundation

/// Fabrique les `CKRecord` du fil et les relit. Seules les clés listées existent : un test le prouve.
/// Aucune clé de lieu exact (latitude, longitude, altitude, nom de plan d'eau interrogeable) : `schema.md`, « Règles qui valent pour tous les types ».
nonisolated enum FabriqueFeed {
    static let typePublication = "Publication"
    static let typeLike = "Like"
    static let typeCommentaire = "Commentaire"
    static let typeSignalement = "Signalement"
    static let typeBlocage = "Blocage"

    static let clesPublication: Set<String> = [
        "auteur", "auteurNom", "media", "genre", "vignette", "dureeS", "legende", "lieuMode", "lieuTexte", "departement",
        "espece", "rarete", "tailleCm", "club", "creeLe",
    ]
    static let clesLike: Set<String> = ["publication", "auteurNom", "creeLe"]
    static let clesCommentaire: Set<String> = ["publication", "auteurNom", "texte", "creeLe"]
    static let clesSignalement: Set<String> = ["cible", "typeCible", "motif", "signalePar", "creeLe"]
    static let clesBlocage: Set<String> = ["bloque", "creeLe"]
    /// Les clés qu'on lit pour afficher le fil : sans `media`, qui ne se télécharge qu'à l'affichage.
    static var clesDuFil: [String] { clesPublication.subtracting(["media"]).sorted() }

    static func identifiantLike(publication: String, auteur: String) -> String { "l-\(publication)-\(auteur)" }

    // MARK: Écriture

    static func record(pour b: BrouillonPublication, maintenant: Date = Date()) -> CKRecord {
        let r = CKRecord(recordType: typePublication, recordID: CKRecord.ID(recordName: b.id))
        r["auteur"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: b.auteurNom), action: .none)
        r["auteurNom"] = b.auteurNom
        r["media"] = CKAsset(fileURL: b.fichierMedia)
        r["genre"] = b.genre.rawValue
        r["vignette"] = CKAsset(fileURL: b.vignette)
        r["dureeS"] = b.dureeS
        r["legende"] = b.legende
        r["lieuMode"] = b.lieu.mode.rawValue
        r["lieuTexte"] = b.lieu.lieuTexte
        r["departement"] = b.lieu.departement
        if let carte = b.carte {
            r["espece"] = carte.espece
            r["rarete"] = carte.rarete.rawValue
            if let taille = carte.tailleCm { r["tailleCm"] = taille }
        }
        r["club"] = b.club
        r["creeLe"] = maintenant
        return r
    }

    static func recordLike(publication: String, auteur: String, maintenant: Date = Date()) -> CKRecord {
        let r = CKRecord(recordType: typeLike, recordID: CKRecord.ID(recordName: identifiantLike(publication: publication, auteur: auteur)))
        r["publication"] = publication
        r["auteurNom"] = auteur
        r["creeLe"] = maintenant
        return r
    }

    static func record(pour c: CommentaireFeed) -> CKRecord {
        let r = CKRecord(recordType: typeCommentaire, recordID: CKRecord.ID(recordName: c.id))
        r["publication"] = c.publication
        r["auteurNom"] = c.auteurNom
        r["texte"] = c.texte
        r["creeLe"] = c.creeLe
        return r
    }

    static func record(pour s: SignalementFeed, maintenant: Date = Date()) -> CKRecord {
        let r = CKRecord(recordType: typeSignalement, recordID: CKRecord.ID(recordName: s.id))
        r["cible"] = s.cible
        r["typeCible"] = s.typeCible.rawValue
        r["motif"] = s.motif.rawValue
        r["signalePar"] = s.signalePar
        r["creeLe"] = maintenant
        return r
    }

    /// Base privée du pêcheur : une liste publique de « qui a bloqué qui » nourrirait le harcèlement (`schema.md`, type 9).
    static func recordBlocage(_ auteur: String, maintenant: Date = Date()) -> CKRecord {
        let r = CKRecord(recordType: typeBlocage, recordID: CKRecord.ID(recordName: "b-\(auteur)"))
        r["bloque"] = auteur
        r["creeLe"] = maintenant
        return r
    }

    // MARK: Lecture

    static func publication(depuis r: CKRecord) -> PublicationFeed? {
        guard r.recordType == typePublication,
              let auteur = r["auteurNom"] as? String,
              let genre = (r["genre"] as? String).flatMap(GenreMedia.init(rawValue:)),
              let mode = (r["lieuMode"] as? String).flatMap(ModeLieu.init(rawValue:)),
              let date = r["creeLe"] as? Date else { return nil }
        return PublicationFeed(
            id: r.recordID.recordName, auteurNom: auteur, genre: genre, dureeS: min(max(r["dureeS"] as? Int ?? 0, 0), 600),
            legende: r["legende"] as? String ?? "", lieuMode: mode, lieuTexte: r["lieuTexte"] as? String ?? "",
            departement: r["departement"] as? String ?? "", espece: r["espece"] as? String,
            rarete: (r["rarete"] as? String).flatMap(NiveauRarete.init(rawValue:)), tailleCm: tailleSure(r["tailleCm"] as? Double),
            club: r["club"] as? String ?? "", creeLe: date, vignette: (r["vignette"] as? CKAsset)?.fileURL)
    }

    /// `tailleCm` vient de la base publique, écrite par n'importe quel client : NaN, infini, négatif ou géant deviennent « sans taille ».
    static func tailleSure(_ valeur: Double?) -> Double? {
        guard let valeur, valeur.isFinite, valeur > 0, valeur < 500 else { return nil }
        return valeur
    }

    /// Les centimètres à afficher, sans jamais planter : `Int(exactly:)` après arrondi d'une valeur déjà bornée.
    static func centimetres(_ valeur: Double?) -> Int? {
        guard let sure = tailleSure(valeur), let entier = Int(exactly: sure.rounded()) else { return nil }
        return entier
    }

    static func commentaire(depuis r: CKRecord) -> CommentaireFeed? {
        guard r.recordType == typeCommentaire, let publication = r["publication"] as? String,
              let auteur = r["auteurNom"] as? String, let texte = r["texte"] as? String,
              let date = r["creeLe"] as? Date else { return nil }
        return CommentaireFeed(id: r.recordID.recordName, publication: publication, auteurNom: auteur, texte: texte, creeLe: date)
    }
}
