import Core
import Foundation
import MapKit

// La couche « spots d'eau » de la carte : des endroits où l'eau existe, en plus des stations de pêche électrique de l'OFB.
// Un spot d'eau n'est PAS un relevé : aucun chiffre n'y est attaché. Les espèces d'un spot viennent du département (Core).

/// D'où vient un spot d'eau (sert au symbole, à la source citée et au libellé d'accessibilité).
nonisolated enum OrigineEau: String, Sendable, Equatable, Hashable {
  /// Station hydrométrique Hub'Eau / Vigicrues : un cours d'eau nommé (« La Marne à Charenton »). Hors ligne.
  case coursDEau
  /// Recherche MapKit dans la zone visible : étang, lac, canal, base de loisirs... En ligne.
  case planDEau
  /// Coin public d'OpenStreetMap déjà embarqué dans `Core` (pêche, ponton, accès à l'eau). Hors ligne.
  case lieuPublic

  var symboleSF: String {
    switch self {
    case .coursDEau: return "water.waves"
    case .planDEau: return "drop.fill"
    case .lieuPublic: return "figure.fishing"
    }
  }

  var libelle: String {
    switch self {
    case .coursDEau: return "Cours d'eau"
    case .planDEau: return "Plan d'eau"
    case .lieuPublic: return "Coin public"
    }
  }

  /// La source à citer sous le nom du spot.
  var source: String {
    switch self {
    case .coursDEau: return "Hub'Eau, Vigicrues"
    case .planDEau: return "Plans"
    case .lieuPublic: return "OpenStreetMap"
    }
  }
}

nonisolated struct SpotEau: Sendable, Equatable, Hashable, Identifiable {
  var id: String
  var nom: String
  var coordonnee: Coordonnee
  var origine: OrigineEau
}

/// D'où viennent les spots d'eau de la carte.
nonisolated protocol FournisseurSpotsEau: Sendable {
  /// Les cours d'eau nommés de `stations-hydro.json` (France métropolitaine), lus une fois puis gardés. `[]` si le fichier manque.
  func coursDEau() async -> [SpotEau]
  /// Les coins publics OpenStreetMap de la zone (seulement si `Core` les fournit et si la zone n'est pas trop large).
  func lieuxPublics(dans zone: ZoneCarte) async -> [SpotEau]
  /// Les plans d'eau de la zone visible (MapKit). `[]` hors ligne, en cas d'échec, ou si la zone est trop large. Jamais d'erreur.
  func plansDEau(dans zone: ZoneCarte) async -> [SpotEau]
}

/// Aucun spot d'eau : pour les tests et les aperçus qui n'en veulent pas.
nonisolated struct SpotsEauVides: FournisseurSpotsEau {
  func coursDEau() async -> [SpotEau] { [] }
  func lieuxPublics(dans zone: ZoneCarte) async -> [SpotEau] { [] }
  func plansDEau(dans zone: ZoneCarte) async -> [SpotEau] { [] }
}

// MARK: Ce que la couche rend à la carte

nonisolated struct CoucheEau: Sendable, Equatable {
  var elements: [ElementCarte] = []
  /// Les spots des points affichés (pas des regroupements), par identifiant.
  var spots: [String: SpotEau] = [:]
}

extension Regroupeur {
  /// Au-delà, les spots d'eau se regroupent en cases (comme les stations).
  nonisolated static let maximumEau = 90
}

@concurrent nonisolated func calculerCoucheEau(spots: [SpotEau], region: ZoneCarte) async
  -> CoucheEau
{
  let points = spots.map { PointCarte(id: $0.id, coordonnee: $0.coordonnee) }
  let elements = Regroupeur.elements(points: points, region: region, maximum: Regroupeur.maximumEau)
  var ids: Set<String> = []
  for e in elements {
    if case .point(let p) = e { ids.insert(p.id) }
  }
  var index: [String: SpotEau] = [:]
  for s in spots where ids.contains(s.id) { index[s.id] = s }
  return CoucheEau(elements: elements, spots: index)
}

// MARK: Le fournisseur réel

