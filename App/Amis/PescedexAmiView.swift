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
            VStack(alignment: .leading, spacing: 16) {
                barre
                compteur
                grille
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .background(Jeton.fondPage.ignoresSafeArea())
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
                    .font(Jeton.police(17))
                    .frame(width: Jeton.zoneTactile, height: Jeton.zoneTactile)
                    .background(Jeton.papier, in: Circle())
            }
            .accessibilityLabel("Retour")
            Spacer()
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
                    .font(Jeton.police(17))
                    .frame(width: Jeton.zoneTactile, height: Jeton.zoneTactile)
                    .background(Jeton.papier, in: Circle())
            }
            .accessibilityLabel("Plus d'actions")
        }
    }

    private var compteur: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ami.nom).font(Jeton.police(30)).foregroundStyle(Jeton.encre)
            Text(texteCompteur).font(Jeton.police(16, .bold)).foregroundStyle(Jeton.encreDouce)
        }
    }

    private var texteCompteur: String {
        let n = especes.count
        let mot = n == 1 ? "espèce" : "espèces"
        guard let zone else { return "\(n) \(mot)" }
        return "\(n) \(mot) sur les \(gestion.especesReleveesDans(zone)) relevées dans le \(zone)"
    }

    private var grille: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
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
        let style = StyleRarete(carte.rarete)
        let espece = gestion.espece(carte.espece)
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14)
                .fill(LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom))
            if let espece {
                Image(espece.image).resizable().scaledToFit().padding(10)
            }
            BadgeRarete(style: style, taille: 24).padding(6)
            if !gestion.mesEspeces.contains(carte.espece) {
                Text("nouvelle")
                    .font(Jeton.police(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Jeton.vert, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(6)
            }
        }
        .aspectRatio(Jeton.rapportCarte, contentMode: .fit)
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
                Text(Formats.date(carte.date)).font(Jeton.police(15, .bold)).foregroundStyle(Jeton.encreDouce)
                if let d = carte.departement {
                    Text("· dans le \(d)").font(Jeton.police(15, .bold)).foregroundStyle(Jeton.encreDouce)
                }
            }
            Button("Signaler cette carte", action: signaler)
                .font(Jeton.police(16))
                .frame(minHeight: Jeton.zoneTactile)
        }
        .padding(20)
        .presentationDetents([.large])
        .background(Jeton.fondPage.ignoresSafeArea())
    }
}
