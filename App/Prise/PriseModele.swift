import Core
import Foundation
import Observation
import UIKit

/// Où en est le pêcheur dans l'écran Prise.
enum PriseEtape: Equatable {
    case photo
    case lecture
    case propositions
    case grille(classe: String?)
    case sosies(EspecePechable)
    case stade
    case taille
    case resultat
}

/// L'état de l'écran Prise. L'IA propose, le pêcheur confirme, `Core` décide : ce modèle ne calcule aucune règle.
@MainActor
@Observable
final class PriseModele {
    let services: PriseServices
    let contexte: PriseContexte
    let terminer: (PriseConfirmee?) -> Void

    private(set) var etape: PriseEtape = .photo
    private(set) var photo: Data?
    private(set) var imagePhoto: UIImage?
    private(set) var catalogue: [EspecePechable] = []
    private(set) var proches: [EspeceProche] = []
    private(set) var propositions: [Proposition] = []
    private(set) var exemple = false

    /// L'espèce confirmée (touchée par le pêcheur). `nil` tant qu'il n'a pas confirmé.
    private(set) var especeConfirmee: EspecePechable?
    private(set) var stade: StadeAnguille?

    var longueurCm: Double = 40
    /// Valeur lue sur la toise, pour savoir si le pêcheur a gardé la valeur pré-réglée.
    private(set) var longueurLue: Double?
    private(set) var tailleConfirmee = false
    var gardee = false
    private(set) var toise: ToiseCalibrage?
    private(set) var toiseImage: UIImage?
    private(set) var toiseIntrouvable = false
    /// Fourchette de la dernière mesure en réalité augmentée validée (aucune position du monde n'est gardée).
    private(set) var mesureAR: PlageMesureAR?

    init(services: PriseServices, contexte: PriseContexte, terminer: @escaping (PriseConfirmee?) -> Void) {
        self.services = services
        self.contexte = contexte
        self.terminer = terminer
        self.catalogue = services.especes.especesPechables()
        self.proches = services.especes.especesProches(contexte.coordonnee)
    }

    // MARK: Photo et reconnaissance

    func photoPrise(_ image: UIImage, exemple: Bool = false) {
        let droite = image.priseRedressee()
        guard let data = droite.jpegData(compressionQuality: 0.85) else { ouvrirLaGrille(); return }
        photo = data
        imagePhoto = droite
        self.exemple = exemple
        etape = .lecture
        Task { await identifier(data) }
    }

    private func identifier(_ data: Data) async {
        let resultat = await services.identification.identifier(photo: data)
        switch resultat {
        case .scores(let scores):
            let a = services.especes.classer(scores: scores, especesProches: proches.map { $0.espece })
            if a.isEmpty { ouvrirLaGrille() } else { propositions = a; etape = .propositions }
        case .grille:
            ouvrirLaGrille()
        }
    }

    // MARK: Choix de l'espèce

    func ouvrirLaGrille(classe: String? = nil) { etape = .grille(classe: classe) }

    func toucher(_ proposition: Proposition) {
        switch proposition.type {
        case .espece(let e):
            if let entree = catalogue.first(where: { $0.espece == e }) { choisir(entree) } else { ouvrirLaGrille() }
        case .classe(let nom): ouvrirLaGrille(classe: nom)
        case .autreEspece: ouvrirLaGrille()
        case .pasUnPoisson: terminer(nil)
        }
    }

    /// Le pêcheur touche une espèce : anguille, d'abord son stade ; sosies coûteux, d'abord les sosies côte à côte.
    func choisir(_ entree: EspecePechable) {
        if PriseLogique.estAnguille(entree.espece) { etape = .stade; return }
        if PriseLogique.demandeSosies(entree) { etape = .sosies(entree); return }
        confirmer(entree)
    }

    /// Un toucher sur l'espèce, après les sosies ou le stade : c'est la confirmation.
    func confirmer(_ entree: EspecePechable) {
        especeConfirmee = entree
        stade = PriseLogique.stade(de: entree.espece)
        tailleConfirmee = false
        etape = .taille
    }

