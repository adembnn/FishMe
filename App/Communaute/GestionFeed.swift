import Foundation
import MessageUI
import Observation

/// L'état d'une section du fil.
nonisolated struct EtatSection: Equatable {
    var publications: [PublicationFeed] = []
    var encore = false
    var charge = false
}

/// Ce que la personne doit lire en haut du fil. Jamais « signalé », « lu » ni « envoyé » promis sans preuve.
nonisolated enum MessageFeed: Equatable {
    case iCloudIndisponible
    case horsLigne
    case iCloudPlein
    case profilRequis
    case echec
    /// Fil d'exemple (mode démo, ou iPhone sans compte iCloud) : lecture seule.
    case modeExemple
    /// L'enregistrement `Signalement` a réussi (et lui seul).
    case signale
    /// L'écriture a échoué : le signalement attend dans la file de reprise.
    case signalementEnAttente
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
    /// Vrai : le fil montre les publications d'exemple (pas de compte iCloud, ou « Mode démo »). Lecture seule.
    private(set) var exemples = false

    /// Le service réel.
    private let reel: any ServiceFeed
    /// Le faux service du mode démo (`ServiceFeedExemple`). `nil` : pas de mode démo (tests).
    private let exemple: (any ServiceFeed)?
    private let cache: CacheFeed
    private let source: any SourceContexte
    private let adresseSignalement: String
    private let mailDisponible: @MainActor () -> Bool
    /// Par section : la date de la DERNIÈRE publication chargée (masquée ou non), pas de la dernière affichée.
    /// Sinon une page entière masquée ou bloquée rejouerait la même page à chaque « Voir plus ».
    private var curseurs: [SectionFeed: Date] = [:]

    /// Pages lues d'affilée quand une page entière est masquée, avant de rendre la main.
    static let pagesMaxParChargement = 5

    /// Le service que les écrans interrogent (commentaires, média) : l'exemple en mode démo, sinon le réel.
    var service: any ServiceFeed { exemples ? (exemple ?? reel) : reel }

    init(service: any ServiceFeed, cache: CacheFeed, source: any SourceContexte, exemple: (any ServiceFeed)? = nil,
         adresseSignalement: String = CourrielSignalement.adresse,
         mailDisponible: @escaping @MainActor () -> Bool = { MFMailComposeViewController.canSendMail() }) { // ⚠ à vérifier sur le Mac
        self.reel = service
        self.exemple = exemple
        self.cache = cache
        self.source = source
        self.adresseSignalement = adresseSignalement
        self.mailDisponible = mailDisponible
    }

    /// Le service réel (À brancher par A) : base publique du conteneur, cache sur disque, cache en mémoire si le disque refuse.
    /// Sans compte iCloud, ou en « Mode démo » (`SourceContexte.modeDemo`), le fil montre `ServiceFeedExemple`.
    static func reel(source: any SourceContexte) -> GestionFeed {
        let conteneur = (try? CacheFeed.creerConteneur()) ?? (try! CacheFeed.creerConteneur(enMemoire: true))
        let cache = CacheFeed(conteneur: conteneur, dossierImages: CacheFeed.dossierParDefaut())
        return GestionFeed(service: ServiceFeedCloudKit(), cache: cache, source: source, exemple: ServiceFeedExemple())
    }

    /// Le lieu du spot, pour le sélecteur du « + » du fil.
    func lieuCourant() async -> ContexteLieu { await source.lieuCourant() }

    /// Décision de Titouan : publier et commenter exigent un profil 15 ans ou plus (créé avec l'acceptation des conditions, L21) ;
    /// sinon le fil est en lecture seule. Les publications d'exemple sont toujours en lecture seule.
    var peutPublier: Bool { !exemples && contexte.monNom != nil && contexte.quinzeAns }

    func etat(_ section: SectionFeed) -> EtatSection { sections[section] ?? EtatSection() }

    // MARK: Lecture

    /// Au premier affichage : le cache d'abord (instantané, lisible en mode avion), les blocages de la base privée, puis le réseau.
    func ouvrir() async {
        bloques = await cache.bloques()
        masquees = await cache.masquees()
        for section in SectionFeed.allCases where etat(section).publications.isEmpty {
            let gardees = await cache.lire(section: section)
            if !gardees.isEmpty { sections[section] = EtatSection(publications: gardees, encore: false, charge: true) }
        }
        await synchroniserBlocages()
        guard !Task.isCancelled else { return }
        await actualiser()
    }

    /// Tirer pour rafraîchir : reprend la première page de chaque section.
    func actualiser() async {
        enCours = true
        defer { enCours = false }
        await chargerContexte()
        let demo = await source.modeDemo()
        let compte = await reel.compteDisponible()
        guard !Task.isCancelled else { return }
        let basculer = (demo || !compte) && exemple != nil
        if basculer != exemples {
            // Le fil change de nature : rien d'exemple ne reste dans le vrai fil, ni l'inverse.
            exemples = basculer
            sections = [:]
            curseurs = [:]
        }
        if exemples {
            message = .modeExemple
        } else {
            guard compte else {
                message = .iCloudIndisponible
                return
            }
            message = nil
            await rejouerLaFile()
        }
        for section in SectionFeed.allCases {
            await charger(section, plus: false)
        }
    }

    func voirPlus(_ section: SectionFeed) async {
        await charger(section, plus: true)
    }

    private func chargerContexte() async {
        contexte = ContexteFeed(monNom: await source.monNom(), quinzeAns: await source.profilQuinzeAnsOuPlus(), clubs: await source.mesClubs(),
                                amis: await source.nomsDesAmis(), departements: await source.departementsDeMaRegion())
    }

    private func charger(_ section: SectionFeed, plus: Bool) async {
        let valeurs = exemples ? ["exemple"] : contexte.valeurs(pour: section)
        guard !valeurs.isEmpty else {
            sections[section] = EtatSection(publications: [], encore: false, charge: true)
            curseurs[section] = nil
            return
        }
        var avant: Date?
        if plus {
            guard let curseur = curseurs[section] else { return }
            avant = curseur
        }
        let base = plus ? etat(section).publications : []
        var connus = Set(base.map(\.id))
        var nouvelles: [PublicationFeed] = []
        var encore = false
        var tentatives = 0
        do {
            repeat {
                let page = try await service.page(DemandeSection(section: section, valeurs: valeurs, avant: avant))
                // Le curseur est la plus ancienne publication REÇUE, qu'elle soit affichée ou non.
                let derniere = page.publications.map(\.creeLe).min()
                encore = page.encore && derniere != nil
                avant = derniere
                var recues = visibles(page.publications, section: section)
                let comptes: [String: [String]]
                do {
                    comptes = try await service.likes(de: recues.map(\.id))
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    comptes = [:]
                }
                for i in recues.indices {
                    let auteurs = comptes[recues[i].id] ?? []
                    recues[i].nbLikes = auteurs.count
                    recues[i].aime = contexte.monNom.map { auteurs.contains($0) } ?? false
                }
                nouvelles += recues.filter { connus.insert($0.id).inserted }
                tentatives += 1
                // Une page entièrement masquée ne laisse pas la section vide : on lit la suivante.
            } while nouvelles.isEmpty && encore && tentatives < Self.pagesMaxParChargement
            sections[section] = EtatSection(publications: base + nouvelles, encore: encore, charge: true)
            curseurs[section] = avant
            if !exemples { await cache.enregistrer(nouvelles, section: section, remplacer: !plus) }
        } catch is CancellationError {
            // L'écran a changé de page : ni erreur affichée, ni état à moitié écrit.
            return
        } catch let erreur as ErreurFeed {
            // Hors ligne ou en échec : le dernier fil lu reste affiché.
            message = Self.message(pour: erreur)
            if etat(section).publications.isEmpty, !exemples {
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
        case .lectureSeule: .modeExemple
        default: .echec
        }
    }

    // MARK: Publier

    /// Publie, puis recharge. Le brouillon doit venir de `ModelePublication`, qui a déjà filtré la légende.
    func publier(_ brouillon: BrouillonPublication) async throws {
        if contexte.monNom == nil { await chargerContexte() }
        // La règle vit aussi dans le modèle, pas seulement dans l'écran : 15 ans ou plus, profil créé, pas de fil d'exemple.
        guard peutPublier else { throw ErreurFeed.refuse }
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
        guard !exemples else {
            message = .modeExemple
            return
        }
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

    /// Masque tout de suite sur cet iPhone, écrit le `Signalement`, et dit la vérité : « signalé » seulement si l'écriture a réussi.
    /// Le texte signalé est joint à l'e-mail prérempli, rendu seulement si Mail est disponible.
    @discardableResult
    func signaler(_ publication: PublicationFeed, motif: MotifSignalementPublication) async -> IssueSignalement {
        let s = SignalementFeed(cible: publication.id, typeCible: .publication, motif: motif,
                                signalePar: contexte.monNom ?? "anonyme", auteurCible: publication.auteurNom, extrait: publication.legende)
        return await traiter(s)
    }

    @discardableResult
    func signaler(_ commentaire: CommentaireFeed, motif: MotifSignalementPublication) async -> IssueSignalement {
        let s = SignalementFeed(cible: commentaire.id, typeCible: .commentaire, motif: motif,
                                signalePar: contexte.monNom ?? "anonyme", auteurCible: commentaire.auteurNom, extrait: commentaire.texte)
        return await traiter(s)
    }

    private func traiter(_ s: SignalementFeed) async -> IssueSignalement {
        await masquer(s.cible)
        guard !exemples else {
            message = .modeExemple
            return .exemple
        }
        do {
            try await service.signaler(s)
            message = .signale
            return .enregistre(courriel: courriel(s))
        } catch {
            // Pas de trace écrite : on ne dit pas « signalé ». Le signalement attend sur disque et repart au prochain chargement.
            await cache.mettreEnFile(s)
            message = .signalementEnAttente
            return .pasEnregistre(courriel: courriel(s))
        }
    }

    /// L'e-mail prérempli, seulement si Mail peut s'ouvrir. Il n'est jamais dit « envoyé » : l'enregistrement est la trace sûre.
    private func courriel(_ s: SignalementFeed) -> URL? {
        mailDisponible() ? CourrielSignalement.url(s, adresse: adresseSignalement) : nil
    }

    /// Rejoue les signalements dont l'écriture avait échoué. S'arrête au premier échec (hors ligne) : ils restent dans la file.
    private func rejouerLaFile() async {
        for s in await cache.fileDeReprise() {
            do {
                try await reel.signaler(s)
                await cache.sortirDeLaFile(s.id)
            } catch {
                break
            }
        }
    }

    /// Le contenu disparaît tout de suite de cet iPhone seulement. En mode démo, rien n'est gardé sur disque.
    func masquer(_ id: String) async {
        masquees.insert(id)
        retirerDesSections { $0.id == id }
        if !exemples { await cache.masquer(id) }
    }

    /// Plus rien de cet auteur : fil, commentaires, cache. Le blocage vit sur l'iPhone ; la base privée en garde une copie,
    /// relue à l'ouverture (`synchroniserBlocages`).
    func bloquer(_ auteur: String) async {
        bloques.insert(auteur)
        retirerDesSections { $0.auteurNom == auteur }
        guard !exemples else { return }
        await cache.bloquer(auteur)
        // Échec (hors ligne) : la copie privée est renvoyée à la prochaine ouverture, car le blocage local reste.
        try? await reel.bloquer(auteur)
    }

    /// Relit les `Blocage` de la base privée (réinstallation, autre iPhone) et renvoie ceux qui n'y sont pas encore.
    private func synchroniserBlocages() async {
        guard let distants = try? await reel.blocagesPrives(), !Task.isCancelled else { return }
        let distantsSet = Set(distants)
        for nom in distantsSet.subtracting(bloques) {
            bloques.insert(nom)
            retirerDesSections { $0.auteurNom == nom }
            await cache.bloquer(nom)
        }
        for nom in bloques.subtracting(distantsSet) {
            try? await reel.bloquer(nom)
        }
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

    /// Pour `EffaceurFeed` (L21 : `EffaceurContenu`, composé par A) : efface tout ce que ce profil a publié, commenté et aimé,
    /// puis le cache. Lève une erreur si rien n'a pu être effacé : L21 garde alors le profil et la personne réessaie (5.1.1).
    func effacerContenu(deProfil profilID: String) async throws {
        let moi: String?
        if !profilID.isEmpty {
            moi = profilID
        } else if let connu = contexte.monNom {
            moi = connu
        } else {
            moi = await source.monNom()
        }
        guard let moi, !moi.isEmpty else { throw ErreurFeed.introuvable }
        try await reel.supprimerContenus(de: moi)
        await cache.effacerLeFil()
        for section in SectionFeed.allCases { sections[section] = EtatSection() }
        curseurs = [:]
    }

    /// Même chose avec le profil courant (nom gardé pour A, qui l'appelait ainsi).
    func effacerMesContenus() async throws {
        try await effacerContenu(deProfil: "")
    }
}

/// Le conformeur réel de L23 : `RegistreEffaceurs.partage.ajouter(EffaceurFeed(gestion: app.feed))` (A, `RootView.swift`).
nonisolated struct EffaceurFeed: EffaceurContenu {
    let gestion: GestionFeed

    func effacerContenu(deProfil profilID: String) async throws {
        try await gestion.effacerContenu(deProfil: profilID)
    }
}
