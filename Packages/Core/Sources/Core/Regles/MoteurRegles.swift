import Foundation

/// La liste de contrôle : lit les fichiers de règles (`Resources/regles/`), jamais une règle écrite en dur.
/// Elle montre la loi, elle n'accorde rien : aucune valeur ne dit « tu peux la garder ».
public struct MoteurRegles: ServiceRegles {
    /// À moins de cet écart de la maille, aucun verdict de taille (par défaut, à confirmer par Adem).
    public static let ecartTropPresCm = 2.0
    /// À moins de cette marge d'une heure limite (lever moins 30 min, fin légale), la ligne horaire est « à vérifier ».
    public static let margeHoraireMin = 10.0
    /// Lien de la préfecture quand le département n'a pas de fichier de règles (à confirmer par Adem : page de l'annuaire du ministère).
    public static let urlPrefectures = "https://www.interieur.gouv.fr/Le-ministere/Prefectures"
    public static let urlCarteDePecheNationale = "https://www.cartedepeche.fr"

    let chargeur: ChargeurRegles
    let especes: [EspecePechable]
    let soleil: MoteurSoleil
    /// Un point par département (centre de son contour) pour l'heure du soleil : `Lieu` ne porte aucune coordonnée.
    let centres: [String: Coordonnee]
    let creditsLus: [Credit]
    let liens: [String: LiensFederation]

    public init(chargeur: ChargeurRegles, especes: [EspecePechable] = [], centresDepartements: [String: Coordonnee] = [:],
                credits: [Credit] = [], liens: [String: LiensFederation] = [:], soleil: MoteurSoleil = MoteurSoleil()) {
        self.chargeur = chargeur
        self.especes = especes
        self.centres = centresDepartements
        self.creditsLus = credits
        self.liens = liens
        self.soleil = soleil
    }

    // MARK: Contrat

    public func verdictTaille(longueurCm: Double, mesure: MethodeMesure, maille: Double) -> VerdictTaille {
        if mesure == .estimee { return .sansVerdict }
        if abs(longueurCm - maille) < Self.ecartTropPresCm { return .tropPres }
        return longueurCm > maille ? .respectee : .sousLaMaille
    }

    public func departementsCouverts() -> [DepartementCouvert] {
        let index = chargeur.index()
        return chargeur.codesPresents().compactMap { code in
            guard let f = chargeur.fichier(code) else { return nil }
            let datesLecture = f.textes.values.compactMap { dateAAAAMMJJ($0.luLe) } + f.regles.compactMap { dateAAAAMMJJ($0.source?.luLe) }
            let expire = f.regles.compactMap { dateAAAAMMJJ($0.expireLe) }.min()
            let entree = index?.departements[code]
            return DepartementCouvert(
                departement: Departement(code: code),
                niveau: f.niveau == "complet" ? .complet : .partiel,
                reglesConfirmees: f.regles.count,
                lignesAVerifier: f.aVerifier.count + f.illisibles,
                dateLecture: datesLecture.max(),
                expireMin: expire ?? dateAAAAMMJJ(entree?.expireMin))
        }
    }

    public func credits() -> [Credit] { creditsLus }

    public func liensFederation(departement: Departement) -> LiensFederation {
        let l = liens[departement.code] ?? LiensFederation()
        return LiensFederation(siteFederation: l.siteFederation, pageCarteDePeche: l.pageCarteDePeche ?? Self.urlCarteDePecheNationale)
    }

    public func controle(espece: Espece, tailleCm: Double?, mesure: MethodeMesure?, date: Date, lieu: Lieu,
                         prisesDuJour: [Prise]) -> ResultatControle {
        let esp = completer(espece)
        let ctx = Contexte(espece: esp, tailleCm: tailleCm, mesure: mesure, date: date, lieu: lieu, prises: prisesDuJour)
        let calcul = calculer(ctx)
        var lignes = calcul.internes.map(\.ligne)
        lignes.append(contentsOf: lignesDEspece(esp))
        if let carpe = ligneCarpeDeNuit(ctx: ctx, calcul: calcul) { lignes.append(carpe) }
        return ResultatControle(lignes: lignes, consigne: consigne(lignes: lignes, calcul: calcul))
    }

    public func reglesDuJour(lieu: Lieu, date: Date) -> [LigneControle] {
        let ctx = Contexte(espece: nil, tailleCm: nil, mesure: nil, date: date, lieu: lieu, prises: [])
        return calculer(ctx).internes.map(\.ligne)
    }

    /// Ouverte ce jour, ou fermée avec la date de réouverture si les règles la donnent (pour `coins` et `spotPropose`).
    func ouverture(espece: Espece, lieu: Lieu, date: Date) -> OuvertureDuJour {
        let esp = completer(espece)
        let ctx = Contexte(espece: esp, tailleCm: nil, mesure: nil, date: date, lieu: lieu, prises: [])
        let calcul = calculer(ctx)
        let fermees = calcul.internes.filter { $0.ligne.type == .periode && $0.ligne.etat == .nonRespectee }
        if !fermees.isEmpty || !lignesDEspece(esp).isEmpty {
            return .fermee(reouverture: fermees.compactMap(\.reouverture).max())
        }
        return .ouverte
    }

