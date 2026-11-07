import Foundation
import Testing
@testable import Core

@Suite("Région US : moteur, absence, spécificité, conflits")
struct MoteurUSTests {
    // MARK: Absence

    @Test("Aucune règle du tout : donnée absente")
    func aucuneRegle() {
        let r = usMoteur([]).evaluer(usQuestion())
        #expect(r.verdict == .donneeAbsente)
        #expect(r.motifs.contains(.aucuneRegleLue))
        #expect(r.regles.isEmpty && r.sources.isEmpty)
    }

    @Test("Règle pour une autre espèce : donnée absente")
    func autreEspece() {
        let r = usMoteur([usRegle("r1", usWI, espece: "muskie", tailles: usMin(40))]).evaluer(usQuestion(pouces: 10))
        #expect(r.verdict == .donneeAbsente)
    }

    @Test("Règle sur une autre branche (frère, enfant, autre État) : donnée absente")
    func autreBranche() {
        let regles = [usRegle("fils", usTroncon, tailles: usMin(40)), usRegle("frere", usLacY, tailles: usMin(40)),
                      usRegle("mi", usMI, tailles: usMin(40))]
        let moteur = usMoteur(regles)
        #expect(moteur.evaluer(usQuestion(usLacX, pouces: 10)).verdict == .donneeAbsente)
        #expect(moteur.evaluer(usQuestion(usWI, pouces: 10)).verdict == .donneeAbsente)
    }

