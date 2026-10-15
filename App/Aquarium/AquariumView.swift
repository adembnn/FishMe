import SwiftUI

/// L'aquarium (lot L14). Point d'entrée pour A : « Voir mon aquarium » (bouton dessiné par L4) affiche cette vue en plein écran.
///
/// - `entrees` : `SelectionAquarium.entrees(...)` sur les cartes du Pescedex (jamais un lieu).
/// - `sessionsTerminees` : le nombre de sessions terminées, même bredouilles (une ration chacune, décor « étang » à 10).
/// - `decorsProOuverts` : vrai si le pêcheur peut utiliser Pro (A le lit avec `peutUtiliser` de Core, ou l'état de `Achats`).
/// - `ouvrirPaywall` : appelé quand un décor Pro est touché sans abonnement. A y ouvre le paywall de L6.
/// - `carte` : la carte de L4 (recto puis verso) pour un poisson touché ; reçoit une action pour fermer.
struct AquariumView: View {
    let entrees: [EntreeAquarium]
    let sessionsTerminees: Int
    let decorsProOuverts: Bool
    let ouvrirPaywall: () -> Void
    var carte: ((EntreeAquarium, @escaping () -> Void) -> AnyView)?
    var afficherFermer = true

    @State private var modele: ModeleAquarium
    @State private var carteOuverte: EntreeAquarium?
    @State private var decorsOuverts = false
    @State private var vue = false
    @State private var dernierToucher = CGPoint(x: 0.5, y: 0.5)
    @State private var basseConsommation = ProcessInfo.processInfo.isLowPowerModeEnabled
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @Environment(\.scenePhase) private var phase
    @Environment(\.dismiss) private var fermer
    @Environment(\.dynamicTypeSize) private var tailleTexte

    init(entrees: [EntreeAquarium], sessionsTerminees: Int, decorsProOuverts: Bool, ouvrirPaywall: @escaping () -> Void,
         carte: ((EntreeAquarium, @escaping () -> Void) -> AnyView)? = nil, afficherFermer: Bool = true,
         stockage: any StockageAquarium = StockageUserDefaults()) {
        self.entrees = entrees
        self.sessionsTerminees = sessionsTerminees
        self.decorsProOuverts = decorsProOuverts
        self.ouvrirPaywall = ouvrirPaywall
        self.carte = carte
        self.afficherFermer = afficherFermer
        _modele = State(initialValue: ModeleAquarium(stockage: stockage))
    }

    private var actif: Bool { vue && phase == .active && carteOuverte == nil }
    private var anime: Bool { !reduireAnimations }