    // MARK: Calcul

    struct Contexte {
        var espece: Espece?
        var tailleCm: Double?
        var mesure: MethodeMesure?
        var date: Date
        var lieu: Lieu
        var prises: [Prise]
    }

    struct LigneInterne {
        var ligne: LigneControle
        var regleId: String?
        var reouverture: Date?
        /// « fermée », « ouverte », « 60 cm » : la valeur affichée par catégorie quand la catégorie est inconnue.
        var etiquette: String
    }

    struct Calcul {
        var internes: [LigneInterne]
        var departementsComplets: Bool
        var aVerifierTouche: Bool
        var categorieConnue: Bool
    }

    func completer(_ e: Espece) -> Espece {
        guard e.codeSandre == nil, let connue = especes.first(where: { $0.espece.id == e.id }) else { return e }
        return Espece(id: e.id, codeSandre: connue.espece.codeSandre)
    }

    private func vise(_ liste: [String], _ espece: Espece?) -> Bool {
        guard let espece else { return true }
        if liste.isEmpty { return true }
        let nom = especes.first(where: { $0.espece.id == espece.id })?.nom
        return liste.contains { GroupesEspeces.vise($0, espece: espece, nom: nom) }
    }

    private func calculer(_ ctx: Contexte) -> Calcul {
        var departements = [ctx.lieu.departement.code]
        if let v = ctx.lieu.departementVoisin?.code, !departements.contains(v) { departements.append(v) }
        var toutes: [LigneInterne] = []
        var complets = true
        var touche = false
        let national = chargeur.fichier("national")

        for dep in departements {
            if dep == Departement.inconnu.code {
                complets = false
                toutes.append(LigneInterne(ligne: LigneControle(
                    type: .autre, etat: .aVerifierSurPlace,
                    phrase: "Hors de France : aucune règle française.", sources: []), regleId: nil, reouverture: nil, etiquette: "à vérifier"))
                continue
            }
            let local = chargeur.fichier(dep)
            if let local {
                if local.niveau != "complet" { complets = false }
            } else {
                complets = false
                toutes.append(LigneInterne(ligne: LigneControle(
                    type: .autre, etat: .aVerifierSurPlace,
                    phrase: "Règles locales non saisies pour le \(dep) : le socle national seul s'affiche. Vérifie l'arrêté préfectoral.",
                    sources: [SourceRegle(titre: "Préfecture du \(dep) : arrêtés de pêche", url: Self.urlPrefectures)]),
                    regleId: nil, reouverture: nil, etiquette: "à vérifier"))
            }
            if (local?.illisibles ?? 0) + (national?.illisibles ?? 0) > 0 {
                touche = true
                toutes.append(LigneInterne(ligne: LigneControle(
                    type: .autre, etat: .aVerifierSurPlace, raison: .desaccord,
                    phrase: "Une règle de ce département n'a pas pu être lue : vérifie l'arrêté.", sources: []),
                    regleId: nil, reouverture: nil, etiquette: "à vérifier"))
            }
            let categories: [Categorie] = ctx.lieu.categorie.valeur == .inconnue ? [.premiere, .deuxieme] : [ctx.lieu.categorie.valeur]
            var parCategorie: [Categorie: [LigneInterne]] = [:]
            for cat in categories {
                let (l, t) = lignes(dep: dep, ctx: ctx, categorie: cat, national: national, local: local)
                parCategorie[cat] = l
                touche = touche || t
            }
            toutes.append(contentsOf: fusionner(parCategorie, categoriesInconnues: categories.count > 1))
        }
        return Calcul(internes: dedoublonner(toutes), departementsComplets: complets, aVerifierTouche: touche,
                      categorieConnue: ctx.lieu.categorie.valeur != .inconnue)
    }

    /// Deux départements (limite à moins de 500 m) : la même phrase n'apparaît qu'une fois, avec le pire état.
    private func dedoublonner(_ lignes: [LigneInterne]) -> [LigneInterne] {
        var sortie: [LigneInterne] = []
        for l in lignes {
            if let i = sortie.firstIndex(where: { $0.ligne.phrase == l.ligne.phrase && $0.ligne.type == l.ligne.type }) {
                if rang(l.ligne.etat) > rang(sortie[i].ligne.etat) { sortie[i] = l }
            } else {
                sortie.append(l)
            }
        }
        return sortie
    }

    private func rang(_ e: EtatLigne) -> Int {
        switch e {
        case .respectee, .information: return 0
        case .aVerifierSurPlace: return 1
        case .nonRespectee: return 2
        }
    }

