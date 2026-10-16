import Core
import SwiftUI
import UIKit

/// Le verso de la carte « Eau calme », au même gabarit que `CarteVersoView` : la photo de soi (sinon l'eau calme), puis le lieu
/// (département ou lieu flou, jamais de coordonnées), le jour, la durée de la sortie, la lune et la météo du départ si on l'a.
struct CarteBredouilleVersoView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var photo: UIImage? = nil

    @State private var photoChargee: UIImage?

    private var image: UIImage? { photo ?? photoChargee }

    var body: some View {
        CarteCadre(style: .commun, declaree: false, fond: Color(carte: 0xE9EDEB)) {
            GeometryReader { geo in
                let u = geo.size.width / 100
                VStack(spacing: 0) {
                    fondPhoto
                        .frame(width: geo.size.width - 5.2 * u, height: 66 * u)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * u, style: .continuous))
                        .padding(.top, 2.6 * u)
                    infos(u)
                        .padding(.horizontal, 5.5 * u)
                        .padding(.top, 3.4 * u)
                        .padding(.bottom, 4.6 * u)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .clipped()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .task(id: carte.photoURL) { if photo == nil { photoChargee = await PhotoSortie.charger(carte.photoURL) } }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var fondPhoto: some View {
        if let image {
            Color.clear.overlay { Image(uiImage: image).resizable().scaledToFill() }
                .clipped()
                .accessibilityLabel("Photo de la sortie")
        } else {
            EauCalmeFond(avecBouchon: true)
        }
    }

    private func infos(_ u: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1.8 * u) {
            Text(image == nil ? "Eau calme" : "Belle sortie")
                .font(Police.taille(5.6 * u, .black))
                .foregroundStyle(encre)
                .lineLimit(1).minimumScaleFactor(0.6)
            if let lieu = carte.lieuFlou, !lieu.isEmpty { ligne("mappin.and.ellipse", lieu, u) }
            ligne("calendar", "\(Formats.date(carte.debut)) · \(Formats.heure(carte.debut))", u)
            if let s = carte.dureeSecondes { ligne("timer", "Sortie de \(Formats.duree(s))", u) }
            ligne("moon", Formats.lune(services.soleil.phaseLune(date: carte.debut)).capitalizedFirst, u)
            if let c = carte.conditions, let meteo = resume(c) { ligne("cloud", meteo, u) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Seulement ce que le relevé porte ; une valeur absente est omise, jamais inventée.
    private func resume(_ c: Conditions) -> String? {
        var m: [String] = []
        if let v = c.ventKmh { m.append("Vent \(Formats.nombre(v, decimales: 0)) km/h") }
        if let p = c.pressionHPa { m.append("\(Formats.nombre(p, decimales: 0)) hPa") }
        if let pluie = c.pluieMm, pluie > 0 { m.append("Pluie \(Formats.nombre(pluie)) mm") }
        return m.isEmpty ? nil : m.joined(separator: " · ")
    }

    private func ligne(_ icone: String, _ texte: String, _ u: CGFloat) -> some View {
        HStack(spacing: 2 * u) {
            Image(systemName: icone)
                .font(Police.taille(3.6 * u))
                .foregroundStyle(Palette.marine)
                .frame(width: 4.6 * u)
                .accessibilityHidden(true)
            Text(texte)
                .font(Police.taille(3.8 * u, .bold))
                .foregroundStyle(encre)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    private var encre: Color { Color(carte: 0x0F1A1C) }
}

private extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
