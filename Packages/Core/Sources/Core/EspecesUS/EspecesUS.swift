import Foundation

/// Poissons signalés par zone aux États-Unis (lot US16). Fichiers `Resources/especes-us/<USPS>-<producteur>.json`
/// (format : outils/us/especes/SCHEMA-zones.md), fusionnés par État, lus à la demande, une seule fois.
/// Un État sans fichier donne un tableau vide. Aucune rareté, aucun verdict : seulement « signalée ici, voici la source ».
public enum EspecesUS {
  /// Toutes les entrées de l'État, tous producteurs confondus.
  public static func charger(etat: String) -> [EntreeEspeceUS] {
    DonneesEspecesUS.embarque.entrees(etat: etat)
  }

  /// Espèces signalées pour la zone, avec repli plan d'eau, puis HUC8, puis État.
  public static func signalees(etat: String, zone: ZoneDemandeeUS) -> ResultatEspecesUS {
    DonneesEspecesUS.embarque.signalees(etat: etat, zone: zone)
  }
}

/// Lecture et cache. Séparé de l'API publique pour pouvoir pointer un dossier de test.
final class DonneesEspecesUS: @unchecked Sendable {
  static let embarque = DonneesEspecesUS(
    dossier: Bundle.module.url(forResource: "especes-us", withExtension: nil))

  private let dossier: URL?
  private let verrou = NSLock()
  private var cache: [String: [EntreeEspeceUS]] = [:]

  init(dossier: URL?) { self.dossier = dossier }

  func entrees(etat: String) -> [EntreeEspeceUS] {
    let code = etat.uppercased()
    verrou.lock()
    if let c = cache[code] {
      verrou.unlock()
      return c
    }
    verrou.unlock()
    let lues = Self.lireEtat(code, dossier: dossier)
    verrou.lock()
    cache[code] = lues
    verrou.unlock()
    return lues
  }

  func signalees(etat: String, zone: ZoneDemandeeUS) -> ResultatEspecesUS {
    Self.interroger(entrees: entrees(etat: etat), etat: etat.uppercased(), zone: zone)
  }

  // MARK: Lecture

  private static func lireEtat(_ code: String, dossier: URL?) -> [EntreeEspeceUS] {
    guard code.count == 2, let dossier,
      let noms = try? FileManager.default.contentsOfDirectory(atPath: dossier.path)
    else { return [] }
    let prefixe = code + "-"
    var sortie: [EntreeEspeceUS] = []
    for nom in noms.sorted() where nom.hasPrefix(prefixe) && nom.hasSuffix(".json") {
      guard let data = try? Data(contentsOf: dossier.appendingPathComponent(nom)) else { continue }
      sortie.append(contentsOf: decoder(data))
    }
    return sortie
  }

  /// Un fichier illisible ou une entrée mal formée est ignoré ; les champs inconnus aussi.
  static func decoder(_ data: Data) -> [EntreeEspeceUS] {
    guard let fichier = try? JSONDecoder().decode(Fichier.self, from: data) else { return [] }
    var sortie: [EntreeEspeceUS] = []
    for brute in fichier.entrees.compactMap({ $0.valeur }) {
      guard brute.src >= 0, brute.src < fichier.sources.count,
        let s = fichier.sources[brute.src].valeur
      else { continue }
      sortie.append(
        EntreeEspeceUS(
          slug: brute.slug, nom: brute.nom, latin: brute.latin, zone: brute.zone,
          preuve: brute.preuve, confiance: brute.confiance, n: brute.n,
          anneeMax: brute.anneeMax, source: s))
    }
    return sortie
  }

  private struct Tolerant<T: Decodable>: Decodable {
    let valeur: T?
    init(from decoder: Decoder) throws { valeur = try? T(from: decoder) }
  }

  private struct Fichier: Decodable {
    let sources: [Tolerant<SourceEspeceUS>]
    let entrees: [Tolerant<Brute>]
  }

