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
        let lue = "prévision lue \(FormatConditions.jourHeure(lecture.lueLe))"

        if criteres.ventSousKmh != nil || criteres.pressionEnBaisse || criteres.niveauNormal {
            let heures = lecture.meteo.heures.sorted { $0.heure < $1.heure }
            let niveauOk = !criteres.niveauNormal || lecture.conditions.etatRiviere == .normal
            if niveauOk, let h = heures.first(where: { h in
                h.heure > maintenant && h.heure < maintenant.addingTimeInterval(horizon)
                    && (criteres.ventSousKmh.map { h.ventKmh < $0 } ?? true)
                    && (!criteres.pressionEnBaisse || baisse(heures, a: h))
            }) {
                var morceaux = ["vent \(FormatConditions.nombre(h.ventKmh)) km/h"]
                if criteres.pressionEnBaisse { morceaux.append("pression en baisse") }
                if criteres.niveauNormal { morceaux.append("rivière normale") }
                sorties.append(NotificationPrevue(
                    identifiant: "conditions-\(Int(h.heure.timeIntervalSince1970))", date: h.heure,
                    titre: "Prévu \(FormatConditions.jourHeure(h.heure)) sur ton spot",
                    corps: morceaux.joined(separator: ", ") + ", " + lue))
            }
        }
        for o in criteres.ouvertures where o.date > maintenant {
            sorties.append(NotificationPrevue(identifiant: "ouverture-\(o.espece)", date: o.date,
                                              titre: "Ouverture : \(o.espece)", corps: "C'est ouvert à partir d'aujourd'hui."))
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
    @State private var ventActif = false
    @State private var vent: Double = 15

    var body: some View {
        Form {
            Section {
                Text("FishMe te prévient sur ton spot, seulement pour ce que tu choisis.")
                    .font(JetonsConditions.police(.footnote)).foregroundStyle(JetonsConditions.encre2)
            }
            Section {
                Toggle("vent sous \(FormatConditions.nombre(vent)) km/h", isOn: $ventActif)
                if ventActif { Slider(value: $vent, in: 5...40, step: 1) }
                Toggle("pression en baisse", isOn: $modele.criteres.pressionEnBaisse)
                Toggle("rivière normale", isOn: $modele.criteres.niveauNormal)
            }
            Section {
                Toggle("vigilance sur mon spot", isOn: $modele.vigilanceActive)
                Text("dès que l'app peut vérifier").font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
            }
        }
        .font(JetonsConditions.police(.body))
        .scrollIndicators(.hidden)
        .onChange(of: ventActif) { _, _ in appliquer() }
        .onChange(of: vent) { _, _ in appliquer() }
        .onChange(of: modele.criteres) { _, _ in appliquer() }
        .onChange(of: modele.vigilanceActive) { _, _ in appliquer() }
        .accessibilityIdentifier("previens-moi")
    }

    private func appliquer() {
        modele.criteres.ventSousKmh = ventActif ? vent : nil
        Task {
            _ = await modele.assurerPermission()
            await modele.reprogrammer(avec: lecture)
        }
    }
}
