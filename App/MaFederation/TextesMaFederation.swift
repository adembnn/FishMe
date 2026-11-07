import Core
import Foundation

/// Les textes fixes de « Ma fédération » et du guide de mesure. Aucun verdict de taille ou de droit.
nonisolated enum TextesMaFederation {
    static let titre = "Ma fédération"
    static let siteFederation = "Site de ma fédération"
    static let evenements = "Événements et actualités"
    static let cartesNationales = "Toutes les cartes de pêche"
    static let ouvreSafari = "S'ouvre dans Safari"

    /// ⚠ à vérifier : la phrase exacte du texte fixe sur les règles locales est à fournir par Adem
    /// (décision 7 de `docs/fiches/N5.md`). Provisoire : le début donné par la fiche, sans rien ajouter au-delà.
    static let reglesLocales = "Cette application ne connaît pas les règles de pêche locales."
    /// Reprise des CGU, article 4 (à vérifier mot à mot avec S2).
    static let renseigneToi = "Renseigne-toi auprès de ta fédération ou de ton association agréée (AAPPMA)."

    static let numerosTitre = "Numéros utiles"
    static let autresNumeros = "Autres numéros"
    static let ouvrirSource = "Voir la source"

    /// `locale` : français par défaut (les tests comparent le texte français) ; l'écran passe la langue de la région.
    static func releveLe(_ jourTexte: String, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        AnglaisE.f("Lien relevé le %@", locale, jourTexte)
    }
    static func sourceNumeros(_ jourTexte: String, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        AnglaisE.f("Source : %@, relevé le %@", locale, NumerosUtiles.nomDeLaSource, jourTexte)
    }

    // Guide de mesure
    static let mesureTitre = "Mesurer un poisson"
    static let mesureEtapes = [
        "Pose le poisson à plat, sur une toise.",
        "Le museau touche le zéro.",
        "Lis la longueur au bout de la queue.",
    ]
    static let mesureLegende = "Ce guide montre où mesurer. Il ne dit pas si ton poisson a la bonne taille : regarde les règles de ton spot."
    /// ⚠ à vérifier : le geste « du museau à l'extrémité de la queue » vient d'Adem, non confirmé à un texte officiel
    /// (Code de l'environnement ou arrêté). Tant qu'aucune source n'est citée, le guide se présente comme un repère pratique.
    static let mesureRepere = "Repère pratique, du museau à l'extrémité de la queue."
    static let mesureDessin = "Poisson mesuré du museau au bout de la queue : une flèche va du museau à l'extrémité de la queue."
}
