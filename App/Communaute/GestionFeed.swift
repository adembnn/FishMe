import Foundation
import Observation

/// L'état d'une section du fil.
nonisolated struct EtatSection: Equatable {
    var publications: [PublicationFeed] = []
    var encore = false
    var charge = false
}

/// Ce que la personne doit lire en haut du fil. Jamais « lu » ni « envoyé » promis sans preuve.
nonisolated enum MessageFeed: Equatable {
    case iCloudIndisponible
    case horsLigne
    case iCloudPlein
    case profilRequis
    case echec
}

/// Le cerveau du fil : trois sections de 20, « voir plus », cache hors ligne, likes, signalement, blocage, suppression.
/// Tout CloudKit passe par `ServiceFeed`.
@MainActor
@Observable
final class GestionFeed {
    private(set) var sections: [SectionFeed: EtatSection] = [:]
    private(set) var contexte = ContexteFeed(monNom: nil)
    private(set) var message: MessageFeed?
    private(set) var enCours = false
    private(set) var bloques: Set<String> = []
    private(set) var masquees: Set<String> = []

    let service: any ServiceFeed
    private let cache: CacheFeed
    private let source: any SourceContexte
    private let adresseSignalement: String

    init(service: any ServiceFeed, cache: CacheFeed, source: any SourceContexte,
         adresseSignalement: String = CourrielSignalement.adresse) {
        self.service = service
        self.cache = cache
        self.source = source
        self.adresseSignalement = adresseSignalement
    }

    /// Le service réel (À brancher par A) : base publique du conteneur, cache sur disque, cache en mémoire si le disque refuse.
    static func reel(source: any SourceContexte) -> GestionFeed {
        let conteneur = (try? CacheFeed.creerConteneur()) ?? (try! CacheFeed.creerConteneur(enMemoire: true))
        let cache = CacheFeed(conteneur: conteneur, dossierImages: CacheFeed.dossierParDefaut())
        return GestionFeed(service: ServiceFeedCloudKit(), cache: cache, source: source)
    }

    /// Le lieu du spot, pour le sélecteur du « + » du fil.
    func lieuCourant() async -> ContexteLieu { await source.lieuCourant() }

    /// Décision de Titouan : publier et commenter exigent un profil 15 ans ou plus ; sinon le fil est en lecture seule.
    var peutPublier: Bool { contexte.monNom != nil && contexte.quinzeAns }

    func etat(_ section: SectionFeed) -> EtatSection { sections[section] ?? EtatSection() }

    // MARK: Lecture

    /// Au premier affichage : le cache d'abord (instantané, lisible en mode avion), puis le réseau.
    func ouvrir() async {
        bloques = await cache.bloques()
        masquees = await cache.masquees()
        for section in SectionFeed.allCases where etat(section).publications.isEmpty {
            let gardees = await cache.lire(section: section)
            if !gardees.isEmpty { sections[section] = EtatSection(publications: gardees, encore: false, charge: true) }
        }
        await actualiser()
    }

    /// Tirer pour rafraîchir : reprend la première page de chaque section.
    func actualiser() async {
        enCours = true
        defer { enCours = false }
        contexte = ContexteFeed(monNom: await source.monNom(), quinzeAns: await source.profilQuinzeAnsOuPlus(), clubs: await source.mesClubs(),
                                amis: await source.nomsDesAmis(), departements: await source.departementsDeMaRegion())
        guard await service.compteDisponible() else {
            message = .iCloudIndisponible
            return
        }
        message = nil
        for section in SectionFeed.allCases {
            await charger(section, plus: false)
        }
    }

    func voirPlus(_ section: SectionFeed) async {
        await charger(section, plus: true)
    }

    private func charger(_ section: SectionFeed, plus: Bool) async {
        let valeurs = contexte.valeurs(pour: section)
        guard !valeurs.isEmpty else {
            sections[section] = EtatSection(publications: [], encore: false, charge: true)
            return
        }
        let avant = plus ? etat(section).publications.last?.creeLe : nil
        do {
            let page = try await service.page(DemandeSection(section: section, valeurs: valeurs, avant: avant))
            var recues = visibles(page.publications, section: section)
            let comptes = (try? await service.likes(de: recues.map(\.id))) ?? [:]
            for i in recues.indices {
                let auteurs = comptes[recues[i].id] ?? []
                recues[i].nbLikes = auteurs.count
                recues[i].aime = contexte.monNom.map { auteurs.contains($0) } ?? false
            }
            let base = plus ? etat(section).publications : []
            let connus = Set(base.map(\.id))
            sections[section] = EtatSection(publications: base + recues.filter { !connus.contains($0.id) }, encore: page.encore, charge: true)
            await cache.enregistrer(recues, section: section, remplacer: !plus)
        } catch let erreur as ErreurFeed {
            // Hors ligne ou en échec : le dernier fil lu reste affiché.
            message = Self.message(pour: erreur)
            if etat(section).publications.isEmpty {
                let gardees = await cache.lire(section: section)
                sections[section] = EtatSection(publications: gardees, encore: false, charge: true)
            }
        } catch {
            message = .echec
        }
    }

