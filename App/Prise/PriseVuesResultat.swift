import Core
import Foundation
import SwiftUI
import UIKit

/// P21 : la taille, sur la photo. Une fourchette (« 52 à 56 cm ») quand elle est mesurée en réalité augmentée,
/// avec le poids estimé aux deux bornes ; la toise et le curseur restent en secours. Le pêcheur valide toujours.
struct PriseTailleView: View {
    @Bindable var modele: PriseModele
    @State private var cameraToise = false
    @State private var mesureAR = false
    @State private var saisieOuverte = false

    private var curseurVisible: Bool { saisieOuverte || !MesureAR.disponible || modele.toiseImage != nil }

    var body: some View {
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(spacing: Espace.m) {
                if let image = modele.toiseImage { photoToise(image) }
                chiffres
                if curseurVisible { curseur }
                if modele.toiseIntrouvable {
                    Text("Je n'ai pas lu la toise : règle le curseur.").font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
            principal
            HStack {
                if PriseCamera.disponible {
                    Button("Toise") { cameraToise = true }
                }
                Spacer()
                if MesureAR.disponible && !saisieOuverte && modele.toiseImage == nil {
                    Button("Saisir à la main") { saisieOuverte = true }
                } else if MesureAR.disponible && modele.curseurBouge {
                    Button("Mesurer en réalité augmentée") { mesureAR = true }
                }
            }
            .font(Police.corps).foregroundStyle(Palette.marine)
            .frame(minHeight: Gabarit.zoneTactile)
        }
        .fullScreenCover(isPresented: $mesureAR) {
            // Garde-fou : jusqu'à 1,2 × le p95 des prises connues de l'espèce (table poids-longueur), sinon 3 à 200 cm.
            // À brancher : le poisson de l'espèce posé sur la scène AR, comme sur la maquette P21 (MesureARView dessine la mesure seulement).
            MesureARView(plausible: MesureARCalcul.plageEspece(p95Cm: modele.especeConfirmee.flatMap {
                                modele.services.especes.longueurPlausibleMax(espece: $0.espece) }),
                         surValider: { mesureAR = false; modele.mesureARValidee($0) }, surAnnuler: { mesureAR = false })
        }
        .fullScreenCover(isPresented: $cameraToise) {
            PriseCamera(onImage: { cameraToise = false; modele.photoToise($0) }, onCancel: { cameraToise = false })
                .ignoresSafeArea()
        }
    }

    /// Le gros chiffre : la fourchette en réalité augmentée, sinon la longueur réglée ; le poids est toujours « estimé ».
    private var chiffres: some View {
        HStack(alignment: .firstTextBaseline) {
            if let plage = modele.plageAR {
                (Text("\(plage.basCm) à \(plage.hautCm)").font(Police.chiffre) + Text(" cm").font(Police.titre))
                    .foregroundStyle(Palette.encre)
            } else if modele.curseurBouge {
                (Text("\(Int(modele.longueurCm.rounded()))").font(Police.chiffre) + Text(" cm").font(Police.titre))
                    .foregroundStyle(Palette.encre)
            } else {
                Text("Mesure ton poisson").font(Police.titre).foregroundStyle(Palette.encre)
            }
            Spacer(minLength: Espace.s)
            if let poids = modele.textePoidsAR {
                Text(poids).font(Police.detail).foregroundStyle(Palette.encre).multilineTextAlignment(.trailing)
            } else if modele.curseurBouge, let entree = modele.especeConfirmee,
                      let poids = modele.services.especes.poidsEstime(espece: entree.espece, longueurCm: modele.longueurCm.rounded()) {
                Text(PriseLogique.texteDuPoids(poids)).font(Police.detail).foregroundStyle(Palette.encre)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var curseur: some View {
        VStack(spacing: Espace.xs) {
            HStack(spacing: Espace.xs) {
                Button { modele.ajusterCurseur(-1) } label: {
                    Image(systemName: "minus.circle.fill").font(.title2).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Un centimètre de moins")
                Slider(value: Binding(get: { modele.longueurCm }, set: { modele.deplacerCurseur($0) }), in: PriseLogique.plageTaille, step: 1)
                    .accessibilityLabel("Taille en centimètres")
                Button { modele.ajusterCurseur(1) } label: {
                    Image(systemName: "plus.circle.fill").font(.title2).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Un centimètre de plus")
            }
            .foregroundStyle(Palette.encre)
            HStack {
                Text("\(Int(PriseLogique.plageTaille.lowerBound)) cm")
                Spacer()
                Text("\(Int(PriseLogique.plageTaille.upperBound)) cm")
            }
            .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
    }

    /// Un seul bouton principal : « Valider » dès qu'il y a une taille, sinon la mesure en réalité augmentée quand elle existe.
    @ViewBuilder private var principal: some View {
        if modele.curseurBouge {
            Button("Valider") { modele.confirmerLaTaille() }.buttonStyle(.principal)
        } else if MesureAR.disponible {
            Button("Mesurer en réalité augmentée") { mesureAR = true }.buttonStyle(.principal)
        } else {
            Button("Valider") { modele.confirmerLaTaille() }.buttonStyle(.principal)
                .disabled(true).opacity(0.5)
        }
    }

    /// La photo de la toise ; quand les chiffres sont lus, un toucher sur le bout de la queue règle le curseur.
    @ViewBuilder private func photoToise(_ image: UIImage) -> some View {
        VStack(spacing: Espace.s) {
            GeometryReader { geo in
                let echelle = min(geo.size.width / image.size.width, geo.size.height / image.size.height)
                let affiche = CGSize(width: image.size.width * echelle, height: image.size.height * echelle)
                let decalage = CGPoint(x: (geo.size.width - affiche.width) / 2, y: (geo.size.height - affiche.height) / 2)
                Image(uiImage: image).resizable().scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { lieu in
                        let pixels = CGPoint(x: (lieu.x - decalage.x) / echelle * image.scale,
                                             y: (lieu.y - decalage.y) / echelle * image.scale)
                        modele.boutDeLaQueue(pixels)
                    }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.m))
            if modele.toise != nil {
                Text("Touche le bout de la queue.").font(Police.legende).foregroundStyle(Palette.encre)
            }
        }
    }
}

/// P22 : ce que le pêcheur a fait de sa prise. « Ne pas dire » est permis : la prise entre quand même au Pescedex.
struct PriseDetailsView: View {
    @Bindable var modele: PriseModele

    var body: some View {
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }) {
            VStack(alignment: .leading, spacing: Espace.m) {
                Text("Ta prise").font(Police.titre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: Espace.s) {
                    tuile("Relâchée", symbole: "water.waves", pour: .relachee)
                    tuile("Gardée", symbole: "basket", pour: .gardee)
                    tuile("Ne pas dire", symbole: "ellipsis", pour: .nonDit)
                }
                // À brancher : « Appât ou leurre » et « Technique » (maquette P22), puis la météo et le niveau de la rivière
                // « ajoutés tout seuls ». `Prise` (Core) n'a pas encore de champ pour eux : rien n'est inventé ici.
            }
            Button("Continuer") { modele.continuerDetails() }.buttonStyle(.principal)
        }
    }

    private func tuile(_ titre: String, symbole: String, pour devenir: DevenirPrise) -> some View {
        let choisi = modele.devenir == devenir
        return Button { modele.devenir = devenir } label: {
            VStack(spacing: Espace.s) {
                Image(systemName: symbole).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(titre).font(Police.detail).multilineTextAlignment(.center)
            }
            .foregroundStyle(choisi ? Palette.surMarine : Palette.encre)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(choisi ? Palette.marine : Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisi ? .isSelected : [])
    }
}

/// P23 : le verdict en haut (taille comparée à la taille minimale, sur toute la fourchette), « Règle et sources » d'un toucher,
/// puis la carte (recto : le poisson ; verso : la vraie photo) et un seul bouton, « Ajouter au Pescedex ».
/// Le verdict vient de la table sourcée de `Core` ; l'IA n'y décide rien.
struct PriseResultatView: View {
    @Bindable var modele: PriseModele
    @State private var sourcesOuvertes = false
    @State private var verso = false

    var body: some View {
        let controle = modele.controle
        ScrollView {
            VStack(spacing: Espace.l) {
                bandeauVerdict(controle)
                carte
                Button { withAnimation { verso.toggle() } } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Palette.marine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(verso ? "Voir le recto de la carte" : "Voir la photo au verso")
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            HStack {
                PriseBoutonRond(symbole: "chevron.left", etiquette: "Retour", action: { modele.retour() })
                Spacer()
                PriseBoutonRond(symbole: "xmark", etiquette: "Fermer", action: { modele.terminer(nil) })
            }
            .padding(.horizontal, Espace.bord).padding(.vertical, Espace.xs)
            .background(Palette.fond)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: Espace.xs) {
                if modele.exemple {
                    Text("Carte d'exemple : elle ne compte pas au Pescedex")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
                Button(modele.exemple ? "Ranger (carte d'exemple)" : "Ajouter au Pescedex") { modele.ranger() }
                    .buttonStyle(.principal)
            }
            .padding(.horizontal, Espace.bord).padding(.vertical, Espace.s)
            .background(Palette.fond)
        }
    }

    // MARK: Verdict

    private var tailleTexte: String {
        if let plage = modele.plageAR { return plage.texte }
        return "\(Int(modele.longueurCm.rounded())) cm"
    }

    /// Lignes « à vérifier » et règles d'interdiction : visibles sous le titre, pas dans « Règle et sources » replié.
    private func bandeauVerdict(_ controle: ResultatControle?) -> some View {
        let lignesVisibles = controle.map { PriseLogique.lignesVisibles([$0]) } ?? []
        let verdict = modele.verdictTaille
        let (symbole, titre, couleur) = presentation(verdict, controle)
        return VStack(spacing: 0) {
            HStack(spacing: Espace.m) {
                Image(systemName: symbole).font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(couleur).accessibilityHidden(true)
                Text(titre).font(Police.sousTitre).foregroundStyle(couleur)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(tailleTexte).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
            .padding(Espace.m)
            if !lignesVisibles.isEmpty {
                VStack(spacing: Espace.s) {
                    ForEach(Array(lignesVisibles.enumerated()), id: \.offset) { _, ligne in PriseLigneView(ligne: ligne) }
                }
                .padding([.horizontal, .bottom], Espace.m)
            }
            Divider().overlay(Palette.filet)
            Button { withAnimation { sourcesOuvertes.toggle() } } label: {
                HStack(spacing: Espace.m) {
                    Image(systemName: "doc.text").foregroundStyle(Palette.marine).accessibilityHidden(true)
                    Text("Règle et sources").font(Police.corps).foregroundStyle(Palette.encre)
                    Spacer()
                    Image(systemName: sourcesOuvertes ? "chevron.up" : "chevron.right")
                        .foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
                }
                .padding(Espace.m).frame(minHeight: Gabarit.zoneTactile)
            }
            .buttonStyle(.plain)
            if sourcesOuvertes, let controle {
                VStack(spacing: Espace.s) {
                    if verdict == .aVerifier || PriseLogique.tropPresDeLaMaille(controle) {
                        Text("Trop près de la taille minimale, mesure sur une toise")
                            .font(Police.corps).foregroundStyle(Palette.encre)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if modele.contexte.lieu.categorie.valeur == .inconnue { categorieInconnue }
                    ForEach(Array(controle.lignes.filter { !lignesVisibles.contains($0) }.enumerated()), id: \.offset) { _, ligne in PriseLigneView(ligne: ligne) }
                    Text(PriseLogique.avertissement)
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding([.horizontal, .bottom], Espace.m)
            }
        }
        .tuileFishMe(rayon: Rayon.l)
    }

    /// Icône, titre et couleur du verdict. Orange seulement quand c'est une alerte (sous la taille, règle non respectée).
    private func presentation(_ verdict: PriseLogique.VerdictAffiche?, _ controle: ResultatControle?) -> (String, String, Color) {
        let consigne = controle?.consigne.texte ?? PriseLogique.consigneAvantConfirmation
        switch verdict {
        case .tailleLegale: return ("checkmark.circle.fill", "Taille légale", Palette.ouvert)
        case .tailleRespecteeAVerifier: return ("info.circle.fill", "Taille respectée · vérifie le parcours", Palette.encreDouce)
        case .sousLaMaille: return ("xmark.octagon.fill", "Sous la taille minimale", Palette.alerte)
        case .regleNonRespectee: return ("xmark.octagon.fill", "Relâche-la", Palette.alerte)
        case .aVerifier, .sansRegleDeTaille: return ("questionmark.circle.fill", consigne, Palette.marine)
        case nil: return ("questionmark.circle.fill", consigne, Palette.marine)
        }
    }

    /// Ligne neutre (icône discrète, pas d'orange) quand la catégorie du cours d'eau n'est pas connue.
    private var categorieInconnue: some View {
        HStack(alignment: .top, spacing: Espace.m) {
            Image(systemName: "info.circle").foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
            Text(PriseLogique.categorieInconnue).font(Police.corps).foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Espace.m).frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
        .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    // MARK: Carte (recto et verso)

    private var carte: some View {
        GeometryReader { geo in
            let coin = geo.size.width * Gabarit.coinCarte
            ZStack {
                if verso { versoCarte } else { rectoCarte }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: coin, style: .continuous))
            .shadow(color: Palette.encre.opacity(0.15), radius: 12, y: 6)
        }
        .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
        .frame(maxWidth: 360)
    }

    /// Recto : le poisson en image et son nom.
    /// À brancher : la rareté et le nombre de pêches OFB (« 10 pêches sur 29 dans le 94 · OFB »), le badge Trophée et le centile de taille,
    /// le numéro de carte : ces données viennent du Pescedex (L4), pas de l'écran Prise.
    private var rectoCarte: some View {
        ZStack {
            Palette.nuit
            VStack(spacing: Espace.m) {
                Spacer(minLength: 0)
                if let entree = modele.especeConfirmee {
                    if UIImage(named: entree.image) != nil {
                        Image(entree.image).resizable().scaledToFit().padding(.horizontal, Espace.l)
                            .accessibilityHidden(true)
                    } else {
                        Image(systemName: PriseFamille.de(entree.espece.id).symbole)
                            .font(.system(size: 72, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.7))
                            .accessibilityHidden(true)
                    }
                }
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(modele.especeConfirmee?.nom ?? "Ta prise").font(Police.grandTitre).foregroundStyle(.white)
                        .minimumScaleFactor(0.6).lineLimit(1)
                    if let latin = modele.especeConfirmee?.nomLatin {
                        Text(latin).font(Police.detail).italic().foregroundStyle(.white.opacity(0.7))
                    }
                    Text(tailleTexte).font(Police.chiffreMoyen).foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Espace.l)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Verso : la vraie photo du pêcheur, puis taille (avec sa méthode), poids estimé, ce qu'il en a fait, la date.
    /// À brancher : appât ou leurre, température de l'eau, niveau de la rivière (conditions de la sortie) et le prénom du pêcheur.
    private var versoCarte: some View {
        VStack(spacing: 0) {
            Color.clear
                .overlay {
                    if let image = modele.imagePhoto {
                        Image(uiImage: image).resizable().scaledToFill().accessibilityLabel("Ta photo")
                    } else {
                        Palette.tuile
                    }
                }
                .clipped()
                .padding(Espace.s)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)], spacing: Espace.m) {
                chiffre(tailleTexte, legende: methodeTexte)
                if let poids = poidsTexte { chiffre(poids, legende: "estimé") }
                if let devenir = devenirTexte { chiffre(devenir, legende: "la prise") }
                chiffre(modele.contexte.date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "fr_FR"))), legende: modele.contexte.lieuFlou ?? "")
            }
            .padding(Espace.l)
        }
        .background(Palette.surface)
    }

    private func chiffre(_ valeur: String, legende: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(valeur).font(Police.sousTitre).foregroundStyle(Palette.encre).minimumScaleFactor(0.7).lineLimit(1)
            if !legende.isEmpty { Text(legende).font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1) }
        }
    }

    private var methodeTexte: String {
        switch modele.methode {
        case .estimee: return "réalité augmentée"
        case .toise: return "lue sur ta toise"
        case .saisie: return "saisie"
        }
    }

    /// « ≈ 1,9 à 2,4 kg » (deux bornes quand la taille est une fourchette), marqué « estimé » dessous.
    private var poidsTexte: String? {
        if let texte = modele.textePoidsAR { return texte.replacingOccurrences(of: ", estimé", with: "") }
        guard let poids = modele.poids else { return nil }
        return "≈ \(PriseLogique.kilos(poids.kilos)) kg"
    }

    private var devenirTexte: String? {
        switch modele.devenir {
        case .relachee: return "Relâchée"
        case .gardee: return "Gardée"
        case .nonDit: return nil
        }
    }
}

/// Une ligne de la liste de contrôle : la phrase, puis ses sources et sa date de lecture d'un toucher.
struct PriseLigneView: View {
    var ligne: LigneControle
    /// Vrai si les sources portent des citations différentes : chacune montre la sienne, sans la citation unique en plus.
    private var sourcesAvecCitation: Bool { Set(ligne.sources.compactMap(\.citation)).count > 1 }
    @State private var ouverte = false

    var body: some View {
        Button { withAnimation { ouverte.toggle() } } label: {
            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .top, spacing: Espace.m) {
                    Image(systemName: symbole).foregroundStyle(couleur).accessibilityHidden(true)
                    Text(ligne.phrase).font(Police.corps).foregroundStyle(Palette.encre)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if ouverte {
                    ForEach(Array(ligne.sources.enumerated()), id: \.offset) { _, s in
                        VStack(alignment: .leading, spacing: 2) {
                            if let url = s.url.flatMap({ URL(string: $0) }) {
                                Link(destination: url) {
                                    Label(s.titre, systemImage: "arrow.up.right.square")
                                        .font(Police.legende).multilineTextAlignment(.leading)
                                }
                            } else {
                                Text(s.titre).font(Police.legende).foregroundStyle(Palette.encreDouce)
                            }
                            if sourcesAvecCitation, let citation = s.citation {
                                Text(citation).font(Police.legende).foregroundStyle(Palette.encreDouce)
                            }
                        }
                    }
                    if !sourcesAvecCitation, let citation = ligne.citation { Text(citation).font(Police.legende).foregroundStyle(Palette.encreDouce) }
                    if let date = ligne.dateLecture {
                        Text("Lue le \(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR"))))")
                            .font(Police.legende).foregroundStyle(Palette.encreDouce)
                    }
                }
            }
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var style: PriseLogique.StyleLigne { PriseLogique.styleDeLigne(type: ligne.type, etat: ligne.etat) }

    private var symbole: String {
        switch style {
        case .coche: return "checkmark.circle.fill"
        case .calendrier: return "calendar"
        case .info: return "info.circle.fill"
        case .aVerifier: return "questionmark.circle.fill"
        case .alerte: return "xmark.octagon.fill"
        }
    }

    private var couleur: Color {
        switch style {
        case .coche: return Palette.ouvert
        case .calendrier, .info: return Palette.encreDouce
        case .aVerifier: return Palette.marine
        case .alerte: return Palette.alerte
        }
    }
}
