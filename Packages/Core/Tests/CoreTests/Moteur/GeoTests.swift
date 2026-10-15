import Foundation
import Testing
@testable import Core

@Suite("Géographie : département et lieu")
struct GeoTests {
    let geo = moteurEssai().geo

    @Test("5 points dans le bon département, hors de France : inconnu",
          arguments: [(paris, "75"), (nanterre, "92"), (saintDenis, "93"), (charenton, "94"), (meaux, "77")])
    func cinqPoints(point: Coordonnee, code: String) {
        #expect(geo.departement(de: point).code == code)
    }

    @Test func horsDeFrance() {
        #expect(geo.departement(de: cupertino).estInconnu)
        #expect(geo.lieu(de: cupertino, choix: nil) == .inconnu)
        #expect(geo.lieuFlou(cupertino) == "Hors de France")
    }

    @Test func contourEnPlusieursMorceauxEtTrou() {
        // Le 93 est un MultiPolygon : son second morceau compte.
        #expect(geo.departement(de: Coordonnee(latitude: 48.94, longitude: 2.50)).code == "93")
        // Le trou du 77 n'est dans aucun département.
        #expect(geo.departement(de: Coordonnee(latitude: 48.85, longitude: 3.05)).estInconnu)
    }

    @Test func laMarneACharenton() {
        let lieu = geo.lieu(de: charenton, choix: nil)
        #expect(lieu.departement.code == "94")
        #expect(lieu.eau?.nom == "La Marne")
        #expect(lieu.eau?.cle == "marne")
        #expect(lieu.categorie == CategorieEau(valeur: .deuxieme, origine: .regleDeReste))
        #expect(lieu.departementVoisin == nil)
        #expect(geo.lieuFlou(charenton) == "La Marne · 94")
    }

    @Test func unLacSansQuestion() {
        let lieu = geo.lieu(de: creteilLac, choix: nil)
        #expect(lieu.eau?.type == .lac)
        #expect(lieu.eau?.nom == "Lac de Créteil")
        #expect(geo.lieuFlou(creteilLac) == "Lac de Créteil · 94")
    }

    @Test func laMauldreSansChoixEstDeCategorieInconnue() {
        let lieu = geo.lieu(de: mareilSurMauldre, choix: nil)
        #expect(lieu.departement.code == "78")
        #expect(lieu.eau?.cle == "mauldre")
        #expect(lieu.categorie == .inconnue)
        // Le pêcheur choisit : son choix passe avant les règles.
        let choisi = geo.lieu(de: mareilSurMauldre, choix: ChoixLieu(categorie: .premiere))
        #expect(choisi.categorie == CategorieEau(valeur: .premiere, origine: .choixDuPecheur))
    }

    @Test func leChoixDeLEauDuPecheurPasseAvant() {
        let lieu = geo.lieu(de: charenton, choix: ChoixLieu(eau: morbrasEau, tronconsConfirmes: ["01-ain-troncon-taille"]))
        #expect(lieu.eau == morbrasEau)
        #expect(lieu.tronconsConfirmes == ["01-ain-troncon-taille"])
    }

    @Test func aMoinsDe500mDUneLimite() {
        let lieu = geo.lieu(de: limite94et75, choix: nil)
        #expect(lieu.departement.code == "94")
        #expect(lieu.departementVoisin?.code == "75")
    }

    @Test func eauxProchesProposeLaMarneEtLeLac() {
        let eaux = geo.eauxProches(charenton)
        #expect(eaux.contains { $0.cle == "marne" })
        #expect(geo.eauxProches(creteilLac).first?.nom == "Lac de Créteil")
        #expect(geo.eauxProches(cupertino).isEmpty)
    }

    @Test func cleDEau() {
        #expect(cleEau("La Marne") == "marne")
        #expect(cleEau("L'Ain") == "ain")
        #expect(cleEau("Le Réveillon") == "reveillon")
        #expect(cleEau("Lac de Créteil") == "lac de creteil")
    }
}
