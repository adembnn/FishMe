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

    var body: some View {
        VStack(spacing: 0) {
            barre
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.xl) {
                    PapyOnboardingView(replique: replique)
                    contenu
                }
                .padding(.horizontal, Espace.bord)
                .padding(.top, Espace.l)
                .padding(.bottom, Espace.xl)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            pied
        }
        .background(Palette.fond.ignoresSafeArea())
        .accessibilityIdentifier("onboarding")
        .environment(\.locale, langue.locale)
    }

    private var replique: String {
        switch etape {
        case .langue: textes.replique1
        case .compte: textes.replique2
        case .zone: textes.replique3
        case .poissons: textes.replique4
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

    // MARK: Contenu de chaque étape

    @ViewBuilder private var contenu: some View {
        switch etape {
        case .langue: choixLangue
        case .compte: formulaireCompte
        case .zone: tuilesPoissons
        case .poissons: tuilesPoissons
        }
    }

    private var choixLangue: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text(textes.titreLangue).font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
            ForEach(LangueApp.allCases) { choix in
                Button {
                    langue = choix
                } label: {
                    HStack {
                        Text(choix.nomPropre).font(Police.sousTitre).foregroundStyle(Palette.encre)
                        Spacer()
                        Image(systemName: langue == choix ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(langue == choix ? Palette.marine : Palette.silhouette)
                            .font(.title2)
                    }
                    .padding(.horizontal, Espace.l)
                    .frame(minHeight: Gabarit.bouton)
                    .background(langue == choix ? Palette.marineDoux : Palette.surface,
                                in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
                        .stroke(langue == choix ? Palette.marine : Palette.filet, lineWidth: langue == choix ? 2 : 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(langue == choix ? .isSelected : [])
                .accessibilityIdentifier("onboarding.langue.\(choix.rawValue)")
            }
            Text(textes.aideLangue).font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }

    private var formulaireCompte: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text(textes.titreSurnom).font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
            champ(textes.champSurnom, texte: $surnom, identifiant: "onboarding.surnom", contenu: .nickname, clavier: .default)
            Text(textes.aideSurnom).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Toggle(textes.age, isOn: $age)
                .font(Police.detail)
                .tint(Palette.marine)
                .accessibilityIdentifier("onboarding.age")

            Text(textes.champEmail).font(Police.sousTitre).foregroundStyle(Palette.encre).padding(.top, Espace.s)
            champ("nom@exemple.com", texte: $email, identifiant: "onboarding.email", contenu: .emailAddress, clavier: .emailAddress)
            Text(textes.aideEmail).font(Police.legende).foregroundStyle(Palette.encreDouce)
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
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous).stroke(Palette.filet, lineWidth: 1))
            .accessibilityIdentifier(identifiant)
    }

    /// Trois espèces communes, avec leur nom dans la langue choisie.
    private var tuilesPoissons: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text(etape == .zone ? textes.titreZone : textes.titrePoissons)
                .font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
            if etape == .zone {
                Text(textes.aideZone).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
            HStack(spacing: 10) {
                ForEach(["gardon", "brochet", "sandre"], id: \.self) { id in
                    ImageEspece(nom: id, libelle: NomsEspeces.nom(id: id, langue: langue.codeNoms, defaut: id.capitalized))
                        .padding(.horizontal, 6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    // MARK: Pied : boutons de l'étape

    @ViewBuilder private var pied: some View {
        VStack(spacing: Espace.xs) {
            switch etape {
            case .langue:
                Button(textes.continuer) { validerLangue() }
                    .buttonStyle(.principal)
                    .accessibilityIdentifier("onboarding.continuer")
            case .compte:
                Button(textes.continuer) { Task { await validerCompte(sansEmail: false) } }
                    .buttonStyle(.principal)
                    .disabled(enCours)
                    .accessibilityIdentifier("onboarding.continuer")
                Button(textes.continuerSansEmail) { Task { await validerCompte(sansEmail: true) } }
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .disabled(enCours)
                    .accessibilityIdentifier("onboarding.sans-email")
            case .zone:
                Button { choixZone = .position; etape = .poissons } label: {
                    Label(textes.maPosition, systemImage: "location.fill")
                }
                .buttonStyle(.principal)
                .accessibilityIdentifier("onboarding.position")
                Button(textes.surLaCarte) { choixZone = .carte; etape = .poissons }
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .accessibilityIdentifier("onboarding.carte")
            case .poissons:
                Button(textes.cestParti) { terminer() }
                    .buttonStyle(.principal)
                    .accessibilityIdentifier("onboarding.cestparti")
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.l)
        .padding(.top, Espace.s)
        .background(Palette.fond)
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
