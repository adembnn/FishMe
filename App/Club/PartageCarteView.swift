import MapKit
import SwiftUI
import UIKit

/// Choisir une carte déjà rendue par L4, puis la feuille de partage d'iOS. L'image part sans aucune métadonnée.
/// P33 : la carte en grand, « Sans ta position », « Partager au club » (si le club est branché) et « Autres apps ».
struct PartageCarteView: View {
    @Environment(\.dismiss) private var fermer
    let cartes: [CarteAPartager]
    /// À brancher : l'envoi au club passe par le partage CloudKit du lot Amis. Sans lui, le bouton n'apparaît pas.
    var partagerAuClub: ((CarteAPartager) -> Void)? = nil

    @State private var choisieId: String?

    private var choisie: CarteAPartager? {
        cartes.first { $0.id == choisieId } ?? cartes.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            fondCarte.ignoresSafeArea()
            if cartes.isEmpty {
                ContentUnavailableView("Aucune carte", systemImage: "rectangle.stack",
                                       description: Text("Ta première prise crée ta première carte."))
                    .frame(maxHeight: .infinity)
            } else if let choisie {
                // Maquette : rond « Fermer » à 59 pt du haut, carte de 290 pt de large 53 pt plus bas.
                VStack(spacing: 0) {
                    Spacer().frame(height: 53)
                    apercu(choisie)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 290)
                        .clipShape(RoundedRectangle(cornerRadius: 290 * Gabarit.coinCarte, style: .continuous))
                        .shadow(color: Palette.encre.opacity(0.3), radius: 15, y: 14)
                        .accessibilityLabel(Text(choisie.titre))
                    Spacer(minLength: Espace.s)
                    // Seul ajout à la maquette : choisir quelle carte partager quand il y en a plusieurs.
                    if cartes.count > 1 { bandeau.padding(.bottom, Espace.s) }
                    feuille(choisie)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            HStack {
                BoutonRond(role: .fermer, rendu: .verre) { fermer() }
                Spacer()
            }
            .padding(.horizontal, Espace.bord)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Maquette P33-A : carte MapKit non interactive (France entière), floutée et voilée, décor seulement.
    private var fondCarte: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
            span: MKCoordinateSpan(latitudeDelta: 9, longitudeDelta: 9)))) {}
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .allowsHitTesting(false)
            .saturation(0.6)
            .blur(radius: 5)
            .overlay(Palette.fond.opacity(0.6))
            .accessibilityHidden(true)
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
            Capsule().fill(Palette.filet).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 7)
                .padding(.bottom, Espace.m)
            HStack(spacing: Espace.m) {
                Image(systemName: "lock.fill").font(Police.taille(20)).foregroundStyle(Palette.ouvert)
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
        .padding(.horizontal, 20)
        .padding(.bottom, Espace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        .padding(.horizontal, Espace.s)
        .padding(.bottom, Espace.s)
    }

    private func apercu(_ carte: CarteAPartager) -> Image {
        if let image = UIImage(data: carte.png) { return Image(uiImage: image) }
        return Image(systemName: "photo")
    }
}
