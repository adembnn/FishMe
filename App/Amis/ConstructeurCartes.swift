import Core
import Foundation

/// Transforme les cartes du Pescedex (L4, par le contrat `CollectionCartes` de Core) en cartes partageables.
/// C'est ici que le lieu s'arrête au département et que l'image passe par `ImageSansGPS`.
struct ConstructeurCartes {
    let collection: any CollectionCartes
    let especes: any ServiceEspeces

    /// Les cartes à partager : les vraies prises et les cartes déclarées ; jamais la carte d'exemple.
    func cartesAPartager() async -> [CartePartagee] {
        var resultat: [CartePartagee] = []
        for prise in await collection.cartes() where !prise.exemple {
            resultat.append(await carte(depuis: prise))
        }
        return resultat
    }

    func carte(depuis prise: Prise) async -> CartePartagee {
        let departement = Formats.departement(depuisLieuFlou: prise.lieuFlou).flatMap { $0.estInconnu ? nil : $0 }
        let niveau = departement.map { especes.rarete(espece: prise.espece, departement: $0).niveau } ?? .nonMesuree
        var image: Data?
        if !prise.estDeclaree, let png = await collection.imagePNG(de: prise) {
            image = ImageSansGPS.nettoyer(png)
        }
        return CartePartagee(id: prise.id, espece: prise.espece.id, rarete: niveau, date: prise.date, tailleCm: prise.longueurCm,
                             bredouille: false, departement: departement?.code, image: image)
    }
}
