import Core
import SwiftUI
import UIKit

/// Gris des petits textes d'une carte (`#5B6A6E` dans la maquette).
private let grisCarte = Color(carte: 0x5B6A6E)
/// Encre d'une carte (`#0F1A1C`).
private let encreCarte = Color(carte: 0x0F1A1C)

/// Cadre commun de la carte à collectionner (`.fc` de `fishme-ds.css`) : recto, verso et bredouille ont exactement la même taille.
/// Coins à 6 % de la largeur, ombre portée, filet de 1 pt, et la ligne intérieure (`.in`) : un filet clair, doublé pour les rares.
struct CarteCadre<Contenu: View>: View {
    let style: StyleRarete
    let declaree: Bool
    /// Fond derrière le contenu : la plaque du palier par défaut, gris clair pour le verso.
    var fond: Color? = nil
    @ViewBuilder var contenu: () -> Contenu

    var body: some View {
        GeometryReader { geo in
            let u = geo.size.width / 100
            let forme = RoundedRectangle(cornerRadius: 6 * u, style: .continuous)
            contenu()
                .frame(width: geo.size.width, height: geo.size.height)
                .background(fond ?? style.plaque, in: forme)
                .clipShape(forme)
                .overlay { LigneInterieure(style: style, u: u) }
                .overlay(forme.strokeBorder(Color.black.opacity(0.1), lineWidth: 1))
                .shadow(color: Color.black.opacity(0.32), radius: 4.6 * u, y: 4 * u)
        }
        .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
    }
}

/// `.fc .in` : filet blanc à 2,4 % du bord ; sur les rares (`.fc.r .in`), trois filets (blanc, gris bleu, blanc) à 1,8 %.
private struct LigneInterieure: View {
    let style: StyleRarete
    let u: CGFloat

