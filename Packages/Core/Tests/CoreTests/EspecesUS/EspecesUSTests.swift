import Foundation
import Testing

@testable import Core

/// Poissons signalés par zone (US16) : fusion de producteurs, repli, dédoublonnage, signalement public seul écarté.
@Suite struct EspecesUSTests {
  static let sources =
    #"[{"nom":"Agence","url":"https://exemple.gov/a","licence":"domaine public fédéral","date":"2026-01-01"},{"nom":"GBIF","url":"https://gbif.org/d","licence":"CC0-1.0","date":"2026-02-02"},{"nom":"Forum","url":"https://exemple.org/f","licence":"non précisée","date":"2026-03-03"}]"#

  static func entree(
    _ slug: String?, _ latin: String, _ type: String, _ id: String, nom: String? = nil,
    conf: String, src: Int, n: Int? = nil, an: Int? = nil, extra: String = ""
  ) -> String {
    let s = slug.map { "\"\($0)\"" } ?? "null"
    let zn = nom.map { ",\"nom\":\"\($0)\"" } ?? ""
    let nn = n.map { ",\"n\":\($0)" } ?? ""
    let aa = an.map { ",\"annee_max\":\($0)" } ?? ""
    return
      "{\"slug\":\(s),\"nom\":\"Poisson \(latin)\",\"latin\":\"\(latin)\",\"zone\":{\"type\":\"\(type)\",\"id\":\"\(id)\"\(zn)},\"preuve\":\"p\(src)\",\"src\":\(src),\"confiance\":\"\(conf)\"\(nn)\(aa)\(extra)}"
  }

  static func fichier(_ producteur: String, _ entrees: [String]) -> String {
    "{\"format\":\"fishme-especes-us/1\",\"etat\":\"WI\",\"producteur\":\"\(producteur)\",\"sources\":\(sources),\"entrees\":[\(entrees.joined(separator: ","))]}"
  }

