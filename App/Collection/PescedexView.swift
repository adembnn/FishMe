import Core
import SwiftUI
import UIKit

/// Gris-bleu des chevrons de liste (`.chevron` de la maquette).
private let chevronGris = Color(carte: 0xB4BFCB)

/// Titre d'écran (`.t-grand` : 34 pt, 900, interlettrage -0,01 em).
private func grandTitre(_ texte: String) -> some View {
    Text(texte)
        .font(Police.grandTitre)
        .tracking(-0.34)
        .foregroundStyle(Palette.encre)
}

/// En-tête de groupe (`.entete-groupe` : 13 pt, 800, majuscules, interlettrage 0,04 em, décalé de 16).
func enteteDeGroupe(_ texte: String, haut: CGFloat = 8) -> some View {
    Text(texte.uppercased())
        .font(Police.legende)
        .tracking(0.52)
        .foregroundStyle(Palette.encreDouce)
        .padding(.horizontal, Espace.l)
        .padding(.top, haut)
}

/// Le volet Pescedex (P26 B, P45 B, P48 B) : grand titre, phrase de la zone, « Les miens / Amis », « Voir mon aquarium »,
/// puis un classeur en blocs blancs de cartes en vignette : TROUVÉES, DÉCLARÉES, À TROUVER. Aucune barre de défilement visible.
/// La fiche d'une espèce (P27 B, P28 B) s'ouvre en page, avec le retour « Pescedex » de la barre de navigation.
struct PescedexView: View {
    @State var modele: PescedexModele
    var emplacements: EmplacementsExternes = .vides
    /// Ouvre l'aquarium. À brancher : RootView (aucune destination aquarium n'existe dans App/Collection).
    /// Tant que c'est `nil`, la ligne « Voir mon aquarium » n'est pas affichée.
    var voirAquarium: (() -> Void)? = nil
    /// « Pêcher un sandre en photo », sur la fiche d'une carte déclarée. À brancher : RootView (ouvre la prise sur cette espèce).
    /// Tant que c'est `nil`, la ligne n'est pas affichée.
    var pecherEnPhoto: ((Espece) -> Void)? = nil
    /// « Photographier une prise », dans « Pour commencer » (Pescedex vide). À brancher : RootView (ouvre l'onglet de prise).
    /// Tant que c'est `nil`, la ligne n'est pas affichée.
    var photographier: (() -> Void)? = nil
    /// « Déclarer un poisson déjà pêché ». À brancher : RootView (ouvre les cartes à swiper). Tant que c'est `nil`, la ligne n'est pas affichée.
    var declarer: (() -> Void)? = nil
    /// Choix « Amis » du sélecteur. À brancher : RootView (`app.onglet = .club`). Tant que c'est `nil`, le choix revient sur « Les miens ».
    var voirAmis: (() -> Void)? = nil
    /// Les meilleurs conseils par type (appât, hameçon, technique, moment) pour une espèce et le niveau du pêcheur, déjà filtrés
    /// par l'abonnement. À brancher : RootView (voir `ContexteConseils.parType`). Tant que c'est `nil`, la fiche garde « comment la pêcher ».
    var conseilsParType: ((Espece, NiveauPecheur) -> [TypeConseil: Conseil])? = nil
    /// « Changer » sur la ligne de la zone (P48 B). À brancher : RootView (choix d'une autre zone). Tant que c'est `nil`, la ligne n'a ni « Changer » ni chevron.
    var changerZone: (() -> Void)? = nil
    /// « Importer une photo » : enregistre la carte (photo brute, espèce, taille en cm, date, lieu flou), recharge le Pescedex
    /// et montre la révélation. À brancher : RootView. Tant que c'est `nil`, la carte est écrite ici dans le dépôt et le Pescedex rechargé.
    var ajouterManuellement: ((Data, Espece, Int?, Date, String?) async -> Void)? = nil

    @State private var volet: Volet = .miens
    @State private var ajoutManuelOuvert = false
    @State private var carteOuverte: Emplacement?
    @State private var ficheOuverte: String?
    @State private var bredouilleOuverte: CarteBredouille?
    @State private var conditionsOuvertes = false
    @State private var photoOuverte: Data?
    @State private var pngOuvert: Data?
    @State private var bredouillesDepliees = false
    @State private var aTrouverDeplie = false

    private enum Volet: String, CaseIterable, Identifiable {
        case miens = "Les miens"
        case amis = "Amis"
        var id: String { rawValue }
    }

