import PhotosUI
import SwiftUI
import UIKit

/// La vue de capture de l'app (L19) : cadre sombre, aperçu plein écran, coins de cadrage, déclencheur rond de 72 pt, torche, galerie, Fermer.
/// Elle remplace `UIImagePickerController`. Elle ne demande jamais la permission : `PriseEtapePhoto` ne l'affiche que si l'accès est donné.
/// La photo rendue passe par `imageSansGPS` : aucune métadonnée de lieu ne l'accompagne, et elle ne quitte pas l'iPhone.
/// Même appel qu'avant pour les autres écrans (`PriseCamera(onImage:onCancel:)`, `PriseCamera.disponible`).
struct PriseCamera: View {
    var onImage: (UIImage) -> Void
    var onCancel: () -> Void
    /// Vrai pour la prise : le bouton de galerie (photothèque) est en bas à gauche. La galerie n'a besoin d'aucune permission.
    var galerie = false

    @State private var capture = PriseCapture()
    @State private var torcheAllumee = false
    @State private var enCours = false
    @State private var choix: PhotosPickerItem?

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

    var body: some View {
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
                Text("Le poisson entier, de profil")
                    .font(Police.sousTitre).foregroundStyle(.white).multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                    .padding(.horizontal, Espace.bord)
                Spacer(minLength: 0)
                bas
            }
        }
        .onAppear { if Self.disponible { capture.demarrer() } }
        .onDisappear { capture.arreter() }
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            Task {
                if let donnees = try? await nouveau.loadTransferable(type: Data.self), let image = Self.imageSansGPS(donnees) {
                    onImage(image)
                }
                choix = nil
            }
        }
    }

    // MARK: Barre du haut : Fermer à gauche, torche à droite

    private var haut: some View {
        HStack {
            BoutonRond(role: .fermer, rendu: .verre, action: onCancel)
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
                    if galerie {
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
            guard !enCours else { return }
            enCours = true
            capture.prendre { donnees in
                enCours = false
                if let donnees, let image = Self.imageSansGPS(donnees) { onImage(image) }
            }
        } label: {
            Circle().fill(.white).frame(width: 72, height: 72)
                .overlay(Circle().strokeBorder(.white.opacity(0.55), lineWidth: 4).frame(width: 82, height: 82))
                .frame(width: 88, height: 88)
                .opacity(enCours ? 0.6 : 1)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(enCours)
        .accessibilityLabel("Prendre la photo")
    }
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
