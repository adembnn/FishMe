import Core
import SwiftUI

// L'aquarium dans l'app : LA MÊME scène que le widget « Mon aquarium » (WidgetAquarium/VuesAquariumWidget.swift,
// `CoucheNage`), en plein écran et animée en continu.
//
// Rien n'est copié : le dossier WidgetAquarium/ est déjà dans la cible BuildChallenge (dossier synchronisé,
// seul PoissonsWidget.xcassets en est exclu). On réutilise donc directement, sans second dessin :
//   - les fonds `fond-grand` (FondsWidget.xcassets) et les images `<espèce>-nage-N` / `-lacet-…` (NagePoissons.xcassets) ;
//   - `NageWidget.placements` / `traversees` / `melange` (taille, trajectoires en perspective, fondu des lacets) ;
//   - `PoissonVivant` et `ImagePoisson` (choix des images, sens, retombée sans rendu 3D) ;
//   - `HorlogeAnimation` (boucle de 10 s à 16 images par seconde).
// Différence forcée : le widget empile 160 copies démasquées par des chronos (il n'a pas d'horloge) ; ici une
// `TimelineView` choisit directement l'image de la boucle (`HorlogeAnimation.imageVisible`). Même boucle, mêmes poses.
// Une espèce sans rendu : comme le widget, l'image fixe si elle existe, sinon l'icône de poisson blanche.

/// Combien de poissons nagent à l'écran (le widget en montre 5 au plus : ici l'écran est plus grand).
private let poissonsAffiches = 8
/// Largeur d'un poisson en part de la largeur de l'écran (avant son échelle) : la valeur du widget grand format.
private let partPoisson = 0.32

struct AquariumView: View {
    let modele: PescedexModele
    var fermer: (() -> Void)? = nil
    var emplacements: EmplacementsExternes = .vides

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var choisi: Emplacement?
    @State private var carteOuverte: Emplacement?
    @State private var photoOuverte: Data?
    @State private var pngOuvert: Data?
    @State private var nageurs: [Nageur] = []
    @State private var dateOuverture = Date()

    /// Les espèces dont on a une carte, les plus rares d'abord (même ordre que le fichier du widget).
    private var poissons: [Emplacement] {
        Array(modele.emplacements.filter { $0.carte != nil }
            .sorted { niveau($0) > niveau($1) }
            .prefix(poissonsAffiches))
    }

    /// 0 commun … 3 légendaire : la même table que `publierAquarium` (RootView).
    private func niveau(_ e: Emplacement) -> Int {
        switch e.rarete.niveau {
        case .commun, .nonMesuree: 0
        case .peuCommun: 1
        case .rare: 2
        case .legendaire: 3
        }
    }

    /// Un poisson prêt à nager : comme `CoucheNage.Nageur` du widget, plus l'emplacement touché.
    struct Nageur: Identifiable {
        let id: String
        let slug: String
        let largeur: CGFloat
        let cycle: Bool
        let pas: Int
        let angles: [Int]
        let poses: [NageWidget.PoseNage]
    }

    /// Ce qui change la scène : les espèces affichées, la taille de l'écran, le créneau de 20 minutes.
    private struct Cle: Equatable {
        let ids: [String]
        let taille: CGSize
        let creneau: Int
    }

    /// Une boucle de 90 s (le widget boucle sur 10 s) : dans l'app on se pose et on regarde, les poissons passent doucement,
    /// environ 30 s pour traverser l'écran. Mêmes trajectoires, mêmes poses, juste étalées dans le temps.
    private static let dureeDeLaBoucle: TimeInterval = 90
    private static let nombreDePoses = Int(dureeDeLaBoucle) * HorlogeAnimation.imagesParSeconde

