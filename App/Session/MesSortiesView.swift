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
    /// La croix en haut à gauche ferme l'écran.
    let surRetour: () -> Void
    /// Écran vide : le bouton « Commencer une session ». `nil` : pas de bouton.
    let surCommencer: (() -> Void)?

    init(sorties: [Sortie], infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, lieu: String? = nil,
         surChoix: @escaping (Sortie) -> Void = { _ in }, surRetour: @escaping () -> Void = {},
         surCommencer: (() -> Void)? = nil) {
        self.surCommencer = surCommencer
        self.sorties = sorties
        self.infosEspece = infosEspece
        self.lieu = lieu
        self.surChoix = surChoix
        self.surRetour = surRetour
    }

    private var triees: [Sortie] { sorties.filter { $0.fin != nil }.sorted { $0.debut > $1.debut } }

    var body: some View {
        // Maquette P17 A : la carte en fond (voilée à 20 %), retour de verre, feuille flottante « Mes sorties ».
        ZStack(alignment: .bottom) {
            FondCarteSession()
            Palette.fond.opacity(0.2).ignoresSafeArea().accessibilityHidden(true)
            FeuilleFlottante(basPadding: 16) {
                Text(AnglaisF.t("Mes sorties"))
                    .font(Police.taille(22, .heavy))
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                if triees.isEmpty {
                    vide
                } else {
                    // La feuille s'adapte à la liste ; au-delà de 440 pt, la liste défile.
                    ViewThatFits(in: .vertical) {
                        liste.padding(.top, 12)
                        ScrollView {
                            liste.padding(.top, 12)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .frame(maxHeight: 440)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .retour, rendu: .verre, action: surRetour)
                .padding(.leading, Espace.bord)
        }
    }

    private var liste: some View {
        VStack(spacing: 0) {
            ForEach(Array(triees.enumerated()), id: \.element.id) { index, sortie in
                ligne(sortie)
                    .overlay(alignment: .top) {
                        if index > 0 { Rectangle().fill(Palette.filet).frame(height: 0.5) }
                    }
            }
        }
    }

    private var vide: some View {
        VStack(spacing: Espace.l) {
            Image(systemName: "water.waves")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(Palette.marine)
            Text(AnglaisF.t("Ta première sortie t'attend"))
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            if let surCommencer {
                Button(AnglaisF.t("Commencer une session"), action: surCommencer)
                    .buttonStyle(.principal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espace.xl)
    }

    private func ligne(_ sortie: Sortie) -> some View {
        Button { surChoix(sortie) } label: {
            HStack(spacing: 14) {
                vignettes(sortie)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(FormatSortie.date(sortie.debut)) · \(FormatSortie.duree(sortie))")
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.encre)
                    Text(legende(sortie))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 12)
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
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Palette.marine)
                .frame(width: 88, height: 56)
                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
        } else {
            let largeur: CGFloat = especes.count == 1 ? 88 : 41
            HStack(spacing: 6) {
                ForEach(especes, id: \.id) { espece in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.tuile)
                        if let infos = infosEspece(espece) {
                            Image(infos.image).resizable().scaledToFit()
                                .frame(width: largeur * 0.86, height: especes.count == 1 ? 40 : 26)
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
    /// On écrit ce qui existe : le lieu flou, la rivière si elle est en crue, le nombre de prises.
    private func legende(_ sortie: Sortie) -> String {
        if FormatSortie.prises(sortie).isEmpty {
            let duree = FormatSortie.duree(sortie)
            if let lieu, !lieu.isEmpty { return AnglaisF.f("Bredouille, ça arrive : %@ sur %@", duree, lieu) }
            return AnglaisF.f("Bredouille, ça arrive : %@", duree)
        }
        var morceaux: [String] = []
        if let lieu, !lieu.isEmpty { morceaux.append(lieu) }
        if let c = sortie.conditions.last {
            if c.etatRiviere == .crue { morceaux.append(AnglaisF.bas("Crue")) }
        }
        let n = FormatSortie.prises(sortie).count
        morceaux.append(AnglaisF.nombre(n, un: "1 prise", autres: "%lld prises"))
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
