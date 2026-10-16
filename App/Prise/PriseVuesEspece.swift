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
                Image(entree.image).resizable().scaledToFit().padding(Espace.s)
            } else {
                Image(systemName: PriseFamille.de(entree.espece.id).symbole)
                    .font(.system(size: cote * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(width: cote, height: cote)
        .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// L'image d'une espèce en vignette large (poisson de profil sur fond marine doux), qui prend la largeur offerte.
struct PriseVignetteEspece: View {
    var entree: EspecePechable
    var selectionne = false
    /// Grille « Autre » : tuile de 62 points au lieu de 70.
    var compacte = false

    var body: some View {
        let rayon: CGFloat = compacte ? 14 : 16
        Group {
            if UIImage(named: entree.image) != nil {
                Image(entree.image).resizable().scaledToFit().padding(.horizontal, Espace.xs).padding(.vertical, Espace.xs)
            } else {
                Image(systemName: PriseFamille.de(entree.espece.id).symbole)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(maxWidth: .infinity, minHeight: compacte ? 62 : 70, maxHeight: compacte ? 62 : 70)
        .background(selectionne ? Palette.marineDoux : Palette.tuile, in: RoundedRectangle(cornerRadius: rayon, style: .continuous))
        .overlay {
            if selectionne {
                RoundedRectangle(cornerRadius: rayon, style: .continuous).strokeBorder(Palette.marine, lineWidth: 2.5)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Une espèce en image, le nom dessous. Un seul toucher.
struct PriseTuile: View {
    var entree: EspecePechable
    var duCoin = false
    var selectionne = false
    /// Nom affiché à la place de celui de l'espèce (tuile d'un groupe de sosies).
    var titre: String?
    var compacte = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: compacte ? 5 : 6) {
                PriseVignetteEspece(entree: entree, selectionne: selectionne, compacte: compacte)
                Text(titre ?? entree.nom)
                    .font(compacte ? Police.legende : Police.detail).foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if duCoin {
                Image(systemName: "mappin.circle.fill").foregroundStyle(Palette.marine)
                    .padding(Espace.xs).accessibilityHidden(true)
            }
        }
        .accessibilityLabel(titre ?? entree.nom)
        .accessibilityValue(duCoin ? "Relevée près de toi" : "")
        .accessibilityAddTraits(selectionne ? .isSelected : [])
    }
}

/// P19 : les 3 propositions en images, sur la photo, plus une case « Autre ». Aucun pourcentage.
/// Le pêcheur touche la bonne, puis « Confirmer : … » (un seul bouton principal).
struct PrisePropositionsView: View {
    var modele: PriseModele
    @State private var choix = 0

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

    private func nom(_ tuile: Tuile) -> String {
        switch tuile {
        case .espece(let e): return e.nom
        case .classe(let nom, _): return PriseLogique.nomDeGroupe(classe: nom, membres: modele.catalogue.filter { $0.classeModele == nom })
        }
    }

    var body: some View {
        let liste = Array(tuiles.prefix(3))
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Quelle espèce ?").font(Police.titre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                HStack(alignment: .top, spacing: 10) {
                    // Dans l'ordre du modèle (le plus probable d'abord), espèce seule ou groupe de sosies.
                    // Un groupe (« brochet » : brochet et brochet aquitain) montre l'image de sa 1re espèce et ouvre ses sosies.
                    ForEach(Array(liste.enumerated()), id: \.offset) { i, tuile in
                        switch tuile {
                        case .espece(let entree):
                            PriseTuile(entree: entree, selectionne: choix == i) { choix = i }
                        case .classe(_, let premiere):
                            if let premiere {
                                PriseTuile(entree: premiere, selectionne: choix == i, titre: nom(tuile)) { choix = i }
                            } else {
                                Button(nom(tuile)) { choix = i }.buttonStyle(.secondaire)
                            }
                        }
                    }
                    autre
                }
                .padding(.top, Espace.xs)
                if liste.indices.contains(choix) {
                    let tuile = liste[choix]
                    Button("Confirmer : \(nom(tuile).lowercased())") { confirmer(tuile) }
                        .buttonStyle(.principal)
                }
            }
        }
    }

    private var autre: some View {
        Button { modele.ouvrirLaGrille() } label: {
            VStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Palette.marine)
                    .frame(width: 44, height: 70)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.filet, lineWidth: 1.5))
                Text("Autre").font(Police.detail).foregroundStyle(Palette.encre)
            }
            .frame(minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Autre espèce")
    }

    private func confirmer(_ tuile: Tuile) {
        switch tuile {
        case .espece(let entree): modele.choisir(entree)
        case .classe(let nom, _): modele.ouvrirLaGrille(classe: nom)
        }
    }
}

/// P20 : « Autre espèce », toutes les espèces de France en images, par famille, celles du coin d'abord.
/// Jamais de champ de saisie : l'espèce se touche dans la grille ; les pastilles de famille font défiler jusqu'à la famille.
struct PriseGrilleView: View {
    var modele: PriseModele
    var classe: String?
    @State private var familleChoisie: PriseFamille?

    var body: some View {
        let groupes = PriseLogique.groupes(catalogue: modele.catalogue, proches: modele.proches, filtreClasse: classe)
        let active = familleChoisie ?? groupes.first?.famille
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, pleine: true, voile: 0.4) {
            ScrollViewReader { lecteur in
                VStack(alignment: .leading, spacing: Espace.m) {
                    Text("Autre espèce").font(Police.titre).foregroundStyle(Palette.encre)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                    ScrollView(.horizontal) {
                        HStack(spacing: Espace.s) {
                            ForEach(groupes, id: \.famille) { groupe in
                                Button {
                                    familleChoisie = groupe.famille
                                    withAnimation { lecteur.scrollTo(groupe.famille, anchor: .top) }
                                } label: {
                                    Text(groupe.famille.titre).font(Police.detail)
                                        .foregroundStyle(active == groupe.famille ? Color.white : Palette.encre)
                                        .padding(.horizontal, 14)
                                        .frame(minHeight: 36)
                                        .background(active == groupe.famille ? Palette.marine : Palette.tuile, in: Capsule())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(active == groupe.famille ? .isSelected : [])
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            ForEach(groupes, id: \.famille) { groupe in
                                VStack(alignment: .leading, spacing: Espace.m) {
                                    Text(groupe.famille.titre).font(Police.sousTitre).foregroundStyle(Palette.encre)
                                        .accessibilityAddTraits(.isHeader)
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 14) {
                                        ForEach(groupe.especes, id: \.espece.id) { entree in
                                            PriseTuile(entree: entree, duCoin: groupe.duCoin.contains(entree.espece.id), compacte: true) { modele.choisir(entree) }
                                        }
                                    }
                                }
                                .id(groupe.famille)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    Button("Je ne sais pas") { modele.jeNeSaisPas() }
                        .font(Police.detail).foregroundStyle(Palette.marine)
                        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                }
            }
        }
    }
}

/// Les sosies côte à côte, avec le critère et sa source, lus dans les données. Le pêcheur touche le bon.
struct PriseSosiesView: View {
    var modele: PriseModele
    var entree: EspecePechable

    var body: some View {
        let sosies = PriseLogique.sosies(de: entree, catalogue: modele.catalogue)
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(spacing: Espace.m) {
                PriseEntete(titre: "Touche le bon")
                HStack(alignment: .top, spacing: Espace.m) {
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
    }
}

struct PriseCritere: View {
    var critere: String
    var source: String

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(critere).font(Police.corps).foregroundStyle(Palette.encre)
            Text(source).font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.m)
        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }
}

/// Le stade de l'anguille : toujours demandé, en images, avec le critère qui sépare les stades.
struct PriseStadeView: View {
    var modele: PriseModele

    var body: some View {
        let stades = PriseLogique.stades(catalogue: modele.catalogue)
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, pleine: true) {
            VStack(spacing: Espace.m) {
                PriseEntete(titre: "Quel stade ?")
                ScrollView {
                    VStack(spacing: Espace.m) {
                        ForEach(Array(stades.enumerated()), id: \.offset) { _, s in
                            VStack(spacing: Espace.s) {
                                PriseTuile(entree: s.entree) { modele.confirmer(s.entree) }
                                if let c = s.critere { PriseCritere(critere: c.critere, source: c.source) }
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                Button("Je ne sais pas") { modele.jeNeSaisPas() }
                    .font(Police.detail).foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
    }
}

private extension String {
    /// Majuscule à la première lettre seulement (« Hotu ou toxostome »).
    var capitalizedPremiere: String { prefix(1).uppercased() + dropFirst() }
}
