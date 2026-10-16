import Core
import SwiftUI

/// L'aquarium dans l'app : un fond océan plein écran où nagent les poissons des cartes obtenues (une par espèce).
/// Un toucher sur un poisson affiche son nom et sa taille, avec un accès à sa carte. Fermer est toujours en haut à gauche.
/// Avec « Réduire les animations », les poissons restent posés et les bulles disparaissent.
struct AquariumView: View {
    let modele: PescedexModele
    var fermer: (() -> Void)? = nil
    var emplacements: EmplacementsExternes = .vides

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var choisi: Emplacement?
    @State private var carteOuverte: Emplacement?
    @State private var photoOuverte: Data?
    @State private var pngOuvert: Data?

    /// Les espèces dont on a une carte, 14 au plus pour que l'eau reste lisible.
    private var poissons: [Emplacement] {
        Array(modele.emplacements.filter { $0.carte != nil }.prefix(14))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("FondAquarium")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                Color(red: 0.02, green: 0.18, blue: 0.32).opacity(0.18)
                if poissons.isEmpty {
                    Text("Ton aquarium est vide. Photographie une prise pour y faire nager ton premier poisson.")
                        .font(Police.corps)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(Espace.xl)
                } else {
                    TimelineView(.animation(paused: reduireAnimations)) { contexte in
                        let t = reduireAnimations ? 0 : contexte.date.timeIntervalSinceReferenceDate
                        ZStack {
                            BullesAquarium(temps: t, taille: geo.size)
                            ForEach(Array(poissons.enumerated()), id: \.element.id) { index, e in
                                PoissonNageant(emplacement: e, index: index, temps: t, zone: geo.size,
                                               selectionne: choisi?.id == e.id) {
                                    withAnimation(.spring(duration: 0.3)) {
                                        choisi = (choisi?.id == e.id) ? nil : e
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                BoutonRond(role: .fermer, action: fermer)
                    .padding(.leading, Espace.l)
                    .padding(.top, geo.safeAreaInsets.top + Espace.s)
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: Espace.s) {
                    if let choisi, let carte = choisi.carte {
                        fiche(choisi, carte: carte)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Text(compteur)
                        .font(Police.detail)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Espace.l)
                        .padding(.vertical, Espace.s)
                        .background(.black.opacity(0.35), in: Capsule())
                }
                .padding(.horizontal, Espace.l)
                .padding(.bottom, geo.safeAreaInsets.bottom + Espace.l)
            }
        }
        .fullScreenCover(item: $carteOuverte) { emplacement in
            if let infos = modele.infos(pour: emplacement) {
                CartePleinEcranView(infos: infos, photo: photoOuverte, emplacements: emplacements, png: pngOuvert) {
                    carteOuverte = nil
                }
            }
        }
    }

    private var compteur: String {
        poissons.count == 1 ? "1 poisson dans ton aquarium" : "\(poissons.count) poissons dans ton aquarium"
    }

    private func fiche(_ e: Emplacement, carte: Prise) -> some View {
        Button {
            Task {
                photoOuverte = await modele.depot.photo(de: carte)
                pngOuvert = await modele.depot.imagePNG(de: carte)
                carteOuverte = e
            }
        } label: {
            HStack(spacing: Espace.m) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.espece.nom)
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                    Text(carte.longueurCm.map { "\(Int($0.rounded())) cm" } ?? "Taille non mesurée")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
                Text("Voir la carte")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
            }
            .padding(Espace.l)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(e.espece.nom), voir la carte")
    }
}

/// Un poisson : va-et-vient doux d'un bord à l'autre, ondulation verticale, il se retourne au bout.
private struct PoissonNageant: View {
    let emplacement: Emplacement
    let index: Int
    let temps: Double
    let zone: CGSize
    let selectionne: Bool
    let toucher: () -> Void

    var body: some View {
        let i = Double(index)
        let largeur: CGFloat = 96 + CGFloat((index * 17) % 5) * 12
        let vitesse = 0.025 + 0.006 * Double(index % 4)
        let phase = i * 0.37
        // Position le long de l'aller-retour : 0 à 1 puis retour.
        let p = (temps * vitesse + phase).truncatingRemainder(dividingBy: 1)
        let triangle = p < 0.5 ? p * 2 : (1 - p) * 2
        let versDroite = p < 0.5
        let marge = largeur / 2 + 8
        let x = marge + (zone.width - 2 * marge) * triangle
        // Bande verticale propre à chaque poisson, hors de la zone de fermeture (haut) et de la fiche (bas).
        let haut = zone.height * 0.16
        let bas = zone.height * 0.66
        let base = haut + (bas - haut) * (Double(index % 7) + 0.5) / 7
        let y = base + sin(temps * 0.9 + i * 1.3) * 14
        let inclinaison = cos(temps * 0.9 + i * 1.3) * 3

        Image(emplacement.espece.image)
            .resizable()
            .scaledToFit()
            .frame(width: largeur)
            .scaleEffect(x: versDroite ? 1 : -1, y: 1)
            .rotationEffect(.degrees(versDroite ? inclinaison : -inclinaison))
            .scaleEffect(selectionne ? 1.15 : 1)
            .shadow(color: .black.opacity(0.25), radius: 6, y: 4)
            .contentShape(Rectangle())
            .onTapGesture(perform: toucher)
            .position(x: x, y: y)
            .accessibilityLabel(emplacement.espece.nom)
            .accessibilityAddTraits(.isButton)
    }
}

private struct BullesAquarium: View {
    let temps: Double
    let taille: CGSize

    var body: some View {
        Canvas { contexte, size in
            for i in 0..<10 {
                let graine = Double(i) * 2.3
                let vitesse = 0.05 + 0.015 * Double(i % 4)
                let avance = (temps * vitesse + graine * 0.31).truncatingRemainder(dividingBy: 1)
                let x = size.width * (0.06 + 0.09 * Double(i)) + sin(temps * 0.8 + graine) * 8
                let y = size.height * (1.02 - avance * 1.05)
                let r = 2.5 + Double(i % 3) * 2
                let cercle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                contexte.stroke(cercle, with: .color(.white.opacity(0.55)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
