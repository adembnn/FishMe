import Core
import SwiftUI

/// Le volet Pescedex (P26 B, P45 B, P48 B) : grand titre, phrase de la zone, « Les miens / Amis », « Voir mon aquarium »,
/// puis un classeur en blocs blancs de vignettes de cartes : TROUVÉES, DÉCLARÉES, À TROUVER. Aucune barre de défilement visible.
struct PescedexView: View {
    @State var modele: PescedexModele
    var emplacements: EmplacementsExternes = .vides
    /// Ouvre l'aquarium. À brancher : RootView (aucune destination aquarium n'existe dans App/Collection).
    /// Tant que c'est `nil`, la ligne « Voir mon aquarium » n'est pas affichée.
    var voirAquarium: (() -> Void)? = nil
    /// « Le pêcher en photo », sur la fiche d'une carte déclarée. À brancher : RootView (ouvre la prise sur cette espèce).
    /// Tant que c'est `nil`, la ligne n'est pas affichée.
    var pecherEnPhoto: ((Espece) -> Void)? = nil
    /// « Photographier une prise », dans « Pour commencer » (Pescedex vide). À brancher : RootView (ouvre l'onglet de prise).
    /// Tant que c'est `nil`, la ligne n'est pas affichée.
    var photographier: (() -> Void)? = nil
    /// « Déclarer un poisson déjà pêché ». À brancher : RootView (ouvre les cartes à swiper). Tant que c'est `nil`, la ligne n'est pas affichée.
    var declarer: (() -> Void)? = nil
    /// Choix « Amis » du sélecteur. À brancher : RootView (`app.onglet = .club`). Tant que c'est `nil`, le choix revient sur « Les miens ».
    var voirAmis: (() -> Void)? = nil

    @State private var volet: Volet = .miens
    @State private var carteOuverte: Emplacement?
    @State private var ficheOuverte: Emplacement?
    @State private var bredouilleOuverte: CarteBredouille?
    @State private var conditionsOuvertes = false
    @State private var photoOuverte: Data?
    @State private var aTrouverDeplie = false
    @State private var bredouillesDepliees = false

    private enum Volet: String, CaseIterable, Identifiable {
        case miens = "Les miens"
        case amis = "Amis"
        var id: String { rawValue }
    }

