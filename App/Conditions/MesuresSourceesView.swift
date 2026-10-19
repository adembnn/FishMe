import SwiftUI
import Core

/// Le bloc « Mesures » de N3 : pression, eau et débit, chacune avec sa valeur, sa tendance, sa source et son heure.
/// Aucun classement, aucune couleur d'alerte : une flèche en marine. Rien à montrer : le bloc ne s'affiche pas.
/// À placer sous la rangée « maintenant » (`RangeeMaintenantView`) et dans la feuille « Conditions du jour » : c'est le travail de A (L25).
struct MesuresSourceesView: View {
    let mesures: [MesureSourcee]
    @ObservedObject var marque: StockageMarque
    /// Date de la dernière lecture quand elle vient du cache faute de réseau.
    var luSansReseauLe: Date? = nil
    /// Vrai quand le bloc est déjà dans une feuille : ni tuile ni marge de tuile.
    var enFeuille: Bool = false

    @State private var aideOuverte = false
    @Environment(\.dynamicTypeSize) private var tailleTexte

    var body: some View {
        if !mesures.isEmpty {
            VStack(alignment: .leading, spacing: Espace.m) {
                titre
                ForEach(mesures, id: \.grandeur) { ligne($0) }
                if let date = luSansReseauLe {
                    Text(FormatMesures.luSansReseau(date))
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("mesures-cache")
                }
                // La marque Apple Weather reste sous tout bloc qui montre un chiffre WeatherKit (ici la pression).
                if mesures.contains(where: { $0.grandeur == .pression }) {
                    MarqueMeteoView(stockage: marque)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, enFeuille ? 24 : 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(HabillageMesures(actif: !enFeuille))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("mesures-sourcees")
            .sheet(isPresented: $aideOuverte) {
                AideMesuresView(grandeurs: Set(mesures.map(\.grandeur)), marque: marque)
            }
        }
    }

    private var titre: some View {
        HStack(spacing: Espace.s) {
            Text("Mesures").font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Espace.s)
            Button { aideOuverte = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(Police.titre).foregroundStyle(Palette.marine)
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Que veulent dire ces mesures ?")
            .accessibilityIdentifier("mesures-aide")
        }
    }

    private func ligne(_ m: MesureSourcee) -> some View {
        let ancienne = m.fraicheur == .ancienne
        return VStack(alignment: .leading, spacing: 2) {
            // Aux très grandes tailles de texte, le nom et la valeur passent l'un sous l'autre.
            let disposition = tailleTexte.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
                                                              : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Espace.s))
            disposition {
                HStack(spacing: Espace.s) {
                    Image(systemName: FormatMesures.icone(m.grandeur)).foregroundStyle(Palette.marine).frame(width: 24)
                        .accessibilityHidden(true)
                    Text(FormatMesures.nom(m.grandeur)).font(Police.corps).foregroundStyle(Palette.encre)
                }
                if !tailleTexte.isAccessibilitySize { Spacer(minLength: Espace.s) }
                Text(FormatMesures.valeur(m)).font(Police.chiffreMoyen)
                    .foregroundStyle(ancienne ? Palette.encreDouce : Palette.encre)
                    .minimumScaleFactor(0.7)
            }
            if let t = m.tendance, let e = FormatMesures.ecart(m) {
                HStack(spacing: Espace.xs) {
                    Image(systemName: FormatMesures.fleche(t.sens)).foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                    Text(e).font(Police.detail).foregroundStyle(Palette.encre)
                }
            }
            Text(FormatMesures.sourceEtHeure(m))
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(FormatMesures.accessibilite(m))
        .accessibilityIdentifier(FormatMesures.identifiant(m.grandeur))
    }
}

private struct HabillageMesures: ViewModifier {
    let actif: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if actif { content.tuileFishMe(rayon: Rayon.l) } else { content }
    }
}

/// La feuille du « ? ». Les phrases sont celles de la fiche N3 (⚠ à relire par Adem).
struct AideMesuresView: View {
    let grandeurs: Set<Grandeur>
    @ObservedObject var marque: StockageMarque
    @Environment(\.dismiss) private var fermer
    @Environment(\.openURL) private var ouvrir

    static let phrasePrincipale = "Simple mesure : on ne prédit pas la touche."
    static let phrasePression = "Beaucoup de pêcheurs y voient un bon signe. Les études ne sont pas d'accord."
    static let phraseEau = "La température vient d'une sonde de Hub'Eau, sur la station citée, pas sur ton spot."
    static var pageHubEau: URL { URL(string: "https://hubeau.eaufrance.fr")! }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.l) {
                    Text(Self.phrasePrincipale).font(Police.sousTitre).foregroundStyle(Palette.encre)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("mesures-aide-phrase")
                    if grandeurs.contains(.pression) {
                        paragraphe("Pression", Self.phrasePression)
                    }
                    if grandeurs.contains(.temperatureEau) {
                        paragraphe("Eau", Self.phraseEau)
                    }
                    if grandeurs.contains(.pression) {
                        MarqueMeteoView(stockage: marque)
                    }
                    if grandeurs.contains(.temperatureEau) || grandeurs.contains(.debit) {
                        Button { ouvrir(Self.pageHubEau) } label: {
                            Text("Hub'Eau, la source de l'eau et du débit")
                                .font(Police.corps).foregroundStyle(Palette.marine).underline()
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("mesures-lien-hubeau")
                    }
                }
                .padding(Espace.bord)
            }
            .scrollIndicators(.hidden)
            .background(Palette.surface)
            .navigationTitle("Ces mesures")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { fermer() }
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                        .accessibilityIdentifier("mesures-aide-fermer")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("mesures-aide-feuille")
    }

    private func paragraphe(_ titre: String, _ texte: String) -> some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(titre).font(Police.detail).foregroundStyle(Palette.encreDouce)
            Text(texte).font(Police.corps).foregroundStyle(Palette.encre).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Trois mesures") {
    MesuresSourceesView(mesures: ServiceMesuresFaux().mesures(conditions: ConditionsFaux().lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: Date()),
                                                              eau: nil, temperature: nil, date: Date()),
                        marque: StockageMarque(source: SourceMarqueFaux(), dossier: nil))
        .padding()
}

#Preview("Sans réseau, eau ancienne") {
    let ancienne = MesureSourcee(grandeur: .temperatureEau, valeur: 11.4, unite: "°C", heure: Date().addingTimeInterval(-5 * 86_400),
                                 source: "Hub'Eau, station La Marne (essai), 4 km", fraicheur: .ancienne)
    MesuresSourceesView(mesures: [ancienne], marque: StockageMarque(source: SourceMarqueFaux(), dossier: nil),
                        luSansReseauLe: Date().addingTimeInterval(-3600))
        .padding()
}
#endif
