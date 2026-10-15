import Foundation
import Testing
@testable import Core

@Suite("Règles : liste de contrôle")
struct ReglesTests {
    let moteur = moteurEssai()
    var regles: MoteurRegles { moteur.regles }
    let lyon = Lieu(departement: Departement(code: "69"))

    func ligne(_ r: ResultatControle, _ type: TypeRegle) -> LigneControle? { r.lignes.first { $0.type == type } }

    // MARK: verdictTaille

    @Test func verdictDeTaille() {
        #expect(regles.verdictTaille(longueurCm: 55, mesure: .toise, maille: 60) == .sousLaMaille)
        #expect(regles.verdictTaille(longueurCm: 59, mesure: .toise, maille: 60) == .tropPres)
        #expect(regles.verdictTaille(longueurCm: 61, mesure: .saisie, maille: 60) == .tropPres)
        #expect(regles.verdictTaille(longueurCm: 65, mesure: .toise, maille: 60) == .respectee)
        #expect(regles.verdictTaille(longueurCm: 59, mesure: .estimee, maille: 60) == .sansVerdict)
        #expect(regles.verdictTaille(longueurCm: 90, mesure: .estimee, maille: 60) == .sansVerdict)
    }

    // MARK: Cas d'or (docs/donnees.md, 15 oct. 2026)

    @Test("1. Brochet 55 cm à Charenton : relâche-la, plus stricte des deux textes")
    func cas1() {
        let r = regles.controle(espece: brochetEssai, tailleCm: 55, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(r.consigne == .relacheLa)
        #expect(ligne(r, .taille)?.etat == .nonRespectee)
    }

    @Test("2. Brochet 65 cm à Charenton : taille respectée, consommation interdite, réserve à vérifier : vérifie l'arrêté")
    func cas2() {
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(ligne(r, .taille)?.etat == .respectee)
        #expect(ligne(r, .consommation)?.phrase.contains("interdites") == true)
        #expect(ligne(r, .reserve)?.etat == .aVerifierSurPlace)
        #expect(ligne(r, .reserve)?.raison == .reserve)
        #expect(r.consigne == .verifieLArrete)
        // Sans réserve listée sur cette eau : « aucune règle saisie ne l'interdit ».
        let sansReserve = Lieu(departement: Departement(code: "94"), eau: morbrasEau, categorie: deuxieme)
        let r2 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: sansReserve, prisesDuJour: [])
        #expect(r2.lignes.allSatisfy { $0.etat == .respectee })
        #expect(r2.consigne == .aucuneRegleSaisieNeLInterdit)
    }

    @Test("3. Sandre 45 cm à Paris : relâche-la")
    func cas3() {
        let r = regles.controle(espece: sandreEssai, tailleCm: 45, mesure: .toise, date: quinzeOctobre, lieu: lieuParis, prisesDuJour: [])
        #expect(r.consigne == .relacheLa)
    }

    @Test("4. Truite fario 30 cm à Lyon : fermée par le socle national, relâche-la")
    func cas4() {
        let r = regles.controle(espece: fario, tailleCm: 30, mesure: .toise, date: quinzeOctobre, lieu: lyon, prisesDuJour: [])
        #expect(r.consigne == .relacheLa)
    }

    @Test("5. Perche 20 cm à Lyon : règles locales non saisies, vérifie l'arrêté")
    func cas5() {
        let r = regles.controle(espece: percheEssai, tailleCm: 20, mesure: .toise, date: quinzeOctobre, lieu: lyon, prisesDuJour: [])
        #expect(r.consigne == .verifieLArrete)
        let locale = r.lignes.first { $0.phrase.contains("Règles locales non saisies") }
        #expect(locale != nil)
        #expect(locale?.sources.first?.url == MoteurRegles.urlPrefectures)
    }

