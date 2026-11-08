import Foundation
import Testing
import Core
@testable import BuildChallenge

/// US17 : « Poissons signalés ici ». Modèle de vue sans interface : repli de niveau, vignette « image à venir »,
/// message sans donnée avec le lien de l'agence, aucun mot de permission.
@MainActor
struct PoissonsUSTests {
    let mots = ["autoris", "allowed", "legal", "légal", "tu peux la garder", "you can keep", "libre", "rareté", "rarity"]

    func motInterdit(dans texte: String) -> String? { mots.first { texte.localizedCaseInsensitiveContains($0) } }

    let source = SourceEspeceUS(nom: "WI DNR", url: "https://dnr.wisconsin.gov/x", licence: "domaine public fédéral", date: "2026-01-01")

    func fiche(plan: String? = nil, lien: String? = "https://dnr.wisconsin.gov") -> FicheUS {
        FicheUS(id: "e-1", titre: plan ?? "Accès", sousTitre: "Plan d'eau · Wisconsin", etat: "WI", nomEtat: "Wisconsin",
                coordonnee: Coordonnee(latitude: 43, longitude: -89), source: "x", date: "2026-01-01",
                lienAgence: lien.flatMap(URL.init(string:)), libelleLien: TextesCarteUS.lienAgence("WI DNR"), avis: [], planEau: plan)
    }

    func espece(_ slug: String?, _ nom: String, _ conf: NiveauConfianceEspeceUS = .officielle) -> EspeceSignaleeUS {
        EspeceSignaleeUS(slug: slug, nom: nom, latin: "Latinus " + nom, confiance: conf, preuves: ["liste_agence"], sources: [source], n: nil, anneeMax: nil)
    }

    @Test func leNiveauDeLaListeEstAffiche() {
        for (n, texte) in [(NiveauZoneUS.planEau, TextesPoissonsUS.niveauPlanEau), (.huc8, TextesPoissonsUS.niveauBassin), (.etat, TextesPoissonsUS.niveauEtat)] {
            let p = PoissonsSignalesUS.construire(resultat: ResultatEspecesUS(niveau: n, especes: [espece("northern-pike", "Northern pike")]),
                                                  fiche: fiche(), imageExiste: { _ in true })
            guard case let .especes(niveau, _, _) = p.contenu else { Issue.record("pas d'espèces"); return }
            #expect(niveau == texte)
        }
    }

    @Test func leRepliVientDeEspecesUSEtLeNomDuPlanEauEstTransmis() {
        var demandee: ZoneDemandeeUS?
        let p = PoissonsSignalesUS.pour(fiche: fiche(plan: "Lake Mendota"), charger: { etat, zone in
            demandee = zone
            #expect(etat == "WI")
            return ResultatEspecesUS(niveau: .etat, especes: [espece("walleye", "Walleye")])
        }, imageExiste: { _ in true })
        #expect(demandee?.planEau == "Lake Mendota")
        guard case let .especes(niveau, v, _) = p.contenu else { Issue.record("pas d'espèces"); return }
        #expect(niveau == TextesPoissonsUS.niveauEtat)
        #expect(v.count == 1)
    }

    @Test func uneEspeceSansImageOuSansSlugAUneVignetteNeutreJamaisLImageDUneAutre() {
        let res = ResultatEspecesUS(niveau: .etat, especes: [espece("walleye", "Walleye"), espece(nil, "Mystery fish"),
                                                             espece("northern-pike", "Northern pike")])
        let p = PoissonsSignalesUS.construire(resultat: res, fiche: fiche(), imageExiste: { $0 == "brochet" })
        guard case let .especes(_, v, _) = p.contenu else { Issue.record("pas d'espèces"); return }
        #expect(v[0].nomImage == nil)
        #expect(v[1].nomImage == nil)
        #expect(v[2].nomImage == "brochet")
        #expect(ImagesEspecesUS.nomImage(slug: "walleye", existe: { _ in true }) == nil)
        #expect(ImagesEspecesUS.nomImage(slug: nil, existe: { _ in true }) == nil)
        #expect(ImagesEspecesUS.nomImage(slug: "northern-pike", existe: { _ in false }) == nil)
    }

