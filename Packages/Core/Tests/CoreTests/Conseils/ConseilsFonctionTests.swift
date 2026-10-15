import Foundation
import Testing
@testable import Core

private let tous: [NiveauPecheur] = [.debutant, .occasionnel, .confirme]
private let sources = [SourceLue(id: "s1", titre: "Page lue (essai)", url: "https://example.org/page", luLe: "2026-10-15")]

private func conseil(_ id: String, espece: String = "brochet", rang: Int, mois: [Int] = [10], categorie: CategorieConseil = .toutes,
                     niveaux: [NiveauPecheur] = [.debutant, .occasionnel, .confirme], modes: [ModeConseil] = [],
                     reluPar: String? = "S, 2026-10-16") -> ConseilFiche {
    ConseilFiche(id: id, espece: espece, type: .technique, texte: "Conseil \(id)", icone: "fish", mois: mois,
                 categorie: categorie, niveaux: niveaux, modes: modes, rang: rang, sources: ["s1"], reluPar: reluPar)
}

private func service(_ conseils: [ConseilFiche], regles: (any ServiceRegles)? = nil) -> ConseilsParEspece {
    ConseilsParEspece(fichier: FichierConseils(version: "essai", sources: sources, conseils: conseils), regles: regles,
                      horloge: { Date(timeIntervalSince1970: 1_792_065_600) })
}

private func reglesAvecLigne(_ type: TypeRegle, _ phrase: String) -> ReglesFaux {
    let ligne = LigneControle(type: type, etat: .nonRespectee, phrase: phrase)
    return ReglesFaux(resultat: ResultatControle(lignes: [ligne], consigne: .verifieLArrete))
}

private let lieuDeuxieme = Lieu(departement: Departement(code: "94"), categorie: CategorieEau(valeur: .deuxieme, origine: .choixDuPecheur))
private let lieuPremiere = Lieu(departement: Departement(code: "94"), categorie: CategorieEau(valeur: .premiere, origine: .choixDuPecheur))
private let lieuInconnu = Lieu(departement: Departement(code: "94"))

@Suite("conseils(espece, niveau, mois)")
struct ConseilsFonctionTests {
    private let six = (1...6).map { conseil("c\($0)", rang: $0) }

    @Test func debutantTroisAuPlusLePremierGratuit() {
        let r = service(six).conseils(espece: brochet, niveau: .debutant, mois: 10)
        #expect(r.count == 3)
        #expect(r.map(\.gratuit) == [true, false, false])
        #expect(r.map(\.texte) == ["Conseil c1", "Conseil c2", "Conseil c3"])
    }

    @Test func occasionnelCinqEtConfirmeTous() {
        let s = service(six)
        #expect(s.conseils(espece: brochet, niveau: .occasionnel, mois: 10).count == 5)
        let c = s.conseils(espece: brochet, niveau: .confirme, mois: 10)
        #expect(c.count == 6)
        #expect(c.filter(\.gratuit).count == 1)
    }

    @Test func confirmeEnRendAuMoinsAutantQueDebutant() {
        let s = service(six)
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10).count >= s.conseils(espece: brochet, niveau: .debutant, mois: 10).count)
    }

    @Test func triParRangPasParOrdreDuFichier() {
        let s = service([conseil("b", rang: 2), conseil("a", rang: 1), conseil("c", rang: 3)])
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10).map(\.texte) == ["Conseil a", "Conseil b", "Conseil c"])
    }

    @Test func moisSansConseilRendUneListeVide() {
        let s = service(six)
        #expect(s.conseils(espece: brochet, niveau: .debutant, mois: 2).isEmpty)
        #expect(s.conseils(espece: brochet, niveau: .debutant, mois: 0).isEmpty)
        #expect(s.conseils(espece: brochet, niveau: .debutant, mois: 13).isEmpty)
    }

    @Test func autreEspeceSansConseilRendUneListeVide() {
        #expect(service(six).conseils(espece: sandre, niveau: .confirme, mois: 10).isEmpty)
    }

    @Test func niveauxFiltrent() {
        let s = service([conseil("a", rang: 1, niveaux: [.confirme]), conseil("b", rang: 2, niveaux: [.debutant])])
        #expect(s.conseils(espece: brochet, niveau: .debutant, mois: 10).map(\.texte) == ["Conseil b"])
        #expect(s.conseils(espece: brochet, niveau: .occasionnel, mois: 10).isEmpty)
    }

    @Test func leConseilPorteSaSourceAvecSonLien() {
        let r = service(six).conseils(espece: brochet, niveau: .debutant, mois: 10)
        #expect(r.first?.source.url == "https://example.org/page")
        #expect(r.first?.source.titre == "Page lue (essai)")
        #expect(r.first?.icone == "fish")
    }

    @Test func unConseilSansReluParN_estJamaisMontre() {
        let s = service([conseil("a", rang: 1, reluPar: nil), conseil("b", rang: 2, reluPar: "  "), conseil("c", rang: 3)])
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10).map(\.texte) == ["Conseil c"])
    }

    @Test func unConseilDontLaSourceManqueEstEcarte() {
        var c = conseil("a", rang: 1)
        c.sources = ["inconnue"]
        #expect(service([c]).conseils(espece: brochet, niveau: .confirme, mois: 10).isEmpty)
    }
}

