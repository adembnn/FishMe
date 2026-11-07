import Foundation

/// Les textes de « Ma carte de pêche ». Jamais de verdict : l'app lit une date saisie par le pêcheur.
nonisolated enum TextesCartePeche {
    static let titre = "Ma carte de pêche"
    static let vide = "Garde ici une photo ou un PDF de ta carte de pêche. Rien n'est obligatoire pour utiliser FishMe."
    static let choisirPhoto = "Choisir une photo"
    static let choisirPDF = "Choisir un PDF"
    static let remplacer = "Remplacer le fichier"

    static let millesime = "Millésime"
    static let association = "Association (AAPPMA)"
    static let associationExemple = "Facultatif"
    static let expiration = "Date d'expiration"
    static let rappel = "Me prévenir 30 jours avant"
    static let rappelExplication = "Pour te prévenir 30 jours avant l'expiration."
    static let notificationsCoupees = "Les notifications sont coupées pour FishMe"
    static let ouvrirReglages = "Ouvrir les réglages"
    static let rappelProgramme = "Rappel programmé pour le "

    static let afficherEnGrand = "Afficher en grand"
    static let supprimer = "Supprimer ma carte"
    static let confirmationTitre = "Supprimer ma carte ?"
    static let confirmationMessage = "La fiche, le fichier et le rappel seront effacés de cet iPhone."
    static let annuler = "Annuler"
    static let fermer = "Fermer"

    /// ⚠ à vérifier avec S2 : la dernière phrase est reprise des CGU, article 4.
    static let nonOfficiel = "Copie personnelle, pas une carte officielle. FishMe n'est lié ni à la FNPF ni à cartedepeche.fr. Garde ta carte officielle sur toi."
    static let sauvegarde = "Ta carte reste sur ton iPhone, dans l'espace protégé de l'app. Elle est sauvegardée avec ta sauvegarde iPhone, si tu l'as activée."
    /// Bas du plein écran.
    static let pleinEcranMention = "Copie personnelle · pas une carte officielle"

    static let fichierTropLourd = "Fichier trop lourd. Prends une photo plus petite."
    static let fichierIllisible = "Ce fichier ne peut pas être lu. Essaie une autre photo ou un autre PDF."
    static let enregistrementImpossible = "La carte n'a pas pu être enregistrée sur cet iPhone."
    static let ficheIllisible = "La fiche enregistrée est illisible. Tu peux la supprimer et la refaire."

    /// `locale` : français par défaut (les tests comparent le texte français).
    static func accessibiliteApercu(genre: String, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        AnglaisE.f("Aperçu de ta carte de pêche (%@)", locale, genre)
    }
}
