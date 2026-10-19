import Core
import PDFKit
import SwiftUI
import UIKit

/// La carte en grand, pour la montrer : fond blanc, image ou PDF à la plus grande taille, zoom au pincement,
/// écran qui reste allumé tant qu'il est ouvert, luminosité inchangée. Ni « partager » ni « enregistrer dans Photos » :
/// la carte ne sort pas de l'app.
struct CartePechePleinEcranView: View {
    let genre: GenreFichierCarte
    let donnees: Data

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()

            VStack(spacing: Espace.s) {
                contenu
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(TextesCartePeche.pleinEcranMention)
                    .font(Police.legende)
                    .foregroundStyle(Color.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, Espace.s)
                    .accessibilityIdentifier("plein-ecran-mention")
            }

            BoutonRond(role: .fermer) { dismiss() }
                .padding(Espace.bord)
                .accessibilityLabel(TextesCartePeche.fermer)
                .accessibilityIdentifier("plein-ecran-fermer")
        }
        // Fond blanc fixe : les couleurs du bouton et du texte restent celles du mode clair.
        .preferredColorScheme(.light)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        .onChange(of: phase) { _, nouvelle in
            UIApplication.shared.isIdleTimerDisabled = (nouvelle == .active)
        }
        .accessibilityIdentifier("carte-plein-ecran")
    }

    @ViewBuilder
    private var contenu: some View {
        switch genre {
        case .image:
            if let image = UIImage(data: donnees) {
                ImageZoomable(image: image)
            } else {
                Text(TextesCartePeche.fichierIllisible)
                    .font(Police.corps).foregroundStyle(Color.black)
                    .padding(Espace.bord)
            }
        case .pdf:
            VisionneusePDF(donnees: donnees)
                .accessibilityLabel(TextesCartePeche.accessibiliteApercu(genre: "PDF"))
        }
    }
}

/// Une image qu'on agrandit au pincement (de 1 à 5 fois) et qu'on déplace une fois agrandie ; double toucher : retour.
private struct ImageZoomable: View {
    let image: UIImage

    @State private var echelle: CGFloat = 1
    @State private var echelleDeBase: CGFloat = 1
    @State private var decalage: CGSize = .zero
    @State private var decalageDeBase: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(echelle)
            .offset(decalage)
            .gesture(
                MagnifyGesture()
                    .onChanged { valeur in
                        echelle = min(max(echelleDeBase * valeur.magnification, 1), 5)
                    }
                    .onEnded { _ in
                        echelleDeBase = echelle
                        if echelle <= 1 { remettre() }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { valeur in
                        guard echelle > 1 else { return }
                        decalage = CGSize(width: decalageDeBase.width + valeur.translation.width,
                                          height: decalageDeBase.height + valeur.translation.height)
                    }
                    .onEnded { _ in decalageDeBase = decalage }
            )
            .onTapGesture(count: 2) { withAnimation { remettre() } }
            .accessibilityLabel("Copie de ta carte de pêche")
            .accessibilityAddTraits(.isImage)
    }

    private func remettre() {
        echelle = 1
        echelleDeBase = 1
        decalage = .zero
        decalageDeBase = .zero
    }
}

/// Le PDF entier, défilant et agrandissable (PDFKit gère le pincement).
private struct VisionneusePDF: UIViewRepresentable {
    let donnees: Data

    func makeUIView(context: Context) -> PDFView {
        let vue = PDFView()
        vue.autoScales = true
        vue.displayMode = .singlePageContinuous
        vue.displayDirection = .vertical
        vue.backgroundColor = .white
        vue.document = PDFDocument(data: donnees)
        return vue
    }

    func updateUIView(_ vue: PDFView, context: Context) {}
}
