import AVFoundation
import Core
import SwiftUI
import UIKit

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
            Palette.fond.ignoresSafeArea()
            contenu
        }
        .tint(Palette.marine)
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
        case .details: PriseDetailsView(modele: modele)
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
            Text(titre).font(Police.titre).foregroundStyle(Palette.encre)
            if let consigne {
                Text(consigne).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

/// P38 puis P18 : tant que l'accès à l'appareil photo n'est pas donné, une explication courte (« la photo reste sur ton iPhone, sans GPS ») ;
/// une fois donné, le cadre de prise de vue sombre avec le déclencheur. La photo n'a pas de GPS et ne quitte pas l'iPhone.
struct PriseEtapePhoto: View {
    var modele: PriseModele
    var ouvrirCamera: () -> Void
    var fermer: () -> Void

    @State private var acces = AVCaptureDevice.authorizationStatus(for: .video)
    @Environment(\.openURL) private var ouvrirURL

    var body: some View {
        Group {
            if acces == .authorized && PriseCamera.disponible { cadre } else { permission }
        }
        .onAppear { acces = AVCaptureDevice.authorizationStatus(for: .video) }
    }

    // MARK: P38 : accès à l'appareil photo

    private var permission: some View {
        VStack(spacing: Espace.l) {
            HStack {
                PriseBoutonRond(symbole: "xmark", etiquette: "Fermer", action: fermer)
                Spacer()
            }
            Spacer(minLength: 0)
            Image(systemName: "camera")
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            Spacer(minLength: 0)
            Text("Photographier ta prise")
                .font(Police.grandTitre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("La photo reste sur ton iPhone, sans GPS.")
                .font(Police.corps).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
            Spacer(minLength: 0)
            if PriseCamera.disponible {
                if acces == .denied || acces == .restricted {
                    Button("Ouvrir les réglages") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { ouvrirURL(url) }
                    }
                    .buttonStyle(.principal)
                } else {
                    Button("Continuer") { demanderEtOuvrir() }.buttonStyle(.principal)
                }
            }
            Button("Essayer avec une photo d'exemple") { modele.photoPrise(PhotoExemple.image(), exemple: true) }
                .font(Police.corps).foregroundStyle(Palette.marine)
                .frame(minHeight: Gabarit.zoneTactile)
            #if DEBUG
            PriseSelecteurDebug { modele.photoPrise($0) }.font(Police.legende).foregroundStyle(Palette.marine)
            #endif
        }
        .padding(Espace.bord)
    }

    private func demanderEtOuvrir() {
        if acces == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                Task { @MainActor in
                    acces = AVCaptureDevice.authorizationStatus(for: .video)
                    if acces == .authorized { ouvrirCamera() }
                }
            }
        } else {
            ouvrirCamera()
        }
    }

    // MARK: P18 : cadre de prise de vue

    private var cadre: some View {
        ZStack {
            Palette.nuit.ignoresSafeArea()
            VStack(spacing: Espace.l) {
                HStack {
                    PriseBoutonRond(symbole: "xmark", etiquette: "Fermer", action: fermer)
                    Spacer()
                    Label("Sur l'iPhone, sans réseau", systemImage: "lock.fill")
                        .font(Police.legende).foregroundStyle(Palette.encre)
                        .padding(.horizontal, Espace.m).frame(minHeight: 36)
                        .background(.regularMaterial, in: Capsule())
                    Spacer()
                    Color.clear.frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                }
                Spacer(minLength: 0)
                PriseCoinsDeCadre().stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .aspectRatio(1.3, contentMode: .fit)
                    .padding(.horizontal, Espace.xl)
                    .accessibilityHidden(true)
                Text("Le poisson entier, de profil")
                    .font(Police.corps).foregroundStyle(.white)
                Spacer(minLength: 0)
                Button(action: ouvrirCamera) {
                    Circle().fill(.white).frame(width: 72, height: 72)
                        .overlay(Circle().strokeBorder(.white.opacity(0.5), lineWidth: 5).frame(width: 84, height: 84))
                        .frame(width: 88, height: 88)
                }
                .accessibilityLabel("Prendre la photo")
                Button("Essayer avec une photo d'exemple") { modele.photoPrise(PhotoExemple.image(), exemple: true) }
                    .font(Police.detail).foregroundStyle(.white)
                    .frame(minHeight: Gabarit.zoneTactile)
                #if DEBUG
                PriseSelecteurDebug { modele.photoPrise($0) }.font(Police.legende).foregroundStyle(.white)
                #endif
            }
            .padding(Espace.bord)
        }
    }
}

/// Les quatre coins du cadre de prise de vue.
struct PriseCoinsDeCadre: Shape {
    func path(in rect: CGRect) -> Path {
        let b = min(rect.width, rect.height) * 0.16
        var p = Path()
        for (x, dx) in [(rect.minX, b), (rect.maxX, -b)] {
            for (y, dy) in [(rect.minY, b), (rect.maxY, -b)] {
                p.move(to: CGPoint(x: x + dx, y: y))
                p.addLine(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x, y: y + dy))
            }
        }
        return p
    }
}

/// Lecture de la photo : la photo en grand, le temps que le modèle réponde.
struct PriseEtapeLecture: View {
    var modele: PriseModele

    var body: some View {
        PriseFeuille(photo: modele.imagePhoto) {
            ProgressView().controlSize(.large).frame(minHeight: 96)
                .accessibilityLabel("Lecture de ta photo")
        }
    }
}
