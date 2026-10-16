import Core
import SwiftUI
import UIKit

/// L'image rendue pour le partage : le recto seulement. Ni bloc météo, ni marque Apple à recopier, aucune coordonnée,
/// et un PNG fabriqué par UIKit, sans métadonnée.
enum ImagePartage {
    @MainActor
    static func png(de prise: Prise, services: ServicesCollection, largeur: CGFloat = 360) -> Data? {
        guard let espece = services.especes.especesPechables().first(where: { $0.espece == prise.espece }) else { return nil }
        let dept = Formats.departement(depuisLieuFlou: prise.lieuFlou)
        // Pas de conditions, pas de durée : le partage ne porte jamais d'indice de plus pour retrouver le coin.
        let detail = CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil)
        let infos = InfosCarte.construire(detail: detail, espece: espece, zone: dept, toutesLesCartes: [prise],
                                          especesDeLaZone: [], services: services)
        let carte = CarteRectoView(infos: infos, anime: false, inclinaison: .zero, refletFixe: true,
                                   imageDecodee: UIImage(named: infos.espece.image), pourPartage: true)
            .frame(width: largeur, height: largeur / Gabarit.rapportCarte)
        let vue = FondPartage(carte: carte, largeur: largeur, departement: dept)
        let rendu = ImageRenderer(content: vue)
        rendu.scale = 3
        // Un premier rendu peut échouer le temps que le moteur graphique chauffe (simulateur) : un seul nouvel essai.
        return (rendu.uiImage ?? rendu.uiImage)?.pngData()
    }
}

/// P49 A : fond bleu nuit, la carte légèrement inclinée, le logo discret en haut, « Mon Pescedex · <département> » en bas.
/// Jamais de lieu précis : le département seulement, et rien du tout s'il est inconnu.
private struct FondPartage<Carte: View>: View {
    let carte: Carte
    let largeur: CGFloat
    let departement: Departement?

    private var legende: String {
        if let d = departement, !d.estInconnu { return "Mon Pescedex · \(d.code)" }
        return "Mon Pescedex"
    }

    var body: some View {
        VStack(spacing: Espace.xl) {
            HStack(spacing: Espace.s) {
                Image(systemName: "fish.fill")
                Text("FishMe")
            }
            .font(Police.taille(18, .heavy))
            .foregroundStyle(.white.opacity(0.9))
            carte
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
                .padding(.vertical, Espace.m)
            Text(legende)
                .font(Police.taille(20, .heavy))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, Espace.xl)
        .padding(.vertical, Espace.xxl)
        // Bleu nuit fixe : l'image partagée ne dépend pas du mode sombre.
        .background(Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255))
    }
}