    var body: some View {
        ZStack {
            if style == .rare {
                let r = 4.4 * u
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
                    .padding(1.8 * u)
                RoundedRectangle(cornerRadius: max(0, r - 1), style: .continuous)
                    .strokeBorder(Color(red: 90 / 255, green: 110 / 255, blue: 125 / 255).opacity(0.55), lineWidth: 1.4)
                    .padding(1.8 * u + 1)
                RoundedRectangle(cornerRadius: max(0, r - 2.4), style: .continuous)
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 1)
                    .padding(1.8 * u + 2.4)
            } else {
                RoundedRectangle(cornerRadius: 4.4 * u, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
                    .padding(2.4 * u)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Le recto (P24 A, planche C02) : la fenêtre du palier avec le centile de taille en haut à gauche et le poisson de profil,
/// puis la plaque du bas (nom et nom latin, Taille, Fréquence, palier, source OFB et rang). Le reflet ne couvre que les rares et les légendaires.
/// Avec `mini`, la vignette du Pescedex (P26 B) : centile, poisson, nom et marque de palier seulement.
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
    /// Vignette du classeur : mêmes éléments que la maquette `.fc.mini`.
    var mini = false
    /// Centile de taille (« 84e » : plus grand que 84 % des prises de l'espèce).
    /// À brancher : aucune table de centiles n'existe dans Core ; sans valeur, la carte affiche « – » à la place du chiffre.
    var centile: Int? = nil

    private var declaree: Bool { infos.prise.estDeclaree }
    private var style: StyleRarete { infos.style }

    var body: some View {
        CarteCadre(style: style, declaree: declaree) {
            GeometryReader { geo in
                carte(geo.size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(infos.texteVoixOff)
    }

    // MARK: Assemblage

    private func carte(_ taille: CGSize) -> some View {
        let w = taille.width
        let h = taille.height
        let u = w / 100
        return ZStack(alignment: .topLeading) {
            fenetre(w, h)
            poisson(w, h, u)
            centileEtLegende(u)
            plaque(w, h, u)
            etiquettes()
        }
        .frame(width: w, height: h, alignment: .topLeading)
    }

    // MARK: Fenêtre

    /// Fond du palier, ondes concentriques, et la finition : vernis (peu commun), reflet holographique (rare, légendaire).
    private func fenetre(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            fondFenetre
            OndesFenetre()
                .opacity(0.3)
            if style == .peuCommun {
                DegradeAngle(angle: 118, arrets: [
                    .init(color: .clear, location: 0.38),
                    .init(color: Color(red: 190 / 255, green: 1, blue: 235 / 255).opacity(0.22), location: 0.47),
                    .init(color: .clear, location: 0.56),
                ])
            }
            if style.aUnReflet && !declaree {
                RefletHolographique(inclinaison: inclinaison, fixe: refletFixe)
            }
        }
        .frame(width: w, height: h)
        .clipped()
    }

    @ViewBuilder
    private var fondFenetre: some View {
        switch style {
        case .commun, .nonMesuree, .peuCommun:
            Rectangle().fill(style.fond[0])
        case .rare:
            DegradeAngle(angle: 160, arrets: [
                .init(color: Color(carte: 0xDCE3E8), location: 0),
                .init(color: Color(carte: 0xAFBCC6), location: 0.45),
                .init(color: Color(carte: 0xC9D2D8), location: 0.60),
                .init(color: Color(carte: 0x8497A3), location: 1),
            ])
        case .legendaire:
            ZStack {
                DegradeAngle(angle: 150, arrets: [
                    .init(color: Color(carte: 0xE3B654), location: 0),
                    .init(color: Color(carte: 0xB8862A), location: 0.5),
                    .init(color: Color(carte: 0xD9A845), location: 1),
                ])
                BulleOr(x: 0.20, y: 0.30, couleur: Color(carte: 0xF6D98A), plein: 0.06, fin: 0.12)
                BulleOr(x: 0.70, y: 0.18, couleur: Color(carte: 0xFBE3A0), plein: 0.05, fin: 0.11)
                BulleOr(x: 0.55, y: 0.60, couleur: Color(carte: 0xF2CF78), plein: 0.07, fin: 0.14)
                BulleOr(x: 0.85, y: 0.70, couleur: Color(carte: 0xE9BD5A), plein: 0.06, fin: 0.12)
            }
        }
    }

    // MARK: Poisson

    private var imageUI: UIImage? { imageDecodee ?? UIImage(named: infos.espece.image) }

    /// Le poisson de profil, tête à droite, incliné de 12 degrés vers le haut, avec son ombre portée.
    private func poisson(_ w: CGFloat, _ h: CGFloat, _ u: CGFloat) -> some View {
        let largeur = w * (mini ? 0.92 : 0.88)
        let rapport: CGFloat = {
            guard let image = imageUI, image.size.height > 0 else { return 2.8 }
            return image.size.width / image.size.height
        }()
        let hauteur = largeur / rapport
        return Group {
            if anime {
                NageView(nomImage: infos.espece.image)
            } else {
                (imageUI.map { Image(uiImage: $0) } ?? Image(infos.espece.image))
                    .resizable()
                    .scaledToFit()
                    .saturation(declaree ? 0.55 : 1)
            }
        }
        .frame(width: largeur, height: hauteur)
        .shadow(color: Color.black.opacity(0.35), radius: 1 * u, x: -1.5 * u, y: 2.5 * u)
        .rotationEffect(.degrees(-12))
        .offset(x: w * (mini ? 0.04 : 0.08), y: h * (mini ? 0.20 : 0.22))
    }

    // MARK: Centile

    /// « 84e » en gros, avec sa légende sur la carte pleine taille. « – » tant que le centile n'est pas connu (et pour une carte déclarée).
    private func centileEtLegende(_ u: CGFloat) -> some View {
        let gros = (mini ? 22 : 16) * u
        let petit = (mini ? 10 : 7) * u
        let valeur: Int? = declaree ? nil : centile
        return ZStack(alignment: .topLeading) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(valeur.map { "\($0)" } ?? "–")
                    .font(Police.taille(gros, .black))
                    .tracking(-0.04 * gros)
                if valeur != nil {
                    Text("e").font(Police.taille(petit, .black))
                }
            }
            .foregroundStyle(style.couleurCentile)
            .fixedSize()
            .frame(height: 0.9 * gros)
            .offset(x: 5.5 * u, y: 4 * u)
            if !mini {
                let pastille = style == .rare || style == .legendaire
                Text("CEN · centile de taille")
                    .font(Police.taille(3 * u, .heavy))
                    .foregroundStyle(style.couleurCentile.opacity(pastille ? 1 : 0.85))
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, pastille ? 1.6 * u : 0)
                    .padding(.vertical, pastille ? 0.8 * u : 0)
                    .background(pastille ? Color.white.opacity(0.75) : Color.clear, in: RoundedRectangle(cornerRadius: 1.4 * u, style: .continuous))
                    .offset(x: (pastille ? 5 : 5.5) * u, y: 19.5 * u)
            }
        }
    }

    // MARK: Plaque du bas

    private func plaque(_ w: CGFloat, _ h: CGFloat, _ u: CGFloat) -> some View {
        let hauteur = h * (mini ? 0.28 : 0.40)
        return Group {
            if mini { plaqueMini(u) } else { plaqueComplete(u) }
        }
        .frame(width: w, height: hauteur, alignment: .top)
        .background { PlaqueInclinee().fill(style.plaque) }
        .offset(y: h - hauteur)
    }

    private func plaqueMini(_ u: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Même police et même taille pour toutes les cartes (Adem, 16 oct.) : jamais de réduction automatique,
            // le nom court sur 2 lignes au plus.
            Text(NomCarte.court(infos.espece.nom))
                .font(Police.taille(11 * u, .black))
                .foregroundStyle(encreCarte)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 2 * u)
            if style != .nonMesuree {
                MarqueRarete(style: style, taille: 11 * u)
            }
        }
        .padding(.top, 9 * u)
        .padding(.horizontal, 7 * u)
    }

