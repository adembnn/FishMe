import Core
import SwiftUI

/// E1 / P01 (direction C) : la seule question du premier lancement. Icône et nom FishMe, « Tu pêches depuis… »,
/// trois pastilles rondes avec pictogramme (celle qui est touchée se remplit en marine), « Continuer ».
struct QuestionNiveauView: View {
    let choisir: (NiveauPecheur) -> Void
    let passer: () -> Void

    @State private var selection: NiveauPecheur? = NiveauPecheur.parDefaut

    var body: some View {
        // Maquette P01-C (390 × 844, plein écran) : icône de 168 pt à 120 pt du haut (soit 61 pt sous la barre d'état),
        // « FishMe » dessous, « Tu pêches depuis… » à 470 pt, les pastilles 28 pt plus bas, « Continuer » à 40 pt du bas.
        VStack(spacing: 0) {
            VStack(spacing: Espace.l) {
                IconeFishMe(cote: 168)
                Text("FishMe")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
            }
            .padding(.top, 61)
            Text("Tu pêches depuis…")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .padding(.top, 125)
            HStack(alignment: .top, spacing: Espace.s) {
                ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { niveau in
                    pastille(niveau)
                }
            }
            .padding(.top, 28)
            Spacer(minLength: Espace.l)
            // Pas de « Passer » dans la maquette : la feuille ne se ferme que par « Continuer » (niveau par défaut pré-choisi).
            Button("Continuer") {
                if let selection { choisir(selection) }
            }
            .buttonStyle(.principal)
            .padding(.bottom, 6)
        }
        .padding(.horizontal, Espace.bord)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityIdentifier("question-niveau")
    }

    private func phrase(_ niveau: NiveauPecheur) -> String {
        switch niveau {
        case .debutant: "Je débute"
        case .occasionnel: "Quelques sorties"
        case .confirme: "Depuis longtemps"
        }
    }

    private func pastille(_ niveau: NiveauPecheur) -> some View {
        let choisie = selection == niveau
        return Button { selection = niveau } label: {
            VStack(spacing: Espace.m) {
                PictoNiveau(niveau: niveau)
                    .foregroundStyle(choisie ? Palette.surMarine : Palette.marine)
                    .frame(width: 76, height: 76)
                    .background(choisie ? Palette.marine : Palette.tuile, in: Circle())
                Text(phrase(niveau))
                    .font(Police.taille(15, .bold))
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(phrase(niveau))
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }
}

/// Les trois pictogrammes de la maquette P01-C (bouchon, canne, moulinet), tracés dans une boîte de 24 × 24 puis agrandis
/// à 36 pt, trait de 2, extrémités rondes. Ils prennent la couleur de premier plan.
struct PictoNiveau: View {
    let niveau: NiveauPecheur

    var body: some View {
        Canvas { contexte, taille in
            let echelle = taille.width / 24
            let trait = StrokeStyle(lineWidth: 2 * echelle, lineCap: .round, lineJoin: .round)
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * echelle, y: y * echelle) }
            var chemins: [Path] = []
            switch niveau {
            case .debutant:
                var tige = Path()
                tige.move(to: point(12, 2.5)); tige.addLine(to: point(12, 7.5))
                tige.move(to: point(9, 7.5)); tige.addLine(to: point(15, 7.5))
                tige.addLine(to: point(13.8, 15))
                tige.addQuadCurve(to: point(10.2, 15), control: point(12, 16.31))
                tige.closeSubpath()
                var vague = Path()
                vague.move(to: point(3, 20))
                vague.addCurve(to: point(11, 20), control1: point(5.7, 18.2), control2: point(8.3, 18.2))
                vague.addCurve(to: point(19, 20), control1: point(13.7, 21.8), control2: point(16.3, 21.8))
                vague.addCurve(to: point(21, 18.7), control1: point(21.7, 18.2), control2: point(21, 18.7))
                chemins = [tige, vague]
            case .occasionnel:
                var canne = Path()
                canne.move(to: point(3.5, 20.5)); canne.addLine(to: point(17, 5))
                var fil = Path()
                fil.move(to: point(17, 5))
                fil.addCurve(to: point(21, 8.2), control1: point(19.4, 4.6), control2: point(21, 5.8))
                fil.addLine(to: point(21, 14))
                let hamecon = Path(ellipseIn: CGRect(x: 19.4 * echelle, y: 15.4 * echelle, width: 3.2 * echelle, height: 3.2 * echelle))
                chemins = [canne, fil, hamecon]
            case .confirme:
                let corps = Path(ellipseIn: CGRect(x: 3.5 * echelle, y: 5.5 * echelle, width: 15 * echelle, height: 15 * echelle))
                let axe = Path(ellipseIn: CGRect(x: 8.6 * echelle, y: 10.6 * echelle, width: 4.8 * echelle, height: 4.8 * echelle))
                var manivelle = Path()
                manivelle.move(to: point(11, 5.5)); manivelle.addLine(to: point(11, 10.6))
                manivelle.move(to: point(18.5, 13)); manivelle.addLine(to: point(13.4, 13))
                manivelle.move(to: point(18, 5)); manivelle.addLine(to: point(21, 2.5))
                chemins = [corps, axe, manivelle]
            }
            for chemin in chemins {
                contexte.stroke(chemin, with: .foreground, style: trait)
            }
        }
        .frame(width: 36, height: 36)
        .accessibilityHidden(true)
    }
}

/// Le demi-écran : au premier lancement seulement, jamais bloquant (la carte reste utilisable derrière).
/// `declenchee` : A le passe à vrai quand la demande de position est passée (ordre fixé dans `RootView.swift`).
struct QuestionNiveauModifier: ViewModifier {
    let declenchee: Bool
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue
    @AppStorage(ClesConseils.questionVue) private var questionVue = false
    @State private var ouverte = false

    func body(content: Content) -> some View {
        content
            .onAppear(perform: ouvrirSiBesoin)
            .onChange(of: declenchee) { ouvrirSiBesoin() }
            .fullScreenCover(isPresented: $ouverte, onDismiss: { questionVue = true }) {
                QuestionNiveauView(
                    choisir: { niveau in
                        niveauBrut = niveau.rawValue
                        ouverte = false
                    },
                    passer: {
                        niveauBrut = NiveauPecheur.parDefaut.rawValue
                        ouverte = false
                    }
                )
                .interactiveDismissDisabled()
            }
    }

    private func ouvrirSiBesoin() {
        if declenchee && !questionVue { ouverte = true }
    }
}

extension View {
    /// `.questionNiveau(declenchee: positionDemandee)` sur la carte, dans `RootView.swift`.
    func questionNiveau(declenchee: Bool) -> some View {
        modifier(QuestionNiveauModifier(declenchee: declenchee))
    }
}
