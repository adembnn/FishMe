import ImageIO
import Photos
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Ce que le pêcheur voit après « Enregistrer dans Photos ».
enum ResultatEnregistrement: Equatable {
    case enregistree
    /// Permission « ajout seul » refusée : une ligne mène aux réglages.
    case refuse
    case echec
}

/// Écrit l'image d'une carte dans la photothèque, sans aucune position (L18).
/// Permission « ajout seul » (`.addOnly`) : l'app n'a jamais accès à tes autres photos. La clé
/// `NSPhotoLibraryAddUsageDescription` est déjà dans le projet.
enum EnregistrementPhotos {
    /// Vrai pour une permission qui laisse écrire (l'accès limité suffit pour ajouter).
    static func peutEcrire(_ statut: PHAuthorizationStatus) -> Bool {
        statut == .authorized || statut == .limited
    }

    private static let signaturePNG: [UInt8] = [0x89, 0x50, 0x4E, 0x47]

    /// Les données à écrire, sans second encodage inutile : un PNG tel quel (fabriqué par UIKit, sans métadonnée) ; un JPEG sans bloc
    /// GPS tel quel (le verso est déjà nettoyé à l'enregistrement de la carte) ; tout autre cas est ré-encodé sans GPS, ni date,
    /// ni appareil. `nil` si ce n'est pas une image : on n'écrit jamais des octets qu'on n'a pas contrôlés.
    static func donneesSansLieu(_ donnees: Data) -> Data? {
        if donnees.starts(with: signaturePNG) { return donnees }
        if estJPEG(donnees), !NettoyagePhoto.contientGPS(donnees) { return donnees }
        return NettoyagePhoto.sansMetadonnees(donnees)
    }

    /// Vrai si les octets se lisent comme un JPEG (`contientGPS` répond aussi « faux » pour des octets qui ne sont pas une image).
    private static func estJPEG(_ donnees: Data) -> Bool {
        guard let source = CGImageSourceCreateWithData(donnees as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let type = CGImageSourceGetType(source) else { return false }
        return (type as String) == UTType.jpeg.identifier
    }

    /// Demande la permission d'ajout, puis écrit l'image. Aucune propriété `location` n'est posée sur la demande.
    /// Si Photos refuse le PNG, repli : la même image en JPEG sans métadonnée.
    static func enregistrer(_ donnees: Data) async -> ResultatEnregistrement {
        guard let propres = donneesSansLieu(donnees) else { return .echec }
        let statut = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard peutEcrire(statut) else { return .refuse }
        if await ecrire(propres) { return .enregistree }
        // ⚠ à vérifier sur iPhone : un PNG en `.photo` devrait être accepté ; sinon on retente en JPEG.
        if propres.starts(with: signaturePNG),
           let jpeg = NettoyagePhoto.sansMetadonnees(propres), await ecrire(jpeg) {
            return .enregistree
        }
        return .echec
    }

    private static func ecrire(_ donnees: Data) async -> Bool {
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let demande = PHAssetCreationRequest.forAsset()
                demande.addResource(with: .photo, data: donnees, options: nil)
            }
            return true
        } catch {
            return false
        }
    }

    /// Ouvre les réglages de FishMe (permission Photos).
    @MainActor
    static func ouvrirReglages() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

/// Le bouton « Enregistrer dans Photos » et son message : « Enregistrée », ou la ligne vers les réglages en cas de refus.
struct EnregistrerDansPhotosBouton: View {
    /// L'image à écrire (PNG de la carte, ou photo du verso). `nil` : le bouton n'est pas affiché.
    let donnees: Data?

    @State private var resultat: ResultatEnregistrement?
    @State private var enCours = false
    @Environment(\.locale) private var locale
    private var t: AnglaisD { AnglaisD(locale) }

    var body: some View {
        if let donnees {
            VStack(spacing: Espace.s) {
                Button {
                    Task { await enregistrer(donnees) }
                } label: {
                    Label(t("Enregistrer dans Photos"), systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.secondaire)
                .disabled(enCours)
                message
            }
        }
    }

    @ViewBuilder
    private var message: some View {
        switch resultat {
        case .enregistree:
            Label(t("Enregistrée"), systemImage: "checkmark.circle.fill")
                .font(Police.detail)
                .foregroundStyle(Palette.marine)
                .transition(.opacity)
        case .refuse:
            Button { EnregistrementPhotos.ouvrirReglages() } label: {
                Text(t("FishMe n'a pas le droit d'ajouter à Photos. Ouvrir les réglages"))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .echec:
            Text(t("L'image n'a pas pu être enregistrée."))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
        case nil:
            EmptyView()
        }
    }

    private func enregistrer(_ donnees: Data) async {
        enCours = true
        defer { enCours = false }
        let r = await EnregistrementPhotos.enregistrer(donnees)
        withAnimation { resultat = r }
        guard r == .enregistree else { return }
        // Le message « Enregistrée » s'efface seul.
        try? await Task.sleep(for: .seconds(2.5))
        withAnimation { if resultat == .enregistree { resultat = nil } }
    }
}
