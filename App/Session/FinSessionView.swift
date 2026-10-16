import SwiftUI
import UIKit
import Core

/// Formats communs de la fin de session (P16) et de « Mes sorties » (P17).
enum FormatSortie {
    private static let francais = Locale(identifier: "fr_FR")

    /// « 1 h 24 », « 2 h », « 35 min ».
    static func duree(_ sortie: Sortie) -> String {
        guard let fin = sortie.fin else { return "" }
        let minutes = max(0, Int(fin.timeIntervalSince(sortie.debut) / 60))
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m) min" }
        return m == 0 ? "\(h) h" : "\(h) h \(m)"
    }

    /// « 12 oct. »
    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(francais))
    }

    /// Les prises de la sortie sans les cartes d'exemple.
    static func prises(_ sortie: Sortie) -> [Prise] { sortie.prises.filter { !$0.exemple } }
}

/// P16 A « Plans » : fin de session. La photo de la dernière prise en haut, une feuille dessous avec la durée,
/// la prise, les conditions et un seul bouton « Terminer ». Zéro prise : ton positif, jamais culpabilisant.
///
/// À brancher par A : `FinSessionView(fin: moteur.derniereFin, infosEspece: …, lieu: …) { moteur.acquitterFin() ; … }`.
struct FinSessionView: View {
    let fin: FinDeSession
    /// Nom, image et latin d'une espèce (le catalogue de L1 vit hors du dossier Session).
    let infosEspece: (Espece) -> EspecePechable?
    /// « la Marne » : l'eau, jamais le point exact. `nil` : rien n'est écrit.
    let lieu: String?
    /// Conseil « La prochaine fois » (cas bredouille). `nil` : le bloc n'est pas montré.
    /// // À brancher : le conseil vient des données de L1 (appât, heure) pour l'espèce visée ; rien n'est inventé ici.
    let conseil: String?
    let surTerminer: () -> Void
    let surFermer: () -> Void

    init(fin: FinDeSession, infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, lieu: String? = nil,
         conseil: String? = nil, surTerminer: @escaping () -> Void, surFermer: (() -> Void)? = nil) {
        self.conseil = conseil
        self.fin = fin
        self.infosEspece = infosEspece
        self.lieu = lieu
        self.surTerminer = surTerminer
        self.surFermer = surFermer ?? surTerminer
    }

    private var sortie: Sortie { fin.sortie }
    private var prises: [Prise] { FormatSortie.prises(sortie) }
    /// La plus grande prise, sinon la dernière : c'est elle que la maquette met en avant.
    private var vedette: Prise? {
        prises.max { ($0.longueurCm ?? 0) < ($1.longueurCm ?? 0) } ?? prises.last
    }
    private var conditions: Conditions? { sortie.conditions.last }

    var body: some View {
        ZStack(alignment: .bottom) {
            haut
            feuille
        }
        .background(Palette.nuit)
        .overlay(alignment: .topLeading) { boutonFermer }
    }

    // MARK: Haut de l'écran

