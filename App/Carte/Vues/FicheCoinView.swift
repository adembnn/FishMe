import MapKit
import SwiftUI
import Core

/// La fiche d'un coin (E2), version épurée (P07 A) : le nom de l'eau, 3 à 5 poissons en images avec un point de rareté,
/// la pastille « Ouvert aujourd'hui » (un toucher ouvre les règles, leurs sources et leurs citations),
/// une seule ligne « N pêches OFB · année » et un seul bouton principal.
/// Gratuite et ouverte sans abonnement. Les deux emplacements (L12 : rangée « maintenant » ; L13 : 1er conseil)
/// sont des fermetures que A remplit ; vides par défaut. L'emplacement « maintenant » vit derrière la pastille (feuille des règles),
/// le conseil s'affiche sous les poissons quand on en touche un.
struct FicheCoinView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var modele: ModeleFiche
    @State private var aideCategorie = false
    @State private var toutesLesRegles = false
    @State private var reglesOuvertes = false
    @State private var autresOuvertes = false
    @State private var hauteurContenu: CGFloat = 0
    @State private var sourceOuverte = false
    let emplacementMaintenant: (Coordonnee) -> AnyView
    let emplacementConseil: (Espece) -> AnyView
    /// « Commencer une session » : `nil` (pendant une session, ou sans spot) cache le bouton.
    let onCommencerSession: (() -> Void)?

    init(services: ServicesCarte, selection: CoinSelectionne, pechables: [EspecePechable],
         emplacementMaintenant: @escaping (Coordonnee) -> AnyView = { _ in AnyView(EmptyView()) },
         emplacementConseil: @escaping (Espece) -> AnyView = { _ in AnyView(EmptyView()) },
         onCommencerSession: (() -> Void)? = nil) {
        _modele = State(initialValue: ModeleFiche(services: services, selection: selection, pechables: pechables))
        self.emplacementMaintenant = emplacementMaintenant
        self.emplacementConseil = emplacementConseil
        self.onCommencerSession = onCommencerSession
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                if let fiche = modele.fiche {
                    entete(fiche)
                    poissons(fiche)
                    if let touchee = modele.especeTouchee {
                        emplacementConseil(touchee)
                    }
                    // Toujours visible. Sans action (session déjà en cours, ou aucun spot choisi), il reste grisé.
                    // À brancher : RootView / VueCarte passe `onCommencerSession` dès qu'un spot est choisi.
                    Button { onCommencerSession?() } label: {
                        Label("Commencer une session", systemImage: "play.fill")
                    }
                    .buttonStyle(.principal)
                    .disabled(onCommencerSession == nil)
                    .opacity(onCommencerSession == nil ? 0.45 : 1)
                    releve(fiche)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.l)
            .padding(.bottom, Espace.xl)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { hauteurContenu = $0 }
        }
        .scrollIndicators(.hidden)
        // Attente en page entière, bouchon au centre (jamais un petit bloc en haut de la feuille).
        .overlay {
            if modele.fiche == nil {
                EcranChargement(texte: "Chargement du spot")
            }
        }
        .animation(.easeOut(duration: 0.25), value: modele.fiche == nil)
        .overlay(alignment: .topTrailing) {
            BoutonRond(role: .fermer)
                .padding(.top, Espace.s)
                .padding(.trailing, Espace.bord)
        }
        .scrollBounceBehavior(.basedOnSize)
        // La feuille a la hauteur de son contenu (comme la maquette), et peut se tirer jusqu'en grand.
        .presentationDetents(hauteurContenu > 0 && modele.fiche != nil ? [.height(hauteurContenu + 24), .large] : [.medium, .large])
        .task { await modele.charger() }
        .sheet(isPresented: $reglesOuvertes) { feuilleRegles }
    }

    // MARK: En-tête : nom de l'eau, pastille d'ouverture

    private func nomEau(_ fiche: FicheCalculee) -> String {
        (modele.choix.eau ?? fiche.lieu.eau)?.nom ?? modele.selection.eau ?? fiche.lieuFlou
    }

    /// L'ouverture du jour : celle du coin si on la connaît, sinon « ouverte » si au moins une espèce l'est.
    private func ouverture(_ fiche: FicheCalculee) -> OuvertureDuJour? {
        if let coin = modele.selection.coin { return coin.ouverture }
        let connues = fiche.especes.compactMap(\.ouverture)
        if connues.isEmpty { return nil }
        return connues.first(where: { $0.estOuverte }) ?? connues.first
    }

    /// Le nom de l'eau et la croix sur une ligne, la pastille dessous, puis le but de la fiche en une phrase :
    /// rien ne se chevauche, la croix a sa place dans la ligne du titre.
    private func entete(_ fiche: FicheCalculee) -> some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            HStack(alignment: .center, spacing: Espace.m) {
                Text(nomEau(fiche))
                    .font(Police.taille(30, .heavy))
                    .foregroundStyle(Palette.encre)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Espace.s)
                BoutonRond(role: .fermer)
            }
            pastilleOuverture(ouverture(fiche))
            Text("Ce que tu peux pêcher ici aujourd'hui")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .padding(.top, Espace.s)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func pastilleOuverture(_ ouverture: OuvertureDuJour?) -> some View {
        let ouvert = ouverture?.estOuverte ?? true
        let texte: String
        if let ouverture {
            texte = ouverture.estOuverte ? "Ouvert aujourd'hui" : (String(ouverture.texte.prefix(1)).uppercased() + String(ouverture.texte.dropFirst()))
        } else {
            texte = "Règles du jour"
        }
        let fond = ouverture == nil ? Palette.marineDoux : (ouvert ? Palette.ouvertDoux : Palette.alerteDoux)
        let encre = ouverture == nil ? Palette.marine : (ouvert ? Palette.ouvert : Palette.alerte)
        return Button { reglesOuvertes = true } label: {
            HStack(spacing: Espace.s) {
                Circle().fill(encre).frame(width: 8, height: 8)
                    .accessibilityHidden(true)
                Text(texte)
                    .font(Police.detail)
                    .foregroundStyle(encre)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(fond, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Ouvre les règles du jour")
    }

    // MARK: Poissons en images, un point de rareté dessous

    private func poissons(_ fiche: FicheCalculee) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            if fiche.especes.isEmpty {
                Label("Aucun relevé OFB à proximité", systemImage: "magnifyingglass")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
            } else {
                HStack(alignment: .top, spacing: Espace.m) {
                    ForEach(Array(fiche.especes.prefix(3))) { ligne in
                        tuilePoisson(ligne)
                    }
                }
            }
        }
    }

    private func tuilePoisson(_ ligne: LigneEspece) -> some View {
        let choisie = modele.especeTouchee == ligne.espece
        let niveau = ligne.rarete?.niveau
        return Button {
            Task { await modele.toucherEspece(ligne.espece) }
        } label: {
            VStack(spacing: Espace.xs) {
                ImageEspeceCarte(nom: modele.image(ligne.espece))
                    .padding(Espace.s)
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
                        .strokeBorder(choisie ? Palette.marine : Color.clear, lineWidth: 2))
                HStack(spacing: 4) {
                    if let niveau, niveau != .nonMesuree {
                        Image(systemName: symbole(niveau))
                            .font(Police.taille(10))
                            .foregroundStyle(CouleursCarte.rarete(niveau))
                            .accessibilityHidden(true)
                    }
                    Text(modele.nom(ligne.espece))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                // Sans taille lisible dans la règle, rien n'est écrit (aucun chiffre inventé).
                Text(ligne.tailleMiniCm.map { "\($0) cm mini" } ?? " ")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                badgeOuverture(ligne.ouverture)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(modele.nom(ligne.espece) + ((niveau.map { $0 == .nonMesuree ? "" : ", " + $0.libelle }) ?? "")
                            + (ligne.tailleMiniCm.map { ", taille minimale \($0) centimètres" } ?? "")
                            + (ligne.ouverture.map { $0.estOuverte ? ", ouvert" : ", fermé" } ?? ""))
        .accessibilityHint("Montre les règles et le conseil de cette espèce")
        .accessibilityAddTraits(choisie ? [.isButton, .isSelected] : .isButton)
    }

    /// « Ouvert » en vert, « Fermé » en orange (une alerte), rien si l'ouverture n'est pas connue.
    @ViewBuilder
    private func badgeOuverture(_ ouverture: OuvertureDuJour?) -> some View {
        if let ouverture {
            Text(ouverture.estOuverte ? "Ouvert" : "Fermé")
                .font(Police.taille(12))
                .foregroundStyle(ouverture.estOuverte ? Palette.ouvert : Palette.alerte)
                .padding(.horizontal, Espace.s)
                .padding(.vertical, 3)
                .background(ouverture.estOuverte ? Palette.ouvertDoux : Palette.alerteDoux, in: Capsule())
        } else {
            Color.clear.frame(height: 20)
        }
    }

    /// Un point de couleur, et une forme différente par niveau pour se lire sans la couleur.
    private func symbole(_ niveau: NiveauRarete) -> String {
        switch niveau {
        case .commun, .nonMesuree: return "circle.fill"
        case .peuCommun: return "hexagon.fill"
        case .rare: return "diamond.fill"
        case .legendaire: return "star.fill"
        }
    }

    // MARK: Une seule ligne de relevé

    @ViewBuilder
    private func releve(_ fiche: FicheCalculee) -> some View {
        // Le chiffre vient de la station OFB choisie, sinon de la première espèce relevée ; jamais un chiffre inventé.
        let chiffre: (Int, Int)? = modele.selection.coin.map { ($0.nPeches, $0.annee) }
            ?? fiche.especes.first(where: { $0.releve }).map { ($0.nPeches, $0.annee) }
        if let chiffre {
            Text("\(chiffre.0) \(chiffre.0 > 1 ? "pêches" : "pêche") OFB · \(String(chiffre.1))")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: Feuille des règles (derrière la pastille)

    private var feuilleRegles: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.l) {
                    if let fiche = modele.fiche {
                        if let espece = modele.especeTouchee {
                            regleEspece(espece, fiche)
                        } else {
                            reglesDuJour(fiche)
                        }
                    }
                }
                .padding(Espace.bord)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Règles du jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(modele.especeTouchee == nil ? .automatic : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BoutonRond(role: .fermer, rendu: .simple) { reglesOuvertes = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    /// Les règles du jour du spot, sans espèce choisie.
    @ViewBuilder
    private func reglesDuJour(_ fiche: FicheCalculee) -> some View {
        HStack(spacing: Espace.s) {
            choixEau(fiche)
            Spacer(minLength: Espace.s)
            pastilleCategorie(fiche.lieu)
        }
        bandeauCouverture(fiche.couverture)
        emplacementMaintenant(modele.selection.coordonnee)
        regles(fiche)
        Text(TexteOFB.explication)
            .font(Police.legende)
            .foregroundStyle(Palette.encreDouce)
            .fixedSize(horizontal: false, vertical: true)
        pied
    }

    // MARK: Règle d'une espèce (P08 B)

    /// Une règle de taille, de période ou de quota ne passe en gros chiffre que si son nombre se lit dans la phrase de `Core`.
    private func regleEspece(_ espece: Espece, _ fiche: FicheCalculee) -> some View {
        let lignes = fiche.lignes
        let taille = lignes.first { $0.type == .taille }
        let tailleCm = taille.flatMap { LectureRegle.nombre(avant: "cm", dans: $0.phrase) }
        let periode = lignes.first { $0.type == .periode }
        let jusquau = periode.flatMap { LectureRegle.dateApresJusquAu($0.phrase) }
        let quota = lignes.first { $0.type == .quota }
        let parJour = quota.flatMap { LectureRegle.premierEntier($0.phrase) }
        let utilisees = [tailleCm == nil ? nil : taille, jusquau == nil ? nil : periode, parJour == nil ? nil : quota].compactMap { $0 }
        let autres = lignes.filter { ligne in !utilisees.contains(ligne) }
        let avecSources: LigneControle?
        if let taille, !taille.sources.isEmpty { avecSources = taille } else { avecSources = lignes.first(where: { !$0.sources.isEmpty }) }
        return VStack(alignment: .leading, spacing: Espace.l) {
            HStack {
                BoutonRond(role: .retour, rendu: .simple) { Task { await modele.toucherEspece(espece) } }
                    .offset(x: -Espace.s)
                Spacer(minLength: 0)
            }
            HStack(alignment: .center, spacing: Espace.m) {
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(modele.nom(espece))
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                    Text("Règles dans le \(fiche.lieu.departement.code)")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: Espace.s)
                ImageEspeceCarte(nom: modele.image(espece))
                    .frame(width: 120, height: 52)
            }
            VStack(spacing: 0) {
                if let tailleCm {
                    ligneValeur("Taille minimale") {
                        Text("\(tailleCm) cm").font(Police.chiffreMoyen).foregroundStyle(Palette.marine)
                    }
                }
                if let jusquau {
                    ligneValeur("Ouvert jusqu'au") {
                        Text(jusquau).font(Police.corps).foregroundStyle(Palette.encre)
                    }
                }
                if let parJour {
                    ligneValeur("Par jour") {
                        Text("\(parJour)").font(Police.corps).foregroundStyle(Palette.encre)
                    }
                }
                if !autres.isEmpty {
                    Button { withAnimation(.snappy) { autresOuvertes.toggle() } } label: {
                        ligneValeurContenu("Autres règles") {
                            HStack(spacing: Espace.s) {
                                Text("\(autres.count)").font(Police.corps).foregroundStyle(Palette.encreDouce)
                                Image(systemName: autresOuvertes ? "chevron.up" : "chevron.right")
                                    .font(Police.legende).foregroundStyle(Palette.silhouette)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    if autresOuvertes {
                        VStack(spacing: 0) {
                            ForEach(Array(autres.enumerated()), id: \.offset) { _, ligne in
                                LigneRegleView(ligne: ligne, categorieInconnue: fiche.lieu.categorie.valeur == .inconnue,
                                               tronconConfirme: ligne.libelleTroncon.map { fiche.lieu.tronconsConfirmes.contains($0) } ?? false,
                                               confirmerTroncon: { libelle in Task { await modele.confirmerTroncon(libelle) } })
                            }
                        }
                        .padding(.horizontal, Espace.l)
                        Divider().overlay(Palette.filet).padding(.leading, Espace.l)
                    }
                }
                if let avecSources {
                    Button { withAnimation(.snappy) { sourceOuverte.toggle() } } label: {
                        ligneValeurContenu("Source", titreMarine: true, separateur: sourceOuverte) {
                            Image(systemName: sourceOuverte ? "chevron.up" : "chevron.right")
                                .font(Police.legende).foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(sourceOuverte ? "Referme la source" : "Ouvre la source et la citation")
                    if sourceOuverte {
                        SourceCitationView(ligne: avecSources)
                            .padding(Espace.l)
                    }
                }
            }
            .tuileFishMe(rayon: Rayon.l)
            if let taille, taille.sources.count > 1 {
                Text("Deux textes se contredisent : " + taille.sources.map(\.titre).joined(separator: " · ") + ". Le plus strict est affiché.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Espace.l)
            }
        }
    }

    private func ligneValeur<V: View>(_ titre: String, @ViewBuilder valeur: () -> V) -> some View {
        ligneValeurContenu(titre, valeur: valeur)
    }

    /// Une ligne du groupe : le titre à gauche, la valeur à droite, un filet dessous.
    private func ligneValeurContenu<V: View>(_ titre: String, titreMarine: Bool = false, separateur: Bool = true,
                                             @ViewBuilder valeur: () -> V) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Espace.s) {
                Text(titre)
                    .font(Police.corps)
                    .foregroundStyle(titreMarine ? Palette.marine : Palette.encre)
                Spacer(minLength: Espace.s)
                valeur()
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
            if separateur { Divider().overlay(Palette.filet).padding(.leading, Espace.l) }
        }
    }

    private func pastilleCategorie(_ lieu: Lieu) -> some View {
        let texte: String
        switch lieu.categorie.valeur {
        case .premiere: texte = "1re"
        case .deuxieme: texte = "2e"
        case .inconnue: texte = "inconnue"
        }
        let libelle = TexteCategorie.libelle(lieu.categorie.valeur)
        return HStack(spacing: Espace.xs) {
            Menu {
                Button("1re catégorie") { Task { await modele.choisirCategorie(.premiere) } }
                Button("2e catégorie") { Task { await modele.choisirCategorie(.deuxieme) } }
                Button("Je ne sais pas") { Task { await modele.choisirCategorie(nil) } }
            } label: {
                Text(texte)
                    .font(Police.corps)
                    .frame(minWidth: 36)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, 6)
                    .background(Palette.marineDoux, in: Capsule())
                    .foregroundStyle(Palette.marine)
            }
            .accessibilityLabel("Catégorie de l'eau : \(libelle)")
            .accessibilityHint("Choisir la catégorie")
            Button { aideCategorie = true } label: {
                Image(systemName: "info.circle")
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(Palette.marine)
            .accessibilityLabel("Que veut dire la catégorie ?")
        }
        .alert("Catégorie de l'eau", isPresented: $aideCategorie) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(TexteCategorie.aide)
        }
    }

    private func choixEau(_ fiche: FicheCalculee) -> some View {
        let courante = modele.choix.eau ?? fiche.lieu.eau
        return Menu {
            ForEach(fiche.eaux, id: \.cle) { eau in
                Button(eau.nom) { Task { await modele.choisirEau(eau) } }
            }
            Button(ModeleFiche.planDEau.nom) { Task { await modele.choisirEau(ModeleFiche.planDEau) } }
            Button(ModeleFiche.autreEau.nom) { Task { await modele.choisirEau(ModeleFiche.autreEau) } }
        } label: {
            HStack(spacing: 6) {
                Text("Tu pêches sur : " + (courante?.nom ?? "choisis"))
                    .font(Police.detail)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Police.legende)
            }
            .foregroundStyle(Palette.marine)
        }
    }

    @ViewBuilder
    private func bandeauCouverture(_ couverture: CouvertureLocale) -> some View {
        switch couverture {
        case .complete:
            EmptyView()
        case .partielle(let lien):
            infoCouverture("règles locales en partie", lien: lien)
        case .nonSaisie(let lien):
            infoCouverture("règles locales non saisies", lien: lien)
        }
    }

    private func infoCouverture(_ texte: String, lien: String?) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: "info.circle")
                .accessibilityHidden(true)
            Text(texte)
                .fixedSize(horizontal: false, vertical: true)
            if let lien, let url = URL(string: lien) {
                Link("lien de la fédération", destination: url)
            }
        }
        .font(Police.legende)
        .foregroundStyle(CouleursCarte.attention)
    }

    private func regles(_ fiche: FicheCalculee) -> some View {
        let visibles = OrdreRegles.visibles(fiche.lignes, toutVoir: toutesLesRegles)
        return VStack(alignment: .leading, spacing: 0) {
            Text(modele.especeTouchee.map { "Règles du jour : \(modele.nom($0))" } ?? "Règles du jour")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .textCase(.uppercase)
                .padding(.bottom, Espace.xs)
            ForEach(Array(visibles.enumerated()), id: \.offset) { _, ligne in
                LigneRegleView(ligne: ligne, categorieInconnue: fiche.lieu.categorie.valeur == .inconnue,
                               tronconConfirme: ligne.libelleTroncon.map { fiche.lieu.tronconsConfirmes.contains($0) } ?? false,
                               confirmerTroncon: { libelle in Task { await modele.confirmerTroncon(libelle) } })
                Divider().overlay(Palette.filet)
            }
            if fiche.lignes.count > OrdreRegles.apercu {
                Button {
                    withAnimation(.snappy) { toutesLesRegles.toggle() }
                } label: {
                    Text(toutesLesRegles ? "Voir moins" : "Voir toutes les règles (\(fiche.lignes.count))")
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text("Information indicative : l'arrêté préfectoral fait foi.")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Espace.xs)
        }
    }

    private var pied: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Button(action: ouvrirDansPlans) {
                Label("Y aller", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
            }
            .buttonStyle(.secondaire)

            Text("En cas de doute, relâche.")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Plans d'Apple sur ce coin (la station OFB, jamais la position du pêcheur).
    private func ouvrirDansPlans() {
        let c = modele.selection.coordonnee
        let item = MKMapItem(location: CLLocation(latitude: c.latitude, longitude: c.longitude), address: nil)
        item.name = modele.fiche?.lieuFlou ?? "Coin de pêche"
        item.openInMaps()
    }
}

/// Lit un nombre dans la phrase d'une règle. Rien n'est inventé : sans nombre lisible, la ligne reste dans « Autres règles ».
nonisolated enum LectureRegle {
    /// Le nombre juste avant l'unité (« 60 cm » ou « 60cm »).
    static func nombre(avant unite: String, dans phrase: String) -> String? {
        let mots = phrase.split(whereSeparator: { $0 == " " || $0 == "\u{00A0}" || $0 == "\u{202F}" }).map(String.init)
        for (i, mot) in mots.enumerated() {
            let nettoye = mot.trimmingCharacters(in: .punctuationCharacters)
            if nettoye == unite, i > 0, let n = chiffres(mots[i - 1]) { return n }
            if nettoye.hasSuffix(unite), nettoye.count > unite.count, let n = chiffres(String(nettoye.dropLast(unite.count))) { return n }
        }
        return nil
    }

    /// Le premier entier de la phrase (« 3 par jour »).
    static func premierEntier(_ phrase: String) -> String? {
        let mots = phrase.split(whereSeparator: { !$0.isNumber && !$0.isLetter }).map(String.init)
        return mots.first { !$0.isEmpty && $0.count <= 2 && $0.allSatisfy(\.isNumber) }
    }

    /// « 31 déc. » quand la phrase dit « jusqu'au 31 décembre ».
    static func dateApresJusquAu(_ phrase: String) -> String? {
        let mots = phrase.split(separator: " ").map(String.init)
        guard let i = mots.firstIndex(where: { $0.lowercased().hasPrefix("jusqu") && ($0.lowercased().hasSuffix("au") || $0.lowercased().hasSuffix("à")) }),
              i + 2 < mots.count, mots[i + 1].allSatisfy(\.isNumber) else { return nil }
        let mois = mots[i + 2].trimmingCharacters(in: .punctuationCharacters)
        guard mois.allSatisfy(\.isLetter) else { return nil }
        let court = mois.count > 4 ? String(mois.prefix(3)) + "." : mois
        return mots[i + 1] + " " + court
    }

    private static func chiffres(_ mot: String) -> String? {
        let n = mot.trimmingCharacters(in: .punctuationCharacters)
        return !n.isEmpty && n.allSatisfy({ $0.isNumber || $0 == "," || $0 == "." }) ? n : nil
    }
}