    @Test("6. Black-bass 35 cm à Charenton : la plus stricte (40 cm), relâche-la")
    func cas6() {
        let r = regles.controle(espece: blackBassEssai, tailleCm: 35, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(r.consigne == .relacheLa)
        #expect(ligne(r, .taille)?.sources.count == 2)
    }

    @Test("7. Brochet 70 cm à Paris le 15 janvier 2027 : règle d'avis annuel périmée, vérifie l'arrêté 2027")
    func cas7() {
        let r = regles.controle(espece: brochetEssai, tailleCm: 70, mesure: .toise, date: utc(2027, 1, 15), lieu: lieuParis, prisesDuJour: [])
        let perimee = r.lignes.first { $0.raison == .perimee }
        #expect(perimee != nil)
        #expect(perimee?.phrase.contains("2027") == true)
        #expect(r.consigne == .verifieLArrete)
    }

    @Test("8. Brochet 65 cm à Charenton avec deux brochets déjà gardés : quota, relâche-la")
    func cas8() {
        let gardes = (0..<2).map { _ in Prise(espece: brochetEssai, longueurCm: 70, mesure: .toise, date: utc(2026, 10, 15, 8), gardee: true) }
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: gardes)
        #expect(ligne(r, .quota)?.etat == .nonRespectee)
        #expect(r.consigne == .relacheLa)
        // Un brochet gardé hier ne compte pas.
        let hier = [Prise(espece: brochetEssai, date: utc(2026, 10, 14, 8), gardee: true), Prise(espece: brochetEssai, date: utc(2026, 10, 14, 9), gardee: true)]
        let r2 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: hier)
        #expect(ligne(r2, .quota)?.etat == .respectee)
    }

    @Test("9. Perche 25 cm à Paris à 20 h heure de Paris : après la fin légale, relâche-la")
    func cas9() {
        let r = regles.controle(espece: percheEssai, tailleCm: 25, mesure: .toise, date: utc(2026, 10, 15, 18, 0), lieu: lieuParis, prisesDuJour: [])
        #expect(ligne(r, .nuit)?.etat == .nonRespectee)
        #expect(r.consigne == .relacheLa)
        // À midi, la même prise respecte la ligne horaire.
        let midi = regles.controle(espece: percheEssai, tailleCm: 25, mesure: .toise, date: quinzeOctobre, lieu: lieuParis, prisesDuJour: [])
        #expect(ligne(midi, .nuit)?.etat == .respectee)
    }

    @Test("10. Truite arc-en-ciel 25 cm à Charenton : jamais fermée ; la fario l'est")
    func cas10() {
        let arc = regles.controle(espece: arcEnCiel, tailleCm: 25, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(arc.lignes.allSatisfy { $0.etat != .nonRespectee })
        let f = regles.controle(espece: fario, tailleCm: 25, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(f.consigne == .relacheLa)
    }

    @Test("11. Brochet 59 cm à Charenton : trop près de la maille, mesure-la sur une toise, aucun verdict")
    func cas11() {
        let toise = regles.controle(espece: brochetEssai, tailleCm: 59, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(toise.consigne == .mesureLaSurUneToise)
        #expect(ligne(toise, .taille)?.raison == .tropPresDeLaMaille)
        #expect(!toise.lignes.contains { $0.etat == .nonRespectee })
        let estimee = regles.controle(espece: brochetEssai, tailleCm: 59, mesure: .estimee, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(estimee.consigne == .mesureLaSurUneToise)
        #expect(!estimee.lignes.contains { $0.etat == .nonRespectee })
    }

    @Test("12. Brochet 65 cm sur la Mauldre, catégorie non choisie : les deux valeurs ; 1re choisie : relâche-la")
    func cas12() {
        let lieu = moteur.geo.lieu(de: mareilSurMauldre, choix: nil)
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieu, prisesDuJour: [])
        let ouverture = ligne(r, .periode)
        #expect(ouverture?.valeursParCategorie[.premiere] == "fermée")
        #expect(ouverture?.valeursParCategorie[.deuxieme] == "ouverte")
        #expect(ouverture?.etat == .aVerifierSurPlace)
        #expect(ouverture?.raison == .categorie)
        #expect(r.consigne == .verifieLArrete)
        let premiere = moteur.geo.lieu(de: mareilSurMauldre, choix: ChoixLieu(categorie: .premiere))
        let r2 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: premiere, prisesDuJour: [])
        #expect(r2.consigne == .relacheLa)
        let deuxiemeChoisie = moteur.geo.lieu(de: mareilSurMauldre, choix: ChoixLieu(categorie: .deuxieme))
        let r3 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: deuxiemeChoisie, prisesDuJour: [])
        #expect(r3.consigne != .relacheLa)
    }

    @Test("13. Fusion prudente sur un jeu d'essai du 94 : 50 cm confirmé, 60 cm à vérifier")
    func cas13() {
        let m = moteurEssai(regles: chargeurEssai(extra: ["94": dep94FusionEssai])).regles
        func controle(_ cm: Double) -> ResultatControle {
            m.controle(espece: brochetEssai, tailleCm: cm, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        }
        #expect(controle(45).consigne == .relacheLa)
        #expect(controle(55).consigne == .verifieLArrete)
        #expect(controle(65).consigne == .verifieLArrete)
        // Une espèce qui a une entrée `a_verifier` n'a jamais « aucune règle saisie ne l'interdit ».
        for cm in stride(from: 30.0, through: 120.0, by: 5.0) { #expect(controle(cm).consigne != .aucuneRegleSaisieNeLInterdit) }
        // La perche, sans entrée à vérifier, peut recevoir cette consigne.
        let perche = m.controle(espece: percheEssai, tailleCm: 25, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(perche.consigne == .aucuneRegleSaisieNeLInterdit)
    }

    // MARK: Critères de la fiche

    @Test("3 (fiche). Jamais « tu peux la garder », sur tous les cas")
    func jamaisGarder() {
        let lieux = [lieuCharenton, lieuParis, lyon, Lieu.inconnu, moteur.geo.lieu(de: mareilSurMauldre, choix: nil)]
        let especes = [brochetEssai, sandreEssai, blackBassEssai, percheEssai, fario, arcEnCiel, Espece(id: "anguille"), Espece(id: "esturgeon-europeen")]
        var nb = 0
        for lieu in lieux {
            for espece in especes {
                for cm in [nil, 20.0, 45, 55, 59, 65, 80] {
                    for mesure in [MethodeMesure.toise, .estimee] {
                        let r = regles.controle(espece: espece, tailleCm: cm, mesure: mesure, date: quinzeOctobre, lieu: lieu, prisesDuJour: [])
                        let t = texteDe(r)
                        #expect(!t.contains("tu peux la garder") && !t.contains("peux la garder"))
                        nb += 1
                    }
                }
            }
        }
        #expect(nb == 5 * 8 * 7 * 2)
        for consigne in [Consigne.relacheLa, .mesureLaSurUneToise, .verifieLArrete, .aucuneRegleSaisieNeLInterdit] {
            #expect(!consigne.texte.lowercased().contains("garder"))
        }
    }

    @Test("4 (fiche). Deux tailles contradictoires : la plus stricte, avec les deux sources")
    func deuxTailles() {
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        let taille = ligne(r, .taille)
        #expect(taille?.phrase.contains("60 cm") == true)
        #expect(taille?.sources.map(\.titre) == ["Avis annuel 2026 Val-de-Marne", "Arrêté permanent 2025 Val-de-Marne"])
        #expect(taille?.dateLecture != nil)
        #expect(taille?.citation != nil)
    }

    @Test("10 (fiche). Brochet du 94 : 55 relâche, 59 trop près, 59 estimée sans verdict, 65 respectée")
    func brochetDu94() {
        func c(_ cm: Double, _ m: MethodeMesure) -> ResultatControle {
            regles.controle(espece: brochetEssai, tailleCm: cm, mesure: m, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        }
        #expect(c(55, .toise).consigne == .relacheLa)
        #expect(ligne(c(59, .toise), .taille)?.raison == .tropPresDeLaMaille)
        #expect(c(59, .toise).consigne == .mesureLaSurUneToise)
        #expect(ligne(c(59, .estimee), .taille)?.etat == .aVerifierSurPlace)
        #expect(!c(59, .estimee).lignes.contains { $0.etat == .nonRespectee })
        #expect(ligne(c(65, .toise), .taille)?.etat == .respectee)
    }

    @Test("Tronçon : en texte avec « j'y suis ? », compté seulement une fois confirmé")
    func troncon() {
        let sans = Lieu(departement: Departement(code: "01"), eau: Eau(nom: "L'Ain", cle: "ain", type: .riviere), categorie: deuxieme)
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: sans, prisesDuJour: [])
        let t = r.lignes.first { $0.libelleTroncon != nil }
        #expect(t?.libelleTroncon == "de l'aval du barrage d'Allement à l'amont du barrage Convert")
        #expect(t?.raison == .troncon)
        #expect(r.consigne != .relacheLa)
        let confirme = Lieu(departement: Departement(code: "01"), eau: Eau(nom: "L'Ain", cle: "ain", type: .riviere), categorie: deuxieme,
                            tronconsConfirmes: ["01-ain-troncon-taille"])
        let r2 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: confirme, prisesDuJour: [])
        #expect(r2.consigne == .relacheLa)
    }

    @Test("Espèces protégées et anguille sans stade : relâche-la")
    func protegees() {
        for e in [Espece(id: "esturgeon-europeen"), Espece(id: "lamproie-marine"), Espece(id: "anguille")] {
            let r = regles.controle(espece: e, tailleCm: nil, mesure: nil, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
            #expect(r.consigne == .relacheLa)
        }
    }

    @Test("Écrevisse signal : transport vivant interdit affiché sans changer la consigne")
    func transportVivant() {
        let r = regles.controle(espece: Espece(id: "ecrevisse-signal"), tailleCm: 10, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        let l = ligne(r, .transportVivant)
        #expect(l?.phrase.contains("transport vivant interdit") == true)
        #expect(l?.etat == .respectee)
    }

    @Test("Hors de France : aucune règle française, jamais un feu vert")
    func horsDeFrance() {
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: .inconnu, prisesDuJour: [])
        #expect(r.lignes.contains { $0.phrase.contains("Hors de France") })
        #expect(r.consigne == .verifieLArrete)
    }

    @Test("Une règle illisible ne devient jamais un feu vert")
    func regleIllisible() {
        let cassee = fichierRegles(departement: "94", regles: [
            regle("94-ok", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": 40], phrase: "Brochet : 40 cm."),
            ["type": "taille_min", "phrase": "sans id"],
        ])
        let m = moteurEssai(regles: chargeurEssai(extra: ["94": cassee])).regles
        let r = m.controle(espece: percheEssai, tailleCm: 25, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
        #expect(r.consigne == .verifieLArrete)
        #expect(m.departementsCouverts().first { $0.departement.code == "94" }?.lignesAVerifier == 1)
    }

    @Test("Les jeux d'essai se lisent sans règle illisible")
    func jeuxLisibles() {
        let c = chargeurEssai()
        for nom in ["national", "94", "75", "78", "01"] {
            let f = c.fichier(nom)
            #expect(f != nil)
            #expect(f?.illisibles == 0)
        }
    }

    @Test("Département voisin : les lignes des deux départements, une fois chacune")
    func rivierFrontiere() {
        let lieu = moteur.geo.lieu(de: limite94et75, choix: ChoixLieu(categorie: .deuxieme))
        #expect(lieu.departementVoisin?.code == "75")
        let r = regles.controle(espece: sandreEssai, tailleCm: 45, mesure: .toise, date: quinzeOctobre, lieu: lieu, prisesDuJour: [])
        #expect(r.consigne == .relacheLa)
        let phrases = r.lignes.map(\.phrase)
        #expect(Set(phrases).count == phrases.count)
    }

    // MARK: Couverture

    @Test("departementsCouverts lit les fichiers présents (3 fichiers : 3 départements), le 2A a le socle seul")
    func couverts() {
        let trois = ChargeurRegles(sources: [SourceMemoire(fichiers: [
            "national": nationalEssai, "94": dep94Essai, "78": dep78Essai,
            "01": fichierRegles(departement: "01", niveau: "partiel", regles: [regle("01-x", "taille_min", especes: ["2151"], valeur: ["cm": 50], phrase: "Brochet : 50 cm.", expire: "2026-12-31")]),
        ])])
        let m = MoteurRegles(chargeur: trois)
        let c = m.departementsCouverts()
        #expect(c.map(\.departement.code) == ["01", "78", "94"])
        #expect(c.first { $0.departement.code == "01" }?.niveau == .partiel)
        #expect(c.first { $0.departement.code == "94" }?.niveau == .complet)
        #expect(c.first { $0.departement.code == "94" }?.reglesConfirmees == 7)
        #expect(c.first { $0.departement.code == "01" }?.expireMin == utc(2026, 12, 31, 0))
        let r = m.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: Lieu(departement: Departement(code: "2A")), prisesDuJour: [])
        #expect(r.lignes.contains { $0.phrase.contains("Règles locales non saisies") })
        #expect(r.consigne == .verifieLArrete)
    }

    @Test("La copie téléchargée plus récente passe avant la copie embarquée, la plus ancienne est ignorée")
    func copieLaPlusRecente() {
        let embarquee = SourceMemoire(fichiers: ["national": nationalEssai, "94": fichierRegles(version: "2026-10-15.1", departement: "94", regles: [
            regle("94-a", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": 50], phrase: "Brochet : 50 cm.")])])
        let plusRecente = SourceMemoire(fichiers: ["94": fichierRegles(version: "2026-10-16.1", departement: "94", regles: [
            regle("94-b", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": 80], phrase: "Brochet : 80 cm.")])])
        let plusAncienne = SourceMemoire(fichiers: ["94": fichierRegles(version: "2026-09-01.1", departement: "94", regles: [])])
        let c = ChargeurRegles(sources: [plusAncienne, plusRecente, embarquee])
        #expect(c.fichier("94")?.version == "2026-10-16.1")
        let cassee = ChargeurRegles(sources: [SourceMemoire(fichiers: ["94": Data("pas du json".utf8)]), embarquee])
        #expect(cassee.fichier("94")?.version == "2026-10-15.1")
    }

    @Test("Un fichier de 400 Ko se charge vite")
    func performance() {
        let regles = (0..<1100).map { i in
            regle("94-r\(i)", "taille_min", especes: ["\(2000 + i % 90)"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": 30 + i % 40],
                  phrase: "Règle d'essai numéro \(i), avec une phrase assez longue pour ressembler à un extrait d'arrêté préfectoral.")
        }
        let donnees = fichierRegles(departement: "94", regles: regles)
        #expect(donnees.count > 300_000)
        let horloge = ContinuousClock()
        let duree = horloge.measure { _ = try? JSONDecoder().decode(FichierRegles.self, from: donnees) }
        print("Chargement d'un fichier de \(donnees.count / 1000) Ko : \(duree)")
        #expect(duree < .seconds(1))
    }
}
