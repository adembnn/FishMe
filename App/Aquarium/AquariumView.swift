import Core
import SwiftUI

// L'aquarium dans l'app : le fond et les poissons du widget « Mon aquarium » (WidgetAquarium/), en plein écran,
// mais animés par un vrai moteur de comportement continu (MoteurNage.swift) au lieu de trajectoires précalculées,
// avec l'ambiance de l'eau (EffetsEau.swift : rais de lumière, caustiques, particules, bulles, ondes).
//
// Ce qu'on réutilise du widget, sans le modifier (le dossier WidgetAquarium/ est dans la cible BuildChallenge) :
//   - les fonds `fond-grand` (FondsWidget.xcassets) et les images `<espèce>-nage-N` / `-lacet-…` (NagePoissons.xcassets) ;
//   - `NageWidget.placements` (taille de chaque poisson) et `NageWidget.cycleUtilise` (images par battement) ;
//   - `PoissonVivant` et `ImagePoisson` (choix des images, sens, retombée sans rendu 3D).
// Le fondu entre les lacets suit la règle de `NageWidget.melange`, écrite sans allocation dans `Nageur.melanger()`.
// Une espèce sans rendu : comme le widget, l'image fixe si elle existe, sinon l'icône de poisson blanche,
// avec le même moteur.

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
    /// Le moteur de comportement : l'état de la scène vit dans cet objet, pas dans des `@State` redessinés à chaque image.
    @State private var moteur: MoteurNage?
    @State private var dateOuverture = Date()

    /// Les espèces dont on a une carte, les plus rares d'abord (même ordre que le fichier du widget).
    /// Lue au rendu de la vue (changement de cartes, toucher), jamais à chaque image de l'animation.
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

    /// Ce qui change la scène : les espèces affichées, la taille de l'écran, le créneau de 20 minutes, le mode sans animation.
    private struct Cle: Equatable {
        let ids: [String]
        let taille: CGSize
        let creneau: Int
        let fixe: Bool
    }

    /// Zone sûre du haut de la fenêtre (îlot dynamique, barre d'état) : `geo.safeAreaInsets` vaut 0 quand l'écran l'ignore.
    private static var hautDeLaFenetre: CGFloat {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow?.safeAreaInsets.top ?? 59
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if poissons.isEmpty {
                    Image("fond-grand")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    Text("Ton aquarium est vide. Photographie une prise pour y faire nager ton premier poisson.")
                        .font(Police.corps)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(Espace.xl)
                } else if let moteur {
                    scene(taille: geo.size, moteur: moteur)
                } else {
                    // Pendant la construction (poisson par poisson), le fond seul : le fil principal reste libre.
                    Image("fond-grand")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .task(id: Cle(ids: poissons.map(\.id), taille: geo.size, creneau: creneau(dateOuverture),
                          fixe: reduireAnimations)) {
                let nouveau = await construire(taille: geo.size)
                if !Task.isCancelled { moteur = nouveau }
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

    // MARK: Construction (incrémentale)

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

    /// Prépare le moteur un poisson à la fois : la recherche des images (cycle, lacets) charge des fichiers du catalogue,
    /// on rend la main au fil principal entre deux poissons plutôt que de le figer d'un bloc.
    private func construire(taille: CGSize) async -> MoteurNage? {
        let liste = instantane()
        guard !liste.isEmpty, taille.width > 0 else { return nil }
        let places = NageWidget.placements(liste, a: dateOuverture, dernierRepas: nil,
                                           limite: poissonsAffiches, colonnes: 2)
        let parId = Dictionary(liste.map { ($0.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        var entrees: [MoteurNage.Entree] = []
        for placement in places {
            guard let poisson = parId[placement.id] else { continue }
            let battement = NageWidget.cycleUtilise(disponibles: PoissonVivant.imagesDisponibles(poisson.slug))
            entrees.append(MoteurNage.Entree(
                id: poisson.id, nom: poisson.nom ?? "Poisson", slug: poisson.slug,
                largeur: partPoisson * placement.echelle, cycle: battement.images > 0,
                images: battement.images, pas: battement.pas,
                angles: battement.images > 0 ? PoissonVivant.anglesDisponibles(poisson.slug) : []))
            await Task.yield()
            if Task.isCancelled { return nil }
        }
        return MoteurNage(entrees: entrees, rapport: Double(taille.height / max(taille.width, 1)),
                          tousPresents: reduireAnimations)
    }

    // MARK: La scène

    /// Avec « Réduire les animations » : tous les poissons à leur place de départ, aucune couche d'ambiance, rien ne bouge.
    private func scene(taille: CGSize, moteur: MoteurNage) -> some View {
        TimelineView(.animation(paused: reduireAnimations)) { contexte in
            let _ = avancer(moteur, a: contexte.date)
            let l = taille.width, h = taille.height
            let t = reduireAnimations ? 0 : moteur.temps
            // Léger balancement de caméra : le fond bouge moins que les poissons, les particules proches plus.
            let px = reduireAnimations ? 0 : ReglagesEffets.parallaxe * sin(t * 0.21)
            let py = reduireAnimations ? 0 : ReglagesEffets.parallaxe * 0.7 * sin(t * 0.16 + 1.3)
            ZStack {
                Image("fond-grand")
                    .resizable()
                    .scaledToFill()
                    .frame(width: l, height: h)
                    .scaleEffect(1.04)
                    .offset(x: -px * 0.4, y: -py * 0.4)
                    .clipped()
                if !reduireAnimations {
                    CoucheFondEau(t: t).offset(x: -px * 0.5, y: -py * 0.5)
                }
                // Toucher l'eau vide : une onde de lumière, les petits s'écartent. Sous les zones des poissons.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { point in
                        guard !reduireAnimations else { return }
                        moteur.toucherEau(x: Double(point.x / l), y: Double(point.y / h))
                    }
                ZStack {
                    ForEach(0..<moteur.nageurs.count, id: \.self) { i in
                        let n = moteur.nageurs[i]
                        if n.etat != .absent, n.opacite > 0.01 {
                            vue(n, l: l, h: h)
                        }
                    }
                    // Les zones de toucher suivent les poissons, au premier plan (celui de devant gagne).
                    ForEach(0..<moteur.nageurs.count, id: \.self) { i in
                        let n = moteur.nageurs[i]
                        if n.etat == .present {
                            let cote = max(n.largeur * l * n.echelle, 56)
                            Color.clear
                                .frame(width: cote, height: max(cote * 0.5, 56))
                                .contentShape(Rectangle())
                                .onTapGesture { toucher(i, moteur: moteur) }
                                .position(x: n.sx * l, y: n.sy * h)
                                .zIndex(200 + (1 - n.profondeur))
                                .accessibilityLabel(n.nom)
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .offset(x: px, y: py)
                if !reduireAnimations {
                    CoucheAvantEau(t: t, tempsMoteur: moteur.temps, ondes: moteur.ondes)
                        .offset(x: px * 1.8, y: py * 1.8)
                }
            }
            .frame(width: l, height: h)
            .clipped()
        }
    }

    private func avancer(_ moteur: MoteurNage, a date: Date) {
        if !reduireAnimations { moteur.avancer(a: date) }
    }

    /// Un poisson : il tourne en fondu entre les deux lacets rendus les plus proches (jamais de saut), plus loin il est
    /// plus petit, plus pâle et plus bleuté (brume), le nez suit sa vitesse verticale, léger roulis dans les virages.
    private func vue(_ n: Nageur, l: CGFloat, h: CGFloat) -> some View {
        let largeur = CGFloat(n.largeur) * l * CGFloat(n.echelle)
        let brume = max(n.profondeur, 0)
        let miroir = n.sens >= 0 ? 1.0 : -1.0
        return ZStack {
            ImagePoisson(slug: n.slug, image: n.cycle ? n.image * n.pas : nil, largeur: largeur, sens: n.sens,
                         angle: n.angleA, volume: n.volume)
            if n.poidsB > 0 {
                ImagePoisson(slug: n.slug, image: n.cycle ? n.image * n.pas : nil, largeur: largeur, sens: n.sens,
                             angle: n.angleB, volume: n.volume)
                    .opacity(n.poidsB)
            }
        }
        .saturation(1 - 0.55 * brume)
        .brightness(0.12 * brume)
        .colorMultiply(Color(red: 1 - 0.22 * brume, green: 1 - 0.07 * brume, blue: 1))
        .opacity(n.opacite)
        .rotation3DEffect(.radians(n.roulis), axis: (x: 1, y: 0, z: 0), perspective: 0.3)
        .rotationEffect(.radians(-(n.assiette + n.ondulation) * miroir))
        .shadow(color: .white.opacity(n.selectionne ? 0.9 : 0), radius: 8)
        .position(x: n.sx * l, y: n.sy * h)
        .zIndex(1 - n.profondeur)
        .allowsHitTesting(false)
    }

    private func toucher(_ index: Int, moteur: MoteurNage) {
        guard moteur.nageurs.indices.contains(index) else { return }
        let id = moteur.nageurs[index].id
        guard let e = poissons.first(where: { $0.id == id }) else { return }
        let selection = (choisi?.id == e.id) ? nil : e
        withAnimation(.spring(duration: 0.3)) { choisi = selection }
        moteur.choisir(selection == nil ? nil : index)
        // Il vient voir la vitre, plane un instant, puis repart (rien ne bouge avec « Réduire les animations »).
        if selection != nil, !reduireAnimations { moteur.attirer(index) }
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
                    .font(Police.taille(14))
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
            }
            .padding(Espace.l)
            .tuileFishMe()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(e.espece.nom), voir la carte")
    }
}
