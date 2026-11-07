import Combine
import SwiftUI
import UserNotifications
import Core

/// Les conditions que le pêcheur choisit sur son spot.
nonisolated struct CriteresPreviensMoi: Sendable, Equatable, Codable {
    var ventSousKmh: Double?
    var pressionEnBaisse = false
    var niveauNormal = false
    var ouvertures: [OuvertureChoisie] = []

    var estVide: Bool { ventSousKmh == nil && !pressionEnBaisse && !niveauNormal && ouvertures.isEmpty }
}

/// L'ouverture d'une espèce, à la date tirée des règles (fournie par A).
nonisolated struct OuvertureChoisie: Sendable, Equatable, Codable {
    var espece: String
    var date: Date
}

nonisolated struct NotificationPrevue: Sendable, Equatable {
    var identifiant: String
    var date: Date
    var titre: String
    var corps: String
}

/// Programme les notifications locales à partir de la dernière prévision. Pur : l'horloge est injectée.
nonisolated enum PlanificateurPreviensMoi {
    static let horizon: TimeInterval = 72 * 3600

    static func planifier(criteres: CriteresPreviensMoi, lecture: LectureConditions, maintenant: Date) -> [NotificationPrevue] {
        var sorties: [NotificationPrevue] = []
        let lue = AnglaisF.f("prévision lue %@", FormatConditions.jourHeure(lecture.lueLe))

        if criteres.ventSousKmh != nil || criteres.pressionEnBaisse || criteres.niveauNormal {
            let heures = lecture.meteo.heures.sorted { $0.heure < $1.heure }
            let niveauOk = !criteres.niveauNormal || lecture.conditions.etatRiviere == .normal
            if niveauOk, let h = heures.first(where: { h in
                h.heure > maintenant && h.heure < maintenant.addingTimeInterval(horizon)
                    && (criteres.ventSousKmh.map { h.ventKmh < $0 } ?? true)
                    && (!criteres.pressionEnBaisse || baisse(heures, a: h))
            }) {
                var morceaux = [AnglaisF.f("vent %@", FormatConditions.vent(kmh: h.ventKmh))]
                if criteres.pressionEnBaisse { morceaux.append(AnglaisF.t("pression en baisse")) }
                if criteres.niveauNormal { morceaux.append(AnglaisF.t("rivière normale")) }
                sorties.append(NotificationPrevue(
                    identifiant: "conditions-\(Int(h.heure.timeIntervalSince1970))", date: h.heure,
                    titre: AnglaisF.f("Prévu %@ sur ton spot", FormatConditions.jourHeure(h.heure)),
                    corps: morceaux.joined(separator: ", ") + ", " + lue))
            }
        }
        for o in criteres.ouvertures where o.date > maintenant {
            sorties.append(NotificationPrevue(identifiant: "ouverture-\(o.espece)", date: o.date,
                                              titre: AnglaisF.f("Ouverture : %@", o.espece), corps: AnglaisF.t("C'est ouvert à partir d'aujourd'hui.")))
        }
        return sorties
    }

    /// Pression plus basse 3 h avant : une comparaison de deux valeurs prévues, pas un état calculé.
    private static func baisse(_ heures: [PointMeteo], a h: PointMeteo) -> Bool {
        guard let avant = heures.last(where: { $0.heure <= h.heure.addingTimeInterval(-3 * 3600) }) else { return false }
        return h.pressionHPa < avant.pressionHPa
    }
}

nonisolated protocol Notifieur: Sendable {
    /// Demande la permission d'iOS. Jamais appelée au lancement.
    func demanderPermission() async -> Bool
    func remplacer(_ notifications: [NotificationPrevue]) async
}

nonisolated struct NotifieurSysteme: Notifieur {
    init() {}

    func demanderPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func remplacer(_ notifications: [NotificationPrevue]) async {
        let centre = UNUserNotificationCenter.current()
        let en_attente = await centre.pendingNotificationRequests().map(\.identifier)
            .filter { $0.hasPrefix("conditions-") || $0.hasPrefix("ouverture-") }
        centre.removePendingNotificationRequests(withIdentifiers: en_attente)
        for n in notifications {
            let contenu = UNMutableNotificationContent()
            contenu.title = n.titre
            contenu.body = n.corps
            let composantes = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: n.date)
            let declencheur = UNCalendarNotificationTrigger(dateMatching: composantes, repeats: false)
            try? await centre.add(UNNotificationRequest(identifier: n.identifiant, content: contenu, trigger: declencheur))
        }
    }
}

