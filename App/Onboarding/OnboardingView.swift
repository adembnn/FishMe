import Core
import SwiftUI

/// Le premier lancement, mené par Papy : langue → surnom (et e-mail facultatif) → zone → premiers poissons.
/// Chaque étape se passe en deux touchers au plus ; « Passer » reste visible partout. Rien n'est exigé : le surnom et l'e-mail
/// sont facultatifs (Apple 5.1.1), l'e-mail n'est gardé qu'avec la case de consentement, décochée au départ.
struct OnboardingView: View {
    enum Etape: Int, CaseIterable { case langue, compte, zone, poissons }
    enum ChoixZone { case position, carte }

    @Environment(RegionCourante.self) private var region

    let compte: CompteOnboarding
    let utiliserMaPosition: () -> Void
    let choisirSurLaCarte: () -> Void
    /// « Passer » sur l'étape de la zone : on entre dans l'app sans position (la carte la redemandera une fois).
    let passerLaZone: () -> Void
    var confidentialite: URL = ParcoursApp.confidentialiteProvisoire

    @State private var etape: Etape = .langue
    @State private var langue: LangueApp
    @State private var surnom = ""
    @State private var email = ""
    @State private var consentement = false
    @State private var age = false
    @State private var erreur: String?
    @State private var choixZone: ChoixZone?
    @State private var enCours = false

    init(compte: CompteOnboarding = .partage, langueInitiale: LangueApp? = nil,
         utiliserMaPosition: @escaping () -> Void, choisirSurLaCarte: @escaping () -> Void,
         passerLaZone: @escaping () -> Void) {
        self.compte = compte
        self.utiliserMaPosition = utiliserMaPosition
        self.choisirSurLaCarte = choisirSurLaCarte
        self.passerLaZone = passerLaZone
        _langue = State(initialValue: langueInitiale ?? LanguePersistee.choix() ?? LangueApp.duTelephone())
    }

    private var textes: TextesOnboarding { TextesOnboarding(langue: langue, ageMinimum: ageMinimum) }

    /// L'âge minimum avant toute position : le choix ou la région déjà connus, sinon la région du téléphone (13 aux États-Unis).
    private var ageMinimum: Int {
        if region.choix != .automatique || UserDefaults.standard.string(forKey: RegionCourante.cleDeduite) != nil {
            return region.region.ageMinimum
        }
        return Locale.current.region?.identifier == "US" ? RegionApp.etatsUnis.ageMinimum : RegionApp.france.ageMinimum
    }

    private var variante: VarianteDialogue { VarianteDialogue.active }

    var body: some View {
        VStack(spacing: 0) {
            barre
            ScrollView {
                scene
                    .padding(.horizontal, Espace.bord)
                    .padding(.top, Espace.m)
                    .padding(.bottom, Espace.l)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            choix
        }
        .background(
            LinearGradient(colors: [Palette.marineDoux, Palette.fond], startPoint: .top, endPoint: .center).ignoresSafeArea()
                .overlay(Palette.fond.opacity(0.0))
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding")
        .environment(\.locale, langue.locale)
    }

    // MARK: Scène : la bulle part de Papy

    /// Le champ du surnom et de l'e-mail apparaît sous la bulle, sans écran de formulaire séparé.
    private var champs: some View { etape == .compte ? AnyView(formulaireCompte) : AnyView(EmptyView()) }

    private var tailleDuPapy: CGFloat {
        let compte = etape == .compte
        switch variante {
        case .a: return compte ? 230 : 340
        case .b: return compte ? 150 : 200
        }
    }

    private var papy: some View { PapyPersonnage(pose: pose, hauteur: tailleDuPapy) }

    @ViewBuilder private var scene: some View {
        switch variante {
        case .a:
            // A : bulle à gauche/au-dessus, Papy GRAND à droite à mi-hauteur (les champs passent sous la bulle, à gauche de lui).
            VStack(alignment: .leading, spacing: Espace.s) {
                BulleDialogue(texte: replique, queueDepuisLaDroite: 70)
                if etape == .zone {
                    Text(textes.aideZone).font(Police.detail).foregroundStyle(Palette.encreDouce)
                }
                HStack(alignment: .center, spacing: 0) {
                    Spacer(minLength: 0)
                    papy
                }
                .frame(minHeight: etape == .compte ? 0 : 360)
                champs
            }
        case .b:
            // B : bulle pleine largeur, champs, puis Papy plus petit à droite, en bas ; les choix suivent en dessous.
            VStack(alignment: .leading, spacing: Espace.m) {
                BulleDialogue(texte: replique, queueDepuisLaDroite: 50)
                if etape == .zone {
                    Text(textes.aideZone).font(Police.detail).foregroundStyle(Palette.encreDouce)
                }
                champs
                HStack { Spacer(minLength: 0); papy }
            }
        }
    }

    // MARK: Barre : progression et « Passer »

    private var barre: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(Etape.allCases, id: \.rawValue) { e in
                    Capsule()
                        .fill(e.rawValue <= etape.rawValue ? Palette.marine : Palette.filet)
                        .frame(width: e == etape ? 22 : 8, height: 8)
                }
            }
            .accessibilityHidden(true)
            Spacer()
            Button(textes.passer) { passer() }
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                .accessibilityIdentifier("onboarding.passer")
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
    }

