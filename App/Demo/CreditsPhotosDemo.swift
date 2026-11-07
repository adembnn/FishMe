import SwiftUI

#if DEBUG

/// Les photos libres de droits du mode démo (`App/Demo/Photos`), avec auteur, licence et page Wikimedia Commons.
/// Seules des licences sans « partage à l'identique » (CC0, domaine public, CC BY) sont embarquées.
enum CreditsPhotosDemo {
    struct Credit: Identifiable {
        let fichier: String
        let espece: String
        let auteur: String
        let licence: String
        let source: URL
        var id: String { fichier }
    }

    static let liste: [Credit] = [
        Credit(fichier: "brochet-1", espece: "Brochet", auteur: "AsgerJon", licence: "CC0",
               source: URL(string: "https://commons.wikimedia.org/wiki/File:Esox_Lucius.jpg")!),
        Credit(fichier: "perche-commune-1", espece: "Perche", auteur: "Nervurax Fishing", licence: "CC0",
               source: URL(string: "https://commons.wikimedia.org/wiki/File:Perca_fluviatilis_yerres_river_22-10-17.jpg")!),
        Credit(fichier: "sandre-1", espece: "Sandre", auteur: "eLNuko", licence: "Domaine public",
               source: URL(string: "https://commons.wikimedia.org/wiki/File:Sander_lucioperca_1.jpg")!),
        Credit(fichier: "truite-fario-1", espece: "Truite fario", auteur: "Philthy54", licence: "CC BY 3.0",
               source: URL(string: "https://commons.wikimedia.org/wiki/File:Browntrout029.jpg")!),
        Credit(fichier: "black-bass-1", espece: "Black-bass", auteur: "Arnaudia31", licence: "CC BY 4.0",
               source: URL(string: "https://commons.wikimedia.org/wiki/File:Micropterus_salmoides_manipulation_relache_FR_20251129.jpg")!),
    ]
}

/// « Crédits photos » (Réglages, À propos) : les photos du mode démo, leur auteur et leur licence.
struct CreditsPhotosFeuille: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.m) {
                    Text("Photos du mode démo, publiées sur Wikimedia Commons.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                    ForEach(CreditsPhotosDemo.liste) { credit in
                        Link(destination: credit.source) {
                            HStack(spacing: Espace.m) {
                                if let image = PhotoDemoClub.image(credit.fichier) {
                                    Image(uiImage: image).resizable().scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(credit.espece)
                                        .font(Police.corps)
                                        .foregroundStyle(Palette.encre)
                                    Text("\(credit.auteur) · \(credit.licence)")
                                        .font(Police.legende)
                                        .foregroundStyle(Palette.encreDouce)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .font(Police.legende)
                                    .foregroundStyle(Palette.marine)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Espace.bord)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Crédits photos")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}

#else

/// Build de production : pas de photo de démo, donc rien à créditer.
struct CreditsPhotosFeuille: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Text("Aucune photo à créditer.")
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.fond.ignoresSafeArea())
                .navigationTitle("Crédits photos")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("OK") { dismiss() } } }
        }
    }
}

#endif