    /// Catégorie inconnue : une seule ligne par règle commune aux deux catégories, et une ligne à deux valeurs par couple de règles qui diffèrent.
    private func fusionner(_ parCategorie: [Categorie: [LigneInterne]], categoriesInconnues: Bool) -> [LigneInterne] {
        guard categoriesInconnues, let l1 = parCategorie[.premiere], let l2 = parCategorie[.deuxieme] else {
            return parCategorie.values.first ?? []
        }
        var sortie: [LigneInterne] = []
        let ids2 = Set(l2.compactMap(\.regleId))
        let ids1 = Set(l1.compactMap(\.regleId))
        var orphelines1: [LigneInterne] = []
        for l in l1 {
            if let id = l.regleId, ids2.contains(id) { sortie.append(l) } else { orphelines1.append(l) }
        }
        let orphelines2 = l2.filter { $0.regleId == nil || !ids1.contains($0.regleId!) }
        // Les lignes sans règle (messages du département) ne sont pas dédoublées par catégorie : une seule copie.
        let sansRegle1 = orphelines1.filter { $0.regleId == nil }
        sortie.append(contentsOf: sansRegle1)
        let o1 = orphelines1.filter { $0.regleId != nil }
        let o2 = orphelines2.filter { $0.regleId != nil }
        var reste2 = o2
        for a in o1 {
            let i = reste2.firstIndex(where: { $0.ligne.type == a.ligne.type })
            let b = i.map { reste2.remove(at: $0) }
            sortie.append(combiner(a, b))
        }
        for b in reste2 { sortie.append(combiner(nil, b)) }
        return sortie
    }

    private func combiner(_ a: LigneInterne?, _ b: LigneInterne?) -> LigneInterne {
        let base = (b ?? a)!
        var ligne = base.ligne
        let manque = "aucune règle saisie"
        ligne.valeursParCategorie = [.premiere: a?.etiquette ?? manque, .deuxieme: b?.etiquette ?? manque]
        let defaut: EtatLigne = (a?.ligne.etat == .information || b?.ligne.etat == .information) ? .information : .respectee
        let e1 = a?.ligne.etat ?? defaut, e2 = b?.ligne.etat ?? defaut
        if e1 == e2 {
            ligne.etat = e1
            ligne.raison = e1 == .aVerifierSurPlace ? (a?.ligne.raison ?? b?.ligne.raison) : nil
        } else {
            ligne.etat = .aVerifierSurPlace
            ligne.raison = .categorie
        }
        if let a, let b, a.ligne.phrase != b.ligne.phrase {
            ligne.phrase = "\(a.ligne.phrase) / \(b.ligne.phrase)"
            for s in a.ligne.sources where !ligne.sources.contains(s) { ligne.sources.append(s) }
        }
        var reouv = [a?.reouverture, b?.reouverture].compactMap { $0 }.max()
        if ligne.etat != .nonRespectee { reouv = nil }
        return LigneInterne(ligne: ligne, regleId: base.regleId, reouverture: reouv, etiquette: base.etiquette)
    }

    private struct Retenue {
        var regle: RegleDonnee
        var fichier: FichierRegles
        var rang: Int
        var confirmeTroncon: Bool
    }

