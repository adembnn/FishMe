import SwiftUI
import WidgetKit

// Cible widget seulement. Les vues du widget « Ma session » : peu de texte, de grands chiffres.
// Le chrono est rendu par le système (`Text(timerInterval:)`) : il tourne sans réveiller le widget.
// Orange (#E8571C) SEULEMENT pour « pêche fermée » et fin légale dépassée. Aucun lieu, aucun verdict.
// `WidgetAquarium/` n'importe pas `App/Style` : la palette « Marine » est répétée ici.

private enum Teintes {
    static let marineHaut = Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)   // #0D4A85
    static let marineBas = Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255)      // #082A4C
    static let alerte = Color(red: 232 / 255, green: 87 / 255, blue: 28 / 255)       // #E8571C
}

private let urlSession = URL(string: "fishme://session")
private let urlPrise = URL(string: "fishme://session/prise")
// Pas d'intent de pause côté app : un lien, que l'app interprète (voir la fiche Mac).
private let urlPause = URL(string: "fishme://session/pause")

private func heure(_ date: Date) -> Text {
    Text(date, format: .dateTime.hour().minute())
}

private extension Font {
    static func rond(_ taille: CGFloat) -> Font { .system(size: taille, weight: .bold, design: .rounded) }
}

struct VueSessionWidget: View {
    let entree: EntreeSessionWidget
    let famille: WidgetFamily
    /// Dessine le fond dans un ZStack (rendu en image hors widget) au lieu de `containerBackground`.
    var fondVisible: Bool = false

    init(entree: EntreeSessionWidget, famille: WidgetFamily, fondVisible: Bool = false) {
        self.entree = entree
        self.famille = famille
        self.fondVisible = fondVisible
    }

    private var affichage: AffichageSessionWidget {
        AffichageSessionWidget.calculer(etat: entree.etat, maintenant: entree.date)
    }

