import Core
import SwiftUI

/// Le volet Pescedex (piste « Réglages ») : un classeur en trois blocs, trouvées, déclarées, à trouver.
/// La carte prise dans son emplacement, une silhouette dans les autres. Aucune barre de défilement visible.
struct PescedexView: View {
    @State var modele: PescedexModele
    var emplacements: EmplacementsExternes = .vides
    /// Ouvre l'aquarium. À brancher : RootView (aucune destination aquarium n'existe dans App/Collection).
    /// Tant que c'est `nil`, la ligne « Voir mon aquarium » n'est pas affichée.
    var voirAquarium: (() -> Void)? = nil
    /// « Pêcher un sandre en photo », sur la fiche d'une carte déclarée. À brancher : RootView (ouvre la prise sur cette espèce).
    /// Tant que c'est `nil`, le bouton n'est pas affiché.
    var pecherEnPhoto: ((Espece) -> Void)? = nil
    /// « Photographier une prise », dans « Pour commencer » (Pescedex vide). À brancher : RootView (ouvre l'onglet de prise).
    /// Tant que c'est `nil`, la ligne n'est pas affichée.
    var photographier: (() -> Void)? = nil
    /// « Déclarer un poisson déjà pêché ». À brancher : RootView (ouvre les cartes à swiper). Tant que c'est `nil`, la ligne n'est pas affichée.
    var declarer: (() -> Void)? = nil

    @State private var vue: Vue = .cartes
    @State private var carteOuverte: Emplacement?
    @State private var ficheOuverte: Emplacement?
    @State private var bredouilleOuverte: CarteBredouille?
    @State private var conditionsOuvertes = false
    @State private var photoOuverte: Data?

