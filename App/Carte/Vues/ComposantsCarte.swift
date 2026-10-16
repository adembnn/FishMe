import SwiftUI
import UIKit
import Core

/// L'illustration d'une espèce (posée dans `App/Assets.xcassets/` par A). Sans image : un poisson générique, jamais un blanc.
struct ImageEspeceCarte: View {
    let nom: String?

    var body: some View {
        if let nom, UIImage(named: nom) != nil {
            Image(nom)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            Image(systemName: "fish")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
        }
    }
}

struct PastilleRarete: View {
    let niveau: NiveauRarete

    var body: some View {
        Text(niveau.libelle)
            .font(PolicesCarte.legende())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(Palette.surMarine)
            .background(CouleursCarte.rarete(niveau), in: Capsule())
    }
}

/// Une espèce relevée : image, nom, rareté, « N pêches, dernier relevé AAAA », ouverture du jour.
struct RangeeEspece: View {
    let nom: String
    let image: String?
    let nPeches: Int
    let annee: Int?
    var rarete: ResultatRarete?
    var ouverture: OuvertureDuJour?
    var selectionnee = false
    /// Faux : espèce proposée sans relevé OFB ici ; aucun chiffre n'est montré.
    var releve = true

    var body: some View {
        HStack(spacing: 12) {
            ImageEspeceCarte(nom: image)
                .frame(width: 56, height: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(nom)
                    .font(PolicesCarte.corps())
                    .fixedSize(horizontal: false, vertical: true)
                Text(releve ? texteReleve(nPeches: nPeches, annee: annee) : "pas relevée ici")
                    .font(PolicesCarte.legende())
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
                if let rarete, rarete.echelle == .region {
                    Text("rareté sur la région (moins de 20 pêches ici)")
                        .font(PolicesCarte.legende())
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let ouverture {
                    Text(ouverture.texte)
                        .font(PolicesCarte.legende())
                        .foregroundStyle(ouverture.estOuverte ? Palette.ouvert : Palette.alerte)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 4)
            if let rarete, rarete.niveau != .nonMesuree {
                PastilleRarete(niveau: rarete.niveau)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(selectionnee ? Palette.marineDoux : Color.clear, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Ce que l'écran « Ton spot » montre : le lieu, l'espèce la plus pêchée, trois autres et le reste.
/// Tout vient de `calculerFiche` (donc de `Core`) ; chaque chiffre garde son nombre de pêches et son année.
nonisolated struct ApercuSpot: Sendable, Equatable {
    var lieu: String
    var vedette: LigneEspece?
    var autres: [LigneEspece]
    var reste: Int
    /// Toujours faux depuis le 16 oct. : la vedette est la plus pêchée, jamais la plus rare.
    var vedetteEstRare: Bool = false
    /// Vrai quand aucune station OFB n'est à proximité : les espèces sont alors celles du département (rareté de `Core`).
    var parDepartement: Bool = false
    /// Le code du département dont viennent les espèces quand `parDepartement` est vrai.
    var codeDepartement: String? = nil
    /// Une ligne honnête sous les tuiles (« Pas de relevé OFB ici : espèces du département ») ; `nil` si un relevé existe tout près.
    var noteHonnete: String? = nil
}

/// Une station OFB est « à proximité » si elle est à moins de 10 km : c'est le premier rayon de `Core` pour les espèces d'un coin.
nonisolated enum ProximiteOFB {
    static let rayonM = 10_000.0

    static func aUneStation(pres c: Coordonnee, services: ServicesCarte) -> Bool {
        let dLat = rayonM / 111_000
        let dLon = rayonM / (111_000 * max(0.2, cos(c.latitude * .pi / 180)))
        let zone = RegionCarte(sudOuest: Coordonnee(latitude: c.latitude - dLat, longitude: c.longitude - dLon),
                               nordEst: Coordonnee(latitude: c.latitude + dLat, longitude: c.longitude + dLon))
        return services.especes.stationsDans(zone).contains { distanceMetres($0.coordonnee, c) <= rayonM }
    }

    /// Les espèces du département, de la plus pêchée à la moins pêchée, avec la rareté de `Core` (nombre de pêches et année du dernier
    /// relevé). Une espèce sans relevé dans le département (ou sans année) n'est pas listée : aucun chiffre n'est inventé.
    static func especesDuDepartement(_ departement: Departement, services: ServicesCarte) -> [LigneEspece] {
        guard !departement.estInconnu else { return [] }
        return services.especes.especesPechables().compactMap { p -> LigneEspece? in
            let r = services.especes.rarete(espece: p.espece, departement: departement)
            guard r.nPeches > 0, let annee = r.anneeDernierReleve else { return nil }
            return LigneEspece(espece: p.espece, nPeches: r.nPeches, annee: annee, ouverture: nil, rarete: r)
        }
        .sorted { ($0.nPeches, $1.espece.id) > ($1.nPeches, $0.espece.id) }
    }
}

@concurrent nonisolated func calculerApercuSpot(services: ServicesCarte, spot: Spot, date: Date) async -> ApercuSpot {
    let fiche = await calculerFiche(services: services, coordonnee: spot.centre, choix: nil, espece: nil, date: date)
    var releves = fiche.especes.filter { $0.releve }
    // Aucune station OFB à proximité : on ne prête pas à ce spot les poissons d'une station lointaine. On dit la vérité, puis on
    // liste les espèces du département avec la rareté de Core.
    var parDepartement = false
    var noteHonnete: String?
    if !ProximiteOFB.aUneStation(pres: spot.centre, services: services) {
        parDepartement = true
        releves = ProximiteOFB.especesDuDepartement(spot.departement, services: services)
        noteHonnete = releves.isEmpty ? "Pas de relevé OFB ici ni dans le département." : "Pas de relevé OFB ici : espèces du département."
    }
    // La vedette est toujours l'espèce la plus pêchée de la station (Adem, 16 oct. : l'app ne met jamais
    // un spot en avant pour une espèce rare). Les rares restent visibles dans la liste du spot.
    let vedette = releves.max { $0.nPeches < $1.nPeches }
    let vedetteEstRare = false
    let autres = releves
        .filter { $0.espece != vedette?.espece }
        .sorted { $0.nPeches > $1.nPeches }
    let eau = fiche.eaux.first?.nom ?? fiche.lieu.eau?.nom
    let code = spot.departement.estInconnu ? nil : spot.departement.code
    let lieu: String
    switch (eau, code) {
    case let (eau?, code?): lieu = "\(eau) · \(code)"
    case let (eau?, nil): lieu = eau
    case let (nil, code?): lieu = "Ton spot · \(code)"
    case (nil, nil): lieu = "Ton spot"
    }
    return ApercuSpot(lieu: lieu, vedette: vedette, autres: Array(autres.prefix(3)), reste: max(0, autres.count - 3),
                       vedetteEstRare: vedetteEstRare, parDepartement: parDepartement,
                       codeDepartement: spot.departement.estInconnu ? nil : spot.departement.code, noteHonnete: noteHonnete)
}

/// Bouton rond de 44 pt en verre (carte) : icône encre ou marine.
struct BoutonVerreCarte: View {
    let symbole: String
    let libelle: String
    var teinte: Color = Palette.encre
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbole)
                .font(Police.taille(18))
                .foregroundStyle(teinte)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                        .overlay(Circle().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}