nonisolated final class SpotsEauReels: FournisseurSpotsEau, Sendable {
  /// Au-delà de cette étendue (en degrés de latitude, environ 130 km), la recherche en ligne ne montrerait que le centre de la vue.
  static let etendueMaximaleRecherche = 1.2
  /// Au-delà, on ne lit pas les coins publics (le regroupement serait faux).
  static let etendueMaximaleLieux = 2.5
  static let maximumParVue = 60
  static let requetes = [
    "étang", "lac", "plan d'eau", "rivière", "canal", "base de loisirs", "pêche",
  ]

  private let lecture = LectureCoursDEau()
  private let cache = CacheZonesEau()
  private let coinsPublics: (any ServiceCoinsPublics)?

  init(coinsPublics: (any ServiceCoinsPublics)? = nil) {
    self.coinsPublics = coinsPublics
  }

  func coursDEau() async -> [SpotEau] {
    await lecture.tous()
  }

  @concurrent
  func lieuxPublics(dans zone: ZoneCarte) async -> [SpotEau] {
    guard let coinsPublics, zone.spanLatitude <= Self.etendueMaximaleLieux else { return [] }
    let demiLat = zone.spanLatitude / 2 * 1.1
    let demiLon = zone.spanLongitude / 2 * 1.1
    let region = RegionCarte(
      sudOuest: Coordonnee(
        latitude: zone.centre.latitude - demiLat, longitude: zone.centre.longitude - demiLon),
      nordEst: Coordonnee(
        latitude: zone.centre.latitude + demiLat, longitude: zone.centre.longitude + demiLon))
    return coinsPublics.coinsPublicsDans(region).map { c in
      let nom: String
      if let n = c.nom, !n.isEmpty {
        nom = n
      } else {
        switch c.type {
        case .ponton: nom = "Ponton de pêche"
        case .acces: nom = "Accès à l'eau"
        case .peche: nom = "Coin de pêche public"
        }
      }
      return SpotEau(id: "osm:\(c.id)", nom: nom, coordonnee: c.coordonnee, origine: .lieuPublic)
    }
  }

  @concurrent
  func plansDEau(dans zone: ZoneCarte) async -> [SpotEau] {
    guard zone.spanLatitude <= Self.etendueMaximaleRecherche, zone.spanLatitude > 0,
      zone.spanLongitude > 0
    else { return [] }
    let cle = Self.cleDeZone(zone)
    if let deja = await cache.lire(cle) { return deja }

    // Les requêtes partent ensemble ; l'annulation de la tâche annule chaque recherche MapKit en cours.
    var tous: [SpotEau] = []
    await withTaskGroup(of: [SpotEau].self) { groupe in
      for requete in Self.requetes {
        groupe.addTask { await Self.chercher(requete, dans: zone) }
      }
      for await lot in groupe { tous.append(contentsOf: lot) }
    }
    if Task.isCancelled { return [] }

    let resultat = Self.dedupliquer(tous, centre: zone.centre, maximum: Self.maximumParVue)
    // Un résultat vide peut venir d'un échec réseau ou d'un quota : on ne le garde pas.
    if !resultat.isEmpty { await cache.ecrire(resultat, pour: cle) }
    return resultat
  }

  /// La zone arrondie : le pas suit l'étendue (un quart de la vue), donc un petit glissement retombe sur la même clé.
  static func cleDeZone(_ zone: ZoneCarte) -> String {
    let pas = max(0.01, zone.spanLatitude / 4)
    let lat = (zone.centre.latitude / pas).rounded() * pas
    let lon = (zone.centre.longitude / pas).rounded() * pas
    let echelle = Int((log2(max(zone.spanLatitude, 0.005)) * 2).rounded())
    return String(format: "%.3f|%.3f|%d", lat, lon, echelle)
  }

  /// Un même lieu rendu par plusieurs requêtes (ou deux fois) ne compte qu'une fois ; les plus proches du centre d'abord.
  static func dedupliquer(_ spots: [SpotEau], centre: Coordonnee, maximum: Int) -> [SpotEau] {
    var vus: Set<String> = []
    var gardes: [SpotEau] = []
    let tries = spots.sorted {
      distanceMetres($0.coordonnee, centre) < distanceMetres($1.coordonnee, centre)
    }
    for s in tries {
      let cle = cleDeDoublon(s)
      if vus.insert(cle).inserted { gardes.append(s) }
      if gardes.count >= maximum { break }
    }
    return gardes
  }

  static func cleDeDoublon(_ s: SpotEau) -> String {
    let nom = s.nom.folding(
      options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
    let lat = (s.coordonnee.latitude * 200).rounded()
    let lon = (s.coordonnee.longitude * 200).rounded()
    return "\(nom)|\(lat)|\(lon)"
  }

  /// Les commerces et services qui portent un mot d'eau dans leur nom (« Restaurant de l'Étang ») ne sont pas des spots.
  private static let categoriesExclues: Set<MKPointOfInterestCategory> = [
    .restaurant, .hotel, .cafe, .bakery, .brewery, .winery, .nightlife, .store, .foodMarket, .bank,
    .atm,
    .gasStation, .pharmacy, .hospital, .school, .university, .parking, .evCharger, .laundry,
    .carRental,
    .fitnessCenter, .theater, .movieTheater, .library, .postOffice, .police, .fireStation,
    .publicTransport, .airport,
  ]

  /// Une recherche MapKit dans la zone. Sur le fil principal (MapKit le veut), mais le réseau attend sans le bloquer.
  @MainActor
  private static func chercher(_ requete: String, dans zone: ZoneCarte) async -> [SpotEau] {
    let demande = MKLocalSearch.Request()
    demande.naturalLanguageQuery = requete
    demande.region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(
        latitude: zone.centre.latitude, longitude: zone.centre.longitude),
      span: MKCoordinateSpan(latitudeDelta: zone.spanLatitude, longitudeDelta: zone.spanLongitude))
    let porte = PorteAnnulation()
    return await withTaskCancellationHandler {
      let recherche = MKLocalSearch(request: demande)
      porte.poser(recherche)
      do {
        let reponse = try await recherche.start()
        return reponse.mapItems.compactMap { (item: MKMapItem) -> SpotEau? in
          guard let nom = item.name?.trimmingCharacters(in: .whitespacesAndNewlines), !nom.isEmpty
          else { return nil }
          if let categorie = item.pointOfInterestCategory, categoriesExclues.contains(categorie) {
            return nil
          }
          let c = item.placemark.coordinate
          guard CLLocationCoordinate2DIsValid(c) else { return nil }
          let coordonnee = Coordonnee(latitude: c.latitude, longitude: c.longitude)
          guard zone.contient(coordonnee) else { return nil }
          let id = "mk:\(nom)@\((c.latitude * 1000).rounded() / 1000),\((c.longitude * 1000).rounded() / 1000)"
          return SpotEau(id: id, nom: nom, coordonnee: coordonnee, origine: .planDEau)
        }
      } catch {
        // Hors ligne, quota ou annulation : la couche reste telle quelle, sans message.
        return []
      }
    } onCancel: {
      porte.annuler()
    }
  }
}

