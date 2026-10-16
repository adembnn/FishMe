import SwiftUI
import UIKit
import ImageIO
import WidgetKit

// Cible widget seulement. Le widget « Ma carte » : une seule carte du Pescedex sur l'écran d'accueil, recto et verso.
// Demande d'Adem (16 oct.) : « juste la carte », donc AUCUN texte ni chiffre dessus (ni nom, ni taille, ni date, ni lieu).
// Un toucher retourne la carte (RetournerCarteIntent). Aucune coordonnée : l'écran d'accueil est vu par d'autres.
// La carte est verticale : petit et grand seulement, pas de moyen.

/// Une image du widget : la carte choisie, la face montrée, la photo du verso déjà chargée.
/// `UIImage` n'est pas toujours `Sendable` : l'entrée n'est jamais modifiée après sa création.
nonisolated struct EntreeCarte: TimelineEntry, @unchecked Sendable {
    let date: Date
    let carte: InstantaneCartes.Carte?
    let verso: Bool
    let photo: UIImage?
}

nonisolated struct FournisseurCarte: AppIntentTimelineProvider {
    typealias Intent = ChoixCarteIntent
    typealias Entry = EntreeCarte

    /// Rendu flouté du système : aucune carte, donc l'emplacement vide.
    func placeholder(in context: Context) -> EntreeCarte {
        EntreeCarte(date: .now, carte: nil, verso: false, photo: nil)
    }

    func snapshot(for configuration: ChoixCarteIntent, in context: Context) async -> EntreeCarte {
        Self.entree(pour: configuration)
    }

    func timeline(for configuration: ChoixCarteIntent, in context: Context) async -> Timeline<EntreeCarte> {
        // Une seule entrée : rien ne change tout seul. L'app (publier) et le bouton recharge la timeline.
        Timeline(entries: [Self.entree(pour: configuration)], policy: .never)
    }

    static func entree(pour configuration: ChoixCarteIntent) -> EntreeCarte {
        let instantane = DepotCartesWidget.lire()
        // Carte choisie ; si elle a été supprimée ou si rien n'est choisi : la plus rare, puis la plus récente.
        let carte = configuration.carte.flatMap { instantane.carte(id: $0.id) } ?? instantane.laPlusRare
        guard let carte else {
            return EntreeCarte(date: .now, carte: nil, verso: false, photo: nil)
        }
        let verso = instantane.verso(id: carte.id)
        // La photo ne se charge que si le verso est montré : la mémoire des widgets est limitée.
        let photo = (verso && carte.aPhoto) ? chargerPhoto(id: carte.id) : nil
        return EntreeCarte(date: .now, carte: carte, verso: verso, photo: photo)
    }

    /// Décode la photo réduite (au plus 700 px) directement depuis le fichier, sans charger l'image entière.
    static func chargerPhoto(id: String, cotePlusGrand: Int = 700) -> UIImage? {
        guard let url = DepotCartesWidget.urlPhoto(id: id),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: cotePlusGrand,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

struct CarteWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: DepotCartesWidget.genre, intent: ChoixCarteIntent.self, provider: FournisseurCarte()) { entree in
            VueCarteWidgetRacine(entree: entree)
        }
        .configurationDisplayName("Ma carte")
        .description("Une carte de ton Pescedex.")
        // La carte est verticale : pas de format moyen.
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}

/// Lit la famille une seule fois, ici, et la passe à la vue : les sous-vues ne lisent jamais l'environnement.
private struct VueCarteWidgetRacine: View {
    @Environment(\.widgetFamily) private var famille
    let entree: EntreeCarte

    var body: some View {
        VueCarteWidget(entree: entree, famille: famille)
    }
}

#if DEBUG
extension EntreeCarte {
    /// Pour rendre des PNG hors widget (tests de rendu). Photo absente : au verso, on voit le dos de carte.
    static func exempleRendu(verso: Bool, rarete: Int) -> EntreeCarte {
        EntreeCarte(
            date: .now,
            carte: InstantaneCartes.Carte(id: "exemple", slug: "brochet", rarete: rarete, nom: "Brochet", aPhoto: false),
            verso: verso,
            photo: nil
        )
    }
}

#Preview(as: .systemSmall) {
    CarteWidget()
} timeline: {
    EntreeCarte.exempleRendu(verso: false, rarete: 3)
    EntreeCarte.exempleRendu(verso: true, rarete: 3)
}

#Preview(as: .systemLarge) {
    CarteWidget()
} timeline: {
    EntreeCarte.exempleRendu(verso: false, rarete: 2)
}
#endif