    /// Les lignes d'un département pour une catégorie connue.
    private func lignes(dep: String, ctx: Contexte, categorie: Categorie, national: FichierRegles?, local: FichierRegles?)
        -> (lignes: [LigneInterne], aVerifierTouche: Bool) {
        var retenues: [Retenue] = []
        var info: [LigneInterne] = []
        var reservesLocales: [(RegleDonnee, FichierRegles)] = []
        let fichiers: [(FichierRegles, Bool)] = [national, local].enumerated().compactMap { i, f in f.map { ($0, i == 0) } }
        for (fichier, estNational) in fichiers {
            for r in fichier.regles {
                guard r.type != "categorie", vise(r.especes, ctx.espece), categorieConvient(r.categorie, categorie) else { continue }
                let niveau = r.portee?.niveau ?? (estNational ? "national" : "departement")
                switch niveau {
                case "national":
                    retenues.append(Retenue(regle: r, fichier: fichier, rang: 1, confirmeTroncon: true))
                case "departement":
                    if let c = r.portee?.code, c != dep, c != "FR" { continue }
                    // Une réserve du département sans eau ni géométrie ne se place pas sur la carte : jamais masquée,
                    // elle devient une ligne « à vérifier sur place » avec sa source (voir `ligneReservesLocales`).
                    if r.type == "reserve", !(r.portee?.lieu ?? "").lowercased().hasPrefix("tous") {
                        reservesLocales.append((r, fichier))
                        continue
                    }
                    retenues.append(Retenue(regle: r, fichier: fichier, rang: estNational ? 1 : 2, confirmeTroncon: true))
                case "cours_eau", "plan_eau":
                    guard memeEau(r.portee?.eau, lieu: ctx.lieu, fichier: fichier) else { continue }
                    retenues.append(Retenue(regle: r, fichier: fichier, rang: 3, confirmeTroncon: true))
                case "troncon":
                    guard memeEau(r.portee?.eau, lieu: ctx.lieu, fichier: fichier) else { continue }
                    // L'app enregistre le libellé du tronçon (celui de la ligne « à vérifier »), le moteur accepte aussi l'id de la règle.
                    if ctx.lieu.tronconsConfirmes.contains(r.id) || ctx.lieu.tronconsConfirmes.contains(libelleDuTroncon(r)) {
                        retenues.append(Retenue(regle: r, fichier: fichier, rang: 4, confirmeTroncon: true))
                    } else {
                        var ligne = ligneDeBase(r, fichier: fichier, etat: .aVerifierSurPlace)
                        ligne.raison = .troncon
                        ligne.libelleTroncon = libelleDuTroncon(r)
                        info.append(LigneInterne(ligne: ligne, regleId: r.id, reouverture: nil, etiquette: "à vérifier"))
                    }
                default:
                    retenues.append(Retenue(regle: r, fichier: fichier, rang: estNational ? 1 : 2, confirmeTroncon: true))
                }
            }
        }
        // La règle la plus locale remplace la plus générale de même type, catégorie et portée d'espèce.
        let remplacees = Set(retenues.compactMap { $0.regle.remplace })
        retenues = retenues.filter { !remplacees.contains($0.regle.id) }
        func cle(_ r: Retenue) -> String {
            let esp = ctx.espece == nil ? r.regle.especes.sorted().joined(separator: ",") : (r.regle.especes.isEmpty ? "*" : "e")
            return "\(r.regle.type)|\(r.regle.categorie)|\(esp)|\(r.regle.type == "reserve" ? r.regle.id : "")"
        }
        var meilleurRang: [String: Int] = [:]
        for r in retenues { meilleurRang[cle(r)] = max(meilleurRang[cle(r)] ?? 0, r.rang) }
        retenues = retenues.filter { $0.rang == meilleurRang[cle($0)] }

        var resultat: [LigneInterne] = retenues.map { evaluer($0, ctx: ctx, dep: dep) }
        resultat = fusionnerOuvertures(resultat, retenues: retenues)
        resultat.append(contentsOf: info)
        if let reserves = ligneReservesLocales(reservesLocales) { resultat.append(reserves) }

        var touche = false
        for fichier in [local, national].compactMap({ $0 }) {
            for av in fichier.aVerifier {
                guard vise(av.especes, ctx.espece), categorieConvient(av.categorie, categorie),
                      av.eau == nil || memeEau(av.eau, lieu: ctx.lieu, fichier: fichier) else { continue }
                touche = true
                let type = typeLigne(av.type)
                let sources = av.textes.compactMap { sourceDe(id: $0, fichier: fichier) }
                var trouve = false
                for i in resultat.indices where resultat[i].ligne.type == type && resultat[i].ligne.raison != .troncon {
                    trouve = true
                    if resultat[i].ligne.etat == .respectee || resultat[i].ligne.etat == .information {
                        resultat[i].ligne.etat = .aVerifierSurPlace
                        resultat[i].ligne.raison = .desaccord
                        resultat[i].etiquette = "à vérifier"
                    }
                    for s in sources where !resultat[i].ligne.sources.contains(s) { resultat[i].ligne.sources.append(s) }
                }
                if !trouve {
                    let ligne = LigneControle(type: type, etat: .aVerifierSurPlace, raison: .desaccord,
                                              phrase: "Règle locale possible (\(libelleType(av.type))) : vérifie l'arrêté.",
                                              sources: sources)
                    resultat.append(LigneInterne(ligne: ligne, regleId: nil, reouverture: nil, etiquette: "à vérifier"))
                }
            }
        }
        return (resultat, touche)
    }

    private func libelleDuTroncon(_ r: RegleDonnee) -> String { r.portee?.lieu ?? r.phrase }

    /// Réserves du département qu'on ne sait pas placer (ports, darses, estacades...) : une seule ligne « à vérifier sur place »,
    /// avec toutes leurs sources. La consigne ne change pas : le moteur ne dit pas où est la réserve, il dit qu'elle existe.
    private func ligneReservesLocales(_ reserves: [(RegleDonnee, FichierRegles)]) -> LigneInterne? {
        guard !reserves.isEmpty else { return nil }
        var sources: [SourceRegle] = []
        for (r, f) in reserves {
            var s = r.textes.compactMap { sourceDe(id: $0, fichier: f) }
            if s.isEmpty, let en = r.source { s = [SourceRegle(titre: en.texte ?? "Source", url: en.url)] }
            for x in s where !sources.contains(x) { sources.append(x) }
        }
        let n = reserves.count
        let phrase = n == 1
            ? "\(reserves[0].0.phrase) Regarde le panneau."
            : "\(n) réserves de pêche locales dans le département (ports, darses, ouvrages) : regarde les panneaux sur place."
        let ligne = LigneControle(type: .reserve, etat: .aVerifierSurPlace, raison: .reserve, phrase: phrase, sources: sources,
                                  citation: n == 1 ? reserves[0].0.citation : nil)
        return LigneInterne(ligne: ligne, regleId: nil, reouverture: nil, etiquette: "à vérifier")
    }

