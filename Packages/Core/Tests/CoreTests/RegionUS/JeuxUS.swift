import Foundation
@testable import Core

// Jeux d'essai de la région US. Aucune donnée réelle : États, plans d'eau, règles et URL sont inventés pour les tests.

func usJour(_ a: Int, _ m: Int, _ j: Int) -> JourCivil { JourCivil(annee: a, mois: m, jour: j)! }
func usEtat(_ s: String) -> CodeEtat { CodeEtat(rawValue: s)! }
func usId(_ s: String) -> IdJuridiction { IdJuridiction(rawValue: s)! }
func usPeriode(_ m1: Int, _ j1: Int, _ m2: Int, _ j2: Int) -> PeriodeAnnuelle {
    PeriodeAnnuelle(debut: MoisJour(mois: m1, jour: j1)!, fin: MoisJour(mois: m2, jour: j2)!)
}

/// Jour de référence des questions : un jour d'été, bien dans la saison des règles d'essai.
let usEte = usJour(2026, 7, 10)
/// Lecture des règles d'essai : récente par rapport à `usEte`.
let usLecture = usJour(2026, 6, 20)

func usSource(_ lecture: JourCivil = usLecture, url: String = "https://agence.exemple.test/reglements") -> SourceUS {
    SourceUS(url: url, dateLecture: lecture, edition: "Édition d'essai 2026")!
}

let usWI = usId("US-WI")
let usNord = usId("US-WI/nord")
let usLacX = usId("US-WI/lac-x")
let usTroncon = usId("US-WI/lac-x/tr1")
let usLacY = usId("US-WI/lac-y")
let usReserve = usId("US-WI/reserve-z")
let usLacTribal = usId("US-WI/reserve-z/lac-t")
let usMI = usId("US-MI")

let usLienWI = URL(string: "https://agence-wi.exemple.test/peche")!
let usLienNord = URL(string: "https://agence-wi.exemple.test/nord")!

/// Wisconsin d'essai : État → zone « nord » → lac X → tronçon ; lac Y directement sous l'État ; réserve tribale Z → lac T ; Michigan à côté.
func usArbre() -> ArbreJuridictions {
    let wi = Juridiction.etat(usEtat("WI"), nom: "Wisconsin d'essai", lienAgence: usLienWI)!
    let mi = Juridiction.etat(usEtat("MI"), nom: "Michigan d'essai")!
    let nord = Juridiction(id: usNord, niveau: .zone, nom: "Zone nord", etat: usEtat("WI"), parent: usWI, lienAgence: usLienNord)!
    let lacX = Juridiction(id: usLacX, niveau: .planDeau, nom: "Lac X", etat: usEtat("WI"), parent: usNord, huc8: "07070001")!
    let tr = Juridiction(id: usTroncon, niveau: .troncon, nom: "Tronçon amont", etat: usEtat("WI"), parent: usLacX)!
    let lacY = Juridiction(id: usLacY, niveau: .planDeau, nom: "Lac Y", etat: usEtat("WI"), parent: usWI)!
    let res = Juridiction(id: usReserve, niveau: .zone, nom: "Réserve Z", etat: usEtat("WI"), parent: usWI, alertes: [.reserveTribale])!
    let lacT = Juridiction(id: usLacTribal, niveau: .planDeau, nom: "Lac T", etat: usEtat("WI"), parent: usReserve)!
    return try! ArbreJuridictions([wi, mi, nord, lacX, tr, lacY, res, lacT])
}

func usRegle(_ id: String, _ portee: IdJuridiction, espece: String? = "walleye", saison: PeriodeAnnuelle? = nil, tailles: TaillesUS = TaillesUS(),
             limites: LimitesUS = LimitesUS(), engins: [String] = [], appats: [String] = [], fermetures: [FermetureUS] = [],
             age: ConditionAge? = nil, source: SourceUS? = nil, couverture: CouvertureUS = .niveau2,
             statut: StatutRelecture = .doubleLectureConfirmee, valideJusqua: JourCivil? = nil) -> RegleUS {
    RegleUS(id: id, portee: portee, espece: espece, saison: saison, tailles: tailles, limites: limites, engins: engins, appats: appats,
            fermetures: fermetures, age: age, source: source ?? usSource(), couverture: couverture, statut: statut, valideJusqua: valideJusqua)
}

func usMin(_ pouces: Double) -> TaillesUS { TaillesUS(minimale: .pouces(pouces)) }

func usMoteur(_ regles: [RegleUS], exigences: [ExigenceUS] = [], parametres: ParametresMoteurUS = ParametresMoteurUS()) -> MoteurUS {
    MoteurUS(arbre: usArbre(), regles: regles, exigences: exigences, parametres: parametres)
}

func usQuestion(_ lieu: IdJuridiction = usLacX, espece: String = "walleye", jour: JourCivil = usEte, pouces: Double? = nil, estimee: Bool = false,
                age: Int? = nil, prises: Int? = nil, possession: Int? = nil) -> QuestionUS {
    QuestionUS(espece: espece, juridiction: lieu, jour: jour, taille: pouces.map { .pouces($0) }, tailleEstimee: estimee, age: age,
               prisesGardeesAujourdhui: prises, enPossession: possession)
}

/// Mots que l'app ne dit jamais (décision 3 du 7 nov. et décision 10 du 19 oct.).
let usMotsInterdits = ["autoris", "tu peux", "peux la garder", "peut garder", "peut la garder", "légal", "legal", "allowed", "you can keep", "en règle"]
