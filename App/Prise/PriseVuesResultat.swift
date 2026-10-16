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
            HStack(spacing: 0) {
                Group {
                    if PriseCamera.disponible {
                        Button("Toise") { cameraToise = true }
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity)
                Group {
                    if MesureAR.disponible && !saisieOuverte && modele.toiseImage == nil {
                        Button("Saisir à la main") { saisieOuverte = true }
                    } else if MesureAR.disponible && modele.curseurBouge {
                        Button("Mesurer en réalité augmentée") { mesureAR = true }
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity)
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
    /// Mise en page de la maquette P21 : « 52 à 56 cm » à gauche, « ≈ 1,6 à 2,0 kg / estimé » à droite, la méthode dessous.
    private var chiffres: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            HStack(alignment: .top) {
                if let plage = modele.plageAR {
                    (Text("\(plage.basCm) à \(plage.hautCm)").font(Police.taille(56, .heavy).monospacedDigit()) + Text(" cm").font(Police.titre))
                        .foregroundStyle(Palette.encre).minimumScaleFactor(0.6).lineLimit(1)
                } else if modele.curseurBouge {
                    (Text("\(Int(modele.longueurCm.rounded()))").font(Police.taille(56, .heavy).monospacedDigit()) + Text(" cm").font(Police.titre))
                        .foregroundStyle(Palette.encre).lineLimit(1)
                } else {
                    Text("Mesure ton poisson").font(Police.titre).foregroundStyle(Palette.encre)
                }
                Spacer(minLength: Espace.s)
                if let poids = poidsAffiche {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(poids).font(Police.sousTitre).foregroundStyle(Palette.encre)
                        Text("estimé").font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                }
            }
            if let methode = methodeLigne {
                Label(methode.texte, systemImage: methode.symbole)
                    .font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// « ≈ 1,6 à 2,0 kg » (sans le mot « estimé », écrit dessous).
    private var poidsAffiche: String? {
        if let texte = modele.textePoidsAR { return texte.replacingOccurrences(of: ", estimé", with: "") }
        if modele.curseurBouge, let entree = modele.especeConfirmee,
           let poids = modele.services.especes.poidsEstime(espece: entree.espece, longueurCm: modele.longueurCm.rounded()) {
            return "≈ \(PriseLogique.kilos(poids.kilos)) kg"
        }
        return nil
    }

    private var methodeLigne: (texte: String, symbole: String)? {
        if modele.plageAR != nil { return ("Mesurée en réalité augmentée", "cube") }
        guard modele.curseurBouge else { return nil }
        if modele.methode == .toise { return ("Lue sur ta toise", "ruler") }
        return ("Saisie à la main", "hand.point.up.left")
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
            Button("Règle le curseur") {}.buttonStyle(.principal)
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
                HStack(spacing: 10) {
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
            VStack(spacing: 10) {
                Image(systemName: symbole).font(.system(size: 24, weight: .bold, design: .rounded))
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
                HStack(spacing: Espace.m) {
                    HStack(spacing: 8) {
                        Circle().fill(verso ? Palette.filet : Palette.marine).frame(width: 8, height: 8)
                        Circle().fill(verso ? Palette.marine : Palette.filet).frame(width: 8, height: 8)
                    }
                    .accessibilityHidden(true)
                    Button { withAnimation { verso.toggle() } } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundStyle(Palette.marine)
                            .frame(width: 44, height: 44)
                            .background(Palette.surface, in: Circle())
                            .shadow(color: Palette.encre.opacity(0.12), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(verso ? "Voir le recto de la carte" : "Voir la photo au verso")
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            HStack {
                BoutonRond(role: .retour, rendu: .simple, action: { modele.retour() })
                Spacer()
                BoutonRond(role: .fermer, rendu: .simple, action: { modele.terminer(nil) })
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
                Button("Ajouter au Pescedex") { modele.ranger() }
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
                Image(systemName: symbole).font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(couleur).accessibilityHidden(true)
                Text(titre).font(Police.titre).foregroundStyle(couleur)
                    .frame(maxWidth: .infinity, alignment: .leading).minimumScaleFactor(0.7)
                // À brancher : « 68 / 60 cm mini » (la taille minimale n'est pas un champ du résultat de Core, seulement dans la phrase de la règle).
                Text(tailleTexte).font(Police.corps).foregroundStyle(Palette.encreDouce).lineLimit(1)
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

    /// La carte de l'écran Pescedex (`CarteRectoView`, `CarteVersoView`) construite avec ce que la prise sait déjà.
    /// Rareté : table de Core pour le département de la prise. Rang dans la zone, consigne et lune : absents ici
    /// (ni le recto ni le verso ne les montrent).
    private var infosCarte: InfosCarte? {
        guard let entree = modele.especeConfirmee else { return nil }
        let prise = Prise(espece: entree.espece, longueurCm: modele.longueurCm.rounded(), mesure: modele.methode,
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
            Group {
                if verso {
                    CarteVersoView(infos: infos, photo: modele.photo)
                } else {
                    CarteRectoView(infos: infos)
                }
            }
            .frame(maxWidth: 360)
        } else {
            RoundedRectangle(cornerRadius: Rayon.l, style: .continuous)
                .fill(Palette.tuile)
                .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
                .frame(maxWidth: 360)
                .accessibilityHidden(true)
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
