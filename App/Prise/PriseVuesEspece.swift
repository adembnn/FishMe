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

/// Les trois tailles de tuile d'espèce : l'ancienne (sosies, stade), celle des propositions P19 et celle de la grille P20.
enum PriseFormatTuile {
    case standard, proposition, grille

    var hauteur: CGFloat {
        switch self { case .standard: return 84; case .proposition: return 70; case .grille: return 62 }
    }
    var rayon: CGFloat {
        switch self { case .standard, .proposition: return 16; case .grille: return 14 }
    }
    /// Taille maximale du poisson dans sa tuile (P19 : 78 × 52 ; P20 : 86 × 46).
    var imageMax: CGSize {
        switch self { case .standard: return CGSize(width: 200, height: 76); case .proposition: return CGSize(width: 78, height: 52); case .grille: return CGSize(width: 86, height: 46) }
    }
    var ecartTitre: CGFloat {
        switch self { case .standard, .proposition: return 6; case .grille: return 5 }
    }
}

/// L'image d'une espèce en vignette large (poisson de profil sur fond tuile), qui prend la largeur offerte.
/// Choisie : fond marine doux et contour marine de 2,5 points (P19).
struct PriseVignetteEspece: View {
    var entree: EspecePechable
    var selectionne = false
    var format: PriseFormatTuile = .standard

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: format.rayon, style: .continuous)
        Group {
            if UIImage(named: entree.image) != nil {
                Image(entree.image).resizable().scaledToFit()
                    .frame(maxWidth: format.imageMax.width, maxHeight: format.imageMax.height)
            } else {
                Image(systemName: PriseFamille.de(entree.espece.id).symbole)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(maxWidth: .infinity, minHeight: format.hauteur, maxHeight: format.hauteur)
        .background(selectionne ? Palette.marineDoux : Palette.tuile, in: forme)
        .overlay {
            if selectionne { forme.strokeBorder(Palette.marine, lineWidth: 2.5) }
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
    var format: PriseFormatTuile = .standard
    var action: () -> Void
    @Environment(\.locale) private var locale

    private var t: AnglaisD { AnglaisD(locale) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: format.ecartTitre) {
                PriseVignetteEspece(entree: entree, selectionne: selectionne, format: format)
                Text(titre ?? entree.nom)
                    .font(format == .grille ? Police.legende : Police.detail).foregroundStyle(Palette.encre)
                    .lineSpacing(0)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titre ?? entree.nom)
        .accessibilityValue(duCoin ? t("Relevée près de toi") : "")
        .accessibilityAddTraits(selectionne ? .isSelected : [])
    }
}

/// P19 : les 3 propositions en images, sur la photo, plus une case « Autre ». Aucun pourcentage.
/// Le pêcheur touche la bonne, puis « Confirmer : … » (un seul bouton principal).
struct PrisePropositionsView: View {
    var modele: PriseModele
    @State private var choix = 0
    @Environment(\.locale) private var locale

    private var t: AnglaisD { AnglaisD(locale) }

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
        if liste.isEmpty {
            // Aucune proposition : la phrase, puis la grille directement.
            PriseGrilleView(modele: modele, classe: nil, titre: "Je n'ai pas reconnu ton poisson")
        } else {
            propositions(liste)
        }
    }

    /// Maquette P19 A : titre de 22, tuiles de 70 de haut (écart de 10), 16 sous le titre et 20 avant « Confirmer ».
    private func propositions(_ liste: [Tuile]) -> some View {
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(alignment: .leading, spacing: 0) {
                Text(t("Quelle espèce ?")).font(Police.titre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                HStack(alignment: .top, spacing: 10) {
                    // Dans l'ordre du modèle (le plus probable d'abord), espèce seule ou groupe de sosies.
                    // Un groupe (« brochet » : brochet et brochet aquitain) montre l'image de sa 1re espèce et ouvre ses sosies.
                    ForEach(Array(liste.enumerated()), id: \.offset) { i, tuile in
                        switch tuile {
                        case .espece(let entree):
                            PriseTuile(entree: entree, selectionne: choix == i, format: .proposition) { choix = i }
                        case .classe(_, let premiere):
                            if let premiere {
                                PriseTuile(entree: premiere, selectionne: choix == i, titre: nom(tuile), format: .proposition) { choix = i }
                            } else {
                                Button(nom(tuile)) { choix = i }.buttonStyle(.secondaire)
                            }
                        }
                    }
                    autre
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
                if liste.indices.contains(choix) {
                    let tuile = liste[choix]
                    Button(t("Confirmer : %@", nom(tuile).lowercased())) { confirmer(tuile) }
                        .buttonStyle(.principal)
                }
            }
        }
    }

    private var autre: some View {
        Button { modele.ouvrirLaGrille() } label: {
            VStack(spacing: PriseFormatTuile.proposition.ecartTitre) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: PriseFormatTuile.proposition.hauteur, maxHeight: PriseFormatTuile.proposition.hauteur)
                    .overlay(RoundedRectangle(cornerRadius: PriseFormatTuile.proposition.rayon, style: .continuous)
                        .strokeBorder(Palette.filet, lineWidth: 1.5))
                Text(t("Autre")).font(Police.detail).foregroundStyle(Palette.encre)
            }
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t("Autre espèce"))
    }

    private func confirmer(_ tuile: Tuile) {
        switch tuile {
        case .espece(let entree): modele.choisir(entree)
        case .classe(let nom, _): modele.ouvrirLaGrille(classe: nom)
        }
    }
}

