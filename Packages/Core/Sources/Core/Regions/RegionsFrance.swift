import Foundation

/// Une région administrative de la France métropolitaine (13 régions), avec ses départements.
/// Sert à « Ma région » (Pescedex) et à « Dans ta région » (feed) : un département dit sa région, jamais l'inverse sans lui.
public struct RegionFrance: Sendable, Equatable, Hashable, Identifiable {
    public let id: String
    public let nom: String
    /// Tournure pour une phrase : « en Bretagne », « dans le Grand Est ».
    public let locution: String
    /// Codes de département sur deux caractères : « 01 », « 2A », « 94 ».
    public let departements: [String]

    public init(id: String, nom: String, locution: String, departements: [String]) {
        self.id = id
        self.nom = nom
        self.locution = locution
        self.departements = departements
    }
}

public enum RegionsFrance {
    public static let toutes: [RegionFrance] = [
        RegionFrance(id: "ara", nom: "Auvergne-Rhône-Alpes", locution: "en Auvergne-Rhône-Alpes",
                     departements: ["01", "03", "07", "15", "26", "38", "42", "43", "63", "69", "73", "74"]),
        RegionFrance(id: "bfc", nom: "Bourgogne-Franche-Comté", locution: "en Bourgogne-Franche-Comté",
                     departements: ["21", "25", "39", "58", "70", "71", "89", "90"]),
        RegionFrance(id: "bre", nom: "Bretagne", locution: "en Bretagne", departements: ["22", "29", "35", "56"]),
        RegionFrance(id: "cvl", nom: "Centre-Val de Loire", locution: "en Centre-Val de Loire",
                     departements: ["18", "28", "36", "37", "41", "45"]),
        RegionFrance(id: "cor", nom: "Corse", locution: "en Corse", departements: ["2A", "2B"]),
        RegionFrance(id: "ges", nom: "Grand Est", locution: "dans le Grand Est",
                     departements: ["08", "10", "51", "52", "54", "55", "57", "67", "68", "88"]),
        RegionFrance(id: "hdf", nom: "Hauts-de-France", locution: "dans les Hauts-de-France",
                     departements: ["02", "59", "60", "62", "80"]),
        RegionFrance(id: "idf", nom: "Île-de-France", locution: "en Île-de-France",
                     departements: ["75", "77", "78", "91", "92", "93", "94", "95"]),
        RegionFrance(id: "nor", nom: "Normandie", locution: "en Normandie", departements: ["14", "27", "50", "61", "76"]),
        RegionFrance(id: "naq", nom: "Nouvelle-Aquitaine", locution: "en Nouvelle-Aquitaine",
                     departements: ["16", "17", "19", "23", "24", "33", "40", "47", "64", "79", "86", "87"]),
        RegionFrance(id: "occ", nom: "Occitanie", locution: "en Occitanie",
                     departements: ["09", "11", "12", "30", "31", "32", "34", "46", "48", "65", "66", "81", "82"]),
        RegionFrance(id: "pdl", nom: "Pays de la Loire", locution: "dans les Pays de la Loire",
                     departements: ["44", "49", "53", "72", "85"]),
        RegionFrance(id: "pac", nom: "Provence-Alpes-Côte d'Azur", locution: "en Provence-Alpes-Côte d'Azur",
                     departements: ["04", "05", "06", "13", "83", "84"]),
    ]

    /// La région d'un département ; `nil` si le code n'est pas un département métropolitain connu.
    /// Accepte « 1 » comme « 01 » et « 2a » comme « 2A ».
    public static func region(deDepartement code: String) -> RegionFrance? {
        let propre = normaliser(code)
        return toutes.first { $0.departements.contains(propre) }
    }

    /// Les départements de la région qui contient ce département, ce département compris (vide si le code est inconnu).
    public static func departementsDeLaRegion(de code: String) -> [String] {
        region(deDepartement: code)?.departements ?? []
    }

    static func normaliser(_ code: String) -> String {
        let nu = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if nu.count == 1, nu.allSatisfy({ $0.isNumber }) { return "0" + nu }
        return nu
    }
}
