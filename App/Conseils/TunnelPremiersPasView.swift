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

    private let seuil: CGFloat = 100

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if index < especes.count {
                    Text("\(index + 1) / \(especes.count)")
                        .font(JetonsConseils.police(.subheadline))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Passer", action: passer)
                    .font(JetonsConseils.police(.body))
                    .frame(minWidth: JetonsConseils.tailleToucher, minHeight: JetonsConseils.tailleToucher)
            }
            if index < especes.count {
                cartes
                boutons
            } else {
                fin
            }
        }
        .padding(16)
        .accessibilityIdentifier("tunnel-premiers-pas")
    }

    private var cartes: some View {
        let espece = especes[index]
        return VStack(spacing: 12) {
            ImageEspece(nom: espece.image, libelle: espece.nom)
                .frame(maxWidth: .infinity, maxHeight: 260)
            Text(espece.nom)
                .font(JetonsConseils.police(.title2))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(JetonsConseils.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 28))
        .overlay(alignment: .topLeading) { marque("xmark", visible: decalage < -30, couleur: JetonsConseils.alerte) }
        .overlay(alignment: .topTrailing) { marque("checkmark", visible: decalage > 30, couleur: JetonsConseils.accent) }
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
            .font(.title.weight(.bold))
            .foregroundStyle(couleur)
            .padding(16)
            .opacity(visible ? 1 : 0)
            .accessibilityHidden(true)
    }

    /// Les deux boutons font la même chose que le glissement (VoiceOver, un toucher).
    private var boutons: some View {
        HStack(spacing: 24) {
            bouton(icone: "xmark", mot: "Jamais pêché", couleur: JetonsConseils.alerte) { repondre(dejaPeche: false) }
            bouton(icone: "checkmark", mot: "Déjà pêché", couleur: JetonsConseils.accent) { repondre(dejaPeche: true) }
        }
    }

    private func bouton(icone: String, mot: String, couleur: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icone)
                    .font(.title2.weight(.bold))
                    .frame(width: 64, height: 64)
                    .background(couleur.opacity(0.14), in: Circle())
                    .foregroundStyle(couleur)
                Text(mot).font(JetonsConseils.police(.caption)).foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mot)
    }

    private var fin: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(JetonsConseils.accent)
                .accessibilityHidden(true)
            Text("\(nbDeclarees)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
            Label("dans ton Pescedex", systemImage: "square.stack.fill")
                .font(JetonsConseils.police(.title3))
            Spacer(minLength: 0)
            gros("Pêcher maintenant", icone: "figure.fishing", plein: true, action: pecherMaintenant)
            gros("Choisir un spot", icone: "mappin.and.ellipse", plein: false, action: choisirUnSpot)
        }
    }

    private func gros(_ mot: String, icone: String, plein: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(mot, systemImage: icone)
                .font(JetonsConseils.police(.headline))
                .frame(maxWidth: .infinity, minHeight: 56)
                .foregroundStyle(plein ? Color.white : JetonsConseils.accent)
                .background(plein ? JetonsConseils.accent : JetonsConseils.accent.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func repondre(dejaPeche: Bool) {
        let espece = especes[index].espece
        if dejaPeche {
            declarer(Prise.declaree(espece: espece, date: maintenant()))
            nbDeclarees += 1
        }
        decalage = 0
        index += 1
    }
}
