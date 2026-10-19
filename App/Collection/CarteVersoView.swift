import Core
import SwiftUI
import UIKit

/// Le verso de toute carte : la photo de la prise seule, plein cadre, sans aucun texte, bandeau ni pastille (décision d'Adem).
/// Sans photo (carte déclarée, ancienne carte, exemple), le dessin de l'espèce en grand sur le fond de sa rareté, toujours sans texte.
/// Le lieu, la date, la taille et la consigne se lisent sur le recto ou sous la carte (`FaitsPrise`).
struct CarteVersoView: View {
    let infos: InfosCarte
    let photo: Data?
    /// Gardé pour les appelants ; « comment la pêcher » s'affiche dans `FaitsPrise`.
    var emplacements: EmplacementsExternes = .vides

    private var declaree: Bool { infos.prise.estDeclaree }

    var body: some View {
        // Même cadre, même arrondi et même bordure que le recto ; le gris clair ne se voit que si l'image ne couvre pas tout.
        CarteCadre(style: infos.style, declaree: declaree, fond: Color(carte: 0xE9EDEB)) {
            GeometryReader { geo in
                fond(geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(photo == nil ? "Verso de la carte, \(infos.espece.nom)" : "Photo de la prise, \(infos.espece.nom)")
    }

    @ViewBuilder
    private func fond(_ taille: CGSize) -> some View {
        if let photo, let image = UIImage(data: photo) {
            PhotoVersoEntiere(image: image)
        } else {
            ZStack {
                LinearGradient(colors: infos.style.fond, startPoint: .top, endPoint: .bottom)
                if let poisson = UIImage(named: infos.espece.image) {
                    Image(uiImage: poisson)
                        .resizable()
                        .scaledToFit()
                        .frame(width: taille.width * 0.88)
                        .saturation(declaree ? 0.55 : 1)
                        .shadow(color: .black.opacity(0.3), radius: taille.width * 0.01, x: -taille.width * 0.015, y: taille.width * 0.025)
                        .rotationEffect(.degrees(-12))
                }
            }
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
                    if let valeur = Formats.tailleValeur(infos.prise) {
                        ligne("ruler", "\(LibellesCarte.libelleTaille(estimee: infos.prise.mesure == .estimee)) : \(valeur)")
                    }
                    if let valeur = Formats.poidsValeur(infos.poids) {
                        ligne("scalemass", "\(LibellesCarte.poidsEstime) : \(valeur)")
                    }
                    // À brancher : l'appât ou le leurre de la prise (« Relâché · leurre souple ») ; la prise ne le garde pas.
                    ligne("water.waves", infos.prise.gardee ? "Gardé" : "Relâché")
                    // Le bloc météo branché (L12) porte la marque Apple Weather ; sans lui, aucune donnée météo n'est montrée.
                    if let conditions = infos.detail.conditions, let bloc = emplacements.meteoDuDos {
                        bloc(conditions)
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

/// La photo du verso en entier (jamais rognée) : la photo à sa taille, posée sur son propre flou qui remplit le cadre.
struct PhotoVersoEntiere: View {
    let image: UIImage

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .blur(radius: 26)
                    .overlay(Color.black.opacity(0.15))
                    .clipped()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }
}
