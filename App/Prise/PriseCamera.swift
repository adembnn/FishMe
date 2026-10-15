import SwiftUI
import UIKit
#if DEBUG
import PhotosUI
#endif

/// L'appareil photo de l'app. Une carte ne naît que d'une photo prise ici : pas d'import depuis la photothèque (sauf sous #if DEBUG).
struct PriseCamera: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    var onCancel: () -> Void

    static var disponible: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinateur { Coordinateur(self) }

    final class Coordinateur: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PriseCamera
        init(_ parent: PriseCamera) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) } else { parent.onCancel() }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onCancel() }
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
/// Sélecteur de photos pour le simulateur sans caméra : n'existe que sous #if DEBUG.
struct PriseSelecteurDebug: View {
    var onImage: (UIImage) -> Void
    @State private var choix: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $choix, matching: .images) {
            Text("Choisir une photo (simulateur)")
        }
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            Task {
                if let data = try? await nouveau.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    onImage(image)
                }
            }
        }
    }
}
#endif