    private enum Vue: String, CaseIterable, Identifiable {
        case cartes = "Cartes"
        case bredouilles = "Sans prise"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            entete
            Picker("Vue", selection: $vue) {
                ForEach(Vue.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Gabarit.zoneTactile)
            switch vue {
            case .cartes: classeur
            case .bredouilles: rangeeBredouilles
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .background(Palette.fond.ignoresSafeArea())
        .task { await modele.charger() }
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

    private var entete: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text("Pescedex")
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
            if PescedexVide.estVide(modele.emplacements) {
                // P45 B : ton positif, jamais « tu n'as rien ».
                Text(texteVide)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !zoneEnCartes {
                Text(modele.compteur.texte)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if emplacements.tesConditions != nil {
                Button { conditionsOuvertes = true } label: {
                    Label("Tes conditions", systemImage: "cloud.sun")
                        .font(Police.detail)
                        .padding(.horizontal, Espace.m)
                        .frame(minHeight: Gabarit.zoneTactile)
                        .background(Palette.surface, in: Capsule())
                }
                .foregroundStyle(Palette.encre)
            }
        }
    }

    private var texteVide: String {
        let m = modele.compteur.releveesDansLaZone
        if modele.zone != nil, m > 0 { return "\(m) espèces de ta zone t'attendent." }
        return PescedexVide.texte
    }

    // MARK: Zone (P48 B)

    /// Vrai quand la ligne de zone avec sa barre remplace la phrase du compteur : une zone connue, des espèces relevées dedans.
    private var zoneEnCartes: Bool {
        guard let zone = modele.zone, !zone.estInconnu else { return false }
        return modele.compteur.releveesDansLaZone > 0 && !PescedexVide.estVide(modele.emplacements)
    }

    private var carteDeZone: some View {
        let c = modele.compteur
        let part = c.releveesDansLaZone > 0 ? Double(c.trouvees) / Double(c.releveesDansLaZone) : 0
        let pourcent = Int((part * 100).rounded())
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Espace.m) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
                // À brancher : le nom de l'eau (« La Marne ») n'existe pas dans le modèle ; le département seul, jamais un total national.
                Text("Département \(c.zone?.code ?? "")")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                Spacer(minLength: 0)
            }
            .padding(Espace.l)
            Divider().overlay(Palette.filet)
            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .firstTextBaseline, spacing: Espace.xs) {
                    Text("\(c.trouvees)").font(Police.chiffre).foregroundStyle(Palette.encre)
                    Text("sur \(c.releveesDansLaZone)").font(Police.corps).foregroundStyle(Palette.encreDouce)
                    Spacer(minLength: 0)
                    Text("\(pourcent) %").font(Police.corps).foregroundStyle(Palette.encreDouce)
                }
                ProgressView(value: part)
                    .tint(Palette.marine)
                Text("Tu en as trouvé \(c.trouvees) sur \(c.releveesDansLaZone) espèces de la zone")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
                if c.legendairesEnPlus > 0 {
                    Text("+ \(c.legendairesEnPlus) légendaire" + (c.legendairesEnPlus > 1 ? "s" : ""))
                        .font(Police.detail)
                        .foregroundStyle(Palette.legendaire)
                }
            }
            .padding(Espace.l)
        }
        .tuileFishMe(rayon: Rayon.l)
        .accessibilityElement(children: .combine)
    }

    // MARK: Pescedex vide (P45 B)

    private var pourCommencer: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text("POUR COMMENCER")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .padding(.horizontal, Espace.s)
            VStack(spacing: 0) {
                if let photographier {
                    ligneDepart("Photographier une prise", icone: "camera.fill", action: photographier)
                }
                if photographier != nil, declarer != nil { Divider().overlay(Palette.filet) }
                if let declarer {
                    ligneDepart("Déclarer un poisson déjà pêché", icone: "checkmark.circle.fill", action: declarer)
                }
            }
            .tuileFishMe(rayon: Rayon.l)
        }
    }

    private func ligneDepart(_ titre: String, icone: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: icone).foregroundStyle(Palette.marine).accessibilityHidden(true)
                Text(titre).foregroundStyle(Palette.encre)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
            }
            .font(Police.corps)
            .padding(.horizontal, Espace.l)
            .frame(minHeight: Gabarit.bouton)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Grille de dos de cartes : six espèces à trouver au plus, puis « + N autres ».
    private var dosATrouver: some View {
        let liste = aTrouver
        return VStack(alignment: .leading, spacing: Espace.s) {
            Text("À TROUVER · \(liste.count)")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .padding(.horizontal, Espace.s)
            VStack(spacing: Espace.m) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3), spacing: Espace.s) {
                    ForEach(liste.prefix(6)) { e in
                        Button { ficheOuverte = e } label: { DosAATrouver(espece: e.espece) }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(e.espece.nom), pas encore pris")
                    }
                }
                if liste.count > 6 {
                    Text("+ \(liste.count - 6) autres")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            .padding(Espace.s)
            .tuileFishMe(rayon: Rayon.l)
        }
    }

    // MARK: Classeur

    private var trouvees: [Emplacement] { modele.emplacements.filter { $0.carte != nil && $0.carte?.estDeclaree == false } }
    private var declarees: [Emplacement] { modele.emplacements.filter { $0.carte?.estDeclaree == true } }
    private var aTrouver: [Emplacement] { modele.emplacements.filter { $0.carte == nil } }

    private var classeur: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                if let voirAquarium {
                    Button(action: voirAquarium) {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "fish")
                                .accessibilityHidden(true)
                            Text("Voir mon aquarium")
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.encreDouce)
                                .accessibilityHidden(true)
                        }
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: Gabarit.bouton)
                        .tuileFishMe()
                    }
                    .buttonStyle(.plain)
                }
                if PescedexVide.estVide(modele.emplacements) {
                    if photographier != nil || declarer != nil { pourCommencer }
                    if !aTrouver.isEmpty { dosATrouver }
                } else {
                    if zoneEnCartes { carteDeZone }
                    section("Trouvées", trouvees)
                    section("Déclarées", declarees, note: "Sans photo. Pêches-en un pour en faire une vraie carte.")
                    section("À trouver", aTrouver)
                }
            }
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func section(_ titre: String, _ liste: [Emplacement], note: String? = nil) -> some View {
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                Text("\(titre.uppercased()) · \(liste.count)")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.s)
                VStack(alignment: .leading, spacing: Espace.m) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3), spacing: Espace.s) {
                        ForEach(liste) { emplacement in
                            cellule(emplacement)
                        }
                    }
                    if let note {
                        Text(note).font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                }
                .padding(Espace.s)
                .tuileFishMe(rayon: Rayon.l)
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

    // MARK: Sans prise

    private var rangeeBredouilles: some View {
        Group {
            if modele.bredouilles.isEmpty {
                Text("Les sessions finies sans poisson se rangent ici.")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3), spacing: Espace.s) {
                        ForEach(modele.bredouilles) { b in
                            Button { bredouilleOuverte = b } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "water.waves")
                                        .font(Police.taille(30))
                                    Text(Formats.date(b.debut)).font(Police.legende).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(Palette.commun)
                                .frame(maxWidth: .infinity, minHeight: 96)
                                .tuileFishMe(rayon: Rayon.m)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sortie sans prise, \(Formats.date(b.debut))")
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// Le dos d'une carte « à trouver » (P45 B) : marine, la silhouette de l'espèce et son nom.
struct DosAATrouver: View {
    let espece: EspecePechable

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
        VStack(spacing: Espace.xs) {
            Image(espece.image)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .foregroundStyle(.white.opacity(0.45))
                .padding(.horizontal, Espace.s)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
            Text(espece.nom)
                .font(Police.legende)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
        }
        .padding(Espace.s)
        .frame(maxWidth: .infinity)
        .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
        // Marine fixe (même en mode sombre) pour que le texte blanc reste lisible.
        .background(Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255), in: forme)
        .overlay(forme.strokeBorder(.white.opacity(0.25), lineWidth: 1))
    }
}