/// P20 : « Autre espèce », toutes les espèces de France en images, par famille, celles du coin d'abord.
/// Jamais de champ de saisie d'espèce : l'espèce se touche dans la grille ; les pastilles de famille font défiler jusqu'à la famille.
/// Maquette P20 A : feuille haute (128 du haut de l'écran), titre, champ de recherche de 40, pastilles de 34, grille de 3 colonnes (écarts 10 et 14).
struct PriseGrilleView: View {
    var modele: PriseModele
    var classe: String?
    /// Titre de la feuille ; « Autre espèce » par défaut.
    var titre = "Autre espèce"
    @State private var familleChoisie: PriseFamille?
    /// Filtre la grille par le nom ; ce n'est pas une saisie d'espèce : l'espèce se touche toujours dans la grille.
    @State private var filtre = ""
    @Environment(\.locale) private var locale

    private var t: AnglaisD { AnglaisD(locale) }

    private func correspond(_ entree: EspecePechable) -> Bool {
        let texte = filtre.trimmingCharacters(in: .whitespaces)
        if texte.isEmpty { return true }
        return entree.nom.range(of: texte, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    var body: some View {
        let tous = PriseLogique.groupes(catalogue: modele.catalogue, proches: modele.proches, filtreClasse: classe)
        let groupes = tous.filter { groupe in groupe.especes.contains(where: correspond) }
        let active = familleChoisie ?? groupes.first?.famille
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, haut: 128, voile: 0.4) {
            ScrollViewReader { lecteur in
                VStack(alignment: .leading, spacing: 0) {
                    Text(t(titre)).font(Police.titre).foregroundStyle(Palette.encre)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: Espace.s) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
                        TextField("", text: $filtre,
                                  prompt: Text(t("Rechercher une espèce")).foregroundStyle(Palette.encreDouce))
                            .font(Police.corps).foregroundStyle(Palette.encre)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if !filtre.isEmpty {
                            Button { filtre = "" } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(Palette.encreDouce)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(t("Effacer"))
                        }
                    }
                    .padding(.horizontal, Espace.m)
                    .frame(height: 40)
                    .background(Color(red: 118 / 255, green: 128 / 255, blue: 140 / 255).opacity(0.14),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, Espace.m)
                    ScrollView(.horizontal) {
                        HStack(spacing: Espace.s) {
                            ForEach(groupes, id: \.famille) { groupe in
                                Button {
                                    familleChoisie = groupe.famille
                                    withAnimation { lecteur.scrollTo(groupe.famille, anchor: .top) }
                                } label: {
                                    Text(t(groupe.famille.titre)).font(Police.detail)
                                        .foregroundStyle(active == groupe.famille ? Color.white : Palette.encre)
                                        .padding(.horizontal, 14)
                                        .frame(height: 34)
                                        .background(active == groupe.famille ? Palette.marine : Palette.surface, in: Capsule())
                                        .overlay { if active != groupe.famille { Capsule().strokeBorder(Palette.filet, lineWidth: 1) } }
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(active == groupe.famille ? .isSelected : [])
                            }
                        }
                    }
                    .contentMargins(.horizontal, 20, for: .scrollContent)
                    .padding(.horizontal, -20)
                    .scrollIndicators(.hidden)
                    .padding(.top, 14)
                    if groupes.isEmpty { rechercheVide.padding(.top, 18) }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(groupes.enumerated()), id: \.offset) { rang, groupe in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Maquette : la première famille n'a pas d'intitulé (la pastille choisie le dit), les suivantes oui.
                                    if rang > 0 {
                                        Text(t(groupe.famille.titre)).font(Police.sousTitre).foregroundStyle(Palette.encre)
                                            .padding(.top, 22).padding(.bottom, Espace.m)
                                            .accessibilityAddTraits(.isHeader)
                                    }
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 14) {
                                        ForEach(groupe.especes.filter(correspond), id: \.espece.id) { entree in
                                            PriseTuile(entree: entree, duCoin: groupe.duCoin.contains(entree.espece.id), format: .grille) { modele.choisir(entree) }
                                        }
                                    }
                                }
                                .id(groupe.famille)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .padding(.top, groupes.isEmpty ? 0 : 18)
                }
            }
        }
    }

    /// État sans résultat : un poisson, une phrase, une issue (jamais un blanc).
    private var rechercheVide: some View {
        VStack(spacing: Espace.m) {
            Image(systemName: "fish.fill")
                .font(.system(size: 44, weight: .bold, design: .rounded)).foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
            Text(t("Aucune espèce ne porte ce nom")).font(Police.sousTitre).foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
            Button(t("Effacer la recherche")) { filtre = "" }.buttonStyle(.secondaire)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Espace.xl)
    }
}

/// Les sosies côte à côte, avec le critère et sa source, lus dans les données. Le pêcheur touche le bon.
struct PriseSosiesView: View {
    var modele: PriseModele
    var entree: EspecePechable
    @Environment(\.locale) private var locale

    private var t: AnglaisD { AnglaisD(locale) }

    var body: some View {
        let sosies = PriseLogique.sosies(de: entree, catalogue: modele.catalogue)
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(spacing: Espace.m) {
                PriseEntete(titre: t("Touche le bon"))
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
    @Environment(\.locale) private var locale

    private var t: AnglaisD { AnglaisD(locale) }

    var body: some View {
        let stades = PriseLogique.stades(catalogue: modele.catalogue)
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, pleine: true) {
            VStack(spacing: Espace.m) {
                PriseEntete(titre: t("Quel stade ?"))
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
                Button(t("Je ne sais pas")) { modele.jeNeSaisPas() }
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