    /// Nombre de dos de cartes montrés avant « + N autres ».
    private let apercu = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            entete
            classeur
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .background(Palette.fond.ignoresSafeArea())
        .task { await modele.charger() }
        .onChange(of: volet) { _, nouveau in
            if nouveau == .amis {
                voirAmis?()
                volet = .miens
            }
        }
        .fullScreenCover(item: $carteOuverte) { emplacement in
            if let infos = modele.infos(pour: emplacement) {
                CartePleinEcranView(infos: infos, photo: photoOuverte, emplacements: emplacements_) {
                    carteOuverte = nil
                }
            }
        }
        .sheet(item: $ficheOuverte) { emplacement in
            FicheEspeceView(emplacement: emplacement, zone: modele.zone, emplacements: emplacements_,
                            infos: emplacement.carte?.estDeclaree == true ? modele.infos(pour: emplacement) : nil,
                            pecherEnPhoto: pecherEnPhoto)
        }
        .fullScreenCover(item: $bredouilleOuverte) { carte in
            BredouillePleinEcranView(carte: carte, services: modele.services, emplacements: emplacements_) {
                bredouilleOuverte = nil
            }
        }
        .sheet(isPresented: $conditionsOuvertes) {
            Group {
                if let tes = emplacements.tesConditions { tes() }
            }
            .overlay(alignment: .topLeading) {
                BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord)
            }
        }
    }

    private var emplacements_: EmplacementsExternes { emplacements }

    private var estVide: Bool { PescedexVide.estVide(modele.emplacements) }

    // MARK: En-tête (P26 B)

    private var entete: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pescedex")
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
            Text(sousTitre)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
            if !estVide {
                Picker("Volet", selection: $volet) {
                    ForEach(Volet.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(minHeight: Gabarit.zoneTactile)
                .padding(.top, Espace.m)
            }
            if let voirAquarium {
                Button(action: voirAquarium) {
                    HStack(spacing: Espace.m) {
                        Image(systemName: "fish")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text("Voir mon aquarium")
                            .font(Police.corps)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.encreDouce)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Palette.marine)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 52)
                    .tuileFishMe(rayon: Rayon.m)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, Espace.m)
            }
        }
        .padding(.bottom, Espace.xs)
    }

    /// P26 B : « Tu en as trouvé 3 sur 11 espèces de la zone » ; P45 B : « Tu n'as pas encore trouvé les 11 espèces de la zone ».
    private var sousTitre: String {
        let c = modele.compteur
        if estVide {
            if modele.zone != nil, c.releveesDansLaZone > 0 {
                return "Tu n'as pas encore trouvé les \(c.releveesDansLaZone) espèces de la zone"
            }
            return PescedexVide.texte
        }
        return c.phraseDeZone ?? c.texte
    }

    // MARK: Zone (P48 B)

    /// Vrai quand le bloc « Ta zone » s'ajoute : une zone connue, des espèces relevées dedans, au moins une carte.
    private var zoneEnCartes: Bool {
        guard let zone = modele.zone, !zone.estInconnu else { return false }
        return modele.compteur.releveesDansLaZone > 0 && !estVide
    }

    private var blocZone: some View {
        let c = modele.compteur
        let part = c.releveesDansLaZone > 0 ? min(1, Double(c.trouvees) / Double(c.releveesDansLaZone)) : 0
        let pourcent = Int((part * 100).rounded())
        return VStack(alignment: .leading, spacing: Espace.s) {
            titreSection("Ta zone")
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Espace.m) {
                    Image(systemName: "mappin")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.marine)
                        .frame(width: 32)
                        .accessibilityHidden(true)
                    // À brancher : le nom de l'eau (« La Marne ») n'existe pas dans le modèle ; le département seul, jamais un total national.
                    Text("Département \(c.zone?.code ?? "")")
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                    Spacer(minLength: 0)
                    // À brancher : « Changer » (choix d'une autre zone), aucune action n'existe encore.
                }
                .padding(.horizontal, Espace.l)
                .frame(minHeight: 56)
                Divider().overlay(Palette.filet)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(alignment: .firstTextBaseline, spacing: Espace.xs) {
                            Text("\(c.trouvees)").font(Police.chiffre).foregroundStyle(Palette.encre)
                            Text("sur \(c.releveesDansLaZone)").font(Police.detail).foregroundStyle(Palette.encreDouce)
                        }
                        Spacer(minLength: 0)
                        Text("\(pourcent) %").font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.tuile)
                            Capsule().fill(Palette.marine).frame(width: geo.size.width * part)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(.top, Espace.m)
                .padding(.horizontal, Espace.l)
                .padding(.bottom, Espace.l)
            }
            .tuileFishMe(rayon: Rayon.m)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(c.phraseDeZone ?? c.texte)
        }
    }

    // MARK: Pescedex vide (P45 B)

    private var pourCommencer: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            titreSection("Pour commencer")
            VStack(spacing: 0) {
                if let photographier {
                    ligneDepart("Photographier une prise", icone: "camera", action: photographier)
                }
                if photographier != nil, declarer != nil { Divider().overlay(Palette.filet).padding(.leading, Espace.l) }
                if let declarer {
                    ligneDepart("Déclarer un poisson déjà pêché", icone: "checkmark.circle.fill", action: declarer)
                }
            }
            .tuileFishMe(rayon: Rayon.m)
        }
    }

    private func ligneDepart(_ titre: String, icone: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: icone)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                Text(titre)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Classeur

    private var trouvees: [Emplacement] { modele.emplacements.filter { $0.carte != nil && $0.carte?.estDeclaree == false } }
    private var declarees: [Emplacement] { modele.emplacements.filter { $0.carte?.estDeclaree == true } }
    private var aTrouver: [Emplacement] { modele.emplacements.filter { $0.carte == nil } }

    private var colonnes: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3) }

    private var classeur: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.s) {
                if estVide {
                    if photographier != nil || declarer != nil { pourCommencer }
                } else {
                    if zoneEnCartes { blocZone }
                    sectionCartes("Trouvées", trouvees)
                    sectionDeclarees
                }
                sectionATrouver
                sectionBredouilles
                if emplacements.tesConditions != nil {
                    Button { conditionsOuvertes = true } label: {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "cloud.sun")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.marine)
                                .frame(width: 32)
                                .accessibilityHidden(true)
                            Text("Tes conditions")
                                .font(Police.corps)
                                .foregroundStyle(Palette.encre)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.encreDouce)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Espace.s)
                }
            }
            .padding(.top, Espace.xs)
            .padding(.bottom, Espace.xxl)
        }
        .scrollIndicators(.hidden)
    }

    private func titreSection(_ texte: String) -> some View {
        Text(texte.uppercased())
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .padding(.horizontal, Espace.l)
            .padding(.top, Espace.s)
    }

    /// Un bloc blanc de vignettes de cartes, trois par ligne.
    @ViewBuilder
    private func sectionCartes(_ titre: String, _ liste: [Emplacement]) -> some View {
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                titreSection("\(titre) · \(liste.count)")
                LazyVGrid(columns: colonnes, spacing: Espace.s) {
                    ForEach(liste) { emplacement in cellule(emplacement) }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
            }
        }
    }

    /// Déclarées : une seule, la carte à gauche et la phrase à droite (P26 B) ; plusieurs, une grille puis la phrase.
    @ViewBuilder
    private var sectionDeclarees: some View {
        let liste = declarees
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                titreSection("Déclarées · \(liste.count)")
                Group {
                    if liste.count == 1, let seule = liste.first {
                        UnTiersDeuxTiers(espacement: Espace.s) {
                            cellule(seule)
                            noteDeclaree
                                .padding(.horizontal, Espace.s)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Espace.m) {
                            LazyVGrid(columns: colonnes, spacing: Espace.s) {
                                ForEach(liste) { emplacement in cellule(emplacement) }
                            }
                            noteDeclaree
                        }
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
            }
        }
    }

    private var noteDeclaree: some View {
        Text("Sans photo. Pêches-en un pour en faire une vraie carte.")
            .font(Police.detail)
            .foregroundStyle(Palette.encreDouce)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Dos de cartes marine : six au plus, puis « + N autres » qui déplie le reste.
    @ViewBuilder
    private var sectionATrouver: some View {
        let liste = aTrouver
        if !liste.isEmpty {
            let visibles = aTrouverDeplie ? liste : Array(liste.prefix(apercu))
            VStack(alignment: .leading, spacing: Espace.s) {
                titreSection("À trouver · \(liste.count)")
                VStack(spacing: Espace.s) {
                    LazyVGrid(columns: colonnes, spacing: Espace.s) {
                        ForEach(visibles) { e in
                            Button { ficheOuverte = e } label: { DosAATrouver(espece: e.espece) }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(e.espece.nom), pas encore pris")
                        }
                    }
                    if liste.count > apercu {
                        Button { aTrouverDeplie.toggle() } label: {
                            Text(aTrouverDeplie ? "Réduire" : "+ \(liste.count - apercu) autres")
                                .font(Police.detail)
                                .foregroundStyle(Palette.encreDouce)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
            }
        }
    }

    /// Les sessions finies sans poisson, rangées à part : six vignettes au plus, puis « + N autres ».
    @ViewBuilder
    private var sectionBredouilles: some View {
        let liste = modele.bredouilles
        if !liste.isEmpty {
            let visibles = bredouillesDepliees ? liste : Array(liste.prefix(apercu))
            VStack(alignment: .leading, spacing: Espace.s) {
                titreSection("Sans prise · \(liste.count)")
                VStack(spacing: Espace.s) {
                    LazyVGrid(columns: colonnes, spacing: Espace.s) {
                        ForEach(visibles) { b in
                            Button { bredouilleOuverte = b } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "water.waves")
                                        .font(Police.taille(28))
                                    Text(Formats.date(b.debut)).font(Police.legende).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(Palette.commun)
                                .frame(maxWidth: .infinity, minHeight: 88)
                                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sortie sans prise, \(Formats.date(b.debut))")
                        }
                    }
                    if liste.count > apercu {
                        Button { bredouillesDepliees.toggle() } label: {
                            Text(bredouillesDepliees ? "Réduire" : "+ \(liste.count - apercu) autres")
                                .font(Police.detail)
                                .foregroundStyle(Palette.encreDouce)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
            }
        }
    }

    private func cellule(_ e: Emplacement) -> some View {
        Button {
            if let carte = e.carte, !carte.estDeclaree {
                Task {
                    photoOuverte = await modele.depot.photo(de: carte)
                    carteOuverte = e
                }
            } else {
                ficheOuverte = e
            }
        } label: {
            EmplacementView(emplacement: e)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle(e))
    }

    private func libelle(_ e: Emplacement) -> String {
        guard let c = e.carte else { return "\(e.espece.nom), pas encore pris" }
        let style = StyleRarete(e.rarete.niveau)
        let zone = modele.zone.map { " dans le \($0.code)" } ?? ""
        if c.estDeclaree { return "\(e.espece.nom), carte déclarée" }
        let t = Formats.taille(c).map { ", \($0)" } ?? ""
        return "\(e.espece.nom), \(style.mot)\(zone)\(t)"
    }
}

/// Une carte à gauche (un tiers de la largeur), un texte à droite (deux tiers).
private struct UnTiersDeuxTiers: Layout {
    var espacement: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let largeur = proposal.width ?? 300
        let un = (largeur - 2 * espacement) / 3
        let deux = largeur - un - espacement
        let h1 = subviews[0].sizeThatFits(ProposedViewSize(width: un, height: nil)).height
        let h2 = subviews[1].sizeThatFits(ProposedViewSize(width: deux, height: nil)).height
        return CGSize(width: largeur, height: max(h1, h2))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let un = (bounds.width - 2 * espacement) / 3
        let deux = bounds.width - un - espacement
        let h1 = subviews[0].sizeThatFits(ProposedViewSize(width: un, height: nil)).height
        let h2 = subviews[1].sizeThatFits(ProposedViewSize(width: deux, height: nil)).height
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY + (bounds.height - h1) / 2), anchor: .topLeading,
                          proposal: ProposedViewSize(width: un, height: h1))
        subviews[1].place(at: CGPoint(x: bounds.minX + un + espacement, y: bounds.minY + (bounds.height - h2) / 2),
                          anchor: .topLeading, proposal: ProposedViewSize(width: deux, height: h2))
    }
}

/// Le dos d'une carte « à trouver » (P45 B) : marine, des ronds d'eau, la silhouette de l'espèce et son nom.
struct DosAATrouver: View {
    let espece: EspecePechable

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
        Color.clear
            .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
            .overlay {
                ZStack {
                    // Marine fixe (même en mode sombre) pour que le texte blanc reste lisible.
                    Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)
                    ZStack {
                        ForEach(1..<6, id: \.self) { i in
                            Ellipse()
                                .strokeBorder(.white.opacity(0.10), lineWidth: 1)
                                .scaleEffect(CGFloat(i) * 0.3)
                        }
                    }
                    .scaleEffect(x: 1.1, y: 1.4)
                    .allowsHitTesting(false)
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Image(espece.image)
                            .renderingMode(.template)
                            .resizable().scaledToFit()
                            .foregroundStyle(.white.opacity(0.45))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, Espace.m)
                            .accessibilityHidden(true)
                        Spacer(minLength: 0)
                        Text(espece.nom)
                            .font(Police.taille(12))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, Espace.xs)
                            .padding(.bottom, Espace.s)
                    }
                    forme.inset(by: 4).strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
            }
            .clipShape(forme)
            .overlay(forme.strokeBorder(.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Palette.encre.opacity(0.18), radius: 6, y: 4)
    }
}

