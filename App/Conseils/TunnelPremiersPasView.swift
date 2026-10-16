import Core
import SwiftUI

/// Tunnel des 3 premières minutes (Adem, 15 oct. 16h), après la question du niveau :
/// des cartes à swiper (gauche : jamais pêché, droite : déjà pêché), puis « pêcher maintenant » ou « choisir un spot ».
/// Chaque droite crée une carte « déclarée » (sans photo) que A range au Pescedex via `declarer`.
struct TunnelPremiersPasView: View {
    let especes: [EspecePechable]
    let maintenant: () -> Date
    /// A range la carte au Pescedex.
    let declarer: (Prise) -> Void
    let pecherMaintenant: () -> Void
    let choisirUnSpot: () -> Void
    let passer: () -> Void

    @State private var index = 0
    @State private var decalage: CGFloat = 0
    @State private var nbDeclarees = 0
    /// Positions déjà déclarées : revenir en arrière puis re-glisser à droite ne crée pas de doublon.
    @State private var declarees: Set<Int> = []

    private let seuil: CGFloat = 100

    var body: some View {
        VStack(spacing: Espace.l) {
            HStack {
                if index > 0 {
                    BoutonRond(role: .retour, action: revenir)
                        .accessibilityLabel("Revenir à la carte d'avant")
                }
                if index < especes.count {
                    Text("\(index + 1) / \(especes.count)")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 36)
                        .background(Palette.surface, in: Capsule())
                }
                Spacer()
            }
            if index < especes.count {
                cartes
                boutons
            } else {
                fin
            }
            // En bas, à portée du pouce ; l'écran de fin a déjà son bouton.
            if index < especes.count {
                Button("Passer", action: passer)
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
            }
        }
        .padding(Espace.bord)
        .background(Palette.fond)
        .accessibilityIdentifier("tunnel-premiers-pas")
    }

    private var cartes: some View {
        let espece = especes[index]
        // À brancher : la rareté de l'espèce dans la zone (maquette : « • Commun » sous le nom) ; absente de ce paramètre.
        return VStack(spacing: Espace.l) {
            Spacer(minLength: 0)
            ImageEspece(nom: espece.image, libelle: espece.nom)
                .frame(maxWidth: .infinity, maxHeight: 260)
            Text(espece.nom)
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(Espace.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l + 6, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.10), radius: 14, y: 6)
        .overlay(alignment: .topLeading) { marque("xmark", visible: decalage < -30, couleur: Palette.encreDouce) }
        .overlay(alignment: .topTrailing) { marque("checkmark", visible: decalage > 30, couleur: Palette.marine) }
        .offset(x: decalage)
        .rotationEffect(.degrees(Double(decalage) / 20))
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

    private func marque(_ icone: String, visible: Bool, couleur: Color) -> some View {
        Image(systemName: icone)
            .font(Police.chiffreMoyen)
            .foregroundStyle(couleur)
            .padding(Espace.l)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(true)
    }

    /// Les deux boutons font la même chose que le glissement (VoiceOver, un toucher).
    private var boutons: some View {
        HStack(spacing: Espace.xl) {
            bouton(icone: "xmark", mot: "Jamais pêché", plein: false) { repondre(dejaPeche: false) }
            bouton(icone: "checkmark", mot: "Déjà pêché", plein: true) { repondre(dejaPeche: true) }
        }
        .padding(.vertical, Espace.l)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
    }

    /// « Non » : rond blanc cerclé, croix marine. « Oui » : rond marine plein, coche blanche (jamais d'orange ici).
    private func bouton(icone: String, mot: String, plein: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Espace.xs) {
                Image(systemName: icone)
                    .font(Police.taille(24, .bold))
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
            Text("\(nbDeclarees)")
                .font(Police.chiffre)
                .foregroundStyle(Palette.encre)
            Label("dans ton Pescedex", systemImage: "square.stack.fill")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            Spacer(minLength: 0)
            gros("Pêcher maintenant", icone: "figure.fishing", plein: true, action: pecherMaintenant)
            gros("Choisir un spot", icone: "mappin.and.ellipse", plein: false, action: choisirUnSpot)
        }
    }

    /// Un seul bouton principal (« Pêcher maintenant »), l'autre est secondaire.
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
