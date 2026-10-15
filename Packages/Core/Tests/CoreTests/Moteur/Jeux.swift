import Foundation
@testable import Core

// Jeux d'essai des tests du moteur. Aucune donnée réelle de D1 ni de D2 n'est lue : les contours, les stations et les règles sont
// écrits ici, simplifiés, avec des codes Sandre d'essai. Les tests lisent les moteurs, jamais Resources/.

/// Un instant UTC : année, mois, jour, heure, minute.
func utc(_ a: Int, _ m: Int, _ j: Int, _ h: Int = 12, _ mi: Int = 0, _ s: Int = 0) -> Date {
    Calendar.utcGregorien.date(from: DateComponents(year: a, month: m, day: j, hour: h, minute: mi, second: s))!
}

/// Le 15 oct. 2026 à midi UTC : la date de référence des cas d'or.
let quinzeOctobre = utc(2026, 10, 15)

// MARK: Points

let charenton = Coordonnee(latitude: 48.822, longitude: 2.413)
let paris = Coordonnee(latitude: 48.8566, longitude: 2.3522)
let nanterre = Coordonnee(latitude: 48.892, longitude: 2.207)
let saintDenis = Coordonnee(latitude: 48.936, longitude: 2.357)
let meaux = Coordonnee(latitude: 48.96, longitude: 2.88)
let cupertino = Coordonnee(latitude: 37.3230, longitude: -122.0322)
let creteilLac = Coordonnee(latitude: 48.78, longitude: 2.462)
let mareilSurMauldre = Coordonnee(latitude: 48.89, longitude: 1.80)
/// À 44 m de la limite entre le 94 et le 75.
let limite94et75 = Coordonnee(latitude: 48.8346, longitude: 2.35)

// MARK: Contours (rectangles simplifiés autour des vraies villes)

private func rectangle(_ lonMin: Double, _ latMin: Double, _ lonMax: Double, _ latMax: Double) -> [[Double]] {
    [[lonMin, latMin], [lonMax, latMin], [lonMax, latMax], [lonMin, latMax], [lonMin, latMin]]
}

private func feature(_ props: [String: Any], polygone: [[[Double]]]) -> [String: Any] {
    ["type": "Feature", "properties": props, "geometry": ["type": "Polygon", "coordinates": polygone]]
}

private func featureMulti(_ props: [String: Any], _ morceaux: [[[[Double]]]]) -> [String: Any] {
    ["type": "Feature", "properties": props, "geometry": ["type": "MultiPolygon", "coordinates": morceaux]]
}

func geoJSON(_ features: [[String: Any]]) -> Data {
    try! JSONSerialization.data(withJSONObject: ["type": "FeatureCollection", "features": features])
}

let departementsEssai: Data = geoJSON([
    feature(["code": "75", "nom": "Paris"], polygone: [rectangle(2.25, 48.835, 2.42, 48.90)]),
    feature(["code": "94", "nom": "Val-de-Marne"], polygone: [rectangle(2.30, 48.70, 2.62, 48.835)]),
    feature(["code": "92", "nom": "Hauts-de-Seine"], polygone: [rectangle(2.10, 48.75, 2.25, 48.95)]),
    // Le 93 en deux morceaux (MultiPolygon).
    featureMulti(["code": "93", "nom": "Seine-Saint-Denis"], [[rectangle(2.25, 48.90, 2.40, 48.98)], [rectangle(2.45, 48.90, 2.60, 48.98)]]),
    // Le 77 avec un trou (un faux enclave de 0,1°) : un point dedans n'est pas dans le 77.
    feature(["code": "77", "nom": "Seine-et-Marne"], polygone: [rectangle(2.62, 48.50, 3.20, 49.10), rectangle(3.00, 48.80, 3.10, 48.90)]),
    feature(["code": "78", "nom": "Yvelines"], polygone: [rectangle(1.60, 48.70, 2.05, 49.00)]),
    feature(["code": "01", "nom": "Ain"], polygone: [rectangle(4.90, 45.90, 5.80, 46.40)]),
])