    @ViewBuilder private var haut: some View {
        GeometryReader { geo in
            ZStack {
                Palette.nuit
                if vedette == nil {
                    // P47 A : le fond carte/eau de la sortie sans prise (pas de position exacte).
                    Palette.fond
                    Palette.eauClaire.frame(height: geo.size.height * 0.2).rotationEffect(.degrees(-12)).offset(y: 20)
                    Palette.eau.frame(height: geo.size.height * 0.1).rotationEffect(.degrees(-12)).offset(y: 20)
                } else if let photo = imageDe(vedette) {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 0.62)
                        .clipped()
                } else {
                    Image(systemName: "water.waves")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(Palette.surMarine.opacity(0.35))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height * 0.62)
            .clipped()
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var boutonFermer: some View {
        BoutonRond(role: .fermer, rendu: .verre, action: surFermer)
            .padding(.leading, Espace.bord)
        .padding(.top, Espace.s)
    }

    // MARK: Feuille

    private var feuille: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            Capsule().fill(Palette.filet).frame(width: 36, height: 5).frame(maxWidth: .infinity)
            enTete
            if let vedette {
                ligneVedette(vedette)
                if prises.count > 1 { autresPrises }
            }
            if let conditions { ligneConditions(conditions) }
            if vedette == nil { bredouille }
            if let message = fin.message {
                Text(message)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
            }
            Button("Terminer", action: surTerminer)
                .buttonStyle(.principal)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.l)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: UnevenRoundedRectangle(topLeadingRadius: Rayon.l, topTrailingRadius: Rayon.l, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private var enTete: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titre)
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            Spacer(minLength: Espace.s)
            Text(FormatSortie.date(sortie.debut))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
        }
    }

    /// « 1 h 24 sur la Marne » ou « 1 h 24 ».
    private var titre: String {
        let duree = FormatSortie.duree(sortie)
        if let lieu, !lieu.isEmpty {
            return vedette == nil ? "\(duree) au bord de \(lieu)" : "\(duree) sur \(lieu)"
        }
        return duree
    }

    private func ligneVedette(_ prise: Prise) -> some View {
        let infos = infosEspece(prise.espece)
        return HStack(spacing: Espace.m) {
            tuilePoisson(infos, largeur: 96, hauteur: 60)
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(titrePrise(prise, infos))
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                if let detail = detailPrise(prise) {
                    Text(detail)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func titrePrise(_ prise: Prise, _ infos: EspecePechable?) -> String {
        let nom = infos?.nom ?? prise.espece.id
        if let cm = prise.longueurCm { return "\(nom) · \(Int(cm.rounded())) cm" }
        return nom
    }

    /// « relâché » ou « gardé » : ce que le pêcheur a déclaré, jamais un verdict de l'app.
    /// Le poids estimé n'est pas dans `Prise` : // À brancher : poids estimé (formule longueur-poids de L3), marqué « estimé ».
    private func detailPrise(_ prise: Prise) -> String? {
        prise.gardee ? "gardé" : "relâché"
    }

    private var autresPrises: some View {
        HStack(spacing: Espace.s) {
            ForEach(prises.filter { $0.id != vedette?.id }.prefix(4)) { prise in
                tuilePoisson(infosEspece(prise.espece), largeur: 48, hauteur: 34)
            }
            Spacer(minLength: 0)
        }
    }

    /// Cas bredouille : zéro prise, ton positif. Le bloc « La prochaine fois » n'existe que si un conseil est fourni.
    @ViewBuilder private var bredouille: some View {
        if let conseil, !conseil.isEmpty {
            HStack(spacing: Espace.m) {
                Image(systemName: "fish")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 84, height: 56)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text("La prochaine fois")
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                    Text(conseil)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private func tuilePoisson(_ infos: EspecePechable?, largeur: CGFloat, hauteur: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Rayon.s, style: .continuous).fill(Palette.tuile)
            if let infos {
                Image(infos.image)
                    .resizable()
                    .scaledToFit()
                    .padding(Espace.xs)
            } else {
                Image(systemName: "fish")
                    .foregroundStyle(Palette.marine)
            }
        }
        .frame(width: largeur, height: hauteur)
        .accessibilityHidden(true)
    }

    // MARK: Conditions

    /// Seulement ce que `Conditions` porte : vent, pression, état de la rivière.
    /// // À brancher : température et hauteur d'eau (« 14° », « 1,42 m ») n'existent pas encore dans `Conditions`.
    private func ligneConditions(_ c: Conditions) -> some View {
        HStack(alignment: .top, spacing: Espace.s) {
            if let fin = c.finLegale {
                caseCondition(symbole: "clock", valeur: fin.formatted(.dateTime.hour().minute().locale(Locale(identifier: "fr_FR"))),
                              legende: "fin légale")
            }
            if let vent = c.ventKmh {
                caseCondition(symbole: "wind", valeur: "\(Int(vent.rounded()))", legende: "km/h")
            }
            if c.etatRiviere != .inconnu {
                caseCondition(symbole: "water.waves", valeur: c.etatRiviere.libelle, legende: "rivière",
                              alerte: c.etatRiviere == .crue)
            }
            if let hpa = c.pressionHPa {
                caseCondition(symbole: "gauge.medium", valeur: "\(Int(hpa.rounded()))", legende: "hPa")
            }
        }
        .padding(.top, Espace.m)
        .overlay(alignment: .top) { Rectangle().fill(Palette.filet).frame(height: 0.5) }
    }

    private func caseCondition(symbole: String, valeur: String, legende: String, alerte: Bool = false) -> some View {
        VStack(spacing: Espace.xs) {
            Image(systemName: symbole)
                .font(Police.sousTitre)
                .foregroundStyle(alerte ? Palette.alerte : Palette.marine)
            Text(valeur)
                .font(Police.sousTitre)
                .foregroundStyle(alerte ? Palette.alerte : Palette.encre)
            Text(legende)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: Photo

    /// La photo enregistrée de la prise (sans GPS). Rien si le chemin ne mène à aucun fichier.
    private func imageDe(_ prise: Prise?) -> UIImage? {
        guard let chemin = prise?.cheminPhoto, !chemin.isEmpty else { return nil }
        return UIImage(contentsOfFile: chemin)
    }
}

extension EtatRiviere {
    /// Mot court pour une case de conditions.
    var libelle: String {
        switch self {
        case .normal: "normal"
        case .haut: "haut"
        case .crue: "crue"
        case .inconnu: "inconnu"
        }
    }
}

#if DEBUG
#Preview("Fin de session") {
    let brochet = EspecePechable(espece: Espece(id: "brochet"), nom: "Brochet", nomLatin: "Esox lucius", image: "brochet")
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let prise = Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: debut)
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(5_040), prises: [prise],
                        conditions: [Conditions(heure: debut, ventKmh: 12, pressionHPa: 1016, etatRiviere: .normal)])
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .aucun), infosEspece: { _ in brochet },
                   lieu: "la Marne", surTerminer: {})
}

#Preview("Fin de session bredouille") {
    let debut = Date(timeIntervalSince1970: 1_760_000_000)
    let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(7_200))
    FinSessionView(fin: FinDeSession(sortie: sortie, paywall: .quiSeFerme), lieu: "la Marne", surTerminer: {})
}
#endif
