import SwiftUI
import Core

/// P14 C « Sujet » : l'écran plein de la session en cours. Fond clair, « Ton spot · <eau> » en haut, le chrono géant,
/// « Fin légale HH:MM », le poisson de la dernière prise et sa taille, « Ajouter une prise » en bas, « Terminer la session » en lien.
///
/// À brancher par A : cet écran remplace le bandeau posé sur la carte. Dans `RootView`, quand `app.moteur.enCours != nil`,
/// poser `SessionEnCoursView(moteur: app.moteur, ajouterPrise: { app.ajouterPrise() }, infosEspece: …, eau: …) { LigneSessionEmplacement(app: app) }`
/// en plein écran (par exemple `.overlay { … }` ou un `ZStack` au-dessus du `TabView`, `.ignoresSafeArea()` compris), et ne plus passer
/// `BandeauSession` à `VueCarte` (`bandeauSession` reste vide).
///
/// État réduit (16 oct., « plein écran réductible ») : avec `reduire`, un bouton « Carte » en haut et un geste vers le bas
/// rendent la main à la racine, qui pose alors `BandeauSessionView` sur la carte ; toucher le bandeau rouvre ce plein écran.
struct SessionEnCoursView<LigneConditions: View>: View {
    let moteur: SuiviSession
    let ajouterPrise: () -> Void
    /// Nom, image et latin d'une espèce (le catalogue de L1 vit hors du dossier Session).
    let infosEspece: (Espece) -> EspecePechable?
    /// « la Marne » : l'eau du spot, jamais le point exact. `nil` : « Ton spot » seul.
    let eau: String?
    /// Réduit l'écran en bandeau sur la carte. `nil` : pas de bouton « Carte », pas de geste.
    let reduire: (() -> Void)?
    let ligneConditions: LigneConditions
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var explicationFin = false
    @State private var confirmationFin = false

    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void,
         infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, eau: String? = nil,
         reduire: (() -> Void)? = nil,
         @ViewBuilder ligneConditions: () -> LigneConditions) {
        self.moteur = moteur
        self.ajouterPrise = ajouterPrise
        self.infosEspece = infosEspece
        self.eau = eau
        self.reduire = reduire
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
        // Maquette : chrono à 190 pt du haut, poisson à 430 pt, boutons à 24 pt du bas (écran 390 × 844, haut sûr 59 pt).
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                enTete(session)
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    Button(action: ajouterPrise) {
                        Label("Ajouter une prise", systemImage: "camera")
                    }
                    .buttonStyle(.principal)
                    Button("Terminer la session", role: .cancel) { confirmationFin = true }
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.marine)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                        .padding(.top, Espace.xs)
                }
            }
            // Sans prise, l'anneau est au milieu de l'écran ; avec une prise il remonte pour laisser la place au poisson.
            chrono(session, maintenant: maintenant)
                .padding(.top, FormatSortie.prises(session.sortie).isEmpty ? 330 - 59 : 150 - 59)
            // Sans prise, le chrono reste seul : pas de poisson gris.
            if !FormatSortie.prises(session.sortie).isEmpty {
                dernierePrise(session)
                    .padding(.top, 430 - 59)
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, 24)
        .ignoresSafeArea(edges: .bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .simultaneousGesture(gesteReduire)
        .confirmationDialog("Terminer la session ?", isPresented: $confirmationFin, titleVisibility: .visible) {
            Button("Terminer la session", role: .destructive) { moteur.terminer() }
            Button("Continuer à pêcher", role: .cancel) {}
        }
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    /// Un geste vers le bas (assez long, surtout vertical) réduit l'écran en bandeau.
    private var gesteReduire: some Gesture {
        DragGesture(minimumDistance: 24).onEnded { (valeur: DragGesture.Value) in
            let bas: Bool = valeur.translation.height > 90 && abs(valeur.translation.width) < valeur.translation.height
            if bas, let reduire { reduire() }
        }
    }

    /// « Carte » : le bouton qui réduit P14 en bandeau (seulement si la racine a fourni `reduire`).
    @ViewBuilder
    private var boutonReduire: some View {
        if let reduire {
            Button(action: reduire) {
                Label("Carte", systemImage: "map")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                    .padding(.horizontal, Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .background(Palette.tuile, in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Réduit la session en bandeau sur la carte")
        }
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
                boutonReduire
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

    /// Le chrono façon minuteur d'Apple : un anneau qui avance jusqu'à la fin légale (un tour par heure si elle est inconnue),
    /// le temps écoulé en gros chiffres fins au centre. Le reste de l'écran (boutons, poisson) est celui du design système.
    private func chrono(_ session: SessionEnCours, maintenant: Date) -> some View {
        let ecoule = moteur.duree(a: maintenant)
        return ChronoAnneauView(temps: Self.temps(ecoule), progression: progression(session, maintenant: maintenant),
                                diametre: 270) {
            if let legale = session.finLegale {
                VStack(spacing: 2) {
                    Button { explicationFin.toggle() } label: {
                        Text("Fin légale \(BandeauSession<EmptyView>.heure(legale))")
                            .font(Police.taille(15, .heavy).monospacedDigit())
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Touche pour lire d'où vient cette heure")
                    if explicationFin {
                        Text(BandeauSession<EmptyView>.explication(legale))
                            .font(Police.legende)
                            .foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Durée de la session")
        .accessibilityValue(Self.temps(ecoule))
    }

    /// Temps écoulé jusqu'à la fin légale si elle est connue ; sinon un tour par heure.
    private func progression(_ session: SessionEnCours, maintenant: Date) -> Double {
        let ecoule = moteur.duree(a: maintenant)
        if let legale = session.finLegale {
            let total = legale.timeIntervalSince(session.sortie.debut)
            if total > 0 { return min(1, ecoule / total) }
        }
        return ecoule.truncatingRemainder(dividingBy: 3600) / 3600
    }

    /// « 1:23:45 » ou « 12:34 ».
    private static func temps(_ secondes: TimeInterval) -> String {
        let total = Int(secondes)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// Le poisson de la dernière prise (image) et « 1 prise · 68 cm ». Aucune prise : une silhouette et « 0 prise ».
    private func dernierePrise(_ session: SessionEnCours) -> some View {
        let prises = FormatSortie.prises(session.sortie)
        let derniere = prises.last
        let infos = derniere.flatMap { infosEspece($0.espece) }
        return VStack(spacing: 10) {
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
         infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, eau: String? = nil,
         reduire: (() -> Void)? = nil) {
        self.init(moteur: moteur, ajouterPrise: ajouterPrise, infosEspece: infosEspece, eau: eau, reduire: reduire) { EmptyView() }
    }
}