/// Une vignette de carte du classeur (P26 B) : le poisson sur son fond de rareté, le nom et le badge de rareté dessous.
/// Une carte déclarée porte l'étiquette « Déclarée » et le poisson pâli.
struct EmplacementView: View {
    let emplacement: Emplacement

    var body: some View {
        let style = StyleRarete(emplacement.rarete.niveau)
        let declaree = emplacement.carte?.estDeclaree == true
        let forme = RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
        Color.clear
            .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
            .overlay {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
                        Image(emplacement.espece.image)
                            .resizable().scaledToFit()
                            .padding(Espace.xs)
                            .saturation(declaree ? 0.35 : 1)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        if declaree {
                            Text("Déclarée")
                                .font(Police.taille(11, .heavy))
                                .foregroundStyle(Palette.encre)
                                .padding(.horizontal, 7)
                                .frame(height: 18)
                                .background(Palette.surface, in: Capsule())
                                .padding(5)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    HStack(spacing: Espace.xs) {
                        Text(emplacement.espece.nom)
                            .font(Police.taille(13, .heavy))
                            .foregroundStyle(Palette.encre)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer(minLength: 0)
                        BadgeRarete(style: style, taille: 16)
                    }
                    .padding(.horizontal, Espace.s)
                    .frame(height: 34)
                    .background(Palette.tuile)
                }
            }
            .clipShape(forme)
            .overlay(forme.strokeBorder(Palette.filet, lineWidth: 1))
            .shadow(color: Palette.encre.opacity(0.14), radius: 5, y: 3)
    }
}

