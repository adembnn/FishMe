import SwiftUI
import Core

/// Le contenu de la feuille « Mon spot » (moyen, grand, plein écran) :
/// le nom de l'eau avec la pastille de fréquentation devant, la météo du moment (emplacement de L12 que A branche),
/// les poissons du spot en images, « Commencer une session », « Règles du spot » (règles groupées) et « Choisir un autre spot ».
/// Aucune phrase de verdict : le lieu, des images, des boutons. La feuille se ferme par la croix, la poignée ou un glissement vers le bas.
struct MonSpotView: View {
    let detent: DetentPanneau
    let apercu: ApercuSpot?
    /// Le niveau du tronçon du spot ; `nil` : pastille grise.
    let niveau: NiveauFrequentation?
    /// « 2,4 km » entre l'iPhone et le centre du spot ; `nil` sans position.
    let distance: String?
    /// Le spot d'eau touché qui a posé le cercle (nom et source) ; `nil` si le cercle vient d'ailleurs.
    let spotEauChoisi: SpotEau?
    /// Il n'y a pas encore de spot : la feuille propose d'en poser un.
    let sansSpot: Bool
    let meteo: AnyView
    let pechable: (Espece) -> EspecePechable?
    let peutChangerDeSpot: Bool
    let modeChoixDuSpot: Bool
    let commencer: (() -> Void)?
    let coinCalme: (() -> Void)?
    let reglesDuSpot: () -> Void
    let choisirUnAutreSpot: () -> Void
    let annulerChoix: () -> Void
    let ouvrirPoissons: (Espece?) -> Void
    let fermer: () -> Void
    /// « Mes repères » (N6) : ouvre la liste privée du pêcheur. `nil` : la rangée n'existe pas.
    var ouvrirReperes: (() -> Void)? = nil
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.m) {
                titre
                if sansSpot {
                    sansSpotContenu
                    rangeeReperes
                } else {
                    meteo
                    tuiles
                    if detent >= .grand { legende }
                    boutons
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: Titre

    private var titre: some View {
        HStack(alignment: .center, spacing: Espace.m) {
            if !sansSpot {
                PastilleFrequentationView(niveau: niveau)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(sansSpot ? MonSpotTextes.t("Mon spot", locale) : (apercu?.lieu ?? MonSpotTextes.t("Mon spot", locale)))
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let distance, !sansSpot {
                    Text(distance)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            Spacer(minLength: Espace.s)
            Button(action: fermer) {
                Image(systemName: "xmark")
                    .font(Police.taille(18, .heavy))
                    .foregroundStyle(Palette.encre)
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                    .background(Palette.encre.opacity(0.06), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(MonSpotTextes.t("Fermer Mon spot", locale))
        }
    }

    // MARK: Pas de spot

    private var sansSpotContenu: some View {
        PasDeSpotView(choisirUnSpot: choisirUnAutreSpot)
    }

    // MARK: Les poissons du spot

    @ViewBuilder
    private var tuiles: some View {
        if let apercu {
            let lignes: [LigneEspece] = lignesDeLaFeuille(apercu)
            HStack(alignment: .top, spacing: 10) {
                ForEach(lignes) { (ligne: LigneEspece) in
                    tuilePoisson(ligne)
                }
                if resteDeLaFeuille(apercu) > 0 {
                    tuileReste(resteDeLaFeuille(apercu))
                }
            }
        } else {
            // Relevés en cours de lecture : la place des tuiles reste, sans rien inventer.
            Color.clear.frame(height: 52 + 6 + 14)
        }
    }

    /// Les trois premières espèces du spot : la plus pêchée, puis les suivantes.
    private func lignesDeLaFeuille(_ apercu: ApercuSpot) -> [LigneEspece] {
        var toutes: [LigneEspece] = []
        if let vedette = apercu.vedette { toutes.append(vedette) }
        toutes.append(contentsOf: apercu.autres)
        return Array(toutes.prefix(3))
    }

    private func resteDeLaFeuille(_ apercu: ApercuSpot) -> Int {
        let total: Int = (apercu.vedette == nil ? 0 : 1) + apercu.autres.count + apercu.reste
        return max(0, total - 3)
    }

    private func tuilePoisson(_ ligne: LigneEspece) -> some View {
        let fiche = pechable(ligne.espece)
        let niveau: NiveauRarete = ligne.rarete?.niveau ?? .nonMesuree
        return Button { ouvrirPoissons(ligne.espece) } label: {
            VStack(spacing: 6) {
                ImageEspeceCarte(nom: fiche?.image)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 6)
                    .frame(height: 52)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                marqueRarete(niveau)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(fiche?.nom ?? ligne.espece.id)
        .accessibilityValue(niveau == .nonMesuree ? "" : niveau.libelle(locale: locale))
    }

    @ViewBuilder
    private func marqueRarete(_ niveau: NiveauRarete) -> some View {
        if niveau == .nonMesuree {
            Color.clear.frame(width: 14, height: 14)
        } else {
            Image(systemName: niveau.symboleSF)
                .font(Police.taille(13, .heavy))
                .foregroundStyle(CouleursCarte.rarete(niveau))
                .frame(height: 14)
        }
    }

    private func tuileReste(_ reste: Int) -> some View {
        Button { ouvrirPoissons(nil) } label: {
            VStack(spacing: 6) {
                Text("+ \(reste)")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.filet, lineWidth: 1.5))
                Color.clear.frame(width: 14, height: 14)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MonSpotTextes.autresPoissons(reste, locale: locale))
    }

    // MARK: Légende (la vérité sur les relevés)

    @ViewBuilder
    private var legende: some View {
        if spotEauChoisi != nil || apercu?.noteHonnete != nil {
            VStack(spacing: 4) {
                if let eau = spotEauChoisi {
                    Label(eau.nom, systemImage: eau.origine.symboleSF)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text(MonSpotTextes.origineEtSource(libelle: eau.origine.libelle, source: eau.origine.source, locale: locale))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
                if let note = apercu?.noteHonnete {
                    Text(note)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Boutons

    @ViewBuilder
    private var boutons: some View {
        if let commencer {
            Button(action: commencer) {
                Label(MonSpotTextes.t("Commencer une session", locale), systemImage: "play.fill")
            }
            .buttonStyle(.principal)
        }
        Button(action: reglesDuSpot) {
            Label(MonSpotTextes.t("Règles du spot", locale), systemImage: "list.bullet.rectangle")
        }
        .buttonStyle(.secondaire)
        rangeeReperes
        if let niveau, niveau == .charge, let coinCalme {
            FrequentationFicheView(niveau: niveau, onCoinCalme: coinCalme)
        }
        lienAutreSpot
    }

    /// « Mes repères » : parkings, postes, dangers et amorçages que le pêcheur a posés lui-même (liste de N6, privée).
    @ViewBuilder
    private var rangeeReperes: some View {
        if let ouvrirReperes {
            Button(action: ouvrirReperes) {
                Label(MonSpotTextes.t(TextesReperes.titreListe, locale), systemImage: "signpost.right")
            }
            .buttonStyle(.secondaire)
            .accessibilityHint(MonSpotTextes.t("Ouvre la liste de tes repères, visibles de toi seul", locale))
        }
    }

    /// « Choisir un autre spot » ; pendant le choix, la consigne prend sa place (toucher l'annule).
    @ViewBuilder
    private var lienAutreSpot: some View {
        if modeChoixDuSpot {
            Button(action: annulerChoix) {
                Text(MonSpotTextes.t("Touche la rivière pour poser ton cercle de 1 km", locale))
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(MonSpotTextes.t("Touche pour annuler", locale))
        } else if peutChangerDeSpot {
            Button(action: choisirUnAutreSpot) {
                Text(MonSpotTextes.t("Choisir un autre spot", locale))
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