    private var pose: PapyPersonnage.Pose {
        switch etape {
        case .langue: .salut
        case .compte: .rit
        case .zone: .montre
        case .poissons: .pouce
        }
    }

    private var replique: String {
        switch etape {
        case .langue: textes.replique1
        case .compte: textes.replique2
        case .zone: textes.replique3
        case .poissons: textes.replique4
        }
    }

    // MARK: Les champs du compte

    private var formulaireCompte: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            champ(textes.champSurnom, texte: $surnom, identifiant: "onboarding.surnom", contenu: .nickname, clavier: .default)
            Text(textes.aideSurnom).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Toggle(textes.age, isOn: $age)
                .font(Police.detail)
                .tint(Palette.marine)
                .accessibilityIdentifier("onboarding.age")
            champ(textes.placeholderEmail, texte: $email, identifiant: "onboarding.email", contenu: .emailAddress, clavier: .emailAddress)
                .padding(.top, Espace.xs)
            Text(textes.champEmail + " · " + textes.aideEmail).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Toggle(textes.consentement, isOn: $consentement)
                .font(Police.detail)
                .tint(Palette.marine)
                .accessibilityIdentifier("onboarding.consentement")
            Link(textes.confidentialite, destination: confidentialite)
                .font(Police.detail)
                .foregroundStyle(Palette.marine)
                .accessibilityIdentifier("onboarding.confidentialite")
            if let erreur {
                Text(erreur).font(Police.detail).foregroundStyle(Palette.bouchon)
                    .accessibilityIdentifier("onboarding.erreur")
            }
        }
    }

    private func champ(_ titre: String, texte: Binding<String>, identifiant: String, contenu: UITextContentType,
                       clavier: UIKeyboardType) -> some View {
        TextField(titre, text: texte)
            .textContentType(contenu)
            .keyboardType(clavier)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(Police.corps)
            .padding(.horizontal, Espace.l)
            .frame(minHeight: Gabarit.bouton)
            .background(Palette.surface, in: Capsule())
            .overlay(Capsule().stroke(Palette.filet, lineWidth: 1))
            .accessibilityIdentifier(identifiant)
    }

    // MARK: Les choix, en bas, comme des réponses dans une conversation

    @ViewBuilder private var choix: some View {
        VStack(spacing: Espace.s) {
            switch etape {
            case .langue:
                ForEach(LangueApp.allCases) { l in
                    reponse(l.nomPropre, principal: l == langue, id: "onboarding.langue.\(l.rawValue)") { langue = l; validerLangue() }
                }
            case .compte:
                reponse(textes.continuer, principal: true, id: "onboarding.continuer") { Task { await validerCompte(sansEmail: false) } }
                reponse(textes.continuerSansEmail, principal: false, id: "onboarding.sans-email") { Task { await validerCompte(sansEmail: true) } }
            case .zone:
                reponse(textes.maPosition, principal: true, id: "onboarding.position", icone: "location.fill") { choixZone = .position; etape = .poissons }
                reponse(textes.surLaCarte, principal: false, id: "onboarding.carte", icone: "map") { choixZone = .carte; etape = .poissons }
            case .poissons:
                reponse(textes.cestParti, principal: true, id: "onboarding.cestparti") { terminer() }
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.l)
        .padding(.top, Espace.s)
        .disabled(enCours)
    }

    /// Un choix : bouton arrondi, plein pour la réponse conseillée, cerné pour les autres.
    private func reponse(_ titre: String, principal: Bool, id: String, icone: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.s) {
                if let icone { Image(systemName: icone) }
                Text(titre)
            }
            .font(Police.sousTitre)
            .foregroundStyle(principal ? Palette.surMarine : Palette.marine)
            .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
            .background(principal ? Palette.marine : Palette.surface, in: Capsule())
            .overlay(Capsule().stroke(principal ? Color.clear : Palette.marine.opacity(0.35), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }

    // MARK: Actions

    private func validerLangue() {
        region.langueChoisie = langue
        etape = .compte
    }

    private func validerCompte(sansEmail: Bool) async {
        erreur = nil
        if sansEmail { email = ""; consentement = false }
        if !email.trimmingCharacters(in: .whitespaces).isEmpty, !consentement {
            erreur = textes.erreurConsentement
            return
        }
        enCours = true
        defer { enCours = false }
        let echec = await compte.enregistrer(surnom: surnom, ageDeclare: age, email: email, consentement: consentement,
                                             langue: langue.rawValue)
        switch echec {
        case .surnom(let refus): erreur = textes.erreurSurnom(refus)
        case .emailInvalide: erreur = textes.erreurEmail
        case .ageRequis: erreur = textes.erreurAge
        case nil: etape = .zone
        }
    }

    private func passer() {
        erreur = nil
        switch etape {
        case .langue: region.langueChoisie = langue; etape = .compte
        case .compte: etape = .zone
        case .zone: passerLaZone()
        case .poissons: terminer()
        }
    }

    private func terminer() {
        switch choixZone {
        case .position: utiliserMaPosition()
        case .carte: choisirSurLaCarte()
        case nil: passerLaZone()
        }
    }
}
