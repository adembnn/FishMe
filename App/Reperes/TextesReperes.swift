import Core
import Foundation

/// Tous les textes des repères. Rien ici ne promet un bon endroit, une sécurité ou un droit de pêcher :
/// un repère est une étiquette du pêcheur, une réserve est signalée d'après les textes lus, jamais écartée.
nonisolated enum TextesReperes {
    static let titreListe = "Mes repères"
    static let interrupteurCalque = "Mes repères"
    static let ajouterIci = "Ajouter un repère ici"
    static let ajouterSurLaCarte = "Choisir sur la carte"
    static let etatVide = "Aucun repère. Pose un parking, un poste ou un amorçage : il reste sur cet iPhone."
    static let nouveauTitre = "Nouveau repère"
    static let modifierTitre = "Modifier le repère"
    static let champNom = "Nom"
    static let champNote = "Note"
    static let enregistrer = "Enregistrer"
    static let annuler = "Annuler"
    static let modifier = "Modifier"
    static let supprimer = "Supprimer"
    static let supprimerQuestion = "Supprimer ce repère ?"
    static let supprimerExplication = "Le repère, sa note et ses photos seront effacés de cet iPhone et de ton iCloud."
    static let yAller = "Y aller"
    static let reglesIci = "Règles ici"
    static let noterPassage = "Noter un passage aujourd'hui"
    static let ajouterPhotos = "Ajouter des photos"
    static let photosDuRepere = "Photos"
    static let photosDesPrises = "Photos de tes prises ici"
    static let dernierPassage = "Dernier passage"
    static let jamaisNote = "Jamais noté"
    static let sansPhoto = "Aucune photo"
    static let prive = "Privé : ce repère n'est vu que par toi."
    static let sourcesTitre = "Sources"
    static let lectureSeule = "Ces repères viennent d'une version plus récente de FishMe. Mets l'app à jour pour les modifier."
    static let fichierIllisible = "Le fichier des repères était illisible. Une copie a été gardée."
    static let paywallTitre = "3 repères gratuits"
    static let paywallTexte = "Tu as posé tes 3 repères gratuits. Avec Pro, tu en poses autant que tu veux. Ceux qui existent restent à toi."
    static let voirPro = "Voir Pro"
    static let plafondTexte = "Tu as atteint le nombre maximal de repères (300). Supprime-en un pour en poser un autre."
    static let positionIndisponible = "Position indisponible. Choisis le point sur la carte."
    static let choisirPointTitre = "Touche la carte où poser le repère"
    static let poserCePoint = "Poser ici"
    static let horsDeFrance = "Règles non couvertes ici"
    static let applicationAbsente = "Cette application n'est pas installée sur cet iPhone."
    static let limitePhotos = "6 photos au plus par repère."
    static let photoRefusee = "Cette photo n'a pas pu être préparée."
    static let enregistrementImpossible = "Le repère n'a pas pu être enregistré sur cet iPhone."

    static func compteur(actifs: Int) -> String { "\(actifs) sur \(LimitesReperes.gratuits)" }

    static func confirmerTiers(_ nom: String) -> String { "\(nom) saura où se trouve ce repère. Continuer ?" }

    // MARK: Réserves

    static func reserveSurEau(_ nom: String) -> String { "Une réserve est signalée sur \(nom) dans les textes lus." }

    static func reservesNonPlacees(_ nombre: Int) -> String {
        nombre == 1
            ? "Une réserve de ce département n'est pas placée sur la carte : vérifie sur place."
            : "\(nombre) réserves de ce département ne sont pas placées sur la carte : vérifie sur place."
    }

    static let aucuneReserve = "Aucune réserve connue ici dans nos textes. Vérifie sur place."

    static func lueLe(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR")))
    }

    // MARK: Icônes

    static func libelle(_ icone: IconeRepere) -> String {
        switch icone {
        case .parking: return "Parking"
        case .poste: return "Poste"
        case .danger: return "Danger"
        case .amorcage: return "Amorçage"
        }
    }

    /// Ce que VoiceOver lit pour l'icône seule (le texte affiché reste `libelle`).
    static func libelleVocal(_ icone: IconeRepere) -> String {
        switch icone {
        case .parking: return "parking"
        case .poste: return "poste de pêche"
        case .danger: return "danger"
        case .amorcage: return "amorçage"
        }
    }

    static func message(_ erreur: ErreurRepere) -> String {
        switch erreur {
        case .nomVide: return "Donne un nom au repère."
        case .nomTropLong: return "Le nom est trop long (\(LimitesReperes.nomMax) caractères au plus)."
        case .noteTropLongue: return "La note est trop longue (\(LimitesReperes.noteMax) caractères au plus)."
        }
    }
}
