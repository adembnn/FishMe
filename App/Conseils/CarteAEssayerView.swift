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

    private var especes: [EspeceProche] { EspecesDuSpot.ordonnees(especesProches) }
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
                        Label("Aucun relevé près d'ici", systemImage: "mappin.slash")
                            .font(JetonsConseils.police(.body))
                            .foregroundStyle(.secondary)
                    } else {
                        rangeeEspeces
                        conseilsDeLEspece
                    }
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("carte-a-essayer")
    }

    private var entete: some View {
        HStack(spacing: 12) {
            Text("À essayer").font(JetonsConseils.police(.title2))
            Spacer(minLength: 0)
            if let eau = IconeEau(etat: etatEau) {
                Label(eau.mot, systemImage: eau.icone)
                    .font(JetonsConseils.police(.subheadline))
                    .foregroundStyle(etatEau == .crue ? JetonsConseils.alerte : JetonsConseils.marne)
            }
            BoutonRond(role: .fermer, action: fermer)
        }
    }

    /// Le niveau se change d'un toucher : il ne change que le ton et le nombre de conseils, jamais leur contenu.
    private var niveauChoisi: some View {
        HStack(spacing: 8) {
            ForEach([NiveauPecheur.debutant, .occasionnel, .confirme], id: \.self) { n in
                let actif = NiveauPecheur.depuis(niveauBrut) == n
                Button { niveauBrut = n.rawValue } label: {
                    HStack(spacing: 5) {
                        Image(systemName: n.pictogramme).font(.caption.weight(.bold))
                        Text(n.motPecheur).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .font(Police.legende)
                    .padding(.horizontal, 6)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .foregroundStyle(actif ? Palette.surMarine : Palette.marine)
                    .background(actif ? Palette.marine : Palette.marineDoux, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(n.motPecheur)
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
        let fermee = EspecesDuSpot.texteFermeture(e.ouverture)
        let actif = selection?.espece == e.espece
        let forme = RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
        return Button { choix = e.espece.id } label: {
            VStack(spacing: 6) {
                ImageEspece(nom: fiche(e)?.image ?? e.espece.id, libelle: nom)
                    .frame(width: 96, height: 56)
                    .opacity(fermee == nil ? 1 : 0.45)
                Text(nom)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                PastilleOuverture(ouverte: fermee == nil)
                Text(Self.releveCourt(nPeches: e.nPeches, annee: e.annee))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Palette.encreDouce)
            }
            .frame(width: 116)
            .padding(.vertical, 10)
            .background(Palette.surface, in: forme)
            .overlay { forme.strokeBorder(actif ? Palette.marine : Palette.filet, lineWidth: actif ? 3 : 1) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fermee.map { "\(nom), \($0)" } ?? "\(nom), ouverte")
        .accessibilityAddTraits(actif ? .isSelected : [])
    }

    @ViewBuilder private var conseilsDeLEspece: some View {
        if let e = selection {
            if let fermee = EspecesDuSpot.texteFermeture(e.ouverture) {
                // Espèce fermée : on le dit, aucun conseil de pêche.
                VStack(alignment: .leading, spacing: 12) {
                    heros(e, titre: "Fermée")
                    Label(fermee, systemImage: "nosign")
                        .font(JetonsConseils.police(.body))
                        .foregroundStyle(JetonsConseils.alerte)
                }
            } else {
                aujourdhui(e)
            }
        } else {
            Label("Toutes les espèces du coin sont fermées ce jour", systemImage: "nosign")
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
                Text("Autres conseils").font(Police.sousTitre).foregroundStyle(Palette.encre)
            }
            ConseilsEspeceView(espece: e.espece, contexte: contexte, dejaMontres: montres)
        }
    }

    /// Grande image de profil sur fond d'eau, avec le nom de l'espèce.
    fileprivate func heros(_ e: EspeceProche, titre: String) -> some View {
        let nom = fiche(e)?.nom ?? e.espece.id
        return VStack(alignment: .leading, spacing: 6) {
            Text(titre).font(Police.legende).foregroundStyle(Palette.encreDouce)
            Text(nom).font(Police.titre).foregroundStyle(Palette.encre).lineLimit(2).minimumScaleFactor(0.8)
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
        Text(ouverte ? "Ouverte" : "Fermée")
            .font(.caption2.weight(.heavy))
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
                    Text(type.libelle).font(Police.legende).foregroundStyle(Palette.marine)
                    Spacer(minLength: 0)
                    if verrouille {
                        Image(systemName: "lock.fill").font(.footnote).foregroundStyle(Palette.encreDouce)
                    }
                }
                if let conseil {
                    if verrouille {
                        Text("Avec le kit complet")
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
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Palette.encreDouce)
                        }
                    }
                } else {
                    Text("Pas encore de conseil")
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
        .accessibilityLabel(type.libelle)
        .accessibilityHint(verrouille ? "Ouvre le kit complet" : "Montre la source")
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Crue : ne pêche pas au bord de l'eau", systemImage: "exclamationmark.triangle.fill")
                .font(JetonsConseils.police(.title3))
                .foregroundStyle(JetonsConseils.alerte)
            Link(destination: URL(string: "https://www.vigicrues.gouv.fr")!) {
                Label("Vigicrues", systemImage: "arrow.up.right.square")
                    .font(JetonsConseils.police(.body))
                    .frame(minHeight: JetonsConseils.tailleToucher)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JetonsConseils.alerte.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityIdentifier("avertissement-crue")
    }
}

extension CarteAEssayerView {
    /// « 10 pêches · 2025 » : le même relevé OFB en court, pour la tuile d'une espèce.
    nonisolated static func releveCourt(nPeches: Int, annee: Int?) -> String {
        let mot = nPeches > 1 ? "pêches" : "pêche"
        guard let annee else { return "\(nPeches) \(mot)" }
        return "\(nPeches) \(mot) · \(annee)"
    }

    /// « 1 pêche, dernier relevé 2024 » : même forme que la fiche d'un coin (le dossier Conseils n'importe pas Carte).
    nonisolated static func releve(nPeches: Int, annee: Int?) -> String {
        let mot = nPeches > 1 ? "pêches" : "pêche"
        guard let annee else { return "\(nPeches) \(mot)" }
        return "\(nPeches) \(mot), dernier relevé \(annee)"
    }
}
