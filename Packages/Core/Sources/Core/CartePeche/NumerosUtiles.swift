import Foundation

public enum GroupeNumeroUtile: String, Sendable, Equatable, CaseIterable {
    case principal
    case autre
}

public struct NumeroUtile: Sendable, Equatable, Hashable, Identifiable {
    public var numero: String
    /// Le libellé de la source, mot pour mot.
    public var libelle: String
    public var groupe: GroupeNumeroUtile
    public var sourceURL: URL
    public var releveLe: JourCivil

    public var id: String { numero }

    /// Le lien `tel:` (l'iPhone demande confirmation avant d'appeler).
    public var lienTelephone: URL? { URL(string: "tel:\(numero)") }

    public init(numero: String, libelle: String, groupe: GroupeNumeroUtile, sourceURL: URL, releveLe: JourCivil) {
        self.numero = numero
        self.libelle = libelle
        self.groupe = groupe
        self.sourceURL = sourceURL
        self.releveLe = releveLe
    }
}

/// Les numéros d'urgence, relevés sur service-public.gouv.fr le 19/10/2026 (page « Numéros d'urgence »,
/// signalée « Mise à jour le 18 octobre 2024 »). Aucun autre numéro n'est cité : non vérifié, donc absent.
/// Le numéro du sauvetage maritime (sans objet en eau douce) et le numéro de rappel de la source (il ne prend pas d'appel d'urgence) sont exclus.
/// ⚠ à vérifier : relire la page source avant chaque version publiée.
public enum NumerosUtiles {
    public static let sourceURL: URL = URL(string: "https://www.service-public.gouv.fr/particuliers/actualites/A17758?lang=fr")!
    public static let nomDeLaSource = "service-public.gouv.fr"
    public static let releveLe: JourCivil = JourCivil(annee: 2026, mois: 10, jour: 19)!

    private static func numero(_ n: String, _ libelle: String, _ groupe: GroupeNumeroUtile) -> NumeroUtile {
        NumeroUtile(numero: n, libelle: libelle, groupe: groupe, sourceURL: sourceURL, releveLe: releveLe)
    }

    public static let liste: [NumeroUtile] = [
        numero("112", "Numéro d'urgence européen", .principal),
        numero("18", "Sapeurs-pompiers", .principal),
        numero("15", "Samu (Service d'aide médicale d'urgence)", .principal),
        numero("17", "Police ou gendarmerie", .autre),
        numero("114", "Urgence pour les personnes sourdes et malentendantes", .autre),
    ]

    public static var principaux: [NumeroUtile] { liste.filter { $0.groupe == .principal } }
    public static var autres: [NumeroUtile] { liste.filter { $0.groupe == .autre } }
}
