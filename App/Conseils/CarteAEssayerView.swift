import Core
import SwiftUI

/// E4 : la carte « à essayer », ouverte par A au départ d'une session (une fois par session, A ne la rouvre pas).
/// Les espèces du spot en images, l'état de l'eau, puis quoi mettre au bout de la ligne pour l'espèce touchée.
struct CarteAEssayerView: View {
    let especesProches: [EspeceProche]
    let pechables: [EspecePechable]
    /// Passé par A depuis L12.
    let etatEau: EtatRiviere
    let contexte: ContexteConseils
    let fermer: () -> Void

    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue
    @State private var choix: String?
    @Environment(\.locale) private var locale

    /// Aucun relevé OFB près du spot : l'écran ne reste pas vide, il propose les espèces courantes en France (sans chiffre).
    private var sansReleve: Bool { especesProches.isEmpty }
    private var especes: [EspeceProche] {
        if !sansReleve { return EspecesDuSpot.ordonnees(especesProches) }
        // L'ouverture du jour n'est pas connue ici : `.ouverte` ne sert qu'à garder la sélection ; l'écran dit « vérifie l'ouverture ».
        return EspecesDuTunnel.choisir(pechables: pechables, proches: [], nombre: 8)
            .map { EspeceProche(espece: $0.espece, nPeches: 0, annee: 0, ouverture: .ouverte) }
    }
    private func fiche(_ e: EspeceProche) -> EspecePechable? { pechables.first { $0.espece == e.espece } }
    private var selection: EspeceProche? {
        especes.first { $0.espece.id == choix } ?? especes.first { EspecesDuSpot.texteFermeture($0.ouverture) == nil }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                entete
                if etatEau == .crue {
                    AvertissementCrueView()
                } else {
                    niveauChoisi
                    if especes.isEmpty {
                        videPlein
                    } else {
                        titreRangee
                        rangeeEspeces
                        conseilsDeLEspece
                    }
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.l)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationBackground(Palette.fond)
        .accessibilityIdentifier("carte-a-essayer")
    }

