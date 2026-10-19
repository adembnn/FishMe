import AVFoundation
import Core
import SwiftUI
import UIKit
import PhotosUI

/// L'écran Prise : de la photo à la liste de contrôle. A le branche dans `RootView.swift` avec ses services, le contexte de la sortie et la fermeture `terminer`
/// (`nil` : aucune carte créée ; sinon la prise confirmée et la photo, que L4 range).
struct PriseRacineView: View {
    @State private var modele: PriseModele
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
    }

    @ViewBuilder private var contenu: some View {
        switch modele.etape {
        case .photo: PriseEtapePhoto(modele: modele, fermer: { modele.terminer(nil) })
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

/// P38 puis P18 : quand l'accès à l'appareil photo est donné et que l'iPhone a une caméra, la vue de capture maison est là tout de suite
/// (aucune explication, aucun écran intermédiaire) ; sinon (jamais demandé, refusé, simulateur) une explication courte
/// (« la photo reste sur ton iPhone, sans GPS »). La permission n'est demandée qu'au toucher de « Continuer ». La photo n'a pas de GPS.
struct PriseEtapePhoto: View {
    var modele: PriseModele
    var fermer: () -> Void

    @State private var acces = AVCaptureDevice.authorizationStatus(for: .video)
    @Environment(\.openURL) private var ouvrirURL
    @Environment(\.scenePhase) private var phase

    var body: some View {
        Group {
            if acces == .authorized && PriseCamera.disponible {
                PriseCamera(onImage: { modele.photoPrise($0) }, onCancel: fermer, galerie: true)
            } else {
                permission
            }
        }
        .onAppear { acces = AVCaptureDevice.authorizationStatus(for: .video) }
        // Retour des Réglages d'iOS : l'accès a peut-être été donné entre-temps.
        .onChange(of: phase) { _, nouvelle in
            if nouvelle == .active { acces = AVCaptureDevice.authorizationStatus(for: .video) }
        }
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
                        Button("Continuer") { demander() }.buttonStyle(.principal)
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

    private func demander() {
        if acces == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                Task { @MainActor in
                    acces = AVCaptureDevice.authorizationStatus(for: .video)
                }
            }
        }
    }
}

private enum PriseChoixPhotoTexte {
    static let libelle = "Choisir une photo"
}

/// Le second chemin vers une photo sur l'écran d'explication (sans caméra ou sans accès) : la galerie, puis la photo d'exemple.
/// L'import depuis la galerie est voulu (décision de Titouan, 19 oct.) : la photo est ré-encodée par `PriseCamera.imageSansGPS`, donc sans GPS.
/// Avec la caméra, la galerie est aussi dans la vue de capture (`PriseCamera`).
private struct PriseChoixPhoto<Etiquette: View>: View {
    var modele: PriseModele
    @ViewBuilder var etiquette: () -> Etiquette
    @State private var choix: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            PhotosPicker(selection: $choix, matching: .images) { etiquette() }
                .accessibilityLabel("Choisir une photo")
                .onChange(of: choix) { _, nouveau in
                    guard let nouveau else { return }
                    Task {
                        if let data = try? await nouveau.loadTransferable(type: Data.self), let image = PriseCamera.imageSansGPS(data) {
                            modele.photoPrise(image)
                        }
                        choix = nil
                    }
                }
            Button { modele.photoPrise(PhotoExemple.image(), exemple: true) } label: {
                Text("Essayer avec une photo d'exemple").font(Police.corps).foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            }
            .accessibilityLabel("Essayer avec une photo d'exemple")
        }
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
