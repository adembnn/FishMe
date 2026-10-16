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
        // Chrono façon Horloge d'Apple : l'anneau au centre vertical, Prise et Terminer en boutons ronds dessous,
        // les infos (prises, quota, avis, conditions) en cartes discrètes. Le tout défile si le texte est très agrandi.
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: Espace.l) {
                    enTete(session)
                    Spacer(minLength: Espace.s)
                    ChronoAnneauView(temps: Self.temps(moteur.duree(a: maintenant)),
                                     progression: progression(session, maintenant: maintenant),
                                     diametre: diametreAnneau(geo.size)) {
                        sousTitreFin(session, maintenant: maintenant)
                    }
                    .accessibilityLabel("Durée de la session")
                    .accessibilityValue(Self.temps(moteur.duree(a: maintenant)))
                    boutons
                    Spacer(minLength: Espace.s)
                    cartes(session)
                }
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.xl)
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(
            LinearGradient(colors: [Palette.fond, Palette.marineDoux.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .accessibilityElement(children: .contain)
        .simultaneousGesture(gesteReduire)
        .confirmationDialog("Terminer la session ?", isPresented: $confirmationFin, titleVisibility: .visible) {
            Button("Terminer la session", role: .destructive) { moteur.terminer() }
            Button("Continuer à pêcher", role: .cancel) {}
        }
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    /// L'anneau tient dans la largeur et dans une part de la hauteur (le reste va aux boutons et aux cartes).
    private func diametreAnneau(_ taille: CGSize) -> CGFloat {
        let parLargeur = taille.width - 2 * Espace.bord - Espace.xl
        let parHauteur = taille.height * (tailleTexte.isAccessibilitySize ? 0.5 : 0.44)
        return max(180, min(parLargeur, parHauteur, 340))
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

    /// « Fin légale à 20:41 » et « dans 2 h 15 » ; touche pour lire d'où vient l'heure.
    @ViewBuilder
    private func sousTitreFin(_ session: SessionEnCours, maintenant: Date) -> some View {
        if let legale = session.finLegale {
            Button { explicationFin.toggle() } label: {
                VStack(spacing: 2) {
                    Text("Fin légale à \(BandeauSession<EmptyView>.heure(legale))")
                        .font(Police.detail.monospacedDigit())
                    if legale > maintenant {
                        Text("dans \(BandeauSession<EmptyView>.reste(legale.timeIntervalSince(maintenant)))")
                            .font(Police.legende)
                    }
                }
                .foregroundStyle(Palette.encreDouce)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(minHeight: Gabarit.zoneTactile)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Touche pour lire d'où vient cette heure")
        }
    }

    private var boutons: some View {
        HStack(spacing: Espace.xxl) {
            BoutonRondHorloge(titre: "Prise", icone: "camera.fill", couleur: Palette.ouvert, action: ajouterPrise)
            BoutonRondHorloge(titre: "Terminer", icone: "stop.fill", couleur: .red) { confirmationFin = true }
        }
        .frame(maxWidth: .infinity)
    }

    /// Les infos de la session, sous l'anneau : prises, quota, explication de la fin légale.
    private func cartes(_ session: SessionEnCours) -> some View {
        VStack(spacing: Espace.s) {
            dernierePrise(session)
            if let ligneQuota { carte(ligneQuota, icone: "fish") }
            if explicationFin, let legale = session.finLegale {
                carte(BandeauSession<EmptyView>.explication(legale), icone: "sunset")
            }
        }
        .frame(maxWidth: 460)
    }

    private var ligneQuota: String? {
        let q = moteur.quotaDuJour()
        guard let plafond = q.plafond else { return nil }
        return "Quota du jour : \(q.gardees) sur \(plafond)"
    }

    private func carte(_ texte: String, icone: String) -> some View {
        HStack(spacing: Espace.m) {
            Image(systemName: icone).foregroundStyle(Palette.marine).accessibilityHidden(true)
            Text(texte)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Espace.m)
        .tuileFishMe()
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

    /// La carte des prises : vignette de la dernière espèce, « 1 prise · 68 cm ». Aucune prise : « 0 prise ».
    private func dernierePrise(_ session: SessionEnCours) -> some View {
        let prises = FormatSortie.prises(session.sortie)
        let derniere = prises.last
        let infos = derniere.flatMap { infosEspece($0.espece) }
        return HStack(spacing: Espace.m) {
            Group {
                if let infos {
                    Image(infos.image).resizable().scaledToFit()
                } else {
                    Image(systemName: "fish.fill").resizable().scaledToFit()
                        .foregroundStyle(derniere == nil ? Palette.silhouette : Palette.marine)
                }
            }
            .frame(width: 64, height: 32)
            .accessibilityHidden(true)
            Text(legendePrises(prises, derniere))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Espace.m)
        .tuileFishMe()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(infos.map { "\($0.nom), " + legendePrises(prises, derniere) } ?? legendePrises(prises, derniere))
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
