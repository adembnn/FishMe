import Core
import SwiftUI
import UIKit

/// Cadre commun : recto et verso, comme toutes les cartes, ont exactement la même taille.
struct CarteCadre<Contenu: View>: View {
    let style: StyleRarete
    let declaree: Bool
    @ViewBuilder var contenu: () -> Contenu

    private static var rayon: CGFloat { Rayon.l + 2 }

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: Self.rayon, style: .continuous)
        contenu()
            .background(Palette.surface, in: forme)
            .clipShape(forme)
            .overlay { filets(forme) }
            .shadow(color: Palette.encre.opacity(0.22), radius: 14, y: 8)
            .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
    }

    @ViewBuilder
    private func filets(_ forme: RoundedRectangle) -> some View {
        if declaree {
            // Carte déclarée : cadre en tirets, jamais plein.
            forme.strokeBorder(Palette.commun, style: StrokeStyle(lineWidth: 3, dash: [9, 6]))
        } else {
            ZStack {
                ForEach(0..<style.filets, id: \.self) { i in
                    RoundedRectangle(cornerRadius: Self.rayon - CGFloat(i) * 4, style: .continuous)
                        .strokeBorder(i % 2 == 0 ? style.couleur : Palette.surface, lineWidth: 3)
                        .padding(CGFloat(i) * 4)
                }
            }
        }
    }
}

/// Le recto (piste « Plans ») : le poisson en grand sur son fond de rareté, son nom, sa taille, la fréquence OFB, la rareté,
/// puis la source du chiffre et la date. Le reflet holographique ne couvre que les rares et les légendaires.
struct CarteRectoView: View {
    let infos: InfosCarte
    /// Vrai seulement sur la carte ouverte en plein écran : le poisson nage.
    var anime = false
    var inclinaison: CGSize = .zero
    var refletFixe = false
    /// Image déjà décodée (rendu du partage) : évite le fournisseur d'images asynchrone d'`ImageRenderer`, qui peut expirer.
    var imageDecodee: UIImage? = nil
    /// Image partagée : ni rivière, ni jour exact (le département et « mois année » suffisent).
    var pourPartage = false

    var body: some View {
        CarteCadre(style: infos.style, declaree: infos.prise.estDeclaree) {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    illustration
                    bas
                }
                if infos.style.aUnReflet && !infos.prise.estDeclaree {
                    RefletHolographique(inclinaison: inclinaison, fixe: refletFixe)
                        .clipShape(RoundedRectangle(cornerRadius: Rayon.l + 2, style: .continuous))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(infos.texteVoixOff)
    }

    /// La fenêtre : fond de rareté, ondes concentriques, poisson de profil (il nage une fois la carte ouverte).
    /// Le bord bas est incliné, comme sur la maquette.
    private var illustration: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(colors: infos.style.fond, startPoint: .top, endPoint: .bottom)
            OndesFenetre().stroke(.white.opacity(0.12), lineWidth: 1)
            if anime {
                NageView(nomImage: infos.espece.image)
                    .padding(.bottom, 18)
            } else {
                (imageDecodee.map { Image(uiImage: $0) } ?? Image(infos.espece.image))
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, Espace.m)
                    .padding(.bottom, Espace.xl)
                    .saturation(infos.prise.estDeclaree ? 0.35 : 1)
            }
            // À brancher : le centile de taille (« 84e », gros chiffre blanc en haut à gauche avec « CEN · centile de taille »).
            // Aucune donnée de centile n'existe encore dans Core ; rien n'est affiché tant qu'elle manque. Même chose pour le badge « Trophée ».
            VStack(alignment: .trailing, spacing: 6) {
                if infos.prise.estDeclaree { etiquette("Déclarée") }
                if infos.prise.exemple { etiquette("Exemple") }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(Espace.m)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .clipShape(FenetreInclinee())
        .layoutPriority(1)
    }

