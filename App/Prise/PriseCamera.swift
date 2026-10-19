import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

/// La vue de capture de l'app (L19) : cadre sombre, aperçu plein écran, coins de cadrage, déclencheur rond de 72 pt, torche, galerie, Fermer.
/// Elle remplace `UIImagePickerController`. Elle gère elle-même la permission, pour tous les écrans qui l'utilisent (prise, toise, photo de sortie) :
/// accès jamais demandé -> demande système à l'apparition ; accès refusé -> jamais d'écran noir, une explication avec « Ouvrir les réglages »
/// et le repli « Choisir une photo » (galerie, sans permission).
/// La photo rendue (appareil ou galerie) passe par `imageSansGPS` : ré-encodée, aucune métadonnée de lieu ne l'accompagne, et elle ne quitte pas l'iPhone.
/// L'import depuis la galerie pour créer une carte est voulu (décision de Titouan, 19 oct.).
/// Même appel qu'avant pour les autres écrans (`PriseCamera(onImage:onCancel:)`, `PriseCamera.disponible`).
struct PriseCamera: View {
    var onImage: (UIImage) -> Void
    var onCancel: () -> Void
    /// Vrai pour la prise : le bouton de galerie (photothèque) est en bas à gauche. La galerie n'a besoin d'aucune permission.
    var galerie = false

    @State private var capture = PriseCapture()
    @State private var etat = PriseCameraEtat()
    @State private var acces = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var torcheAllumee = false
    @State private var choix: PhotosPickerItem?
    @Environment(\.openURL) private var ouvrirURL
    @Environment(\.scenePhase) private var phase

    static var disponible: Bool { PriseCapture.disponible }

    /// Les données JPEG de l'appareil (ou de la galerie) ré-encodées : l'orientation est appliquée, tous les dictionnaires de métadonnées
    /// (EXIF, GPS) disparaissent. C'est la seule porte de sortie d'une photo vers le reste de l'app.
    static func imageSansGPS(_ donnees: Data) -> UIImage? {
        UIImage(data: donnees)?.priseRedressee()
    }

    /// Même chose en données JPEG (pour le test des métadonnées).
    static func jpegSansGPS(_ donnees: Data) -> Data? {
        imageSansGPS(donnees)?.jpegData(compressionQuality: 0.85)
    }

    /// Accès à l'appareil photo refusé ou restreint, sur un iPhone qui a une caméra.
    private var refuse: Bool { Self.disponible && (acces == .denied || acces == .restricted) }