    func jeNeSaisPas() { terminer(nil) }

    func retourAuxPropositions() { etape = propositions.isEmpty ? .grille(classe: nil) : .propositions }

    // MARK: Taille

    func photoToise(_ image: UIImage) {
        let droite = image.priseRedressee()
        toiseImage = droite
        toise = nil
        toiseIntrouvable = false
        Task {
            let calibrage = await ToiseLecteur.calibrer(image: droite)
            toise = calibrage
            toiseIntrouvable = (calibrage == nil)
        }
    }

    /// Le pêcheur touche le bout de la queue sur la photo de la toise (point en pixels de l'image).
    func boutDeLaQueue(_ point: CGPoint) {
        guard let toise else { return }
        let cm = toise.longueurCm(boutDeLaQueue: point).rounded()
        guard PriseLogique.plageTaille.contains(cm) else { return }
        longueurLue = cm
        longueurCm = cm
    }

    /// Le pêcheur valide la mesure en réalité augmentée : la longueur devient le centre de la fourchette.
    func mesureARValidee(_ plage: PlageMesureAR) {
        let centre = min(max(Double(plage.centreCm), PriseLogique.plageTaille.lowerBound), PriseLogique.plageTaille.upperBound)
        mesureAR = plage
        longueurLue = nil
        longueurCm = centre
    }

    /// La fourchette n'est montrée que tant que la longueur est celle mesurée ; le curseur la fait tomber.
    var plageAR: PlageMesureAR? {
        guard let m = mesureAR, longueurCm.rounded() == min(max(Double(m.centreCm), PriseLogique.plageTaille.lowerBound), PriseLogique.plageTaille.upperBound) else { return nil }
        return m
    }

    /// « ≈ 1,6 à 2,0 kg, estimé », calculé aux deux bornes de la fourchette.
    var textePoidsAR: String? {
        guard let entree = especeConfirmee, let plage = plageAR,
              let bas = services.especes.poidsEstime(espece: entree.espece, longueurCm: Double(plage.basCm)),
              let haut = services.especes.poidsEstime(espece: entree.espece, longueurCm: Double(plage.hautCm)) else { return nil }
        return MesureARCalcul.textePoids(minKilos: bas.kilos, maxKilos: haut.kilos)
    }

    func confirmerLaTaille() {
        tailleConfirmee = true
        etape = .resultat
    }

    /// `.estimee` tant que la longueur est celle mesurée en réalité augmentée (jamais de verdict), `.toise` tant que le pêcheur garde la valeur lue sur la toise, sinon `.saisie`.
    var methode: MethodeMesure {
        if plageAR != nil { return .estimee }
        if let lue = longueurLue, lue == longueurCm.rounded() { return .toise }
        return .saisie
    }

    // MARK: Résultat, tout vient de Core

    /// Avant la confirmation de l'espèce et de la taille : rien de calculé, seulement « relâche-la ».
    var controle: ResultatControle? {
        guard let entree = especeConfirmee, tailleConfirmee else { return nil }
        return services.regles.controle(espece: entree.espece, tailleCm: longueurCm.rounded(), mesure: methode,
                                        date: contexte.date, lieu: contexte.lieu, prisesDuJour: contexte.prisesDuJour)
    }

    var poids: PoidsEstime? {
        guard let entree = especeConfirmee, tailleConfirmee else { return nil }
        return services.especes.poidsEstime(espece: entree.espece, longueurCm: longueurCm.rounded())
    }

    func ranger() {
        guard let entree = especeConfirmee, let photo else { terminer(nil); return }
        let prise = Prise(espece: entree.espece, longueurCm: longueurCm.rounded(), mesure: methode, stade: stade,
                          date: contexte.date, lieuFlou: contexte.lieuFlou, cheminPhoto: nil, gardee: gardee, exemple: exemple)
        terminer(PriseConfirmee(prise: prise, photo: photo))
    }
}
