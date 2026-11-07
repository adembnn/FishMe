import Core
import SwiftUI
import UIKit

/// P23, version du 19 oct. : de haut en bas, 1. la carte de la prise (un toucher la retourne : verso = la photo), 2. le bloc de règles de cette espèce
/// à ce spot (`BlocReglesView`, un seul de deux états en tête), 3. l'interrupteur « gardée » (il ne sert qu'au quota du jour) et « Ajouter au Pescedex ».
/// Rien d'autre au-dessus de la carte. Les lignes et la consigne viennent de `controle` de `Core` : l'écran ne filtre rien et n'ajoute aucune règle.
/// B9 : le bouton ne contredit jamais la ligne qui dit qu'une carte d'exemple ne compte pas.
nonisolated enum TextesPriseResultat {
    static let mentionExemple = "Carte d'exemple : elle ne compte pas au Pescedex"
    static func boutonPrincipal(exemple: Bool) -> String { exemple ? "Voir le Pescedex" : "Ajouter au Pescedex" }
}

struct PriseResultatView: View {
    @Bindable var modele: PriseModele
    @State private var verso = false
    /// US12 : en région États-Unis, le bloc de règles est `BlocReglesUS` ; en France rien ne change.
    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.l) {
                carte
                blocDeRegles
                gardee
                if modele.exemple {
                    // Dans le défilement, pas dans la barre du bas : en bas, elle se chevauchait avec la mention « font foi ».
                    Text(TextesPriseResultat.mentionExemple)
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                }
                // Sortie visible vers le choix de l'espèce : on ne reste jamais enfermé sans pouvoir corriger la prise.
                Button("Modifier la prise") { modele.retour() }
                    .font(Police.corps).foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.m)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, Espace.l, for: .scrollContent)
        .background(Palette.fond.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Espace.xs) {
                Button(TextesPriseResultat.boutonPrincipal(exemple: modele.exemple)) { modele.ranger() }
                    .buttonStyle(.principal)
            }
            .padding(.horizontal, Espace.bord).padding(.vertical, Espace.s)
            .background(Palette.fond.ignoresSafeArea(edges: .bottom))
        }
    }

    // MARK: 2. Les règles

    @ViewBuilder private var blocDeRegles: some View {
        let categorieInconnue = modele.contexte.lieu.categorie.valeur == .inconnue
        if regionCourante?.region == .etatsUnis {
            blocDeReglesUS
        } else if let controle = modele.controle {
            BlocReglesView(resultat: controle, especeConfirmee: modele.especeConfirmee != nil, categorieInconnue: categorieInconnue)
        } else if modele.especeConfirmee != nil {
            // Espèce confirmée mais pas de contrôle (taille non confirmée) : jamais « Espèce non confirmée ».
            // Zéro ligne inventée : la consigne de Core « Vérifie l'arrêté » et l'invitation à lire les textes.
            BlocReglesView(lignes: [], consigne: .verifieLArrete, especeConfirmee: true, categorieInconnue: categorieInconnue)
        } else {
            // Espèce non confirmée : « Il faut relâcher le poisson », sans ligne inventée.
            BlocReglesView(lignes: [], consigne: .relacheLa, especeConfirmee: false)
        }
    }

    /// US12 : les règles des États-Unis. L'État vient de la position de la prise (WI, MN) ; sinon le bloc propose de le choisir.
    /// Une taille estimée (réalité augmentée) ne fait jamais dire « interdit » au moteur.
    @ViewBuilder private var blocDeReglesUS: some View {
        BlocReglesUS(espece: modele.especeConfirmee?.espece.id ?? "", nomEspece: modele.especeConfirmee?.nom,
                     etat: EtatUSDepuisLieu.etat(pour: modele.contexte.coordonnee),
                     tailleCm: modele.tailleConnue ? modele.longueurCm.rounded() : nil,
                     tailleEstimee: modele.methode == .estimee, date: modele.contexte.date)
    }

    // MARK: 3. Gardée ou relâchée (quota du jour)

    private var gardee: some View {
        Toggle(isOn: $modele.gardee) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Je l'ai gardée").font(Police.corps).foregroundStyle(Palette.encre)
                Text("Compte pour le quota du jour").font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
        }
        .tint(Palette.marine)
        .padding(Espace.m)
        .frame(minHeight: Gabarit.zoneTactile)
        .tuileFishMe()
    }

    // MARK: 1. La carte (recto et verso)

    /// La carte de l'écran Pescedex (`CarteRectoView`, `CarteVersoView`) construite avec ce que la prise sait déjà.
    /// Rareté : table de Core pour le département de la prise. Rang dans la zone, consigne et lune : absents ici
    /// (ni le recto ni le verso ne les montrent).
    private var infosCarte: InfosCarte? {
        guard let entree = modele.especeConfirmee else { return nil }
        let prise = Prise(espece: entree.espece, longueurCm: modele.tailleConnue ? modele.longueurCm.rounded() : nil,
                          mesure: modele.tailleConnue ? modele.methode : nil,
                          stade: modele.stade, date: modele.contexte.date, lieuFlou: modele.contexte.lieuFlou,
                          gardee: modele.gardee, exemple: modele.exemple)
        let departement = modele.contexte.lieu.departement
        return InfosCarte(detail: CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil), espece: entree,
                          rarete: modele.services.especes.rarete(espece: entree.espece, departement: departement),
                          departement: departement, rangDansLaZone: nil, poids: modele.poids,
                          lune: .nouvelle, consigne: nil, sourceConsigne: nil)
    }

    @ViewBuilder private var carte: some View {
        if let infos = infosCarte {
            // Les deux faces sont superposées ; la carte tourne autour de son axe vertical et l'on voit l'une ou l'autre.
            ZStack {
                CarteRectoView(infos: infos).opacity(verso ? 0 : 1)
                CarteVersoView(infos: infos, photo: modele.photo)
                    .opacity(verso ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .rotation3DEffect(.degrees(verso ? 180 : 0), axis: (x: 0, y: 1, z: 0))
            .frame(maxWidth: 345)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.easeInOut(duration: 0.45)) { verso.toggle() } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(verso ? "Photo de la prise, \(infos.espece.nom)" : infos.texteVoixOff)
            .accessibilityHint(verso ? "Toucher pour revenir à la carte" : "Toucher pour voir la photo")
            .accessibilityAddTraits(.isButton)
        } else {
            RoundedRectangle(cornerRadius: Rayon.l, style: .continuous)
                .fill(Palette.tuile)
                .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
                .frame(maxWidth: 345)
                .accessibilityHidden(true)
        }
    }
}
