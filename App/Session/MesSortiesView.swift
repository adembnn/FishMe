import SwiftUI
import Core

/// P17 A « Plans » : l'historique des sorties terminées, la plus récente en haut. Une ligne par sortie :
/// les poissons en images (ou des vagues pour une bredouille), la date, la durée et les conditions.
/// Aucun point exact : le lieu est un nom d'eau flou.
///
/// À brancher par A : `MesSortiesView(sorties: moteur.sortiesTerminees, infosEspece: …, lieu: …, surChoix: …, surRetour: …)`.
struct MesSortiesView: View {
    let sorties: [Sortie]
    let infosEspece: (Espece) -> EspecePechable?
    /// « la Marne » ; `nil` : rien n'est écrit.
    let lieu: String?
    let surChoix: (Sortie) -> Void
    let surRetour: () -> Void

    init(sorties: [Sortie], infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, lieu: String? = nil,
         surChoix: @escaping (Sortie) -> Void = { _ in }, surRetour: @escaping () -> Void = {}) {
        self.sorties = sorties
        self.infosEspece = infosEspece
        self.lieu = lieu
        self.surChoix = surChoix
        self.surRetour = surRetour
    }

    private var triees: [Sortie] { sorties.filter { $0.fin != nil }.sorted { $0.debut > $1.debut } }

    var body: some View {
        ZStack(alignment: .bottom) {
            fondCarte
            feuille
        }
        .background(Palette.fond)
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .retour, rendu: .verre, action: surRetour)
                .padding(.leading, Espace.bord)
                .padding(.top, Espace.s)
        }
    }

    /// P17 A : la carte de la zone derrière la feuille (aplats d'eau, pas de point exact).
    private var fondCarte: some View {
        GeometryReader { geo in
            ZStack {
                Palette.fond
                Palette.eauClaire.frame(height: geo.size.height * 0.2).rotationEffect(.degrees(-12)).offset(y: 20)
                Palette.eau.frame(height: geo.size.height * 0.1).rotationEffect(.degrees(-12)).offset(y: 20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var feuille: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Capsule().fill(Palette.filet).frame(width: 36, height: 5).frame(maxWidth: .infinity)
            Text("Mes sorties")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            if triees.isEmpty {
                vide
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(triees.enumerated()), id: \.element.id) { index, sortie in
                            ligne(sortie)
                                .overlay(alignment: .top) {
                                    if index > 0 { Rectangle().fill(Palette.filet).frame(height: 0.5) }
                                }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: 340)
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.l)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: UnevenRoundedRectangle(topLeadingRadius: Rayon.l, topTrailingRadius: Rayon.l, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private var vide: some View {
        VStack(spacing: Espace.m) {
            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Palette.marine)
            Text("Ta première sortie t'attend")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Espace.xxl)
    }

    private func ligne(_ sortie: Sortie) -> some View {
        Button { surChoix(sortie) } label: {
            HStack(spacing: Espace.m) {
                vignettes(sortie)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(FormatSortie.date(sortie.debut)) · \(FormatSortie.duree(sortie))")
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                    Text(legende(sortie))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .lineLimit(2)
                }
                Spacer(minLength: Espace.s)
                Image(systemName: "chevron.right")
                    .font(Police.legende)
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    /// Jusqu'à deux espèces différentes en images ; vagues si la sortie est bredouille.
    @ViewBuilder private func vignettes(_ sortie: Sortie) -> some View {
        let especes = especesDistinctes(sortie)
        if especes.isEmpty {
            Image(systemName: "water.waves")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Palette.marine)
                .frame(width: 88, height: 56)
                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                .accessibilityHidden(true)
        } else {
            let largeur: CGFloat = especes.count == 1 ? 88 : 41
            HStack(spacing: 6) {
                ForEach(especes, id: \.id) { espece in
                    ZStack {
                        RoundedRectangle(cornerRadius: Rayon.s, style: .continuous).fill(Palette.tuile)
                        if let infos = infosEspece(espece) {
                            Image(infos.image).resizable().scaledToFit().padding(Espace.xs)
                        } else {
                            Image(systemName: "fish").foregroundStyle(Palette.marine)
                        }
                    }
                    .frame(width: largeur, height: 56)
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func especesDistinctes(_ sortie: Sortie) -> [Espece] {
        var vues = Set<String>()
        var rendu: [Espece] = []
        for prise in FormatSortie.prises(sortie) where vues.insert(prise.espece.id).inserted {
            rendu.append(prise.espece)
            if rendu.count == 2 { break }
        }
        return rendu
    }

    /// « Ton spot · Marne 1,42 m » n'est pas possible : le spot, la température et la hauteur d'eau
    /// ne sont pas dans `Sortie` (// À brancher : spot gratuit, température et hauteur d'eau par sortie).
    /// On écrit ce qui existe : le lieu flou, le vent, la pression, la rivière si elle est en crue.
    private func legende(_ sortie: Sortie) -> String {
        if FormatSortie.prises(sortie).isEmpty {
            let duree = FormatSortie.duree(sortie)
            if let lieu, !lieu.isEmpty { return "Bredouille, ça arrive : \(duree) sur \(lieu)" }
            return "Bredouille, ça arrive : \(duree)"
        }
        var morceaux: [String] = []
        if let lieu, !lieu.isEmpty { morceaux.append(lieu) }
        if let c = sortie.conditions.last {
            if let vent = c.ventKmh { morceaux.append("\(Int(vent.rounded())) km/h") }
            if let hpa = c.pressionHPa { morceaux.append("\(Int(hpa.rounded())) hPa") }
            if c.etatRiviere == .crue { morceaux.append("crue") }
        }
        let n = FormatSortie.prises(sortie).count
        morceaux.append(n == 1 ? "1 prise" : "\(n) prises")
        return morceaux.joined(separator: " · ")
    }
}

#if DEBUG
#Preview("Mes sorties") {
    let brochet = EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet")
    let t0 = Date(timeIntervalSince1970: 1_760_000_000)
    let s1 = Sortie(debut: t0, fin: t0.addingTimeInterval(5_040),
                    prises: [Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: t0)],
                    conditions: [Conditions(heure: t0, ventKmh: 12, pressionHPa: 1016)])
    let s2 = Sortie(debut: t0.addingTimeInterval(-604_800), fin: t0.addingTimeInterval(-604_800 + 7_200))
    MesSortiesView(sorties: [s2, s1], infosEspece: { _ in brochet }, lieu: "la Marne")
}

#Preview("Mes sorties vide") {
    MesSortiesView(sorties: [])
}
#endif