    private func categorieConvient(_ valeur: String, _ cat: Categorie) -> Bool {
        if valeur == "toutes" || valeur.isEmpty { return true }
        return valeur == (cat == .premiere ? "1" : "2")
    }

    /// Le lieu est-il sur l'eau que vise la règle ? Une règle peut viser plusieurs cours d'eau d'un coup
    /// (`seine-marne-et-yerres`, nom « Seine, Marne et Yerres ») : on compare le lieu à chaque cours d'eau du nom, jamais à des
    /// morceaux de mots (« seine » ne touche pas « seine-saint-denis »).
    private func memeEau(_ cle: String?, lieu: Lieu, fichier: FichierRegles) -> Bool {
        guard let cle, !cle.isEmpty, let eau = lieu.eau else { return false }
        let k = cleEau(cle)
        let cles = [cleEau(eau.cle), cleEau(eau.nom)]
        if cles.contains(k) { return true }
        guard let declaree = fichier.eaux.first(where: { cleEau($0.cle) == k }) else { return false }
        if let code = eau.codeSandre, declaree.code == code { return true }
        return cleEaux(declaree).contains { cles.contains($0) }
    }

    /// Les cours d'eau cités dans le nom d'une eau de règle : « Seine, Marne et Yerres » donne seine, marne, yerres.
    /// Un nom avec « hors » (« Seine et canaux de Paris, hors les deux lots listés ») reste un seul bloc : pas de découpe.
    private func cleEaux(_ e: EauDonnee) -> [String] {
        guard var nom = e.nom?.lowercased(), !nom.contains(" hors ") else { return [] }
        while let o = nom.firstIndex(of: "("), let f = nom[o...].firstIndex(of: ")") { nom.removeSubrange(o...f) }
        return nom.replacingOccurrences(of: " et ", with: ",").split(separator: ",")
            .map { cleEau(String($0)) }.filter { !$0.isEmpty }
    }

    /// Plusieurs fenêtres d'ouverture de même groupe : ouvert si l'une contient la date.
    private func fusionnerOuvertures(_ lignes: [LigneInterne], retenues: [Retenue]) -> [LigneInterne] {
        var sortie: [LigneInterne] = []
        var groupes: [String: [Int]] = [:]
        for (i, r) in retenues.enumerated() where r.regle.type == "ouverture" && i < lignes.count {
            groupes["\(r.regle.categorie)|\(r.regle.especes.isEmpty ? "*" : "e")", default: []].append(i)
        }
        var ecartees = Set<Int>()
        for (_, indices) in groupes where indices.count > 1 {
            if indices.contains(where: { lignes[$0].ligne.etat == .respectee }) {
                for i in indices where lignes[i].ligne.etat != .respectee { ecartees.insert(i) }
            } else {
                for i in indices.dropFirst() { ecartees.insert(i) }
            }
        }
        for (i, l) in lignes.enumerated() where !ecartees.contains(i) { sortie.append(l) }
        return sortie
    }

    // MARK: Une règle

