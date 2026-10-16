import Core
import SwiftUI
import UIKit

/// Le verso de toute carte (prise réelle, déclarée, exemple, sans photo) : la photo de la prise (sinon l'espèce), puis où (département ou
/// lieu flou, jamais de coordonnées), quand, la taille et le poids estimé si connus, la consigne et sa source. Une valeur absente est omise.
struct CarteVersoView: View {
    let infos: InfosCarte
    let photo: Data?
    /// Gardé pour les appelants ; « comment la pêcher » s'affiche dans `FaitsPrise`.
    var emplacements: EmplacementsExternes = .vides

    private var declaree: Bool { infos.prise.estDeclaree }

    var body: some View {
        // Fond gris clair de la carte (`.fc.verso`) ; tailles en pourcentage de la largeur, comme le recto.
        CarteCadre(style: infos.style, declaree: declaree, fond: Color(carte: 0xE9EDEB)) {
            GeometryReader { geo in
                let u = geo.size.width / 100
                VStack(spacing: 0) {
                    fondPhoto(u)
                        .frame(width: geo.size.width - 5.2 * u, height: 66 * u)
                        .clipShape(RoundedRectangle(cornerRadius: 4 * u, style: .continuous))
                        .padding(.top, 2.6 * u)
                    infosPrise(u)
                        .padding(.horizontal, 5.5 * u)
                        .padding(.top, 3.4 * u)
                        .padding(.bottom, 4.6 * u)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .clipped()
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Photo

    @ViewBuilder
    private func fondPhoto(_ u: CGFloat) -> some View {
        if let photo, let image = UIImage(data: photo) {
            Color.clear.overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .accessibilityLabel("Photo de la prise")
        } else {
            ZStack {
                LinearGradient(colors: infos.style.fond, startPoint: .top, endPoint: .bottom).opacity(0.5)
                VStack(spacing: 2 * u) {
                    if let poisson = UIImage(named: infos.espece.image) {
                        Image(uiImage: poisson)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60 * u, height: 30 * u)
                            .saturation(declaree ? 0.55 : 1)
                            .accessibilityHidden(true)
                    }
                    Text(declaree ? "Carte déclarée : pas de photo" : "Pas de photo")
                        .font(Police.taille(4.4 * u, .heavy))
                        .foregroundStyle(Palette.encreDouce)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4 * u)
                }
            }
        }
    }

    // MARK: Infos

    /// Le lieu flou tel qu'enregistré (« La Marne · 94 »), sinon le département ; jamais un point exact.
    private var lieu: String? {
        if let flou = infos.prise.lieuFlou, !flou.isEmpty { return flou }
        return infos.departement.map { "Département \($0.code)" }
    }

    private func infosPrise(_ u: CGFloat) -> some View {
        let encre = Color(carte: 0x0F1A1C)
        let gris = Color(carte: 0x5B6A6E)
        return VStack(alignment: .leading, spacing: 1.8 * u) {
            Text(infos.espece.nom)
                .font(Police.taille(5.6 * u, .black))
                .foregroundStyle(encre)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
            if declaree {
                Text("Tu l'as déjà pêché : cette carte n'a ni photo, ni taille, ni date.")
                    .font(Police.taille(3.6 * u, .bold))
                    .foregroundStyle(gris)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            } else {
                ligne("mappin.and.ellipse", lieu ?? "Lieu non renseigné", u: u)
                ligne(
                    "calendar", "\(Formats.date(infos.prise.date)) · \(Formats.heure(infos.prise.date))", u: u
                )
                if let taille = Formats.taille(infos.prise) {
                    ligne(
                        "ruler",
                        [taille, Formats.poids(infos.poids)].compactMap { $0 }.joined(separator: " · "), u: u)
                }
                if let consigne = infos.consigne {
                    Text(consigne + (infos.sourceConsigne.map { " (source : \($0))" } ?? ""))
                        .font(Police.taille(3 * u, .semibold))
                        .foregroundStyle(gris)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 0.6 * u)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ligne(_ icone: String, _ texte: String, u: CGFloat) -> some View {
        HStack(spacing: 2 * u) {
            Image(systemName: icone)
                .font(Police.taille(3.6 * u))
                .foregroundStyle(Palette.marine)
                .frame(width: 4.6 * u)
                .accessibilityHidden(true)
            Text(texte)
                .font(Police.taille(3.8 * u, .bold))
                .foregroundStyle(Color(carte: 0x0F1A1C))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

/// Sous la carte retournée : trois lignes à icône (taille et poids estimé, relâché ou gardé, conditions),
/// puis la consigne et « comment la pêcher » si on les a. Chaque valeur absente est omise, jamais inventée.
struct FaitsPrise: View {
    let infos: InfosCarte
    var emplacements: EmplacementsExternes = .vides

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if infos.prise.estDeclaree {
                    Text("Tu as déclaré l'avoir déjà pêché : cette carte n'a ni photo, ni taille, ni lieu.")
                        .font(Police.corps)
                        .multilineTextAlignment(.center)
                } else {
                    if let taille = Formats.taille(infos.prise) {
                        ligne(
                            "ruler",
                            [taille, Formats.poids(infos.poids)].compactMap { $0 }.joined(separator: " · "))
                    }
                    // À brancher : l'appât ou le leurre de la prise (« Relâché · leurre souple ») ; la prise ne le garde pas.
                    ligne("water.waves", infos.prise.gardee ? "Gardé" : "Relâché")
                    if let conditions = infos.detail.conditions, let texte = texteConditions(conditions) {
                        ligne("cloud", texte)
                        MarqueAppleWeather()
                    }
                    if let consigne = infos.consigne {
                        ligne(
                            "info.circle", consigne + (infos.sourceConsigne.map { " (source : \($0))" } ?? "")
                        )
                        .font(Police.detail)
                    }
                }
                if let comment = emplacements.commentLaPecher {
                    comment(infos.prise.espece)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Espace.bord)
        }
        .scrollIndicators(.hidden)
    }

    private func ligne(_ icone: String, _ texte: String) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: icone)
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            Text(texte)
                .multilineTextAlignment(.leading)
        }
        .font(Police.corps)
        .foregroundStyle(Palette.encre)
        .frame(maxWidth: .infinity)
    }

    /// « Vent 14 km/h · Rivière niveau normal » : seulement ce que la prise a gardé.
    private func texteConditions(_ c: Conditions) -> String? {
        var morceaux: [String] = []
        if let v = c.ventKmh { morceaux.append("Vent \(Formats.nombre(v, decimales: 0)) km/h") }
        switch c.etatRiviere {
        case .normal: morceaux.append("Rivière niveau normal")
        case .haut: morceaux.append("Rivière niveau haut")
        case .crue: morceaux.append("Rivière en crue")
        case .inconnu: break
        }
        return morceaux.isEmpty ? nil : morceaux.joined(separator: " · ")
    }
}

/// Valeurs relevées au moment de la prise, chacune avec son heure. Une valeur absente n'est jamais inventée.
struct BlocMeteoSimple: View {
    let conditions: Conditions

    var body: some View {
        let heure = Formats.heure(conditions.heure)
        VStack(alignment: .leading, spacing: 2) {
            if let v = conditions.ventKmh { ligne("Vent \(Formats.nombre(v, decimales: 0)) km/h", heure) }
            if let p = conditions.pressionHPa {
                ligne("Pression \(Formats.nombre(p, decimales: 0)) hPa\(tendance)", heure)
            }
            if let pluie = conditions.pluieMm { ligne("Pluie \(Formats.nombre(pluie)) mm", heure) }
            if conditions.etatRiviere != .inconnu { ligne("Rivière : \(etat)", heure) }
        }
        .font(Jeton.police(13))
    }

    private var tendance: String {
        guard let t = conditions.tendancePressionHPa6h else { return "" }
        let fleche = t < 0 ? "↘" : (t > 0 ? "↗" : "→")
        return " \(fleche) \(Formats.nombre(t, decimales: 0)) en 6 h"
    }

    private var etat: String {
        switch conditions.etatRiviere {
        case .normal: return "niveau normal"
        case .haut: return "niveau haut"
        case .crue: return "crue"
        case .inconnu: return "inconnu"
        }
    }

    private func ligne(_ texte: String, _ heure: String) -> some View {
        Text("\(texte) · \(heure)")
    }
}

/// Marque Apple Weather et lien légal, obligatoires sous toute donnée WeatherKit.
struct MarqueAppleWeather: View {
    var body: some View {
        HStack(spacing: 8) {
            Label("Apple Weather", systemImage: "applelogo")
                .font(Jeton.police(12))
            if let url = URL(string: "https://weatherkit.apple.com/legal-attribution.html") {
                Link("Autres sources de données", destination: url)
                    .font(Jeton.police(12))
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
    }
}
