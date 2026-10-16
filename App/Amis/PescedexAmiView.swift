import Core
import SwiftUI

/// Le Pescedex d'un ami (maquette F3) : ses cartes en images, « nouvelle » sur les espèces que je n'ai pas.
/// Le menu porte la règle 1.2 d'Apple : signaler, bloquer, retirer.
struct PescedexAmiView: View {
    let gestion: GestionAmis
    let ami: Ami
    let fermer: () -> Void

    @State private var carteOuverte: CartePartagee?
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

    private var zone: String? {
        let comptes = Dictionary(grouping: cartes.compactMap(\.departement), by: { $0 }).mapValues(\.count)
        return comptes.max { $0.value < $1.value }?.key
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                barre
                compteur
                grille
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
        }
        .scrollIndicators(.hidden)
        .background(JetonAmis.fondPage.ignoresSafeArea())
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
            Button(action: fermer) {
                Image(systemName: "chevron.left")
                    .font(JetonAmis.police(17))
                    .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
                    .background(JetonAmis.papier, in: Circle())
            }
            .accessibilityLabel("Retour")
            Spacer()
            HStack(spacing: Espace.s) {
                Avatar(nom: ami.nom).scaleEffect(0.75).frame(width: 34, height: 34)
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

    private var compteur: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(texteCompteur).font(Police.chiffreMoyen).foregroundStyle(Palette.encre)
        }
    }

    private var texteCompteur: String {
        let n = especes.count
        let mot = n == 1 ? "espèce" : "espèces"
        guard let zone else { return "\(n) \(mot)" }
        return "\(n) sur \(gestion.especesReleveesDans(zone)) espèces de la zone (\(zone))"
    }

    private var grille: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Espace.m), count: 3), spacing: Espace.m) {
            ForEach(especes) { carte in
                Button { if carte.image != nil { carteOuverte = carte } } label: { tuile(carte) }
                    .buttonStyle(.plain)
                    .contextMenu {
                        if let url = gestion.urlDeSignalement(ami: ami, carte: carte) {
                            Link(destination: url) { Label("Signaler cette carte", systemImage: "flag") }
                        }
                    }
            }
        }
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
        .overlay(alignment: .topTrailing) { CroixFermerAmis().padding(8) }
    }
}
