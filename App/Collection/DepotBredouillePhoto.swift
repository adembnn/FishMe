import Foundation

/// La photo de soi d'une carte « Eau calme » (sortie sans prise). Un fichier à côté des photos de prises, nommé d'après la sortie :
/// aucun changement du schéma SwiftData. Elle repasse par `NettoyagePhoto` comme toutes les photos : jamais de GPS.
extension DepotCartes {
    private func fichierPhotoSortie(id: UUID) -> URL {
        dossierPhotos.appendingPathComponent("\(id.uuidString)-sortie.jpg")
    }

    /// Le fichier de la photo, s'il existe.
    func urlPhotoSortie(id: UUID) -> URL? {
        let url = fichierPhotoSortie(id: id)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Enregistre (ou remplace) la photo de la sortie. Lève `photoIllisible` si les données ne sont pas une image.
    func ajouterPhotoBredouille(id: UUID, photo: Data) throws {
        guard let propre = NettoyagePhoto.sansMetadonnees(photo) else { throw ErreurDepot.photoIllisible }
        try propre.write(to: fichierPhotoSortie(id: id), options: [.atomic, .completeFileProtection])
    }
}
