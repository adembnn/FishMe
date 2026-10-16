import Core
import SwiftUI
import UIKit

/// L'image rendue pour le partage : le recto seulement. Ni bloc météo, ni marque Apple à recopier, aucune coordonnée,
/// et un PNG fabriqué par UIKit, sans métadonnée.
enum ImagePartage {
    @MainActor
    static func png(de prise: Prise, services: ServicesCollection, largeur: CGFloat = 360) -> Data? {
        guard let espece = services.especes.especesPechables().first(where: { $0.espece == prise.espece }) else { return nil }
        let dept = Formats.departement(depuisLieuFlou: prise.lieuFlou)
        // Pas de conditions, pas de durée : le partage ne porte jamais d'indice de plus pour retrouver le coin.
        let detail = CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil)
        let infos = InfosCarte.construire(detail: detail, espece: espece, zone: dept, toutesLesCartes: [prise],
                                          especesDeLaZone: [], services: services)
        let carte = CarteRectoView(infos: infos, anime: false, inclinaison: .zero, refletFixe: true,
                                   imageDecodee: UIImage(named: infos.espece.image), pourPartage: true)
            .frame(width: largeur * 0.81, height: largeur * 0.81 / Gabarit.rapportCarte)
        let vue = FondPartage(carte: carte, largeur: largeur, departement: dept)
        let rendu = ImageRenderer(content: vue)
        rendu.scale = 3
        // Un premier rendu peut échouer le temps que le moteur graphique chauffe (simulateur) : un seul nouvel essai.
        // Rendu raté : on rend `nil` (le partage n'a pas d'image), jamais de plantage.
        guard let image = rendu.uiImage ?? rendu.uiImage else { return nil }
        return image.pngData()
    }
}

/// P49 A : un format 9/16 bleu nuit semé de ronds d'eau, le logo discret en haut, la carte inclinée de 3 degrés (81 % de la largeur),
/// « Mon Pescedex · <département> » en bas. Jamais de lieu précis : le département seulement, et rien du tout s'il est inconnu.
private struct FondPartage<Carte: View>: View {
    let carte: Carte
    let largeur: CGFloat
    let departement: Departement?

    private var legende: String {
        if let d = departement, !d.estInconnu { return "Mon Pescedex · \(NomsDepartements.nom(code: d.code) ?? d.code)" }
        return "Mon Pescedex"
    }

    /// L'icône de l'app quand l'image « fishme-icone-1024 » est rangée dans le bundle, sinon le poisson d'origine.
    /// (L'icône d'app d'un `AppIcon.appiconset` n'est pas lisible par nom : on garde le repli.)
    @ViewBuilder
    private func logo(_ k: CGFloat) -> some View {
        if let icone = UIImage(named: "fishme-icone-1024") {
            Image(uiImage: icone)
                .resizable().scaledToFit()
                .frame(width: 24 * k, height: 24 * k)
                .clipShape(RoundedRectangle(cornerRadius: 5 * k, style: .continuous))
        } else {
            Image(systemName: "fish.fill")
                .font(Police.taille(13 * k, .heavy))
                .foregroundStyle(.white)
                .frame(width: 24 * k, height: 24 * k)
                .background(Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255),
                            in: RoundedRectangle(cornerRadius: 5 * k, style: .continuous))
        }
    }

    var body: some View {
        // Toutes les mesures de la maquette (324 pt de large) suivent la largeur demandée.
        let k = largeur / 324
        let hauteur = largeur * 16 / 9
        ZStack {
            // Bleu nuit fixe : l'image partagée ne dépend pas du mode sombre.
            Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255)
            ZStack {
                ForEach(1..<24, id: \.self) { i in
                    Circle()
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        .frame(width: CGFloat(i) * 46 * k, height: CGFloat(i) * 46 * k)
                }
            }
            .position(x: largeur / 2, y: hauteur * 0.46)
            VStack(spacing: 0) {
                HStack(spacing: 8 * k) {
                    logo(k)
                    Text("FishMe")
                        .font(Police.taille(15 * k, .black))
                        .tracking(0.01 * 15 * k)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, 22 * k)
                Spacer(minLength: 0)
                carte
                    .rotationEffect(.degrees(-3))
                    .shadow(color: .black.opacity(0.35), radius: 18 * k, y: 10 * k)
                Spacer(minLength: 0)
                Text(legende)
                    .font(Police.taille(15 * k, .heavy))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 26 * k)
            }
        }
        .frame(width: largeur, height: hauteur)
        .clipped()
    }
}

/// P49 A : l'image qui va partir, vue en entier (324 × 576 pt, coins de 22), fermer en haut à gauche et un seul bouton « Partager » en bas.
/// Le PNG est celui de `ImagePartage` : sans métadonnée, sans lieu précis.
struct ApercuPartageView: View {
    let png: Data
    let fermer: () -> Void

    var body: some View {
        let image = UIImage(data: png)
        ZStack {
            Palette.fond.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    BoutonRond(role: .fermer, rendu: .verre, action: fermer)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Espace.bord)
                Spacer(minLength: Espace.s)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 324, maxHeight: 576)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Palette.encre.opacity(0.28), radius: 20, y: 18)
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Palette.encre.opacity(0.08), lineWidth: 1))
                        .accessibilityLabel("Aperçu de l'image à partager")
                }
                Spacer(minLength: Espace.l)
                if let image {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("Ma carte FishMe", image: Image(uiImage: image))) {
                        Label("Partager", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.principal)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, 6)
                }
            }
        }
    }
}
