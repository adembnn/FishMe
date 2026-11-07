import Foundation

/// Que dit le moteur d'un État de niveau 1 sans aucune règle par espèce. Décision du 7 nov. non tranchée : « donnée absente » pour
/// l'instant ; passer à `.aVerifier` ne change que ce paramètre. Jamais « interdit » : sans règle lue, rien n'est interdit par nous.
public enum VerdictNiveau1US: Sendable, Equatable {
    case donneeAbsente
    case aVerifier

    var verdict: VerdictUS { self == .aVerifier ? .aVerifier : .donneeAbsente }
}

/// `MoteurUS` + niveau 1 : le moteur est alimenté par les règles chargées, et chaque État connu du niveau 1 devient une juridiction
/// racine (avec le lien de son agence) pour que la question « lac X en Y » reçoive au moins le lien et un verdict honnête.
public struct EvaluateurUS: Sendable {
    public let moteur: MoteurUS
    public let niveau1: Niveau1US?
    public let verdictNiveau1: VerdictNiveau1US
    private let etatsAvecRegles: Set<CodeEtat>

    public init(contenu: ContenuReglesUS, niveau1: Niveau1US? = nil, verdictNiveau1: VerdictNiveau1US = .donneeAbsente,
                parametres: ParametresMoteurUS = ParametresMoteurUS()) throws {
        let presents = Set(contenu.juridictions.map(\.id))
        var racines: [Juridiction] = []
        for e in niveau1?.etats ?? [] where !presents.contains(.etat(e.code)) {
            if let j = Juridiction.etat(e.code, nom: e.nom, lienAgence: e.lienOfficiel) { racines.append(j) }
        }
        self.moteur = MoteurUS(arbre: try contenu.arbre(avec: racines), regles: contenu.regles, exigences: contenu.exigences, parametres: parametres)
        self.niveau1 = niveau1
        self.verdictNiveau1 = verdictNiveau1
        self.etatsAvecRegles = Set(contenu.etats.filter { !$0.regles.isEmpty }.map(\.code))
    }

    public func evaluer(_ q: QuestionUS) -> ResultatUS {
        let r = moteur.evaluer(q)
        guard let etat = moteur.arbre.chaine(de: q.juridiction)?.first?.etat else { return r }
        var verdict = r.verdict
        // État de niveau 1 : connu du niveau 1, aucune règle chargée pour lui.
        if verdict == .donneeAbsente, r.motifs.contains(.aucuneRegleLue), niveau1?[etat] != nil, !etatsAvecRegles.contains(etat) {
            verdict = verdictNiveau1.verdict
        }
        let lien = r.lienAgence ?? niveau1?[etat]?.lienOfficiel
        guard verdict != r.verdict || lien != r.lienAgence else { return r }
        return ResultatUS(verdict: verdict, motifs: r.motifs, regles: r.regles, sources: r.sources, exigences: r.exigences, alertes: r.alertes,
                          lienAgence: lien, couverture: r.couverture, lectureLaPlusAncienne: r.lectureLaPlusAncienne)
    }
}
