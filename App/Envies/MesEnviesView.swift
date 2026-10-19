import Core
import SwiftUI

/// « Mes envies » : les espèces que le pêcheur veut pêcher, triables. Privée, gratuite, aucune barre de défilement visible.
/// S'ouvre en page depuis le Pescedex (retour « Pescedex »), donc sans pile de navigation propre.
struct MesEnviesView: View {
    let modele: EnviesModele
    /// Les cartes du Pescedex : celles dont l'espèce est dans la liste la font sortir avant l'affichage.
    var cartes: [Prise] = []
    /// Ouvre la fiche d'une espèce. À brancher dans le Pescedex. `nil` : pas de chevron.
    var ouvrirFiche: ((Espece) -> Void)? = nil

    @AppStorage("envies.ordre") private var ordreBrut = OrdreEnvies.ouvertesDAbord.rawValue

    private var ordre: OrdreEnvies { OrdreEnvies(rawValue: ordreBrut) ?? .ouvertesDAbord }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            barre
            Text(TextesEnvies.titre)
                .font(Police.grandTitre)
                .tracking(-0.34)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Espace.bord)
                .padding(.top, Espace.s)
                .accessibilityAddTraits(.isHeader)
            contenu
        }
        .background(Palette.fond.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { modele.charger(cartes: cartes) }
    }

    private var barre: some View {
        HStack {
            BoutonRond(role: .retour)
            Spacer(minLength: Espace.s)
            if modele.nombre > 1 { menuTri }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
    }

    private var menuTri: some View {
        Menu {
            Picker("Trier", selection: $ordreBrut) {
                ForEach(OrdreEnvies.allCases, id: \.rawValue) { o in
                    Text(TextesEnvies.libelle(o)).tag(o.rawValue)
                }
            }
        } label: {
            HStack(spacing: Espace.xs) {
                Text(TextesEnvies.libelle(ordre))
                    .font(Police.detail)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Palette.marine)
            .padding(.horizontal, Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Trier : \(TextesEnvies.libelle(ordre))")
    }

    @ViewBuilder
    private var contenu: some View {
        let resumes = modele.resumes(ordre: ordre)
        if resumes.isEmpty {
            vide
        } else {
            List {
                ForEach(resumes, id: \.espece.espece.id) { resume in
                    LigneEnvieView(resume: resume, ouvrirFiche: ouvrirFiche, choisirSpot: modele.externes.choisirSpot)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: Espace.xs, leading: Espace.bord, bottom: Espace.xs, trailing: Espace.bord))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                modele.retirer(resume.espece)
                            } label: {
                                Label(TextesEnvies.retirer, systemImage: "heart.slash")
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modele.retirer(resume.espece)
                            } label: {
                                Label("Retirer de mes envies", systemImage: "heart.slash")
                            }
                        }
                        .accessibilityAction(named: "Retirer de mes envies") { modele.retirer(resume.espece) }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("envies.liste")
        }
    }

    private var vide: some View {
        VStack(spacing: Espace.l) {
            Spacer(minLength: Espace.xl)
            Image(systemName: "heart")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.silhouette)
                .accessibilityHidden(true)
            Text(TextesEnvies.videPhrase)
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Espace.xl)
            Spacer(minLength: Espace.xl)
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("envies.vide")
    }
}

/// La ligne « Mes envies · N » du Pescedex, sous l'en-tête. À poser seulement si N est au moins 1 :
/// `if let envies, envies.nombre >= 1 { LigneMesEnviesView(nombre: envies.nombre, action: ouvrir) }`.
struct LigneMesEnviesView: View {
    let nombre: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: "heart")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .frame(width: 24)
                    .accessibilityHidden(true)
                Text(TextesEnvies.ligneDuPescedex(nombre: nombre))
                    .font(Police.corps)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Palette.marine)
            .padding(.horizontal, 14)
            .frame(minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(TextesEnvies.titre), \(nombre)")
        .accessibilityIdentifier("envies.ligne")
    }
}
