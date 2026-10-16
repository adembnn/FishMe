import Core
import SwiftUI

/// Mode démo de la page Amis : quatre amis et un fil de cartes, 100 % locaux à la vue.
/// Rien ici ne touche `GestionAmis`, CloudKit, le réseau ni le disque : aucun signalement, blocage ou retrait réel.
/// Les prénoms sont fictifs et aucun lieu n'est donné.
/// Interrupteur : `@AppStorage("demo.communaute")`, branché dans les réglages.
enum DemoCommunaute {
    static let cle = "demo.communaute"
}

/// Un ami de démo (sans identifiant iCloud).
struct DemoAmi: Identifiable, Hashable {
    let id: String
    let nom: String
    let nombreDeCartes: Int
}

/// Une carte de démo. `image` est le nom d'une image d'espèce déjà présente dans les ressources de l'app.
struct DemoCarte: Identifiable, Hashable {
    let id: String
    let ami: String
    let espece: String
    let image: String
    let tailleCm: Double
    let rarete: NiveauRarete
    /// Nombre de mois avant aujourd'hui (le fil n'affiche que le mois et l'année).
    let ilYaMois: Int

    /// La vraie photo de démo (`App/Demo/Photos/<image>-1.jpg`), ou `nil` : la carte montre alors l'image d'espèce.
    var photo: Data? { PhotosDemoAmis.donnees(especeId: image) }

    var date: Date {
        let jour = Calendar(identifier: .gregorian).date(byAdding: .month, value: -ilYaMois, to: Date()) ?? Date()
        return CartePartagee.moisEtAnnee(jour)
    }
}

/// Les photos de démo embarquées. Cherchées à la racine du bundle puis dans `Photos` ou `Demo/Photos` ; absentes : `nil`.
enum PhotosDemoAmis {
    static func donnees(especeId: String, bundle: Bundle = .main) -> Data? {
        let base = "\(especeId)-1"
        for dossier in [nil, "Photos", "Demo/Photos"] as [String?] {
            if let url = bundle.url(forResource: base, withExtension: "jpg", subdirectory: dossier),
               let donnees = try? Data(contentsOf: url) {
                return donnees
            }
        }
        return nil
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

extension DemoCarte {
    /// La carte au format de la grille (même dessin que les cartes d'Adem).
    var pourGrille: CarteAmiGrille {
        CarteAmiGrille(id: id, prenom: ami, mois: JetonAmis.date(date), style: StyleRarete(rarete), nomEspece: espece,
                       imageEspece: image, tailleCm: tailleCm, photo: photo)
    }
}

/// Le contenu de la page Amis en mode démo : liste d'amis et cartes, tout en local.
/// `avecInviter` : sans `GestionAmis` (pas d'iCloud), la page n'a pas son propre bouton ; celui-ci le remplace, sans effet réel.
struct DemoAmisContenu: View {
    var avecInviter = false

    @State private var carteOuverte: DemoCarte?
    @State private var amiOuvert: DemoAmi?
    @State private var actionSansEffet = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.xl) {
            if avecInviter {
                Text("Amis")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                Button { actionSansEffet = true } label: {
                    Label("Inviter un ami", systemImage: "person.badge.plus")
                        .font(Police.sousTitre)
                        .padding(.vertical, Espace.s)
                }
                .buttonStyle(.principal)
            }
            listeDesAmis
            fil
        }
        .padding(.top, avecInviter ? Espace.s : 0)
        .sheet(item: $carteOuverte) { carte in
            DemoCarteDetail(carte: carte)
        }
        .fullScreenCover(item: $amiOuvert) { ami in
            DemoCollectionAmi(ami: ami)
        }
        .alert("Action indisponible en démo", isPresented: $actionSansEffet) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cette action n'est pas disponible en démo.")
        }
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
        HStack(spacing: 0) {
            Button { amiOuvert = ami } label: {
                HStack(spacing: Espace.m) {
                    Avatar(nom: ami.nom)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ami.nom).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(1).minimumScaleFactor(0.7)
                        Text("\(ami.nombreDeCartes) cartes")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .lineLimit(2)
                    }
                    Spacer(minLength: Espace.s)
                    Image(systemName: "chevron.right").foregroundStyle(Palette.encreDouce)
                }
                .frame(minHeight: 60)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
            }
            .buttonStyle(.plain)
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
            .accessibilityLabel("Plus d'actions pour \(ami.nom)")
        }
    }

    private var fil: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Nouvelles cartes")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            GrilleCartesAmis(cartes: DonneesDemoAmis.cartes.map(\.pourGrille)) { choisie in
                carteOuverte = DonneesDemoAmis.cartes.first { $0.id == choisie.id }
            }
        }
    }
}

/// La collection d'un ami de démo : ses cartes, au même dessin que les vraies. Rien n'est lu en ligne.
private struct DemoCollectionAmi: View {
    let ami: DemoAmi
    @State private var carteOuverte: DemoCarte?

    var body: some View {
        let cartes = DonneesDemoAmis.cartes.filter { $0.ami == ami.nom }
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Collection de \(ami.nom)")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .padding(.top, Espace.xl)
                if cartes.isEmpty {
                    Text("Pas encore de carte pour \(ami.nom).")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                } else {
                    GrilleCartesAmis(cartes: cartes.map(\.pourGrille)) { choisie in
                        if let carte = cartes.first(where: { $0.id == choisie.id }) {
                            carteOuverte = carte
                        }
                    }
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) { BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord) }
        .sheet(item: $carteOuverte) { carte in DemoCarteDetail(carte: carte) }
    }
}

/// Détail local d'une carte de démo : la carte en grand, aucun signalement possible, rien ne sort de la vue.
private struct DemoCarteDetail: View {
    let carte: DemoCarte

    var body: some View {
        VStack(spacing: Espace.l) {
            CarteAmiMini(style: StyleRarete(carte.rarete), nomEspece: carte.espece, imageEspece: carte.image,
                         photo: carte.photo, tailleCm: carte.tailleCm)
                .frame(maxWidth: 280)
            Text("\(carte.ami) · \(JetonAmis.date(carte.date))")
                .font(Police.detail)
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