    var body: some View {
        Group {
            if refuse { ecranRefus } else { ecranCamera }
        }
        .onAppear {
            etat.fermee = false
            demarrerCamera()
        }
        .onDisappear {
            etat.fermee = true   // une photo qui arrive après la fermeture n'est jamais livrée
            capture.arreter()
        }
        // Retour des Réglages d'iOS : l'accès a peut-être été donné entre-temps.
        .onChange(of: phase) { _, nouvelle in
            if nouvelle == .active { demarrerCamera() }
        }
        // Réponse à la demande système : relire l'accès et lancer la session s'il est donné.
        .onChange(of: etat.accesChange) { _, _ in demarrerCamera() }
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            let etat = etat
            Task {
                if let donnees = try? await nouveau.loadTransferable(type: Data.self), let image = Self.imageSansGPS(donnees), !etat.fermee {
                    onImage(image)
                }
                choix = nil
            }
        }
    }

    private func fermer() {
        etat.fermee = true
        onCancel()
    }

    /// Vérifie l'accès, le demande s'il ne l'a jamais été, puis lance la session. Rien à faire sans caméra (simulateur) ou si l'accès est refusé.
    private func demarrerCamera() {
        guard Self.disponible else { return }
        acces = AVCaptureDevice.authorizationStatus(for: .video)
        switch acces {
        case .authorized:
            lancer()
        case .notDetermined:
            let etat = etat
            AVCaptureDevice.requestAccess(for: .video) { _ in
                Task { @MainActor in etat.accesChange += 1 }
            }
        default:
            break
        }
    }

    private func lancer() {
        let etat = etat
        capture.demarrer { tourne in etat.erreur = tourne ? nil : PriseCameraEtat.messageIndisponible }
    }

    // MARK: Accès refusé : une explication, jamais un écran noir

    private var ecranRefus: some View {
        ZStack(alignment: .topLeading) {
            Palette.surface.ignoresSafeArea()
            VStack(spacing: Espace.l) {
                Spacer(minLength: 0)
                PriseIconeAppareil()
                    .stroke(Palette.marine, style: StrokeStyle(lineWidth: 0.9 * 120 / 24, lineJoin: .round))
                    .frame(width: 120, height: 120)
                    .accessibilityHidden(true)
                Text("L\u{2019}appareil photo est coupé pour FishMe.")
                    .font(Police.titre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Autorise-le dans les réglages, ou choisis une photo dans ta galerie. Elle reste sur ton iPhone, sans GPS.")
                    .font(Police.detail).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                VStack(spacing: Espace.xs) {
                    Button("Ouvrir les réglages") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { ouvrirURL(url) }
                    }
                    .buttonStyle(.principal)
                    PhotosPicker(selection: $choix, matching: .images) {
                        Text("Choisir une photo").font(Police.corps).foregroundStyle(Palette.marine)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    }
                    .accessibilityLabel("Choisir une photo dans la galerie")
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.xl)
            BoutonRond(role: .fermer, rendu: .verre, action: fermer).padding(.horizontal, Espace.bord)
        }
    }

    // MARK: La caméra

    private var ecranCamera: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if Self.disponible {
                PriseApercu(capture: capture).ignoresSafeArea().accessibilityHidden(true)
            }
            // Voile marine léger et coins de cadrage de la maquette P18.
            Palette.nuit.opacity(0.18).ignoresSafeArea().allowsHitTesting(false)
            PriseCoinsDeCadre()
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .aspectRatio(320.0 / 290.0, contentMode: .fit)
                .frame(maxWidth: 320)
                .padding(.horizontal, Espace.xl)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            VStack(spacing: 0) {
                haut
                Spacer(minLength: 0)
                if let erreur = etat.erreur {
                    // La session ne tourne pas (caméra occupée, appel en cours) ou la photo a échoué : on le dit.
                    VStack(spacing: Espace.s) {
                        Text(erreur)
                            .font(Police.sousTitre).foregroundStyle(.white).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        if Self.disponible {
                            Button("Réessayer") { etat.erreur = nil; lancer() }
                                .font(Police.corps).foregroundStyle(.white)
                                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                        }
                    }
                    .padding(.horizontal, Espace.bord)
                } else {
                    Text("Le poisson entier, de profil")
                        .font(Police.sousTitre).foregroundStyle(.white).multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                        .padding(.horizontal, Espace.bord)
                }
                Spacer(minLength: 0)
                bas
            }
        }
    }

    // MARK: Barre du haut : Fermer à gauche, torche à droite

    private var haut: some View {
        HStack {
            BoutonRond(role: .fermer, rendu: .verre, action: fermer)
            Spacer()
            if PriseCapture.torcheDisponible {
                Button {
                    torcheAllumee.toggle()
                    capture.torche(torcheAllumee)
                } label: {
                    Image(systemName: torcheAllumee ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(torcheAllumee ? Palette.nuit : .white)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(torcheAllumee ? Color.white : Color.white.opacity(0.18), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(torcheAllumee ? "Éteindre la torche" : "Allumer la torche")
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
    }

    // MARK: Barre du bas : galerie, déclencheur, mention

    private var bas: some View {
        VStack(spacing: Espace.m) {
            HStack {
                Group {
                    if galerie || etat.erreur != nil {
                        PhotosPicker(selection: $choix, matching: .images) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .accessibilityLabel("Choisir une photo dans la galerie")
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 56, height: 56)
                Spacer()
                declencheur
                Spacer()
                Color.clear.frame(width: 56, height: 56)
            }
            .padding(.horizontal, Espace.xl)
            Text("Sur l\u{2019}iPhone, sans réseau")
                .font(Police.legende).foregroundStyle(.white.opacity(0.85))
        }
        .padding(.bottom, Espace.l)
    }

    /// Le déclencheur rond de 72 pt (zone touchable de 88 pt avec son anneau).
    private var declencheur: some View {
        Button {
            guard !etat.enCours else { return }
            etat.enCours = true
            let etat = etat
            // ⚠ à vérifier : la fermeture est @MainActor @Sendable et appelle `onImage` (capturé) ; en Swift 6, si le compilateur refuse,
            // ranger `onImage` dans `PriseCameraEtat` (classe MainActor) et l'appeler depuis là.
            capture.prendre { donnees in
                etat.enCours = false
                guard !etat.fermee else { return }   // Fermer touché entre-temps : rien n'est livré
                if let donnees, let image = Self.imageSansGPS(donnees) {
                    onImage(image)
                } else {
                    etat.erreur = PriseCameraEtat.messagePhotoManquee
                }
            }
        } label: {
            Circle().fill(.white).frame(width: 72, height: 72)
                .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 4).frame(width: 82, height: 82))
                .frame(width: 88, height: 88)
                .opacity(etat.enCours ? 0.6 : 1)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(etat.enCours)
        .accessibilityLabel("Prendre la photo")
    }
}

/// L'état de la vue de capture, lu et écrit sur le fil principal (une classe, pour que les fermetures de la session ne capturent pas la vue).
@Observable final class PriseCameraEtat {
    static let messageIndisponible = "Caméra indisponible. Ferme les autres apps qui l\u{2019}utilisent, puis réessaie."
    static let messagePhotoManquee = "La photo n\u{2019}a pas pu être prise. Réessaie."
    var erreur: String?
    var enCours = false
    /// Vrai dès que le pêcheur a touché Fermer (ou que la vue a disparu) : `onImage` n'est plus appelé.
    var fermee = false
    /// Compteur incrémenté quand la demande système d'accès a répondu (la vue relit alors l'état).
    var accesChange = 0
}

/// La photo d'exemple, embarquée (fichier `photo-exemple.jpg` à poser dans `App/Prise/`, à fournir : photo libre de droits).
/// Sans le fichier, une image neutre est dessinée pour que le parcours marche quand même.
enum PhotoExemple {
    static func image() -> UIImage {
        if let url = Bundle.main.url(forResource: "photo-exemple", withExtension: "jpg"),
           let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            return image
        }
        let taille = CGSize(width: 900, height: 600)
        return UIGraphicsImageRenderer(size: taille).image { ctx in
            UIColor(red: 0.32, green: 0.69, blue: 0.82, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: taille))
        }
    }
}

#if DEBUG
#Preview("Capture (simulateur : cadre sombre sans aperçu)") {
    PriseCamera(onImage: { _ in }, onCancel: {}, galerie: true)
}
#endif