let lacsEssai: Data = geoJSON([
    feature(["nom": "Lac de Créteil", "code": "lac-creteil"], polygone: [rectangle(2.455, 48.775, 2.470, 48.785)]),
])

// MARK: Espèces (codes Sandre d'essai)

let especesEssai: Data = {
    func e(_ id: String, _ nom: String, _ code: String?, classe: String?, statut: [String] = [], suivi: Bool = true,
           confusions: [[String: String]] = []) -> [String: Any] {
        var d: [String: Any] = ["id": id, "nom": nom, "latin": "latin", "classe_modele": classe as Any, "statut": statut,
                                "suivi_ofb": suivi, "image": id, "confusions": confusions]
        if let code { d["code_sandre"] = code }
        if classe == nil { d["classe_modele"] = NSNull() }
        return d
    }
    let liste: [[String: Any]] = [
        e("brochet", "Brochet", "2151", classe: "brochet", confusions: [["avec": "sandre", "critere": "Museau en bec de canard", "source": "MNHN 2017"]]),
        e("sandre", "Sandre", "2195", classe: "sandre"),
        e("perche-commune", "Perche", "2193", classe: "perche"),
        e("gardon", "Gardon", "2180", classe: "gardon"),
        e("chevesne", "Chevesne", "2181", classe: "chevesne"),
        e("silure-glane", "Silure", "2182", classe: "silure"),
        e("barbeau-fluviatile", "Barbeau", "2183", classe: "barbeau"),
        e("breme-commune", "Brème", "2184", classe: "breme"),
        e("tanche", "Tanche", "2185", classe: "tanche"),
        e("black-bass", "Black-bass", "2053", classe: "black-bass"),
        e("carpe-commune", "Carpe", "2186", classe: "carpe"),
        e("truite-fario", "Truite fario", "2221", classe: "truite fario"),
        e("truite-arc-en-ciel", "Truite arc-en-ciel", "2216", classe: "truite arc-en-ciel"),
        e("ombre-commun", "Ombre commun", "2247", classe: "ombre"),
        e("grenouille-verte", "Grenouille verte", nil, classe: "grenouille", suivi: false),
        e("lamproie-marine", "Lamproie marine", "2187", classe: "lamproie", statut: ["protegee"]),
        e("lamproie-fluviatile", "Lamproie fluviatile", "2188", classe: "lamproie", statut: ["protegee"]),
        e("esturgeon-europeen", "Esturgeon européen", "2189", classe: "esturgeon", statut: ["protegee", "toujours_relachee"]),
        e("anguille-jaune", "Anguille jaune", "2190", classe: "anguille", statut: ["stade_a_demander"]),
        e("autre-poisson", "Autre poisson", nil, classe: "autre poisson"),
    ]
    return try! JSONSerialization.data(withJSONObject: liste)
}()

let longueurPoidsEssai: Data = {
    // Brochet : W = 0,003208 × L^3,17 donne environ 1,39 kg à 60 cm ; carpe : coefficients d'essai calés sur 3,6 kg à 60 cm.
    let liste: [[String: Any]] = [
        ["espece": "brochet", "a": 0.003208, "b": 3.17, "lt_min_cm": 20, "lt_max_cm": 100, "n": 1464, "region": "Flandre", "source": "Verreycken et al. 2011"],
        ["espece": "carpe-commune", "a": 0.015356, "b": 3.02, "lt_min_cm": 15, "lt_max_cm": 90, "n": 200, "region": "essai", "source": "Coefficients d'essai"],
    ]
    return try! JSONSerialization.data(withJSONObject: liste)
}()

// MARK: Stations OFB

