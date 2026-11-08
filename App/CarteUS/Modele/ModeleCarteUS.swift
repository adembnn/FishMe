import Foundation
import Observation
import Core

/// L'état de la carte américaine. Le calcul de ce qui est visible (lecture des fichiers, filtre, regroupement) se fait hors du
/// thread principal ; seul le résultat, petit (196 éléments au plus), revient sur l'écran. Un résultat périmé est jeté.
@MainActor
@Observable
final class ModeleCarteUS {
    @ObservationIgnored let source: any SourceCarteUS
    private(set) var agences: any AgencesCarteUS
    @ObservationIgnored private var agencesChargees: Bool
    @ObservationIgnored private var derniereZone: ZoneCarte?
    @ObservationIgnored private var generation = 0

    private(set) var resultat = ResultatCarteUS.vide
    /// La fiche ouverte (lieu touché sur la carte).
    var fiche: FicheUS? {
        didSet { if fiche?.id != oldValue?.id { ficheOuverteA = fiche == nil ? nil : horloge() } }
    }
    /// Quand la fiche actuelle est apparue : sert à `yAllerPret`.
    @ObservationIgnored private(set) var ficheOuverteA: Date?
    /// L'heure (remplaçable dans les tests).
    @ObservationIgnored var horloge: () -> Date = { Date() }
    @ObservationIgnored private var ouvertureEnCours = 0
    /// Un toucher sur « Y aller » dans les 0,8 s qui suivent l'apparition d'une fiche n'est pas pour lui : la fiche monte sous le doigt
    /// du pêcheur (un second toucher sur le pin, ou un pin sous le bouton) et lançait Plans sans que personne l'ait demandé.
    /// Règle du produit : un toucher sur un pin ne lance JAMAIS une autre application.
    static let delaiAvantYAller: TimeInterval = 0.8
    /// L'État choisi à la main quand la carte ne le devine pas.
    var etatChoisi: String? {
        didSet { if etatChoisi != oldValue { recalculer() } }
    }

    /// Sans `agences`, le fichier embarque du niveau 1 est lu hors du thread principal par `chargerAgences()`.
    init(source: any SourceCarteUS, agences: (any AgencesCarteUS)? = nil) {
        self.source = source
        self.agences = agences ?? AgencesFixesCarteUS(tous: [])
        self.agencesChargees = agences != nil
    }

    func chargerAgences() async {
        guard !agencesChargees else { return }
        agencesChargees = true
        let lues = await Task.detached(priority: .utility) { AgencesNiveau1US.embarquees() }.value
        agences = lues
    }

    /// Les États que le pêcheur peut choisir (niveau 1, par ordre alphabétique).
    var etatsChoisissables: [InfoAgenceUS] { agences.tous }

    /// Le message "Pas encore de données pour cet État", seulement s'il y a lieu.
    var message: MessageSansDonneesUS? {
        resultat.sansDonnees ? MessageSansDonneesUS.pour(etat: resultat.etat, agences: agences) : nil
    }

    func zoneChangee(_ zone: ZoneCarte) {
        derniereZone = zone
        recalculer()
    }

    private func recalculer() {
        guard let zone = derniereZone else { return }
        generation += 1
        let numero = generation
        let source = source
        let choisi = etatChoisi
        Task {
            let calcule = await Task.detached(priority: .userInitiated) {
                CalculCarteUS.calculer(source: source, zone: zone, etatChoisi: choisi)
            }.value
            if numero == self.generation { self.resultat = calcule }
        }
    }

    /// Vrai seulement si la fiche est là depuis assez longtemps pour que le toucher vienne d'un pêcheur qui a vu le bouton.
    func yAllerPret() -> Bool {
        guard let depuis = ficheOuverteA else { return false }
        return horloge().timeIntervalSince(depuis) >= Self.delaiAvantYAller
    }

    /// Un toucher sur la carte : un lieu ouvre sa fiche (les avis du plan d'eau se lisent hors du thread principal).
    func ouvrir(_ element: ElementCarteUS) {
        switch element {
        case .point(let p):
            ouvertureEnCours += 1
            fiche = FicheUS.pour(point: p, agences: agences)
        case .planEau(let e):
            let source = source
            let agences = agences
            // Seul le dernier toucher compte : deux touchers rapprochés sur la goutte n'ouvrent pas deux fiches.
            ouvertureEnCours += 1
            let numero = ouvertureEnCours
            Task {
                let f = await Task.detached(priority: .userInitiated) {
                    FicheUS.pour(plan: e, avis: source.avis(etat: e.etat), agences: agences)
                }.value
                if numero == self.ouvertureEnCours { self.fiche = f }
            }
        case .groupe:
            break
        }
    }
}
