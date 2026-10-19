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
        // P21 A : photo floutée, poisson posé à plat et ligne de mesure ; en haut « Retour » et « Remesurer » ; feuille basse :
        // chiffre de 40, poids estimé à droite, la méthode (10 pt dessous), « Valider » (20 pt dessous), puis « Toise » et « Saisir à la main » (4 pt dessous).
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, floute: true, arriere: scene,
                     actionHaute: MesureAR.disponible ? (symbole: "arrow.triangle.2.circlepath", etiquette: "Remesurer", action: { mesureAR = true }) : nil) {
            VStack(spacing: 0) {
                chiffres
                if let image = modele.toiseImage { photoToise(image).padding(.top, Espace.l) }
                if curseurVisible { curseur.padding(.top, Espace.l) }
                if modele.toiseIntrouvable {
                    Text("Je n'ai pas lu la toise : règle le curseur.").font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .padding(.top, Espace.s)
                }
                principal.padding(.top, 20)
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
                .padding(.top, Espace.xs)
            }
        }
        .fullScreenCover(isPresented: $mesureAR) {
            // Garde-fou : jusqu'à 1,2 × le p95 des prises connues de l'espèce (table poids-longueur), sinon 3 à 200 cm.
            MesureARView(plausible: MesureARCalcul.plageEspece(p95Cm: modele.especeConfirmee.flatMap {
                                modele.services.especes.longueurPlausibleMax(espece: $0.espece) }),
                         surValider: { mesureAR = false; modele.mesureARValidee($0) }, surAnnuler: { mesureAR = false })
        }
        .fullScreenCover(isPresented: $cameraToise) {
            PriseCamera(onImage: { cameraToise = false; modele.photoToise($0) }, onCancel: { cameraToise = false })
                .ignoresSafeArea()
        }
    }

    /// La scène de la maquette P21 : le poisson de l'espèce posé à plat (350 de large, à 300 du haut), et, une fois la mesure faite,
    /// la ligne blanche de 3 points tendue sur sa longueur avec ses deux poignées marine de 26 points.
    private var scene: AnyView {
        AnyView(
            ZStack(alignment: .topLeading) {
                Color.clear
                if let entree = modele.especeConfirmee, UIImage(named: entree.image) != nil {
                    Image(entree.image).resizable().scaledToFit()
                        .frame(width: 350)
                        .shadow(color: .black.opacity(0.45), radius: 7, y: 8)
                        .padding(.leading, 20).padding(.top, 300)
                }
                if modele.plageAR != nil {
                    Capsule().fill(.white).frame(width: 338, height: 3)
                        .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.35), lineWidth: 0.5))
                        .rotationEffect(.degrees(-0.4), anchor: .leading)
                        .padding(.leading, 27).padding(.top, 353)
                    poignee.padding(.leading, 14).padding(.top, 341)
                    poignee.padding(.leading, 352).padding(.top, 339)
                }
            }
            .accessibilityHidden(true)
        )
    }

    private var poignee: some View {
        Circle().fill(Palette.marine).frame(width: 26, height: 26)
            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
    }

    /// Le gros chiffre : la fourchette en réalité augmentée, sinon la longueur réglée ; le poids est toujours « estimé ».
    /// Mise en page de la maquette P21 : « 52 à 56 cm » (40 points) à gauche, « ≈ 1,6 à 2,0 kg / estimé » à droite, alignés en bas, la méthode dessous.
    private var chiffres: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                if let plage = modele.plageAR {
                    (Text("\(plage.basCm) à \(plage.hautCm)").font(Police.taille(40, .black).monospacedDigit()) + Text(" cm").font(Police.taille(18, .heavy)))
                        .foregroundStyle(Palette.encre).minimumScaleFactor(0.6).lineLimit(1)
                } else if modele.curseurBouge {
                    (Text("\(Int(modele.longueurCm.rounded()))").font(Police.taille(40, .black).monospacedDigit()) + Text(" cm").font(Police.taille(18, .heavy)))
                        .foregroundStyle(Palette.encre).lineLimit(1)
                } else {
                    Text("Mesure ton poisson").font(Police.titre).foregroundStyle(Palette.encre)
                }
                Spacer(minLength: Espace.s)
                if let poids = poidsAffiche {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(poids).font(Police.sousTitre).foregroundStyle(Palette.encre).lineLimit(1)
                        Text("estimé").font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                }
            }
            if let methode = methodeLigne {
                HStack(spacing: 6) {
                    Image(systemName: methode.symbole).font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(methode.texte)
                }
                .font(Police.detail).foregroundStyle(Palette.encreDouce)
                .padding(.top, 10)
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
/// Maquette P22 A : feuille haute (116 du haut), « Ta prise », trois tuiles de 84, « Appât ou leurre » (6 tuiles de 76), « Technique » (pastilles), « Continuer » en bas.
struct PriseDetailsView: View {
    @Bindable var modele: PriseModele
    // À brancher : `Prise` (Core) n'a pas encore de champ appât ni technique, ces deux choix ne sont donc pas enregistrés.
    @State private var appat: String?
    @State private var technique: String?

    private static let appats: [(nom: String, symbole: String)] = [
        ("Souple", "fish.fill"), ("Cuiller", "drop"), ("Nageur", "fish"),
        ("Poisson vif", "fish"), ("Ver", "scribble.variable"), ("Maïs", "leaf"),
    ]
    private static let techniques = ["Lancer", "Posé", "Mouche", "Verticale"]

    var body: some View {
        PriseFeuille(photo: modele.imagePhoto, retour: { modele.retour() }, haut: 116, voile: 0.4) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Ta prise").font(Police.titre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 10) {
                    tuile("Relâchée", symbole: "water.waves", pour: .relachee)
                    tuile("Gardée", symbole: "basket", pour: .gardee)
                    tuile("Ne pas dire", symbole: "ellipsis", pour: .nonDit)
                }
                .padding(.top, 14)
                Text("Appât ou leurre").font(Police.sousTitre).foregroundStyle(Palette.encre)
                    .padding(.top, 20).padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.s), count: 3), spacing: Espace.s) {
                    ForEach(Self.appats, id: \.nom) { a in appatTuile(a.nom, symbole: a.symbole) }
                }
                Text("Technique").font(Police.sousTitre).foregroundStyle(Palette.encre)
                    .padding(.top, 20).padding(.bottom, 10)
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: Espace.s) {
                    ForEach(Self.techniques, id: \.self) { t in puce(t) }
                }
                // À brancher : la ligne « 14° · Marne 1,42 m, ajoutés tout seuls » (maquette P22) : `PriseContexte` n'a ni température ni
                // hauteur d'eau (`Conditions` de Core n'a pas de température) ; sans ces données, rien n'est affiché (aucun chiffre inventé).
                Spacer(minLength: 20)
                Button("Continuer") { modele.continuerDetails() }.buttonStyle(.principal)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func tuile(_ titre: String, symbole: String, pour devenir: DevenirPrise) -> some View {
        let choisi = modele.devenir == devenir
        return Button { modele.devenir = devenir } label: {
            VStack(spacing: 6) {
                Image(systemName: symbole).font(.system(size: 28, weight: .bold, design: .rounded))
                Text(titre).font(Police.sousTitre).multilineTextAlignment(.center).lineSpacing(0)
            }
            .foregroundStyle(choisi ? Palette.surMarine : Palette.marineFonce)
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84)
            .background(choisi ? Palette.marine : Palette.tuile, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(titre)
        .accessibilityAddTraits(choisi ? .isSelected : [])
    }

    @ViewBuilder private func appatTuile(_ nom: String, symbole: String) -> some View {
        let choisi = appat == nom
        Button { appat = choisi ? nil : nom } label: {
            VStack(spacing: 6) {
                if nom == "Poisson vif", let vif = modele.catalogue.first(where: { $0.espece.id == "gardon" }), UIImage(named: vif.image) != nil {
                    Image(vif.image).resizable().scaledToFit().frame(width: 38, height: 26)
                } else {
                    Image(systemName: symbole).font(.system(size: 26, weight: .bold, design: .rounded)).frame(height: 34)
                }
                Text(nom).font(Police.legende)
            }
            .foregroundStyle(choisi ? Palette.surMarine : Palette.marineFonce)
            .frame(maxWidth: .infinity, minHeight: 76, maxHeight: 76)
            .background(choisi ? Palette.marine : Palette.tuile, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nom)
        .accessibilityAddTraits(choisi ? .isSelected : [])
    }

    private func puce(_ nom: String) -> some View {
        let choisie = technique == nom
        return Button { technique = choisie ? nil : nom } label: {
            Text(nom).font(Police.detail)
                .foregroundStyle(choisie ? Color.white : Palette.encre)
                .padding(.horizontal, 14).frame(height: 34)
                .background(choisie ? Palette.marine : Palette.surface, in: Capsule())
                .overlay { if !choisie { Capsule().strokeBorder(Palette.filet, lineWidth: 1) } }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }
}
