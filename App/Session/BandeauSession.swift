import SwiftUI
import Core

/// « Commencer une session » : A le place sur la carte et appelle `moteur.commencer(...)` dans l'action.
struct BoutonCommencerSession: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(AnglaisF.t("Commencer une session"), systemImage: "figure.fishing")
        }
        .buttonStyle(.principal)
    }
}

/// Le bandeau de la session en cours. `ligneConditions` est l'emplacement de L12 (vide par défaut) : elle disparaît
/// aux tailles de texte d'accessibilité et ne passe jamais devant le chrono, la fin légale ni « Ajouter une prise ».
struct BandeauSession<LigneConditions: View>: View {
    let moteur: SuiviSession
    let ajouterPrise: () -> Void
    let ligneConditions: LigneConditions
    @Environment(\.dynamicTypeSize) private var tailleTexte
    @State private var explicationFin = false

    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void,
         @ViewBuilder ligneConditions: () -> LigneConditions) {
        self.moteur = moteur
        self.ajouterPrise = ajouterPrise
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
        // P14 C « Sujet » : le chrono en grand, la fin légale dessous, puis les prises et un seul bouton principal.
        VStack(spacing: Espace.m) {
            Text(Self.formater(moteur.duree(a: maintenant)))
                .font(Police.taille(64, .heavy).monospacedDigit())
                .foregroundStyle(Palette.encre)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let legale = session.finLegale {
                Button { explicationFin.toggle() } label: {
                    VStack(spacing: Espace.xs) {
                        Text(AnglaisF.f("Fin légale %@", Self.heure(legale)))
                            .font(Police.sousTitre.monospacedDigit())
                            .foregroundStyle(Palette.encreDouce)
                        if legale > maintenant {
                            Text(AnglaisF.f("encore %@", Self.reste(legale.timeIntervalSince(maintenant))))
                                .font(Police.legende)
                                .foregroundStyle(Palette.encreDouce)
                        }
                    }
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                }
                .buttonStyle(.plain)
                .accessibilityHint(AnglaisF.t("Touche pour lire d'où vient cette heure"))
            }
            if explicationFin, let legale = session.finLegale {
                Text(Self.explication(legale))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            Text(Self.textePrises(moteur.nombrePrises))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            ForEach(AvisSession.affiches(session.messages), id: \.self) { AvisSession(texte: $0) }
            if moteur.quotaAtteint {
                AvisSession(texte: AnglaisF.t("Quota du jour atteint"))
            }
            if !tailleTexte.isAccessibilitySize {
                ligneConditions
            }
            Button(action: ajouterPrise) {
                Label(AnglaisF.t("Ajouter une prise"), systemImage: "camera.fill")
            }
            .buttonStyle(.principal)
            Button(AnglaisF.t("Terminer la session"), role: .cancel) { moteur.terminer() }
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minHeight: Gabarit.zoneTactile)
        }
        .padding(Espace.l)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityElement(children: .contain)
        .onChange(of: maintenant) { _, _ in moteur.verifierFin() }
    }

    static func formater(_ secondes: TimeInterval) -> String {
        let total = Int(secondes)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    /// « 1 h 12 » ou « 12 min » (arrondi à la minute inférieure, au moins 1 min).
    static func reste(_ secondes: TimeInterval) -> String {
        let minutes = max(1, Int(secondes) / 60)
        let h = minutes / 60, m = minutes % 60
        if AnglaisF.estAnglais(AnglaisF.localeActive()) { return h > 0 ? "\(h) h \(m) min" : "\(m) min" }
        return h > 0 ? "\(h) h \(String(format: "%02d", m))" : "\(m) min"
    }

    /// Le coucher se déduit de la fin légale (coucher + 30 min − 1 min de marge, constantes de `MoteurSoleil`).
    static func explication(_ finLegale: Date) -> String {
        let decalage = (MoteurSoleil.prolongationLegaleMin - MoteurSoleil.margeDeSecuriteMin) * 60
        let coucher = finLegale.addingTimeInterval(-decalage)
        return AnglaisF.f("Coucher du soleil %@ + 30 min (article R436-13 du Code de l'environnement)", heure(coucher))
    }

    /// « 0 prise », « 1 prise », « 3 prises » (« No catches yet », « 1 catch », « 3 catches »).
    static func textePrises(_ n: Int) -> String {
        n == 0 ? AnglaisF.t("0 prise") : AnglaisF.nombre(n, un: "1 prise", autres: "%lld prises")
    }

    static func heure(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        FormatRegion(region: region).heure(date)
    }
}

extension BandeauSession where LigneConditions == EmptyView {
    init(moteur: SuiviSession, ajouterPrise: @escaping () -> Void) {
        self.init(moteur: moteur, ajouterPrise: ajouterPrise) { EmptyView() }
    }
}

struct AvisSession: View {
    let texte: String

    /// Les avis traduits dans la langue de la région. « Hors de France : aucune règle française » n'a pas de sens aux États-Unis :
    /// il n'y est pas montré (la couverture américaine est annoncée ailleurs, avec les règles de l'agence de l'État).
    nonisolated static func affiches(_ messages: [String], locale: Locale = AnglaisF.localeActive()) -> [String] {
        messages.compactMap { message in
            if message == "hors de France : aucune règle française", AnglaisF.estAnglais(locale) { return nil }
            return AnglaisF.t(message, locale)
        }
    }

    var body: some View {
        Text(texte)
            .font(Police.detail)
            .foregroundStyle(Palette.alerte)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

/// Pas de coordonnée connue : la session demande de toucher son point sur la carte (un point, jamais un département).
struct DemandePointSession: View {
    var body: some View {
        AvisSession(texte: AnglaisF.t("Touche ton point sur la carte pour commencer"))
    }
}
