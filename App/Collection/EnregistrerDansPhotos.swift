import Photos
import SwiftUI
import UIKit

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

    /// Les données à écrire : un PNG tel quel (fabriqué par UIKit, sans métadonnée) ; toute autre image est ré-encodée sans GPS,
    /// ni date, ni appareil. `nil` si ce n'est pas une image : on n'écrit jamais des octets qu'on n'a pas nettoyés.
    static func donneesSansLieu(_ donnees: Data) -> Data? {
        if donnees.starts(with: signaturePNG) { return donnees }
        return NettoyagePhoto.sansMetadonnees(donnees)
    }

    /// Demande la permission d'ajout, puis écrit l'image. Aucune propriété `location` n'est posée sur la demande.
    static func enregistrer(_ donnees: Data) async -> ResultatEnregistrement {
        guard let propres = donneesSansLieu(donnees) else { return .echec }
        let statut = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard peutEcrire(statut) else { return .refuse }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let demande = PHAssetCreationRequest.forAsset()
                // ⚠ à vérifier sur iPhone : un PNG ajouté en `.photo` doit apparaître dans Photos (repli : le convertir en JPEG).
                demande.addResource(with: .photo, data: propres, options: nil)
            }
            return .enregistree
        } catch {
            return .echec
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

    var body: some View {
        if let donnees {
            VStack(spacing: Espace.s) {
                Button {
                    Task { await enregistrer(donnees) }
                } label: {
                    Label("Enregistrer dans Photos", systemImage: "square.and.arrow.down")
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
            Label("Enregistrée", systemImage: "checkmark.circle.fill")
                .font(Police.detail)
                .foregroundStyle(Palette.marine)
                .transition(.opacity)
        case .refuse:
            Button { EnregistrementPhotos.ouvrirReglages() } label: {
                Text("FishMe n'a pas le droit d'ajouter à Photos. Ouvrir les réglages")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        case .echec:
            Text("L'image n'a pas pu être enregistrée.")
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