    private func plaqueComplete(_ u: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            nomEtLatin(u)
            statistiques(u)
                .padding(.top, 2.8 * u)
            Spacer(minLength: 0)
            if let lieu = lieuEtDate {
                Text(lieu)
                    .font(Police.taille(3.1 * u, .bold))
                    .foregroundStyle(grisCarte)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 1.2 * u)
            }
            pied(u)
        }
        .padding(.top, 6 * u)
        .padding(.horizontal, 5.5 * u)
        .padding(.bottom, 4 * u)
    }

    private func nomEtLatin(_ u: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2.4 * u) {
            Text(NomCarte.court(infos.espece.nom))
                .font(Police.taille(8.4 * u, .black))
                .foregroundStyle(encreCarte)
                .lineLimit(1)
                .layoutPriority(2)
            Text(infos.espece.nomLatin)
                .font(Police.taille(3.2 * u, .bold))
                .italic()
                .foregroundStyle(grisCarte)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 3 * u)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(red: 15 / 255, green: 26 / 255, blue: 28 / 255).opacity(0.12)).frame(height: 1)
        }
    }

    /// « La Marne · 94 · 12 oct. 2026 » : où et quand la prise a été pêchée. Jamais de coordonnées ; rien pour une carte déclarée.
    /// Sur l'image partagée : le département seulement et « mois année ».
    private var lieuEtDate: String? {
        guard !declaree else { return nil }
        let departement = infos.departement.map { "Département \($0.code)" }
        var lieu: String?
        if pourPartage {
            lieu = departement
        } else if let flou = infos.prise.lieuFlou, !flou.isEmpty {
            lieu = flou
        } else {
            lieu = departement
        }
        let date = pourPartage ? Formats.moisAnnee(infos.prise.date) : Formats.date(infos.prise.date)
        return [lieu, date].compactMap { $0 }.joined(separator: " · ")
    }

    /// Taille, Fréquence et le palier : trois colonnes égales, alignées sur leur bas.
    private func statistiques(_ u: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            colonne(valeur: tailleTexte, unite: tailleTexte == "–" ? nil : "cm",
                    legende: legendeTaille, legendeCourte: legendeTailleCourte, u: u)
                .frame(maxWidth: .infinity, alignment: .leading)
            colonne(valeur: frequence.map { "\($0)" } ?? "–", unite: frequence == nil ? nil : "%",
                    legende: LibellesCarte.frequence, legendeCourte: LibellesCarte.frequenceCourt, u: u)
                .frame(maxWidth: .infinity, alignment: .leading)
            palier(u)
                .frame(maxWidth: .infinity)
        }
    }

    /// Le libellé en toutes lettres ; la forme courte seulement si la largeur de la colonne manque.
    private func etiquetteColonne(_ texte: String, u: CGFloat) -> some View {
        Text(texte)
            .font(Police.taille(2.9 * u, .heavy))
            .tracking(0.06 * 2.9 * u)
            .foregroundStyle(grisCarte)
            .lineLimit(1)
    }

    private func colonne(valeur: String, unite: String?, legende: String, legendeCourte: String, u: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1.4 * u) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(valeur)
                    .font(Police.taille(7.4 * u, .black))
                    .monospacedDigit()
                if let unite {
                    Text(" \(unite)").font(Police.taille(3.4 * u, .bold))
                }
            }
            .foregroundStyle(encreCarte)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            ViewThatFits(in: .horizontal) {
                etiquetteColonne(legende, u: u)
                etiquetteColonne(legendeCourte, u: u)
                    .minimumScaleFactor(0.6)
            }
        }
    }

    private func palier(_ u: CGFloat) -> some View {
        VStack(spacing: 1.4 * u) {
            if style != .nonMesuree {
                MarqueRarete(style: style, taille: 6.6 * u)
            }
            Text(style.mot.uppercased())
                .font(Police.taille(2.9 * u, .heavy))
                .tracking(0.06 * 2.9 * u)
                .foregroundStyle(style.couleur)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var tailleTexte: String {
        guard !declaree, let l = infos.prise.longueurCm else { return "–" }
        return Formats.nombre(l, decimales: 0)
    }

    /// « Taille » ; la taille choisie au curseur reste marquée « Taille · estimée ».
    private var tailleEstimee: Bool { infos.prise.mesure == .estimee && tailleTexte != "–" }
    private var legendeTaille: String { LibellesCarte.libelleTaille(estimee: tailleEstimee) }
    private var legendeTailleCourte: String { LibellesCarte.libelleTailleCourt(estimee: tailleEstimee) }

    /// Part des pêches OFB de la zone où l'espèce a été relevée. `nil` sans relevé.
    private var frequence: Int? {
        let r = infos.rarete
        guard style != .nonMesuree, r.nTotal > 0 else { return nil }
        return Int((Double(r.nPeches) / Double(r.nTotal) * 100).rounded())
    }

    /// Chaque chiffre OFB porte son nombre de pêches et l'année du dernier relevé.
    private var sourceOFB: String? {
        let r = infos.rarete
        let zone = infos.departement.map { " dans le \($0.code)" } ?? ""
        let annee = r.anneeDernierReleve.map { " \($0)" } ?? ""
        switch style {
        case .nonMesuree:
            return nil
        case .legendaire:
            let total = r.nTotal > 0 ? "0 pêche sur \(r.nTotal) · " : ""
            return "\(total)jamais relevée ici · OFB\(annee)"
        default:
            let mot = r.nPeches > 1 ? "pêches" : "pêche"
            return "\(r.nPeches) \(mot) sur \(r.nTotal)\(zone) · OFB\(annee)"
        }
    }

    /// Source du chiffre OFB à gauche, rang dans le Pescedex à droite (« déclarée » pour une carte sans photo).
    private func pied(_ u: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let source = sourceOFB {
                Text(source)
                    .font(Police.taille(3 * u, .bold))
                    .foregroundStyle(grisCarte)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Spacer(minLength: 2 * u)
            if let droite = numero {
                Text(droite)
                    .font(.system(size: 3.1 * u, weight: .semibold, design: .monospaced))
                    .foregroundStyle(encreCarte)
                    .lineLimit(1)
            }
        }
    }

    private var numero: String? {
        if declaree { return "déclarée" }
        return infos.rangDansLaZone.map { "\(LibellesCarte.rang) \(String(format: "%03d", $0))" }
    }

    // MARK: Étiquettes

    /// « Déclarée » en haut à droite (P26 B, P28 B) ; « Exemple » sous elle pour la carte d'exemple. Tailles fixes, comme la maquette.
    private func etiquettes() -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            if declaree { etiquette("Déclarée") }
            if infos.prise.exemple { etiquette("Exemple") }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .padding(.top, mini ? 6 : 10)
        .padding(.trailing, mini ? 5 : 10)
    }

    private func etiquette(_ texte: String) -> some View {
        Text(texte)
            .font(Police.taille(11, .heavy))
            .foregroundStyle(Palette.encre)
            .lineLimit(1)
            .padding(.horizontal, mini ? 7 : 8)
            .frame(height: 18)
            .background(Palette.surface, in: Capsule())
    }
}

