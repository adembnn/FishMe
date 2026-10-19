import Core
import SwiftUI

/// Le bloc de règles d'une espèce à un spot (L19), partagé avec « Règles du spot » (L17). Il ne prend que des types de `Core`.
/// Un seul de deux états en tête (décision 10 du 19 oct.) :
/// - « Il faut relâcher le poisson » (fond orange) : une règle n'est pas respectée, l'espèce est protégée ou l'espèce n'est pas confirmée ;
///   dessous, la raison la plus forte en une ligne, sa source à un toucher ;
/// - « Voir la réglementation en vigueur sur ce poisson » : un dépliant fermé, trois groupes (garder ou relâcher · horaires · matériel et pratique).
///   Une pastille orange sur le titre quand une ligne est à vérifier.
/// Les lignes et la consigne viennent de `controle` de `Core` : le bloc ne filtre rien et n'ajoute aucune règle.
/// Jamais de phrase d'autorisation : le dépliant est une porte vers les textes, pas un verdict.
struct BlocReglesView: View {
    let lignes: [LigneControle]
    let consigne: Consigne
    let especeConfirmee: Bool
    @State private var deplie: Bool

    /// Le cas ordinaire : le résultat de `controle`. `deplieAuDepart` sert aux aperçus et aux tests d'écran.
    init(resultat: ResultatControle, especeConfirmee: Bool = true, deplieAuDepart: Bool = false) {
        self.init(lignes: resultat.lignes, consigne: resultat.consigne, especeConfirmee: especeConfirmee, deplieAuDepart: deplieAuDepart)
    }

    /// Les lignes d'un lieu (`reglesDuJour`) avec une consigne ; pour « Règles du spot ».
    init(lignes: [LigneControle], consigne: Consigne, especeConfirmee: Bool = true, deplieAuDepart: Bool = false) {
        self.lignes = lignes
        self.consigne = consigne
        self.especeConfirmee = especeConfirmee
        _deplie = State(initialValue: deplieAuDepart)
    }

    private var tete: BlocReglesLogique.Tete {
        BlocReglesLogique.tete(lignes: lignes, consigne: consigne, especeConfirmee: especeConfirmee)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            if case .relacher(let raison, let ligne) = tete { relacher(raison: raison, ligne: ligne) }
            if !lignes.isEmpty { reglementation }
            Text(BlocReglesLogique.mentionFoi)
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: État 1 : il faut relâcher le poisson

    private func relacher(raison: String, ligne: LigneControle?) -> some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            HStack(alignment: .top, spacing: Espace.m) {
                Image(systemName: "arrow.uturn.down")
                    .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(.white).accessibilityHidden(true)
                Text(BlocReglesLogique.titreRelacher)
                    .font(Police.titre).foregroundStyle(.white)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
            }
            if let ligne {
                LigneRegleBlocView(ligne: ligne)
            } else {
                Text(raison).font(Police.corps).foregroundStyle(.white)
                    .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.alerte, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    // MARK: État 2 : voir la réglementation en vigueur

    private var reglementation: some View {
        let aVerifier = BlocReglesLogique.aVerifier(lignes)
        return DisclosureGroup(isExpanded: $deplie) {
            VStack(alignment: .leading, spacing: Espace.l) {
                ForEach(Array(BlocReglesLogique.groupes(lignes).enumerated()), id: \.offset) { _, g in
                    groupe(g.groupe, g.lignes)
                }
            }
            .padding(.top, Espace.m)
        } label: {
            VStack(alignment: .leading, spacing: Espace.xs) {
                HStack(alignment: .top, spacing: Espace.s) {
                    Text(BlocReglesLogique.titreReglementation)
                        .font(Police.sousTitre).foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if aVerifier {
                        Circle().fill(Palette.alerte).frame(width: 12, height: 12).padding(.top, 5)
                            .accessibilityHidden(true)
                    }
                    Spacer(minLength: 0)
                }
                if aVerifier {
                    Text("Vérifie sur place").font(Police.detail).foregroundStyle(Palette.alerte)
                    if let c = BlocReglesLogique.consigneSousLeTitre(lignes: lignes, consigne: consigne) {
                        Text(c).font(Police.detail).foregroundStyle(Palette.encre)
                            .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
        }
        .tint(Palette.marine)
        .padding(Espace.m)
        .tuileFishMe()
    }

    /// Un groupe : son en-tête, puis ses lignes.
    private func groupe(_ g: BlocReglesLogique.Groupe, _ lignes: [LigneControle]) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            enteteDeGroupe(g)
            ForEach(Array(lignes.enumerated()), id: \.offset) { _, l in LigneRegleBlocView(ligne: l) }
        }
    }

    private func enteteDeGroupe(_ g: BlocReglesLogique.Groupe) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: g.symbole).foregroundStyle(Palette.marine).accessibilityHidden(true)
            Text(g.titre).font(Police.sousTitre).foregroundStyle(Palette.encre)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

#if DEBUG
/// Données factices des aperçus : des lignes de forme `Core`, sans valeur juridique.
private enum ApercuBlocRegles {
    static let source = SourceRegle(titre: "Arrêté préfectoral (aperçu)", url: "https://example.org/arrete", citation: "Citation d'exemple.")
    static let taille = LigneControle(type: .taille, etat: .nonRespectee, phrase: "Exemple : 55 cm, maille à 60 cm.", sources: [source])
    static let periode = LigneControle(type: .periode, etat: .respectee, phrase: "Exemple : période ouverte.", sources: [source])
    static let reserve = LigneControle(type: .reserve, etat: .aVerifierSurPlace, raison: .reserve, phrase: "Exemple : regarde le panneau.", sources: [source])
    static let nuit = LigneControle(type: .nuit, etat: .information, phrase: "Exemple : horaire de pêche.", sources: [source])
    static let tropPres = LigneControle(type: .taille, etat: .aVerifierSurPlace, raison: .tropPresDeLaMaille, phrase: "Exemple : trop près de la maille.", sources: [source])
}

#Preview("Relâcher") {
    ScrollView {
        BlocReglesView(resultat: ResultatControle(lignes: [ApercuBlocRegles.taille, ApercuBlocRegles.periode, ApercuBlocRegles.reserve], consigne: .relacheLa))
            .padding(Espace.bord)
    }
    .background(Palette.fond)
}

#Preview("Réglementation, cas limite") {
    ScrollView {
        BlocReglesView(resultat: ResultatControle(lignes: [ApercuBlocRegles.tropPres, ApercuBlocRegles.nuit], consigne: .mesureLaSurUneToise),
                       deplieAuDepart: true)
            .padding(Espace.bord)
    }
    .background(Palette.fond)
}

#Preview("Espèce non confirmée") {
    BlocReglesView(lignes: [], consigne: .relacheLa, especeConfirmee: false)
        .padding(Espace.bord)
        .background(Palette.fond)
}
#endif
