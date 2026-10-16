import Core
import SwiftUI

/// Le Pescedex d'un ami (maquette F3) : ses cartes en images, « nouvelle » sur les espèces que je n'ai pas.
/// Le menu porte la règle 1.2 d'Apple : signaler, bloquer, retirer.
struct PescedexAmiView: View {
    let gestion: GestionAmis
    let ami: Ami
    let fermer: () -> Void

    @State private var carteOuverte: CartePartagee?
    @State private var carteChoisieId: UUID?
    @State private var confirmerBlocage = false
    @State private var confirmerRetrait = false
    @Environment(\.openURL) private var ouvrirURL

    private var cartes: [CartePartagee] {
        (gestion.collections.first { $0.id == ami.id }?.cartes ?? []).sorted { $0.date > $1.date }
    }

    private var especes: [CartePartagee] {
        var vues = Set<String>()
        return cartes.filter { vues.insert($0.espece).inserted }
    }

    /// Les espèces que j'ai et que l'ami n'a pas encore : des silhouettes, six au plus.
    private var manquantes: [String] {
        let siennes = Set(especes.map(\.espece))
        return Array(gestion.mesEspeces.subtracting(siennes).sorted().prefix(6))
    }

    private var zone: String? {
        let comptes = Dictionary(grouping: cartes.compactMap(\.departement), by: { $0 }).mapValues(\.count)
        return comptes.max { $0.value < $1.value }?.key
    }

    /// La carte montrée en grand : celle qu'on a touchée en bas, sinon la plus récente de l'ami.
    private var carteEnGrand: CartePartagee? {
        especes.first { $0.id == carteChoisieId } ?? especes.first
    }

