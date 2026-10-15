import Foundation

/// Une règle dont `expire_le` est passé ne donne jamais un feu vert, même venue d'un fichier téléchargé :
/// elle devient une ligne « à vérifier sur place », « vérifie l'arrêté » avec l'année en cours.
public enum Peremption {
    /// Un fichier dont la plus proche expiration approche (alerte de la veille : moins de 30 jours).
    public struct FichierQuiExpire: Sendable, Equatable {
        public var code: String
        public var expireMin: Date
        public var joursRestants: Int
    }

    /// Périmée dès le lendemain du jour d'`expire_le` (le 31/12/2026 est encore valable, le 01/01/2027 non).
    static func estPerimee(expireLe: String?, le date: Date) -> Bool {
        guard let expireLe, let reste = Jours.jours(de: date, jusquA: expireLe) else { return false }
        return reste < 0
    }

    static func type(de brut: String) -> TypeRegle {
        switch brut {
        case "taille_min": return .taille
        case "ouverture", "fenetre_capture": return .periode
        case "quota_jour": return .quota
        case "mode_peche": return .modeDePeche
        case "horaire", "carpe_nuit": return .nuit
        case "reserve": return .reserve
        case "consommation": return .consommation
        case "transport_vivant": return .transportVivant
        default: return .autre
        }
    }

    /// Ajoute les lignes périmées au résultat d'un contrôle et empêche tout feu vert : la consigne « aucune règle
    /// saisie ne l'interdit » devient « vérifie l'arrêté ». « Relâche-la » et « mesure-la sur une toise » restent,
    /// car elles sont plus strictes.
    public static func durcir(_ resultat: ResultatControle, avec perimees: [LigneControle]) -> ResultatControle {
        guard !perimees.isEmpty else { return resultat }
        var consigne = resultat.consigne
        if consigne == .aucuneRegleSaisieNeLInterdit { consigne = .verifieLArrete }
        return ResultatControle(lignes: resultat.lignes + perimees, consigne: consigne)
    }
}

extension CatalogueRegles {
    /// Les règles périmées au jour `date`, du département et du socle national, qui visent cette espèce (ou toutes),
    /// en lignes « à vérifier sur place » (raison `.perimee`), avec la source et la citation du texte périmé.
    public func lignesPerimees(departement: Departement, espece: Espece, date: Date) -> [LigneControle] {
        var lignes: [LigneControle] = []
        let annee = Jours.annee(date)
        for code in [departement.code, Self.codeNational] {
            guard let fichier = meilleure(code)?.fichier else { continue }
            for regle in fichier.regles where Peremption.estPerimee(expireLe: regle.expireLe, le: date) {
                if !regle.especes.isEmpty {
                    guard let sandre = espece.codeSandre, regle.especes.contains(sandre) || regle.especes.contains(espece.id)
                    else { continue }
                }
                let depuis = regle.expireLe.map(Jours.francais(iso:)) ?? ""
                lignes.append(LigneControle(
                    type: Peremption.type(de: regle.type), etat: .aVerifierSurPlace, raison: .perimee,
                    phrase: "Cette règle était valable jusqu'au \(depuis) : vérifie l'arrêté \(annee).",
                    sources: regle.sources, citation: regle.citation,
                    dateLecture: regle.dateLecture.flatMap(Jours.date(iso:))))
            }
        }
        return lignes
    }

    /// Les fichiers dont le plus petit `expire_le` tombe dans moins de `jours` jours (déjà passé compris).
    public func fichiersQuiExpirent(dans jours: Int = 30, le date: Date) -> [Peremption.FichierQuiExpire] {
        let codes = [Self.codeNational] + departementsCouverts().map(\.departement.code)
        return codes.compactMap { code in
            guard let min = meilleure(code)?.fichier.expireMin, let reste = Jours.jours(de: date, jusquA: min),
                  reste < jours, let jour = Jours.date(iso: min) else { return nil }
            return Peremption.FichierQuiExpire(code: code, expireMin: jour, joursRestants: reste)
        }
    }
}
