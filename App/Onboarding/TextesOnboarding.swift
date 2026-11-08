import Foundation

/// Les textes de l'onboarding en français et en anglais, dans la langue CHOISIE (pas celle de la région).
/// Les répliques de Papy : affectueuses, un peu d'humour, aucune promesse de capture, jamais « autorisé » ni « allowed ».
nonisolated struct TextesOnboarding: Sendable, Equatable {
    let langue: LangueApp
    /// L'âge minimum de la région (15 en France, 13 aux États-Unis).
    var ageMinimum: Int = 15

    private var fr: Bool { langue == .francais }
    private func t(_ francais: String, _ anglais: String) -> String { fr ? francais : anglais }

    // Papy : quatre répliques, une par étape.
    var replique1: String { t("Approche, petit. Avant de pêcher, trois mots… D'abord : dans quelle langue on cause ?",
                              "Come on over, kid. Before we wet a line, a few quick things… First: which language do we speak?") }
    var replique2: String { t("Un pêcheur sans surnom, c'est une canne sans moulinet. Comment on t'appelle ?",
                              "An angler with no nickname is like a rod with no reel. What should I call you?") }
    var replique3: String { t("Maintenant, où traînes-tu ta ligne ? Je te montre les poissons du coin. Pas de promesse : même moi, certains jours, je ne prends rien.",
                              "Now, where do you wet a line? I'll show you the fish around there. No promises: some days even I come home empty-handed.") }
    var replique4: String { t("Direction l'eau ! Dis-moi quels poissons tu as déjà attrapés, et on remplit ton Pescedex.",
                              "To the water! Tell me which fish you've already caught, and we'll fill your Pescedex.") }

    var papy: String { "Papy" }

    // Boutons communs
    var passer: String { t("Passer", "Skip") }
    var continuer: String { t("Continuer", "Continue") }

    // Étape 1 : langue
    var titreLangue: String { t("Ta langue", "Your language") }
    var aideLangue: String { t("Tu pourras la changer dans Réglages.", "You can change it later in Settings.") }

    // Étape 2 : surnom et e-mail
    var titreSurnom: String { t("Ton surnom de pêcheur", "Your angler nickname") }
    var champSurnom: String { t("Surnom", "Nickname") }
    var aideSurnom: String { t("3 à 20 caractères : lettres, chiffres, tiret.", "3 to 20 characters: letters, numbers, hyphen.") }
    var placeholderEmail: String { t("nom@exemple.com", "name@example.com") }
    var champEmail: String { t("E-mail (facultatif)", "Email (optional)") }
    var aideEmail: String { t("Pour recevoir des nouvelles de FishMe et retrouver ton compte.", "To get FishMe news and recover your account.") }
    var consentement: String { t("J'accepte que FishMe m'écrive à cette adresse.", "I agree that FishMe may email me at this address.") }
    var confidentialite: String { t("Politique de confidentialité", "Privacy policy") }
    var age: String { t("J'ai \(ageMinimum) ans ou plus", "I am \(ageMinimum) or older") }
    var continuerSansEmail: String { t("Continuer sans e-mail", "Continue without email") }

    func erreurSurnom(_ refus: Surnom.Refus) -> String {
        switch refus {
        case .tropCourt: t("Au moins 3 caractères.", "At least 3 characters.")
        case .tropLong: t("20 caractères au plus.", "20 characters at most.")
        case .caractereInterdit: t("Lettres, chiffres et tiret seulement.", "Letters, numbers and hyphen only.")
        case .tiretMalPlace: t("Le tiret va entre deux lettres.", "The hyphen goes between two letters.")
        case .motRefuse: t("Ce mot n'est pas accepté.", "This word is not accepted.")
        }
    }
    var erreurEmail: String { t("Cette adresse e-mail n'a pas l'air valide.", "This email address doesn't look valid.") }
    var erreurConsentement: String { t("Coche la case pour que FishMe garde ton e-mail, ou continue sans e-mail.", "Tick the box so FishMe keeps your email, or continue without email.") }
    var erreurAge: String { t("Coche la case de l'âge pour créer ton surnom.", "Tick the age box to create your nickname.") }

    // Étape 3 : zone
    var titreZone: String { t("Où pêches-tu ?", "Where do you fish?") }
    var aideZone: String { t("Pour voir les poissons et les règles près de toi.", "To see the fish and the rules near you.") }
    var maPosition: String { t("Utiliser ma position", "Use my location") }
    var surLaCarte: String { t("Choisir sur la carte", "Choose on the map") }

    // Étape 4 : premiers poissons
    var titrePoissons: String { t("Tes premiers poissons", "Your first fish") }
    var cestParti: String { t("C'est parti", "Let's go") }

    // Réglages
    var langueReglage: String { t("Langue", "Language") }
}