/// La fiche d'une espèce (P27 B) : retour « Pescedex », son nom, son image, sa rareté dans la zone avec le nombre de pêches OFB
/// et l'année, puis « comment la pêcher » (L13). Pour une carte déclarée (P28 B), la carte sans photo et la ligne pour la pêcher en vrai.
struct FicheEspeceView: View {
    let emplacement: Emplacement
    let zone: Departement?
    let emplacements: EmplacementsExternes
    /// Renseigné seulement pour une carte déclarée : sert à montrer la carte elle-même.
    var infos: InfosCarte? = nil
    /// Ouvre la prise sur cette espèce. À brancher : RootView via `PescedexView.pecherEnPhoto`.
    var pecherEnPhoto: ((Espece) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var style: StyleRarete { StyleRarete(emplacement.rarete.niveau) }
    private var estDeclaree: Bool { emplacement.carte?.estDeclaree == true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.m) {
                Button { dismiss() } label: {
                    HStack(spacing: Espace.xs) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .heavy, design: .rounded))
                            .accessibilityHidden(true)
                        Text("Pescedex").font(Police.corps)
                    }
                    .foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Retour au Pescedex")
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(emplacement.espece.nom).font(Police.grandTitre).foregroundStyle(Palette.encre)
                    Text(estDeclaree ? "Carte déclarée" : emplacement.espece.nomLatin)
                        .font(Police.detail)
                        .italic(!estDeclaree)
                        .foregroundStyle(Palette.encreDouce)
                }
                if estDeclaree, let infos {
                    carteDeclaree(infos)
                } else {
                    tuileEspece
                }
                if let pecherEnPhoto, estDeclaree {
                    Button { pecherEnPhoto(emplacement.espece.espece) } label: {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "camera")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text("Le pêcher en photo")
                                .font(Police.corps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.encreDouce)
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(Palette.marine)
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Espace.xs)
                }
                // À brancher : « Où il vit » (cache, eau) : aucune donnée d'habitat n'existe dans le modèle.
                if let comment = emplacements.commentLaPecher {
                    comment(emplacement.espece.espece)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.medium, .large])
        .background(Palette.fond.ignoresSafeArea())
    }

    private var tuileEspece: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Image(emplacement.espece.image)
                .renderingMode(emplacement.carte == nil ? .template : .original)
                .resizable().scaledToFit()
                .foregroundStyle(Palette.silhouette)
                .frame(maxWidth: .infinity)
                .frame(height: 78)
                .padding(.top, 14)
                .accessibilityHidden(true)
            if zone != nil, style != .nonMesuree {
                HStack(spacing: Espace.s) {
                    BadgeRarete(style: style, taille: 18)
                    Text(style.mot.capitalized)
                        .font(Police.sousTitre)
                        .foregroundStyle(style.couleur)
                    Spacer(minLength: 0)
                    if let part = partOFB {
                        Text("\(part) %").font(Police.sousTitre).foregroundStyle(Palette.encreDouce)
                    }
                }
                Text(statOFB)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, Espace.l)
        .padding(.bottom, Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.m)
    }

    /// Part des pêches OFB de la zone. `nil` sans relevé.
    private var partOFB: Int? {
        let r = emplacement.rarete
        guard r.nTotal > 0, r.niveau != .legendaire else { return nil }
        return Int((Double(r.nPeches) / Double(r.nTotal) * 100).rounded())
    }

    /// Chaque chiffre OFB porte son nombre de pêches et l'année du dernier relevé.
    private var statOFB: String {
        let r = emplacement.rarete
        let lieu = zone.map { " dans le \($0.code)" } ?? ""
        let annee = r.anneeDernierReleve.map { " · \($0)" } ?? ""
        if r.niveau == .legendaire { return "Jamais relevée\(lieu) · OFB\(annee)" }
        return "\(r.nPeches) pêches sur \(r.nTotal)\(lieu) · OFB\(annee)"
    }

    private func carteDeclaree(_ infos: InfosCarte) -> some View {
        HStack(spacing: Espace.l) {
            CarteRectoView(infos: infos)
                .frame(width: 130)
            Text("Tu l'as déclaré au premier lancement. Pas de photo, donc pas de taille ni de numéro.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.m)
    }
}

/// Pescedex sans aucune carte (ni vraie, ni déclarée) : un état vide court au lieu du silence.
enum PescedexVide {
    static let texte = "Ta première prise ouvrira ton Pescedex"
    static func estVide(_ emplacements: [Emplacement]) -> Bool {
        !emplacements.contains { $0.carte != nil }
    }
}