    private func evaluer(_ r: Retenue, ctx: Contexte, dep: String) -> LigneInterne {
        let regle = r.regle
        var ligne = ligneDeBase(regle, fichier: r.fichier, etat: .respectee)
        if regle.portee?.niveau == "troncon" { ligne.libelleTroncon = libelleDuTroncon(regle) }
        var reouverture: Date?
        let unJour: TimeInterval = 86_400

        func fini(_ etat: EtatLigne, _ raison: RaisonAVerifier? = nil, etiq: String? = nil) -> LigneInterne {
            ligne.etat = etat
            ligne.raison = raison
            let e = etiq ?? (etat == .respectee ? "respectée" : etat == .nonRespectee ? "non respectée" : etat == .information ? "information" : "à vérifier")
            return LigneInterne(ligne: ligne, regleId: regle.id, reouverture: reouverture, etiquette: e)
        }

        if let expire = dateAAAAMMJJ(regle.expireLe), ctx.date >= expire.addingTimeInterval(unJour) {
            let annee = Calendar.utcGregorien.component(.year, from: expire) + 1
            ligne.phrase += " Cette règle a expiré le \(jjmmaaaa(expire)) : vérifie l'arrêté \(annee)."
            return fini(.aVerifierSurPlace, .perimee)
        }
        let candidats = regle.valeur["candidats_cm"]?.nombres ?? []
        if regle.statut == "incertain", candidats.isEmpty {
            return fini(.aVerifierSurPlace, .desaccord)
        }
        let fiche = ctx.espece == nil
        switch regle.type {
        case "taille_min":
            guard let maille = regle.valeur["cm"]?.nombre ?? candidats.max() else { return fini(.aVerifierSurPlace) }
            let etiq = "\(Int(maille == maille.rounded() ? maille : maille.rounded())) cm"
            if fiche { return fini(.respectee, etiq: etiq) }
            guard let t = ctx.tailleCm else { return fini(.aVerifierSurPlace, etiq: etiq) }
            switch verdictTaille(longueurCm: t, mesure: ctx.mesure ?? .saisie, maille: maille) {
            case .respectee: return fini(.respectee, etiq: etiq)
            case .sousLaMaille: return fini(.nonRespectee, etiq: etiq)
            case .tropPres:
                ligne.phrase += " Trop près de la maille : mesure-la sur une toise."
                return fini(.aVerifierSurPlace, .tropPresDeLaMaille, etiq: etiq)
            case .sansVerdict:
                ligne.phrase += " Mesure estimée : aucun verdict de taille, mesure-la sur une toise."
                return fini(.aVerifierSurPlace, .tropPresDeLaMaille, etiq: etiq)
            }
        case "fenetre_capture":
            let mn = regle.valeur["min_cm"]?.nombre, mx = regle.valeur["max_cm"]?.nombre
            if fiche || (mn == nil && mx == nil) { return fini(.respectee) }
            guard let t = ctx.tailleCm else { return fini(.aVerifierSurPlace) }
            if ctx.mesure == .estimee { return fini(.aVerifierSurPlace, .tropPresDeLaMaille) }
            for borne in [mn, mx].compactMap({ $0 }) where abs(t - borne) < Self.ecartTropPresCm {
                return fini(.aVerifierSurPlace, .tropPresDeLaMaille)
            }
            let dedans = (mn.map { t >= $0 } ?? true) && (mx.map { t <= $0 } ?? true)
            return fini(dedans ? .respectee : .nonRespectee)
        case "ouverture":
            guard let du = dateAAAAMMJJ(regle.du), let au = dateAAAAMMJJ(regle.au) else { return fini(.aVerifierSurPlace) }
            if ctx.date >= du && ctx.date < au.addingTimeInterval(unJour) { return fini(.respectee, etiq: "ouverte") }
            if du > ctx.date { reouverture = du }
            return fini(.nonRespectee, etiq: "fermée")
        case "interdit":
            // Interdiction générale de moyen, de vente ou d'accès (« la gaffe est interdite ») : une ligne d'information.
            if regle.especes.isEmpty && regle.du == nil && regle.au == nil { return fini(.information) }
            guard let du = dateAAAAMMJJ(regle.du), let au = dateAAAAMMJJ(regle.au) else {
                if regle.du == nil && regle.au == nil { return fini(.nonRespectee, etiq: "fermée") }
                return fini(.aVerifierSurPlace)
            }
            if ctx.date >= du && ctx.date < au.addingTimeInterval(unJour) {
                reouverture = au.addingTimeInterval(unJour)
                return fini(.nonRespectee, etiq: "fermée")
            }
            return fini(.respectee, etiq: "ouverte")
        case "quota_jour":
            let total = regle.valeur["total"]?.nombre ?? regle.valeur["nombre"]?.nombre
            guard let total, !fiche, let espece = ctx.espece else { return fini(.respectee) }
            let jour = Calendar.utcGregorien
            let gardees = ctx.prises.filter { $0.gardee && !$0.estDeclaree && !$0.exemple && jour.isDate($0.date, inSameDayAs: ctx.date) }
            let dansRegle = gardees.filter { vise(regle.especes, completer($0.espece)) }
            ligne.phrase += " (déjà \(dansRegle.count) gardé\(dansRegle.count > 1 ? "s" : "") aujourd'hui)"
            if Double(dansRegle.count) >= total { return fini(.nonRespectee) }
            if let dont = regle.valeur["dont_brochet"]?.nombre, completer(espece).id == "brochet" || completer(espece).codeSandre == "2151" {
                let brochets = dansRegle.filter { completer($0.espece).id == "brochet" || completer($0.espece).codeSandre == "2151" }
                if Double(brochets.count) >= dont { return fini(.nonRespectee) }
            }
            return fini(.respectee)
        case "horaire":
            guard !fiche else { return fini(.respectee) }
            guard let centre = centres[dep],
                  let (lever, coucher) = soleil.leverEtCoucher(date: ctx.date, coordonnee: centre) else { return fini(.aVerifierSurPlace) }
            let avant = regle.valeur["avant_lever_min"]?.nombre ?? 30
            let apres = regle.valeur["apres_coucher_min"]?.nombre ?? 30
            let debut = lever.addingTimeInterval(-avant * 60)
            let fin = coucher.addingTimeInterval((apres - MoteurSoleil.margeDeSecuriteMin) * 60)
            let marge = Self.margeHoraireMin * 60
            if ctx.date < debut.addingTimeInterval(-marge) || ctx.date > fin.addingTimeInterval(marge) { return fini(.nonRespectee) }
            if abs(ctx.date.timeIntervalSince(debut)) <= marge || abs(ctx.date.timeIntervalSince(fin)) <= marge { return fini(.aVerifierSurPlace) }
            return fini(.respectee)
        case "reserve":
            ligne.phrase += " Regarde le panneau."
            return fini(.aVerifierSurPlace, .reserve)
        case "no_kill":
            return fini(.nonRespectee)
        case "remise_eau":
            return fini(.aVerifierSurPlace)
        case "carpe_nuit" where !eauConvient(regle, lieu: ctx.lieu):
            // Règle visant les cours d'eau, pêcheur sur un plan d'eau, « autre » ou une eau inconnue : on ne l'applique pas.
            return fini(.aVerifierSurPlace)
        case "consommation", "transport_vivant", "mode_peche", "carpe_nuit", "limite_eau_douce", "autre":
            // Information (interdiction ou obligation à appliquer) : jamais « respectée », ne change pas la consigne.
            return fini(.information)
        default:
            return fini(.aVerifierSurPlace)
        }
    }

