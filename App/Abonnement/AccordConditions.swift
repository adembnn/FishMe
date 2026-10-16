import SwiftUI

/// Retient la dernière version des conditions acceptée. `UserDefaults` est injecté (celui de l'app par défaut) :
/// la struct n'est pas `Sendable`, elle s'utilise sur le main actor.
struct SuiviConditions {
    static let cle = "fishme.conditions.versionAcceptee"

    private let defauts: UserDefaults

    init(defauts: UserDefaults = .standard) {
        self.defauts = defauts
    }

    /// La version acceptée, ou `nil` si le pêcheur n'a rien accepté.
    var versionAcceptee: Int? {
        defauts.object(forKey: Self.cle) as? Int
    }

    /// Vrai si rien n'est accepté, ou si une version plus récente du texte est sortie.
    var doitDemander: Bool {
        guard let acceptee = versionAcceptee else { return true }
        return acceptee < TexteConditions.numeroVersion
    }

    func accepter() {
        defauts.set(TexteConditions.numeroVersion, forKey: Self.cle)
    }
}

/// La phrase à poser sous le bouton « Continuer » du premier lancement (pas d'inscription : le compte, c'est l'identifiant Apple).
/// « Conditions d'utilisation » ouvre la feuille des conditions ; « Politique de confidentialité » ouvre `confidentialite`.
struct LigneAccordConditions: View {
    let confidentialite: URL

    @State private var conditionsOuvertes = false

    /// Adresse interne interceptée par `openURL` : elle n'ouvre jamais Safari.
    private static let adresseConditions = URL(string: "fishme://conditions")

    var body: some View {
        Text(phrase)
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .environment(\.openURL, OpenURLAction { url in
                if url == Self.adresseConditions {
                    conditionsOuvertes = true
                    return .handled
                }
                return .systemAction
            })
            .sheet(isPresented: $conditionsOuvertes) { ConditionsFeuille() }
    }

    private var phrase: AttributedString {
        let debut = AttributedString("En continuant, tu acceptes les ")
        var conditions = AttributedString("Conditions d'utilisation")
        conditions.link = Self.adresseConditions
        let milieu = AttributedString(" et la ")
        var politique = AttributedString("Politique de confidentialité")
        politique.link = confidentialite
        let fin = AttributedString(".")
        return debut + conditions + milieu + politique + fin
    }
}

#if DEBUG
#Preview {
    LigneAccordConditions(confidentialite: LiensLegaux.conditionsApple)
        .padding(Espace.bord)
        .background(Palette.fond)
}
#endif