let stationsOFBEssai: Data = {
    func s(_ id: String, _ lat: Double, _ lon: Double, _ dep: String, eau: String?, codeEau: String?, peches: Int, derniere: Int, vues: [String: Int]) -> [String: Any] {
        var d: [String: Any] = ["id": id, "lat": lat, "lon": lon, "dep": dep, "peches": peches, "derniere": derniere, "vues": vues]
        if let eau { d["eau"] = eau }
        if let codeEau { d["code_eau"] = codeEau }
        return d
    }
    let liste: [[String: Any]] = [
        // Sur la Marne, à 150 m de Charenton : brochet, perche, sandre et la truite fario (fermée à cette date).
        s("S1", 48.8235, 2.4160, "94", eau: "La Marne", codeEau: "F6--0020", peches: 10, derniere: 2025, vues: ["2151": 4, "2193": 9, "2195": 1]),
        s("S2", 48.80, 2.45, "94", eau: "La Marne", codeEau: "F6--0020", peches: 6, derniere: 2024, vues: ["2193": 5, "2151": 2]),
        // Une station du 94 dont l'unique espèce relevée, la truite fario, est fermée ce jour-là.
        s("S3", 48.7600, 2.4000, "94", eau: "Le Morbras", codeEau: "F6--0030", peches: 3, derniere: 2025, vues: ["2221": 3]),
        // Une station du 94 aux relevés trop anciens (2009).
        s("S4", 48.8300, 2.3800, "94", eau: "La Marne", codeEau: "F6--0020", peches: 2, derniere: 2009, vues: ["2151": 2]),
        // Sur la Mauldre (78).
        s("M1", 48.8910, 1.8030, "78", eau: "La Mauldre", codeEau: "F7--0010", peches: 4, derniere: 2024, vues: ["2193": 2]),
        // Un point isolé, loin de tout.
        s("L1", 46.00, 5.00, "01", eau: "L'Ain", codeEau: "V---0000", peches: 5, derniere: 2025, vues: ["2151": 1]),
    ]
    return try! JSONSerialization.data(withJSONObject: liste)
}()

let raretesEssai: Data = {
    // 94 : 29 pêches sur 10 ans (`docs/donnees.md`, « Attendu dans le 94 »).
    let e: [String: Any] = [
        "2193": ["peches": 25, "derniere": 2025], "2180": ["peches": 20, "derniere": 2025], "2181": ["peches": 17, "derniere": 2025],
        "2151": ["peches": 8, "derniere": 2025], "2182": ["peches": 7, "derniere": 2024], "2183": ["peches": 6, "derniere": 2024],
        "2195": ["peches": 3, "derniere": 2023], "2184": ["peches": 4, "derniere": 2023], "2185": ["peches": 2, "derniere": 2022],
        "2053": ["peches": 2, "derniere": 2022], "2186": ["peches": 1, "derniere": 2021],
    ]
    let racine: [String: Any] = [
        "source": "essai",
        "departements": [
            "94": ["region": "11", "dix_ans": ["peches": 29, "especes": e], "historique": ["peches": 90, "especes": ["2221": ["peches": 1, "derniere": 1998]]]],
            // Paris : 12 pêches seulement, donc le calcul passe à la région.
            "75": ["region": "11", "dix_ans": ["peches": 12, "especes": ["2193": ["peches": 3, "derniere": 2014]]], "historique": ["peches": 36, "especes": [:]]],
        ],
        "regions": [
            "11": ["dix_ans": ["peches": 400, "especes": ["2193": ["peches": 240, "derniere": 2025], "2151": ["peches": 120, "derniere": 2025], "2195": ["peches": 30, "derniere": 2025]]],
                   "historique": ["peches": 900, "especes": [:]]],
        ],
    ]
    return try! JSONSerialization.data(withJSONObject: racine)
}()

// MARK: Règles

