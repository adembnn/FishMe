import MapKit
import SwiftUI
import Core

/// La fiche d'un coin (E2) : le lieu, les espèces en images, les règles du jour en liste de contrôle.
/// Gratuite et ouverte sans abonnement. Les deux emplacements (L12 : rangée « maintenant » et jauge ; L13 : 1er conseil)
/// sont des fermetures que A remplit ; vides par défaut, la fiche marche seule.
struct FicheCoinView: View {
    @State private var modele: ModeleFiche
    @State private var aideCategorie = false
    @State private var toutesLesRegles = false
    let emplacementMaintenant: (Coordonnee) -> AnyView
    let emplacementConseil: (Espece) -> AnyView

    init(services: ServicesCarte, selection: CoinSelectionne, pechables: [EspecePechable],
         emplacementMaintenant: @escaping (Coordonnee) -> AnyView = { _ in AnyView(EmptyView()) },
         emplacementConseil: @escaping (Espece) -> AnyView = { _ in AnyView(EmptyView()) }) {
        _modele = State(initialValue: ModeleFiche(services: services, selection: selection, pechables: pechables))
        self.emplacementMaintenant = emplacementMaintenant
        self.emplacementConseil = emplacementConseil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let fiche = modele.fiche {
                    entete(fiche)
                    emplacementMaintenant(modele.selection.coordonnee)
                    if let coin = modele.selection.coin {
                        releveDuFiltre(coin)
                    }
                    regles(fiche)
                    especes(fiche)
                    pied
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 120)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .task { await modele.charger() }
    }

    // MARK: En-tête : lieu, eau, catégorie

    private func entete(_ fiche: FicheCalculee) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(fiche.lieuFlou)
                    .font(PolicesCarte.titre())
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                pastilleCategorie(fiche.lieu)
            }
            choixEau(fiche)
            bandeauCouverture(fiche.couverture)
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
        return HStack(spacing: 4) {
            Menu {
                Button("1re catégorie") { Task { await modele.choisirCategorie(.premiere) } }
                Button("2e catégorie") { Task { await modele.choisirCategorie(.deuxieme) } }
                Button("Je ne sais pas") { Task { await modele.choisirCategorie(nil) } }
            } label: {
                Text(texte)
                    .font(PolicesCarte.corps())
                    .frame(minWidth: 36)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CouleursCarte.accent.opacity(0.15), in: Capsule())
                    .foregroundStyle(CouleursCarte.accent)
            }
            .accessibilityLabel("Catégorie de l'eau : \(libelle)")
            .accessibilityHint("Choisir la catégorie")
            Button { aideCategorie = true } label: {
                Image(systemName: "info.circle")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(CouleursCarte.accent)
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
                    .font(PolicesCarte.detail())
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.up.chevron.down")
                    .font(PolicesCarte.legende())
            }
            .foregroundStyle(CouleursCarte.accent)
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
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .accessibilityHidden(true)
            Text(texte)
                .fixedSize(horizontal: false, vertical: true)
            if let lien, let url = URL(string: lien) {
                Link("lien de la fédération", destination: url)
            }
        }
        .font(PolicesCarte.legende())
        .foregroundStyle(CouleursCarte.attention)
    }

    // MARK: Relevé du filtre

    private func releveDuFiltre(_ coin: Coin) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(texteReleve(nPeches: coin.nPeches, annee: coin.annee)) · \(coin.ouverture.texte)")
                .font(PolicesCarte.detail())
                .foregroundStyle(.secondary)
            Text(TexteOFB.explication)
                .font(PolicesCarte.legende())
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Espèces en images

    private func especes(_ fiche: FicheCalculee) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if fiche.especes.isEmpty {
                Label("Aucun relevé OFB à proximité", systemImage: "magnifyingglass")
                    .font(PolicesCarte.corps())
                    .foregroundStyle(.secondary)
            } else {
                ForEach(fiche.especes) { ligne in
                    Button {
                        Task { await modele.toucherEspece(ligne.espece) }
                    } label: {
                        RangeeEspece(nom: modele.nom(ligne.espece), image: modele.image(ligne.espece), nPeches: ligne.nPeches,
                                     annee: ligne.releve ? ligne.annee : nil, rarete: ligne.rarete, ouverture: ligne.ouverture,
                                     selectionnee: modele.especeTouchee == ligne.espece, releve: ligne.releve)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(modele.especeTouchee == ligne.espece ? .isSelected : [])
                    if modele.especeTouchee == ligne.espece {
                        emplacementConseil(ligne.espece)
                    }
                }
            }
        }
    }

    // MARK: Règles du jour

    private func regles(_ fiche: FicheCalculee) -> some View {
        let visibles = OrdreRegles.visibles(fiche.lignes, toutVoir: toutesLesRegles)
        return VStack(alignment: .leading, spacing: 0) {
            Text(modele.especeTouchee.map { "Règles du jour : \(modele.nom($0))" } ?? "Règles du jour")
                .font(PolicesCarte.legende())
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 4)
            ForEach(Array(visibles.enumerated()), id: \.offset) { _, ligne in
                LigneRegleView(ligne: ligne, categorieInconnue: fiche.lieu.categorie.valeur == .inconnue,
                               tronconConfirme: ligne.libelleTroncon.map { fiche.lieu.tronconsConfirmes.contains($0) } ?? false,
                               confirmerTroncon: { libelle in Task { await modele.confirmerTroncon(libelle) } })
                Divider()
            }
            if fiche.lignes.count > OrdreRegles.apercu {
                Button {
                    withAnimation(.snappy) { toutesLesRegles.toggle() }
                } label: {
                    Text(toutesLesRegles ? "Voir moins" : "Voir toutes les règles (\(fiche.lignes.count))")
                        .font(PolicesCarte.corps())
                        .foregroundStyle(CouleursCarte.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text("Information indicative : l'arrêté préfectoral fait foi.")
                .font(PolicesCarte.legende())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    // MARK: Pied

    private var pied: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: ouvrirDansPlans) {
                Label("Y aller", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(PolicesCarte.corps())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(CouleursCarte.accent)

            Text("En cas de doute, relâche.")
                .font(PolicesCarte.legende())
                .foregroundStyle(.secondary)
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
