import Core
import SwiftUI

/// Une source à un toucher : un lien si elle a une adresse, sinon son titre en texte. Même patron que le bloc de règles de la prise
/// (copié, pas importé).
private struct SourceEnvieView: View {
    let source: SourceRegle

    var body: some View {
        if let adresse = source.url, let url = URL(string: adresse) {
            Link(destination: url) {
                HStack(spacing: Espace.xs) {
                    Text(source.titre)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Image(systemName: "arrow.up.right")
                        .accessibilityHidden(true)
                }
                .font(Police.legende)
                .foregroundStyle(Palette.marine)
                .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Source : \(source.titre)")
        } else {
            Text(source.titre)
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Une envie dans « Mes envies » : l'image du poisson, son nom, la ligne d'ouverture, la règle de taille, un conseil du mois.
/// Rien d'autre : aucun indice, aucune couleur de probabilité.
struct LigneEnvieView: View {
    let resume: ResumeEnvie
    /// Ouvre la fiche de l'espèce (chevron). `nil` : pas de chevron.
    var ouvrirFiche: ((Espece) -> Void)? = nil
    /// Ouvre le choix d'un spot, sur la ligne « Choisis un spot ». `nil` : texte simple.
    var choisirSpot: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            entete
            ouverture
            if let taille = resume.taille { tailleBloc(taille) }
            if let conseil = resume.conseil { conseilBloc(conseil) }
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.l)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var entete: some View {
        if let ouvrirFiche {
            Button { ouvrirFiche(resume.espece.espece) } label: { enteteContenu(avecChevron: true) }
                .buttonStyle(.plain)
                .accessibilityLabel("\(resume.espece.nom), ouvrir la fiche")
        } else {
            enteteContenu(avecChevron: false)
        }
    }

    private func enteteContenu(avecChevron: Bool) -> some View {
        HStack(spacing: Espace.m) {
            Image(resume.espece.image)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 48)
                .accessibilityHidden(true)
            Text(resume.espece.nom)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if avecChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: Gabarit.zoneTactile)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var ouverture: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            if case .sansSpot = resume.ouverture, let choisirSpot {
                Button(action: choisirSpot) { ligneOuverture }
                    .buttonStyle(.plain)
            } else {
                ligneOuverture
            }
            if let source = TextesEnvies.source(resume.ouverture) {
                SourceEnvieView(source: source)
            }
        }
    }

    private var ligneOuverture: some View {
        HStack(alignment: .firstTextBaseline, spacing: Espace.s) {
            pastille
            Text(TextesEnvies.ouverture(resume.ouverture))
                .font(Police.corps)
                .foregroundStyle(couleurTexte)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// La couleur aide, le texte porte le sens : l'orange accompagne « Vérifie l'arrêté » avec un point d'exclamation.
    @ViewBuilder
    private var pastille: some View {
        switch resume.ouverture {
        case .aVerifier:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Palette.alerte)
                .accessibilityHidden(true)
        case .fermee:
            Image(systemName: "calendar")
                .foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
        case .ouverte:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.ouvert)
                .accessibilityHidden(true)
        case .sansSpot:
            Image(systemName: "mappin.circle")
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
        }
    }

    private var couleurTexte: Color {
        if case .sansSpot = resume.ouverture, choisirSpot != nil { return Palette.marine }
        return Palette.encre
    }

    private func tailleBloc(_ phrase: String) -> some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(phrase)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(resume.sourcesTaille.enumerated()), id: \.offset) { _, source in
                SourceEnvieView(source: source)
            }
        }
    }

    private func conseilBloc(_ conseil: Conseil) -> some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(TextesEnvies.conseilDuMois.uppercased())
                .font(Police.legende)
                .tracking(0.52)
                .foregroundStyle(Palette.encreDouce)
            Text(conseil.texte)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            SourceEnvieView(source: conseil.source)
        }
    }
}