/// Une règle au format de `docs/donnees.md` (`regles/<code>.json`).
func regle(_ id: String, _ type: String, especes: [String] = [], cat: String = "toutes", niveau: String = "national", code: String? = nil,
           eau: String? = nil, lieu: String? = nil, du: String? = nil, au: String? = nil, valeur: [String: Any] = [:],
           phrase: String, textes: [String] = ["t1"], statut: String = "brouillon", expire: String? = nil,
           remplace: String? = nil) -> [String: Any] {
    var portee: [String: Any] = ["niveau": niveau]
    if let code { portee["code"] = code }
    if let eau { portee["eau"] = eau }
    if let lieu { portee["lieu"] = lieu }
    var r: [String: Any] = ["id": id, "type": type, "especes": especes, "categorie": cat, "portee": portee, "valeur": valeur,
                            "phrase": phrase, "textes": textes, "citation": "citation d'essai", "statut": statut]
    if let du { r["du"] = du }
    if let au { r["au"] = au }
    if let expire { r["expire_le"] = expire }
    if let remplace { r["remplace"] = remplace }
    return r
}

func fichierRegles(version: String = "2026-10-15.1", departement: String, niveau: String = "complet", textes: [[String: Any]] = [],
                   eaux: [[String: Any]] = [], regles: [[String: Any]], aVerifier: [[String: Any]] = []) -> Data {
    let racine: [String: Any] = ["version": version, "departement": departement, "niveau": niveau,
                                 "textes": textes.isEmpty ? [["id": "t1", "titre": "Texte d'essai", "url": "https://example.org/t1", "lu_le": "2026-10-15"]] : textes,
                                 "eaux": eaux, "regles": regles, "a_verifier": aVerifier]
    return try! JSONSerialization.data(withJSONObject: racine)
}

let nationalEssai: Data = fichierRegles(departement: "national", textes: [["id": "t1", "titre": "Code de l'environnement (essai)", "url": "https://example.org/code", "lu_le": "2026-10-12"]], regles: [
    regle("nat-hor-horaire", "horaire", valeur: ["avant_lever_min": 30, "apres_coucher_min": 30], phrase: "Pêche interdite plus d'une demi-heure avant le lever et après le coucher du soleil."),
    regle("nat-bro-taille", "taille_min", especes: ["2151"], valeur: ["cm": 50], phrase: "Brochet : 50 cm minimum."),
    regle("nat-san-taille", "taille_min", especes: ["2195"], cat: "2", valeur: ["cm": 40], phrase: "Sandre : 40 cm minimum en 2e catégorie."),
    regle("nat-bla-taille", "taille_min", especes: ["2053"], cat: "2", valeur: ["cm": 30], phrase: "Black-bass : 30 cm minimum en 2e catégorie."),
    regle("nat-car-quota", "quota_jour", especes: ["2151", "2195", "2053"], cat: "2", valeur: ["total": 3, "dont_brochet": 2],
          phrase: "Sandre, brochet et black-bass : 3 par jour dont 2 brochets au maximum en 2e catégorie."),
    regle("nat-tru-ferme", "interdit", especes: ["2221"], du: "2026-09-21", au: "2027-03-12", valeur: ["raison": "fermeture"],
          phrase: "Truite fario : pêche fermée du 21 septembre 2026 au 12 mars 2027."),
    regle("nat-bro-ouv-1re", "ouverture", especes: ["2151"], cat: "1", du: "2026-03-14", au: "2026-09-20", phrase: "Brochet en 1re catégorie : ouvert du 14 mars au 20 septembre."),
    regle("nat-bro-ferme-2e", "interdit", especes: ["2151"], cat: "2", du: "2026-01-25", au: "2026-04-24", phrase: "Brochet en 2e catégorie : fermé du 25 janvier au 24 avril."),
    regle("nat-ecr-vivant", "transport_vivant", especes: ["ecrevisse-signal"], phrase: "Écrevisse signal : transport vivant interdit (arrêté du 14/02/2018)."),
])

