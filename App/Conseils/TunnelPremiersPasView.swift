import Core
import MapKit
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
    /// Code du département de la zone (« 94 »), pour le compteur de « pas encore de carte » ; `nil` : « ta zone ».
    var departement: String? = nil
    /// Région US : la carte de fond montre les États-Unis, pas la France.
    var regionUS = false

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @Environment(\.locale) private var locale
    @State private var index = 0
    /// Déplacement du doigt (x et y) : la carte suit, penche, et part hors de l'écran au-delà du seuil (façon Tinder).
    @State private var glisse: CGSize = .zero
    /// Vrai pendant l'envol d'une carte : bloque un 2e geste ou un 2e toucher de bouton.
    @State private var envol = false
    /// Change à chaque passage du seuil et à chaque décision : déclenche la vibration.
    @State private var vibreSeuil = 0
    @State private var vibreChoix = 0
    private var decalage: CGFloat { glisse.width }
    @State private var nbDeclarees = 0
    /// Positions déjà déclarées : revenir en arrière puis re-glisser à droite ne crée pas de doublon.
    @State private var declarees: Set<Int> = []

    private let seuil: CGFloat = 100

    var body: some View {
        Group {
            if index < especes.count {
                // Maquette P02-A : le compteur en verre, le titre, les cartes penchées, la feuille de deux boutons ronds en bas.
                // Les cartes occupent tout l'espace entre le titre et la feuille et s'y centrent : aucune marge fixe.
                VStack(spacing: 0) {
                    compteur
                        .accessibilitySortPriority(1)
                    entete
                        .accessibilitySortPriority(2)
                    cartes
                        .accessibilitySortPriority(0)
                    panneau
                }
                .accessibilityElement(children: .contain)
                .ignoresSafeArea(edges: .bottom)
            } else {
                fin
                    .padding(Espace.bord)
            }
        }
        // Maquette P02-A : les cartes posées sur la carte de la zone, floutée (blur 5, saturation .6, voile .6).
        .background { fondCarte.ignoresSafeArea() }
        .presentationBackground(Palette.fond)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
        .accessibilityIdentifier("tunnel-premiers-pas")
    }

    /// Carte MapKit non interactive (France entière), floutée et voilée : décor seulement, aucune donnée.
    private var fondCarte: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: regionUS ? 39.5 : 46.6, longitude: regionUS ? -98.5 : 2.5),
            span: MKCoordinateSpan(latitudeDelta: regionUS ? 40 : 9, longitudeDelta: regionUS ? 40 : 9)))) {}
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .allowsHitTesting(false)
            .saturation(0.6)
            .blur(radius: 5)
            .overlay(Palette.fond.opacity(0.6))
            .accessibilityHidden(true)
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
            .accessibilityLabel(AnglaisC.texte("Carte %lld sur %lld", locale, index + 1, especes.count))
    }

    /// Le titre de l'écran : dit l'objectif. VoiceOver le lit en premier (en-tête).
    private var entete: some View {
        VStack(spacing: Espace.xs) {
            Text(c: "Lesquels as-tu déjà pêchés ?")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(c: "Glisse à droite si oui, à gauche sinon")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.m)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("tunnel-titre")
    }

    /// 0 au repos, 1 quand la carte du dessus atteint le seuil : la carte d'en dessous se redresse et grandit.
    private var progression: CGFloat { min(abs(decalage) / seuil, 1) }

    private static let largeurCarte: CGFloat = 318
    private static let hauteurCarte: CGFloat = 400

    private var cartes: some View {
        GeometryReader { geo in
            // Sur un petit écran la pile se réduit pour tenir entre le titre et la feuille ; son centre ne bouge pas.
            let echelle = min(1, max(0.5, (geo.size.height - Espace.l) / Self.hauteurCarte))
            pile
                .scaleEffect(echelle)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pile: some View {
        let espece = especes[index]
        return ZStack {
            // La carte d'en dessous : la suivante, qui monte quand on glisse celle du dessus (penchée de 4° au repos).
            carteDessous
            // La carte du dessus : 318 × 400, coins 32, penchée de -2,5°, ombre douce ; poisson 270 × 180, nom en 34, rareté.
            VStack(spacing: 10) {
                ImageEspece(nom: espece.image, libelle: espece.nom)
                    .frame(width: 270, height: 180)
                Text(espece.nom)
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
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
            .frame(width: Self.largeurCarte, height: Self.hauteurCarte)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: Palette.encre.opacity(0.35), radius: 20, y: 14)
            .overlay(alignment: .topLeading) {
                tampon("Jamais pêché", couleur: Palette.encreDouce, angle: 14)
                    .opacity(decalage < 0 ? Double(progression) : 0)
            }
            .overlay(alignment: .topTrailing) {
                tampon("Déjà pêché", couleur: Palette.marine, angle: -14)
                    .opacity(decalage > 0 ? Double(progression) : 0)
            }
            .rotationEffect(.degrees(-2.5 + Double(decalage) / 18), anchor: .bottom)
            .offset(glisse)
            .gesture(geste)
            // Une identité par espèce (jamais par index) : la carte suivante est une vue neuve qui entre en douceur,
            // la carte envolée disparaît sans animation (elle est déjà hors de l'écran).
            .id(espece.espece.id)
            .transition(.asymmetric(
                insertion: reduireAnimations ? .opacity : .scale(scale: 0.96).combined(with: .opacity),
                removal: .identity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(espece.nom)
            .accessibilityAction(named: Text(c: "Déjà pêché")) { lancer(dejaPeche: true) }
            .accessibilityAction(named: Text(c: "Jamais pêché")) { lancer(dejaPeche: false) }
        }
        .sensoryFeedback(.selection, trigger: vibreSeuil)
        .sensoryFeedback(.impact(weight: .medium), trigger: vibreChoix)
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

    /// La carte suivante sous celle qu'on glisse : elle se redresse et grandit à mesure que la carte du dessus s'éloigne.
    @ViewBuilder private var carteDessous: some View {
        if index + 1 < especes.count {
            let suivante = especes[index + 1]
            ImageEspece(nom: suivante.image, libelle: suivante.nom)
                .frame(width: 240, height: 160)
                .opacity(0.35 + 0.65 * Double(progression))
                .frame(width: Self.largeurCarte - 20, height: Self.hauteurCarte)
                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .scaleEffect(0.94 + 0.06 * progression)
                .rotationEffect(.degrees(4 * Double(1 - progression)))
                .offset(x: 10 * (1 - progression), y: 10 * (1 - progression))
                .id("dessous-" + suivante.espece.id)
                .transition(.opacity)
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Palette.tuile)
                .frame(width: Self.largeurCarte - 20, height: Self.hauteurCarte)
                .rotationEffect(.degrees(4))
                .offset(x: 10, y: 10)
                .accessibilityHidden(true)
        }
    }

    /// Le tampon penché qui apparaît sur la carte pendant qu'on glisse (marine pour « Déjà pêché », gris pour « Jamais pêché »).
    private func tampon(_ mot: String, couleur: Color, angle: Double) -> some View {
        Text(AnglaisC.texte(mot, locale).uppercased())
            .font(Police.taille(20, .heavy))
            .foregroundStyle(couleur)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(couleur, lineWidth: 3))
            .rotationEffect(.degrees(angle))
            .padding(22)
            .accessibilityHidden(true)
    }

    /// Glisser : la carte suit le doigt ; au-delà du seuil (ou d'un geste rapide) elle s'envole, sinon elle revient en ressort.
    private var geste: some Gesture {
        DragGesture()
            .onChanged { valeur in
                guard !envol else { return }
                let avant = abs(glisse.width) > seuil
                glisse = CGSize(width: valeur.translation.width, height: valeur.translation.height * 0.4)
                if avant != (abs(glisse.width) > seuil) { vibreSeuil += 1 }
            }
            .onEnded { valeur in
                guard !envol else { return }
                let elan = valeur.predictedEndTranslation.width
                if valeur.translation.width > seuil || elan > seuil * 2.5 {
                    lancer(dejaPeche: true)
                } else if valeur.translation.width < -seuil || elan < -seuil * 2.5 {
                    lancer(dejaPeche: false)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) { glisse = .zero }
                }
            }
    }

    /// La carte part hors de l'écran du côté choisi, puis la suivante prend sa place (fondu et léger zoom de 0,2 s).
    /// « Réduire les animations » : la carte est remplacée tout de suite, sans envol.
    private func lancer(dejaPeche: Bool) {
        guard !envol, index < especes.count else { return }
        envol = true
        vibreChoix += 1
        if reduireAnimations {
            var sansAnimation = Transaction()
            sansAnimation.disablesAnimations = true
            withTransaction(sansAnimation) { repondre(dejaPeche: dejaPeche) }
            envol = false
            return
        }
        let sens: CGFloat = dejaPeche ? 1 : -1
        withAnimation(.easeIn(duration: 0.28), completionCriteria: .logicallyComplete) {
            glisse = CGSize(width: sens * 600, height: glisse.height + 60)
        } completion: {
            // Un seul changement d'état : la carte envolée part et la suivante entre dans la même transaction.
            withAnimation(.easeOut(duration: 0.2)) { repondre(dejaPeche: dejaPeche) }
            envol = false
        }
    }

    /// La feuille du bas, fixe (maquette : 8 pt des bords, coins 38, deux boutons ronds de 68 pt, mot dessous). Aucune poignée, aucun geste.
    private var panneau: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Spacer()
                bouton(icone: "xmark", mot: "Jamais pêché", plein: false) { lancer(dejaPeche: false) }
                Spacer()
                bouton(icone: "checkmark", mot: "Déjà pêché", plein: true) { lancer(dejaPeche: true) }
                Spacer()
            }
            .padding(.top, Espace.l)
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
                Text(c: mot).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(c: mot))
    }

    @ViewBuilder private var fin: some View {
        if nbDeclarees > 0 {
            VStack(spacing: Espace.l) {
                Spacer(minLength: 0)
                Text("\(nbDeclarees)")
                    .font(Police.taille(72, .heavy).monospacedDigit())
                    .foregroundStyle(Palette.marine)
                Label { Text(c: "dans ton Pescedex") } icon: { Image(systemName: "square.stack.fill") }
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                poissonsDeclares
                Spacer(minLength: 0)
                gros("Voir mon spot", icone: "mappin.and.ellipse", plein: true, action: voirMonSpot ?? choisirUnSpot)
            }
        } else {
            finSansCarte
        }
    }

    /// Largeur de la carte à débloquer (hauteur : largeur / `Gabarit.rapportCarte`).
    private static let largeurCarteADebloquer: CGFloat = 176

    /// « Pas encore de carte » : le cartouche nuit à débloquer (contour de poisson en pointillés, espèce la plus commune de la zone), le compteur de la zone,
    /// une phrase sur le Pescedex, un seul bouton. Défilement sans barre si l'écran est trop court (texte agrandi).
    private var finSansCarte: some View {
        let aDebloquer = FinDuTunnel.aDebloquer(especes: especes, libelleRarete: { rarete($0)?.libelle })
        return GeometryReader { geo in
            ScrollView {
                VStack(spacing: Espace.l) {
                    Spacer(minLength: 0)
                    if let aDebloquer {
                        // Cartouche nuit : le titre « Pas encore de carte » est dans la carte.
                        CartouchePasEncoreView(espece: aDebloquer.nom, rarete: rarete(aDebloquer)?.libelle,
                                               largeur: Self.largeurCarteADebloquer)
                    } else {
                        Text(c: "Pas encore de carte")
                            .font(Police.titre)
                            .foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Image(systemName: "fish.fill")
                            .font(Police.taille(56, .bold))
                            .foregroundStyle(Palette.silhouette)
                            .frame(width: 128, height: 128)
                            .background(Palette.marineDoux, in: Circle())
                            .accessibilityHidden(true)
                    }
                    // Aucune espèce chargée : pas de « 0 sur 0 », la phrase et le bouton suffisent.
                    if !especes.isEmpty {
                        Text(FinDuTunnel.compteur(declarees: 0, total: especes.count, departement: departement, locale: locale))
                            .font(Police.chiffreMoyen)
                            .foregroundStyle(Palette.marine)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("tunnel-compteur-zone")
                    }
                    Text(c: "Tu pourras en déclarer d'autres depuis ton Pescedex.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    gros("Voir mon spot", icone: "mappin.and.ellipse", plein: true, action: voirMonSpot ?? choisirUnSpot)
                        .accessibilityIdentifier("tunnel-voir-mon-spot")
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .accessibilityIdentifier("tunnel-pas-encore-de-carte")
    }

    /// Les poissons déclarés, en images (jamais en liste de noms), 3 par rangée.
    private var poissonsDeclares: some View {
        let colonnes = Array(repeating: GridItem(.flexible(), spacing: Espace.m), count: 3)
        let choisis = declarees.sorted().filter { $0 < especes.count }.map { especes[$0] }
        return LazyVGrid(columns: colonnes, spacing: Espace.m) {
            ForEach(choisis, id: \.espece) { e in
                ImageEspece(nom: e.image, libelle: e.nom)
                    .frame(height: 52)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Espace.s)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
            }
        }
    }

    /// Un seul bouton principal (« Voir mon spot »).
    @ViewBuilder
    private func gros(_ mot: String, icone: String, plein: Bool, action: @escaping () -> Void) -> some View {
        if plein {
            Button(action: action) { Label { Text(c: mot) } icon: { Image(systemName: icone) } }
                .buttonStyle(.principal)
        } else {
            Button(action: action) { Label { Text(c: mot) } icon: { Image(systemName: icone) } }
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
        glisse = .zero
        index += 1
    }

    /// Revient sur la carte d'avant. Une carte déjà rangée au Pescedex y reste : le tunnel n'a pas de moyen de la retirer.
    private func revenir() {
        guard index > 0 else { return }
        glisse = .zero
        index -= 1
    }
}
