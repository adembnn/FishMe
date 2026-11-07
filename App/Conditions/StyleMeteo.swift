import SwiftUI
import Core

/// Le style « app Météo » de la feuille « Tes conditions » : fond qui suit le temps, textes blancs, cartes de verre.
/// Mise en forme seulement : aucune valeur de prévision n'est calculée ici.
enum StyleMeteo {
    enum Ciel { case degage, nuageux, couvert, brouillard, pluie, neige, orage }

    static func ciel(codeTemps: Int) -> Ciel {
        switch codeTemps {
        case 0: return .degage
        case 1, 2: return .nuageux
        case 45...48: return .brouillard
        case 51...67, 80...82: return .pluie
        case 71...77, 85, 86: return .neige
        case 95...99: return .orage
        default: return .couvert
        }
    }

    /// Les deux couleurs du dégradé (haut, bas).
    static func fond(codeTemps: Int, nuit: Bool) -> [Color] {
        switch (ciel(codeTemps: codeTemps), nuit) {
        case (.orage, _): return [couleur(0x241B3D), couleur(0x4B3B70)]
        case (.pluie, true): return [couleur(0x10151F), couleur(0x262D3C)]
        case (.pluie, false): return [couleur(0x2E3945), couleur(0x56626F)]
        case (.neige, true): return [couleur(0x1A2536), couleur(0x3A4C63)]
        case (.neige, false): return [couleur(0x7992AD), couleur(0xC2D2E2)]
        case (.brouillard, true): return [couleur(0x1B222B), couleur(0x3A4450)]
        case (.brouillard, false): return [couleur(0x76848F), couleur(0xA8B3BC)]
        case (.couvert, true): return [couleur(0x151C2A), couleur(0x2E3A4F)]
        case (.couvert, false): return [couleur(0x56697F), couleur(0x8C9FB4)]
        case (.nuageux, true): return [couleur(0x0E1A38), couleur(0x24386A)]
        case (.nuageux, false): return [couleur(0x3C78C2), couleur(0x82B2E2)]
        case (.degage, true): return [couleur(0x08122B), couleur(0x1B2D63)]
        case (.degage, false): return [couleur(0x2670D0), couleur(0x6FB4F4)]
        }
    }

    static func libelle(codeTemps: Int) -> String {
        switch codeTemps {
        case 0: return AnglaisF.t("Dégagé")
        case 1, 2: return AnglaisF.t("Peu nuageux")
        case 3: return AnglaisF.t("Couvert")
        case 45...48: return AnglaisF.t("Brouillard")
        case 51...57: return AnglaisF.t("Bruine")
        case 61...67: return AnglaisF.t("Pluie")
        case 80...82: return AnglaisF.t("Averses")
        case 71...77, 85, 86: return AnglaisF.t("Neige")
        case 95...99: return AnglaisF.t("Orage")
        default: return AnglaisF.t("Nuageux")
        }
    }

    /// Symbole SF d'un code de temps, version nuit comprise.
    static func symbole(codeTemps: Int, nuit: Bool) -> String {
        switch ciel(codeTemps: codeTemps) {
        case .degage: return nuit ? "moon.stars.fill" : "sun.max.fill"
        case .nuageux: return nuit ? "cloud.moon.fill" : "cloud.sun.fill"
        case .brouillard: return "cloud.fog.fill"
        case .pluie: return codeTemps >= 51 && codeTemps <= 57 ? "cloud.drizzle.fill" : "cloud.rain.fill"
        case .neige: return codeTemps >= 71 && codeTemps <= 77 ? "snowflake" : "cloud.snow.fill"
        case .orage: return "cloud.bolt.rain.fill"
        case .couvert: return "cloud.fill"
        }
    }

    /// Nuit : entre le coucher et l'aube du jour quand on les connaît, sinon avant 7 h et après 21 h.
    static func estNuit(_ date: Date, conditions: Conditions) -> Bool {
        let cal = Calendar.current
        if let aube = conditions.aube, let soir = conditions.crepuscule, cal.isDate(date, inSameDayAs: aube) {
            return date < aube || date > soir
        }
        let h = cal.component(.hour, from: date)
        return h < 7 || h >= 21
    }

    /// Couleur d'une température sur la barre de plage : teintes marine et eau seulement (l'orange est réservé aux alertes).
    static func couleur(temperature t: Double) -> Color {
        switch t {
        case ..<0: return couleur(0xC7DFF3)
        case 0..<10: return couleur(0x9CC7EA)
        case 10..<16: return couleur(0x7FB8EE)
        case 16..<22: return couleur(0x5C9FE0)
        case 22..<28: return couleur(0x3F86D0)
        default: return couleur(0x2670D0)
        }
    }

    static func couleur(_ hex: UInt32) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    static let texteDoux = Color.white.opacity(0.65)

    nonisolated(unsafe) private static let fHeureCourte: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "H 'h'"
        return f
    }()
    nonisolated(unsafe) private static let fHeureCourteUS: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h a"
        return f
    }()

    /// « 14 h » ou « 2 PM ».
    static func heureCourte(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        (region == .etatsUnis ? fHeureCourteUS : fHeureCourte).string(from: date)
    }

    /// Les sept jours rendus par `Core` ; à défaut, regroupés depuis la météo heure par heure (mise en page, pas de calcul de prévision).
    static func jours(_ lecture: LectureConditions) -> [JourConditions] {
        if !lecture.conditions.septJours.isEmpty { return Array(lecture.conditions.septJours.prefix(7)) }
        let cal = Calendar.current
        let groupes = Dictionary(grouping: lecture.meteo.heures) { cal.startOfDay(for: $0.heure) }
        return groupes.keys.sorted().prefix(7).compactMap { debut in
            guard let h = groupes[debut] else { return nil }
            let midi = debut.addingTimeInterval(13 * 3600)
            guard let milieu = h.min(by: { abs($0.heure.timeIntervalSince(midi)) < abs($1.heure.timeIntervalSince(midi)) }) else { return nil }
            return JourConditions(jour: debut, ventKmh: h.map(\.ventKmh).max() ?? 0, pluieMm: h.map(\.pluieMm).reduce(0, +),
                                  temperatureMinC: h.map(\.temperatureC).min() ?? milieu.temperatureC,
                                  temperatureMaxC: h.map(\.temperatureC).max() ?? milieu.temperatureC, codeTemps: milieu.codeTemps)
        }
    }
}

/// Une carte de verre de l'app Météo : petit titre en capitales avec son icône, puis le contenu.
struct CarteVitree<Contenu: View>: View {
    let titre: String
    let icone: String
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Label {
                Text(titre.uppercased()).font(Police.taille(12, .bold)).tracking(0.4)
            } icon: {
                Image(systemName: icone).font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(StyleMeteo.texteDoux)
            .accessibilityAddTraits(.isHeader)
            contenu()
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
    }
}