/// Chargé de « préviens-moi » : la permission se demande au premier toucher, après une ligne de chez nous.
@MainActor
final class PreviensMoiModele: ObservableObject {
    @Published var criteres = CriteresPreviensMoi()
    @Published var vigilanceActive = false
    @Published var crueActive = false
    @Published private(set) var permissionDemandee = false
    @Published private(set) var permissionAccordee = false

    private let notifieur: any Notifieur
    private let maintenant: @Sendable () -> Date

    init(notifieur: any Notifieur, maintenant: @escaping @Sendable () -> Date = { Date() }) {
        self.notifieur = notifieur
        self.maintenant = maintenant
    }

    /// À appeler au premier toucher sur « préviens-moi » ou sur l'interrupteur de vigilance.
    func assurerPermission() async -> Bool {
        if !permissionDemandee {
            permissionDemandee = true
            permissionAccordee = await notifieur.demanderPermission()
        }
        return permissionAccordee
    }

    func reprogrammer(avec lecture: LectureConditions?) async {
        guard permissionAccordee, let lecture else { return }
        await notifieur.remplacer(PlanificateurPreviensMoi.planifier(criteres: criteres, lecture: lecture, maintenant: maintenant()))
    }
}

struct PreviensMoiView: View {
    @ObservedObject var modele: PreviensMoiModele
    let lecture: LectureConditions?

    /// Nom réel de la station hydrométrique si la lecture en a une.
    private var legendeCrue: String {
        if let nom = lecture?.eau?.station.nom, !nom.isEmpty { return AnglaisF.f("Niveau : %@", nom) }
        return AnglaisF.t("Niveau de ta rivière")
    }

    // Maquette P39-notifs-B : titre, une ligne de texte, un groupe de deux lignes (Orage, Crue), un bouton en bas.
    // Les réglages fins (vent, pression, rivière normale) restent dans `CriteresPreviensMoi` et le planificateur,
    // mais la maquette n'a pas d'écran pour eux : ils ne sont plus affichés ici.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(AnglaisF.t("Alertes"))
                    .font(Police.taille(34, .black)).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Text(AnglaisF.t("FishMe te prévient avant que ça tourne mal."))
                    .font(Police.detail).foregroundStyle(Palette.encreDouce)
                    .padding(.top, 8)
                VStack(spacing: 0) {
                    ligne(icone: "bolt.fill", titre: AnglaisF.t("Orage"), legende: AnglaisF.t("Vigilance Météo-France sur ton spot"), actif: $modele.vigilanceActive)
                    Rectangle().fill(Palette.filet).frame(height: 0.5).padding(.leading, Espace.l)
                    ligne(icone: "water.waves", titre: AnglaisF.t("Crue"), legende: legendeCrue, actif: $modele.crueActive)
                }
                .tuileFishMe()
                .padding(.top, 24)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(AnglaisF.t("Préviens-moi")) {
                Task {
                    _ = await modele.assurerPermission()
                    await modele.reprogrammer(avec: lecture)
                }
            }
            .buttonStyle(.principal)
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.s)
        }
        .onChange(of: modele.criteres) { _, _ in appliquer() }
        .presentationDetents([.large])
        .accessibilityIdentifier("previens-moi")
    }

    private func ligne(icone: String, titre: String, legende: String, actif: Binding<Bool>) -> some View {
        HStack(spacing: Espace.m) {
            Image(systemName: icone)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.alerte)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(titre).font(Police.corps).foregroundStyle(Palette.encre)
                Text(legende).font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
            Spacer(minLength: Espace.s)
            Toggle(titre, isOn: actif).labelsHidden().tint(Palette.marine)
        }
        .padding(.horizontal, Espace.l).padding(.vertical, Espace.s)
        .frame(minHeight: 72)
    }

    /// Reprogramme avec la permission déjà donnée ; ne la demande jamais (c'est le bouton qui s'en charge).
    private func appliquer() {
        Task { await modele.reprogrammer(avec: lecture) }
    }
}
