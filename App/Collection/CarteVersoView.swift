import Core
import SwiftUI
import UIKit

/// Le verso : seulement la photo que le pêcheur a prise, sur toute la carte (Adem, 16 oct. : « on met que la photo uploadée »).
/// Ni date, ni lune, ni rareté, ni consigne, ni conseil.
struct CarteVersoView: View {
    let infos: InfosCarte
    let photo: Data?
    /// Gardé pour les appelants ; « comment la pêcher » s'affiche maintenant dans `FaitsPrise`.
    var emplacements: EmplacementsExternes = .vides

    var body: some View {
        // P25 : fond gris clair de la carte (`.fc.verso`), photo à 2,6 % du bord, coins à 4 % de la largeur.
        CarteCadre(style: infos.style, declaree: infos.prise.estDeclaree, fond: Color(carte: 0xE9EDEB)) {
            GeometryReader { geo in
                let u = geo.size.width / 100
                fondPhoto
                    .clipShape(RoundedRectangle(cornerRadius: 4 * u, style: .continuous))
                    .padding(2.6 * u)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var fondPhoto: some View {
        if let photo, let image = UIImage(data: photo) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .accessibilityLabel("Photo de la prise")
        } else {
            ZStack {
                LinearGradient(colors: infos.style.fond, startPoint: .top, endPoint: .bottom).opacity(0.5)
                VStack(spacing: Espace.s) {
                    Image(systemName: "camera")
                        .font(Police.taille(34))
                        .accessibilityHidden(true)
                    Text(infos.prise.estDeclaree ? "Carte déclarée : pas de photo" : "Pas de photo")
                        .font(Jeton.police(17))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Palette.encreDouce)
                .padding(Espace.l)
            }
        }
    }

    /// Le lieu flou (« La Marne · 94 », jamais le point exact) en gras à gauche, le jour et l'heure à droite.
    private var bande: some View {
        HStack(alignment: .center, spacing: Espace.s) {
            // À brancher : le prénom du pêcheur (« Adem ») ; aucune donnée de profil n'arrive jusqu'ici. Le lieu flou le remplace.
            Text(infos.prise.estDeclaree ? infos.espece.nom : (infos.prise.lieuFlou ?? infos.espece.nom))
                .font(Jeton.police(22, .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Spacer(minLength: 0)
            if !infos.prise.estDeclaree {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(Formats.date(infos.prise.date))
                    Text(Formats.heure(infos.prise.date))
                }
                .font(Jeton.police(12))
                .monospacedDigit()
                .foregroundStyle(Palette.encreDouce)
            }
        }
        .foregroundStyle(Palette.encre)
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Le verso dit « dans les relevés OFB », jamais une promesse de prise.
    var phraseRarete: String {
        let r = infos.rarete
        let zone = infos.departement.map { "du \($0.code)" } ?? "de la zone"
        switch r.niveau {
        case .nonMesuree:
            return "Espèce non suivie par l'OFB : rareté non mesurée."
        case .legendaire:
            let depuis = r.anneeDernierReleve.map { " depuis \($0)" } ?? ""
            return "Rareté dans les relevés de l'Office français de la biodiversité (OFB) \(zone) : aucune pêche ne l'a relevée\(depuis)."
        default:
            let annee = r.anneeDernierReleve.map { ", dernier relevé \($0)" } ?? ""
            var texte = "Rareté dans les relevés de l'Office français de la biodiversité (OFB) \(zone) : relevée dans \(r.nPeches) pêches sur \(r.nTotal)\(annee)."
            if r.echelle == .region {
                texte += " Moins de 20 pêches dans le département : rareté calculée sur la région."
            }
            return texte
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
                        ligne("ruler", [taille, Formats.poids(infos.poids)].compactMap { $0 }.joined(separator: " · "))
                    }
                    // À brancher : l'appât ou le leurre de la prise (« Relâché · leurre souple ») ; la prise ne le garde pas.
                    ligne("water.waves", infos.prise.gardee ? "Gardé" : "Relâché")
                    if let conditions = infos.detail.conditions, let texte = texteConditions(conditions) {
                        ligne("cloud", texte)
                        MarqueAppleWeather()
                    }
                    if let consigne = infos.consigne {
                        ligne("info.circle", consigne + (infos.sourceConsigne.map { " (source : \($0))" } ?? ""))
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
