import Core
import SwiftUI
import UIKit

/// La page récap de fin de sortie : « La pêche du jour ». En haut le lieu (l'eau, jamais le point), la date et trois chiffres ;
/// au centre les cartes que la sortie a créées en carrousel, ou la carte « Eau calme » quand rien n'a mordu ; en bas « Terminer ».
/// Pas de chargement, pas de carte géographique.
struct RecapSortieView: View {
    let fin: FinDeSession
    let infosEspece: (Espece) -> EspecePechable?
    let lieu: String?
    let conseil: String?
    let surTerminer: () -> Void
    let surFermer: (() -> Void)?
    let poidsEstime: (Espece, Double) -> PoidsEstime?
    let especeConseil: Espece?
    let surPhotoSortie: ((Data) -> Void)?
    let rarete: (Prise) -> ResultatRarete?
    let estNouvelleEspece: (Espece) -> Bool
    var photoDe: (Prise) -> Data? = { _ in nil }

    @Environment(\.dynamicTypeSize) private var tailleTexte
    /// La photo ajoutée à l'instant, montrée tout de suite sur la carte « Eau calme ».
    @State private var photoAjoutee: UIImage?

    private var sortie: Sortie { fin.sortie }
    private var prises: [Prise] { FormatSortie.prises(sortie) }
    private var nbEspeces: Int { Set(prises.map(\.espece.id)).count }

    /// Le poisson de profil de l'espèce conseillée ; sans espèce, une silhouette.
    private var tuileConseil: some View {
        let infos = especeConseil.flatMap { infosEspece($0) }
        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.tuile)
            if let infos {
                Image(infos.image).resizable().scaledToFit().frame(width: 67, height: 42)
            } else {
                Image(systemName: "fish.fill").font(Police.taille(26, .heavy)).foregroundStyle(Palette.silhouette)
            }
        }
        .frame(width: 84, height: 56)
        .accessibilityHidden(true)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.xl) {
                enTete
                // Le message de fin (« Session terminée à la fin légale ») sous le titre : en bas il passait sous « Terminer ».
                if let message = fin.message {
                    Text(AnglaisF.t(message))
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Espace.bord)
                }
                chiffres
                if prises.isEmpty { bredouille } else { RecapSortieCartes(cartes: cartes, photoDe: photoDe) }
            }
            .padding(.top, surFermer == nil ? Espace.xl : Gabarit.zoneTactile + Espace.xl)
            .padding(.bottom, Espace.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            if let surFermer {
                BoutonRond(role: .fermer, rendu: .verre, action: surFermer)
                    .padding(.leading, Espace.bord)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(AnglaisF.t("Terminer"), action: surTerminer)
                .buttonStyle(.principal)
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.m)
                .background(Palette.fond)
        }
    }

    // MARK: En-tête

    private var enTete: some View {
        VStack(spacing: Espace.s) {
            Text(AnglaisF.t("La pêche du jour"))
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            Text(sousTitre)
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Espace.bord)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    /// « Belle sortie sur la Marne · 16 oct. ».
    private var sousTitre: String {
        let date = FormatSortie.date(sortie.debut)
        if let lieu, !lieu.isEmpty { return AnglaisF.f("Belle sortie sur %@ · %@", lieu, date) }
        return AnglaisF.f("Belle sortie · %@", date)
    }

    // MARK: Trois chiffres

    private var chiffres: some View {
        let duree = FormatSortie.duree(sortie)
        let contenu = Group {
            tuile(valeur: duree.isEmpty ? "–" : duree, legende: AnglaisF.t("sur l'eau"))
            tuile(valeur: "\(prises.count)", legende: AnglaisF.t(prises.count > 1 ? "prises" : "prise"))
            tuile(valeur: "\(nbEspeces)", legende: AnglaisF.t(nbEspeces > 1 ? "espèces" : "espèce"))
        }
        return Group {
            if tailleTexte.isAccessibilitySize {
                VStack(spacing: Espace.s) { contenu }
            } else {
                HStack(spacing: Espace.s) { contenu }
            }
        }
        .padding(.horizontal, Espace.bord)
    }

    private func tuile(valeur: String, legende: String) -> some View {
        VStack(spacing: Espace.xs) {
            Text(valeur)
                .font(Police.chiffreMoyen)
                .foregroundStyle(Palette.encre)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(legende)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, Espace.m)
        .frame(maxWidth: .infinity)
        .tuileFishMe()
        .accessibilityElement(children: .combine)
    }

    // MARK: Les cartes de la sortie

    private var cartes: [RecapCarte] {
        prises.compactMap { prise in
            guard let espece = infosEspece(prise.espece) else { return nil }
            let niveau = rarete(prise) ?? ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0,
                                                         anneeDernierReleve: nil, echelle: .departement)
            let infos = InfosCarte(
                detail: CarteDetaillee(prise: prise, conditions: sortie.conditions.last,
                                       dureeSecondes: sortie.fin.map { $0.timeIntervalSince(sortie.debut) }),
                espece: espece, rarete: niveau,
                departement: Formats.departement(depuisLieuFlou: prise.lieuFlou), rangDansLaZone: nil,
                poids: prise.longueurCm.flatMap { poidsEstime(prise.espece, $0) },
                lune: .nouvelle, consigne: nil, sourceConsigne: nil)
            return RecapCarte(id: prise.id, prise: prise, infos: infos, nouvelle: estNouvelleEspece(prise.espece))
        }
    }

    // MARK: Sortie sans prise

    private var bredouille: some View {
        VStack(spacing: Espace.l) {
            RecapCarteBredouille(carte: CarteBredouille(id: sortie.id, debut: sortie.debut, fin: sortie.fin, lieuFlou: lieu,
                                                        conditions: sortie.conditions.first),
                                 photo: photoAjoutee)
            VStack(spacing: Espace.xs) {
                Text(AnglaisF.t("Tu y étais, c'est ce qui compte"))
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                Text(AnglaisF.t("Voici ta carte Eau calme, rangée dans ta collection."))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Espace.bord)
            if let conseil, !conseil.isEmpty {
                HStack(spacing: Espace.m) {
                    tuileConseil
                    VStack(alignment: .leading, spacing: Espace.xs) {
                        Text(AnglaisF.t("La prochaine fois")).font(Police.sousTitre).foregroundStyle(Palette.encre)
                        Text(conseil).font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                    Spacer(minLength: 0)
                }
                .padding(Espace.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .tuileFishMe()
                .padding(.horizontal, Espace.bord)
                .accessibilityElement(children: .combine)
            }
            if let surPhotoSortie {
                AjoutPhotoSortieView(surPhoto: { data in
                    photoAjoutee = UIImage(data: data)
                    surPhotoSortie(data)
                })
                .padding(.horizontal, Espace.l)
                .tuileFishMe()
                .padding(.horizontal, Espace.bord)
            }
        }
    }
}

#if DEBUG
#Preview("Récap avec prises") {
    let brochet = EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet")
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let prises = [Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: debut),
                  Prise(espece: Espece(id: "brochet"), longueurCm: 54, date: debut)]
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(5_040), prises: prises)
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .aucun), infosEspece: { _ in brochet },
                   lieu: "la Marne", surTerminer: {}, estNouvelleEspece: { _ in true })
}

#Preview("Récap bredouille") {
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(7_200))
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .quiSeFerme), lieu: "la Marne", surTerminer: {},
                   surPhotoSortie: { _ in })
}
#endif