/// Un emplacement du classeur : la carte prise, ou la silhouette de l'espèce.
struct EmplacementView: View {
    let emplacement: Emplacement

    var body: some View {
        let style = StyleRarete(emplacement.rarete.niveau)
        let prise = emplacement.carte
        let forme = RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
        VStack(spacing: Espace.xs) {
            ZStack(alignment: .topTrailing) {
                if let prise {
                    LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
                    Image(emplacement.espece.image)
                        .resizable().scaledToFit().padding(6)
                        .saturation(prise.estDeclaree ? 0.35 : 1)
                    BadgeRarete(style: style, taille: 24).padding(5)
                } else {
                    Palette.tuile
                    Image(emplacement.espece.image)
                        .renderingMode(.template)
                        .resizable().scaledToFit().padding(10)
                        .foregroundStyle(Palette.silhouette)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
            Text(emplacement.espece.nom)
                .font(Police.legende)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(prise == nil ? Palette.encreDouce : Palette.encre)
            if let prise, !prise.estDeclaree { PointsRarete(style: style, taille: 8) }
            if prise?.estDeclaree == true {
                Text("Déclarée").font(Jeton.police(11)).foregroundStyle(Palette.encreDouce)
            }
        }
        .padding(Espace.xs)
        .frame(maxWidth: .infinity)
        .background(Palette.surface.opacity(prise == nil ? 0.6 : 1), in: forme)
        .overlay {
            if prise?.estDeclaree == true {
                forme.strokeBorder(Palette.commun, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            } else if prise != nil, style != .nonMesuree {
                // Filets de rareté (1, 1, 2, 3), comme sur la carte plein écran.
                forme.strokeBorder(style.couleur, lineWidth: CGFloat(style.filets) * 1.5)
            }
        }
    }
}

/// La fiche d'une espèce (piste « Réglages ») : son nom, son image, sa rareté dans la zone avec le nombre de pêches OFB,
/// puis « comment la pêcher » (L13). Pour une carte déclarée, la carte sans photo et un seul bouton pour la pêcher en vrai.
struct FicheEspeceView: View {
    let emplacement: Emplacement
    let zone: Departement?
    let emplacements: EmplacementsExternes
    /// Renseigné seulement pour une carte déclarée : sert à montrer la carte elle-même.
    var infos: InfosCarte? = nil
    /// Ouvre la prise sur cette espèce. À brancher : RootView via `PescedexView.pecherEnPhoto`.
    var pecherEnPhoto: ((Espece) -> Void)? = nil

    private var style: StyleRarete { StyleRarete(emplacement.rarete.niveau) }
    private var estDeclaree: Bool { emplacement.carte?.estDeclaree == true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(emplacement.espece.nom).font(Police.grandTitre).foregroundStyle(Palette.encre)
                    Text(estDeclaree ? "Carte déclarée" : emplacement.espece.nomLatin)
                        .font(Police.corps)
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
                        Label("Le pêcher en photo", systemImage: "camera")
                    }
                    .buttonStyle(.principal)
                }
                if let comment = emplacements.commentLaPecher {
                    comment(emplacement.espece.espece)
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.medium, .large])
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .simple).padding(Espace.bord)
        }
    }

    private var tuileEspece: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Image(emplacement.espece.image)
                .renderingMode(emplacement.carte == nil ? .template : .original)
                .resizable().scaledToFit()
                .foregroundStyle(Palette.silhouette)
                .frame(maxWidth: .infinity, maxHeight: 160)
                .accessibilityHidden(true)
            if let zone, style != .nonMesuree {
                HStack(spacing: Espace.s) {
                    BadgeRarete(style: style, taille: 24)
                    Text("\(style.mot.capitalized) dans le \(zone.code)")
                        .font(Police.detail)
                        .foregroundStyle(style.couleur)
                    Spacer(minLength: 0)
                    Text(statOFB)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity)
        .tuileFishMe(rayon: Rayon.l)
    }

    /// Chaque chiffre OFB porte son nombre de pêches et l'année du dernier relevé.
    private var statOFB: String {
        let r = emplacement.rarete
        let annee = r.anneeDernierReleve.map { " · \($0)" } ?? ""
        if r.niveau == .legendaire { return "Jamais relevée\(annee)" }
        return "\(r.nPeches) pêches sur \(r.nTotal)\(annee)"
    }

    private func carteDeclaree(_ infos: InfosCarte) -> some View {
        HStack(spacing: Espace.l) {
            CarteRectoView(infos: infos)
                .frame(width: 150)
            Text("Tu l'as déclaré au premier lancement. Pas de photo, donc pas de taille ni de numéro.")
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.l)
    }
}

/// Pescedex sans aucune carte (ni vraie, ni déclarée) : un état vide court au lieu du silence.
enum PescedexVide {
    static let texte = "Ta première prise ouvrira ton Pescedex"
    static func estVide(_ emplacements: [Emplacement]) -> Bool {
        !emplacements.contains { $0.carte != nil }
    }
}
