import Foundation

/// Le verdict à trois valeurs des décisions du 7 nov. Il n'existe aucune valeur permissive : aucun cas « autorisé », « peut garder »
/// ou « en règle ». Le type l'interdit, et le moteur ne peut donc pas en produire.
public enum VerdictUS: String, Sendable, Hashable, Codable, CaseIterable {
    /// Une interdiction explicite, sourcée et confirmée s'applique (saison fermée, sous la taille, fenêtre protégée, limite atteinte, fermeture).
    case interdit
    /// Des règles existent mais sont incertaines, en conflit, non confirmées, ou n'interdisent rien de connu : vérifie l'agence.
    case aVerifier = "a_verifier"
    /// Aucune règle lue pour cette espèce à cet endroit.
    case donneeAbsente = "donnee_absente"

    public var libelle: String {
        switch self {
        case .interdit: "Interdit"
        case .aVerifier: "À vérifier"
        case .donneeAbsente: "Donnée absente"
        }
    }

    /// Phrase de tête, sans promesse : « à vérifier » vaut aussi pour « aucune interdiction connue ».
    public var phrase: String {
        switch self {
        case .interdit: "Il faut relâcher le poisson"
        case .aVerifier: "Aucune interdiction connue de nous, vérifie auprès de l'agence"
        case .donneeAbsente: "Nous n'avons lu aucune règle pour ce poisson ici, vérifie auprès de l'agence"
        }
    }
}

/// Pourquoi le moteur a rendu ce verdict. Chaque motif porte l'identifiant de la règle concernée pour afficher sa source.
public enum MotifUS: Sendable, Equatable {
    // Interdictions
    case horsSaison(regle: String)
    case fermeture(regle: String, type: TypeFermeture, motif: String)
    case sousTailleMinimale(regle: String, taille: Longueur, minimale: Longueur)
    case dansFenetreProtegee(regle: String, taille: Longueur, fenetre: FenetreProtegee)
    case auDessusTailleMaximale(regle: String, taille: Longueur, maximale: Longueur)
    case limiteDePriseAtteinte(regle: String, limite: Int)
    case limiteDePossessionAtteinte(regle: String, limite: Int)
    // Incertitudes
    case regleNonConfirmee(regle: String, statut: StatutRelecture)
    case regleExpiree(regle: String)
    case lectureAncienne(regle: String, jours: Int)
    case lectureDansLeFutur(regle: String)
    case reglesDEtatSurTerrainTribal(regle: String)
    case conflitEntreRegles(famille: FamilleRegle, regles: [String])
    case jourSurUneBorne(regle: String)
    case tailleALaLimite(regle: String)
    case tailleNonMesuree(regle: String)
    case tailleEstimee(regle: String)
    case ageInconnu(regle: String)
    case regleHorsTrancheDAge(regle: String)
    case enginsOuAppatsALire(regle: String)
    case compteursInconnus(regle: String)
    // Contexte
    case alerteTerrain(AlerteTerrain, juridiction: IdJuridiction)
    case juridictionInconnue(IdJuridiction)
    case aucuneRegleLue

    /// Phrase pour l'écran. Les tailles se formatent dans le système d'unités demandé, avec les arrondis du côté prudent.
    public func libelle(unites: SystemeUnites = .imperial) -> String {
        let f = FormatteurUnites(systeme: unites)
        switch self {
        case .horsSaison: return "Hors de la période d'ouverture lue"
        case .fermeture(_, let type, let motif):
            switch type {
            case .pecheInterdite: return "Pêche interdite ici : \(motif)"
            case .remiseAEauSeulement: return "Prise et relâche seulement : \(motif)"
            case .especeProtegee: return "Espèce protégée, à relâcher : \(motif)"
            }
        case .sousTailleMinimale(_, let t, let m):
            return "Sous la taille minimale (\(f.texte(m, role: .tailleMinimale))) : poisson mesuré \(f.texte(t))"
        case .dansFenetreProtegee(_, let t, let w):
            return "Dans la fenêtre protégée de \(f.texte(w.basse, role: .debutFenetreProtegee)) à \(f.texte(w.haute, role: .finFenetreProtegee)) : poisson mesuré \(f.texte(t))"
        case .auDessusTailleMaximale(_, let t, let m):
            return "Au-dessus de la taille maximale (\(f.texte(m, role: .tailleMaximale))) : poisson mesuré \(f.texte(t))"
        case .limiteDePriseAtteinte(_, let n): return "Limite de prise du jour atteinte (\(n))"
        case .limiteDePossessionAtteinte(_, let n): return "Limite de possession atteinte (\(n))"
        case .regleNonConfirmee: return "Règle lue mais pas encore confirmée par une seconde lecture"
        case .regleExpiree: return "Règle dont la date de validité est passée"
        case .lectureAncienne(_, let j): return "Règle lue il y a \(j) jours : l'édition a pu changer"
        case .lectureDansLeFutur: return "Date de lecture de la règle incohérente"
        case .reglesDEtatSurTerrainTribal: return "Terrain tribal : les règles d'État peuvent ne pas s'y appliquer"
        case .conflitEntreRegles(let fam, _): return "Deux règles de même niveau se contredisent (\(fam.rawValue))"
        case .jourSurUneBorne: return "Jour de début ou de fin de période : les textes divergent sur l'inclusion"
        case .tailleALaLimite: return "Poisson à la limite exacte : mesure de nouveau et vérifie"
        case .tailleNonMesuree: return "Poisson non mesuré : une règle de taille existe"
        case .tailleEstimee: return "Taille estimée, pas mesurée : une estimation ne suffit pas"
        case .ageInconnu: return "Une règle dépend de l'âge du pêcheur"
        case .regleHorsTrancheDAge: return "Les règles lues visent une autre tranche d'âge que la tienne"
        case .enginsOuAppatsALire: return "Des règles d'engins ou d'appâts existent : lis-les"
        case .compteursInconnus: return "Une limite existe : compte de tes prises non renseigné"
        case .alerteTerrain(let a, _):
            switch a {
            case .reserveTribale: return "Réserve tribale : permis de la tribu et règles propres"
            case .refugeFederal: return "Refuge fédéral : règles propres en plus de celles de l'État"
            case .parcNational: return "Parc national : règles propres en plus de celles de l'État"
            case .eauFrontaliere: return "Eau frontalière : deux États, réciprocité à vérifier"
            case .especeListeeESA: return "Espèce protégée par la loi fédérale sur les espèces menacées"
            }
        case .juridictionInconnue: return "Lieu absent de nos données"
        case .aucuneRegleLue: return "Aucune règle lue pour cette espèce à cet endroit"
        }
    }
}
