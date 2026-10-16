import Core
import SwiftUI

/// Mode démo de la page Amis : quatre amis et un fil de cartes d'exemple, 100 % locaux à la vue.
/// Rien ici ne touche `GestionAmis`, CloudKit, le réseau ni le disque : aucun signalement, blocage ou retrait réel.
/// Les noms sont fictifs, aucun lieu n'est donné, et tout est marqué « Exemple » à l'écran.
/// Interrupteur : `@AppStorage("demo.communaute")`, branché dans les réglages.
enum DemoCommunaute {
    static let cle = "demo.communaute"
}

/// Un ami d'exemple (sans identifiant iCloud).
struct DemoAmi: Identifiable, Hashable {
    let id: String
    let nom: String
    let nombreDeCartes: Int
}

/// Une carte d'exemple. `image` est le nom d'une image d'espèce déjà présente dans les ressources de l'app.
struct DemoCarte: Identifiable, Hashable {
    let id: String
    let ami: String
    let espece: String
    let image: String
    let tailleCm: Double
    let rarete: NiveauRarete
    /// Nombre de mois avant aujourd'hui (le fil n'affiche que le mois et l'année).
    let ilYaMois: Int

    var date: Date {
        let jour = Calendar(identifier: .gregorian).date(byAdding: .month, value: -ilYaMois, to: Date()) ?? Date()
        return CartePartagee.moisEtAnnee(jour)
    }
}

enum DonneesDemoAmis {
    static let amis: [DemoAmi] = [
        DemoAmi(id: "demo-lea", nom: "Léa", nombreDeCartes: 14),
        DemoAmi(id: "demo-hugo", nom: "Hugo", nombreDeCartes: 9),
        DemoAmi(id: "demo-camille", nom: "Camille", nombreDeCartes: 21),
        DemoAmi(id: "demo-theo", nom: "Théo", nombreDeCartes: 6),
    ]

    static let cartes: [DemoCarte] = [
        DemoCarte(id: "c1", ami: "Camille", espece: "Brochet", image: "brochet", tailleCm: 78, rarete: .rare, ilYaMois: 0),
        DemoCarte(id: "c2", ami: "Léa", espece: "Perche commune", image: "perche-commune", tailleCm: 27, rarete: .commun, ilYaMois: 0),
        DemoCarte(id: "c3", ami: "Hugo", espece: "Truite fario", image: "truite-fario", tailleCm: 31, rarete: .peuCommun, ilYaMois: 0),
        DemoCarte(id: "c4", ami: "Théo", espece: "Sandre", image: "sandre", tailleCm: 61, rarete: .peuCommun, ilYaMois: 1),
        DemoCarte(id: "c5", ami: "Camille", espece: "Ombre commun", image: "ombre-commun", tailleCm: 38, rarete: .legendaire, ilYaMois: 1),
        DemoCarte(id: "c6", ami: "Léa", espece: "Carpe commune", image: "carpe-commune", tailleCm: 64, rarete: .commun, ilYaMois: 1),
        DemoCarte(id: "c7", ami: "Hugo", espece: "Tanche", image: "tanche", tailleCm: 36, rarete: .peuCommun, ilYaMois: 2),
        DemoCarte(id: "c8", ami: "Camille", espece: "Chevesne", image: "chevesne", tailleCm: 33, rarete: .commun, ilYaMois: 2),
        DemoCarte(id: "c9", ami: "Théo", espece: "Black-bass", image: "black-bass", tailleCm: 41, rarete: .rare, ilYaMois: 3),
    ]
}

