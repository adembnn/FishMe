import Core
import SwiftUI

/// Le bouton « Règles de pêche de l'État » d'une carte de la collection, pour un pêcheur en région États-Unis seulement : il ouvre
/// `BlocReglesUS` dans une feuille. En France (ou sans région dans l'environnement) il n'affiche rien : rien ne change.
/// La prise ne garde pas de position : l'État se lit dans le lieu flou de la carte, sinon le bloc propose de le choisir.
struct BoutonReglesUS: View {
    let prise: Prise
    let nomEspece: String

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    @State private var ouverte = false

    private var visible: Bool { regionCourante?.region == .etatsUnis && !prise.estDeclaree }
    private var textes: TextesReglesUS { TextesReglesUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }

    var body: some View {
        if visible {
            Button { ouverte = true } label: {
                Label(textes.boutonRegles, systemImage: "list.bullet.rectangle")
            }
            .buttonStyle(.secondaire)
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.s)
            .sheet(isPresented: $ouverte) { feuille }
        }
    }

    private var feuille: some View {
        let noms = (ServiceReglesUS.evaluateur?.niveau1?.etats ?? []).map { e in (code: e.code, nom: e.nom) }
        return ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text(textes.titreBloc).font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
                BlocReglesUS(espece: prise.espece.id, nomEspece: nomEspece,
                             etat: EtatUSDepuisLieu.etat(depuisLieuFlou: prise.lieuFlou, noms: noms),
                             tailleCm: prise.longueurCm, tailleEstimee: prise.mesure == .estimee, date: prise.date)
            }
            .padding(Espace.bord)
        }
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
