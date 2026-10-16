import Core
import SwiftUI
import UIKit

/// L'illustration d'une espèce. Sans image dans le catalogue : la silhouette de sa famille, le nom restant dessous.
struct PriseImageEspece: View {
    var entree: EspecePechable
    var cote: CGFloat = 96

    var body: some View {
        Group {
            if UIImage(named: entree.image) != nil {
                Image(entree.image).resizable().scaledToFit().padding(8)
            } else {
                Image(systemName: PriseFamille.de(entree.espece.id).symbole)
                    .font(.system(size: cote * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(PriseJetons.encre.opacity(0.55))
            }
        }
        .frame(width: cote, height: cote)
        .background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
        .accessibilityHidden(true)
    }
}

/// Une espèce en image, le nom dessous. Un seul toucher.
struct PriseTuile: View {
    var entree: EspecePechable
    var duCoin = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                PriseImageEspece(entree: entree)
                Text(entree.nom)
                    .font(PriseJetons.legende()).foregroundStyle(PriseJetons.encre)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: PriseJetons.cibleMin)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if duCoin { Image(systemName: "mappin.circle.fill").foregroundStyle(PriseJetons.accent).accessibilityHidden(true) }
        }
        .accessibilityLabel(entree.nom)
        .accessibilityValue(duCoin ? "Relevée près de toi" : "")
    }
}

/// Les 3 propositions, « autre espèce » et « pas un poisson », toujours visibles. Aucun pourcentage.
struct PrisePropositionsView: View {
    var modele: PriseModele

    private enum Tuile {
        case espece(EspecePechable)
        case classe(String, premiere: EspecePechable?)
    }

    private var tuiles: [Tuile] {
        modele.propositions.compactMap { p in
            switch p.type {
            case .espece(let e): return modele.catalogue.first { $0.espece == e }.map(Tuile.espece)
            case .classe(let nom): return .classe(nom, premiere: modele.catalogue.first { $0.classeModele == nom })
            default: return nil
            }
        }
    }

    private var trois: [EspecePechable] {
        modele.propositions.compactMap { p in
            if case .espece(let e) = p.type { return modele.catalogue.first { $0.espece == e } }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            PriseEntete(titre: "Quelle espèce ?", consigne: PriseLogique.consigneAvantConfirmation)
            if let image = modele.imagePhoto {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: PriseJetons.rayon))
                    .accessibilityLabel("Ta photo")
            }
            ScrollView {
                VStack(spacing: 16) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        // Dans l'ordre du modèle (le plus probable d'abord), espèce seule ou groupe de sosies.
                        // Un groupe (« brochet » : brochet et brochet aquitain) montre l'image de sa 1re espèce et ouvre ses sosies.
                        ForEach(Array(tuiles.enumerated()), id: \.offset) { _, tuile in
                            switch tuile {
                            case .espece(let entree):
                                PriseTuile(entree: entree) { modele.choisir(entree) }
                            case .classe(let nom, let premiere):
                                if let premiere {
                                    PriseTuile(entree: premiere) { modele.ouvrirLaGrille(classe: nom) }
                                } else {
                                    Button(nom.split(separator: "_").joined(separator: " ou ").capitalizedPremiere) { modele.ouvrirLaGrille(classe: nom) }
                                        .buttonStyle(PriseBoutonSecondaire())
                                }
                            }
                        }
                    }
                    Button("Autre espèce") { modele.ouvrirLaGrille() }.buttonStyle(PriseBoutonSecondaire())
                    Button("Pas un poisson") { modele.terminer(nil) }.buttonStyle(PriseBoutonSecondaire())
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(20)
    }

    private var classes: [String] {
        modele.propositions.compactMap { p in if case .classe(let nom) = p.type { return nom }; return nil }
    }
}

/// « Autre espèce » : toutes les espèces en images, par famille, celles du coin d'abord. Jamais de champ de saisie.
struct PriseGrilleView: View {
    var modele: PriseModele
    var classe: String?

    var body: some View {
        VStack(spacing: 12) {
            PriseEntete(titre: "Touche ton espèce", consigne: PriseLogique.consigneAvantConfirmation)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(PriseLogique.groupes(catalogue: modele.catalogue, proches: modele.proches, filtreClasse: classe), id: \.famille) { groupe in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(groupe.famille.titre).font(PriseJetons.corps()).foregroundStyle(PriseJetons.encre)
                                .accessibilityAddTraits(.isHeader)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                                ForEach(groupe.especes, id: \.espece.id) { entree in
                                    PriseTuile(entree: entree, duCoin: groupe.duCoin.contains(entree.espece.id)) { modele.choisir(entree) }
                                }
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button("Je ne sais pas") { modele.jeNeSaisPas() }.buttonStyle(PriseBoutonSecondaire())
        }
        .padding(20)
    }
}

/// Les sosies côte à côte, avec le critère et sa source, lus dans les données. Le pêcheur touche le bon.
struct PriseSosiesView: View {
    var modele: PriseModele
    var entree: EspecePechable

    var body: some View {
        let sosies = PriseLogique.sosies(de: entree, catalogue: modele.catalogue)
        VStack(spacing: 12) {
            PriseEntete(titre: "Touche le bon", consigne: PriseLogique.consigneAvantConfirmation)
            ScrollView {
                VStack(spacing: 16) {
                    HStack(alignment: .top, spacing: 12) {
                        PriseTuile(entree: entree) { modele.confirmer(entree) }
                        ForEach(Array(sosies.enumerated()), id: \.offset) { _, s in
                            PriseTuile(entree: s.entree) { modele.confirmer(s.entree) }
                        }
                    }
                    ForEach(Array(entree.confusions.enumerated()), id: \.offset) { _, c in
                        PriseCritere(critere: c.critere, source: c.source)
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button("Retour") { modele.retourAuxPropositions() }.buttonStyle(PriseBoutonSecondaire())
        }
        .padding(20)
    }
}

struct PriseCritere: View {
    var critere: String
    var source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(critere).font(PriseJetons.corps()).foregroundStyle(PriseJetons.encre)
            Text(source).font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
    }
}

/// Le stade de l'anguille : toujours demandé, en images, avec le critère qui sépare les stades.
struct PriseStadeView: View {
    var modele: PriseModele

    var body: some View {
        let stades = PriseLogique.stades(catalogue: modele.catalogue)
        VStack(spacing: 12) {
            PriseEntete(titre: "Quel stade ?", consigne: PriseLogique.consigneAvantConfirmation)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(stades.enumerated()), id: \.offset) { _, s in
                        VStack(spacing: 8) {
                            PriseTuile(entree: s.entree) { modele.confirmer(s.entree) }
                            if let c = s.critere { PriseCritere(critere: c.critere, source: c.source) }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button("Je ne sais pas") { modele.jeNeSaisPas() }.buttonStyle(PriseBoutonSecondaire())
        }
        .padding(20)
    }
}


private extension String {
    /// Majuscule à la première lettre seulement (« Hotu ou toxostome »).
    var capitalizedPremiere: String { prefix(1).uppercased() + dropFirst() }
}