    /// Nombre de vignettes de sorties sans prise montrées avant « + N autres ».
    private let apercu = 6

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                entete
                classeur
            }
            .padding(.horizontal, Espace.bord)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Pescedex")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $ficheOuverte) { id in
                if let emplacement = modele.emplacements.first(where: { $0.id == id }) {
                    FicheEspeceView(emplacement: emplacement, zone: modele.zone, emplacements: emplacements_,
                                    infos: emplacement.carte?.estDeclaree == true ? modele.infos(pour: emplacement) : nil,
                                    pecherEnPhoto: pecherEnPhoto, aEssayer: aEssayer, conseilsParType: conseilsParType)
                }
            }
        }
        .task { await modele.charger() }
        .onChange(of: volet) { _, nouveau in
            if nouveau == .amis {
                voirAmis?()
                volet = .miens
            }
        }
        .fullScreenCover(item: $carteOuverte) { emplacement in
            if let infos = modele.infos(pour: emplacement) {
                CartePleinEcranView(infos: infos, photo: photoOuverte, emplacements: emplacements_, png: pngOuvert) {
                    carteOuverte = nil
                }
            }
        }
        .fullScreenCover(item: $bredouilleOuverte) { carte in
            BredouillePleinEcranView(carte: carte, services: modele.services, emplacements: emplacements_) {
                bredouilleOuverte = nil
            }
        }
        .sheet(isPresented: $ajoutManuelOuvert) {
            AjoutManuelPriseView(especes: modele.services.especes.especesPechables(), creer: creerManuellement)
        }
        .sheet(isPresented: $conditionsOuvertes) {
            Group {
                if let tes = emplacements.tesConditions { tes() }
            }
        }
    }

    private var emplacements_: EmplacementsExternes { emplacements }

    /// Crée la carte d'une photo importée : la closure de RootView si elle est branchée, sinon écriture directe dans le dépôt.
    private func creerManuellement(_ photo: Data, _ espece: Espece, _ cm: Int?, _ date: Date, _ lieu: String?) async {
        if let ajouterManuellement {
            await ajouterManuellement(photo, espece, cm, date, lieu)
            return
        }
        let prise = Prise(espece: espece, origine: .priseReelle, longueurCm: cm.map(Double.init),
                          mesure: cm == nil ? nil : .saisie, date: date, lieuFlou: lieu, exemple: false)
        _ = try? await modele.depot.enregistrer(prise: prise, photo: photo)
        await modele.charger()
    }

    /// « Ajouter une prise » : photo prise dans l'app, ou photo importée de la photothèque.
    private var boutonAjout: some View {
        Menu {
            if let photographier {
                Button { photographier() } label: { Label("Prendre une photo", systemImage: "camera") }
            }
            Button { ajoutManuelOuvert = true } label: { Label("Importer une photo", systemImage: "photo.on.rectangle") }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Ajouter une prise")
    }

    private var estVide: Bool { PescedexVide.estVide(modele.emplacements) }

    /// L'espèce de la zone la plus pêchée par l'OFB que le pêcheur n'a pas encore trouvée (« À essayer près de toi », P28 B). `nil` sans relevé.
    private var aEssayer: Emplacement? {
        modele.emplacements
            .filter { $0.carte == nil && $0.releveeDansLaZone && $0.rarete.nTotal > 0 }
            .max { Double($0.rarete.nPeches) / Double($0.rarete.nTotal) < Double($1.rarete.nPeches) / Double($1.rarete.nTotal) }
    }

    // MARK: En-tête (P26 B)

    private var entete: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                grandTitre("Pescedex")
                Spacer(minLength: Espace.s)
                boutonAjout
            }
            if !sousTitre.isEmpty {
                Text(sousTitre)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }
            if !estVide {
                Picker("Volet", selection: $volet) {
                    ForEach(Volet.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(height: 34)
                .padding(.top, Espace.m)
            }
            if let voirAquarium, !estVide {
                Button(action: voirAquarium) {
                    HStack(spacing: Espace.m) {
                        Image(systemName: "fish")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        Text("Voir mon aquarium")
                            .font(Police.corps)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.encreDouce)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Palette.marine)
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .tuileFishMe(rayon: 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, Espace.m)
            }
        }
        .padding(.bottom, Espace.xs)
    }

    /// P26 B : « Tu en as trouvé 3 sur 11 espèces de la zone » ; P45 B : « Tu n'as pas encore trouvé les 11 espèces de la zone ».
    /// À brancher : le nom de l'eau (« de la Marne ») n'existe pas dans le modèle ; « de la zone » le remplace.
    private var sousTitre: String {
        let c = modele.compteur
        if estVide {
            if modele.zone != nil, c.releveesDansLaZone > 0 {
                return phraseAvecNom("Tu n'as pas encore trouvé les \(c.releveesDansLaZone) espèces de la zone") ?? ""
            }
            return PescedexVide.texte
        }
        // Avec le bloc de zone (P48 B), la phrase est sous la barre : pas de sous-titre.
        if zoneEnCartes { return "" }
        return phraseAvecNom(c.phraseDeZone) ?? c.texte
    }

    /// Le nom du département en toutes lettres (« Val-de-Marne »). Le nom de l'eau n'existe pas dans le modèle.
    private var nomDepartement: String? {
        guard let zone = modele.compteur.zone, !zone.estInconnu else { return nil }
        return NomsDepartements.nom(code: zone.code)
    }

    /// « … espèces de la zone » devient « … espèces de la zone (Val-de-Marne) » quand le nom est connu.
    private func phraseAvecNom(_ phrase: String?) -> String? {
        guard let phrase else { return nil }
        guard let nom = nomDepartement else { return phrase }
        return phrase.replacingOccurrences(of: "de la zone", with: "de la zone (\(nom))")
    }

    // MARK: Zone (P48 B)

    /// Vrai quand le bloc « Ta zone » s'ajoute : une zone connue, des espèces relevées dedans, au moins une carte.
    private var zoneEnCartes: Bool {
        guard let zone = modele.zone, !zone.estInconnu else { return false }
        return modele.compteur.releveesDansLaZone > 0 && !estVide
    }

    private var ligneZone: some View {
        HStack(spacing: Espace.m) {
            Image(systemName: "mappin")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: 32)
                .accessibilityHidden(true)
            // À brancher : le nom de l'eau (« La Marne · 94 ») n'existe pas dans le modèle ; le département seul, jamais un total national.
            Text(texteLigneZone)
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
            if changerZone != nil {
                Text("Changer")
                    .font(Police.taille(17, .bold))
                    .foregroundStyle(Palette.encreDouce)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(chevronGris)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.s)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }

    /// P48 B : « Val-de-Marne · 94 » ; sans nom connu, le code seul (« Département 94 »).
    private var texteLigneZone: String {
        if let nom = nomDepartement, let code = modele.compteur.zone?.code { return "\(nom) · \(code)" }
        return NomDeZone.texte(departement: modele.compteur.zone) ?? "Zone"
    }

    private var blocZone: some View {
        let c = modele.compteur
        let part = c.releveesDansLaZone > 0 ? min(1, Double(c.trouvees) / Double(c.releveesDansLaZone)) : 0
        let pourcent = Int((part * 100).rounded())
        return VStack(alignment: .leading, spacing: 0) {
            enteteDeGroupe("Ta zone")
            VStack(alignment: .leading, spacing: 0) {
                if let changerZone {
                    Button(action: changerZone) { ligneZone }
                        .buttonStyle(.plain)
                } else {
                    ligneZone
                }
                Divider().overlay(Palette.filet)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(c.trouvees)")
                                .font(Police.chiffre)
                                .monospacedDigit()
                                .foregroundStyle(Palette.encre)
                            Text(" sur \(c.releveesDansLaZone)").font(Police.detail).foregroundStyle(Palette.encreDouce)
                        }
                        Spacer(minLength: 0)
                        Text("\(pourcent) %").font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.tuile)
                            Capsule().fill(Palette.marine).frame(width: geo.size.width * part)
                        }
                    }
                    .frame(height: 12)
                    .padding(.top, 10)
                    // P48 : l'unique phrase du compteur, juste sous la barre.
                    if let phrase = c.phraseDeZone {
                        Text(phrase)
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                    }
                }
                .padding(.top, Espace.m)
                .padding(.horizontal, Espace.l)
                .padding(.bottom, Espace.l)
            }
            .tuileFishMe(rayon: Rayon.m)
            .padding(.top, Espace.s)
            .accessibilityElement(children: changerZone == nil ? .ignore : .contain)
            .accessibilityLabel(c.phraseDeZone ?? c.texte)
        }
    }

    // MARK: Pescedex vide (P45 B)

    private var pourCommencer: some View {
        VStack(alignment: .leading, spacing: 0) {
            enteteDeGroupe("Pour commencer", haut: 14)
            VStack(spacing: 0) {
                if let photographier {
                    ligneDepart("Photographier une prise", icone: "camera", action: photographier)
                }
                if photographier != nil, declarer != nil { Divider().overlay(Palette.filet).padding(.leading, Espace.l) }
                if let declarer {
                    ligneDepart("Déclarer un poisson déjà pêché", icone: "checkmark.circle.fill", action: declarer)
                }
            }
            .tuileFishMe(rayon: Rayon.m)
            .padding(.top, Espace.s)
        }
    }

    /// Sans action fournie, l'écran vide garde quand même une ligne utile (rien d'inventé).
    private var premierePrise: some View {
        HStack(spacing: Espace.m) {
            Image(systemName: "camera")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: 32)
                .accessibilityHidden(true)
            Text(PescedexVide.texte)
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Espace.l)
        .frame(minHeight: 56)
        .tuileFishMe(rayon: Rayon.m)
    }

    private func ligneDepart(_ titre: String, icone: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Image(systemName: icone)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                Text(titre)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .padding(.vertical, Espace.s)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Classeur

    private var trouvees: [Emplacement] { modele.emplacements.filter { $0.carte != nil && $0.carte?.estDeclaree == false } }
    private var declarees: [Emplacement] { modele.emplacements.filter { $0.carte?.estDeclaree == true } }
    /// À trouver : les espèces de la zone pas encore prises (le M du compteur) ; sans relevé, toutes celles pas encore prises.
    private var aTrouver: [Emplacement] {
        let sans = modele.emplacements.filter { $0.carte == nil }
        let zone = sans.filter(\.releveeDansLaZone)
        return zone.isEmpty ? sans : zone
    }

    private var colonnes: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3) }

    private var classeur: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if estVide {
                    if photographier != nil || declarer != nil { pourCommencer } else { premierePrise }
                    // P45 B : le Pescedex vide reste plein, avec six silhouettes de la zone puis « + N autres ».
                    sectionATrouver
                } else {
                    if zoneEnCartes { blocZone }
                    sectionCartes("Trouvées", trouvees)
                    sectionDeclarees
                    sectionATrouver
                }
                sectionBredouilles
                if emplacements.tesConditions != nil {
                    Button { conditionsOuvertes = true } label: {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "cloud.sun")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.marine)
                                .frame(width: 32)
                                .accessibilityHidden(true)
                            Text("Tes conditions")
                                .font(Police.corps)
                                .foregroundStyle(Palette.encre)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.encreDouce)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, Espace.l)
                        .padding(.vertical, Espace.s)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Espace.l)
                }
            }
            .padding(.top, Espace.xs)
            .padding(.bottom, Espace.xxl)
        }
        .scrollIndicators(.hidden)
    }

    /// Un bloc blanc de cartes en vignette, trois par ligne (12 pt de marge, 8 pt entre les cartes).
    @ViewBuilder
    private func sectionCartes(_ titre: String, _ liste: [Emplacement]) -> some View {
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                enteteDeGroupe("\(titre) · \(liste.count)", haut: 16)
                LazyVGrid(columns: colonnes, spacing: Espace.s) {
                    ForEach(liste) { emplacement in cellule(emplacement) }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
                .padding(.top, Espace.s)
            }
        }
    }

    /// Déclarées : la carte dans la première colonne, la phrase sur les deux autres (P26 B) ; plusieurs, une grille puis la phrase.
    @ViewBuilder
    private var sectionDeclarees: some View {
        let liste = declarees
        if !liste.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                enteteDeGroupe("Déclarées · \(liste.count)", haut: 16)
                Group {
                    if liste.count == 1, let seule = liste.first {
                        UnTiersDeuxTiers(espacement: Espace.s) {
                            cellule(seule)
                            noteDeclaree
                                .padding(.horizontal, Espace.s)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Espace.m) {
                            LazyVGrid(columns: colonnes, spacing: Espace.s) {
                                ForEach(liste) { emplacement in cellule(emplacement) }
                            }
                            noteDeclaree
                        }
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
                .padding(.top, Espace.s)
            }
        }
    }

    private var noteDeclaree: some View {
        Text("Sans photo. Pêches-en un pour en faire une vraie carte.")
            .font(Police.detail)
            .foregroundStyle(Palette.encreDouce)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Dos de cartes marine, toutes les espèces pas encore trouvées (P26 B).
    @ViewBuilder
    private var sectionATrouver: some View {
        let liste = aTrouver
        if !liste.isEmpty {
            let visibles = (estVide && !aTrouverDeplie) ? Array(liste.prefix(apercu)) : liste
            VStack(alignment: .leading, spacing: 0) {
                enteteDeGroupe("À trouver · \(liste.count)", haut: 16)
                VStack(spacing: Espace.s) {
                    LazyVGrid(columns: colonnes, spacing: Espace.s) {
                        ForEach(visibles) { e in
                            Button { ficheOuverte = e.id } label: { DosAATrouver(espece: e.espece) }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(e.espece.nom), pas encore pris")
                        }
                    }
                    if estVide, liste.count > apercu {
                        Button { aTrouverDeplie.toggle() } label: {
                            Text(aTrouverDeplie ? "Réduire" : "+ \(liste.count - apercu) autres")
                                .font(Police.detail)
                                .foregroundStyle(Palette.encreDouce)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
                .padding(.top, Espace.s)
            }
        }
    }

    /// Les sessions finies sans poisson, rangées à part : six vignettes au plus, puis « + N autres ».
    /// À confirmer : la maquette P26 B ne montre pas ce bloc ; il garde la place des cartes bredouilles (L4).
    @ViewBuilder
    private var sectionBredouilles: some View {
        let liste = modele.bredouilles
        if !liste.isEmpty {
            let visibles = bredouillesDepliees ? liste : Array(liste.prefix(apercu))
            VStack(alignment: .leading, spacing: 0) {
                enteteDeGroupe("Eau calme · \(liste.count)", haut: 16)
                VStack(spacing: Espace.s) {
                    LazyVGrid(columns: colonnes, spacing: Espace.s) {
                        ForEach(visibles) { b in
                            Button { bredouilleOuverte = b } label: {
                                CarteBredouilleRectoView(carte: b, refletFixe: true, mini: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Sortie sans prise, \(Formats.date(b.debut))")
                        }
                    }
                    if liste.count > apercu {
                        Button { bredouillesDepliees.toggle() } label: {
                            Text(bredouillesDepliees ? "Réduire" : "+ \(liste.count - apercu) autres")
                                .font(Police.detail)
                                .foregroundStyle(Palette.encreDouce)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(Espace.m)
                .tuileFishMe(rayon: Rayon.m)
                .padding(.top, Espace.s)
            }
        }
    }

    @ViewBuilder
    private func cellule(_ e: Emplacement) -> some View {
        Button {
            if let carte = e.carte, !carte.estDeclaree {
                Task {
                    photoOuverte = await modele.depot.photo(de: carte)
                    // La carte s'ouvre tout de suite ; le PNG de partage (rendu lourd) arrive juste après.
                    pngOuvert = nil
                    carteOuverte = e
                    let png = await modele.depot.imagePNG(de: carte)
                    if carteOuverte?.id == e.id { pngOuvert = png }
                }
            } else {
                ficheOuverte = e.id
            }
        } label: {
            if let infos = InfosCarte.vignette(emplacement: e, zone: modele.zone) {
                CarteRectoView(infos: infos, mini: true)
                    // Mode démo (Adem, 16 oct.) : une carte installée par la démo le dit toujours.
                    .overlay(alignment: .bottom) {
                        if let carte = e.carte, DemoPescedex.estDemo(carte.id) {
                            PastilleDemo().padding(.bottom, 6)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle(e))
    }

    private func libelle(_ e: Emplacement) -> String {
        guard let c = e.carte else { return "\(e.espece.nom), pas encore pris" }
        let style = StyleRarete(e.rarete.niveau)
        let zone = modele.zone.map { " dans le \($0.code)" } ?? ""
        if c.estDeclaree { return "\(e.espece.nom), carte déclarée" }
        let t = Formats.taille(c).map { ", \($0)" } ?? ""
        return "\(e.espece.nom), \(style.mot)\(zone)\(t)"
    }
}

/// Une carte à gauche (un tiers de la largeur), un texte à droite (deux tiers).
private struct UnTiersDeuxTiers: Layout {
    var espacement: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let largeur = proposal.width ?? 300
        let un = (largeur - 2 * espacement) / 3
        let deux = largeur - un - espacement
        let h1 = subviews[0].sizeThatFits(ProposedViewSize(width: un, height: nil)).height
        let h2 = subviews[1].sizeThatFits(ProposedViewSize(width: deux, height: nil)).height
        return CGSize(width: largeur, height: max(h1, h2))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let un = (bounds.width - 2 * espacement) / 3
        let deux = bounds.width - un - espacement
        let h1 = subviews[0].sizeThatFits(ProposedViewSize(width: un, height: nil)).height
        let h2 = subviews[1].sizeThatFits(ProposedViewSize(width: deux, height: nil)).height
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.minY + (bounds.height - h1) / 2), anchor: .topLeading,
                          proposal: ProposedViewSize(width: un, height: h1))
        subviews[1].place(at: CGPoint(x: bounds.minX + un + espacement, y: bounds.minY + (bounds.height - h2) / 2),
                          anchor: .topLeading, proposal: ProposedViewSize(width: deux, height: h2))
    }
}

/// Le dos d'une carte « à trouver » (`.fc.dos`, P26 B) : marine, les anneaux de l'eau, la silhouette blanche de l'espèce et son nom en bas.
struct DosAATrouver: View {
    let espece: EspecePechable

    var body: some View {
        // Marine fixe (même en mode sombre) pour que le texte blanc reste lisible.
        CarteCadre(style: .commun, declaree: false, fond: Color(carte: 0x0D4A85)) {
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let u = w / 100
                let rapport: CGFloat = {
                    guard let image = UIImage(named: espece.image), image.size.height > 0 else { return 2.8 }
                    return image.size.width / image.size.height
                }()
                ZStack(alignment: .topLeading) {
                    OndesFenetre().opacity(0.18)
                    Image(espece.image)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: w * 0.68, height: w * 0.68 / rapport)
                        .offset(x: w * 0.16, y: h * 0.36)
                        .accessibilityHidden(true)
                    Text(NomCarte.court(espece.nom))
                        .font(Police.taille(9 * u, .heavy))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(1)
                        .padding(.horizontal, 6 * u)
                        .frame(width: w)
                        .position(x: w / 2, y: h * 0.91 - 4.5 * u)
                }
                .frame(width: w, height: h, alignment: .topLeading)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(espece.nom), pas encore pris")
    }
}

/// Article indéfini d'un nom de poisson (« un sandre », « une perche »). Masculin sauf pour les noms féminins connus.
enum ArticlePoisson {
    private static let feminins: Set<String> = [
        "perche", "truite", "carpe", "tanche", "brème", "breme", "anguille", "lamproie", "loche", "ablette", "vandoise",
        "bouvière", "bouviere", "écrevisse", "ecrevisse", "grenouille", "lotte", "alose", "gambusie", "épinoche", "epinoche",
        "bondelle", "féra", "fera", "truitelle",
    ]

    static func indefini(pour nom: String) -> String {
        let premier = nom.lowercased().split(whereSeparator: { $0 == " " || $0 == "-" || $0 == "'" }).first.map(String.init) ?? ""
        return feminins.contains(premier) ? "une \(nom.lowercased())" : "un \(nom.lowercased())"
    }
}

/// La fiche d'une espèce, ouverte en page avec le retour « Pescedex » : P27 B pour une espèce pas encore trouvée
/// (nom, nom latin, image, palier avec le nombre de pêches OFB et l'année, puis « comment la pêcher » de L13) ;
/// P28 B pour une carte déclarée (la carte sans photo, la ligne pour la pêcher en vrai, « À essayer près de toi »).
struct FicheEspeceView: View {
    let emplacement: Emplacement
    let zone: Departement?
    let emplacements: EmplacementsExternes
    /// Renseigné seulement pour une carte déclarée : sert à montrer la carte elle-même.
    var infos: InfosCarte? = nil
    /// Ouvre la prise sur cette espèce. À brancher : RootView via `PescedexView.pecherEnPhoto`.
    var pecherEnPhoto: ((Espece) -> Void)? = nil
    /// Une espèce de la zone pas encore trouvée, pour « À essayer près de toi » (carte déclarée seulement).
    var aEssayer: Emplacement? = nil
    /// Conseils par type pour « Pour toi » (P27 B) et « À essayer près de toi » (P28 B). `nil` : l'ancien bloc « comment la pêcher ».
    var conseilsParType: ((Espece, NiveauPecheur) -> [TypeConseil: Conseil])? = nil
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue

    private func conseils(_ e: Emplacement) -> [TypeConseil: Conseil] {
        conseilsParType?(e.espece.espece, NiveauPecheur.depuis(niveauBrut)) ?? [:]
    }

    private var style: StyleRarete { StyleRarete(emplacement.rarete.niveau) }
    private var estDeclaree: Bool { emplacement.carte?.estDeclaree == true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    grandTitre(emplacement.espece.nom)
                    Text(estDeclaree ? "Carte déclarée" : emplacement.espece.nomLatin)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                }
                .padding(.top, 4)
                if estDeclaree, let infos {
                    carteDeclaree(infos)
                        .padding(.top, 14)
                } else {
                    tuileEspece
                        .padding(.top, 12)
                    if zone != nil, style != .nonMesuree { releves }
                }
                if let pecherEnPhoto, estDeclaree {
                    Button { pecherEnPhoto(emplacement.espece.espece) } label: {
                        HStack(spacing: Espace.m) {
                            Image(systemName: "camera")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .frame(width: 28)
                                .accessibilityHidden(true)
                            Text("Pêcher \(ArticlePoisson.indefini(pour: emplacement.espece.nom)) en photo")
                                .font(Police.corps)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(chevronGris)
                                .accessibilityHidden(true)
                        }
                        .foregroundStyle(Palette.marine)
                        .padding(.horizontal, Espace.l)
                        .padding(.vertical, Espace.s)
                        .frame(minHeight: 56)
                        .tuileFishMe(rayon: Rayon.m)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, Espace.l)
                }
                if estDeclaree, let aEssayer {
                    enteteDeGroupe("À essayer près de toi", haut: 22)
                    blocAEssayer(aEssayer)
                        .tuileFishMe(rayon: Rayon.m)
                        .padding(.top, Espace.s)
                }
                // « Où il vit » (cache, eau) : aucune donnée d'habitat n'existe, on garde les relevés OFB ci-dessus.
                pourToi
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    /// P27 B, « Pour toi » : les lignes Appât / Hameçon / Technique / Moment si les conseils sont branchés,
    /// sinon le bloc « comment la pêcher » de L13 rendu par RootView.
    @ViewBuilder private var pourToi: some View {
        let parType = conseils(emplacement)
        if !parType.isEmpty {
            BlocPourToi(parType: parType)
        } else if let comment = emplacements.commentLaPecher {
            comment(emplacement.espece.espece)
                .padding(.top, Espace.m)
        }
    }

    /// P28 B : dans un seul bloc, la ligne de l'espèce, « Conseil du jour » (l'appât) et « Moment ». Une ligne sans donnée disparaît.
    private func blocAEssayer(_ e: Emplacement) -> some View {
        let parType = conseils(e)
        return VStack(spacing: 0) {
            ligneAEssayer(e)
            if let appat = parType[.appat] {
                Divider().overlay(Palette.filet).padding(.leading, 52)
                LigneIconeFiche(icone: IconesConseils.parDefaut(.appat), titre: "Conseil du jour", valeur: appat.texte)
            }
            if let moment = parType[.moment] {
                Divider().overlay(Palette.filet).padding(.leading, 52)
                LigneIconeFiche(icone: IconesConseils.parDefaut(.moment), titre: "Moment", valeur: moment.texte)
            }
        }
    }

    /// P27 B : le poisson en image (260 × 78), puis le palier à gauche et « 34 % · 10 sur 29 » à droite.
    private var tuileEspece: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(emplacement.espece.image)
                .resizable().scaledToFit()
                .frame(width: 260, height: 78)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 6)
                .accessibilityHidden(true)
            if zone != nil, style != .nonMesuree {
                HStack(spacing: Espace.m) {
                    HStack(spacing: 5) {
                        MarqueRarete(style: style, taille: 14)
                        Text(motDuPalier)
                            .font(Police.taille(13, .heavy))
                            .foregroundStyle(style.couleur)
                    }
                    Spacer(minLength: 0)
                    if let ligne = ligneChiffres {
                        Text(ligne)
                            .font(Police.taille(17, .bold))
                            .monospacedDigit()
                            .foregroundStyle(Palette.encreDouce)
                    }
                }
                .padding(.horizontal, Espace.l)
                .padding(.vertical, Espace.s)
                .frame(minHeight: 56)
                Text(statOFB)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.horizontal, Espace.l)
                    .padding(.bottom, Espace.m)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.m)
    }

    /// P27 B, bloc « Où il vit » : aucune donnée d'habitat, donc les relevés OFB réels de la zone (nombre de pêches et année).
    @ViewBuilder
    private var releves: some View {
        let r = emplacement.rarete
        VStack(alignment: .leading, spacing: 0) {
            enteteDeGroupe("Relevés OFB dans ta zone", haut: 22)
            VStack(spacing: 0) {
                if r.niveau == .legendaire {
                    ligneReleve("eye.slash", "Jamais relevée", "dans ta zone")
                } else {
                    ligneReleve("fish", "Pêches", "\(r.nPeches) sur \(r.nTotal)")
                    Divider().overlay(Palette.filet).padding(.leading, 52)
                    if let part = partOFB { ligneReleve("chart.pie", "Part des pêches", "\(part) %") }
                }
                if let annee = r.anneeDernierReleve {
                    Divider().overlay(Palette.filet).padding(.leading, 52)
                    ligneReleve("calendar", "Dernier relevé", "\(annee)")
                }
            }
            .tuileFishMe(rayon: Rayon.m)
            .padding(.top, Espace.s)
        }
    }

    private func ligneReleve(_ icone: String, _ titre: String, _ valeur: String) -> some View {
        HStack(spacing: Espace.m) {
            Image(systemName: icone)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(titre).font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: 0)
            Text(valeur).font(Police.taille(17, .bold)).monospacedDigit().foregroundStyle(Palette.encreDouce)
        }
        .padding(.horizontal, Espace.l)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }

    private var motDuPalier: String {
        style.mot.prefix(1).uppercased() + style.mot.dropFirst()
    }

    /// Part des pêches OFB de la zone. `nil` sans relevé.
    private var partOFB: Int? {
        let r = emplacement.rarete
        guard r.nTotal > 0, r.niveau != .legendaire else { return nil }
        return Int((Double(r.nPeches) / Double(r.nTotal) * 100).rounded())
    }

    /// « 34 % · 10 sur 29 » sur une ligne. `nil` sans relevé.
    private var ligneChiffres: String? {
        guard let part = partOFB else { return nil }
        return "\(part) % · \(emplacement.rarete.nPeches) sur \(emplacement.rarete.nTotal)"
    }

    /// La légende « OFB · année » ; le nombre de pêches est dans la ligne au-dessus.
    private var statOFB: String {
        let r = emplacement.rarete
        let annee = r.anneeDernierReleve.map { " · \($0)" } ?? ""
        if r.niveau == .legendaire { return "Jamais relevée · OFB\(annee)" }
        return "OFB\(annee)"
    }

    /// P28 B : la carte déclarée à gauche (130 pt), la phrase à droite.
    private func carteDeclaree(_ infos: InfosCarte) -> some View {
        HStack(spacing: Espace.l) {
            CarteRectoView(infos: infos)
                .frame(width: 130)
            Text("Tu l'as déclaré au premier lancement. Pas de photo, donc pas de taille ni de numéro.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe(rayon: Rayon.m)
    }

    /// Une ligne « avec image » (P28 B) : le poisson en vignette, son nom, son palier et sa part des pêches OFB (avec le nombre de pêches et l'année).
    private func ligneAEssayer(_ e: Emplacement) -> some View {
        let s = StyleRarete(e.rarete.niveau)
        let r = e.rarete
        let part = r.nTotal > 0 ? Int((Double(r.nPeches) / Double(r.nTotal) * 100).rounded()) : 0
        let annee = r.anneeDernierReleve.map { " · \($0)" } ?? ""
        return HStack(spacing: Espace.m) {
            Image(e.espece.image)
                .resizable().scaledToFit()
                .frame(maxWidth: 56, maxHeight: 32)
                .frame(width: 56, height: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.espece.nom)
                    .font(Police.taille(17, .heavy))
                    .foregroundStyle(Palette.encre)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    MarqueRarete(style: s, taille: 14)
                    Text("\(s.mot.prefix(1).uppercased() + s.mot.dropFirst()) · \(r.nPeches) sur \(r.nTotal)\(annee)")
                        .font(Police.taille(13, .heavy))
                        .foregroundStyle(s.couleur)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("\(part) %")
                .font(Police.taille(17, .bold))
                .monospacedDigit()
                .foregroundStyle(Palette.encreDouce)
        }
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.s)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }
}

/// Pescedex sans aucune carte (ni vraie, ni déclarée) : un état vide court au lieu du silence.
enum PescedexVide {
    static let texte = "Ta première prise ouvrira ton Pescedex"
    static func estVide(_ emplacements: [Emplacement]) -> Bool {
        !emplacements.contains { $0.carte != nil }
    }
}
