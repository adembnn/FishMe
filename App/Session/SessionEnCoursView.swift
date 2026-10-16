import SwiftUI
import Core

/// P14 C « Sujet » : l'écran plein de la session en cours. Fond clair, « Ton spot · <eau> » en haut, le chrono géant,
/// « Fin légale HH:MM », le poisson de la dernière prise et sa taille, « Ajouter une prise » en bas, « Terminer la session » en lien.
///
/// À brancher par A : cet écran remplace le bandeau posé sur la carte. Dans `RootView`, quand `app.moteur.enCours != nil`,
/// poser `SessionEnCoursView(moteur: app.moteur, ajouterPrise: { app.ajouterPrise() }, infosEspece: …, eau: …) { LigneSessionEmplacement(app: app) }`
/// en plein écran (par exemple `.overlay { … }` ou un `ZStack` au-dessus du `TabView`, `.ignoresSafeArea()` compris), et ne plus passer
/// `BandeauSession` à `VueCarte` (`bandeauSession` reste vide).
struct SessionEnCoursView<LigneConditions: View>: View {
    let moteur: SuiviSession
    let ajouterPrise: () -> Void
    /// Nom, image et latin d'une espèce (le catalogue de L1 vit hors du dossier Session).
    let infosEspece: (Espece) -> EspecePechable?
    /// « la Marne » : l'eau du spot, jamais le point exact. `nil` : « Ton spot » seul.
    let eau: String?
    let ligneConditions: LigneConditions
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var explicationFin = false
    @State private var confirmationFin = false

    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void,
         infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, eau: String? = nil,
         @ViewBuilder ligneConditions: () -> LigneConditions) {
        self.moteur = moteur
        self.ajouterPrise = ajouterPrise
        self.infosEspece = infosEspece
        self.eau = eau
        self.ligneConditions = ligneConditions()
    }

    var body: some View {
        if let session = moteur.enCours {
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                contenu(session, maintenant: moteur.maintenant())
            }
        }
    }

    private func contenu(_ session: SessionEnCours, maintenant: Date) -> some View {
        VStack(spacing: 0) {
            enTete(session)
            Spacer(minLength: Espace.l)
            chrono(session, maintenant: maintenant)
            Spacer(minLength: Espace.l)
            // Sans prise, le chrono reste seul : pas de poisson gris.
            if !FormatSortie.prises(session.sortie).isEmpty {
                dernierePrise(session)
                Spacer(minLength: Espace.l)
            }
            VStack(spacing: Espace.s) {
                Button(action: ajouterPrise) {
                    Label("Ajouter une prise", systemImage: "camera.fill")
                }
                .buttonStyle(.principal)
                Button("Terminer la session", role: .cancel) { confirmationFin = true }
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .confirmationDialog("Terminer la session ?", isPresented: $confirmationFin, titleVisibility: .visible) {
            Button("Terminer la session", role: .destructive) { moteur.terminer() }
            Button("Continuer à pêcher", role: .cancel) {}
        }
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    /// « Ton spot · <eau> », puis les avis (quota, fin légale) et la ligne de conditions.
    private func enTete(_ session: SessionEnCours) -> some View {
        VStack(spacing: Espace.s) {
            HStack(spacing: Espace.s) {
                Circle().fill(Palette.ouvert).frame(width: 10, height: 10).accessibilityHidden(true)
                Text(titreSpot)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                Spacer(minLength: 0)
            }
            ForEach(session.messages, id: \.self) { AvisSession(texte: $0) }
            if moteur.quotaAtteint { AvisSession(texte: "Quota du jour atteint") }
            if !tailleTexte.isAccessibilitySize { ligneConditions }
        }
    }

    private var titreSpot: String {
        if let eau, !eau.isEmpty { return "Ton spot · \(eau)" }
        return "Ton spot"
    }

    private func chrono(_ session: SessionEnCours, maintenant: Date) -> some View {
        VStack(spacing: Espace.m) {
            Text(BandeauSession<EmptyView>.formater(moteur.duree(a: maintenant)))
                .font(Police.taille(80, .heavy).monospacedDigit())
                .tracking(-3)
                .foregroundStyle(Palette.encre)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let legale = session.finLegale {
                Button { explicationFin.toggle() } label: {
                    Text("Fin légale \(BandeauSession<EmptyView>.heure(legale))")
                        .font(Police.sousTitre.monospacedDigit())
                        .foregroundStyle(Palette.encreDouce)
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Touche pour lire d'où vient cette heure")
                if explicationFin {
                    Text(BandeauSession<EmptyView>.explication(legale))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Le poisson de la dernière prise (image) et « 1 prise · 68 cm ». Aucune prise : une silhouette et « 0 prise ».
    private func dernierePrise(_ session: SessionEnCours) -> some View {
        let prises = FormatSortie.prises(session.sortie)
        let derniere = prises.last
        let infos = derniere.flatMap { infosEspece($0.espece) }
        return VStack(spacing: Espace.m) {
            Group {
                if let infos {
                    Image(infos.image).resizable().scaledToFit()
                } else {
                    Image(systemName: "fish.fill").resizable().scaledToFit()
                        .foregroundStyle(derniere == nil ? Palette.silhouette : Palette.marine)
                        .padding(.horizontal, 60)
                }
            }
            .frame(width: 190, height: 70)
            .accessibilityLabel(infos?.nom ?? "")
            Text(legendePrises(prises, derniere))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func legendePrises(_ prises: [Prise], _ derniere: Prise?) -> String {
        let n = prises.count
        var texte = n == 0 ? "0 prise" : "\(n) prise\(n > 1 ? "s" : "")"
        if let cm = derniere?.longueurCm { texte += " · \(Int(cm.rounded())) cm" }
        return texte
    }
}

extension SessionEnCoursView where LigneConditions == EmptyView {
    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void,
         infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, eau: String? = nil) {
        self.init(moteur: moteur, ajouterPrise: ajouterPrise, infosEspece: infosEspece, eau: eau) { EmptyView() }
    }
}