@Suite("conseils(espece, niveau, mois, lieu)")
struct ConseilsAvecLieuTests {
    @Test func uneLigneQuiInterditLeVifRetireLesConseilsVif() {
        let s = service([conseil("vif", rang: 1, modes: [.vif]), conseil("leurre", rang: 2, modes: [.leurre]), conseil("rien", rang: 3)],
                        regles: reglesAvecLigne(.modeDePeche, "Pêche au vif interdite sur ce plan d'eau"))
        let r = s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme)
        #expect(r.map(\.texte) == ["Conseil leurre", "Conseil rien"])
        #expect(r.first?.gratuit == true)
    }

    @Test func sansLigneInterditeToutResteEnDeuxiemeCategorie() {
        let s = service([conseil("vif", rang: 1, modes: [.vif]), conseil("rien", rang: 2)], regles: ReglesFaux())
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme).count == 2)
    }

    @Test func uneLigneQuiAutoriseLeVifNeLeRetirePas() {
        let s = service([conseil("vif", rang: 1, modes: [.vif])], regles: reglesAvecLigne(.modeDePeche, "Pêche au vif autorisée"))
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme).count == 1)
    }

    @Test func lAsticotInterditRetireLesConseilsAsticot() {
        let s = service([conseil("asticot", rang: 1, modes: [.asticot]), conseil("rien", rang: 2)],
                        regles: reglesAvecLigne(.modeDePeche, "Asticots interdits en 1re catégorie"))
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuPremiere).map(\.texte) == ["Conseil rien"])
    }

    @Test func laNuitInterditeRetireLesConseilsDeNuit() {
        let s = service([conseil("nuit", rang: 1, modes: [.nuit]), conseil("rien", rang: 2)],
                        regles: reglesAvecLigne(.nuit, "Pêche de nuit interdite hors parcours"))
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme).map(\.texte) == ["Conseil rien"])
    }

    @Test func categorieDuLieu() {
        let s = service([conseil("un", rang: 1, categorie: .premiere), conseil("deux", rang: 2, categorie: .deuxieme),
                         conseil("toutes", rang: 3, categorie: .toutes)], regles: ReglesFaux())
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuPremiere).map(\.texte) == ["Conseil un", "Conseil toutes"])
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme).map(\.texte) == ["Conseil deux", "Conseil toutes"])
    }

    @Test func categorieInconnueSeulementLesConseilsToutes() {
        let s = service([conseil("un", rang: 1, categorie: .premiere), conseil("deux", rang: 2, categorie: .deuxieme),
                         conseil("toutes", rang: 3, categorie: .toutes)], regles: ReglesFaux())
        let r = s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuInconnu)
        #expect(r.map(\.texte) == ["Conseil toutes"])
        #expect(r.first?.gratuit == true)
    }

    @Test func leLimiteDeNiveauSAppliqueApresLeFiltre() {
        let cs = [conseil("vif1", rang: 1, modes: [.vif]), conseil("vif2", rang: 2, modes: [.vif])] + (3...7).map { conseil("c\($0)", rang: $0) }
        let s = service(cs, regles: reglesAvecLigne(.modeDePeche, "Vif interdit"))
        #expect(s.conseils(espece: brochet, niveau: .debutant, mois: 10, lieu: lieuDeuxieme).map(\.texte) == ["Conseil c3", "Conseil c4", "Conseil c5"])
    }

    @Test func sansServiceDeReglesSeulLaCategorieFiltre() {
        let s = service([conseil("vif", rang: 1, modes: [.vif])])
        #expect(s.conseils(espece: brochet, niveau: .confirme, mois: 10, lieu: lieuDeuxieme).count == 1)
    }
}

