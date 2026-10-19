import Core
import SwiftUI

/// Un souvenir : l'image de l'espèce, son nom, sa taille, le jour et l'eau. Ne dépend que de `Core` (pas de `CarteRectoView`).
/// L'étiquette « Trophée » est sobre : `Palette.marine` sur `Palette.marineDoux`, jamais une couleur de rareté.
/// ⚠ à vérifier : écrit sans compilateur Swift ; rendu, AX5 et mode sombre à juger sur Mac.
struct RecordCarteView: View {
    let record: RecordEspece
    let nom: String
    let imageNom: String?
    /// « ≈ 4,2 kg estimé » seulement si le poids est connu.
    let poidsKg: Double?
    var nouveau: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            ZStack(alignment: .topTrailing) {
                image
                    .frame(maxWidth: .infinity)
                    .frame(height: 84)
                    .padding(.vertical, Espace.s)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                if nouveau {
                    Text(TextesRecords.nouveau)
                        .font(Police.legende)
                        .foregroundStyle(Palette.marine)
                        .padding(.horizontal, Espace.s)
                        .padding(.vertical, Espace.xs)
                        .background(Palette.marineDoux, in: Capsule())
                        .padding(Espace.s)
                }
            }
            Text(nom)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: Espace.xs) {
                Text(TextesRecords.longueur(record.longueurCm))
                    .font(Police.chiffreMoyen)
                    .foregroundStyle(Palette.encre)
                    .minimumScaleFactor(0.6)
                if record.mesure == .estimee {
                    Text("estimé").font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
            Text(TextesRecords.jourEtLieu(record))
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
            if let poidsKg {
                Text(TextesRecords.poids(poidsKg))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            if record.estTrophee {
                Text(TextesRecords.etiquetteTrophee)
                    .font(Police.legende)
                    .foregroundStyle(Palette.marine)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.xs)
                    .background(Palette.marineDoux, in: Capsule())
            }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Rayon.l, style: .continuous).stroke(Palette.filet, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TextesRecords.phraseVoixOff(record, nom: nom, nouveau: nouveau))
    }

    @ViewBuilder private var image: some View {
        if let imageNom {
            Image(imageNom).resizable().scaledToFit().accessibilityHidden(true)
        } else {
            Image(systemName: "fish").font(.largeTitle).foregroundStyle(Palette.silhouette).accessibilityHidden(true)
        }
    }
}
