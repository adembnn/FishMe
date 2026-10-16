import Core
import SwiftUI

/// E6 : la carte d'une prise confirmée se révèle en plein écran. Elle arrive face cachée, un toucher (ou un court délai)
/// la retourne ; un toucher de plus montre la vraie photo au verso. « Ranger dans le Pescedex » ferme l'écran.
/// La carte est déjà enregistrée par `DepotCartes` : cette vue ne fait que la montrer.
struct RevelationCarteView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    /// Délai avant la révélation automatique, en secondes.
    var delaiAuto: Double = 1.4
    let ranger: () -> Void

    /// Révélations déjà montrées pendant cette session de l'app.
    @MainActor private static var dejaRevelees = 0
    /// Vrai à partir de la 2e révélation, ou pour un « commun » déjà possédé : le bouton est là tout de suite.
    var dejaPossedee = false

    private enum Face { case cachee, recto, verso }

    @State private var face: Face = .cachee
    @State private var angle: Double = 0
    @State private var enCours = false
    @State private var mouvement = MouvementIPhone()
    @State private var rapide = false
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    private var style: StyleRarete { infos.style }

    private var boutonVisible: Bool { face != .cachee || rapide || reduireAnimations }

    var body: some View {
        ZStack {
            Palette.fond.ignoresSafeArea()
            VStack(spacing: 14) {
                Spacer(minLength: 24)
                carte
                    .padding(.horizontal, 20)
                    .rotation3DEffect(.degrees(reduireAnimations ? 0 : angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                rarete
                    .opacity(face == .cachee ? 0 : 1)
                    .frame(minHeight: Gabarit.zoneTactile)
                Button(action: ranger) {
                    Text("Ranger dans le Pescedex")
                }
                .buttonStyle(.principal)
                .padding(.horizontal, 20)
                .opacity(boutonVisible ? 1 : 0)
                .disabled(!boutonVisible)
                .accessibilityHidden(!boutonVisible)
                Spacer(minLength: 16)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if rapide { ranger() } }
        .task {
            guard face == .cachee else { return }
            try? await Task.sleep(for: .seconds(reduireAnimations ? 0.3 : (rapide ? 0.15 : delaiAuto)))
            if !Task.isCancelled, face == .cachee { await retourner(vers: .recto) }
        }
        .onAppear {
            rapide = Self.dejaRevelees >= 1 || (dejaPossedee && infos.style == .commun)
            Self.dejaRevelees += 1
        }
        .onAppear { if style.aUnReflet && !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
        .sensoryFeedback(.success, trigger: face == .recto)
    }

    @ViewBuilder
    private var carte: some View {
        Group {
            switch face {
            case .cachee:
                DosDeCarte(style: style)
                    .accessibilityLabel("Carte face cachée")
                    .accessibilityHint("Touche pour la révéler")
            case .recto:
                CarteRectoView(infos: infos, anime: true, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(infos.texteVoixOff)
                    .accessibilityHint("Touche pour voir la photo au verso")
            case .verso:
                CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                    .accessibilityHint("Touche pour revoir le recto")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if rapide { ranger(); return }
            Task {
                switch face {
                case .cachee, .verso: await retourner(vers: .recto)
                case .recto: await retourner(vers: .verso)
                }
            }
        }
        .accessibilityAddTraits(.isButton)
    }

    private var rarete: some View {
        HStack(spacing: 10) {
            BadgeRarete(style: style, taille: 32)
            if style != .nonMesuree {
                PointsRarete(style: style, taille: 10)
            }
            Text(style.mot.capitalized)
                .font(Jeton.police(19))
                .foregroundStyle(style.couleur)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rareté : \(style.mot)")
    }

    /// Premier quart de tour jusqu'à 90 degrés, changement de face, second quart de tour. Sans animation : fondu.
    private func retourner(vers cible: Face) async {
        guard !enCours else { return }
        enCours = true
        defer { enCours = false }
        if reduireAnimations {
            withAnimation(.easeInOut(duration: 0.2)) { face = cible }
            return
        }
        withAnimation(.easeIn(duration: 0.22)) { angle = 90 }
        try? await Task.sleep(for: .milliseconds(220))
        face = cible
        angle = -90
        withAnimation(.spring(duration: 0.35)) { angle = 0 }
    }
}

/// Le dos de la carte avant la révélation : même cadre et même taille que le recto, couleur de la rareté.
private struct DosDeCarte: View {
    let style: StyleRarete

    var body: some View {
        CarteCadre(style: style, declaree: false) {
            ZStack {
                LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
                Image(systemName: "fish.fill")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityHidden(true)
            }
        }
    }
}

#if DEBUG
#Preview("Révélation, rare") {
    let prise = Prise(espece: Espece(id: "brochet", codeSandre: nil), longueurCm: 62, date: .now, lieuFlou: "94")
    let infos = InfosCarte(
        detail: CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil),
        espece: EspecePechable(espece: prise.espece, nom: "Brochet", nomLatin: "Esox lucius", image: "brochet"),
        rarete: ResultatRarete(niveau: .rare, nPeches: 9, nTotal: 29, anneeDernierReleve: 2023, echelle: .departement),
        departement: Departement(code: "94"), rangDansLaZone: 3, poids: nil, lune: .pleine, consigne: nil, sourceConsigne: nil)
    RevelationCarteView(infos: infos, photo: nil, ranger: {})
}
#endif
