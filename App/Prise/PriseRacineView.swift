import AVFoundation
import Core
import SwiftUI
import UIKit
#if DEBUG
import PhotosUI
#endif

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
        // P38 C : fond blanc, grande icône d'appareil photo en trait fin (210 pt, à 96 pt du haut), titre à 520 pt, bouton et lien à 40 pt du bas.
        // La fenêtre d'autorisation est celle d'iOS : l'app ne la dessine pas.
        let refus = acces == .denied || acces == .restricted
        return ZStack(alignment: .topLeading) {
          ZStack(alignment: .top) {
            Palette.surface
            PriseIconeAppareil()
                .stroke(Palette.marine, style: StrokeStyle(lineWidth: 0.9 * 210 / 24, lineJoin: .round))
                .frame(width: 210, height: 210)
                .padding(.top, 96)
                .accessibilityHidden(true)
            VStack(spacing: Espace.m) {
                Text("Photographier ta prise")
                    .font(Police.grandTitre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(refus ? "L'appareil photo est coupé pour FishMe." : "La photo reste sur ton iPhone, sans GPS.")
                    .font(Police.detail).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
            }
            .padding(.horizontal, Espace.xl)
            .padding(.top, 520)
            VStack(spacing: Espace.xs) {
                if PriseCamera.disponible {
                    if refus {
                        Button("Ouvrir les réglages") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { ouvrirURL(url) }
                        }
                        .buttonStyle(.principal)
                    } else {
                        Button("Continuer") { demanderEtOuvrir() }.buttonStyle(.principal)
                    }
                }
                PriseChoixPhoto(modele: modele) {
                    Text(PriseChoixPhotoTexte.libelle).font(Police.corps).foregroundStyle(Palette.marine)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, 40)
            .frame(maxHeight: .infinity, alignment: .bottom)
          }
          .ignoresSafeArea()
            // La maquette n'a pas de croix ici ; on la garde pour qu'on puisse toujours quitter l'écran (sans elle, seule une photo sort de l'écran).
            BoutonRond(role: .fermer, rendu: .verre, action: fermer).padding(.horizontal, Espace.bord)
        }
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
        // P18 C : la photo prend tout l'écran (l'aperçu vivant est ouvert par le déclencheur), voile marine à 28 %, coins de cadrage (320 × 290 à 230 pt du haut),
        // consigne à 545 pt, déclencheur de 92 pt à 92 pt du bas, galerie 48 pt à gauche, mention à 48 pt du bas.
        ZStack(alignment: .topLeading) {
          ZStack(alignment: .top) {
            Palette.nuit
            Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255).opacity(0.28)
            PriseCoinsDeCadre().stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .aspectRatio(320.0 / 290.0, contentMode: .fit)
                .frame(width: 320)
                .padding(.top, 230)
                .accessibilityHidden(true)
            Text("Le poisson entier, de profil")
                .font(Police.sousTitre).foregroundStyle(.white).multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                .frame(maxWidth: .infinity)
                .padding(.top, 545)
            Button(action: ouvrirCamera) {
                Circle().fill(.white).frame(width: 92, height: 92)
                    .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 4).frame(width: 100, height: 100))
                    .frame(width: 100, height: 100)
            }
            .accessibilityLabel("Prendre la photo")
            .padding(.bottom, 88)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            PriseChoixPhoto(modele: modele) {
                Image(systemName: "photo")
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(Palette.encre)
                    .frame(width: 48, height: 48)
                    .background(Color(red: 250 / 255, green: 252 / 255, blue: 255 / 255).opacity(0.92),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.leading, 32).padding(.bottom, 114)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            Text("Sur l\u{2019}iPhone, sans réseau")
                .font(Police.legende).foregroundStyle(.white.opacity(0.85))
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
          }
          .ignoresSafeArea()
            BoutonRond(role: .fermer, rendu: .verre, action: fermer).padding(.horizontal, Espace.bord)
        }
    }
}

private enum PriseChoixPhotoTexte {
    #if DEBUG
    static let libelle = "Choisir une photo"
    #else
    static let libelle = "Essayer avec une photo d'exemple"
    #endif
}

/// Le second chemin vers une photo : la photothèque sous #if DEBUG (simulateur sans caméra), sinon la photo d'exemple.
/// Une vraie carte ne naît que d'une photo prise avec l'appareil.
private struct PriseChoixPhoto<Etiquette: View>: View {
    var modele: PriseModele
    @ViewBuilder var etiquette: () -> Etiquette
    #if DEBUG
    @State private var choix: PhotosPickerItem?
    #endif

    var body: some View {
        #if DEBUG
        PhotosPicker(selection: $choix, matching: .images) { etiquette() }
            .accessibilityLabel("Choisir une photo")
            .onChange(of: choix) { _, nouveau in
                guard let nouveau else { return }
                Task {
                    if let data = try? await nouveau.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        modele.photoPrise(image)
                    }
                }
            }
        #else
        Button { modele.photoPrise(PhotoExemple.image(), exemple: true) } label: { etiquette() }
            .accessibilityLabel("Essayer avec une photo d'exemple")
        #endif
    }
}

/// Les quatre coins du cadre de prise de vue : le tracé de la maquette P18 (viewBox 320 × 290, coins arrondis de 12).
nonisolated struct PriseCoinsDeCadre: Shape {
    func path(in rect: CGRect) -> Path {
        let kx = rect.width / 320, ky = rect.height / 290
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * kx, y: rect.minY + y * ky) }
        var p = Path()
        p.move(to: pt(2, 44)); p.addLine(to: pt(2, 14)); p.addQuadCurve(to: pt(14, 2), control: pt(2, 2)); p.addLine(to: pt(44, 2))
        p.move(to: pt(276, 2)); p.addLine(to: pt(306, 2)); p.addQuadCurve(to: pt(318, 14), control: pt(318, 2)); p.addLine(to: pt(318, 44))
        p.move(to: pt(318, 246)); p.addLine(to: pt(318, 276)); p.addQuadCurve(to: pt(306, 288), control: pt(318, 288)); p.addLine(to: pt(276, 288))
        p.move(to: pt(44, 288)); p.addLine(to: pt(14, 288)); p.addQuadCurve(to: pt(2, 276), control: pt(2, 288)); p.addLine(to: pt(2, 246))
        return p
    }
}

/// L'icône d'appareil photo de la maquette P38 (viewBox 24 × 24) : boîtier et objectif, en trait.
nonisolated struct PriseIconeAppareil: Shape {
    func path(in rect: CGRect) -> Path {
        let k = min(rect.width, rect.height) / 24
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * k, y: rect.minY + y * k) }
        var p = Path()
        p.move(to: pt(4, 8))
        for (x, y) in [(7, 8), (9, 5), (15, 5), (17, 8), (20, 8), (20, 19), (4, 19)] as [(CGFloat, CGFloat)] { p.addLine(to: pt(x, y)) }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: rect.minX + 8.4 * k, y: rect.minY + 9.4 * k, width: 7.2 * k, height: 7.2 * k))
        return p
    }
}

/// Lecture de la photo : la photo en grand, le temps que le modèle réponde.
struct PriseEtapeLecture: View {
    var modele: PriseModele

    var body: some View {
        EcranChargement(texte: "Lecture de ta photo", photo: modele.imagePhoto)
            .overlay(alignment: .topLeading) {
                BoutonRond(role: .retour, rendu: .verre) { modele.retour() }
                    .padding(Espace.bord)
            }
    }
}
