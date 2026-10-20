import Core
import SwiftUI

/// Les services de Core dont la collection a besoin, passés par A dans RootView.swift. Rien n'est calculé ici.
nonisolated struct ServicesCollection: Sendable {
    var especes: any ServiceEspeces
    var soleil: any ServiceSoleil
    var regles: any ServiceRegles

    init(especes: any ServiceEspeces, soleil: any ServiceSoleil, regles: any ServiceRegles) {
        self.especes = especes
        self.soleil = soleil
        self.regles = regles
    }
}

/// Emplacements de vues d'autres lots (L12, L13). Vides par défaut : A y branche leurs vues dans RootView.swift.
struct EmplacementsExternes {
    /// « comment la pêcher » (L13), au dos de chaque espèce, prise ou non.
    var commentLaPecher: ((Espece) -> AnyView)?
    /// « tes conditions » (L12), ouvert depuis le Pescedex.
    var tesConditions: (() -> AnyView)?
    /// Bloc météo du dos d'une carte (L12), à partir de l'instantané gardé avec la carte.
    var meteoDuDos: ((Conditions) -> AnyView)?
    /// « Publier » sur une carte (L23) : la feuille de publication, avec la prise, sa rareté et sa photo (sans GPS). `nil` : pas de bouton.
    var publierCarte: ((Prise, NiveauRarete, Data) -> AnyView)?

    init(commentLaPecher: ((Espece) -> AnyView)? = nil, tesConditions: (() -> AnyView)? = nil,
         meteoDuDos: ((Conditions) -> AnyView)? = nil, publierCarte: ((Prise, NiveauRarete, Data) -> AnyView)? = nil) {
        self.publierCarte = publierCarte
        self.commentLaPecher = commentLaPecher
        self.tesConditions = tesConditions
        self.meteoDuDos = meteoDuDos
    }

    static var vides: EmplacementsExternes { EmplacementsExternes() }
}
