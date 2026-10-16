import Core
import Foundation
import SwiftUI
import UIKit

/// Taille : curseur de longueur, pré-réglé par la toise quand Vision a lu les chiffres. Le pêcheur confirme toujours.
struct PriseTailleView: View {
    @Bindable var modele: PriseModele
    @State private var cameraToise = false
    @State private var mesureAR = false

    var body: some View {
        VStack(spacing: 16) {
            PriseEntete(titre: "Quelle taille ?", consigne: PriseLogique.consigneAvantConfirmation)
            ScrollView {
                VStack(spacing: 16) {
                    if let image = modele.toiseImage { photoToise(image) }
                    VStack(spacing: 8) {
                        Text("\(Int(modele.longueurCm.rounded())) cm").font(PriseJetons.chiffre()).foregroundStyle(PriseJetons.encre)
                        Slider(value: $modele.longueurCm, in: PriseLogique.plageTaille, step: 1)
                            .accessibilityLabel("Taille en centimètres")
                        HStack {
                            Text("\(Int(PriseLogique.plageTaille.lowerBound)) cm")
                            Spacer()
                            Text("\(Int(PriseLogique.plageTaille.upperBound)) cm")
                        }
                        .font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
                    }
                    .padding(16)
                    .background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
                    if let plage = modele.plageAR {
                        VStack(spacing: 4) {
                            Text(plage.texte).font(PriseJetons.titre()).foregroundStyle(PriseJetons.encre)
                            if let poids = modele.textePoidsAR { Text(poids) }
                            Text("Mesuré en réalité augmentée").foregroundStyle(PriseJetons.discret)
                        }
                        .font(PriseJetons.legende()).foregroundStyle(PriseJetons.encre)
                    }
                    if MesureAR.disponible {
                        Button("Mesurer en réalité augmentée") { mesureAR = true }.buttonStyle(PriseBoutonSecondaire())
                    }
                    if PriseCamera.disponible {
                        Button("Photo de mon poisson sur la toise") { cameraToise = true }.buttonStyle(PriseBoutonSecondaire())
                    }
                    if modele.toiseIntrouvable {
                        Text("Je n'ai pas lu la toise : règle le curseur.").font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
                    }
                }
            }
            .scrollIndicators(.hidden)
            Button("Confirmer la taille") { modele.confirmerLaTaille() }.buttonStyle(PriseBoutonPrincipal())
        }
        .padding(20)
        .fullScreenCover(isPresented: $mesureAR) {
            MesureARView(surValider: { mesureAR = false; modele.mesureARValidee($0) }, surAnnuler: { mesureAR = false })
        }
        .fullScreenCover(isPresented: $cameraToise) {
            PriseCamera(onImage: { cameraToise = false; modele.photoToise($0) }, onCancel: { cameraToise = false })
                .ignoresSafeArea()
        }
    }

    /// La photo de la toise ; quand les chiffres sont lus, un toucher sur le bout de la queue règle le curseur.
    @ViewBuilder private func photoToise(_ image: UIImage) -> some View {
        VStack(spacing: 8) {
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
            .clipShape(RoundedRectangle(cornerRadius: PriseJetons.rayon))
            if modele.toise != nil {
                Text("Touche le bout de la queue.").font(PriseJetons.legende()).foregroundStyle(PriseJetons.encre)
            }
        }
    }
}

/// Le résultat : la consigne et la liste de contrôle de `Core`, le poids estimé, l'interrupteur « gardée ».
struct PriseResultatView: View {
    @Bindable var modele: PriseModele
    @State private var poidsOuvert = false

    var body: some View {
        let controle = modele.controle
        VStack(spacing: 12) {
            PriseEntete(titre: modele.especeConfirmee?.nom ?? "Ta prise",
                        consigne: controle?.consigne.texte ?? PriseLogique.consigneAvantConfirmation)
            ScrollView {
                VStack(spacing: 14) {
                    if let entree = modele.especeConfirmee {
                        HStack(spacing: 14) {
                            PriseImageEspece(entree: entree, cote: 88)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(Int(modele.longueurCm.rounded())) cm").font(PriseJetons.titre()).foregroundStyle(PriseJetons.encre)
                                if modele.methode == .toise { Text("Lu sur ta toise").font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret) }
                                if let plage = modele.plageAR { Text("\(plage.texte), mesuré en réalité augmentée").font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret) }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    if let controle, PriseLogique.tropPresDeLaMaille(controle) {
                        Text("Trop près de la maille, mesure sur une toise")
                            .font(PriseJetons.corps()).foregroundStyle(PriseJetons.encre)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14).background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
                    }
                    if let poids = modele.poids { blocPoids(poids) }
                    if let controle {
                        ForEach(Array(controle.lignes.enumerated()), id: \.offset) { _, ligne in PriseLigneView(ligne: ligne) }
                    }
                    Toggle("Gardée", isOn: $modele.gardee)
                        .font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
                        .frame(minHeight: PriseJetons.cibleMin)
                }
            }
            .scrollIndicators(.hidden)
            Button("Ranger dans le Pescedex") { modele.ranger() }.buttonStyle(PriseBoutonPrincipal())
        }
        .padding(20)
    }

    private func blocPoids(_ poids: PoidsEstime) -> some View {
        Button { withAnimation { poidsOuvert.toggle() } } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(PriseLogique.texteDuPoids(poids)).font(PriseJetons.titre()).foregroundStyle(PriseJetons.encre)
                if poidsOuvert {
                    Text(PriseLogique.texteDeLaFourchette(poids))
                    Text(poids.source)
                    Text(PriseLogique.calculePasPese)
                }
            }
            .font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
        }
        .buttonStyle(.plain)
    }
}

/// Une ligne de la liste de contrôle : la phrase, puis ses sources et sa date de lecture d'un toucher.
struct PriseLigneView: View {
    var ligne: LigneControle
    @State private var ouverte = false

    var body: some View {
        Button { withAnimation { ouverte.toggle() } } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: symbole).foregroundStyle(couleur).accessibilityHidden(true)
                    Text(ligne.phrase).font(PriseJetons.corps()).foregroundStyle(PriseJetons.encre)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if ouverte {
                    ForEach(Array(ligne.sources.enumerated()), id: \.offset) { _, s in
                        Text(s.titre).font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
                    }
                    if let citation = ligne.citation { Text(citation).font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret) }
                    if let date = ligne.dateLecture {
                        Text("Lue le \(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "fr_FR"))))")
                            .font(PriseJetons.legende()).foregroundStyle(PriseJetons.discret)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PriseJetons.papier, in: RoundedRectangle(cornerRadius: PriseJetons.rayon))
        }
        .buttonStyle(.plain)
    }

    private var symbole: String {
        switch ligne.etat {
        case .respectee: return "checkmark.circle.fill"
        case .nonRespectee: return "xmark.octagon.fill"
        case .aVerifierSurPlace: return "questionmark.circle.fill"
        }
    }

    private var couleur: Color {
        switch ligne.etat {
        case .respectee: return PriseJetons.accent
        case .nonRespectee: return .red
        case .aVerifierSurPlace: return PriseJetons.mise
        }
    }
}