  static func donnees(_ fichiers: [String: String]) throws -> DonneesEspecesUS {
    let d = FileManager.default.temporaryDirectory.appendingPathComponent(
      "especes-us-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
    for (nom, contenu) in fichiers {
      try contenu.write(to: d.appendingPathComponent(nom), atomically: true, encoding: .utf8)
    }
    return DonneesEspecesUS(dossier: d)
  }

  static let off = "officielle", sci = "enregistrement_scientifique",
    pub = "non confirmé, signalement public"

  @Test func fusionneLesProducteursEtDedoublonne() throws {
    let base = try Self.donnees([
      "WI-agence.json": Self.fichier(
        "agence",
        [
          Self.entree(
            "walleye", "Sander vitreus", "etat", "WI", conf: Self.off, src: 0, n: 5, an: 2020)
        ]),
      "WI-gbif.json": Self.fichier(
        "gbif",
        [
          Self.entree(
            "walleye", "Sander vitreus", "etat", "WI", conf: Self.sci, src: 1, n: 7, an: 2024),
          Self.entree(nil, "Esox lucius", "etat", "WI", conf: Self.sci, src: 1),
        ]),
      "MN-agence.json": Self.fichier(
        "agence", [Self.entree("walleye", "Sander vitreus", "etat", "MN", conf: Self.off, src: 0)]),
    ])
    #expect(base.entrees(etat: "wi").count == 3)
    let r = base.signalees(etat: "WI", zone: ZoneDemandeeUS())
    #expect(r.niveau == .etat)
    #expect(r.especes.count == 2)
    let w = try #require(r.especes.first { $0.slug == "walleye" })
    #expect(w.confiance == .officielle)
    #expect(w.n == 12)
    #expect(w.anneeMax == 2024)
    #expect(w.sources.count == 2)
    #expect(r.especes.first?.slug == "walleye")
    #expect(r.especes.last?.latin == "Esox lucius")
    #expect(r.especes.last?.n == nil)
  }

  @Test func repliPlanEauHuc8Etat() throws {
    let base = try Self.donnees([
      "WI-agence.json": Self.fichier(
        "agence",
        [
          Self.entree(
            "walleye", "Sander vitreus", "plan_eau", "3dhp:1", nom: "Lake Mendota", conf: Self.off,
            src: 0),
          Self.entree("muskie", "Esox masquinongy", "huc8", "07090002", conf: Self.sci, src: 1),
          Self.entree("walleye", "Sander vitreus", "etat", "WI", conf: Self.off, src: 0),
          Self.entree("brook-trout", "Salvelinus fontinalis", "etat", "WI", conf: Self.off, src: 0),
        ])
    ])
    let nom = base.signalees(
      etat: "WI", zone: ZoneDemandeeUS(planEau: "lake  MENDOTA", huc8: "07090002"))
    #expect(nom.niveau == .planEau)
    #expect(nom.especes.map(\.slug) == ["walleye"])
    let id = base.signalees(etat: "WI", zone: ZoneDemandeeUS(planEau: "3dhp:1"))
    #expect(id.niveau == .planEau)
    let huc = base.signalees(
      etat: "WI", zone: ZoneDemandeeUS(planEau: "Lac inconnu", huc8: "07090002"))
    #expect(huc.niveau == .huc8)
    #expect(huc.especes.map(\.slug) == ["muskie"])
    let etat = base.signalees(etat: "WI", zone: ZoneDemandeeUS(huc8: "99999999"))
    #expect(etat.niveau == .etat)
    #expect(etat.especes.count == 2)
  }

  @Test func signalementPublicSeulEstEcarte() throws {
    let base = try Self.donnees([
      "WI-agence.json": Self.fichier(
        "agence", [Self.entree("walleye", "Sander vitreus", "etat", "WI", conf: Self.off, src: 0)]),
      "WI-signalements.json": Self.fichier(
        "signalements",
        [
          Self.entree(
            "walleye", "Sander vitreus", "plan_eau", "3dhp:1", nom: "Lake A", conf: Self.pub, src: 2
          ),
          Self.entree(
            "muskie", "Esox masquinongy", "plan_eau", "3dhp:1", nom: "Lake A", conf: Self.pub,
            src: 2),
          Self.entree("muskie", "Esox masquinongy", "etat", "WI", conf: Self.pub, src: 2),
        ]),
    ])
    // Le walleye public à Lake A est confirmé au niveau État : il sort. Le muskie n'est confirmé nulle part : écarté.
    let r = base.signalees(etat: "WI", zone: ZoneDemandeeUS(planEau: "Lake A"))
    #expect(r.niveau == .planEau)
    #expect(r.especes.map(\.slug) == ["walleye"])
    #expect(r.especes.first?.confiance == .nonConfirme)
    let seul = base.signalees(etat: "WI", zone: ZoneDemandeeUS())
    #expect(seul.especes.map(\.slug) == ["walleye"])
    #expect(seul.especes.first?.confiance == .officielle)
  }

  @Test func zoneAvecSeulementDuPublicRetombeSurLeNiveauSuivant() throws {
    let base = try Self.donnees([
      "WI-x.json": Self.fichier(
        "x",
        [
          Self.entree(
            "muskie", "Esox masquinongy", "plan_eau", "p", nom: "Lake B", conf: Self.pub, src: 2),
          Self.entree("walleye", "Sander vitreus", "etat", "WI", conf: Self.sci, src: 1),
        ])
    ])
    let r = base.signalees(etat: "WI", zone: ZoneDemandeeUS(planEau: "Lake B"))
    #expect(r.niveau == .etat)
    #expect(r.especes.map(\.slug) == ["walleye"])
  }

  @Test func etatSansFichierDonneTableauVide() throws {
    let base = try Self.donnees([:])
    #expect(base.entrees(etat: "ZZ").isEmpty)
    let r = base.signalees(etat: "ZZ", zone: ZoneDemandeeUS(planEau: "x"))
    #expect(r.niveau == nil && r.especes.isEmpty)
    #expect(EspecesUS.charger(etat: "ZZ").isEmpty)
    #expect(EspecesUS.signalees(etat: "ZZ", zone: ZoneDemandeeUS()).especes.isEmpty)
    #expect(DonneesEspecesUS(dossier: nil).entrees(etat: "WI").isEmpty)
  }

  @Test func toleranceChampInconnuEtEntreeMalFormee() throws {
    let bonne = Self.entree(
      "walleye", "Sander vitreus", "etat", "WI", conf: Self.off, src: 0,
      extra: ",\"nouveau\":{\"a\":1}")
    let sansLatin =
      "{\"nom\":\"X\",\"zone\":{\"type\":\"etat\",\"id\":\"WI\"},\"preuve\":\"p\",\"src\":0,\"confiance\":\"officielle\"}"
    let mauvaiseSource = Self.entree(
      "muskie", "Esox masquinongy", "etat", "WI", conf: Self.off, src: 9)
    let json = Self.fichier("agence", [bonne, sansLatin, mauvaiseSource])
      .replacingOccurrences(of: "\"producteur\"", with: "\"inconnu\":true,\"producteur\"")
    let base = try Self.donnees(["WI-agence.json": json, "WI-casse.json": "pas du json"])
    let e = base.entrees(etat: "WI")
    #expect(e.count == 1)
    #expect(e.first?.slug == "walleye")
    #expect(e.first?.source.licence == "domaine public fédéral")
  }

  @Test func aucunMotDePermissionDansLesTextes() {
    let mots = ["autoris", "allowed", "legal", "tu peux la garder", "you can keep"]
    for niveau in [NiveauConfianceEspeceUS.officielle, .enregistrementScientifique, .nonConfirme] {
      for m in mots { #expect(!niveau.texte.lowercased().contains(m)) }
    }
  }
}
