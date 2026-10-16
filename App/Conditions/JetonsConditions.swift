import SwiftUI

// Les jetons de ce dossier pointent vers App/Style/Style.swift (Palette, Police).
enum JetonsConditions {
    static func police(_ style: Font.TextStyle) -> Font {
        switch style {
        case .largeTitle: return Police.grandTitre
        case .title, .title2, .title3: return Police.titre
        case .headline: return Police.sousTitre
        case .body: return Police.corps
        case .subheadline: return Police.detail
        default: return Police.legende
        }
    }

    static var encre: Color { Palette.encre }
    static var encre2: Color { Palette.encreDouce }
    static var filet: Color { Palette.filet }
    static var accent: Color { Palette.marine }
    /// Orange : alertes seulement (orage, crue).
    static var haut: Color { Palette.alerte }
    static var crue: Color { Palette.alerte }
}
