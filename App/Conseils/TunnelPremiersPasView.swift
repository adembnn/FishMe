import Core
import SwiftUI

/// Tunnel des 3 premières minutes (Adem, 15 oct. 16h), après la question du niveau :
/// des cartes à swiper (gauche : jamais pêché, droite : déjà pêché), puis un seul bouton « Voir mon spot » (16 oct. : il ne démarre jamais la session).
/// Chaque droite crée une carte « déclarée » (sans photo) que A range au Pescedex via `declarer`.
struct TunnelPremiersPasView: View {
    let especes: [EspecePechable]
    let maintenant: () -> Date
    /// A range la carte au Pescedex.
    let declarer: (Prise) -> Void
    /// Plus utilisé depuis le 16 oct. (le swipe ne démarre jamais la session) ; le paramètre reste pour ne pas casser l'appelant.
    let pecherMaintenant: () -> Void
    /// Repli de « Voir mon spot » quand `voirMonSpot` n'est pas fourni.
    let choisirUnSpot: () -> Void
    /// Plus de bouton « Passer » à l'écran (la maquette n'en a pas) ; le paramètre reste pour ne pas casser l'appelant.
    let passer: () -> Void
    /// Rareté de l'espèce dans la zone, affichée sous le nom quand elle est fournie (libellé et couleur de rareté).
    var rarete: (EspecePechable) -> (libelle: String, couleur: Color)? = { _ in nil }
    /// « Voir mon spot » : la racine ferme le swipe, ouvre l'onglet Carte et demande le vol vers le spot.
    var voirMonSpot: (() -> Void)? = nil

    @State private var index = 0
    @State private var decalage: CGFloat = 0
    @State private var nbDeclarees = 0
    /// Positions déjà déclarées : revenir en arrière puis re-glisser à droite ne crée pas de doublon.
    @State private var declarees: Set<Int> = []

    private let seuil: CGFloat = 100

    var body: some View {
        Group {
            if index < especes.count {
                // Maquette P02-A : le compteur en verre en haut, les deux cartes penchées, la feuille de deux boutons ronds en bas.
                ZStack {
                    cartes
                    VStack(spacing: 0) {
                        compteur
                        Spacer(minLength: 0)
                        panneau
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
            } else {
                fin
                    .padding(Espace.bord)
            }
        }
        .background(Palette.fond.ignoresSafeArea())
        // À brancher : la maquette pose ces cartes sur la carte de la zone, floutée (blur 5, saturation .6, voile .62) ;
        // l'app n'a pas d'image de carte à cet endroit, le fond reste uni.
        .presentationBackground(Palette.fond)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .accessibilityIdentifier("tunnel-premiers-pas")
    }

    /// « 4 / 12 » en pastille de verre centrée en haut (36 pt de haut, texte de 15 en encre) : aucun autre élément.
    private var compteur: some View {
        Text("\(index + 1) / \(especes.count)")
            .font(Police.detail)
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, Espace.l)
            .frame(height: 36)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
            .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Espace.bord)
            .accessibilityLabel("Carte \(index + 1) sur \(especes.count)")
    }