@Suite("Validation des conseils")
struct ValidationTests {
    private func bon() -> ConseilFiche { conseil("ok", rang: 1) }

    @Test func unBonConseilPasse() {
        #expect(ValidationConseils.erreurs(bon(), sources: sources, exigerRelecture: true).isEmpty)
    }

    @Test func plusDe80Caracteres() {
        var c = bon(); c.texte = String(repeating: "a", count: 81)
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true).isEmpty)
        c.texte = String(repeating: "a", count: 80)
        #expect(ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true).isEmpty)
    }

    @Test func iconeHorsListe() {
        var c = bon(); c.icone = "pizza"
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true).isEmpty)
        for type in TypeConseil.allCases { #expect(IconesConseils.estAutorisee(IconesConseils.parDefaut(type))) }
    }

    @Test func sourceSansLienOuSansDate() {
        var c = bon(); c.sources = []
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true).isEmpty)
        let sansLien = [SourceLue(id: "s1", titre: "t", url: "page", luLe: "2026-10-15")]
        #expect(!ValidationConseils.erreurs(bon(), sources: sansLien, exigerRelecture: true).isEmpty)
        let sansDate = [SourceLue(id: "s1", titre: "t", url: "https://example.org", luLe: "hier")]
        #expect(!ValidationConseils.erreurs(bon(), sources: sansDate, exigerRelecture: true).isEmpty)
    }

    @Test func relecturePasExigeeAvantS() {
        var c = bon(); c.reluPar = nil
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true).isEmpty)
        #expect(ValidationConseils.erreurs(c, sources: sources, exigerRelecture: false).isEmpty)
    }

    @Test func motsInterditsTaillesEtGarde() {
        for texte in ["Un brochet de 60 cm", "Tu peux le garder", "Meilleure heure : l'aube", "Un bon spot", "Les poissons vont mordre",
                      "Heures solunaires", "Quota de trois", "Taille minimale"] {
            var c = bon(); c.texte = texte
            #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: false).isEmpty, "\(texte)")
        }
        var gardon = bon(); gardon.texte = "Asticots pour le gardon"
        #expect(ValidationConseils.erreurs(gardon, sources: sources, exigerRelecture: false).isEmpty)
    }

    @Test func especeProtegeeSeulementRelacheLa() {
        var c = bon(); c.texte = "Relâche-la"
        #expect(ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true, statuts: [.protegee]).isEmpty)
        c.texte = "Pêche-la au ver"
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true, statuts: [.protegee]).isEmpty)
        let f = FichierConseils(version: "e", sources: sources, conseils: [conseil("a", espece: "civelle", rang: 1), conseil("b", espece: "civelle", rang: 2)])
        #expect(!ValidationConseils.erreurs(f, exigerRelecture: false, statuts: ["civelle": [.protegee]]).isEmpty)
    }

    @Test func especeEnvahissanteJamaisRelacheNiVif() {
        var c = bon(); c.texte = "Relâche-la"
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true, statuts: [.envahissante]).isEmpty)
        c.texte = "Ver de terre au fond"; c.modes = [.vif]
        #expect(!ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true, statuts: [.envahissante]).isEmpty)
        c.modes = []
        #expect(ValidationConseils.erreurs(c, sources: sources, exigerRelecture: true, statuts: [.envahissante]).isEmpty)
    }

    @Test func fermetureNationale() {
        // Brochet, 2e catégorie : fermé du dernier dimanche de janvier au dernier samedi d'avril.
        #expect(!RegleDuLot.erreurs(conseil("a", rang: 1, mois: [3], categorie: .deuxieme)).isEmpty)
        #expect(RegleDuLot.erreurs(conseil("a", rang: 1, mois: [10], categorie: .deuxieme)).isEmpty)
        // Fario en octobre : fermée.
        #expect(!RegleDuLot.erreurs(conseil("a", espece: "truite-fario", rang: 1, mois: [10], categorie: .toutes)).isEmpty)
        // Leurre pendant la fermeture du brochet.
        #expect(!RegleDuLot.erreurs(conseil("a", espece: "sandre", rang: 1, mois: [2], categorie: .deuxieme, modes: [.leurre])).isEmpty)
        #expect(RegleDuLot.erreurs(conseil("a", espece: "sandre", rang: 1, mois: [10], categorie: .deuxieme, modes: [.leurre])).isEmpty)
    }
}
