import Core
import MapKit
import SwiftUI

/// Les repères sur la carte. Un `MapContent` à poser dans la `Map` de `VueCarte` (accroche 1 de la fiche) : il reçoit les repères
/// et une action, rien d'autre. Jamais en grappe, jamais dans une image de partage.
/// ⚠ à compiler sur Mac : `ForEach` et `Annotation` dans un `MapContent` écrit sans compilateur.
struct CalqueReperes: MapContent {
    let reperes: [Repere]
    /// Le nom s'écrit au-dessus de l'icône seulement quand la carte est assez zoomée (`CalqueReperes.afficheLesNoms`).
    var afficherNoms = false
    let ouvrir: (Repere) -> Void

    var body: some MapContent {
        ForEach(reperes) { repere in
            Annotation(afficherNoms ? repere.nom : "", coordinate: CLLocationCoordinate2D(latitude: repere.position.latitude,
                                                                                         longitude: repere.position.longitude),
                       anchor: .bottom) {
                Button { ouvrir(repere) } label: {
                    Image(systemName: TextesReperes.symbole(repere.icone))
                        .font(Police.taille(26, .heavy))
                        .foregroundStyle(Palette.surMarine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(repere.icone == .danger ? Palette.alerte : Palette.marine, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(repere.nom), \(TextesReperes.libelle(repere.icone))")
            }
        }
    }

    /// Au-delà de ce que montre un département (environ 2,5 degrés de latitude), les repères sont cachés (accroche 1d).
    static let spanMaxVisible: Double = 2.5
    /// Les noms s'écrivent sous cette hauteur de carte (en degrés de latitude).
    static let spanNoms: Double = 0.08

    static func visible(spanLatitude: Double) -> Bool { spanLatitude <= spanMaxVisible }
    static func afficheLesNoms(spanLatitude: Double) -> Bool { spanLatitude <= spanNoms }
}

/// L'interrupteur « Mes repères » de la colonne de droite de la carte. Éteint au premier lancement.
/// Éteint, la carte n'affiche aucun repère et ne lit aucune photo.
struct InterrupteurCalqueReperes: View {
    static let cle = "reperes.calque"
    @AppStorage(InterrupteurCalqueReperes.cle) private var allume = false

    var body: some View {
        Button { allume.toggle() } label: {
            Image(systemName: "mappin.and.ellipse")
                .font(Police.taille(20, .heavy))
                .foregroundStyle(allume ? Palette.surMarine : Palette.marine)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background(allume ? Palette.marine : Palette.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TextesReperes.interrupteurCalque)
        .accessibilityValue(allume ? "activé" : "désactivé")
        .accessibilityAddTraits(.isToggle)
    }
}