    /// Une règle de département dont le lieu ne vise que les cours d'eau ne vaut que sur une rivière.
    private func eauConvient(_ r: RegleDonnee, lieu: Lieu) -> Bool {
        guard r.portee?.niveau == "departement" else { return true }
        let l = (r.portee?.lieu ?? "").lowercased().replacingOccurrences(of: "’", with: "'")
        guard l.contains("cours d'eau"), !l.contains("plan d'eau"), !l.contains("lac") else { return true }
        return lieu.eau?.type == .riviere
    }

    private func ligneDeBase(_ r: RegleDonnee, fichier: FichierRegles, etat: EtatLigne) -> LigneControle {
        var sources = r.textes.compactMap { sourceDe(id: $0, fichier: fichier) }
        var lecture = r.textes.compactMap { fichier.textes[$0]?.luLe }.compactMap { dateAAAAMMJJ($0) }.min()
        if sources.isEmpty, let s = r.source {
            sources = [SourceRegle(titre: s.texte ?? "Source", url: s.url)]
            lecture = dateAAAAMMJJ(s.luLe)
        }
        // Interdiction qui vise des espèces nommées (écrevisses, migrateurs, anguille argentée) : ligne « autre », comme dans cas-verdicts.json.
        let generale = r.type == "interdit" && r.especes.isEmpty && r.du == nil && r.au == nil
        let type = r.type == "interdit" && (generale || r.especes.contains { $0.hasPrefix("nom:") }) ? TypeRegle.autre : typeLigne(r.type)
        return LigneControle(type: type, etat: etat, phrase: r.phrase, sources: sources, citation: r.citation, dateLecture: lecture)
    }

    private func sourceDe(id: String, fichier: FichierRegles) -> SourceRegle? {
        guard let t = fichier.textes[id] else { return nil }
        return SourceRegle(titre: t.titre ?? id, url: t.url)
    }

    private func typeLigne(_ type: String) -> TypeRegle {
        switch type {
        case "taille_min", "fenetre_capture": return .taille
        case "ouverture", "interdit": return .periode
        case "quota_jour": return .quota
        case "mode_peche": return .modeDePeche
        case "horaire", "carpe_nuit": return .nuit
        case "reserve": return .reserve
        case "consommation": return .consommation
        case "transport_vivant": return .transportVivant
        default: return .autre
        }
    }

    /// Le type d'une règle en français, pour « Règle locale possible (réserve de pêche) : vérifie l'arrêté. »
    private func libelleType(_ type: String) -> String {
        switch type {
        case "taille_min": return "taille minimale"
        case "fenetre_capture": return "fenêtre de capture"
        case "ouverture", "interdit": return "période d'ouverture"
        case "quota_jour": return "quota du jour"
        case "mode_peche": return "mode de pêche"
        case "reserve": return "réserve de pêche"
        case "consommation": return "consommation du poisson"
        case "categorie": return "catégorie de l'eau"
        case "no_kill": return "parcours no-kill"
        case "remise_eau": return "remise à l'eau"
        case "carpe_nuit": return "pêche de la carpe de nuit"
        case "horaire": return "horaires de pêche"
        case "transport_vivant": return "transport du poisson vivant"
        case "limite_eau_douce": return "limite eau douce, eau salée"
        default: return "autre règle"
        }
    }

    private func jjmmaaaa(_ d: Date) -> String {
        let c = Calendar.utcGregorien.dateComponents([.day, .month, .year], from: d)
        return "\(c.day ?? 0)/\(c.month ?? 0)/\(c.year ?? 0)"
    }