    private func visibles(_ publications: [PublicationFeed], section: SectionFeed? = nil) -> [PublicationFeed] {
        publications.filter { p in
            if bloques.contains(p.auteurNom) || masquees.contains(p.id) { return false }
            // R2: décision de Titouan (19 oct.), à réaligner avec Adem : « aucun lieu » ne paraît jamais dans « Dans ta région ».
            if section == .region, p.lieuMode == .aucun || p.departement.isEmpty { return false }
            return true
        }
    }

    private static func message(pour erreur: ErreurFeed) -> MessageFeed {
        switch erreur {
        case .reseau: .horsLigne
        case .iCloudIndisponible: .iCloudIndisponible
        case .iCloudPlein: .iCloudPlein
        default: .echec
        }
    }

    // MARK: Publier

    /// Publie, puis recharge. Le brouillon doit venir de `ModelePublication`, qui a déjà filtré la légende.
    func publier(_ brouillon: BrouillonPublication) async throws {
        guard FiltreTexte.verifier(brouillon.legende) == nil else { throw ErreurFeed.refuse }
        do {
            _ = try await service.publier(brouillon)
        } catch let erreur as ErreurFeed {
            message = Self.message(pour: erreur)
            throw erreur
        }
        await actualiser()
    }

    // MARK: Likes

    /// Un `Like` par personne et par publication ; le compte se relit depuis la requête, jamais d'un compteur.
    func basculerLike(_ publication: PublicationFeed) async {
        guard let moi = contexte.monNom, contexte.quinzeAns else {
            message = .profilRequis
            return
        }
        let aimait = publication.aime
        majPublication(publication.id) {
            $0.aime = !aimait
            $0.nbLikes = max(0, $0.nbLikes + (aimait ? -1 : 1))
        }
        do {
            if aimait {
                try await service.nePlusAimer(publication: publication.id, par: moi)
            } else {
                try await service.aimer(publication: publication.id, par: moi)
            }
        } catch {
            // Échec : on remet l'état d'avant.
            majPublication(publication.id) {
                $0.aime = aimait
                $0.nbLikes = max(0, $0.nbLikes + (aimait ? 1 : -1))
            }
            message = .horsLigne
        }
    }

    private func majPublication(_ id: String, _ changement: (inout PublicationFeed) -> Void) {
        for section in SectionFeed.allCases {
            guard var etat = sections[section], let i = etat.publications.firstIndex(where: { $0.id == id }) else { continue }
            changement(&etat.publications[i])
            sections[section] = etat
        }
    }

    // MARK: Modération

    /// Masque tout de suite sur cet iPhone, écrit le `Signalement`, rend l'e-mail prérempli à envoyer.
    @discardableResult
    func signaler(_ publication: PublicationFeed, motif: MotifSignalementPublication) async -> URL? {
        let s = SignalementFeed(cible: publication.id, typeCible: .publication, motif: motif,
                                signalePar: contexte.monNom ?? "anonyme", auteurCible: publication.auteurNom)
        await masquer(publication.id)
        try? await service.signaler(s)
        return CourrielSignalement.url(s, adresse: adresseSignalement)
    }

    @discardableResult
    func signaler(_ commentaire: CommentaireFeed, motif: MotifSignalementPublication) async -> URL? {
        let s = SignalementFeed(cible: commentaire.id, typeCible: .commentaire, motif: motif,
                                signalePar: contexte.monNom ?? "anonyme", auteurCible: commentaire.auteurNom)
        await masquer(commentaire.id)
        try? await service.signaler(s)
        return CourrielSignalement.url(s, adresse: adresseSignalement)
    }

    /// Le contenu disparaît tout de suite de cet iPhone seulement.
    func masquer(_ id: String) async {
        masquees.insert(id)
        retirerDesSections { $0.id == id }
        await cache.masquer(id)
    }

    /// Plus rien de cet auteur : fil, commentaires, cache. Le blocage vit sur l'iPhone ; la base privée en garde une copie.
    func bloquer(_ auteur: String) async {
        bloques.insert(auteur)
        retirerDesSections { $0.auteurNom == auteur }
        await cache.bloquer(auteur)
        try? await service.bloquer(auteur)
    }

    func estVisible(_ commentaire: CommentaireFeed) -> Bool {
        !bloques.contains(commentaire.auteurNom) && !masquees.contains(commentaire.id)
    }

    func estMienne(_ auteurNom: String) -> Bool {
        contexte.monNom == auteurNom
    }

    private func retirerDesSections(_ test: (PublicationFeed) -> Bool) {
        for section in SectionFeed.allCases {
            guard var etat = sections[section] else { continue }
            etat.publications.removeAll(where: test)
            sections[section] = etat
        }
    }

    // MARK: Suppression

    func supprimer(_ publication: PublicationFeed) async {
        retirerDesSections { $0.id == publication.id }
        await cache.retirer(publication.id)
        do {
            try await service.supprimerPublication(publication.id)
        } catch {
            message = .echec
            await actualiser()
        }
    }

    /// Pour `EffaceurContenu` (L21, composé par A) : efface tout ce que j'ai publié, commenté et aimé, puis le cache.
    func effacerMesContenus() async throws {
        guard let moi = contexte.monNom ?? (await source.monNom()) else { return }
        try await service.supprimerContenus(de: moi)
        await cache.effacerLeFil()
        for section in SectionFeed.allCases { sections[section] = EtatSection() }
    }
}