    var body: some View {
        ZStack(alignment: .top) {
            JetonAmis.fondPage.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 72)
                grandeCarte
                Spacer(minLength: Espace.m)
                feuille
            }
            barre
                .padding(.horizontal, Espace.bord)
                .padding(.top, Espace.s)
        }
        .sheet(item: $carteOuverte) { carte in
            CarteAmiDetail(carte: carte, nomEspece: gestion.espece(carte.espece)?.nom ?? "") {
                if let url = gestion.urlDeSignalement(ami: ami, carte: carte) { ouvrirURL(url) }
            }
        }
        .confirmationDialog("Bloquer \(ami.nom) ? Ses cartes disparaissent et il ne voit plus les tiennes.",
                            isPresented: $confirmerBlocage, titleVisibility: .visible) {
            Button("Bloquer", role: .destructive) { Task { await gestion.bloquer(ami); fermer() } }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Retirer \(ami.nom) de tes amis ?", isPresented: $confirmerRetrait, titleVisibility: .visible) {
            Button("Retirer", role: .destructive) { Task { await gestion.retirer(ami); fermer() } }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var barre: some View {
        HStack {
            BoutonRond(role: .retour, rendu: .verre, action: fermer)
            Spacer()
            HStack(spacing: Espace.s) {
                Text(String(ami.nom.prefix(1)).uppercased())
                    .font(JetonAmis.police(16))
                    .foregroundStyle(Palette.surMarine)
                    .frame(width: 34, height: 34)
                    .background(Palette.marine, in: Circle())
                    .accessibilityHidden(true)
                Text(ami.nom).font(Police.sousTitre).foregroundStyle(Palette.encre)
            }
            .padding(.leading, Espace.xs).padding(.trailing, Espace.l)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(Palette.surface, in: Capsule())
            .accessibilityElement(children: .combine)
            Spacer()
            // Signaler et Bloquer restent rangés dans ce menu, jamais au premier niveau.
            Menu {
                if let url = gestion.urlDeSignalement(ami: ami) {
                    Link(destination: url) { Label("Signaler", systemImage: "flag") }
                }
                Button(role: .destructive) { confirmerBlocage = true } label: { Label("Bloquer", systemImage: "hand.raised") }
                Button(role: .destructive) { confirmerRetrait = true } label: {
                    Label("Retirer cet ami", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(JetonAmis.police(17))
                    .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
                    .background(JetonAmis.papier, in: Circle())
            }
            .accessibilityLabel("Plus d'actions")
        }
    }

    /// La carte de l'ami en grand, au centre. Un toucher l'ouvre (avec « Signaler »).
    @ViewBuilder
    private var grandeCarte: some View {
        if let carte = carteEnGrand {
            Button { if carte.image != nil { carteOuverte = carte } } label: {
                if let donnees = carte.image, let image = UIImage(data: donnees) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                        .shadow(color: Palette.encre.opacity(0.18), radius: 14, y: 8)
                } else {
                    tuile(carte)
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: 320)
            .padding(.horizontal, Espace.xl)
            .accessibilityLabel(gestion.espece(carte.espece)?.nom ?? "Carte")
        } else {
            ContentUnavailableView("Pas encore de carte", systemImage: "rectangle.stack")
        }
    }

    /// La feuille du bas : « 4 sur 11 espèces de la zone » puis les cartes de l'ami, côte à côte.
    private var feuille: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Capsule().fill(Palette.silhouette).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
            compteur
            ScrollView(.horizontal) {
                HStack(spacing: Espace.m) {
                    ForEach(especes) { carte in
                        Button { carteChoisieId = carte.id } label: {
                            tuile(carte)
                                .frame(width: 76)
                                .overlay(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
                                    .strokeBorder(Palette.marine, lineWidth: carte.id == carteEnGrand?.id ? 3 : 0))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let url = gestion.urlDeSignalement(ami: ami, carte: carte) {
                                Link(destination: url) { Label("Signaler cette carte", systemImage: "flag") }
                            }
                        }
                    }
                    ForEach(manquantes, id: \.self) { id in tuileSilhouette(id).frame(width: 76) }
                }
                .padding(.vertical, Espace.xs)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Espace.xl)
        .padding(.top, Espace.s)
        .padding(.bottom, Espace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Espace.s)
    }

    @ViewBuilder
    private var compteur: some View {
        let n = especes.count
        if let zone {
            HStack(alignment: .firstTextBaseline) {
                Text("\(n) sur \(gestion.especesReleveesDans(zone))").font(Police.titre).foregroundStyle(Palette.encre)
                Spacer()
                Text("espèces de la zone").font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
            .accessibilityElement(children: .combine)
        } else {
            Text(n == 1 ? "1 espèce" : "\(n) espèces").font(Police.titre).foregroundStyle(Palette.encre)
        }
    }

    private func tuileSilhouette(_ id: String) -> some View {
        let espece = gestion.espece(id)
        return RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
            .fill(Palette.marineDoux)
            .overlay {
                if let espece {
                    Image(espece.image).resizable().renderingMode(.template).scaledToFit()
                        .foregroundStyle(Palette.silhouette).padding(10)
                }
            }
            .aspectRatio(JetonAmis.rapportCarte, contentMode: .fit)
            .accessibilityLabel("\(espece?.nom ?? "Espèce") pas encore pêchée")
    }

    private func tuile(_ carte: CartePartagee) -> some View {
        let style = RareteAmi(carte.rarete)
        let espece = gestion.espece(carte.espece)
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
                .fill(LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom))
            if let espece {
                Image(espece.image).resizable().scaledToFit().padding(10)
            }
            BadgeRareteAmi(style: style, taille: 24).padding(6)
            if !gestion.mesEspeces.contains(carte.espece) {
                Text("nouvelle")
                    .font(JetonAmis.police(11))
                    .foregroundStyle(Palette.surMarine)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(JetonAmis.vert, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(6)
            }
        }
        .aspectRatio(JetonAmis.rapportCarte, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(espece?.nom ?? "Espèce"), \(style.mot)")
    }
}

/// La carte d'un ami en grand : son image, sans coordonnée, avec « Signaler ».
struct CarteAmiDetail: View {
    let carte: CartePartagee
    let nomEspece: String
    let signaler: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let donnees = carte.image, let image = UIImage(data: donnees) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(nomEspece)
            }
            HStack(spacing: 8) {
                Text(JetonAmis.date(carte.date)).font(JetonAmis.police(15, .bold)).foregroundStyle(JetonAmis.encreDouce)
                if let d = carte.departement {
                    Text("· dans le \(d)").font(JetonAmis.police(15, .bold)).foregroundStyle(JetonAmis.encreDouce)
                }
            }
            Button("Signaler cette carte", action: signaler)
                .font(JetonAmis.police(16))
                .frame(minHeight: JetonAmis.zoneTactile)
        }
        .padding(20)
        .presentationDetents([.large])
        .background(JetonAmis.fondPage.ignoresSafeArea())
        .overlay(alignment: .topLeading) { BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord) }
    }
}
