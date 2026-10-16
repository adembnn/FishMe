import SwiftUI
import UIKit

/// Choisir une carte déjà rendue par L4, puis la feuille de partage d'iOS. L'image part sans aucune métadonnée.
/// P33 : la carte en grand, « Sans ta position », « Partager au club » (si le club est branché) et « Autres apps ».
struct PartageCarteView: View {
    let cartes: [CarteAPartager]
    /// À brancher : l'envoi au club passe par le partage CloudKit du lot Amis. Sans lui, le bouton n'apparaît pas.
    var partagerAuClub: ((CarteAPartager) -> Void)? = nil

    @State private var choisieId: String?

    private var choisie: CarteAPartager? {
        cartes.first { $0.id == choisieId } ?? cartes.first
    }

    var body: some View {
        Group {
            if cartes.isEmpty {
                ContentUnavailableView("Aucune carte", systemImage: "rectangle.stack",
                                       description: Text("Ta première prise crée ta première carte."))
            } else if let choisie {
                VStack(spacing: Espace.l) {
                    apercu(choisie)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                        .padding(.horizontal, Espace.xl)
                        .accessibilityLabel(Text(choisie.titre))
                    if cartes.count > 1 { bandeau }
                    actions(choisie)
                }
                .padding(.top, Espace.s)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle("Partager une carte")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var bandeau: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Espace.s) {
                ForEach(cartes) { carte in
                    Button { choisieId = carte.id } label: {
                        apercu(carte).resizable().scaledToFit()
                            .frame(height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
                                .strokeBorder(Palette.marine, lineWidth: carte.id == choisie?.id ? 3 : 0))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(carte.titre))
                }
            }
            .padding(.horizontal, Espace.bord)
        }
        .scrollIndicators(.hidden)
    }

    private func actions(_ carte: CarteAPartager) -> some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            HStack(spacing: Espace.m) {
                Image(systemName: "lock.fill").foregroundStyle(Palette.ouvert)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sans ta position").font(Police.sousTitre).foregroundStyle(Palette.encre)
                    Text("Ni lieu exact, ni GPS dans l'image.").font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
            if let partagerAuClub {
                Button("Partager au club") { partagerAuClub(carte) }
                    .buttonStyle(.principal)
                ShareLink(item: carte, preview: SharePreview(carte.titre, image: apercu(carte))) {
                    Label("Autres apps", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondaire)
            } else {
                ShareLink(item: carte, preview: SharePreview(carte.titre, image: apercu(carte))) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.principal)
            }
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .padding(.horizontal, Espace.s)
    }

    private func apercu(_ carte: CarteAPartager) -> Image {
        if let image = UIImage(data: carte.png) { return Image(uiImage: image) }
        return Image(systemName: "photo")
    }
}
