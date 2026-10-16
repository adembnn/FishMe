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
                    Image(systemName: n.pictogramme)
                        .frame(maxWidth: .infinity, minHeight: JetonsConseils.tailleToucher)
                        .foregroundStyle(actif ? Color.white : JetonsConseils.accent)
                        .background(actif ? JetonsConseils.accent : JetonsConseils.accent.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(n.mot)
                .accessibilityAddTraits(actif ? .isSelected : [])
            }
        }
    }

    private var rangeeEspeces: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(especes, id: \.espece) { e in
                    let nom = fiche(e)?.nom ?? e.espece.id
                    let fermee = EspecesDuSpot.texteFermeture(e.ouverture)
                    let actif = selection?.espece == e.espece
                    Button { choix = e.espece.id } label: {
                        VStack(spacing: 4) {
                            ImageEspece(nom: fiche(e)?.image ?? e.espece.id, libelle: nom)
                                .frame(width: 88, height: 64)
                                .opacity(fermee == nil ? 1 : 0.4)
                            Text(nom).font(JetonsConseils.police(.caption)).foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            // Chaque chiffre OFB porte son nombre de pêches et l'année du dernier relevé.
                            Text(Self.releve(nPeches: e.nPeches, annee: e.annee))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(width: 104)
                        .padding(.vertical, 8)
                        .background(actif ? JetonsConseils.accent.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(fermee.map { "\(nom), \($0)" } ?? nom)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder private var conseilsDeLEspece: some View {
        if let e = selection {
            if let fermee = EspecesDuSpot.texteFermeture(e.ouverture) {
                // Espèce fermée : on le dit, aucun conseil de pêche.
                Label(fermee, systemImage: "nosign")
                    .font(JetonsConseils.police(.body))
                    .foregroundStyle(JetonsConseils.alerte)
            } else {
                ConseilsEspeceView(espece: e.espece, contexte: contexte)
            }
        } else {
            Label("Toutes les espèces du coin sont fermées ce jour", systemImage: "nosign")
                .font(JetonsConseils.police(.body))
                .foregroundStyle(JetonsConseils.alerte)
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
    /// « 1 pêche, dernier relevé 2024 » : même forme que la fiche d'un coin (le dossier Conseils n'importe pas Carte).
    nonisolated static func releve(nPeches: Int, annee: Int?) -> String {
        let mot = nPeches > 1 ? "pêches" : "pêche"
        guard let annee else { return "\(nPeches) \(mot)" }
        return "\(nPeches) \(mot), dernier relevé \(annee)"
    }
}
