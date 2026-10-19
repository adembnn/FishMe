import Foundation

/// La règle : quel skin est disponible, à quelle date, pour qui.
public func statut(_ skin: Skin, dans contexte: ContexteSkin) -> StatutSkin {
    // Un défi terminé offre le skin à vie : sans Pro, hors saison.
    if contexte.defisTermines.contains(skin.id) { return .disponible }

    switch skin.origine {
    case .gagne(let critere):
        return contexte.progression.satisfait(critere) ? .disponible : .aGagner(critere)
    case .pro, .offertParDefi:
        return contexte.abonne ? .disponible : .apercuSeulement(raison: .proRequis)
    case .saison(_, let fenetre):
        guard fenetre.contient(contexte.date, calendrier: contexte.calendrier) else {
            return .horsSaison(revientLe: fenetre.prochaineOuverture(apres: contexte.date, calendrier: contexte.calendrier))
        }
        return contexte.abonne ? .disponible : .apercuSeulement(raison: .proRequis)
    }
}

/// Le décor gagné à montrer quand un autre n'est plus permis : `dernierGagne` (mémorisé par l'app) s'il est encore
/// disponible, sinon le décor gagné disponible le plus loin dans l'ordre, sinon le décor de départ. Jamais de fond vide.
public func dernierDecorGagne(dernierGagne: IdentifiantSkin?, dans contexte: ContexteSkin,
                              catalogue: [Skin] = CatalogueSkins.tous) -> IdentifiantSkin {
    func gagneDisponible(_ skin: Skin) -> Bool {
        if case .gagne = skin.origine, statut(skin, dans: contexte) == .disponible { return true }
        return false
    }
    if let id = dernierGagne, let skin = catalogue.first(where: { $0.id == id }), gagneDisponible(skin) { return id }
    if let skin = catalogue.filter(gagneDisponible).max(by: { $0.ordre < $1.ordre }) { return skin.id }
    return .parDefaut
}

/// L'identifiant à afficher réellement pour le choix enregistré `id` (c'est ce que l'app donne aussi au widget).
/// - Identifiant inconnu (réglage d'une version future) : le décor de départ.
/// - Skin permis : lui-même.
/// - Skin de saison dont la fenêtre est close, mais que le pêcheur peut encore appliquer (Pro) : il reste affiché
///   (décision 4 d'Adem, à confirmer) ; seul l'appliquer à nouveau attend le retour de la saison.
/// - Skin Pro dont l'abonnement a pris fin : le dernier décor gagné (`choisiActuel` s'il est encore bon).
/// - Décor gagné dont le critère n'est plus rempli : idem.
public func appliquable(_ id: IdentifiantSkin, choisiActuel: IdentifiantSkin?, dans contexte: ContexteSkin,
                        catalogue: [Skin] = CatalogueSkins.tous) -> IdentifiantSkin {
    guard let skin = catalogue.first(where: { $0.id == id }) else { return .parDefaut }
    switch statut(skin, dans: contexte) {
    case .disponible:
        return id
    case .horsSaison:
        if contexte.abonne { return id }
        return dernierDecorGagne(dernierGagne: choisiActuel, dans: contexte, catalogue: catalogue)
    case .apercuSeulement, .aGagner:
        return dernierDecorGagne(dernierGagne: choisiActuel, dans: contexte, catalogue: catalogue)
    }
}
