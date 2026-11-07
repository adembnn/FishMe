import Core
import Foundation

/// Un seul point d'entrée pour afficher tailles, poids, températures, distances, dates et heures selon la région
/// (plan i18n, phases M0 et M1). Les valeurs restent stockées en unités du Système international (cm, kg, °C, km) : la conversion
/// ne se fait qu'ici, à l'affichage. Jamais `usage:` automatique de `Measurement` : il suit les réglages du téléphone, pas la région.
///
/// Tailles, poids et températures passent par `FormatteurUnites` du Core (arrondi sûr : une taille minimale s'arrondit vers le
/// haut, une taille maximale vers le bas, voir `RoleValeur`).
struct FormatRegion: Sendable, Equatable {
    let region: RegionApp

    init(region: RegionApp) { self.region = region }

    var locale: Locale { region.locale }
    var systeme: SystemeUnites { region.unitesParDefaut }

    private var unites: FormatteurUnites {
        FormatteurUnites(systeme: systeme, separateurDecimal: region == .france ? "," : ".")
    }

    // MARK: Tailles, poids, températures

    /// Taille d'un poisson : « 35 cm » ou « 13.8 in ». `role` choisit le sens d'arrondi (défaut : mesure, au plus proche).
    func taille(_ longueur: Longueur, role: RoleValeur = .mesure) -> String {
        unites.texte(longueur, role: role)
    }

    func taille(centimetres: Double, role: RoleValeur = .mesure) -> String {
        taille(.centimetres(centimetres), role: role)
    }

    /// Profondeur : « 2,5 m » ou « 8.2 ft ».
    func profondeur(_ longueur: Longueur, role: RoleValeur = .mesure) -> String {
        unites.texte(longueur, role: role, grandeur: .profondeur)
    }

    func poids(_ masse: Masse, role: RoleValeur = .mesure) -> String {
        unites.texte(masse, role: role)
    }

    func poids(kilogrammes: Double, role: RoleValeur = .mesure) -> String {
        poids(.kilogrammes(kilogrammes), role: role)
    }

    func temperature(_ temperature: Temperature) -> String {
        unites.texte(temperature)
    }

    func temperature(celsius: Double) -> String {
        temperature(.degresCelsius(celsius))
    }

    // MARK: Distances

    /// Distance à pied ou en voiture, depuis des mètres : km et m en France ; miles et pieds aux États-Unis
    /// (pieds en dessous d'un dixième de mile, comme les cartes américaines).
    func distance(metres: Double) -> String {
        let mesure = Measurement(value: metres, unit: UnitLength.meters)
        switch systeme {
        case .metrique:
            if metres < 1000 { return texte(mesure.converted(to: .meters), decimales: 0...0) }
            return texte(mesure.converted(to: .kilometers), decimales: 0...1)
        case .imperial:
            let miles = mesure.converted(to: .miles)
            if miles.value < 0.1 { return texte(mesure.converted(to: .feet), decimales: 0...0) }
            return texte(miles, decimales: 0...1)
        }
    }

    func distance(kilometres: Double) -> String { distance(metres: kilometres * 1000) }

    private func texte(_ mesure: Measurement<UnitLength>, decimales: ClosedRange<Int>) -> String {
        mesure.formatted(
            .measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(decimales)))
                .locale(locale))
    }

    // MARK: Dates et heures

    /// « 07/11/2026 » (France) ou « 11/07/2026 » (États-Unis, MM/DD/YYYY).
    func date(_ date: Date, fuseau: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(locale: locale, timeZone: fuseau).month(.twoDigits).day(.twoDigits).year())
    }

    /// Mois et jour sans année : « 07/11 » ou « 11/07 ».
    func jourMois(_ date: Date, fuseau: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(locale: locale, timeZone: fuseau).month(.twoDigits).day(.twoDigits))
    }

    /// « 15:05 » (24 h, France) ou « 3:05 PM » (12 h, États-Unis).
    func heure(_ date: Date, fuseau: TimeZone = .current) -> String {
        date.formatted(Date.FormatStyle(locale: locale, timeZone: fuseau).hour().minute())
    }

    func dateEtHeure(_ date: Date, fuseau: TimeZone = .current) -> String {
        "\(self.date(date, fuseau: fuseau)) \(heure(date, fuseau: fuseau))"
    }
}