    private var cartes: some View {
        let espece = especes[index]
        return ZStack {
            // La carte d'en dessous : 298 × 400, coins 32, teinte « tuile », penchée de 4°, décalée de (10, 10).
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Palette.tuile)
                .frame(width: 298, height: 400)
                .rotationEffect(.degrees(4))
                .offset(x: 10, y: 10)
            // La carte du dessus : 318 × 400, coins 32, penchée de -2,5°, ombre douce ; poisson 270 × 180, nom en 34, rareté.
            VStack(spacing: 10) {
                ImageEspece(nom: espece.image, libelle: espece.nom)
                    .frame(width: 270, height: 180)
                Text(espece.nom)
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                    .padding(.top, 14)
                if let rareté = rarete(espece) {
                    HStack(spacing: 5) {
                        Image(systemName: Self.forme(rareté.libelle))
                            .font(Police.taille(11, .bold))
                        Text(rareté.libelle)
                            .font(Police.legende)
                    }
                    .foregroundStyle(rareté.couleur)
                }
            }
            .frame(width: 318, height: 400)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Palette.encre.opacity(0.35), radius: 20, y: 14)
            .overlay(alignment: .topLeading) { marque("xmark", visible: decalage < -30, couleur: Palette.encreDouce) }
            .overlay(alignment: .topTrailing) { marque("checkmark", visible: decalage > 30, couleur: Palette.marine) }
            .offset(x: decalage)
            .rotationEffect(.degrees(-2.5 + Double(decalage) / 20))
            .gesture(
                DragGesture()
                    .onChanged { decalage = $0.translation.width }
                    .onEnded { valeur in
                        if valeur.translation.width > seuil {
                            repondre(dejaPeche: true)
                        } else if valeur.translation.width < -seuil {
                            repondre(dejaPeche: false)
                        } else {
                            withAnimation(.spring) { decalage = 0 }
                        }
                    }
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(espece.nom)
        }
        // Les cartes sont centrées à 340 pt du haut de l'écran (maquette : 140 + 400 / 2).
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 189)
    }

    /// La forme de la rareté (le niveau se lit sans la couleur) : rond, hexagone, losange, étoile.
    private static func forme(_ libelle: String) -> String {
        switch libelle.lowercased() {
        case "peu commun": "hexagon.fill"
        case "rare": "diamond.fill"
        case "légendaire", "legendaire": "star.fill"
        default: "circle.fill"
        }
    }

    private func marque(_ icone: String, visible: Bool, couleur: Color) -> some View {
        Image(systemName: icone)
            .font(Police.chiffreMoyen)
            .foregroundStyle(couleur)
            .padding(Espace.l)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(true)
    }

    /// La feuille du bas (maquette : 8 pt des bords, coins 38, poignée, deux boutons ronds de 68 pt, mot dessous).
    private var panneau: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Palette.filet)
                .frame(width: 36, height: 5)
                .padding(.top, 7)
                .padding(.bottom, 12)
            HStack(alignment: .top) {
                Spacer()
                bouton(icone: "xmark", mot: "Jamais pêché", plein: false) { repondre(dejaPeche: false) }
                Spacer()
                bouton(icone: "checkmark", mot: "Déjà pêché", plein: true) { repondre(dejaPeche: true) }
                Spacer()
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    /// « Non » : rond blanc cerclé, croix marine. « Oui » : rond marine plein, coche blanche (jamais d'orange ici).
    private func bouton(icone: String, mot: String, plein: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Espace.s) {
                Image(systemName: icone)
                    .font(Police.taille(24, .heavy))
                    .frame(width: 68, height: 68)
                    .background(plein ? Palette.marine : Palette.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.filet, lineWidth: plein ? 0 : 1))
                    .foregroundStyle(plein ? Palette.surMarine : Palette.marine)
                Text(mot).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mot)
    }

    private var fin: some View {
        VStack(spacing: Espace.l) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .font(Police.taille(56, .bold))
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            if nbDeclarees > 0 {
                Text("\(nbDeclarees)")
                    .font(Police.chiffre)
                    .foregroundStyle(Palette.encre)
                Label("dans ton Pescedex", systemImage: "square.stack.fill")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
            } else {
                Text("Pas encore de carte")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
            }
            Spacer(minLength: 0)
            gros("Voir mon spot", icone: "mappin.and.ellipse", plein: true, action: voirMonSpot ?? choisirUnSpot)
        }
    }

    /// Un seul bouton principal (« Voir mon spot »).
    @ViewBuilder
    private func gros(_ mot: String, icone: String, plein: Bool, action: @escaping () -> Void) -> some View {
        if plein {
            Button(action: action) { Label(mot, systemImage: icone) }
                .buttonStyle(.principal)
        } else {
            Button(action: action) { Label(mot, systemImage: icone) }
                .buttonStyle(.secondaire)
        }
    }

    private func repondre(dejaPeche: Bool) {
        let espece = especes[index].espece
        if dejaPeche && !declarees.contains(index) {
            declarer(Prise.declaree(espece: espece, date: maintenant()))
            declarees.insert(index)
            nbDeclarees = declarees.count
        }
        decalage = 0
        index += 1
    }

    /// Revient sur la carte d'avant. Une carte déjà rangée au Pescedex y reste : le tunnel n'a pas de moyen de la retirer.
    private func revenir() {
        guard index > 0 else { return }
        decalage = 0
        index -= 1
    }
}