let dep94Essai: Data = fichierRegles(departement: "94", textes: [
    ["id": "t1", "titre": "Avis annuel 2026 Val-de-Marne", "url": "https://example.org/avis-94-2026", "lu_le": "2026-10-15"],
    ["id": "t2", "titre": "Arrêté permanent 2025 Val-de-Marne", "url": "https://example.org/arrete-94-2025", "lu_le": "2026-10-15"],
    ["id": "t3", "titre": "Arrêté 2010-5378", "url": "https://example.org/arrete-2010-5378", "lu_le": "2026-10-15"],
], eaux: [["cle": "marne", "nom": "Marne", "code": "F6--0020"]], regles: [
    regle("94-cat-reste", "categorie", cat: "2", niveau: "departement", code: "94", valeur: ["classe": "2"], phrase: "Les eaux non classées en 1re catégorie sont en 2e."),
    regle("94-bro-taille", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": NSNull(), "candidats_cm": [50, 60]],
          phrase: "Brochet : 60 cm d'après l'avis annuel 2026, 50 cm d'après l'arrêté de 2025 ; la plus stricte s'applique.",
          textes: ["t1", "t2"], statut: "incertain", expire: "2026-12-31", remplace: "nat-bro-taille"),
    regle("94-san-taille", "taille_min", especes: ["2195"], cat: "2", niveau: "departement", code: "94", valeur: ["candidats_cm": [40, 50]],
          phrase: "Sandre : 50 cm d'après l'avis 2026, 40 cm d'après l'arrêté.", textes: ["t1", "t2"], statut: "incertain", remplace: "nat-san-taille"),
    regle("94-bla-taille", "taille_min", especes: ["2053"], cat: "2", niveau: "departement", code: "94", valeur: ["candidats_cm": [30, 40]],
          phrase: "Black-bass : 40 cm d'après l'avis 2026, 30 cm d'après l'arrêté.", textes: ["t1", "t2"], statut: "incertain", remplace: "nat-bla-taille"),
    regle("94-car-quota", "quota_jour", especes: ["2151", "2195", "2053"], cat: "2", niveau: "departement", code: "94", valeur: ["total": 3, "dont_brochet": 2],
          phrase: "Trois poissons dont deux brochets au maximum.", remplace: "nat-car-quota"),
    regle("94-consom-marne", "consommation", niveau: "cours_eau", eau: "marne", phrase: "La consommation et la commercialisation des poissons de la Marne sont interdites (arrêté 2010-5378).", textes: ["t3"]),
    regle("94-res-ouvrages", "reserve", niveau: "cours_eau", eau: "marne", lieu: "Barrage de Créteil et 50 m de part et d'autre",
          phrase: "Pêche interdite à moins de 50 m des barrages et écluses.", textes: ["t1"]),
])

let dep75Essai: Data = fichierRegles(departement: "75", regles: [
    regle("75-cat-reste", "categorie", cat: "2", niveau: "departement", code: "75", valeur: ["classe": "2"], phrase: "2e catégorie."),
    regle("75-san-taille", "taille_min", especes: ["2195"], cat: "2", niveau: "departement", code: "75", valeur: ["candidats_cm": [40, 50]],
          phrase: "Sandre : 40 cm d'après l'arrêté, 50 cm d'après l'avis 2026 ; la plus stricte s'applique.", textes: ["t1"], statut: "incertain", remplace: "nat-san-taille"),
    regle("75-bro-taille", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "75", valeur: ["cm": 60], phrase: "Brochet : 60 cm minimum.", remplace: "nat-bro-taille"),
    // Règle d'un avis annuel : périmée après le 31/12/2026.
    regle("75-bro-periode-2026", "interdit", especes: ["2151"], cat: "2", niveau: "departement", code: "75", du: "2026-01-25", au: "2026-04-24",
          phrase: "Brochet : fermé du 25 janvier au 24 avril 2026.", expire: "2026-12-31"),
])