    var body: some View {
        ZStack {
            scene
            VStack {
                barreDuHaut
                Spacer()
                if entrees.isEmpty { messageVide }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.black)
        .onAppear {
            vue = true
            synchroniser()
        }
        .onDisappear { vue = false }
        .onChange(of: actif) { _, estActif in
            if estActif { modele.reprendre(a: Date()) } else { modele.mettreEnPause(a: Date()) }
        }
        .onChange(of: entrees) { _, _ in synchroniser() }
        .onChange(of: sessionsTerminees) { _, _ in synchroniser() }
        .onChange(of: decorsProOuverts) { _, _ in synchroniser() }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            basseConsommation = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        .sheet(isPresented: $decorsOuverts) { feuilleDecors }
        .fullScreenCover(item: $carteOuverte) { entree in
            if let carte {
                carte(entree) { carteOuverte = nil }
            }
        }
    }

    private func synchroniser() {
        modele.mettreAJour(entrees: entrees, sessionsTerminees: sessionsTerminees, proOuvert: decorsProOuverts)
    }

    // MARK: Scène

    @ViewBuilder
    private var scene: some View {
        if anime {
            TimelineView(.animation(minimumInterval: basseConsommation ? 1.0 / 30.0 : nil, paused: !actif)) { contexte in
                vitre(temps: modele.temps(a: contexte.date), anime: true)
            }
        } else {
            vitre(temps: 0, anime: false)
        }
    }

    private func vitre(temps: Double, anime: Bool) -> some View {
        GeometryReader { geo in
            ZStack {
                DecorView(decor: modele.decor, temps: temps, anime: anime, ondes: modele.ondes, rations: modele.rations)
                    .contentShape(Rectangle())
                    .onTapGesture { lieu in
                        guard anime else { return }
                        modele.toucherVitre(a: CGPoint(x: lieu.x / geo.size.width, y: lieu.y / geo.size.height), temps: temps)
                    }
                    .onLongPressGesture(minimumDuration: 0.5) {
                        guard anime else { return }
                        donnerUneRation(temps: temps)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { dernierToucher = CGPoint(x: $0.location.x / geo.size.width, y: $0.location.y / geo.size.height) }
                    )
                ForEach(entrees) { entree in
                    let position = anime ? modele.position(de: entree, temps: temps) : modele.positionFixe(de: entree)
                    let largeur = Nage.largeur(longueurCm: entree.longueurCm, largeurVitre: geo.size.width)
                    Button {
                        if carte != nil { carteOuverte = entree }
                    } label: {
                        PoissonView(entree: entree, largeur: largeur, temps: temps, anime: anime, versLaDroite: position.versLaDroite)
                            .frame(minWidth: MesuresAquarium.zoneTactile, minHeight: MesuresAquarium.zoneTactile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(entree.texteVoixOff)
                    .accessibilityHint(carte != nil ? "Ouvre sa carte" : "")
                    .position(x: position.x * geo.size.width, y: position.y * geo.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func donnerUneRation(temps: Double) {
        if !modele.lancerRation(x: min(max(dernierToucher.x, 0.1), 0.9), temps: temps) {
            Task { await modele.signalerPlusDeRation() }
        }
    }

    // MARK: Barre du haut

    private var barreDuHaut: some View {
        let disposition = tailleTexte.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        return disposition {
            if afficherFermer {
                Button { fermer() } label: {
                    Image(systemName: "xmark")
                        .font(.system(.body, design: .rounded, weight: .heavy))
                        .frame(minWidth: MesuresAquarium.zoneTactile, minHeight: MesuresAquarium.zoneTactile)
                        .background(.regularMaterial, in: Circle())
                }
                .accessibilityLabel("Fermer l'aquarium")
            }
            Button { decorsOuverts = true } label: {
                Label(modele.decor.nom, systemImage: "photo.on.rectangle.angled")
                    .puce()
            }
            .accessibilityHint("Choisir le décor")
            if !(tailleTexte.isAccessibilitySize) { Spacer(minLength: 0) }
            rations
        }
        .foregroundStyle(.primary)
    }

    private var rations: some View {
        let restantes = modele.rationsRestantes
        return Button {
            guard anime else { return }
            donnerUneRation(temps: modele.temps(a: Date()))
            dernierToucher = CGPoint(x: 0.5, y: 0.5)
        } label: {
            Label(modele.plusDeRation ? "plus de ration" : "\(restantes)", systemImage: "fish.fill")
                .puce()
        }
        .disabled(!anime)
        .accessibilityLabel(restantes == 0 ? "Aucune ration" : "\(restantes) ration\(restantes > 1 ? "s" : "")")
        .accessibilityHint(restantes == 0 ? "Chaque session terminée donne une ration" : "Donne une ration aux poissons")
    }

    private var messageVide: some View {
        VStack(spacing: 8) {
            Image(systemName: "fish")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
            Text("Ta première prise nagera ici")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Décors

    private var feuilleDecors: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Decor.allCases) { decor in
                        ligneDecor(decor)
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Décors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { decorsOuverts = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func ligneDecor(_ decor: Decor) -> some View {
        let etat = modele.etat(de: decor)
        let choisi = modele.decor == decor
        return Button {
            switch modele.choisir(decor) {
            case .choisi:
                decorsOuverts = false
            case .paywall:
                decorsOuverts = false
                Task {
                    try? await Task.sleep(for: .seconds(0.4))
                    ouvrirPaywall()
                }
            case .verrouille:
                break
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: decor.icone)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(decor.nom)
                        .font(.system(.headline, design: .rounded, weight: .heavy))
                    if let ligne = sousTitre(etat) {
                        Text(ligne)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: icone(etat, choisi: choisi))
                    .font(.system(.title3, design: .rounded, weight: .heavy))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: MesuresAquarium.zoneTactile, alignment: .leading)
            .background(choisi ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(choisi ? .isSelected : [])
    }

    private func sousTitre(_ etat: EtatDecor) -> String? {
        switch etat {
        case .ouvert: return nil
        case .aGagner(let actuel, let but, let phrase): return but > 1 ? "\(phrase) : \(min(actuel, but)) sur \(but)" : phrase
        case .pro: return "Avec Pro"
        }
    }

    private func icone(_ etat: EtatDecor, choisi: Bool) -> String {
        if choisi { return "checkmark.circle.fill" }
        switch etat {
        case .ouvert: return "circle"
        case .aGagner: return "lock.fill"
        case .pro: return "sparkles"
        }
    }
}

private extension View {
    /// Pastille de la barre du haut : texte lisible sur tous les décors, qui grandit avec la taille de texte.
    func puce() -> some View {
        self.font(.system(.body, design: .rounded, weight: .heavy))
            .padding(.horizontal, 14)
            .frame(minHeight: MesuresAquarium.zoneTactile)
            .background(.regularMaterial, in: Capsule())
    }
}

/// Mesures de l'aquarium (les jetons de style de D0 remplaceront celles-ci).
enum MesuresAquarium {
    /// Hauteur minimale d'une zone touchable.
    static let zoneTactile: CGFloat = 44
}
