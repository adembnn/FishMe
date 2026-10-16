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
    /// La croix en haut à gauche. `nil` : pas de croix (elle ne termine jamais la session : seul « Terminer » le fait).
    let surFermer: (() -> Void)?
    /// Poids estimé d'après la formule longueur-poids de Core (`ServiceEspeces.poidsEstime`). Par défaut : aucun poids.
    let poidsEstime: (Espece, Double) -> PoidsEstime?
    /// Espèce montrée en image dans le bloc bredouille (la plus pêchée du spot, ou celle du conseil).
    /// // À brancher : A passe l'espèce la plus pêchée du spot (relevés OFB) ; `nil` : une silhouette.
    let especeConseil: Espece?

    init(fin: FinDeSession, infosEspece: @escaping (Espece) -> EspecePechable? = { _ in nil }, lieu: String? = nil,
         conseil: String? = nil, surTerminer: @escaping () -> Void, surFermer: (() -> Void)? = nil,
         poidsEstime: @escaping (Espece, Double) -> PoidsEstime? = { _, _ in nil },
         especeConseil: Espece? = nil) {
        self.especeConseil = especeConseil
        self.poidsEstime = poidsEstime
        self.conseil = conseil
        self.fin = fin
        self.infosEspece = infosEspece
        self.lieu = lieu
        self.surTerminer = surTerminer
        self.surFermer = surFermer
    }

    private var sortie: Sortie { fin.sortie }
    private var prises: [Prise] { FormatSortie.prises(sortie) }
    /// La plus grande prise, sinon la dernière : c'est elle que la maquette met en avant.
    private var vedette: Prise? {
        prises.max { ($0.longueurCm ?? 0) < ($1.longueurCm ?? 0) } ?? prises.last
    }
    private var conditions: Conditions? { sortie.conditions.last }

    var body: some View {
        // Maquette P16 A / P47 A : plein écran, photo (ou carte) en haut, feuille flottante dessous, croix de verre à 16 pt du bord.
        ZStack(alignment: .bottom) {
            haut
            feuille
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) { boutonFermer }
    }

    // MARK: Haut de l'écran

    @ViewBuilder private var haut: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                if vedette == nil {
                    // P47 A : la carte de la sortie sans prise, le cercle du spot (1 km) posé sur la rivière : jamais un point exact.
                    FondCarteSession()
                    Circle().fill(Palette.marine.opacity(0.12))
                        .overlay(Circle().stroke(Palette.marine, lineWidth: 2.5))
                        .frame(width: 172, height: 172)
                        .position(x: geo.size.width * 262 / 390, y: geo.size.height * 452 / 844)
                } else if let photo = imageDe(vedette) {
                    // P16 A : la photo, 560 pt de haut sur 844.
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height * 560 / 844)
                        .clipped()
                } else {
                    // Prise sans photo : l'image de l'espèce sur marine doux.
                    ZStack {
                        Palette.marineDoux
                        if let vedette, let infos = infosEspece(vedette.espece) {
                            Image(infos.image).resizable().scaledToFit().padding(Espace.xl)
                        } else {
                            Image(systemName: "water.waves")
                                .font(.system(size: 72, weight: .bold))
                                .foregroundStyle(Palette.marine.opacity(0.35))
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height * 560 / 844)
                    .clipped()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    @ViewBuilder private var boutonFermer: some View {
        if let surFermer {
            BoutonRond(role: .fermer, rendu: .verre, action: surFermer)
                .padding(.leading, Espace.bord)
        }
    }

    // MARK: Feuille

    private var feuille: some View {
        FeuilleFlottante {
            enTete
            if let vedette {
                ligneVedette(vedette)
                    .padding(.vertical, 16)
                if let conditions { ligneConditions(conditions, bordure: true) } else { pasDeReleve(bordure: true) }
            } else {
                if let conditions { ligneConditions(conditions, bordure: false) } else { pasDeReleve(bordure: false) }
                bredouille
            }
            if let message = fin.message {
                Text(message)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.bottom, Espace.s)
            }
            Button("Terminer", action: surTerminer)
                .buttonStyle(.principal)
        }
    }

    private var enTete: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(titre)
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .lineLimit(2)
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
        return HStack(spacing: 14) {
            tuilePoisson(infos, largeur: 96, hauteur: 60, image: 44)
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(titrePrise(prise, infos))
                    .font(Police.taille(17, .heavy))
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

    /// « ~2,1 kg estimé · relâché » : le poids vient de la formule longueur-poids de Core, marqué « estimé » ;
    /// « relâché » ou « gardé » est ce que le pêcheur a déclaré, jamais un verdict de l'app.
    private func detailPrise(_ prise: Prise) -> String? {
        let devenir = prise.gardee ? "gardé" : "relâché"
        if let cm = prise.longueurCm, let poids = poidsEstime(prise.espece, cm) {
            return "~\(PriseLogique.kilos(poids.kilos)) kg estimé · \(devenir)"
        }
        return devenir
    }

    /// Cas bredouille : zéro prise, ton positif. Le bloc « La prochaine fois » n'existe que si un conseil est fourni.
    @ViewBuilder private var bredouille: some View {
        if conseil == nil || conseil?.isEmpty == true {
            // Sans conseil de L1, une phrase positive plutôt qu'un vide au-dessus du bouton.
            HStack(spacing: 14) {
                tuileConseil
                Text("Bredouille, ça arrive. Une sortie de plus au compteur.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) { Rectangle().fill(Palette.filet).frame(height: 0.5) }
            .accessibilityElement(children: .combine)
        } else if let conseil {
            HStack(spacing: 14) {
                tuileConseil
                VStack(alignment: .leading, spacing: 2) {
                    Text("La prochaine fois")
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.encre)
                    Text(conseil)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 16)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) { Rectangle().fill(Palette.filet).frame(height: 0.5) }
            .accessibilityElement(children: .combine)
        }
    }

    /// La tuile 84 × 56 de la maquette P47 : le poisson de profil (image) de l'espèce conseillée ; sans espèce, une silhouette.
    private var tuileConseil: some View {
        let infos = especeConseil.flatMap { infosEspece($0) }
        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.tuile)
            if let infos {
                Image(infos.image).resizable().scaledToFit()
                    .frame(width: 84 * 0.8, height: 42)
            } else {
                Image(systemName: "fish.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.silhouette)
            }
        }
        .frame(width: 84, height: 56)
        .accessibilityHidden(true)
    }

    private func tuilePoisson(_ infos: EspecePechable?, largeur: CGFloat, hauteur: CGFloat, image: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.tuile)
            if let infos {
                Image(infos.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: largeur * 0.86, height: image)
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
    private func ligneConditions(_ c: Conditions, bordure: Bool) -> some View {
        HStack(alignment: .top, spacing: Espace.s) {
            // P16 A : météo, rivière, pression. P47 A (bredouille) : météo, rivière, puis la fin légale.
            if let vent = c.ventKmh {
                caseCondition(symbole: "wind", valeur: "\(Int(vent.rounded()))", legende: "km/h")
            }
            if c.etatRiviere != .inconnu {
                caseCondition(symbole: "water.waves", valeur: c.etatRiviere.libelle, legende: "rivière",
                              alerte: c.etatRiviere == .crue)
            }
            if vedette == nil, let fin = c.finLegale {
                caseCondition(symbole: "clock", valeur: fin.formatted(.dateTime.hour().minute().locale(Locale(identifier: "fr_FR"))),
                              legende: "fin légale")
            } else if let hpa = c.pressionHPa {
                caseCondition(symbole: "gauge.medium", valeur: Int(hpa.rounded()).formatted(.number.locale(Locale(identifier: "fr_FR"))), legende: "hPa")
            }
        }
        .padding(.top, bordure ? 14 : 16)
        .padding(.bottom, bordure ? 20 : 16)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { if bordure { Rectangle().fill(Palette.filet).frame(height: 0.5) } }
    }

    /// Aucun relevé enregistré pour cette sortie.
    private func pasDeReleve(bordure: Bool) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: "cloud.slash").foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
            Text("Pas de relevé météo").font(Police.detail).foregroundStyle(Palette.encreDouce)
            Spacer(minLength: 0)
        }
        .padding(.top, bordure ? 14 : 16)
        .padding(.bottom, bordure ? 20 : 16)
        .overlay(alignment: .top) { if bordure { Rectangle().fill(Palette.filet).frame(height: 0.5) } }
        .accessibilityElement(children: .combine)
    }

    private func caseCondition(symbole: String, valeur: String, legende: String, alerte: Bool = false) -> some View {
        VStack(spacing: Espace.xs) {
            Image(systemName: symbole)
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(alerte ? Palette.alerte : Palette.marine)
            Text(valeur)
                .font(Police.taille(17, .heavy))
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
