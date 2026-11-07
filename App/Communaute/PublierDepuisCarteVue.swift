import Core
import SwiftUI

/// Règles de « Publier » depuis une carte du Pescedex (L18 vers L23), sans écran, donc testables.
enum PublicationDepuisCarte {
    /// Un bouton « Publier » seulement pour une vraie prise avec sa photo : ni carte déclarée (sans photo), ni carte d'exemple ou de démo.
    static func estPublicable(_ prise: Prise, photo: Data?) -> Bool {
        guard let photo, !photo.isEmpty else { return false }
        return !prise.estDeclaree && !prise.exemple
    }

    /// Le lieu proposé vient du `lieuFlou` de la carte (département, jamais une coordonnée). Le défaut reste « département seul »
    /// (`LieuPublication.parDefaut`, décision de Titouan).
    static func contexteLieu(_ prise: Prise) -> ContexteLieu {
        ContexteLieu(lieuFlou: prise.lieuFlou, typeEau: nil)
    }

    static func carteLiee(_ prise: Prise, rarete: NiveauRarete) -> CarteLiee {
        CarteLiee(espece: prise.espece.id, rarete: rarete, tailleCm: prise.longueurCm)
    }
}

/// La feuille ouverte par « Publier » sur une carte : la feuille de publication de L23 avec la photo de la carte,
/// ou « Finis ton profil » quand le profil n'est pas créé ou que l'âge (15 ans) manque.
/// La photo du dépôt est déjà sans GPS, et le pipeline de L23 (`PreparationMedia`) la refabrique de toute façon à partir des pixels.
struct PublierDepuisCarteVue: View {
    let gestion: GestionFeed
    let prise: Prise
    let rarete: NiveauRarete
    let photo: Data

    @State private var pret = false
    @State private var profilOuvert = false
    @Environment(\.dismiss) private var fermer

    var body: some View {
        Group {
            if !pret {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if gestion.peutPublier || gestion.exemples {
                PublierVue(gestion: gestion, contexteLieu: PublicationDepuisCarte.contexteLieu(prise),
                           carte: PublicationDepuisCarte.carteLiee(prise, rarete: rarete), imagePNG: photo)
            } else {
                finisTonProfil
            }
        }
        .background(Palette.fond.ignoresSafeArea())
        .task {
            await gestion.ouvrir()
            pret = true
        }
    }

    private var finisTonProfil: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            HStack(alignment: .top) {
                Text(c: "Publier").font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
                Spacer()
                BoutonRond(role: .fermer)
            }
            Text(c: "Pour publier, il faut un surnom et avoir 15 ans ou plus.")
                .font(Police.corps).foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            Button { profilOuvert = true } label: { Text(c: "Finis ton profil") }
                .buttonStyle(.principal)
            Spacer(minLength: 0)
        }
        .padding(Espace.bord)
        .sheet(isPresented: $profilOuvert, onDismiss: {
            // Profil créé : le contexte du fil se relit, et la feuille de publication prend la place.
            Task {
                pret = false
                await gestion.ouvrir()
                pret = true
            }
        }) {
            FinisTonProfilView(gestion: .partage)
        }
    }
}
