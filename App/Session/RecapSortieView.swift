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
    let surPhotoSortie: ((Data) -> Void)?
    let rarete: (Prise) -> ResultatRarete?
    let estNouvelleEspece: (Espece) -> Bool

    @Environment(\.dynamicTypeSize) private var tailleTexte
    /// La photo ajoutée à l'instant, montrée tout de suite sur la carte « Eau calme ».
    @State private var photoAjoutee: UIImage?

    private var sortie: Sortie { fin.sortie }
    private var prises: [Prise] { FormatSortie.prises(sortie) }
    private var nbEspeces: Int { Set(prises.map(\.espece.id)).count }

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.xl) {
                enTete
                chiffres
                if prises.isEmpty { bredouille } else { RecapSortieCartes(cartes: cartes) }
                if let message = fin.message {
                    Text(message)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Espace.bord)
                }
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
            Button("Terminer", action: surTerminer)
                .buttonStyle(.principal)
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.m)
                .background(Palette.fond)
        }
    }

    // MARK: En-tête

    private var enTete: some View {
        VStack(spacing: Espace.s) {
            Text("La pêche du jour")
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
        if let lieu, !lieu.isEmpty { return "Belle sortie sur \(lieu) · \(date)" }
        return "Belle sortie · \(date)"
    }

    // MARK: Trois chiffres

    private var chiffres: some View {
        let duree = FormatSortie.duree(sortie)
        let contenu = Group {
            tuile(valeur: duree.isEmpty ? "–" : duree, legende: "sur l'eau")
            tuile(valeur: "\(prises.count)", legende: prises.count > 1 ? "prises" : "prise")
            tuile(valeur: "\(nbEspeces)", legende: nbEspeces > 1 ? "espèces" : "espèce")
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
            return RecapCarte(id: prise.id, infos: infos, nouvelle: estNouvelleEspece(prise.espece))
        }
    }

    // MARK: Sortie sans prise

    private var bredouille: some View {
        VStack(spacing: Espace.l) {
            RecapCarteBredouille(carte: CarteBredouille(id: sortie.id, debut: sortie.debut, fin: sortie.fin, lieuFlou: lieu,
                                                        conditions: sortie.conditions.first),
                                 photo: photoAjoutee)
            VStack(spacing: Espace.xs) {
                Text("Tu y étais, c'est ce qui compte")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                Text("Voici ta carte Eau calme, rangée dans ta collection.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Espace.bord)
            if let conseil, !conseil.isEmpty {
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text("La prochaine fois").font(Police.sousTitre).foregroundStyle(Palette.encre)
                    Text(conseil).font(Police.detail).foregroundStyle(Palette.encreDouce)
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
