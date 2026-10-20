import Core
import SwiftUI
import UIKit

/// Charge la photo de soi d'une carte « Eau calme » hors du fil principal.
enum PhotoSortie {
    static func charger(_ url: URL?) async -> UIImage? {
        guard let url else { return nil }
        let donnees = await Task.detached { try? Data(contentsOf: url) }.value
        return donnees.flatMap { UIImage(data: $0) }
    }
}

/// Le recto de la carte « Eau calme » (sortie sans prise), au même gabarit que `CarteRectoView` : fenêtre en haut, plaque en bas.
/// La fenêtre montre la photo de soi si le pêcheur en a ajouté une, sinon l'eau calme à l'aube dessinée en SwiftUI.
/// Ni rareté, ni pourcentage, ni classement : seulement la sortie (titre, durée, jour, lieu au département).
struct CarteBredouilleRectoView: View {
    let carte: CarteBredouille
    /// Photo déjà décodée (rendu du partage, aperçu) ; sinon elle est lue depuis `carte.photoURL`.
    var photo: UIImage? = nil
    var inclinaison: CGSize = .zero
    var refletFixe = false
    /// Vignette du classeur : titre et jour seulement.
    var mini = false

    @State private var photoChargee: UIImage?

    private var image: UIImage? { photo ?? photoChargee }
    private var titre: String { image == nil ? "Eau calme" : "Belle sortie" }

    var body: some View {
        CarteCadre(style: .commun, declaree: false, fond: Color(carte: 0xEAF3F1)) {
            GeometryReader { geo in
                carteComplete(geo.size)
            }
        }
        .task(id: carte.photoURL) { if photo == nil { photoChargee = await PhotoSortie.charger(carte.photoURL) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voixOff)
    }

    private var voixOff: String {
        var morceaux = ["Carte \(titre)", Formats.date(carte.debut)]
        if let lieu = carte.lieuFlou, !lieu.isEmpty { morceaux.append(lieu) }
        if let s = carte.dureeSecondes { morceaux.append("sortie de \(Formats.duree(s))") }
        return morceaux.joined(separator: ", ")
    }

    private func carteComplete(_ taille: CGSize) -> some View {
        let w = taille.width, h = taille.height, u = w / 100
        let hauteurPlaque = h * (mini ? 0.28 : 0.40)
        return ZStack(alignment: .topLeading) {
            fenetre(w, h)
            etiquette(u)
            plaque(w, hauteurPlaque, u)
                .frame(width: w, height: hauteurPlaque, alignment: .top)
                .background { PlaqueEauCalme().fill(Color(carte: 0xEAF3F1)) }
                .offset(y: h - hauteurPlaque)
        }
        .frame(width: w, height: h, alignment: .topLeading)
    }

    // MARK: Fenêtre

    private func fenetre(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            EauCalmeFond(avecBouchon: image == nil)
            if let image {
                Color.clear.overlay {
                    Image(uiImage: image).resizable().scaledToFill()
                }
                .clipped()
                // Un voile d'aube léger : la photo reste la vedette, la carte garde son ambiance.
                LinearGradient(colors: [Color(carte: 0xF8DFC6).opacity(0.22), .clear, Color(carte: 0x20677F).opacity(0.18)],
                               startPoint: .top, endPoint: .bottom)
            }
            RefletHolographique(inclinaison: inclinaison, fixe: refletFixe)
                .opacity(image == nil ? 0.9 : 0.6)
        }
        .frame(width: w, height: h)
        .clipped()
    }

    private func etiquette(_ u: CGFloat) -> some View {
        HStack(spacing: 1.4 * u) {
            Image(systemName: "sunrise.fill").font(Police.taille((mini ? 6.5 : 4.4) * u, .heavy))
            if !mini { Text("SORTIE").font(Police.taille(3.2 * u, .heavy)).tracking(0.12 * 3.2 * u) }
        }
        .foregroundStyle(Color(carte: 0x0F3A4B))
        .padding(.horizontal, (mini ? 2.4 : 2.6) * u)
        .padding(.vertical, 1.4 * u)
        .background(Color.white.opacity(0.78), in: Capsule())
        .padding(.top, (mini ? 4 : 5) * u)
        .padding(.leading, 5 * u)
        .accessibilityHidden(true)
    }

    // MARK: Plaque

    @ViewBuilder
    private func plaque(_ w: CGFloat, _ hauteur: CGFloat, _ u: CGFloat) -> some View {
        if mini {
            VStack(alignment: .leading, spacing: 1 * u) {
                Text(titre)
                    .font(Police.taille(11 * u, .black))
                    .foregroundStyle(encre)
                    .lineLimit(1)
                Text(Formats.date(carte.debut))
                    .font(Police.taille(7 * u, .bold))
                    .foregroundStyle(gris)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 9 * u)
            .padding(.horizontal, 7 * u)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0.8 * u) {
                    Text(titre)
                        .font(Police.taille(7.6 * u, .black))
                        .foregroundStyle(encre)
                        .lineLimit(1)
                    Text("Tu y étais, c'est ce qui compte")
                        .font(Police.taille(3.3 * u, .bold))
                        .italic()
                        .foregroundStyle(gris)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 2 * u)
                .overlay(alignment: .bottom) { Rectangle().fill(encre.opacity(0.12)).frame(height: 1) }
                statistiques(u).padding(.top, 2.6 * u)
                Spacer(minLength: 0)
                Text("Pescedex · carte de sortie")
                    .font(Police.taille(2.9 * u, .heavy))
                    .tracking(0.06 * 2.9 * u)
                    .foregroundStyle(gris)
                    .lineLimit(1)
            }
            .padding(.top, 6 * u)
            .padding(.horizontal, 5.5 * u)
            .padding(.bottom, 4 * u)
        }
    }

    private func statistiques(_ u: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 2 * u) {
            if let s = carte.dureeSecondes {
                colonne(Formats.duree(s), "DURÉE", u)
            }
            colonne(Formats.date(carte.debut), "JOUR", u)
            if let lieu = carte.lieuFlou, !lieu.isEmpty {
                colonne(lieu, "LIEU", u)
            }
        }
    }

    private func colonne(_ valeur: String, _ legende: String, _ u: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1.2 * u) {
            Text(valeur)
                .font(Police.taille(4.6 * u, .black))
                .foregroundStyle(encre)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(legende)
                .font(Police.taille(2.9 * u, .heavy))
                .tracking(0.06 * 2.9 * u)
                .foregroundStyle(gris)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var encre: Color { Color(carte: 0x0F1A1C) }
    private var gris: Color { Color(carte: 0x5B6A6E) }
}

/// Plaque du bas : même bord haut incliné que les autres cartes.
private nonisolated struct PlaqueEauCalme: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.07))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
