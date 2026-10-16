import Foundation
import Observation
import Core

/// Ce que A passe au départ. La coordonnée est la position accordée, sinon le point touché sur la carte :
/// jamais un département entier. `nil` : la session demande de toucher un point.
struct ContexteDepart {
    var coordonnee: Coordonnee?
    var departement: Departement
    /// Le spot de `spotPropose`, ou celui que le pêcheur a pris avec « changer de spot » (L2) ; `nil` si aucun n'a été choisi.
    var spotChoisi: Spot?
    var abonne: Bool
    /// Instantané des conditions de L12 au départ (ou rien).
    var conditions: Conditions?

    init(coordonnee: Coordonnee?, departement: Departement, spotChoisi: Spot? = nil, abonne: Bool = false, conditions: Conditions? = nil) {
        self.coordonnee = coordonnee
        self.departement = departement
        self.spotChoisi = spotChoisi
        self.abonne = abonne
        self.conditions = conditions
    }
}

enum ResultatDepart: Equatable {
    /// La session tourne ; A ouvre la carte « à essayer » de L13 maintenant.
    case demarree
    /// Pas de coordonnée connue : demander de toucher son point sur la carte.
    case pointAToucher
    /// Un autre spot que le spot gratuit, sans abonnement : A ouvre le paywall de L6, qui bloque.
    case paywallQuiBloque
    case dejaEnCours
}

/// Ce que L5 rend à la fin : la `Sortie` terminée pour L4 (carte bredouille s'il n'y a aucune prise) et le paywall à ouvrir.
struct FinDeSession: Equatable {
    var sortie: Sortie
    /// `.quiSeFerme` à la fin de la 1re session : A ouvre le paywall de L6 après la carte, il se ferme.
    var paywall: ModePaywall
    /// Non nil quand la session s'est close d'elle-même (« Session terminée à la fin légale ») : à montrer au pêcheur.
    var message: String? = nil
}

@MainActor @Observable
final class SuiviSession {
    private(set) var enCours: SessionEnCours?
    private(set) var derniereFin: FinDeSession?
    private(set) var spotGratuit: Spot?
    private var fichier: FichierSession

    /// A le met à jour quand l'abonnement change.
    var abonne = false
    /// Rappelé à la fin, au bouton comme à la fin légale ou à la reprise après la fin légale.
    @ObservationIgnored var surFin: ((FinDeSession) -> Void)?

    @ObservationIgnored private let session: ServiceSession
    @ObservationIgnored private let soleil: ServiceSoleil
    @ObservationIgnored private let horloge: Horloge
    @ObservationIgnored private let stockage: StockageSession
    @ObservationIgnored private let coffre: CoffreSpotGratuit
    @ObservationIgnored private let calendrier: Calendar

    init(session: ServiceSession, soleil: ServiceSoleil, horloge: Horloge = HorlogeSysteme(),
         stockage: StockageSession = StockageFichier(), coffre: CoffreSpotGratuit,
         calendrier: Calendar = .current) {
        self.session = session
        self.soleil = soleil
        self.horloge = horloge
        self.stockage = stockage
        self.coffre = coffre
        self.calendrier = calendrier
        self.fichier = stockage.charger()
        self.enCours = fichier.enCours
        self.spotGratuit = coffre.lire()
    }

    // MARK: Lecture

    var sessionsTerminees: Int { fichier.sessionsTerminees }

    /// Pour « tes conditions » de L12 : sorties terminées, sans coordonnée exacte.
    var sortiesTerminees: [Sortie] { fichier.terminees }

    var nombrePrises: Int { enCours?.sortie.prises.count ?? 0 }

    func maintenant() -> Date { horloge.maintenant() }

    /// Durée écoulée à l'heure donnée : calculée depuis l'heure de départ, jamais un compteur qui s'arrête en arrière-plan.
    func duree(a date: Date) -> TimeInterval {
        guard let c = enCours else { return 0 }
        var fin = date
        if let legale = c.finLegale, legale > c.sortie.debut { fin = min(fin, legale) }
        return max(0, fin.timeIntervalSince(c.sortie.debut))
    }

    /// Prises gardées du jour (toutes sessions du jour), exemples exclus.
    func prisesGardeesDuJour() -> [Prise] {
        let maintenant = horloge.maintenant()
        return fichier.prisesGardees.filter { calendrier.isDate($0.date, inSameDayAs: maintenant) }
    }

    /// Le quota vient de `Core` : jamais recalculé ici.
    func quotaDuJour() -> QuotaDuJour {
        session.quota(prisesGardeesDuJour: prisesGardeesDuJour(), departement: enCours?.departement ?? .inconnu)
    }

