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
        ZStack(alignment: .top) {
            Palette.fond.ignoresSafeArea()
            if cartes.isEmpty {
                ContentUnavailableView("Aucune carte", systemImage: "rectangle.stack",
                                       description: Text("Ta première prise crée ta première carte."))
                    .frame(maxHeight: .infinity)
            } else if let choisie {
                VStack(spacing: Espace.m) {
                    Spacer(minLength: 64)
                    apercu(choisie)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                        .shadow(color: Palette.encre.opacity(0.18), radius: 14, y: 8)
                        .padding(.horizontal, Espace.xxl + Espace.s)
                        .accessibilityLabel(Text(choisie.titre))
                    if cartes.count > 1 { bandeau }
                    Spacer(minLength: Espace.s)
                    feuille(choisie)
                }
            }
            HStack {
                BoutonRond(role: .fermer, rendu: .verre)
                Spacer()
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var bandeau: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Espace.s) {
                ForEach(cartes) { carte in
                    Button { choisieId = carte.id } label: {
                        apercu(carte).resizable().scaledToFit()
                            .frame(height: 56)
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

    /// La feuille du bas : poignée, « Sans ta position », le bouton principal, puis « Autres apps ».
    private func feuille(_ carte: CarteAPartager) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Palette.silhouette).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.bottom, Espace.m)
            HStack(spacing: Espace.m) {
                Image(systemName: "lock.fill").font(Police.titre).foregroundStyle(Palette.ouvert)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sans ta position").font(Police.sousTitre).foregroundStyle(Palette.encre)
                    Text("Ni lieu exact, ni GPS dans l'image.").font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
            .accessibilityElement(children: .combine)
            if let partagerAuClub {
                Button("Partager au club") { partagerAuClub(carte) }
                    .buttonStyle(.principal)
                    .padding(.top, 18)
                ShareLink(item: carte, preview: SharePreview(carte.titre, image: apercu(carte))) {
                    Label("Autres apps", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.secondaire)
                .padding(.top, Espace.s)
            } else {
                ShareLink(item: carte, preview: SharePreview(carte.titre, image: apercu(carte))) {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.principal)
                .padding(.top, 18)
            }
        }
        .padding(.horizontal, Espace.xl)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Espace.s)
    }

    private func apercu(_ carte: CarteAPartager) -> Image {
        if let image = UIImage(data: carte.png) { return Image(uiImage: image) }
        return Image(systemName: "photo")
    }
}
