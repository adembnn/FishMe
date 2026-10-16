import Core
import Foundation
import SwiftData

/// Mode démo du Pescedex (Adem, « Démo cachée ») : une dizaine de cartes « déclarées » (jamais présentées comme de vraies prises),
/// sans photo : le verso montre l'illustration de l'espèce. Les écrans qui les montrent affichent une pastille « Démo »
/// (`estDemo(id)`). Interrupteur dans Réglages, éteint par défaut. Interrupteur : `@AppStorage("demo.communaute")` (réglages).
///
/// Garde-fous :
/// - les cartes ont des identifiants fixes et reconnaissables (`DemoPescedex.estDemo`) : on n'installe et on ne retire que celles-là,
///   jamais une vraie carte du pêcheur ;
/// - lieu au département seulement, aucune coordonnée, photos ré-encodées sans GPS par `DepotCartes.enregistrer` ;
/// - `exemple` reste faux exprès : une carte marquée « exemple » est exclue du classeur, du compteur et de l'aquarium
///   (`CompteurPescedex.emplacements`, `publierAquarium`), donc elle ne se verrait pas. `gardee` reste faux : aucun quota touché ;
/// - les cartes se retirent d'elles-mêmes quand l'interrupteur est coupé, avec leur photo.
nonisolated enum DemoPescedex {
  static let cle = "demo.communaute"

  // MARK: Les cartes d'exemple
  private struct Modele {
    let n: Int
    let espece: String
    let photo: Int
    let cm: Double
    let ilYaJours: Int
    let lieu: String
    let mesure: MethodeMesure
  }

  /// Du plus récent au plus ancien. La plus récente est dans le 94 : c'est la zone du Pescedex à l'ouverture.
  private static let modeles: [Modele] = [
    Modele(
      n: 1, espece: "brochet", photo: 1, cm: 74, ilYaJours: 2, lieu: "La Marne · 94", mesure: .toise
    ),
    Modele(
      n: 2, espece: "perche-commune", photo: 1, cm: 28, ilYaJours: 5, lieu: "La Seine · 94",
      mesure: .toise),
    Modele(
      n: 3, espece: "sandre", photo: 1, cm: 61, ilYaJours: 8, lieu: "La Seine · 92", mesure: .toise),
    Modele(
      n: 4, espece: "carpe-commune", photo: 1, cm: 68, ilYaJours: 11,
      lieu: "Étang de Vincennes · 94", mesure: .estimee),
    Modele(
      n: 5, espece: "chevesne", photo: 1, cm: 38, ilYaJours: 14, lieu: "Le Grand Morin · 77",
      mesure: .toise),
    Modele(
      n: 6, espece: "black-bass", photo: 1, cm: 41, ilYaJours: 17, lieu: "Département 93",
      mesure: .saisie),
    Modele(
      n: 7, espece: "truite-fario", photo: 1, cm: 33, ilYaJours: 21, lieu: "L'Yerres · 77",
      mesure: .toise),
    Modele(
      n: 8, espece: "silure-glane", photo: 1, cm: 112, ilYaJours: 25, lieu: "La Seine · 75",
      mesure: .estimee),
    Modele(
      n: 9, espece: "gardon", photo: 1, cm: 22, ilYaJours: 29, lieu: "Le canal de l'Ourcq · 93",
      mesure: .toise),
    Modele(
      n: 10, espece: "tanche", photo: 1, cm: 36, ilYaJours: 33, lieu: "Département 92",
      mesure: .saisie),
    Modele(
      n: 11, espece: "breme-commune", photo: 1, cm: 44, ilYaJours: 38, lieu: "La Marne · 77",
      mesure: .toise),
    Modele(
      n: 12, espece: "barbeau-fluviatile", photo: 1, cm: 52, ilYaJours: 44, lieu: "La Loire · 45",
      mesure: .toise),
  ]

  /// Identifiant fixe de la carte n : `DE300000-0000-4000-8000-0000000000NN`.
  static func identifiant(_ n: Int) -> UUID {
    UUID(uuidString: String(format: "DE300000-0000-4000-8000-%012d", n)) ?? UUID()
  }

  /// Vrai pour une carte installée par la démo (et jamais pour une carte du pêcheur).
  static func estDemo(_ id: UUID) -> Bool {
    id.uuidString.uppercased().hasPrefix("DE300000-0000-4000-8000-")
  }

  static var identifiantsDemo: [UUID] {
    modeles.map { identifiant($0.n) }
  }

  // MARK: Photos

  /// Le JPEG `<especeId>-<n>.jpg` embarqué, cherché à la racine du bundle puis dans `Photos` ou `Demo/Photos`.
  static func donneesPhoto(especeId: String, numero: Int, bundle: Bundle = .main) -> Data? {
    let base = "\(especeId)-\(numero)"
    for dossier in [nil, "Photos", "Demo/Photos", "Demo"] as [String?] {
      if let url = bundle.url(forResource: base, withExtension: "jpg", subdirectory: dossier),
        let donnees = try? Data(contentsOf: url)
      {
        return donnees
      }
    }
    return nil
  }

  // MARK: Installer et retirer

  /// À appeler au lancement, à chaque changement de l'interrupteur « demo.communaute » et après un rapatriement iCloud.
  /// `demo` vrai : installe les cartes qui manquent. `demo` faux : retire celles de la démo, et seulement elles.
  /// Renvoie vrai si le dépôt a changé (alors recharger le Pescedex et republier l'aquarium).
  @discardableResult
  static func synchroniser(demo: Bool, depot: DepotCartes) async
    -> Bool
  {
    let presentes = Set(await depot.identifiants().cartes)
    if demo {
      var change = false
      let maintenant = Date()
      for m in modeles {
        let id = identifiant(m.n)
        guard !presentes.contains(id) else { continue }
        // Un peu de variété d'heure, sans jamais dépasser maintenant.
        let jour =
          Calendar.current.date(byAdding: .day, value: -m.ilYaJours, to: maintenant) ?? maintenant
        let date =
          Calendar.current.date(
            bySettingHour: 9 + (m.n * 3) % 9, minute: (m.n * 17) % 60, second: 0, of: jour) ?? jour
        let prise = Prise(
          id: id, espece: Espece(id: m.espece), origine: .declaree, longueurCm: nil,
          mesure: nil,
          date: min(date, maintenant), lieuFlou: nil, cheminPhoto: nil, gardee: false,
          exemple: false)
        if (try? await depot.enregistrer(prise: prise, photo: nil)) != nil { change = true }
      }
      return change
    } else {
      let aRetirer = identifiantsDemo.filter(presentes.contains)
      guard !aRetirer.isEmpty else { return false }
      return await depot.supprimer(ids: aRetirer.filter(estDemo)) > 0
    }
  }

  // MARK: Aquarium

  /// Espèces des cartes de démo présentes, de la plus récente à la plus ancienne. Utile pour un contrôle ou un repli ;
  /// `publierAquarium` lit déjà ces cartes dans le Pescedex puisqu'elles ne sont pas marquées « exemple ».
  static func especesDeLAquarium(parmi cartes: [Prise]) -> [String] {
    cartes.filter { estDemo($0.id) }.sorted { $0.date > $1.date }.map(\.espece.id)
  }

  // MARK: Crédits des photos (page Sources)

  /// Aucune photo de démo n'est embarquée : rien à créditer.
  static func credits(bundle: Bundle = .main) -> [(nom: String, mention: String, url: URL?)] { [] }
}
