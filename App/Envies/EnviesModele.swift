import Core
import Foundation
import Observation

/// État de « Mes envies » : la liste, son stockage, et ce qu'il faut pour la montrer. Aucune règle n'est calculée ici :
/// l'ouverture et la taille viennent de `Core` (`ResumeEnvie`), la liste se tient dans `ListeEnvies`.
@MainActor
@Observable
final class EnviesModele {
    private(set) var liste: ListeEnvies
    /// Les cartes du Pescedex au dernier chargement (pour savoir quelles espèces sont déjà trouvées).
    private(set) var cartes: [Prise] = []
    var externes: EnviesExternes

    @ObservationIgnored private let stockage: any StockageEnvies
    private let especes: [EspecePechable]
    private let parId: [String: EspecePechable]

    init(stockage: any StockageEnvies, especes: [EspecePechable], externes: EnviesExternes = .vides) {
        self.stockage = stockage
        self.especes = especes
        self.externes = externes
        self.parId = Dictionary(especes.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        self.liste = stockage.lire()
    }

    /// À chaque chargement du Pescedex et avant d'afficher la liste : les espèces qui ont une carte sortent. Écrit seulement si ça a changé.
    func charger(cartes: [Prise], le date: Date = Date()) {
        self.cartes = cartes
        var suivante = liste
        if suivante.retirerLesExaucees(cartes: cartes, le: date) {
            liste = suivante
            stockage.ecrire(liste)
        }
    }

    /// Recharge depuis le stockage (après une restauration de la sauvegarde, par exemple).
    func relire() {
        liste = stockage.lire()
    }

    func contient(_ espece: EspecePechable) -> Bool {
        liste.contient(espece.espece)
    }

    /// Le bouton « Je veux la pêcher » : proposé si l'espèce peut être marquée, ou si elle l'est déjà (pour pouvoir la retirer).
    func peutAfficherBouton(_ espece: EspecePechable) -> Bool {
        contient(espece) || ListeEnvies.peutEtreMarquee(espece, cartes: cartes)
    }

    func basculer(_ espece: EspecePechable, le date: Date = Date()) {
        var suivante = liste
        if suivante.contient(espece.espece) {
            suivante.retirer(espece.espece, le: date)
        } else if ListeEnvies.peutEtreMarquee(espece, cartes: cartes) {
            suivante.ajouter(espece.espece, le: date)
        } else {
            return
        }
        liste = suivante
        stockage.ecrire(liste)
    }

    func retirer(_ espece: EspecePechable, le date: Date = Date()) {
        guard liste.contient(espece.espece) else { return }
        liste.retirer(espece.espece, le: date)
        stockage.ecrire(liste)
    }

    /// Les envies actives dont l'espèce existe encore dans `especes.json`. Une envie vers une espèce inconnue est ignorée, jamais effacée.
    var especesEnvisagees: [EspecePechable] {
        liste.actives.compactMap { parId[$0.espece] }
    }

    /// « Mes envies · N ».
    var nombre: Int { especesEnvisagees.count }

    func resumes(ordre: OrdreEnvies, le date: Date = Date()) -> [ResumeEnvie] {
        let externes = self.externes
        let construits = especesEnvisagees.map { e in
            ResumeEnvie.construire(espece: e, controle: externes.controle(e.espece, date), conseil: externes.conseil(e.espece),
                                   reouverture: externes.reouverture(e.espece, date))
        }
        return ResumeEnvie.trier(construits, ordre: ordre, liste: liste)
    }
}