    private var fond: LinearGradient {
        LinearGradient(colors: [Teintes.marineHaut, Teintes.marineBas], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        switch famille {
        case .accessoryCircular: rond
        case .accessoryRectangular: rectangle
        default: ecranAccueil
        }
    }

    // MARK: Écran verrouillé (une teinte, pas de couleur)

    private var rond: some View {
        ZStack {
            AccessoryWidgetBackground()
            switch affichage.contenu {
            case .aucuneSession:
                Image(systemName: "fish").font(.rond(22))
            case .compteARebours(let debut, let fin):
                VStack(spacing: 0) {
                    Image(systemName: "fish.fill").font(.rond(11))
                    Text(timerInterval: debut...fin, pauseTime: nil, countsDown: true, showsHours: false)
                        .monospacedDigit().font(.rond(13)).minimumScaleFactor(0.6).multilineTextAlignment(.center)
                    Text("\(affichage.prises)").font(.rond(11))
                }
                .padding(2)
            case .finLegalePassee(let fin):
                VStack(spacing: 0) {
                    Image(systemName: "fish.fill").font(.rond(11))
                    heure(fin).monospacedDigit().font(.rond(14)).minimumScaleFactor(0.6)
                    Text("\(affichage.prises)").font(.rond(11))
                }
            case .pecheFermee:
                Image(systemName: "nosign").font(.rond(24))
            case .finInconnue(let depuis):
                VStack(spacing: 0) {
                    Image(systemName: "fish.fill").font(.rond(11))
                    Text(depuis, style: .timer).monospacedDigit().font(.rond(13)).minimumScaleFactor(0.6)
                        .multilineTextAlignment(.center)
                    Text("\(affichage.prises)").font(.rond(11))
                }
            }
        }
        .widgetURL(urlSession)
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangle: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch affichage.contenu {
            case .aucuneSession:
                Label("Pas de session", systemImage: "fish").font(.rond(15))
            case .compteARebours(let debut, let fin):
                Text(timerInterval: debut...fin, pauseTime: nil, countsDown: true, showsHours: true)
                    .monospacedDigit().font(.rond(26)).minimumScaleFactor(0.6).lineLimit(1)
                HStack {
                    Label("\(affichage.prises)", systemImage: "fish.fill")
                    Spacer()
                    heure(fin).monospacedDigit()
                }
                .font(.rond(13))
            case .finLegalePassee(let fin):
                heure(fin).monospacedDigit().font(.rond(26))
                Label("\(affichage.prises)", systemImage: "fish.fill").font(.rond(13))
            case .pecheFermee:
                Label("Pêche fermée", systemImage: "nosign").font(.rond(18))
                Label("\(affichage.prises)", systemImage: "fish.fill").font(.rond(13))
            case .finInconnue(let depuis):
                Text(depuis, style: .timer).monospacedDigit().font(.rond(26)).lineLimit(1)
                Label("\(affichage.prises)", systemImage: "fish.fill").font(.rond(13))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(urlSession)
        .containerBackground(for: .widget) { Color.clear }
    }

    // MARK: Écran d'accueil

    @ViewBuilder
    private var ecranAccueil: some View {
        let contenu = ecranAccueilContenu
            .foregroundStyle(.white)
            .widgetURL(urlSession)
        if fondVisible {
            ZStack {
                fond
                contenu.padding(16)
            }
        } else {
            contenu.containerBackground(for: .widget) { fond }
        }
    }

    @ViewBuilder
    private var ecranAccueilContenu: some View {
        if case .aucuneSession = affichage.contenu {
            invitation
        } else if famille == .systemMedium {
            moyen
        } else {
            petit
        }
    }

    private var invitation: some View {
        VStack(spacing: 8) {
            Image(systemName: "fish").font(.rond(34))
            Text("Pas de session").font(.rond(17)).minimumScaleFactor(0.7).lineLimit(1)
            Link(destination: urlSession ?? URL(fileURLWithPath: "/")) {
                Text("Commencer")
                    .font(.rond(14))
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(.white.opacity(0.2)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Le grand chrono, ou l'heure fixe, ou « pêche fermée ».
    @ViewBuilder
    private func gros(taille: CGFloat) -> some View {
        switch affichage.contenu {
        case .compteARebours(let debut, let fin):
            Text(timerInterval: debut...fin, pauseTime: nil, countsDown: true, showsHours: true)
                .monospacedDigit().font(.rond(taille)).minimumScaleFactor(0.5).lineLimit(1)
        case .finLegalePassee(let fin):
            VStack(alignment: .leading, spacing: 0) {
                Label("fin légale", systemImage: "sunset.fill").font(.rond(13))
                heure(fin).monospacedDigit().font(.rond(taille))
            }
            .foregroundStyle(Teintes.alerte)
        case .pecheFermee:
            Label("Pêche fermée", systemImage: "nosign")
                .font(.rond(taille * 0.55)).minimumScaleFactor(0.5).lineLimit(2)
                .foregroundStyle(Teintes.alerte)
        case .finInconnue(let depuis):
            Text(depuis, style: .timer)
                .monospacedDigit().font(.rond(taille)).minimumScaleFactor(0.5).lineLimit(1)
        case .aucuneSession:
            EmptyView()
        }
    }

    private var nombrePrises: some View {
        Label("\(affichage.prises)", systemImage: "fish.fill")
            .accessibilityLabel("\(affichage.prises) prises")
    }

    private var petit: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "fish.fill").font(.rond(16)).opacity(0.75)
            gros(taille: 34)
            Spacer(minLength: 0)
            HStack {
                nombrePrises.font(.rond(22))
                Spacer()
                if case .compteARebours(_, let fin) = affichage.contenu {
                    heure(fin).monospacedDigit().font(.rond(15)).opacity(0.8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var moyen: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    if case .compteARebours = affichage.contenu {
                        Text("fin légale dans").font(.rond(12)).opacity(0.75)
                    }
                    gros(taille: 40)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing, spacing: 4) {
                    nombrePrises.font(.rond(30))
                    if case .compteARebours(_, let fin) = affichage.contenu {
                        HStack(spacing: 4) { Image(systemName: "sunset.fill"); heure(fin).monospacedDigit() }
                            .font(.rond(15)).opacity(0.85)
                    }
                }
            }
            HStack(spacing: 8) {
                boutonLien("Prise", symbole: "plus.circle.fill", url: urlPrise)
                boutonLien("Pause", symbole: "pause.circle.fill", url: urlPause)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func boutonLien(_ titre: String, symbole: String, url: URL?) -> some View {
        if let url {
            Link(destination: url) {
                Label(titre, systemImage: symbole)
                    .font(.rond(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(.white.opacity(0.2)))
            }
        }
    }
}
