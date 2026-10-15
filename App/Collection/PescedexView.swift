import Core
import SwiftUI

/// Le volet Pescedex : un classeur de cartes, des pages d'emplacements. La carte prise dans le sien, une silhouette dans les autres.
/// Aucune barre de défilement : les pages se tournent d'un balayage, sans ascenseur.
struct PescedexView: View {
    @State var modele: PescedexModele
    var emplacements: EmplacementsExternes = .vides

    @State private var vue: Vue = .cartes
    @State private var page = 0
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

    private static let parPage = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            entete
            Picker("Vue", selection: $vue) {
                ForEach(Vue.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Jeton.zoneTactile)
            switch vue {
            case .cartes: classeur
            case .bredouilles: rangeeBredouilles
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Jeton.fondPage.ignoresSafeArea())
        .task { await modele.charger() }
        .fullScreenCover(item: $carteOuverte) { emplacement in
            if let infos = modele.infos(pour: emplacement) {
                CartePleinEcranView(infos: infos, photo: photoOuverte, emplacements: emplacements_) {
                    carteOuverte = nil
                }
            }
        }
        .sheet(item: $ficheOuverte) { emplacement in
            FicheEspeceView(emplacement: emplacement, zone: modele.zone, emplacements: emplacements_)
        }
        .fullScreenCover(item: $bredouilleOuverte) { carte in
            BredouillePleinEcranView(carte: carte, services: modele.services, emplacements: emplacements_) {
                bredouilleOuverte = nil
            }
        }
        .sheet(isPresented: $conditionsOuvertes) {
            if let tes = emplacements.tesConditions { tes() }
        }
    }

    private var emplacements_: EmplacementsExternes { emplacements }

    private var entete: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pescedex")
                .font(Jeton.police(34))
                .foregroundStyle(Jeton.encre)
            Text(modele.compteur.texte)
                .font(Jeton.police(17, .semibold))
                .foregroundStyle(Jeton.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
            if emplacements.tesConditions != nil {
                Button { conditionsOuvertes = true } label: {
                    Label("Tes conditions", systemImage: "cloud.sun")
                        .font(Jeton.police(15))
                        .padding(.horizontal, 14)
                        .frame(minHeight: Jeton.zoneTactile)
                        .background(Jeton.papier, in: Capsule())
                }
                .foregroundStyle(Jeton.encre)
            }
        }
    }

    // MARK: Classeur

    private var pages: [[Emplacement]] {
        stride(from: 0, to: modele.emplacements.count, by: Self.parPage).map {
            Array(modele.emplacements[$0..<min($0 + Self.parPage, modele.emplacements.count)])
        }
    }

    private var classeur: some View {
        VStack(spacing: 8) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, lot in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(lot) { emplacement in
                            cellule(emplacement)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            if pages.count > 1 {
                Text("Page \(page + 1) sur \(pages.count)")
                    .font(Jeton.police(13, .semibold))
                    .foregroundStyle(Jeton.encreDouce)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 4)
            }
        }
    }

    private func cellule(_ e: Emplacement) -> some View {
        Button {
            if let carte = e.carte {
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
                    .font(Jeton.police(16, .semibold))
                    .foregroundStyle(Jeton.encreDouce)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(modele.bredouilles) { b in
                            Button { bredouilleOuverte = b } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: "water.waves")
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                    Text(Formats.date(b.debut)).font(Jeton.police(13)).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .foregroundStyle(Jeton.ardoise)
                                .frame(maxWidth: .infinity, minHeight: 96)
                                .background(Jeton.papier, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

/// Un emplacement du classeur : la carte prise, ou la silhouette de l'espèce.
struct EmplacementView: View {
    let emplacement: Emplacement

    var body: some View {
        let style = StyleRarete(emplacement.rarete.niveau)
        let prise = emplacement.carte
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                if let prise {
                    LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
                    Image(emplacement.espece.image)
                        .resizable().scaledToFit().padding(6)
                        .saturation(prise.estDeclaree ? 0.35 : 1)
                    BadgeRarete(style: style, taille: 26).padding(5)
                } else {
                    Color(red: 0.86, green: 0.90, blue: 0.93)
                    Image(emplacement.espece.image)
                        .renderingMode(.template)
                        .resizable().scaledToFit().padding(10)
                        .foregroundStyle(Jeton.ardoise.opacity(0.55))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text(emplacement.espece.nom)
                .font(Jeton.police(13))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(prise == nil ? Jeton.ardoise : Jeton.encre)
            if let prise, !prise.estDeclaree { PointsRarete(style: style, taille: 8) }
            if prise?.estDeclaree == true {
                Text("DÉCLARÉE").font(Jeton.police(9)).foregroundStyle(Jeton.ardoise)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Jeton.papier.opacity(prise == nil ? 0.55 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            if prise?.estDeclaree == true {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Jeton.ardoise, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
        }
    }
}

/// Le dos d'une espèce pas encore prise : sa silhouette, sa rareté dans la zone, et l'emplacement de « comment la pêcher » (L13).
struct FicheEspeceView: View {
    let emplacement: Emplacement
    let zone: Departement?
    let emplacements: EmplacementsExternes

    var body: some View {
        let style = StyleRarete(emplacement.rarete.niveau)
        VStack(alignment: .leading, spacing: 14) {
            Image(emplacement.espece.image)
                .renderingMode(.template)
                .resizable().scaledToFit()
                .foregroundStyle(Jeton.ardoise.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: 180)
                .accessibilityHidden(true)
            Text(emplacement.espece.nom).font(Jeton.police(30)).foregroundStyle(Jeton.encre)
            Text(emplacement.espece.nomLatin).font(Jeton.police(15, .semibold)).italic().foregroundStyle(Jeton.encreDouce)
            if let zone, style != .nonMesuree {
                HStack(spacing: 10) {
                    BadgeRarete(style: style, taille: 30)
                    Text("\(style.mot.capitalized) dans le \(zone.code)")
                        .font(Jeton.police(17))
                        .foregroundStyle(Jeton.encre)
                }
            }
            if let comment = emplacements.commentLaPecher {
                comment(emplacement.espece.espece)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .background(Jeton.fondPage.ignoresSafeArea())
    }
}
