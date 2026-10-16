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
            // Maquette P32 : barre de 44 pt à 59 pt du haut (le bord de la zone sûre), carte de 244 pt à 118 pt.
            VStack(spacing: 0) {
                barre
                    .padding(.horizontal, Espace.bord)
                Spacer().frame(height: 15)
                grandeCarte
                Spacer(minLength: Espace.m)
                feuille
            }
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
            HStack(spacing: 10) {
                Text(String(ami.nom.prefix(1)).uppercased())
                    .font(JetonAmis.police(13))
                    .foregroundStyle(Palette.surMarine)
                    .frame(width: 32, height: 32)
                    .background(Palette.marine, in: Circle())
                    .accessibilityHidden(true)
                Text(ami.nom).font(Police.sousTitre).foregroundStyle(Palette.encre)
            }
            .padding(.leading, 6).padding(.trailing, Espace.l)
            .frame(height: Gabarit.zoneTactile)
            .fondVerre(Capsule())
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
                    .font(Police.taille(18))
                    .foregroundStyle(Palette.encre)
                    .frame(width: JetonAmis.zoneTactile, height: JetonAmis.zoneTactile)
                    .fondVerre(Circle())
            }
            .accessibilityLabel("Signaler ou bloquer \(ami.nom)")
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
                        .frame(width: 244)
                        .clipShape(RoundedRectangle(cornerRadius: 244 * Gabarit.coinCarte, style: .continuous))
                        .shadow(color: Palette.encre.opacity(0.3), radius: 15, y: 14)
                } else {
                    tuile(carte, largeur: 244)
                        .shadow(color: Palette.encre.opacity(0.3), radius: 15, y: 14)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(gestion.espece(carte.espece)?.nom ?? "Carte")
        } else {
            // Aucune carte partagée : le dos d'une carte (marine, motif de vagues) et une phrase, jamais un vide.
            VStack(spacing: Espace.m) {
                RoundedRectangle(cornerRadius: 244 * Gabarit.coinCarte, style: .continuous)
                    .fill(Palette.marine)
                    .frame(width: 244, height: 244 / Gabarit.rapportCarte)
                    .overlay {
                        Image(systemName: "fish.fill")
                            .font(Police.taille(64))
                            .foregroundStyle(Color.white.opacity(0.4))
                    }
                    .shadow(color: Palette.encre.opacity(0.3), radius: 15, y: 14)
                Text("\(ami.nom) n'a pas encore partagé de carte")
                    .font(Police.sousTitre).foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Espace.xl)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// La feuille du bas : « 4 sur 11 espèces de la zone » puis les cartes de l'ami, côte à côte (4 de 76 pt).
    private var feuille: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Palette.filet).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 7)
                .padding(.bottom, Espace.m)
            compteur
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(especes) { carte in
                        Button { carteChoisieId = carte.id } label: {
                            tuile(carte)
                                .overlay(RoundedRectangle(cornerRadius: 76 * Gabarit.coinCarte, style: .continuous)
                                    .strokeBorder(Palette.marine, lineWidth: carte.id == carteEnGrand?.id ? 2 : 0))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let url = gestion.urlDeSignalement(ami: ami, carte: carte) {
                                Link(destination: url) { Label("Signaler cette carte", systemImage: "flag") }
                            }
                        }
                    }
                    ForEach(manquantes, id: \.self) { id in tuileSilhouette(id) }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, Espace.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding(.horizontal, Espace.s)
        // À régler dans RootView : la maquette pose la feuille à 100 pt du bas, au-dessus de la barre d'onglets.
        .padding(.bottom, Espace.s)
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

    /// Une espèce que l'ami n'a pas encore : le dos de la carte (marine, silhouette blanche, nom).
    private func tuileSilhouette(_ id: String) -> some View {
        let espece = gestion.espece(id)
        let largeur: CGFloat = 76
        let hauteur = largeur / Gabarit.rapportCarte
        let u = largeur / 100
        return ZStack(alignment: .top) {
            Palette.marine
            if let espece {
                Image(espece.image).resizable().renderingMode(.template).scaledToFit()
                    .foregroundStyle(Palette.surMarine.opacity(0.4))
                    .frame(width: largeur * 0.68)
                    .padding(.top, hauteur * 0.36)
            }
            VStack {
                Spacer()
                Text(NomCarte.court(espece?.nom ?? ""))
                    .font(Police.taille(9 * u, .heavy))
                    .foregroundStyle(Palette.surMarine.opacity(0.85))
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.bottom, hauteur * 0.09)
            }
            RoundedRectangle(cornerRadius: 4.4 * u, style: .continuous)
                .inset(by: 2.4 * u)
                .strokeBorder(Palette.surMarine.opacity(0.28), lineWidth: 1)
        }
        .frame(width: largeur, height: hauteur)
        .clipShape(RoundedRectangle(cornerRadius: largeur * Gabarit.coinCarte, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(espece?.nom ?? "Espèce") pas encore pêchée")
    }

    /// Une carte de l'ami en petit : le cadre `CarteCadre` d'Adem, le fond de sa rareté, le poisson, le nom et le badge `BadgeRarete`.
    /// Le centile de taille n'est pas dans ce que l'ami partage : il n'est pas affiché.
    // À brancher : le centile (« 52e ») quand `CartePartagee` le portera.
    private func tuile(_ carte: CartePartagee, largeur: CGFloat = 76) -> some View {
        let style = StyleRarete(carte.rarete)
        let espece = gestion.espece(carte.espece)
        let hauteur = largeur / Gabarit.rapportCarte
        let u = largeur / 100
        return CarteCadre(style: style, declaree: false) {
            VStack(spacing: 0) {
                ZStack {
                    LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
                    if let espece {
                        Image(espece.image).resizable().scaledToFit()
                            .padding(4 * u)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                HStack(spacing: 2 * u) {
                    Text(NomCarte.court(espece?.nom ?? ""))
                        .font(Police.taille(11 * u, .heavy))
                        .foregroundStyle(Palette.encre)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    BadgeRarete(style: style, taille: 14 * u)
                }
                .padding(.horizontal, 7 * u)
                .frame(maxWidth: .infinity)
                .frame(height: hauteur * 0.22)
                .background(Palette.surface)
            }
        }
        .frame(width: largeur, height: hauteur)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(espece?.nom ?? "Espèce"), \(style.mot)")
    }
}

/// Le verre des ronds et capsules posés sur une page (matière fine, filet, ombre douce).
private extension View {
    func fondVerre<S: InsettableShape>(_ forme: S) -> some View {
        background {
            forme.fill(.regularMaterial)
                .overlay(forme.strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
        }
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