    @Test func lesImagesDeLaTableExistentDansLeCatalogue() {
        for (_, image) in ImagesEspecesUS.memeEspece {
            #expect(ImagesEspecesUS.imageExiste(image), Comment(rawValue: "image absente : " + image))
        }
    }

    @Test func sansDonneeLeMessageEstHonnetteAvecLeLienDeLAgence() {
        let p = PoissonsSignalesUS.construire(resultat: ResultatEspecesUS(niveau: nil, especes: []), fiche: fiche())
        guard case let .sansDonnee(texte, lien, libelle) = p.contenu else { Issue.record("attendu : sans donnée"); return }
        #expect(texte == TextesPoissonsUS.aucuneListe)
        #expect(TraducteurCarteUS(locale: Locale(identifier: "en_US"))(texte) == "No species list for this area yet")
        #expect(lien?.host == "dnr.wisconsin.gov")
        #expect(libelle.contains("WI DNR"))
    }

    @Test func laSourceLaDateLaLicenceEtLaConfianceAccompagnentLesEspeces() {
        let res = ResultatEspecesUS(niveau: .huc8, especes: [espece("walleye", "Walleye", .nonConfirme), espece("bluegill", "Bluegill")])
        let p = PoissonsSignalesUS.construire(resultat: res, fiche: fiche(), imageExiste: { _ in false })
        guard case let .especes(_, v, sources) = p.contenu else { Issue.record("pas d'espèces"); return }
        #expect(v[0].confiance == TextesPoissonsUS.confianceNonConfirme)
        #expect(v[1].confiance == TextesPoissonsUS.confianceAgence)
        #expect(sources.count == 1)
        #expect(sources[0].lien?.host == "dnr.wisconsin.gov")
        #expect(sources[0].date == "2026-01-01")
        #expect(sources[0].licence == "domaine public fédéral")
        let en = TraducteurCarteUS(locale: Locale(identifier: "en_US"))
        #expect(en(TextesPoissonsUS.confianceAgence) == "Agency list")
        #expect(en(TextesPoissonsUS.confianceNonConfirme) == "Unconfirmed public report")
        #expect(en(TextesPoissonsUS.niveauEtat) == "Species reported statewide — not specific to this lake")
        #expect(en(TextesPoissonsUS.niveauEtatAgence) == "State sport-fish species (agency list) — not specific to this lake")
        #expect(en(TextesPoissonsUS.imageAVenir) == "Image coming soon")
    }

    @Test func aucunTexteNeContientDeMotInterdit() {
        let en = TraducteurCarteUS(locale: Locale(identifier: "en_US"))
        var textes = TextesPoissonsUS.tous
        textes += textes.map { en($0) }
        let res = ResultatEspecesUS(niveau: .etat, especes: [espece("walleye", "Walleye")])
        textes += PoissonsSignalesUS.construire(resultat: res, fiche: fiche()).textes
        textes += PoissonsSignalesUS.construire(resultat: ResultatEspecesUS(niveau: nil, especes: []), fiche: fiche()).textes
        for texte in textes { #expect(motInterdit(dans: texte) == nil, Comment(rawValue: "mot interdit : " + texte)) }
        #expect(en(TextesPoissonsUS.entete).hasPrefix("Species reported"))
    }

    @Test func lesFichiersAjoutesNeContiennentAucunMotInterdit() throws {
        let racine = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for f in ["Modele/PoissonsSignalesUS.swift", "Vues/PoissonsSignalesUSView.swift"] {
            let texte = try String(contentsOf: racine.appendingPathComponent("App/CarteUS/" + f), encoding: .utf8)
            for m in mots { #expect(!texte.localizedCaseInsensitiveContains(m), Comment(rawValue: f + " : " + m)) }
        }
    }
}
