import CloudKit
import SwiftUI
import UniformTypeIdentifiers

// PROTOTYPE R2 : NON COMPILÉ par son auteur. ⚠ à vérifier sur le Mac : les deux délégués de notification ci-dessous.

@MainActor
final class Journal: ObservableObject {
    static let partage = Journal()
    @Published var lignes: [String] = []
    private let f: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f }()
    func ecrire(_ texte: String) {
        let ligne = "\(f.string(from: Date()))  \(texte)"
        lignes.append(ligne)
        print(ligne)
    }
    var texte: String { lignes.joined(separator: "\n") }
}

/// Reçoit les notifications silencieuses de CKQuerySubscription et note le délai écriture -> réception.
@MainActor
enum Recepteur {
    static func recevoir(_ info: [AnyHashable: Any], etat: String) {
        guard let n = CKNotification(fromRemoteNotificationDictionary: info) as? CKQueryNotification else {
            Journal.partage.ecrire("notification reçue, pas de CKQueryNotification"); return
        }
        let maintenant = Date().timeIntervalSince1970
        if let ecrit = n.recordFields?["ecritA"] as? Double {
            Journal.partage.ecrire("REÇU (\(etat)) délai = \(String(format: "%.2f", maintenant - ecrit)) s  [id \(n.subscriptionID ?? "?")]")
        } else {
            Journal.partage.ecrire("REÇU (\(etat)) sans champ ecritA  [id \(n.subscriptionID ?? "?")]")
        }
    }
}

#if os(iOS)
import UIKit
final class Delegue: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIApplication.BackgroundFetchResult {
        let etat = application.applicationState == .active ? "app ouverte" : "arrière-plan"
        await Recepteur.recevoir(userInfo, etat: etat)
        return .newData
    }
}
#else
import AppKit
final class Delegue: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { NSApplication.shared.registerForRemoteNotifications() }
    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        Task { @MainActor in Recepteur.recevoir(userInfo, etat: "macOS") }
    }
}
#endif

@main
struct FishMeReseauApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(Delegue.self) var delegue
    #else
    @NSApplicationDelegateAdaptor(Delegue.self) var delegue
    #endif
    var body: some Scene { WindowGroup { Ecran() } }
}

struct Ecran: View {
    @StateObject private var journal = Journal.partage
    @State private var choisirVideo = false
    @State private var videoSource: URL?
    private let mesures = Mesures()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("R2 : mesures CloudKit (base publique)").font(.headline)
                Button("0. Vérifier iCloud") { lancer { _ in
                    let s = try await CKContainer.default().accountStatus()
                    Journal.partage.ecrire("compte iCloud : \(s == .available ? "disponible" : "INDISPONIBLE (\(s.rawValue))")")
                } }
                Button("1. Écrire 1 000 photos de 300 Ko") { lancer { j in try await mesures.ecrirePhotos(journal: j) } }
                Button(videoSource == nil ? "2a. Choisir une vidéo source (15 s ou plus)" : "2a. Vidéo choisie : \(videoSource!.lastPathComponent)") { choisirVideo = true }
                Button("2b. Exporter en 720p et écrire 100 vidéos") {
                    lancer { j in
                        guard let v = videoSource else { j("choisis d'abord une vidéo (2a)"); return }
                        let ok = v.startAccessingSecurityScopedResource(); defer { if ok { v.stopAccessingSecurityScopedResource() } }
                        try await mesures.ecrireVideos(source: v, journal: j)
                    }
                }
                Button("3a. Lire le fil de 50 (sans médias, plus les likes)") { lancer { j in try await mesures.lireFil(avecMedias: false, journal: j) } }
                Button("3b. Lire le fil de 50 (avec médias)") { lancer { j in try await mesures.lireFil(avecMedias: true, journal: j) } }
                Button("4a. Créer les 20 abonnements (sur l'APPAREIL RÉCEPTEUR)") { lancer { _ in try await mesures.creerAbonnements(); Journal.partage.ecrire("20 abonnements créés") } }
                Button("4b. Écrire 20 enregistrements, un toutes les 8 s (sur l'APPAREIL ÉCRIVAIN)") { lancer { j in try await mesures.ecrireLatence(journal: j) } }
                Button("5. Nettoyer (supprimer les enregistrements d'essai)", role: .destructive) { lancer { j in try await mesures.nettoyer(journal: j) } }
                Divider()
                ShareLink("Copier / envoyer le journal", item: journal.texte)
                Text(journal.texte).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
            }.padding()
        }
        .fileImporter(isPresented: $choisirVideo, allowedContentTypes: [.movie]) { r in
            if case .success(let u) = r { videoSource = u }
        }
    }

    private func lancer(_ travail: @escaping @Sendable (@Sendable (String) -> Void) async throws -> Void) {
        Task {
            let j: @Sendable (String) -> Void = { t in Task { @MainActor in Journal.partage.ecrire(t) } }
            do { try await travail(j) } catch { await Journal.partage.ecrire("ERREUR : \(error)") }
        }
    }
}
