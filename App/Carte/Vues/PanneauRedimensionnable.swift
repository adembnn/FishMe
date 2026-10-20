import SwiftUI

/// Une feuille du bas de la carte à trois hauteurs (moyen, grand, plein écran), à nous plutôt que `.sheet` :
/// - elle a la même hauteur dès son apparition et occupe tout l'espace qu'elle utilise (plus de saut quand le contenu arrive) ;
/// - la carte réserve sa hauteur en bas (voir `DetentPanneau.reservation`), donc la mention légale de Plans reste lisible
///   au-dessus de la feuille à chaque hauteur ;
/// - la poignée se glisse, se touche (parcourt les trois hauteurs) et se règle au VoiceOver (action « ajuster »).
/// La feuille ne dessine rien d'autre que son cadre : le contenu vient de l'appelant.
struct PanneauRedimensionnable<Contenu: View>: View {
    @Binding var detent: DetentPanneau
    /// La hauteur disponible (la carte, hors barre d'onglets).
    let total: CGFloat
    /// Vrai : glisser la poignée vers le bas sous le cran moyen ferme la feuille (fiche d'un coin). Faux : elle reste au moyen.
    let fermable: Bool
    let fermer: () -> Void
    /// La barre d'onglets flotte devant le bas de la feuille : le contenu garde cette hauteur libre pour rester visible et touchable.
    let reserveBas: CGFloat
    let contenu: () -> Contenu

    /// Le glissement en cours, en points vers le bas (négatif : vers le haut). Revient à zéro quand le doigt lâche.
    @GestureState private var glissement: CGFloat = 0

    init(detent: Binding<DetentPanneau>, total: CGFloat, fermable: Bool, fermer: @escaping () -> Void, reserveBas: CGFloat = 0,
         @ViewBuilder contenu: @escaping () -> Contenu) {
        self.reserveBas = reserveBas
        _detent = detent
        self.total = total
        self.fermable = fermable
        self.fermer = fermer
        self.contenu = contenu
    }

    private var hauteurAffichee: CGFloat {
        let base = CGFloat(detent.hauteur(dans: Double(total)))
        return min(total, max(CGFloat(DetentPanneau.moyen.hauteur(dans: Double(total))) * 0.5, base - glissement))
    }

    private var arrondiDuHaut: CGFloat { detent == .pleinEcran && glissement <= 0 ? 0 : 32 }

    var body: some View {
        VStack(spacing: 0) {
            poignee
            contenu()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                // Le défilement ne déborde pas sous la barre d'onglets : il s'arrête au bas de la feuille.
                .clipped()
                .padding(.bottom, reserveBas)
        }
        .frame(height: hauteurAffichee, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: arrondiDuHaut, topTrailingRadius: arrondiDuHaut, style: .continuous)
                .fill(Palette.surface)
                .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
        .animation(.snappy(duration: 0.28), value: detent)
    }

    /// 44 pt de haut : la zone qui se glisse. Le contenu a son propre défilement, sans conflit avec ce geste.
    private var poignee: some View {
        Capsule()
            .fill(Palette.filet)
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: Gabarit.zoneTactile)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.snappy(duration: 0.28)) { detent = detent.suivantEnBoucle } }
            .gesture(glisser)
            .accessibilityElement()
            .accessibilityLabel("Hauteur de la feuille")
            .accessibilityValue(detent.libelle)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: withAnimation(.snappy(duration: 0.28)) { detent = detent.plusHaut }
                case .decrement: withAnimation(.snappy(duration: 0.28)) { detent = detent.plusBas }
                @unknown default: break
                }
            }
    }

    private var glisser: some Gesture {
        DragGesture(minimumDistance: RegleGlissement.seuilToucher)
            .updating($glissement) { valeur, etat, _ in etat = valeur.translation.height }
            .onEnded { valeur in
                let base = detent.hauteur(dans: Double(total))
                let fin = RegleGlissement.fin(hauteur: base - Double(valeur.translation.height), total: Double(total), depart: detent,
                                              vitesse: Double(valeur.velocity.height), fermable: fermable)
                withAnimation(.snappy(duration: 0.28)) {
                    switch fin {
                    case .rester(let nouveau): detent = nouveau
                    case .fermer: fermer()
                    }
                }
            }
    }
}