let dep78Essai: Data = fichierRegles(departement: "78", eaux: [["cle": "mauldre", "nom": "Mauldre", "code": NSNull()]], regles: [
    regle("78-categorie-mauldre", "categorie", cat: "1", niveau: "troncon", eau: "mauldre", lieu: "Mauldre (Mareil-sur-Mauldre) : en amont du pont-route",
          valeur: ["classe": "1"], phrase: "La Mauldre, en amont du pont-route de Mareil-sur-Mauldre, est classée en 1re catégorie."),
    regle("78-cat-reste", "categorie", cat: "2", niveau: "departement", code: "78", valeur: ["classe": "2"], phrase: "Les eaux non classées en 1re catégorie sont en 2e."),
])

let dep01Essai: Data = fichierRegles(departement: "01", eaux: [["cle": "ain", "nom": "Ain", "code": NSNull()]], regles: [
    regle("01-ain-troncon-taille", "taille_min", especes: ["2151"], niveau: "troncon", eau: "ain",
          lieu: "de l'aval du barrage d'Allement à l'amont du barrage Convert", valeur: ["cm": 70], phrase: "Brochet : 70 cm entre le barrage d'Allement et le barrage Convert."),
])

/// Brochet du 94 lu par D3 seul : 50 cm confirmé, 60 cm vu par une seule lecture (`a_verifier`).
let dep94FusionEssai: Data = fichierRegles(departement: "94", regles: [
    regle("94-cat-reste", "categorie", cat: "2", niveau: "departement", code: "94", valeur: ["classe": "2"], phrase: "2e catégorie."),
    regle("94-bro-taille", "taille_min", especes: ["2151"], cat: "2", niveau: "departement", code: "94", valeur: ["cm": 50],
          phrase: "Brochet : 50 cm minimum.", remplace: "nat-bro-taille"),
], aVerifier: [["type": "taille_min", "especes": ["2151"], "categorie": "2", "eau": NSNull(), "textes": ["t1"]]])

func chargeurEssai(extra: [String: Data] = [:]) -> ChargeurRegles {
    var fichiers: [String: Data] = ["national": nationalEssai, "94": dep94Essai, "75": dep75Essai, "78": dep78Essai, "01": dep01Essai]
    for (k, v) in extra { fichiers[k] = v }
    return ChargeurRegles(sources: [SourceMemoire(fichiers: fichiers)])
}

func donneesEssai(regles: ChargeurRegles = chargeurEssai(), stations: Data? = stationsOFBEssai) -> DonneesMoteur {
    DonneesMoteur(departements: departementsEssai, lacs: lacsEssai, especes: especesEssai, longueurPoids: longueurPoidsEssai,
                  stationsEspeces: stations, rareteDepartements: raretesEssai, regles: regles)
}

func moteurEssai(regles: ChargeurRegles = chargeurEssai(), horloge: Date = quinzeOctobre) -> MoteurCore {
    MoteurCore(donnees: donneesEssai(regles: regles), horloge: { horloge })
}

// MARK: Espèces et lieux

let brochetEssai = Espece(id: "brochet", codeSandre: "2151")
let sandreEssai = Espece(id: "sandre", codeSandre: "2195")
let blackBassEssai = Espece(id: "black-bass", codeSandre: "2053")
let percheEssai = Espece(id: "perche-commune", codeSandre: "2193")
let fario = Espece(id: "truite-fario", codeSandre: "2221")
let arcEnCiel = Espece(id: "truite-arc-en-ciel", codeSandre: "2216")

let marneEau = Eau(nom: "La Marne", cle: "marne", codeSandre: "F6--0020", type: .riviere)
let seineEau = Eau(nom: "La Seine", cle: "seine", type: .riviere)
let morbrasEau = Eau(nom: "Le Morbras", cle: "morbras", type: .riviere)
let deuxieme = CategorieEau(valeur: .deuxieme, origine: .choixDuPecheur)

let lieuCharenton = Lieu(departement: Departement(code: "94"), eau: marneEau, categorie: deuxieme)
let lieuParis = Lieu(departement: Departement(code: "75"), eau: seineEau, categorie: deuxieme)

func texteDe(_ r: ResultatControle) -> String {
    (r.lignes.map(\.phrase) + [r.consigne.texte]).joined(separator: " | ").lowercased()
}