    /// Lignes qui tiennent à l'espèce elle-même (statut de `especes.json`, anguille sans stade).
    private func lignesDEspece(_ espece: Espece) -> [LigneControle] {
        var lignes: [LigneControle] = []
        if espece.id == "anguille" {
            lignes.append(LigneControle(type: .periode, etat: .nonRespectee,
                                        phrase: "Stade de l'anguille non précisé : relâche-la.", sources: []))
        }
        if let e = especes.first(where: { $0.espece.id == espece.id }),
           e.statuts.contains(.protegee) || e.statuts.contains(.toujoursRelachee) {
            lignes.append(LigneControle(type: .periode, etat: .nonRespectee,
                                        phrase: "Espèce protégée ou toujours relâchée : remise à l'eau obligatoire.",
                                        sources: [SourceRegle(titre: "Liste des espèces (statut)")]))
        }
        return lignes
    }

    // MARK: Carpe de nuit

    static let phraseCarpeAutorisee = "Carpe de nuit : remise à l'eau obligatoire, appâts végétaux seulement"
    static let phraseCarpeAVerifier = "Pêche de nuit : seulement sur les secteurs autorisés, vérifie l'arrêté"

    private func estCarpe(_ e: Espece) -> Bool { e.id == "carpe-commune" || e.id == "carpe-koi" || e.codeSandre == "2110" }

    /// Vrai si la prise est clairement hors des heures légales (même calcul que la ligne horaire, avec sa marge).
    private func estDeNuit(_ date: Date, departements: [String]) -> Bool {
        for dep in departements {
            guard let centre = centres[dep], let (lever, coucher) = soleil.leverEtCoucher(date: date, coordonnee: centre) else { continue }
            let debut = lever.addingTimeInterval(-30 * 60)
            let fin = coucher.addingTimeInterval((30 - MoteurSoleil.margeDeSecuriteMin) * 60)
            let marge = Self.margeHoraireMin * 60
            return date < debut.addingTimeInterval(-marge) || date > fin.addingTimeInterval(marge)
        }
        return false
    }

    /// Une carpe prise de nuit : la ligne dit si une règle locale chargée autorise la carpe de nuit sur ce lieu (remise à l'eau
    /// obligatoire dans ce cas), sinon renvoie à l'arrêté. Jamais de « tu peux la garder ». Pas de citation inventée du Code :
    /// la source R436-14 est celle du socle national.
    private func ligneCarpeDeNuit(ctx: Contexte, calcul: Calcul) -> LigneControle? {
        guard let espece = ctx.espece, estCarpe(espece) else { return nil }
        var deps = [ctx.lieu.departement.code]
        if let v = ctx.lieu.departementVoisin?.code, !deps.contains(v) { deps.append(v) }
        guard estDeNuit(ctx.date, departements: deps) else { return nil }
        let national = chargeur.fichier("national")
        var codeSource: SourceRegle?
        if let national, let t = national.textes.values.first(where: { ($0.titre ?? "").contains("R436-14") }) {
            codeSource = SourceRegle(titre: t.titre ?? "R436-14", url: t.url)
        }
        for dep in deps {
            guard let local = chargeur.fichier(dep) else { continue }
            for interne in calcul.internes {
                guard let id = interne.regleId, interne.ligne.raison == nil, interne.ligne.etat != .aVerifierSurPlace,
                      let r = local.regles.first(where: { $0.id == id }), r.type == "carpe_nuit", r.statut != "incertain",
                      ["departement", "cours_eau", "plan_eau", "troncon"].contains(r.portee?.niveau ?? ""),
                      eauConvient(r, lieu: ctx.lieu) else { continue }
                // « interdits » apparaît aussi dans les textes qui autorisent (bateaux amorceurs, captivité) :
                // on ne le cherche que dans la phrase, pas dans le détail de la valeur.
                let texte = ((r.valeur["texte"]?.texte ?? "") + " " + r.phrase).lowercased()
                if texte.contains("autorise : non") || texte.contains("pas de pêche")
                    || r.phrase.lowercased().contains("interdit") { continue }
                var sources = r.textes.compactMap { sourceDe(id: $0, fichier: local) }
                if let codeSource, !sources.contains(codeSource) { sources.append(codeSource) }
                return LigneControle(type: .nuit, etat: .nonRespectee, phrase: Self.phraseCarpeAutorisee,
                                     sources: sources, citation: r.citation)
            }
        }
        return LigneControle(type: .nuit, etat: .aVerifierSurPlace, phrase: Self.phraseCarpeAVerifier,
                             sources: codeSource.map { [$0] } ?? [])
    }

    // MARK: Consigne

    private func consigne(lignes: [LigneControle], calcul: Calcul) -> Consigne {
        let comptees = lignes.filter { $0.raison != .troncon }
        if comptees.contains(where: { $0.etat == .nonRespectee }) { return .relacheLa }
        if comptees.contains(where: { $0.raison == .tropPresDeLaMaille }) { return .mesureLaSurUneToise }
        if comptees.contains(where: { $0.etat == .aVerifierSurPlace }) { return .verifieLArrete }
        if calcul.departementsComplets && calcul.categorieConnue && !calcul.aVerifierTouche { return .aucuneRegleSaisieNeLInterdit }
        return .verifieLArrete
    }
}