  private struct Brute: Decodable {
    let slug: String?
    let nom: String
    let latin: String
    let zone: ZoneEspeceUS
    let preuve: String
    let confiance: String
    let src: Int
    let n: Int?
    let anneeMax: Int?
    enum CodingKeys: String, CodingKey {
      case slug, nom, latin, zone, preuve, confiance, src, n
      case anneeMax = "annee_max"
    }
  }

  // MARK: Requête

  static func normaliser(_ s: String) -> String {
    let plat = s.folding(
      options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    return String(plat.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
  }

  private static func correspond(
    _ e: EntreeEspeceUS, niveau: NiveauZoneUS, etat: String, zone: ZoneDemandeeUS
  ) -> Bool {
    switch niveau {
    case .planEau:
      guard e.zone.type == "plan_eau", let demande = zone.planEau else { return false }
      let d = normaliser(demande)
      if d.isEmpty { return false }
      return normaliser(e.zone.id) == d || (e.zone.nom.map { normaliser($0) == d } ?? false)
    case .huc8:
      guard e.zone.type == "huc8", let h = zone.huc8 else { return false }
      return e.zone.id.trimmingCharacters(in: .whitespaces)
        == h.trimmingCharacters(in: .whitespaces)
    case .etat:
      return e.zone.type == "etat" && e.zone.id.uppercased() == etat
    }
  }

  static func interroger(entrees: [EntreeEspeceUS], etat: String, zone: ZoneDemandeeUS)
    -> ResultatEspecesUS
  {
    let niveaux: [NiveauZoneUS] = [.planEau, .huc8, .etat]
    let parNiveau = niveaux.map { n in
      entrees.filter { correspond($0, niveau: n, etat: etat, zone: zone) }
    }
    for i in niveaux.indices where !parNiveau[i].isEmpty {
      // Confirmées à ce niveau ou plus large : seules elles autorisent un signalement public.
      let confirmees = Set(
        parNiveau[i...].flatMap { $0 }.filter { $0.niveauConfiance != .nonConfirme }.map(cle))
      let retenues = parNiveau[i].filter {
        $0.niveauConfiance != .nonConfirme || confirmees.contains(cle($0))
      }
      if retenues.isEmpty { continue }
      return ResultatEspecesUS(niveau: niveaux[i], especes: fusionner(retenues))
    }
    return ResultatEspecesUS(niveau: nil, especes: [])
  }

  private static func cle(_ e: EntreeEspeceUS) -> String {
    if let s = e.slug, !s.isEmpty { return "slug:" + s }
    return "latin:" + e.latin.lowercased().trimmingCharacters(in: .whitespaces)
  }

  private static func fusionner(_ entrees: [EntreeEspeceUS]) -> [EspeceSignaleeUS] {
    var groupes: [String: [EntreeEspeceUS]] = [:]
    var ordre: [String] = []
    for e in entrees {
      let k = cle(e)
      if groupes[k] == nil { ordre.append(k) }
      groupes[k, default: []].append(e)
    }
    let especes = ordre.map { k -> EspeceSignaleeUS in
      let g = groupes[k] ?? []
      let meilleure = g.min { $0.niveauConfiance < $1.niveauConfiance } ?? g[0]
      var preuves: [String] = []
      var sources: [SourceEspeceUS] = []
      for e in g {
        if !preuves.contains(e.preuve) { preuves.append(e.preuve) }
        if !sources.contains(e.source) { sources.append(e.source) }
      }
      let ns = g.compactMap(\.n)
      return EspeceSignaleeUS(
        slug: g.first { $0.slug != nil }?.slug, nom: meilleure.nom, latin: meilleure.latin,
        confiance: meilleure.niveauConfiance, preuves: preuves, sources: sources,
        n: ns.isEmpty ? nil : ns.reduce(0, +), anneeMax: g.compactMap(\.anneeMax).max())
    }
    return especes.enumerated().sorted { a, b in
      if a.element.confiance != b.element.confiance {
        return a.element.confiance < b.element.confiance
      }
      return a.offset < b.offset
    }.map(\.element)
  }
}