    var quotaAtteint: Bool {
        guard enCours != nil else { return false }
        let q = quotaDuJour()
        guard let plafond = q.plafond else { return false }
        return q.gardees >= plafond
    }

    // MARK: Départ

    @discardableResult
    func commencer(_ contexte: ContexteDepart) -> ResultatDepart {
        guard enCours == nil else { return .dejaEnCours }
        guard let coordonnee = contexte.coordonnee else { return .pointAToucher }
        let maintenant = horloge.maintenant()
        abonne = contexte.abonne

        let courant = Spot(centre: coordonnee, departement: contexte.departement)
        let decision = session.acces(sessionsTerminees: fichier.sessionsTerminees, spot: courant,
                                     spotGratuit: spotGratuit, abonne: contexte.abonne)
        if !decision.sessionPermise || decision.paywall == .quiBloque { return .paywallQuiBloque }

        // Le spot se fixe au départ de la 1re session (toujours permise), puis ne bouge plus.
        if spotGratuit == nil {
            let fixe = contexte.spotChoisi ?? decision.spotGratuit ?? courant
            coffre.ecrire(fixe)
            spotGratuit = fixe
        }

        let finLegale = soleil.finLegale(date: maintenant, coordonnee: coordonnee)
        var messages: [String] = []
        // Fermée à cette heure : la session démarre quand même (relecteur de nuit), avec le message.
        if let finLegale, finLegale <= maintenant { messages.append("pêche fermée à cette heure") }
        if let message = decision.message {
            messages.append(message)
        } else if contexte.departement.estInconnu {
            messages.append("hors de France : aucune règle française")
        }

        enCours = SessionEnCours(
            sortie: Sortie(debut: maintenant, conditions: contexte.conditions.map { [$0] } ?? []),
            finLegale: finLegale, departement: contexte.departement, messages: messages)
        derniereFin = nil
        sauver()
        return .demarree
    }

    // MARK: Pendant

    /// Une prise confirmée de L3, gardée ou relâchée, avec l'instantané des conditions du moment (ou rien).
    func ajouter(prise: Prise, conditions: Conditions? = nil) {
        guard var c = enCours else { return }
        c.sortie.prises.append(prise)
        if prise.gardee && !prise.exemple && !prise.estDeclaree {
            c.sortie.gardeesParEspece[prise.espece.id, default: 0] += 1
            fichier.prisesGardees.append(prise)
        }
        if let conditions { c.sortie.conditions.append(conditions) }
        enCours = c
        sauver()
    }

    /// À appeler à chaque seconde affichée et à la réouverture : termine à la fin légale.
    func verifierFin() {
        guard let c = enCours, let legale = c.finLegale, legale > c.sortie.debut else { return }
        if horloge.maintenant() >= legale { cloturer(a: legale, message: "Session terminée à la fin légale") }
    }

    func terminer() {
        guard enCours != nil else { return }
        cloturer(a: horloge.maintenant())
    }

    /// A l'appelle après avoir montré la fin (carte, puis paywall).
    func acquitterFin() { derniereFin = nil }

    private func cloturer(a fin: Date, message: String? = nil) {
        guard var c = enCours else { return }
        c.sortie.fin = fin
        let ancien = fichier.sessionsTerminees

        var paywall = ModePaywall.aucun
        if let spot = spotGratuit {
            paywall = session.acces(sessionsTerminees: ancien + 1, spot: spot, spotGratuit: spot, abonne: abonne).paywall
        }
        // Décidé par Adem le 15 oct. : la fin de la 1re session ouvre le paywall, qui se ferme.
        if paywall == .aucun && ancien == 0 && !abonne { paywall = .quiSeFerme }
        if abonne { paywall = .aucun }

        fichier.terminees.append(c.sortie)
        fichier.sessionsTerminees = ancien + 1
        fichier.enCours = nil
        enCours = nil
        let fini = FinDeSession(sortie: c.sortie, paywall: paywall, message: message)
        derniereFin = fini
        ecrire()
        surFin?(fini)
    }

    // MARK: Reprise

    /// À l'ouverture de l'app : retrouve la session ; si la fin légale est passée, elle est déjà terminée.
    func reprendre() {
        fichier = stockage.charger()
        enCours = fichier.enCours
        spotGratuit = coffre.lire() ?? spotGratuit
        verifierFin()
    }

    // MARK: Fichier

    private func sauver() {
        fichier.enCours = enCours
        ecrire()
    }

    private func ecrire() {
        let limite = horloge.maintenant().addingTimeInterval(-3 * 86_400)
        fichier.prisesGardees.removeAll { $0.date < limite }
        stockage.ecrire(fichier)
    }
}