    @Test("Juridiction inconnue : donnée absente avec le motif, sans lien ni exigence")
    func juridictionInconnue() {
        let inconnue = usId("US-WI/fantome")
        let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15))]).evaluer(usQuestion(inconnue, pouces: 5))
        #expect(r.verdict == .donneeAbsente)
        #expect(r.motifs == [.juridictionInconnue(inconnue)])
        #expect(r.lienAgence == nil)
    }

    @Test("Absence : le lien de l'agence et les exigences restent donnés")
    func absenceAvecLien() {
        let exigence = ExigenceUS(id: "e1", portee: usWI, type: .permis, nom: "Licence d'État", prixDollars: nil, source: usSource())
        let r = usMoteur([], exigences: [exigence]).evaluer(usQuestion())
        #expect(r.verdict == .donneeAbsente)
        #expect(r.lienAgence == usLienNord)
        #expect(r.exigences.map(\.id) == ["e1"])
    }

    // MARK: Taille

    @Test("Sous la taille minimale d'État, règle confirmée : interdit")
    func sousMinimale() {
        let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15))]).evaluer(usQuestion(pouces: 12))
        #expect(r.verdict == .interdit)
        #expect(r.regles == ["r1"])
        #expect(r.motifs.contains(.sousTailleMinimale(regle: "r1", taille: .pouces(12), minimale: .pouces(15))))
        #expect(r.sources.count == 1)
    }

    @Test("Au-dessus de la minimale : à vérifier, jamais plus clément")
    func auDessusMinimale() {
        let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15))]).evaluer(usQuestion(pouces: 20))
        #expect(r.verdict == .aVerifier)
        #expect(r.verdict.phrase.contains("Aucune interdiction connue"))
    }

    @Test("Exactement à la limite : à vérifier, pas interdit")
    func surLaLimite() {
        let m = usMoteur([usRegle("r1", usWI, tailles: usMin(15))])
        let r = m.evaluer(usQuestion(pouces: 15))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.tailleALaLimite(regle: "r1")))
        // Même limite écrite en centimètres : 38,1 cm.
        let q = QuestionUS(espece: "walleye", juridiction: usLacX, jour: usEte, taille: .centimetres(38.1))
        #expect(m.evaluer(q).verdict == .aVerifier)
    }

    @Test("Poisson non mesuré : à vérifier avec le motif")
    func nonMesure() {
        let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15))]).evaluer(usQuestion())
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.tailleNonMesuree(regle: "r1")))
    }

    @Test("Taille estimée : jamais interdit, même très sous la minimale")
    func estimee() {
        let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15))]).evaluer(usQuestion(pouces: 5, estimee: true))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.tailleEstimee(regle: "r1")))
    }

    @Test("Fenêtre protégée 14 à 18 po : dedans interdit, bornes et dehors à vérifier")
    func fenetre() {
        let w = FenetreProtegee(basse: .pouces(14), haute: .pouces(18))!
        let m = usMoteur([usRegle("r1", usWI, tailles: TaillesUS(fenetre: w))])
        #expect(m.evaluer(usQuestion(pouces: 16)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 14.01)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 17.99)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 14)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 18)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 12)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 22)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 16)).motifs.contains(.dansFenetreProtegee(regle: "r1", taille: .pouces(16), fenetre: w)))
    }

    @Test("Fenêtre mal formée (haute sous la basse) : refusée à la construction")
    func fenetreInvalide() {
        #expect(FenetreProtegee(basse: .pouces(18), haute: .pouces(14)) == nil)
        #expect(FenetreProtegee(basse: .pouces(14), haute: .pouces(14)) == nil)
    }

    @Test("Taille maximale : au-dessus interdit, égale ou dessous à vérifier")
    func maximale() {
        let m = usMoteur([usRegle("r1", usWI, tailles: TaillesUS(maximale: .pouces(28)))])
        #expect(m.evaluer(usQuestion(pouces: 30)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 28)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 20)).verdict == .aVerifier)
    }

    @Test("Minimale, fenêtre et maximale ensemble (protégé + trophée)")
    func troisBornes() {
        let w = FenetreProtegee(basse: .pouces(15), haute: .pouces(20))!
        let t = TaillesUS(minimale: .pouces(12), fenetre: w, maximale: .pouces(30))
        let m = usMoteur([usRegle("r1", usWI, tailles: t)])
        #expect(m.evaluer(usQuestion(pouces: 10)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 13)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 17)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 25)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(pouces: 31)).verdict == .interdit)
    }

    // MARK: Hiérarchie

    @Test("Le plan d'eau plus strict que l'État l'emporte : interdit au lac, État seul ailleurs")
    func lacPlusStrict() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15)), usRegle("lac", usLacX, tailles: usMin(18))])
        let auLac = m.evaluer(usQuestion(usLacX, pouces: 16.5))
        #expect(auLac.verdict == .interdit)
        #expect(auLac.regles == ["lac"])
        #expect(m.evaluer(usQuestion(usLacY, pouces: 16.5)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(usLacY, pouces: 14)).verdict == .interdit)
    }

    @Test("Le lac plus souple que l'État l'emporte, mais le verdict n'est jamais permissif : à vérifier")
    func lacPlusSouple() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15)), usRegle("lac", usLacX, tailles: usMin(12))])
        let r = m.evaluer(usQuestion(usLacX, pouces: 13))
        #expect(r.verdict == .aVerifier)
        #expect(r.regles == ["lac"])
        #expect(m.evaluer(usQuestion(usLacY, pouces: 13)).verdict == .interdit)
    }

    @Test("Chaîne complète : tronçon > lac > zone > État")
    func chaineComplete() {
        let regles = [usRegle("etat", usWI, tailles: usMin(10)), usRegle("zone", usNord, tailles: usMin(12)),
                      usRegle("lac", usLacX, tailles: usMin(14)), usRegle("tr", usTroncon, tailles: usMin(16))]
        let m = usMoteur(regles)
        #expect(m.evaluer(usQuestion(usTroncon, pouces: 15)).regles == ["tr"])
        #expect(m.evaluer(usQuestion(usTroncon, pouces: 15)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(usLacX, pouces: 15)).regles == ["lac"])
        #expect(m.evaluer(usQuestion(usLacX, pouces: 15)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(usNord, pouces: 11)).regles == ["zone"])
        #expect(m.evaluer(usQuestion(usNord, pouces: 11)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(usWI, pouces: 11)).regles == ["etat"])
        #expect(m.evaluer(usQuestion(usWI, pouces: 11)).verdict == .aVerifier)
    }

    @Test("Un niveau sauté ne gêne pas : lac sous l'État sans zone")
    func niveauSaute() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15))])
        #expect(m.evaluer(usQuestion(usLacY, pouces: 10)).verdict == .interdit)
    }

    @Test("À portée égale, la règle propre à l'espèce l'emporte sur « toutes espèces »")
    func especeSpecifique() {
        let m = usMoteur([usRegle("toutes", usWI, espece: nil, tailles: usMin(20)), usRegle("walleye", usWI, tailles: usMin(14))])
        let r = m.evaluer(usQuestion(pouces: 16))
        #expect(r.verdict == .aVerifier)
        #expect(r.regles == ["walleye"])
        let autre = m.evaluer(usQuestion(espece: "perch", pouces: 16))
        #expect(autre.verdict == .interdit)
        #expect(autre.regles == ["toutes"])
    }

    @Test("Le niveau de juridiction prime sur l'espèce : « toutes espèces » du lac bat « walleye » de l'État")
    func niveauAvantEspece() {
        let m = usMoteur([usRegle("etat-walleye", usWI, tailles: usMin(12)), usRegle("lac-toutes", usLacX, espece: nil, tailles: usMin(18))])
        let r = m.evaluer(usQuestion(usLacX, pouces: 15))
        #expect(r.regles == ["lac-toutes"])
        #expect(r.verdict == .interdit)
    }

    @Test("Une règle plus spécifique ne remplace que sa famille : la saison d'État reste, la taille du lac s'ajoute")
    func famillesIndependantes() {
        let etat = usRegle("etat", usWI, saison: usPeriode(5, 1, 10, 31), tailles: usMin(15))
        let lac = usRegle("lac", usLacX, tailles: usMin(12))
        let m = usMoteur([etat, lac])
        let horsSaison = m.evaluer(usQuestion(usLacX, jour: usJour(2026, 12, 20), pouces: 20))
        #expect(horsSaison.verdict == .interdit)
        #expect(horsSaison.motifs.contains(.horsSaison(regle: "etat")))
        #expect(Set(m.evaluer(usQuestion(usLacX, pouces: 13)).regles) == ["etat", "lac"])
    }

    // MARK: Conflits

    @Test("Deux règles de même niveau qui se contredisent, une seule violée : à vérifier avec le conflit")
    func conflitUneViolee() {
        let m = usMoteur([usRegle("a", usWI, tailles: usMin(14)), usRegle("b", usWI, tailles: usMin(15))])
        let r = m.evaluer(usQuestion(pouces: 14.5))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.conflitEntreRegles(famille: .taille, regles: ["a", "b"])))
    }

    @Test("Conflit même sans taille mesurée : à vérifier")
    func conflitSansTaille() {
        let m = usMoteur([usRegle("a", usWI, tailles: usMin(14)), usRegle("b", usWI, tailles: usMin(15))])
        let r = m.evaluer(usQuestion())
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.conflitEntreRegles(famille: .taille, regles: ["a", "b"])))
    }

    @Test("Deux règles de même niveau qui interdisent toutes deux : interdit (pas de désaccord sur l'interdiction)")
    func conflitDeuxViolees() {
        let m = usMoteur([usRegle("a", usWI, tailles: usMin(14)), usRegle("b", usWI, tailles: usMin(15))])
        #expect(m.evaluer(usQuestion(pouces: 10)).verdict == .interdit)
    }

    @Test("Deux copies identiques d'une règle ne font pas un conflit")
    func doublonIdentique() {
        let m = usMoteur([usRegle("a", usWI, tailles: usMin(15)), usRegle("b", usWI, tailles: usMin(15))])
        let r = m.evaluer(usQuestion(pouces: 20))
        #expect(r.verdict == .aVerifier)
        #expect(!r.motifs.contains { if case .conflitEntreRegles = $0 { true } else { false } })
    }

    @Test("Conflit de saison entre deux règles de même niveau : à vérifier")
    func conflitSaison() {
        let m = usMoteur([usRegle("a", usWI, saison: usPeriode(5, 1, 10, 31)), usRegle("b", usWI, saison: usPeriode(5, 15, 10, 31))])
        let r = m.evaluer(usQuestion(jour: usJour(2026, 5, 5)))
        #expect(r.verdict == .aVerifier)
    }

    @Test("Un conflit dans une famille ne masque pas une interdiction certaine d'une autre")
    func conflitPuisInterdiction() {
        let regles = [usRegle("a", usWI, tailles: usMin(14)), usRegle("b", usWI, tailles: usMin(15)),
                      usRegle("c", usWI, fermetures: [FermetureUS(type: .pecheInterdite, motif: "frayère")])]
        #expect(usMoteur(regles).evaluer(usQuestion(pouces: 14.5)).verdict == .interdit)
    }

    // MARK: Saison et fermetures

    @Test("Saison qui enjambe le 31 déc. : dedans, dehors et bornes")
    func saisonEnjambe() {
        let m = usMoteur([usRegle("r1", usWI, saison: usPeriode(5, 1, 2, 28))])
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 7, 10))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 1, 15))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 3, 15))).verdict == .interdit)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 4, 30))).verdict == .interdit)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 5, 1))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 2, 28))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 3, 15))).motifs.contains(.horsSaison(regle: "r1")))
    }

    @Test("Saison dans l'année : hors, dedans, bornes")
    func saisonSimple() {
        let m = usMoteur([usRegle("r1", usWI, saison: usPeriode(5, 1, 10, 31))])
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 11, 1))).verdict == .interdit)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 4, 30))).verdict == .interdit)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 10, 31))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 8, 1))).verdict == .aVerifier)
    }

    @Test("Fermeture permanente, fermeture de frai, et espèce protégée")
    func fermetures() {
        let permanente = FermetureUS(type: .pecheInterdite, motif: "eau fermée")
        let frai = FermetureUS(type: .remiseAEauSeulement, periode: usPeriode(4, 1, 5, 15), motif: "frai")
        let protegee = FermetureUS(type: .especeProtegee, motif: "liste d'État")
        #expect(usMoteur([usRegle("p", usWI, fermetures: [permanente])]).evaluer(usQuestion()).verdict == .interdit)
        #expect(usMoteur([usRegle("p", usWI, fermetures: [protegee])]).evaluer(usQuestion()).verdict == .interdit)
        let m = usMoteur([usRegle("f", usWI, fermetures: [frai])])
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 4, 20))).verdict == .interdit)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 6, 1))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 4, 1))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2026, 5, 15))).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(jour: usJour(2027, 4, 20))).motifs.contains(.fermeture(regle: "f", type: .remiseAEauSeulement, motif: "frai")))
    }

    @Test("Un plan d'eau rouvert par une règle locale n'est pas permissif : à vérifier")
    func fermetureLevee() {
        let ferme = FermetureUS(type: .pecheInterdite, motif: "fermé")
        let m = usMoteur([usRegle("etat", usWI, fermetures: [ferme]), usRegle("lac", usLacX, saison: usPeriode(1, 1, 12, 31))])
        let r = m.evaluer(usQuestion(usLacX, jour: usJour(2026, 7, 10)))
        #expect(r.verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(usLacY)).verdict == .interdit)
    }

    // MARK: Limites, engins, appâts

    @Test("Limite de prise : atteinte interdit, en dessous ou inconnue à vérifier")
    func limitePrise() {
        let m = usMoteur([usRegle("r1", usWI, limites: LimitesUS(prise: 5, possession: 10))])
        #expect(m.evaluer(usQuestion(prises: 5)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(prises: 7)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(prises: 4)).verdict == .aVerifier)
        let inconnu = m.evaluer(usQuestion())
        #expect(inconnu.verdict == .aVerifier)
        #expect(inconnu.motifs.contains(.compteursInconnus(regle: "r1")))
    }

    @Test("Limite de possession distincte de la limite de prise")
    func limitePossession() {
        let m = usMoteur([usRegle("r1", usWI, limites: LimitesUS(prise: 5, possession: 10))])
        let r = m.evaluer(usQuestion(prises: 2, possession: 10))
        #expect(r.verdict == .interdit)
        #expect(r.motifs.contains(.limiteDePossessionAtteinte(regle: "r1", limite: 10)))
        #expect(!r.motifs.contains(.limiteDePriseAtteinte(regle: "r1", limite: 5)))
    }

    @Test("Engins et appâts : jamais évalués, toujours à vérifier avec le motif")
    func enginsAppats() {
        let m = usMoteur([usRegle("r1", usWI, engins: ["2 lignes au plus"], appats: ["poissons-appâts vivants interdits"])])
        let r = m.evaluer(usQuestion())
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.enginsOuAppatsALire(regle: "r1")))
    }

    // MARK: Âge

    @Test("Règle propre à une tranche d'âge : âge inconnu, dans la tranche, hors tranche")
    func age() {
        let m = usMoteur([usRegle("r1", usWI, tailles: usMin(15), age: ConditionAge(ageMin: 16))])
        let inconnu = m.evaluer(usQuestion(pouces: 10))
        #expect(inconnu.verdict == .aVerifier)
        #expect(inconnu.motifs.contains(.ageInconnu(regle: "r1")))
        #expect(m.evaluer(usQuestion(pouces: 10, age: 30)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(pouces: 10, age: 16)).verdict == .interdit)
        let enfant = m.evaluer(usQuestion(pouces: 10, age: 15))
        #expect(enfant.verdict == .aVerifier)
        #expect(enfant.motifs.contains(.regleHorsTrancheDAge(regle: "r1")))
    }

    @Test("Hors tranche d'âge, la règle plus large reste appliquée")
    func ageRegleLargeRestante() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15)), usRegle("lac-adultes", usLacX, tailles: usMin(20), age: ConditionAge(ageMin: 16))])
        #expect(m.evaluer(usQuestion(usLacX, pouces: 17, age: 12)).verdict == .aVerifier)
        #expect(m.evaluer(usQuestion(usLacX, pouces: 13, age: 12)).verdict == .interdit)
        #expect(m.evaluer(usQuestion(usLacX, pouces: 17, age: 40)).verdict == .interdit)
    }

    // MARK: Statut, validité, ancienneté

    @Test("Règle non relue ou aux lectures divergentes : jamais interdit")
    func statutsNonConfirmes() {
        for statut in [StatutRelecture.nonRelue, .lecturesDivergentes] {
            let r = usMoteur([usRegle("r1", usWI, tailles: usMin(15), statut: statut)]).evaluer(usQuestion(pouces: 5))
            #expect(r.verdict == .aVerifier)
            #expect(r.motifs.contains(.regleNonConfirmee(regle: "r1", statut: statut)))
        }
        for statut in [StatutRelecture.doubleLectureConfirmee, .relueParPersonne] {
            #expect(usMoteur([usRegle("r1", usWI, tailles: usMin(15), statut: statut)]).evaluer(usQuestion(pouces: 5)).verdict == .interdit)
        }
    }

    @Test("Une règle plus spécifique non confirmée ne laisse pas filer l'interdiction d'État : à vérifier")
    func specifiqueIncertaine() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15)), usRegle("lac", usLacX, tailles: usMin(12), statut: .nonRelue)])
        #expect(m.evaluer(usQuestion(usLacX, pouces: 13)).verdict == .aVerifier)
    }

    @Test("Règle expirée : à vérifier ; le dernier jour de validité compte encore")
    func expiration() {
        let m = usMoteur([usRegle("r1", usWI, tailles: usMin(15), valideJusqua: usEte)])
        #expect(m.evaluer(usQuestion(jour: usEte, pouces: 5)).verdict == .interdit)
        let apres = m.evaluer(usQuestion(jour: usEte.ajouter(jours: 1), pouces: 5))
        #expect(apres.verdict == .aVerifier)
        #expect(apres.motifs.contains(.regleExpiree(regle: "r1")))
    }

    @Test("Lecture trop ancienne : à vérifier ; seuil réglable")
    func lectureAncienne() {
        let vieille = usSource(usJour(2025, 1, 1))
        let m = usMoteur([usRegle("r1", usWI, tailles: usMin(15), source: vieille)])
        let r = m.evaluer(usQuestion(pouces: 5))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains { if case .lectureAncienne = $0 { true } else { false } })
        let large = usMoteur([usRegle("r1", usWI, tailles: usMin(15), source: vieille)], parametres: ParametresMoteurUS(ageMaxLectureJours: 1000))
        #expect(large.evaluer(usQuestion(pouces: 5)).verdict == .interdit)
    }

    @Test("Date de lecture dans le futur : donnée incohérente, à vérifier")
    func lectureFuture() {
        let m = usMoteur([usRegle("r1", usWI, tailles: usMin(15), source: usSource(usEte.ajouter(jours: 3)))])
        let r = m.evaluer(usQuestion(pouces: 5))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.lectureDansLeFutur(regle: "r1")))
    }

    // MARK: Terrains à alerte

    @Test("Réserve tribale : une règle d'État ne dit jamais « interdit », une règle de la réserve oui")
    func tribal() {
        let m = usMoteur([usRegle("etat", usWI, tailles: usMin(15))])
        let r = m.evaluer(usQuestion(usLacTribal, pouces: 5))
        #expect(r.verdict == .aVerifier)
        #expect(r.motifs.contains(.reglesDEtatSurTerrainTribal(regle: "etat")))
        #expect(r.alertes == [.reserveTribale])
        #expect(r.motifs.contains(.alerteTerrain(.reserveTribale, juridiction: usReserve)))
        let propre = usMoteur([usRegle("etat", usWI, tailles: usMin(15)), usRegle("tribu", usReserve, tailles: usMin(18))])
        #expect(propre.evaluer(usQuestion(usLacTribal, pouces: 16)).verdict == .interdit)
        #expect(propre.evaluer(usQuestion(usLacX, pouces: 14)).verdict == .interdit)   // hors réserve, l'État s'applique normalement
    }

    @Test("Les alertes de toute la chaîne remontent, sans doublon, et ne disparaissent pas devant une règle plus fine")
    func alertes() throws {
        let wi = Juridiction.etat(usEtat("WI"), nom: "WI", alertes: [.eauFrontaliere])!
        let parc = Juridiction(id: usNord, niveau: .zone, nom: "Parc", etat: usEtat("WI"), parent: usWI, alertes: [.parcNational, .eauFrontaliere])!
        let lac = Juridiction(id: usLacX, niveau: .planDeau, nom: "X", etat: usEtat("WI"), parent: usNord, alertes: [.especeListeeESA])!
        let moteur = MoteurUS(arbre: try ArbreJuridictions([wi, parc, lac]), regles: [usRegle("r", usLacX, tailles: usMin(15))])
        let r = moteur.evaluer(usQuestion(usLacX, pouces: 20))
        #expect(Set(r.alertes) == [.eauFrontaliere, .parcNational, .especeListeeESA])
        #expect(r.alertes.count == 3)
        #expect(r.verdict == .aVerifier)
    }

    // MARK: Exigences, sources, lien

    @Test("Exigences cumulées le long de la chaîne : permis d'État, timbre de zone, permis tribal ; pas celles d'un frère")
    func exigences() {
        let e1 = ExigenceUS(id: "permis", portee: usWI, type: .permis, nom: "Licence", prixDollars: nil, source: usSource())
        let e2 = ExigenceUS(id: "timbre", portee: usNord, type: .timbre, nom: "Timbre truite", prixDollars: 15, exempteMoinsDe: 16, source: usSource())
        let e3 = ExigenceUS(id: "tribal", portee: usReserve, type: .permisTribal, nom: "Permis tribal", source: usSource())
        let moteur = usMoteur([], exigences: [e3, e2, e1])
        #expect(moteur.evaluer(usQuestion(usLacX)).exigences.map(\.id) == ["permis", "timbre"])
        #expect(moteur.evaluer(usQuestion(usLacTribal)).exigences.map(\.id) == ["permis", "tribal"])
        #expect(moteur.evaluer(usQuestion(usLacY)).exigences.map(\.id) == ["permis"])
        #expect(moteur.evaluer(usQuestion(usLacX)).exigences.last?.type == .timbre)
        #expect(e2.prixDollars == 15 && e1.prixDollars == nil)
    }

    @Test("Lien de l'agence : le plus proche de la chaîne, sinon celui de l'État")
    func lien() {
        let m = usMoteur([usRegle("r", usWI, tailles: usMin(15))])
        #expect(m.evaluer(usQuestion(usLacX, pouces: 20)).lienAgence == usLienNord)
        #expect(m.evaluer(usQuestion(usLacY, pouces: 20)).lienAgence == usLienWI)
        #expect(usMoteur([]).evaluer(usQuestion(usMI)).lienAgence == nil)
    }

    @Test("Sources : triées de la plus récente à la plus ancienne, sans doublon d'adresse ; lecture la plus ancienne et couverture")
    func sources() {
        let s1 = usSource(usJour(2026, 5, 1), url: "https://agence.exemple.test/a")
        let s2 = usSource(usJour(2026, 6, 1), url: "https://agence.exemple.test/b")
        let s3 = usSource(usJour(2026, 6, 10), url: "https://agence.exemple.test/b")
        let regles = [usRegle("etat", usWI, saison: usPeriode(1, 1, 12, 31), source: s1, couverture: .niveau2),
                      usRegle("lac", usLacX, tailles: usMin(12), source: s2, couverture: .niveau3),
                      usRegle("lac2", usLacX, limites: LimitesUS(prise: 5), source: s3, couverture: .niveau3)]
        let r = usMoteur(regles).evaluer(usQuestion(usLacX, pouces: 20, prises: 0))
        #expect(r.sources.map(\.url.absoluteString) == ["https://agence.exemple.test/b", "https://agence.exemple.test/a"])
        #expect(r.lectureLaPlusAncienne == usJour(2026, 5, 1))
        #expect(r.couverture == .niveau3)
    }

    @Test("Une source sans adresse web valide ou sans hôte ne se construit pas")
    func sourceInvalide() {
        #expect(SourceUS(url: "", dateLecture: usLecture) == nil)
        #expect(SourceUS(url: "ftp://agence.exemple.test/x", dateLecture: usLecture) == nil)
        #expect(SourceUS(url: "agence.exemple.test/x", dateLecture: usLecture) == nil)
        #expect(SourceUS(url: "https:///x", dateLecture: usLecture) == nil)
        #expect(SourceUS(url: "http://agence.exemple.test/x", dateLecture: usLecture) != nil)
    }

    @Test("Périodes annuelles : jours impossibles refusés, 29 février accepté")
    func moisJour() {
        #expect(MoisJour(mois: 2, jour: 29) != nil)
        #expect(MoisJour(mois: 2, jour: 30) == nil)
        #expect(MoisJour(mois: 4, jour: 31) == nil)
        #expect(MoisJour(mois: 13, jour: 1) == nil)
        #expect(MoisJour(mois: 0, jour: 1) == nil)
        #expect(MoisJour(mois: 1, jour: 0) == nil)
    }

    @Test("RegleUS : aller-retour JSON exact")
    func codableRegle() throws {
        let w = FenetreProtegee(basse: .pouces(14), haute: .pouces(18))!
        let r = usRegle("r1", usLacX, saison: usPeriode(5, 1, 2, 28), tailles: TaillesUS(minimale: .pouces(12), fenetre: w, maximale: .pouces(30)),
                        limites: LimitesUS(prise: 5, possession: 10), engins: ["2 lignes"], appats: ["sans vifs"],
                        fermetures: [FermetureUS(type: .remiseAEauSeulement, periode: usPeriode(4, 1, 5, 15), motif: "frai")],
                        age: ConditionAge(ageMin: 16), couverture: .niveau3, valideJusqua: usJour(2026, 12, 31))
        let data = try JSONEncoder().encode(r)
        #expect(try JSONDecoder().decode(RegleUS.self, from: data) == r)
    }

    @Test("Niveaux de couverture 1, 2, 3 ordonnés et la règle de niveau 3 remonte")
    func couverture() {
        #expect(CouvertureUS.niveau1 < .niveau2 && CouvertureUS.niveau2 < .niveau3)
        #expect(CouvertureUS(rawValue: 3) == .niveau3)
        let r = usMoteur([usRegle("r", usLacX, tailles: usMin(15), couverture: .niveau3)]).evaluer(usQuestion(pouces: 20))
        #expect(r.couverture == .niveau3)
    }
}