    private func etiquette(_ texte: String) -> some View {
        Text(texte)
            .font(Jeton.police(12))
            .padding(.horizontal, Espace.s)
            .padding(.vertical, Espace.xs)
            .background(Palette.surface, in: Capsule())
            .foregroundStyle(Palette.encre)
    }

    private var bas: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            HStack(alignment: .firstTextBaseline, spacing: Espace.s) {
                Text(infos.espece.nom)
                    .font(Jeton.police(30, .heavy))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(infos.espece.nomLatin)
                    .font(Jeton.police(13))
                    .italic()
                    .foregroundStyle(Palette.encreDouce)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Divider().overlay(Palette.filet)
            statistiques
            Spacer(minLength: 0)
            pied
        }
        .foregroundStyle(Palette.encre)
        .padding(.horizontal, Espace.l)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.m)
        .frame(height: 190)
    }

    private var statistiques: some View {
        HStack(alignment: .top, spacing: Espace.l) {
            if let l = infos.prise.longueurCm {
                colonne(Formats.nombre(l, decimales: 0), unite: "cm",
                        legende: infos.prise.mesure == .estimee ? "TAILLE ESTIMÉE" : "TAILLE")
            }
            if let pourcent = frequence {
                colonne("\(pourcent)", unite: "%", legende: "FRÉQUENCE")
            }
            Spacer(minLength: 0)
            if infos.style != .nonMesuree {
                VStack(spacing: 4) {
                    BadgeRarete(style: infos.style, taille: 26)
                    Text(infos.style.mot.uppercased())
                        .font(Jeton.police(11))
                        .foregroundStyle(infos.style.couleur)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func colonne(_ valeur: String, unite: String, legende: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(valeur).font(Jeton.police(26, .heavy)).monospacedDigit()
                Text(unite).font(Jeton.police(13)).foregroundStyle(Palette.encreDouce)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            Text(legende).font(Jeton.police(11)).foregroundStyle(Palette.encreDouce)
        }
    }

    /// Part des pêches OFB de la zone où l'espèce a été relevée. `nil` sans relevé.
    private var frequence: Int? {
        let r = infos.rarete
        guard infos.style != .nonMesuree, r.nTotal > 0 else { return nil }
        return Int((Double(r.nPeches) / Double(r.nTotal) * 100).rounded())
    }

    /// Chaque chiffre OFB porte son nombre de pêches et l'année du dernier relevé.
    private var sourceOFB: String? {
        let r = infos.rarete
        let zone = infos.departement.map { " dans le \($0.code)" } ?? ""
        switch infos.style {
        case .nonMesuree: return nil
        case .legendaire:
            let depuis = r.anneeDernierReleve.map { " · dernier relevé \($0)" } ?? ""
            return "Jamais relevée\(zone) · OFB\(depuis)"
        default:
            let annee = r.anneeDernierReleve.map { " · dernier relevé \($0)" } ?? ""
            let mot = r.nPeches > 1 ? "pêches" : "pêche"
            return "\(r.nPeches) \(mot) sur \(r.nTotal)\(zone) · OFB\(annee)"
        }
    }

    /// Source du chiffre OFB à gauche, rang dans le Pescedex à droite.
    private var pied: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let source = sourceOFB {
                Text(source)
                    .font(Jeton.police(12))
                    .foregroundStyle(Palette.encreDouce)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            Spacer(minLength: 0)
            if let rang = infos.rangDansLaZone {
                Text("n° \(String(format: "%03d", rang))")
                    .font(Jeton.police(12))
                    .monospaced()
                    .foregroundStyle(Palette.encre)
            }
        }
    }
}

/// Bord bas de la fenêtre : plus haut à gauche qu'à droite (maquette P24).
private nonisolated struct FenetreInclinee: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 16))
        p.closeSubpath()
        return p
    }
}

/// Cercles concentriques de l'eau, centrés à droite du poisson.
private nonisolated struct OndesFenetre: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.minX + rect.width * 0.7, y: rect.minY + rect.height * 0.5)
        var r: CGFloat = 16
        while r < rect.width * 1.1 {
            p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
            r += 16
        }
        return p
    }
}
