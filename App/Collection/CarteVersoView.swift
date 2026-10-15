import Core
import SwiftUI
import UIKit

/// Le verso : la vraie photo de la prise en plein cadre, puis une bande courte (rareté OFB, consigne, heure, lune, durée, météo).
struct CarteVersoView: View {
    let infos: InfosCarte
    let photo: Data?
    /// Durée de la session d'où vient la prise, si elle en vient.
    var emplacements: EmplacementsExternes = .vides

    var body: some View {
        CarteCadre(style: infos.style, declaree: infos.prise.estDeclaree) {
            ZStack(alignment: .bottom) {
                fondPhoto
                bande
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
                Text(infos.prise.estDeclaree ? "Carte déclarée : pas de photo" : "Pas de photo")
                    .font(Jeton.police(17))
                    .foregroundStyle(Jeton.encre)
                    .padding(.bottom, 160)
            }
        }
    }

    private var bande: some View {
        VStack(alignment: .leading, spacing: 6) {
            if infos.prise.estDeclaree {
                Text("Tu as déclaré l'avoir déjà pêché : cette carte n'a ni photo, ni taille, ni lieu.")
                    .font(Jeton.police(14, .semibold))
            } else {
                Text(phraseRarete).font(Jeton.police(14, .semibold))
                if let consigne = infos.consigne {
                    Text(consigne + (infos.sourceConsigne.map { " (source : \($0))" } ?? ""))
                        .font(Jeton.police(14))
                }
                Text(ligneMoment).font(Jeton.police(13, .semibold)).foregroundStyle(Jeton.encreDouce)
                meteo
            }
            if let comment = emplacements.commentLaPecher {
                comment(infos.prise.espece)
            }
        }
        .foregroundStyle(Jeton.encre)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
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
            return "Rareté dans les relevés OFB \(zone) : aucune pêche OFB ne l'a relevée\(depuis)."
        default:
            let annee = r.anneeDernierReleve.map { ", dernier relevé \($0)" } ?? ""
            var texte = "Rareté dans les relevés OFB \(zone) : relevée dans \(r.nPeches) pêches sur \(r.nTotal)\(annee)."
            if r.echelle == .region {
                texte += " Moins de 20 pêches dans le département : rareté calculée sur la région."
            }
            return texte
        }
    }

    private var ligneMoment: String {
        var morceaux = [Formats.heure(infos.prise.date), Formats.lune(infos.lune)]
        if let s = infos.detail.dureeSecondes { morceaux.append("session de \(Formats.duree(s))") }
        return morceaux.joined(separator: " · ")
    }

    @ViewBuilder
    private var meteo: some View {
        if let conditions = infos.detail.conditions {
            VStack(alignment: .leading, spacing: 4) {
                if let slot = emplacements.meteoDuDos {
                    slot(conditions)
                } else {
                    BlocMeteoSimple(conditions: conditions)
                }
                MarqueAppleWeather()
            }
        }
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
        .font(Jeton.police(13, .semibold))
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
                .font(Jeton.police(12, .semibold))
            if let url = URL(string: "https://weatherkit.apple.com/legal-attribution.html") {
                Link("Autres sources de données", destination: url)
                    .font(Jeton.police(12, .semibold))
                    .frame(minHeight: Jeton.zoneTactile)
            }
        }
    }
}