/// Plaque du bas : bord haut incliné, 0 % à gauche, 7 % de sa hauteur à droite (`clip-path` de `.fc .pl`).
private nonisolated struct PlaqueInclinee: Shape {
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

/// Anneaux de l'eau (`.fc .win::before`) : ellipses centrées à 74 % / 26 %, un trait blanc tous les 15 pt.
struct OndesFenetre: View {
    var body: some View {
        Canvas { contexte, taille in
            guard taille.width > 0 else { return }
            let cx = taille.width * 0.74
            let cy = taille.height * 0.26
            let rapport = taille.height / taille.width
            let rayonMax = 2.0.squareRoot() * taille.width * 0.74
            var r: CGFloat = 14.5
            while r < rayonMax {
                let ellipse = Path(ellipseIn: CGRect(x: cx - r, y: cy - r * rapport, width: r * 2, height: r * 2 * rapport))
                contexte.stroke(ellipse, with: .color(.white.opacity(0.55)), lineWidth: 1)
                r += 15
            }
        }
        .allowsHitTesting(false)
    }
}

/// Une tache d'or de la fenêtre légendaire : `radial-gradient(circle at x y, couleur 0 plein, transparent fin)`.
private struct BulleOr: View {
    let x: CGFloat
    let y: CGFloat
    let couleur: Color
    let plein: CGFloat
    let fin: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let centre = CGPoint(x: x * w, y: y * h)
            // Rayon « farthest-corner » : distance au coin le plus loin.
            let loin = hypot(max(centre.x, w - centre.x), max(centre.y, h - centre.y))
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: couleur, location: 0),
                    .init(color: couleur, location: plein / fin),
                    .init(color: couleur.opacity(0), location: 1),
                ]),
                center: UnitPoint(x: x, y: y), startRadius: 0, endRadius: loin * fin
            )
        }
    }
}

/// Le nom affiché sur une carte : le nom commun court, sans parenthèse ni précision
/// (« Carpe commune (miroir, cuir) » → « Carpe commune », « Black-bass à grande bouche » → « Black-bass »).
nonisolated enum NomCarte {
    private static let raccourcis: [String: String] = [
        "Black-bass à grande bouche": "Black-bass",
        "Black-bass à petite bouche": "Black-bass petite bouche",
        "Perche commune": "Perche",
        "Brème commune": "Brème",
        "Silure glane": "Silure",
        "Chevesne (chevaine)": "Chevesne",
    ]

    static func court(_ nom: String) -> String {
        if let r = raccourcis[nom] { return r }
        var court = nom
        for marque in [" (", ", ", " / "] {
            if let r = court.range(of: marque) { court = String(court[..<r.lowerBound]) }
        }
        let net = court.trimmingCharacters(in: .whitespaces)
        return raccourcis[net] ?? net
    }
}
