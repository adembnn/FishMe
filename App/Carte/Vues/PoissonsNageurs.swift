import MapKit
import SwiftUI
import Core

/// De petits poissons de profil nagent sur les stations où `Core` donne une espèce rare ou légendaire.
/// 20 stations au plus, 3 poissons chacune, une seule `TimelineView` pour tous, arrêtée pendant qu'on fait glisser la carte
/// et immobile avec « Réduire les animations ». Aucun texte : toucher la station ouvre sa fiche.
struct PoissonsNageurs: View {
    let animees: [StationAnimee]
    let proxy: MapProxy
    let enMouvement: Bool
    /// Fait relire les positions quand la carte s'arrête.
    let region: ZoneCarte

    @Environment(\.accessibilityReduceMotion) private var reduireLesAnimations

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: enMouvement || reduireLesAnimations)) { contexte in
            let t = reduireLesAnimations ? 0 : contexte.date.timeIntervalSinceReferenceDate
            ZStack {
                ForEach(animees) { station in
                    if let point = proxy.convert(CLLocationCoordinate2D(latitude: station.station.coordonnee.latitude,
                                                                        longitude: station.station.coordonnee.longitude), to: .local) {
                        ForEach(0..<StationAnimee.poissonsParStation, id: \.self) { i in
                            poisson(station: station, indice: i, point: point, t: t)
                        }
                    }
                }
            }
        }
        .opacity(enMouvement ? 0 : 1)
        .animation(.easeInOut(duration: 0.2), value: enMouvement)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func poisson(station: StationAnimee, indice: Int, point: CGPoint, t: Double) -> some View {
        let images = station.images
        let image = images.isEmpty ? nil : images[indice % images.count]
        let graine = Double(station.id.unicodeScalars.reduce(0) { ($0 &+ Int($1.value)) % 997 }) + Double(indice) * 2.1
        let vitesse = 0.35 + 0.1 * Double(indice)
        let angle = t * vitesse + graine
        let dx = cos(angle) * 22
        let dy = sin(angle * 1.3) * 7 + Double(indice - 1) * 9
        let versLaDroite = -sin(angle) * vitesse > 0
        return ImageEspece(nom: image)
            .frame(width: 26, height: 14)
            .scaleEffect(x: versLaDroite ? -1 : 1, y: 1)
            .position(x: point.x + dx, y: point.y + dy - 18)
    }
}