    private var entete: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(c: "À essayer")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Text(c: "Près de ton spot, aujourd'hui")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
            }
            Spacer(minLength: 0)
            if let eau = IconeEau(etat: etatEau) {
                Label { Text(c: eau.mot) } icon: { Image(systemName: eau.icone) }
                    .font(Police.legende)
                    .foregroundStyle(etatEau == .crue ? JetonsConseils.alerte : JetonsConseils.marne)
            }
            BoutonRond(role: .fermer, action: fermer)
        }
    }

    /// Légende de la rangée : d'où viennent les espèces (relevés OFB ou espèces courantes).
    private var titreRangee: some View {
        Text(c: sansReleve ? "Espèces courantes en France" : "Relevées près de ton spot")
            .font(Police.sousTitre)
            .foregroundStyle(Palette.encre)
    }

    /// Ni espèce ni relevé : un état plein (poisson, phrase, issue), jamais un écran blanc.
    private var videPlein: some View {
        VStack(spacing: Espace.l) {
            Image(systemName: "fish.fill")
                .font(Police.taille(64, .bold))
                .foregroundStyle(Palette.marine)
                .frame(width: 140, height: 140)
                .background(Palette.marineDoux, in: Circle())
                .accessibilityHidden(true)
            Text(c: "Pas encore de conseil ici")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            Text(c: "Aucun relevé de l'OFB près de ce spot. Choisis un autre spot sur la carte pour voir les poissons et quoi leur proposer.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
            Button(action: fermer) { Label { Text(c: "Voir la carte") } icon: { Image(systemName: "map.fill") } }
                .buttonStyle(.principal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espace.xxl)
    }

    /// Le niveau se change d'un toucher : il ne change que le ton et le nombre de conseils, jamais leur contenu.
    private var niveauChoisi: some View {
        HStack(spacing: 8) {
            ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { n in
                let actif = NiveauPecheur.depuis(niveauBrut) == n
                Button { niveauBrut = n.rawValue } label: {
                    HStack(spacing: 5) {
                        Image(systemName: n.pictogramme).font(.caption.weight(.bold))
                        Text(c: n.motPecheur).lineLimit(1)
                    }
                    .font(Police.legende)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .foregroundStyle(actif ? Palette.surMarine : Palette.marine)
                    .background(actif ? Palette.marine : Palette.marineDoux, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(c: n.motPecheur))
                .accessibilityAddTraits(actif ? .isSelected : [])
            }
        }
    }

    private var rangeeEspeces: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(especes, id: \.espece) { e in
                    tuileEspece(e)
                }
            }
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .padding(.horizontal, -16)
        .scrollClipDisabled()
        .scrollIndicators(.hidden)
    }

    /// Une espèce du spot : profil, nom, ouverte ou fermée, puis (discret) le relevé OFB avec son nombre de pêches et l'année.
    private func tuileEspece(_ e: EspeceProche) -> some View {
        let nom = fiche(e)?.nom ?? e.espece.id
        let fermee = EspecesDuSpot.texteFermeture(e.ouverture, locale: locale)
        let actif = selection?.espece == e.espece
        let forme = RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
        return Button { choix = e.espece.id } label: {
            VStack(spacing: 6) {
                ImageEspece(nom: fiche(e)?.image ?? e.espece.id, libelle: nom)
                    .frame(width: 96, height: 56)
                    .opacity(fermee == nil ? 1 : 0.45)
                Text(NomCarte.court(nom))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .lineLimit(2)
                if !sansReleve {
                    PastilleOuverture(ouverte: fermee == nil)
                    Text(Self.releveCourt(nPeches: e.nPeches, annee: e.annee, locale: locale))
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            .frame(width: 116)
            .padding(.vertical, 10)
            .background(Palette.surface, in: forme)
            .overlay { forme.strokeBorder(actif ? Palette.marine : Palette.filet, lineWidth: actif ? 3 : 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(sansReleve ? nom : (fermee.map { "\(nom), \($0)" } ?? AnglaisC.texte("%@, ouverte", locale, nom)))
        .accessibilityAddTraits(actif ? .isSelected : [])
    }

    @ViewBuilder private var conseilsDeLEspece: some View {
        if let e = selection {
            if let fermee = EspecesDuSpot.texteFermeture(e.ouverture, locale: locale) {
                // Espèce fermée : on le dit, aucun conseil de pêche.
                VStack(alignment: .leading, spacing: 12) {
                    heros(e, titre: "Fermée")
                    Label { Text(fermee) } icon: { Image(systemName: "nosign") }
                        .font(JetonsConseils.police(.body))
                        .foregroundStyle(JetonsConseils.alerte)
                }
            } else {
                if sansReleve {
                    Label { Text(c: "Vérifie l'ouverture dans les règles du spot") } icon: { Image(systemName: "info.circle") }
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
                aujourdhui(e)
            }
        } else {
            Label { Text(c: "Toutes les espèces du coin sont fermées ce jour") } icon: { Image(systemName: "nosign") }
                .font(JetonsConseils.police(.body))
                .foregroundStyle(JetonsConseils.alerte)
        }
    }
}

extension CarteAEssayerView {
    /// Le grand bloc de l'espèce touchée : son profil, puis le meilleur conseil de chaque type, puis les autres conseils.
    @ViewBuilder fileprivate func aujourdhui(_ e: EspeceProche) -> some View {
        let niveau = NiveauPecheur.depuis(niveauBrut)
        let parType = contexte.parType(espece: e.espece, niveau: niveau)
        let a = contexte.affiches(espece: e.espece, niveau: niveau)
        let ouverts = Set(a.visibles.map(\.texte))
        // Une tuile dont le texte n'est pas parmi les conseils visibles sans abonnement reste fermée (cadenas).
        let montres = Set(parType.values.map(\.texte).filter { ouverts.contains($0) })
        VStack(alignment: .leading, spacing: 14) {
            heros(e, titre: "Aujourd'hui")
            if !parType.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(TypeConseil.allCases, id: \.self) { type in
                        TuileConseilView(
                            type: type,
                            conseil: parType[type],
                            verrouille: parType[type].map { !ouverts.contains($0.texte) } ?? false,
                            ouvrirKit: { contexte.toutLeKit(.conseilsComplets) }
                        )
                    }
                }
            }
            if a.visibles.contains(where: { !montres.contains($0.texte) }) || a.toutLeKit {
                Text(c: "Autres conseils").font(Police.sousTitre).foregroundStyle(Palette.encre)
            }
            ConseilsEspeceView(espece: e.espece, contexte: contexte, dejaMontres: montres)
        }
    }

    /// Grande image de profil sur fond d'eau, avec le nom de l'espèce.
    fileprivate func heros(_ e: EspeceProche, titre: String) -> some View {
        let nom = fiche(e)?.nom ?? e.espece.id
        return VStack(alignment: .leading, spacing: 6) {
            Text(c: titre).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Text(nom).font(Police.titre).foregroundStyle(Palette.encre).lineLimit(2)
            ImageEspece(nom: fiche(e)?.image ?? e.espece.id, libelle: nom)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.eauClaire, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
    }
}

/// « Ouverte » (vert) ou « Fermée » (gris) : le mot et la couleur, jamais la couleur seule.
struct PastilleOuverture: View {
    let ouverte: Bool

    var body: some View {
        Text(c: ouverte ? "Ouverte" : "Fermée")
            .font(Police.legende)
            .foregroundStyle(ouverte ? Palette.ouvert : Palette.encreDouce)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ouverte ? Palette.ouvertDoux : Palette.tuile, in: Capsule())
    }
}

/// Une tuile du bloc « Aujourd'hui » : le type (appât, hameçon, technique, moment) et son meilleur conseil.
/// Verrouillée (sans abonnement) : cadenas, et un toucher ouvre l'écran des abonnements.
/// Ouverte : un toucher montre la source.
struct TuileConseilView: View {
    let type: TypeConseil
    let conseil: Conseil?
    let verrouille: Bool
    let ouvrirKit: () -> Void
    @State private var sourceOuverte = false

    var body: some View {
        Button(action: toucher) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: IconesConseils.parDefaut(type))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.marine)
                        .frame(width: 32, height: 32)
                        .background(Palette.marineDoux, in: Circle())
                        .accessibilityHidden(true)
                    Text(c: type.libelle).font(Police.legende).foregroundStyle(Palette.marine)
                    Spacer(minLength: 0)
                    if verrouille {
                        Image(systemName: "lock.fill").font(.footnote).foregroundStyle(Palette.encreDouce)
                    }
                }
                if let conseil {
                    if verrouille {
                        Text(c: "Avec le kit complet")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                    } else {
                        Text(conseil.texte)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if sourceOuverte {
                            Group {
                                if let url = conseil.source.url.flatMap({ URL(string: $0) }) {
                                    Link(conseil.source.titre, destination: url)
                                } else {
                                    Text(conseil.source.titre)
                                }
                            }
                            .font(Police.legende)
                            .foregroundStyle(Palette.encreDouce)
                        }
                    }
                } else {
                    Text(c: "Pas encore de conseil")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Rayon.m, style: .continuous).strokeBorder(Palette.filet, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(conseil == nil)
        .accessibilityLabel(Text(c: type.libelle))
        .accessibilityHint(Text(c: verrouille ? "Ouvre le kit complet" : "Montre la source"))
    }

    private func toucher() {
        if verrouille { ouvrirKit() } else { sourceOuverte.toggle() }
    }
}

extension TypeConseil {
    /// Le mot sur la tuile.
    var libelle: String {
        switch self {
        case .appat: "Appât"
        case .hamecon: "Hameçon"
        case .technique: "Technique"
        case .moment: "Moment"
        }
    }
}

extension NiveauPecheur {
    /// Le mot sur la pastille de niveau de l'écran « À essayer ».
    var motPecheur: String {
        switch self {
        case .debutant: "Je débute"
        case .occasionnel: "Quelques sorties"
        case .confirme: "Confirmé"
        }
    }
}

/// L'état de l'eau en icône (L12 le calcule, A le passe).
struct IconeEau {
    let icone: String
    let mot: String

    init?(etat: EtatRiviere) {
        switch etat {
        case .normal: self.init(icone: "water.waves", mot: "Eau normale")
        case .haut: self.init(icone: "arrow.up.right", mot: "Eau haute")
        case .crue: self.init(icone: "exclamationmark.triangle.fill", mot: "Crue")
        case .inconnu: return nil
        }
    }

    private init(icone: String, mot: String) {
        self.icone = icone
        self.mot = mot
    }
}

/// En crue : la mise en garde d'abord, le lien Vigicrues, aucun conseil de pêche.
struct AvertissementCrueView: View {
    @Environment(\.openURL) private var ouvrirURL

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(Police.taille(44, .bold))
                .foregroundStyle(JetonsConseils.alerte)
                .frame(width: 96, height: 96)
                .background(Palette.alerteDoux, in: Circle())
                .accessibilityHidden(true)
            Text(c: "Crue : ne pêche pas au bord de l'eau")
                .font(Police.titre)
                .foregroundStyle(JetonsConseils.alerte)
                .multilineTextAlignment(.center)
            Text(c: "Reviens quand l'eau a baissé. Les niveaux officiels sont sur Vigicrues.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
            if let url = URL(string: "https://www.vigicrues.gouv.fr") {
                Button { ouvrirURL(url) } label: {
                    Label("Vigicrues", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.secondaire)
            }
        }
        .padding(Espace.xl)
        .frame(maxWidth: .infinity)
        .background(Palette.alerteDoux, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityIdentifier("avertissement-crue")
    }
}

extension CarteAEssayerView {
    /// « 10 pêches · 2025 » : le même relevé OFB en court, pour la tuile d'une espèce.
    nonisolated static func releveCourt(nPeches: Int, annee: Int?, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        guard let annee else { return AnglaisC.texte(nPeches > 1 ? "%lld pêches" : "%lld pêche", locale, nPeches) }
        return AnglaisC.texte(nPeches > 1 ? "%lld pêches · %lld" : "%lld pêche · %lld", locale, nPeches, annee)
    }

    /// « 1 pêche, dernier relevé 2024 » : même forme que la fiche d'un coin (le dossier Conseils n'importe pas Carte).
    nonisolated static func releve(nPeches: Int, annee: Int?, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        guard let annee else { return AnglaisC.texte(nPeches > 1 ? "%lld pêches" : "%lld pêche", locale, nPeches) }
        return AnglaisC.texte(nPeches > 1 ? "%lld pêches, dernier relevé %lld" : "%lld pêche, dernier relevé %lld", locale, nPeches, annee)
    }
}