    /// Zone sûre du haut de la fenêtre (îlot dynamique, barre d'état) : `geo.safeAreaInsets` vaut 0 quand l'écran l'ignore.
    private static var hautDeLaFenetre: CGFloat {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Le fond du widget (eau, plantes, galets) : rendu en 3D, sans poissons.
                Image("fond-grand")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                if poissons.isEmpty {
                    Text("Ton aquarium est vide. Photographie une prise pour y faire nager ton premier poisson.")
                        .font(Police.corps)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(Espace.xl)
                } else {
                    scene(taille: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .task(id: Cle(ids: poissons.map(\.id), taille: geo.size, creneau: creneau(dateOuverture))) {
                nageurs = fabriquer(taille: geo.size)
            }
            .overlay(alignment: .topLeading) {
                BoutonRond(role: .fermer, action: fermer)
                    .padding(.leading, Espace.l)
                    // L'écran ignore les zones sûres : on lit celle de la fenêtre pour poser la croix sous l'îlot dynamique.
                    .padding(.top, max(geo.safeAreaInsets.top, Self.hautDeLaFenetre) + Espace.l)
                    .contentShape(Rectangle())
                    .zIndex(10)
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
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 34) + Espace.l)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(item: $carteOuverte) { emplacement in
            if let infos = modele.infos(pour: emplacement) {
                CartePleinEcranView(infos: infos, photo: photoOuverte, emplacements: emplacements, png: pngOuvert) {
                    carteOuverte = nil
                }
            }
        }
    }

    // MARK: La scène (celle de CoucheNage)

    private func creneau(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / NageWidget.pas).rounded(.down))
    }

    /// Les poissons du Pescedex au format du fichier du widget : le même chemin que `publierAquarium`.
    private func instantane() -> [InstantaneAquarium.Poisson] {
        poissons.compactMap { e in
            guard let carte = e.carte else { return nil }
            return InstantaneAquarium.Poisson(id: e.id, slug: e.espece.espece.id, rarete: niveau(e),
                                              relache: !carte.gardee, nom: e.espece.nom)
        }
    }

    /// Même construction que dans `CoucheNage` : placements (échelle de chacun), puis trajectoires en perspective.
    private func fabriquer(taille: CGSize) -> [Nageur] {
        let liste = instantane()
        guard !liste.isEmpty, taille.width > 0 else { return [] }
        let places = NageWidget.placements(liste, a: dateOuverture, dernierRepas: nil,
                                           limite: poissonsAffiches, colonnes: 2)
        let parId = Dictionary(liste.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        let creneau = creneau(dateOuverture)
        return places.compactMap { placement in
            guard let poisson = parId[placement.id] else { return nil }
            let longueur = partPoisson * placement.echelle
            let battement = NageWidget.cycleUtilise(disponibles: PoissonVivant.imagesDisponibles(poisson.slug))
            return Nageur(
                id: poisson.id, slug: poisson.slug, largeur: taille.width * longueur,
                cycle: battement.images > 0, pas: battement.pas,
                angles: battement.images > 0 ? PoissonVivant.anglesDisponibles(poisson.slug) : [],
                poses: NageWidget.traversees(id: poisson.id, slug: poisson.slug, creneau: creneau,
                                             nombre: Self.nombreDePoses, duree: Self.dureeDeLaBoucle,
                                             imagesCycle: max(battement.images, 1), longueur: longueur,
                                             rapport: Double(taille.height / max(taille.width, 1))))
        }
    }

    /// Avec « Réduire les animations », comme dans le widget : les poissons restent à leur place de départ (image 0).
    private func scene(taille: CGSize) -> some View {
        TimelineView(.animation(paused: reduireAnimations)) { contexte in
            let j = reduireAnimations ? 0
                : Int((contexte.date.timeIntervalSince1970 * Double(HorlogeAnimation.imagesParSeconde)).rounded(.down))
                    % Self.nombreDePoses
            let l = taille.width, h = taille.height
            // Les poissons du fond d'abord : ceux de devant passent par-dessus.
            let ordre = nageurs.filter { $0.poses.indices.contains(j) }
                .sorted { $0.poses[j].profondeur > $1.poses[j].profondeur }
            ZStack {
                ForEach(ordre) { nageur in
                    let pose = nageur.poses[j]
                    // Il tourne en fondu entre les deux lacets rendus les plus proches : jamais de saut.
                    let vues = nageur.angles.isEmpty ? [(angle: 0, poids: 1.0)]
                        : NageWidget.melange(lacet: pose.lacet, angles: nageur.angles)
                    ZStack {
                        ForEach(Array(vues.enumerated()), id: \.offset) { rang, vue in
                            ImagePoisson(slug: nageur.slug, image: nageur.cycle ? pose.image * nageur.pas : nil,
                                         largeur: nageur.largeur * pose.echelle, sens: pose.sens,
                                         angle: vue.angle, volume: !nageur.angles.isEmpty)
                                .opacity(rang == 0 ? 1 : vue.poids)
                        }
                    }
                    // Brume du fond, comme le widget : plus loin, plus pâle et plus clair.
                    .saturation(1 - 0.55 * max(pose.profondeur, 0))
                    .brightness(0.12 * max(pose.profondeur, 0))
                    .opacity(pose.opacite)
                    // Il lève un peu le nez quand il monte (moitié de l'assiette de nage.js).
                    .rotationEffect(.radians(-pose.assiette * 0.5 * (pose.sens > 0 ? 1 : -1)))
                    .shadow(color: .white.opacity(choisi?.id == nageur.id ? 0.9 : 0), radius: 8)
                    .position(x: pose.x * l, y: pose.y * h)
                    .allowsHitTesting(false)
                }
                // Les zones de toucher suivent les poissons, au premier plan (celui de devant gagne).
                ForEach(ordre.reversed()) { nageur in
                    let pose = nageur.poses[j]
                    let cote = max(nageur.largeur * pose.echelle, 56)
                    Color.clear
                        .frame(width: cote, height: max(cote * 0.5, 56))
                        .contentShape(Rectangle())
                        .onTapGesture { toucher(nageur.id) }
                        .position(x: pose.x * l, y: pose.y * h)
                        .accessibilityLabel(nom(nageur.id))
                        .accessibilityAddTraits(.isButton)
                }
            }
            .frame(width: l, height: h)
        }
    }

    private func nom(_ id: String) -> String {
        poissons.first { $0.id == id }?.espece.nom ?? "Poisson"
    }

    private func toucher(_ id: String) {
        guard let e = poissons.first(where: { $0.id == id }) else { return }
        withAnimation(.spring(duration: 0.3)) {
            choisi = (choisi?.id == e.id) ? nil : e
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
