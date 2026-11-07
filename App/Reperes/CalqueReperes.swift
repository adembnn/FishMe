import Core
import MapKit
import SwiftUI

/// Les repères sur la carte. Un `MapContent` à poser dans la `Map` de `VueCarte` (accroche 1 de la fiche) : il reçoit les repères
/// et une action, rien d'autre. Jamais en grappe, jamais dans une image de partage.
/// ⚠ à compiler sur Mac : `ForEach` et `Annotation` dans un `MapContent` écrit sans compilateur.
struct CalqueReperes: MapContent {
    @Environment(\.locale) private var locale
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
                    // Épingle de 32 pt qui ne grossit pas avec le texte. Cadre de 44 pt (cible tactile) aligné en bas :
                    // le bas du cadre est la pointe de la goutte, donc l'ancre `.bottom` marque l'endroit exact.
                    IconeRepereView(type: repere.icone, taille: Self.tailleEpingle, decoratif: true)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile, alignment: .bottom)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(repere.nom), \(TextesReperes.libelle(repere.icone, locale: locale))")
            }
        }
    }

    /// Largeur de l'épingle sur la carte (pt). Fixe : elle ne suit pas la taille du texte.
    static let tailleEpingle: CGFloat = 32

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
    @Environment(\.locale) private var locale
    static let cle = "reperes.calque"
    @AppStorage(InterrupteurCalqueReperes.cle) private var allume = false

    var body: some View {
        Button { allume.toggle() } label: {
            Image(systemName: "signpost.right")
                .font(Police.taille(20, .heavy))
                .foregroundStyle(allume ? Palette.surMarine : Palette.marine)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background(allume ? Palette.marine : Palette.surface, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TextesReperes.t(TextesReperes.interrupteurCalque, locale))
        .accessibilityValue(allume ? "activé" : "désactivé")
        .accessibilityAddTraits(.isToggle)
    }
}
