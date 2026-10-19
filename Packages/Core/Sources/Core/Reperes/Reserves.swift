import Foundation

/// Une réserve de pêche signalée par les textes lus pour un département. Les fichiers de règles ne contiennent aucun contour :
/// on sait qu'une réserve existe, et parfois sur quelle eau, jamais où elle commence.
public struct ReserveConnue: Sendable, Equatable, Hashable, Codable, Identifiable {
    public var id: String
    /// Clé (`cleEau`) de l'eau visée, si la règle en nomme une.
    public var eauCle: String?
    /// Autres clés de la même eau (nom complet déclaré dans le fichier).
    public var clesEquivalentes: [String]
    public var eauNom: String?
    public var departement: String
    public var phrase: String
    /// Au moins une source (arrêté ou texte, avec son titre) ; la citation est dans la source quand le fichier la donne.
    public var sources: [SourceRegle]
    public var lueLe: Date?
    /// Vrai si la réserve est rattachée à un cours d'eau, un plan d'eau ou un tronçon.
    public var placeeSurUneEau: Bool

    public init(id: String, eauCle: String?, clesEquivalentes: [String] = [], eauNom: String? = nil, departement: String,
                phrase: String, sources: [SourceRegle], lueLe: Date?, placeeSurUneEau: Bool) {
        self.id = id
        self.eauCle = eauCle
        self.clesEquivalentes = clesEquivalentes
        self.eauNom = eauNom
        self.departement = departement
        self.phrase = phrase
        self.sources = sources
        self.lueLe = lueLe
        self.placeeSurUneEau = placeeSurUneEau
    }

    func viseCetteEau(_ cle: String) -> Bool {
        guard placeeSurUneEau else { return false }
        return eauCle == cle || clesEquivalentes.contains(cle)
    }
}

/// Ce que l'app peut dire d'un repère au sujet des réserves. Il n'existe PAS de cas « hors réserve » : sans contour, l'app ne
/// peut pas affirmer qu'un point n'est pas dans une réserve.
public enum AvertissementReserve: Sendable, Equatable {
    /// `lueLe` : la plus ancienne date de lecture des textes cités (celle qui se périme en premier).
    case surCetteEau(nom: String, sources: [SourceRegle], lueLe: Date?)
    case nonPlaceesDansLeDepartement(nombre: Int, sources: [SourceRegle], lueLe: Date?)
    case aucuneConnue
}

public enum DetecteurReserve {
    /// Priorité : une réserve signalée sur l'une des eaux proches, puis des réserves du département qu'on ne sait pas placer,
    /// puis « aucune connue dans nos textes ». Comparaison par `cleEau`, comme `RepartitionSpots.reserveSurLEau`.
    public static func evaluer(eauxProches: [Eau], departement: Departement, reserves: [ReserveConnue]) -> AvertissementReserve {
        guard !departement.estInconnu else { return .aucuneConnue }
        let duDepartement = reserves.filter { $0.departement == departement.code }
        for eau in eauxProches {
            let visees = duDepartement.filter { $0.viseCetteEau(eau.cle) }
            if !visees.isEmpty { return .surCetteEau(nom: eau.nom, sources: sourcesUniques(visees), lueLe: lectureLaPlusAncienne(visees)) }
        }
        let nonPlacees = duDepartement.filter { !$0.placeeSurUneEau }
        if !nonPlacees.isEmpty {
            return .nonPlaceesDansLeDepartement(nombre: nonPlacees.count, sources: sourcesUniques(nonPlacees),
                                                lueLe: lectureLaPlusAncienne(nonPlacees))
        }
        return .aucuneConnue
    }

    private static func lectureLaPlusAncienne(_ reserves: [ReserveConnue]) -> Date? {
        reserves.compactMap(\.lueLe).min()
    }

    private static func sourcesUniques(_ reserves: [ReserveConnue]) -> [SourceRegle] {
        var sortie: [SourceRegle] = []
        for r in reserves {
            for s in r.sources where !sortie.contains(s) { sortie.append(s) }
        }
        return sortie
    }
}

/// Seul fichier des repères qui lit les règles (`regles/<dép>.json`). N'écrit aucune règle de son cru.
public enum ReservesDuDepartement {
    private static let niveauxSurUneEau: Set<String> = ["cours_eau", "plan_eau", "troncon"]

    public static func charger(departement: Departement, chargeur: ChargeurRegles = .embarque()) -> [ReserveConnue] {
        guard !departement.estInconnu, let fichier = chargeur.fichier(departement.code) else { return [] }
        return fichier.regles.compactMap { r -> ReserveConnue? in
            guard r.type == "reserve" else { return nil }
            let eauBrute = (r.portee?.eau ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let placee = niveauxSurUneEau.contains(r.portee?.niveau ?? "") && !eauBrute.isEmpty
            let cle: String? = placee ? cleEau(eauBrute) : nil
            var equivalentes: [String] = []
            var nom: String? = placee ? eauBrute : nil
            if let cle, let declaree = fichier.eaux.first(where: { cleEau($0.cle) == cle }), let n = declaree.nom {
                nom = n
                let k = cleEau(n)
                if k != cle { equivalentes.append(k) }
            }
            var sources: [SourceRegle] = r.textes.compactMap { id -> SourceRegle? in
                guard let t = fichier.textes[id] else { return nil }
                return SourceRegle(titre: t.titre ?? id, url: t.url, citation: r.citations?[id] ?? r.citation)
            }
            var lecture = r.textes.compactMap { fichier.textes[$0]?.luLe }.compactMap { dateAAAAMMJJ($0) }.min()
            if sources.isEmpty, let en = r.source {
                sources = [SourceRegle(titre: en.texte ?? "Source", url: en.url, citation: r.citation)]
                lecture = dateAAAAMMJJ(en.luLe)
            }
            if sources.isEmpty {
                // Le fichier ne nomme aucun texte : on le dit, au lieu d'inventer un arrêté.
                sources = [SourceRegle(titre: "Règles FishMe du département \(departement.code) (texte non précisé dans le fichier)",
                                       citation: r.citation)]
            }
            return ReserveConnue(id: r.id, eauCle: cle, clesEquivalentes: equivalentes, eauNom: nom,
                                 departement: departement.code, phrase: r.phrase, sources: sources, lueLe: lecture,
                                 placeeSurUneEau: placee)
        }
    }
}