/// Le contenu de la page Amis en mode démo : bandeau « Exemple », liste d'amis et fil, tout en local.
struct DemoAmisContenu: View {
    @State private var carteOuverte: DemoCarte?
    @State private var actionSansEffet = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.xl) {
            bandeau
            listeDesAmis
            fil
        }
        .sheet(item: $carteOuverte) { carte in
            DemoCarteDetail(carte: carte)
        }
        .alert("Ami d'exemple", isPresented: $actionSansEffet) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Rien n'est signalé, bloqué ni retiré : ce sont des données d'exemple pour la démo.")
        }
    }

    private var bandeau: some View {
        Label("Données d'exemple pour la démo", systemImage: "info.circle")
            .font(Police.detail)
            .foregroundStyle(Palette.encre)
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tuileFishMe()
            .accessibilityElement(children: .combine)
    }

    private var listeDesAmis: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Tes amis")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            VStack(spacing: 0) {
                ForEach(Array(DonneesDemoAmis.amis.enumerated()), id: \.element.id) { index, ami in
                    rangee(ami)
                    if index < DonneesDemoAmis.amis.count - 1 { Divider() }
                }
            }
            .padding(.leading, Espace.l)
            .tuileFishMe()
        }
    }

    private func rangee(_ ami: DemoAmi) -> some View {
        HStack(spacing: Espace.m) {
            Avatar(nom: ami.nom)
            VStack(alignment: .leading, spacing: 2) {
                Text(ami.nom).font(Police.corps).foregroundStyle(Palette.encre)
                Text("\(ami.nombreDeCartes) cartes · Exemple")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
            }
            Spacer(minLength: Espace.s)
            Menu {
                Button { actionSansEffet = true } label: { Label("Signaler", systemImage: "flag") }
                Button { actionSansEffet = true } label: { Label("Bloquer", systemImage: "hand.raised") }
                Button { actionSansEffet = true } label: { Label("Retirer cet ami", systemImage: "person.badge.minus") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Plus d'actions pour \(ami.nom), exemple")
        }
        .frame(minHeight: 60)
        .accessibilityElement(children: .contain)
    }

    private var fil: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Nouvelles cartes")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            VStack(spacing: Espace.m) {
                ForEach(DonneesDemoAmis.cartes) { carte in carteDuFil(carte) }
            }
        }
    }

    private func carteDuFil(_ carte: DemoCarte) -> some View {
        let style = RareteAmi(carte.rarete)
        return Button { carteOuverte = carte } label: {
            HStack(spacing: Espace.m) {
                DemoVignette(image: carte.image, style: style)
                    .frame(width: 84)
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(carte.espece)
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                    Text("\(carte.tailleCm.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "fr_FR")))) cm")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                    HStack(spacing: Espace.xs) {
                        BadgeRareteAmi(style: style, taille: 18)
                        Text(style.mot).font(Police.legende).foregroundStyle(Palette.encreDouce)
                    }
                    Text("\(carte.ami) · \(JetonAmis.date(carte.date)) · Exemple")
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
            }
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tuileFishMe()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Ouvre la carte d'exemple")
    }
}

/// L'illustration de l'espèce sur le fond de sa rareté (comme une carte déclarée sans photo).
private struct DemoVignette: View {
    let image: String
    let style: RareteAmi

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
                .fill(LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom))
            Image(image).resizable().scaledToFit().padding(Espace.s)
        }
        .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

/// Détail local d'une carte d'exemple : aucun signalement possible, rien ne sort de la vue.
private struct DemoCarteDetail: View {
    let carte: DemoCarte

    var body: some View {
        let style = RareteAmi(carte.rarete)
        VStack(spacing: Espace.l) {
            DemoVignette(image: carte.image, style: style)
                .frame(maxWidth: 260)
            Text(carte.espece).font(Police.titre).foregroundStyle(Palette.encre)
            HStack(spacing: Espace.s) {
                BadgeRareteAmi(style: style, taille: 24)
                Text(style.mot).font(Police.corps).foregroundStyle(Palette.encreDouce)
            }
            Text("\(carte.tailleCm.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "fr_FR")))) cm · \(carte.ami) · \(JetonAmis.date(carte.date))")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            Label("Exemple pour la démo", systemImage: "info.circle")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
            Spacer(minLength: 0)
        }
        .padding(Espace.l)
        .padding(.top, Espace.xl)
        .frame(maxWidth: .infinity)
        .presentationDetents([.large])
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) { BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord) }
    }
}