/// Permet d'annuler une recherche MapKit depuis le gestionnaire d'annulation de la tâche.
nonisolated final class PorteAnnulation: @unchecked Sendable {
  private let verrou = NSLock()
  private var recherche: MKLocalSearch?
  private var annulee = false

  func poser(_ r: MKLocalSearch) {
    verrou.lock()
    defer { verrou.unlock() }
    if annulee { r.cancel() } else { recherche = r }
  }

  func annuler() {
    verrou.lock()
    defer { verrou.unlock() }
    annulee = true
    recherche?.cancel()
  }
}

/// Les résultats des dernières zones, pour ne pas relancer sept recherches quand le pêcheur revient quelque part.
actor CacheZonesEau {
  private var valeurs: [String: [SpotEau]] = [:]
  private var ordre: [String] = []
  private let capacite = 40

  func lire(_ cle: String) -> [SpotEau]? { valeurs[cle] }

  func ecrire(_ spots: [SpotEau], pour cle: String) {
    if valeurs[cle] == nil { ordre.append(cle) }
    valeurs[cle] = spots
    while ordre.count > capacite {
      let ancienne = ordre.removeFirst()
      valeurs[ancienne] = nil
    }
  }
}

// MARK: Les cours d'eau du fichier embarqué

/// `stations-hydro.json` (Hub'Eau, Vigicrues, Licence Ouverte 2.0) : lu une fois, au premier besoin, hors du fil principal.
actor LectureCoursDEau {
  private var cache: [SpotEau]?

  func tous() -> [SpotEau] {
    if let cache { return cache }
    let lus = Self.lireLeFichier()
    cache = lus
    return lus
  }

  private nonisolated struct Fichier: Decodable {
    var stations: [Ligne]
  }

  private nonisolated struct Ligne: Decodable {
    var code: String?
    var nom: String?
    var eau: String?
    var lat: Double?
    var lon: Double?
  }

  /// La France métropolitaine seulement : la carte ne sort pas de `franceEtVoisins`.
  private nonisolated static func lireLeFichier() -> [SpotEau] {
    let url =
      Bundle.main.url(forResource: "stations-hydro", withExtension: "json")
      ?? Bundle.main.url(
        forResource: "stations-hydro", withExtension: "json", subdirectory: "Donnees")
    guard let url, let donnees = try? Data(contentsOf: url, options: .mappedIfSafe),
      let fichier = try? JSONDecoder().decode(Fichier.self, from: donnees)
    else { return [] }
    var noms: Set<String> = []
    var spots: [SpotEau] = []
    for l in fichier.stations {
      guard let code = l.code, let lat = l.lat, let lon = l.lon,
        (41.0...52.0).contains(lat), (-6.0...10.0).contains(lon)
      else { continue }
      let nom = (l.nom ?? l.eau ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      // Pas de nom, pas d'épingle : on ne montre jamais un code technique au pêcheur.
      guard !nom.isEmpty, noms.insert(nom).inserted else { continue }
      spots.append(
        SpotEau(
          id: "hydro:\(code)", nom: nom, coordonnee: Coordonnee(latitude: lat, longitude: lon),
          origine: .coursDEau))
    }
    return spots
  }
}
