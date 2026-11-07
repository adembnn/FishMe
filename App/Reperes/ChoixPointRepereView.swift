import Core
import MapKit
import SwiftUI

/// Mini-carte propre aux repères : un toucher pose le point, « Poser ici » le valide. Sert quand la position courante manque
/// (permission refusée) ou quand le pêcheur veut poser un repère ailleurs que là où il est.
struct ChoixPointRepereView: View {
    @Environment(\.locale) private var locale
    let choisir: (Coordonnee) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5), span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13)))
    @State private var pose: CLLocationCoordinate2D?

    var body: some View {
        ZStack(alignment: .topLeading) {
            MapReader { proxy in
                Map(position: $camera) {
                    if let pose {
                        Annotation(TextesReperes.t(TextesReperes.poserCePoint, locale), coordinate: pose, anchor: .bottom) {
                            Image(systemName: "mappin.circle.fill")
                                .font(Police.taille(34, .heavy))
                                .foregroundStyle(Palette.marine)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                .onTapGesture { point in
                    if let c = proxy.convert(point, from: .local) { pose = c }
                }
            }
            .ignoresSafeArea()

            BoutonRond(role: .retour) { dismiss() }
                .padding(Espace.bord)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Espace.s) {
                Text(TextesReperes.t(TextesReperes.choisirPointTitre, locale)).font(Police.detail).foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                Button {
                    if let pose { choisir(Coordonnee(latitude: pose.latitude, longitude: pose.longitude)) }
                } label: {
                    Text(TextesReperes.t(TextesReperes.poserCePoint, locale)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.principal)
                .disabled(pose == nil)
            }
            .padding(Espace.bord)
            .background(.regularMaterial)
        }
    }
}
