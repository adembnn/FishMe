import Foundation
import Testing
@testable import Core

@Suite("Région US : aucune combinaison ne produit un verdict permissif")
struct JamaisPermissifUSTests {
    @Test("Le verdict n'a que trois valeurs : interdit, à vérifier, donnée absente")
    func troisValeurs() {
        #expect(VerdictUS.allCases == [.interdit, .aVerifier, .donneeAbsente])
        #expect(Set(VerdictUS.allCases.map(\.rawValue)) == ["interdit", "a_verifier", "donnee_absente"])
        #expect(VerdictUS.allCases.map(\.libelle) == ["Interdit", "À vérifier", "Donnée absente"])
    }

    @Test("Aucun texte du verdict ni d'aucun motif ne dit « autorisé », « peut garder » ou équivalent, en impérial comme en métrique")
    func vocabulaire() {
        let w = FenetreProtegee(basse: .pouces(14), haute: .pouces(18))!
        var textes = VerdictUS.allCases.flatMap { [$0.libelle, $0.phrase] }
        let motifs: [MotifUS] = [
            .horsSaison(regle: "r"), .fermeture(regle: "r", type: .pecheInterdite, motif: "frayère"),
            .fermeture(regle: "r", type: .remiseAEauSeulement, motif: "frai"), .fermeture(regle: "r", type: .especeProtegee, motif: "liste"),
            .sousTailleMinimale(regle: "r", taille: .pouces(10), minimale: .pouces(15)),
            .dansFenetreProtegee(regle: "r", taille: .pouces(16), fenetre: w),
            .auDessusTailleMaximale(regle: "r", taille: .pouces(30), maximale: .pouces(28)),
            .limiteDePriseAtteinte(regle: "r", limite: 5), .limiteDePossessionAtteinte(regle: "r", limite: 10),
            .regleNonConfirmee(regle: "r", statut: .nonRelue), .regleExpiree(regle: "r"), .lectureAncienne(regle: "r", jours: 500),
            .lectureDansLeFutur(regle: "r"), .reglesDEtatSurTerrainTribal(regle: "r"),
            .conflitEntreRegles(famille: .taille, regles: ["a", "b"]), .jourSurUneBorne(regle: "r"), .tailleALaLimite(regle: "r"),
            .tailleNonMesuree(regle: "r"), .tailleEstimee(regle: "r"), .ageInconnu(regle: "r"), .regleHorsTrancheDAge(regle: "r"),
            .enginsOuAppatsALire(regle: "r"), .compteursInconnus(regle: "r"),
            .alerteTerrain(.reserveTribale, juridiction: usWI), .alerteTerrain(.refugeFederal, juridiction: usWI),
            .alerteTerrain(.parcNational, juridiction: usWI), .alerteTerrain(.eauFrontaliere, juridiction: usWI),
            .alerteTerrain(.especeListeeESA, juridiction: usWI), .juridictionInconnue(usWI), .aucuneRegleLue,
        ]
        for m in motifs { textes.append(m.libelle(unites: .imperial)); textes.append(m.libelle(unites: .metrique)) }
        #expect(textes.count > 60)
        for t in textes {
            let bas = t.lowercased()
            for mot in usMotsInterdits { #expect(!bas.contains(mot), "« \(t) » contient « \(mot) »") }
        }
    }

    @Test("Motifs de taille : les tailles du libellé suivent le système et l'arrondi prudent")
    func libellesTaille() {
        let m = MotifUS.sousTailleMinimale(regle: "r", taille: .pouces(13), minimale: .pouces(14))
        #expect(m.libelle(unites: .imperial).contains("14 in"))
        #expect(m.libelle(unites: .metrique).contains("35.6 cm"))
        #expect(m.libelle(unites: .metrique).contains("33 cm"))
    }

    /// Une règle d'État (min 15 po) et une règle de lac (min 12 po), dans tous leurs états de relecture, de validité, avec toutes les tailles.
    /// L'oracle dit « interdit » seulement si la règle la plus spécifique présente est confirmée, valide, que la taille est mesurée
    /// et strictement sous sa minimale ; dans tous les autres cas le verdict est « à vérifier » (jamais absent, jamais autre chose).
    @Test("Exhaustif : 4 statuts x 2 validités x 2 lieux x 2 jeux de règles x 8 tailles x 2 modes de mesure, verdict conforme à l'oracle")
    func exhaustif() {
        let statuts = StatutRelecture.allCases
        let fins: [JourCivil?] = [nil, usEte.ajouter(jours: -1)]
        let tailles: [Double?] = [nil, 5, 11.99, 12, 12.01, 14.99, 15, 20]
        var n = 0
        for statutEtat in statuts {
            for statutLac in statuts {
                for finLac in fins {
                    for avecEtat in [true, false] {
                        for avecLac in [true, false] {
                            guard avecEtat || avecLac else { continue }
                            var regles: [RegleUS] = []
                            if avecEtat { regles.append(usRegle("etat", usWI, tailles: usMin(15), statut: statutEtat)) }
                            if avecLac { regles.append(usRegle("lac", usLacX, tailles: usMin(12), statut: statutLac, valideJusqua: finLac)) }
                            let moteur = usMoteur(regles)
                            for lieu in [usLacX, usLacY] {
                                for t in tailles {
                                    for estimee in [false, true] {
                                        let r = moteur.evaluer(usQuestion(lieu, pouces: t, estimee: estimee))
                                        // Règle la plus spécifique présente pour ce lieu.
                                        let top: (min: Double, ok: Bool)? = {
                                            if lieu == usLacX && avecLac { return (12, statutLac.estConfirme && finLac == nil) }
                                            if avecEtat { return (15, statutEtat.estConfirme) }
                                            return nil
                                        }()
                                        n += 1
                                        guard let top else {
                                            #expect(r.verdict == .donneeAbsente)
                                            continue
                                        }
                                        let attendu: VerdictUS = (top.ok && !estimee && t != nil && t! < top.min - 1e-6) ? .interdit : .aVerifier
                                        #expect(r.verdict == attendu, "lieu \(lieu) taille \(String(describing: t)) estimee \(estimee) top \(top)")
                                        #expect(r.verdict != .donneeAbsente)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        #expect(n > 3000)
    }

    @Test("Poisson d'une taille à ou au-dessus de toutes les minimales : jamais interdit, quelle que soit la pile de règles")
    func grosPoissonJamaisInterdit() {
        let regles = [usRegle("e", usWI, tailles: usMin(15)), usRegle("z", usNord, tailles: usMin(16)), usRegle("l", usLacX, tailles: usMin(17)),
                      usRegle("t", usTroncon, tailles: usMin(18))]
        let m = usMoteur(regles)
        for lieu in [usWI, usNord, usLacX, usTroncon] {
            #expect(m.evaluer(usQuestion(lieu, pouces: 40)).verdict == .aVerifier)
            #expect(m.evaluer(usQuestion(lieu, pouces: 18)).verdict == .aVerifier)
        }
    }

    @Test("Aucune règle d'aucune sorte n'a de verdict meilleur que « à vérifier » : balayage de familles et de dates sur l'année entière")
    func balayageAnnee() {
        let w = FenetreProtegee(basse: .pouces(14), haute: .pouces(18))!
        let regles = [usRegle("s", usWI, saison: usPeriode(5, 1, 2, 28)),
                      usRegle("t", usWI, tailles: TaillesUS(minimale: .pouces(12), fenetre: w, maximale: .pouces(30))),
                      usRegle("l", usWI, limites: LimitesUS(prise: 5, possession: 10)),
                      usRegle("f", usWI, fermetures: [FermetureUS(type: .remiseAEauSeulement, periode: usPeriode(4, 1, 5, 15), motif: "frai")]),
                      usRegle("e", usWI, engins: ["1 ligne"], appats: ["sans vifs"])]
        let m = usMoteur(regles)
        var jour = usJour(2026, 6, 25)
        for _ in 0..<366 {
            for t in [nil, 10, 13, 16, 25, 35] as [Double?] {
                for prises in [nil, 0, 5] as [Int?] {
                    let r = m.evaluer(usQuestion(usLacX, jour: jour, pouces: t, prises: prises))
                    #expect([VerdictUS.interdit, .aVerifier].contains(r.verdict))
                    if r.verdict == .aVerifier { #expect(!r.motifs.isEmpty) }
                }
            }
            jour = jour.ajouter(jours: 1)
        }
    }
}
