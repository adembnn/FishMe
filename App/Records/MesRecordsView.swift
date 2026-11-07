import Core
import SwiftUI

/// « Mes records » : trois compteurs, une grille de souvenirs (un par espèce), puis les espèces sans taille.
/// Gratuit, sans verrou. Ne dépend que de `Core`. À brancher par A dans le profil, dans un `NavigationStack`.
/// ⚠ à vérifier : écrit sans compilateur Swift ; rendu, AX5, mode sombre et VoiceOver à juger sur Mac.
struct MesRecordsView: View {
    let modele: ModeleRecords

    @Environment(\.dynamicTypeSize) private var tailleTexte
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                compteurs
                if modele.estVide {
                    Text(AnglaisE.t(TextesRecords.phraseVide, locale))
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if !modele.bilan.records.isEmpty { grille }
                if !modele.bilan.especesSansTaille.isEmpty { sansTaille }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle(AnglaisE.t(TextesRecords.titre, locale))
        .navigationBarTitleDisplayMode(.large)
        .onDisappear { modele.marquerVus() }
    }

    // MARK: Compteurs

    private var compteurs: some View {
        let c = modele.bilan.compteurs
        let disposition = tailleTexte.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Espace.m))
            : AnyLayout(HStackLayout(alignment: .top, spacing: Espace.m))
        return disposition {
            compteur(icone: "calendar", valeur: c.sorties, titre: "Sorties", legende: nil)
            compteur(icone: "fish", valeur: c.especesTrouvees, titre: "Espèces trouvées", legende: nil)
            compteur(icone: "drop", valeur: c.bredouilles, titre: "Bredouilles", legende: TextesRecords.legendeBredouilles)
        }
    }

    private func compteur(icone: String, valeur: Int, titre: String, legende: String?) -> some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Image(systemName: icone).font(.title3).foregroundStyle(Palette.marine).accessibilityHidden(true)
            Text("\(valeur)").font(Police.chiffre).foregroundStyle(Palette.encre).minimumScaleFactor(0.6)
            Text(AnglaisE.t(titre, locale)).font(Police.detail).foregroundStyle(Palette.encre).fixedSize(horizontal: false, vertical: true)
            if let legende {
                Text(AnglaisE.t(legende, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Rayon.l, style: .continuous).stroke(Palette.filet, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AnglaisE.f("%@ : %lld", locale, AnglaisE.t(titre, locale), valeur) + (legende.map { ", \(AnglaisE.t($0, locale))" } ?? ""))
    }

    // MARK: Souvenirs

    private var colonnes: [GridItem] {
        tailleTexte.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.adaptive(minimum: 150), spacing: Espace.m)]
    }

    private var grille: some View {
        LazyVGrid(columns: colonnes, alignment: .leading, spacing: Espace.m) {
            ForEach(modele.bilan.records) { record in
                RecordCarteView(record: record, nom: modele.nom(record.espece), imageNom: modele.info(record.espece)?.image,
                                poidsKg: modele.poidsKg(record), nouveau: modele.nouveaux.contains(record.id))
            }
        }
    }

    // MARK: Espèces sans taille

    private var sansTaille: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(AnglaisE.t(TextesRecords.sansTaille, locale)).font(Police.sousTitre).foregroundStyle(Palette.encre)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: Espace.s)], alignment: .leading, spacing: Espace.s) {
                ForEach(modele.bilan.especesSansTaille, id: \.id) { espece in
                    Group {
                        if let image = modele.info(espece)?.image {
                            Image(image).resizable().scaledToFit()
                        } else {
                            Image(systemName: "fish").foregroundStyle(Palette.silhouette)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, maxHeight: 56)
                    .padding(Espace.xs)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(modele.nom(espece)), \(AnglaisE.t(TextesRecords.sansTaille, locale).lowercased())")
                }
            }
        }
    }
}
