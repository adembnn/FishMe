import Core
import SwiftUI

/// L'écran Prise : de la photo à la liste de contrôle. A le branche dans `RootView.swift` avec ses services, le contexte de la sortie et la fermeture `terminer`
/// (`nil` : aucune carte créée ; sinon la prise confirmée et la photo, que L4 range).
struct PriseRacineView: View {
    @State private var modele: PriseModele
    @State private var cameraOuverte = false
    @Environment(\.dismiss) private var dismiss

    init(services: PriseServices, contexte: PriseContexte, terminer: @escaping (PriseConfirmee?) -> Void) {
        _modele = State(initialValue: PriseModele(services: services, contexte: contexte, terminer: terminer))
    }

    var body: some View {
        ZStack {
            PriseJetons.fond.ignoresSafeArea()
            contenu
        }
        .tint(PriseJetons.accent)
        .fullScreenCover(isPresented: $cameraOuverte) {
            PriseCamera(onImage: { image in cameraOuverte = false; modele.photoPrise(image) },
                        onCancel: { cameraOuverte = false })
                .ignoresSafeArea()
        }
    }

    @ViewBuilder private var contenu: some View {
        switch modele.etape {
        case .photo: PriseEtapePhoto(modele: modele, ouvrirCamera: { cameraOuverte = true }, fermer: { modele.terminer(nil) })
        case .lecture: PriseEtapeLecture(modele: modele)
        case .propositions: PrisePropositionsView(modele: modele)
        case .grille(let classe): PriseGrilleView(modele: modele, classe: classe)
        case .sosies(let entree): PriseSosiesView(modele: modele, entree: entree)
        case .stade: PriseStadeView(modele: modele)
        case .taille: PriseTailleView(modele: modele)
        case .resultat: PriseResultatView(modele: modele)
        }
    }
}

/// Un en-tête commun : titre et, dessous, la consigne tant que l'espèce n'est pas confirmée.
struct PriseEntete: View {
    var titre: String
    var consigne: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titre).font(PriseJetons.titre()).foregroundStyle(PriseJetons.encre)
            if let consigne {
                Text(consigne).font(PriseJetons.corps()).foregroundStyle(PriseJetons.discret)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

struct PriseEtapePhoto: View {
    var modele: PriseModele
    var ouvrirCamera: () -> Void
    var fermer: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            PriseEntete(titre: "Nouvelle prise", consigne: PriseLogique.consigneAvantConfirmation)
            Spacer(minLength: 0)
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(PriseJetons.encre.opacity(0.7))
                .accessibilityHidden(true)
            Text("Prends ta prise en photo, avec ou sans toi dessus.")
                .font(PriseJetons.corps()).foregroundStyle(PriseJetons.encre).multilineTextAlignment(.center)
            Spacer(minLength: 0)
            if PriseCamera.disponible {
                Button("Prendre la photo", action: ouvrirCamera).buttonStyle(PriseBoutonPrincipal())
            }
            Button("Essayer avec une photo d'exemple") { modele.photoPrise(PhotoExemple.image(), exemple: true) }
                .buttonStyle(PriseBoutonSecondaire())
            #if DEBUG
            PriseSelecteurDebug { modele.photoPrise($0) }.font(PriseJetons.legende())
            #endif
            Button("Fermer", action: fermer).buttonStyle(PriseBoutonSecondaire())
        }
        .padding(20)
    }
}

struct PriseEtapeLecture: View {
    var modele: PriseModele

    var body: some View {
        VStack(spacing: 16) {
            PriseEntete(titre: "Quelle espèce ?", consigne: PriseLogique.consigneAvantConfirmation)
            if let image = modele.imagePhoto {
                Image(uiImage: image).resizable().scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: PriseJetons.rayon))
                    .accessibilityLabel("Ta photo")
            }
            ProgressView().controlSize(.large)
            Spacer(minLength: 0)
        }
        .padding(20)
    }
}
