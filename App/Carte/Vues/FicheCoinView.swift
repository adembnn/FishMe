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
            VStack(alignment: .leading, spacing: Espace.l) {
                if let fiche = modele.fiche {
                    entete(fiche)
                    poissons(fiche)
                    if let touchee = modele.especeTouchee {
                        emplacementConseil(touchee)
                    }
                    if let onCommencerSession {
                        Button(action: onCommencerSession) {
                            Label("Commencer une session", systemImage: "play.fill")
                        }
                        .buttonStyle(.principal)
                    }
                    releve
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.xl + Espace.m)
            .padding(.bottom, Espace.xl)
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

    private func entete(_ fiche: FicheCalculee) -> some View {
        HStack(alignment: .center, spacing: Espace.m) {
            Text(nomEau(fiche))
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Espace.s)
            pastilleOuverture(ouverture(fiche))
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
                HStack(alignment: .top, spacing: Espace.s) {
                    ForEach(Array(fiche.especes.prefix(5))) { ligne in
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
            VStack(spacing: Espace.s) {
                ImageEspeceCarte(nom: modele.image(ligne.espece))
                    .padding(Espace.s)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
                        .strokeBorder(choisie ? Palette.marine : Color.clear, lineWidth: 2))
                if let niveau, niveau != .nonMesuree {
                    Image(systemName: symbole(niveau))
                        .font(Police.taille(11))
                        .foregroundStyle(CouleursCarte.rarete(niveau))
                        .accessibilityHidden(true)
                } else {
                    Color.clear.frame(height: 11)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(modele.nom(ligne.espece) + ((niveau.map { $0 == .nonMesuree ? "" : ", " + $0.libelle }) ?? ""))
        .accessibilityHint("Montre les règles et le conseil de cette espèce")
        .accessibilityAddTraits(choisie ? [.isButton, .isSelected] : .isButton)
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
    private var releve: some View {
        // Le chiffre vient du coin choisi (station OFB) ; sans coin, aucun chiffre n'est inventé.
        if let coin = modele.selection.coin {
            Text("\(coin.nPeches) \(coin.nPeches > 1 ? "pêches" : "pêche") OFB · \(String(coin.annee))")
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
                }
                .padding(Espace.bord)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Règles du jour")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BoutonRond(role: .fermer, rendu: .simple) { reglesOuvertes = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
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
