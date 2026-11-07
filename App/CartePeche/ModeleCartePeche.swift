import Combine
import Core
import PDFKit
import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Ce que l'écran montre d'une carte importée : l'image, ou la première page d'un PDF rendue en image.
enum ApercuCarte {
    static func image(donnees: Data, genre: GenreFichierCarte) -> UIImage? {
        switch genre {
        case .image:
            return UIImage(data: donnees)
        case .pdf:
            guard let document = PDFDocument(data: donnees), let page = document.page(at: 0) else { return nil }
            return page.thumbnail(of: CGSize(width: 900, height: 1300), for: .mediaBox)
        }
    }
}

/// Le chef d'orchestre de « Ma carte de pêche ». Le dépôt, le notifieur et l'horloge sont injectés :
/// les tests d'app tournent avec un faux dépôt et un faux notifieur, jamais le vrai centre de notifications.
@MainActor
final class ModeleCartePeche: ObservableObject {
    /// L'heure locale du rappel.
    static let heureDuRappel = 9

    @Published private(set) var fiche: FicheCartePeche?
    @Published private(set) var apercu: UIImage?
    /// Le contenu du fichier, pour le plein écran.
    @Published private(set) var donneesFichier: Data?
    /// Un message d'erreur d'import ou d'enregistrement.
    @Published var message: String?
    /// Les erreurs de saisie de la dernière modification refusée.
    @Published private(set) var erreursSaisie: [ErreurFiche] = []
    /// Vrai quand iOS a refusé les notifications : l'écran montre le lien vers les réglages.
    @Published private(set) var notificationsCoupees = false
    /// Ex. « Moins de 30 jours : pas de rappel, ta carte expire dans 10 jours. »
    @Published private(set) var messageRappel: String?

    /// La langue de la région, posée par l'écran : les textes du rappel et de l'état suivent cette langue.
    /// Français par défaut (les tests comparent les textes français).
    var locale = Locale(identifier: "fr_FR")

    private let depot: any DepotCartePeche
    private let notifieur: any NotifieurCartePeche
    private let calendrier: Calendar
    private let aujourdhui: @Sendable () -> JourCivil

    init(depot: any DepotCartePeche,
         notifieur: any NotifieurCartePeche,
         calendrier: Calendar = .current,
         aujourdhui: (@Sendable () -> JourCivil)? = nil) {
        self.depot = depot
        self.notifieur = notifieur
        self.calendrier = calendrier
        self.aujourdhui = aujourdhui ?? { JourCivil(date: Date(), calendrier: calendrier) }
    }

    /// Le modèle réel : dépôt dans `Application Support`, vrai centre de notifications.
    static func reel() -> ModeleCartePeche {
        ModeleCartePeche(depot: DepotCarteFichiers.reel(), notifieur: NotifieurCartePecheSysteme())
    }

    // MARK: Lecture

    var jourDAujourdhui: JourCivil { aujourdhui() }

    var etat: EtatCartePeche? {
        fiche.map { EtatCartePeche.calculer(expireLe: $0.expireLe, aujourdhui: aujourdhui()) }
    }

    var libelleEtat: String? {
        guard let fiche, let etat else { return nil }
        return etat.libelle(expireLe: fiche.expireLe, locale: locale)
    }

    func charger() {
        do {
            fiche = try depot.lire()
        } catch {
            fiche = nil
            message = TextesCartePeche.ficheIllisible
        }
        rechargerFichier()
    }

    private func rechargerFichier() {
        guard let fiche, let donnees = try? depot.lireDonnees(de: fiche) else {
            donneesFichier = nil
            apercu = nil
            return
        }
        donneesFichier = donnees
        apercu = ApercuCarte.image(donnees: donnees, genre: fiche.fichier.genre)
    }

    // MARK: Import

    /// Importe un fichier depuis une URL (sélecteur de fichiers) : accès sécurisé, taille vérifiée avant lecture.
    func importer(depuis url: URL) {
        let accede = url.startAccessingSecurityScopedResource()
        defer { if accede { url.stopAccessingSecurityScopedResource() } }
        if let taille = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, taille > FichierCarte.tailleMaxOctets {
            message = TextesCartePeche.fichierTropLourd
            return
        }
        guard let donnees = try? Data(contentsOf: url) else {
            message = TextesCartePeche.fichierIllisible
            return
        }
        let genre: GenreFichierCarte = (UTType(filenameExtension: url.pathExtension)?.conforms(to: .pdf) ?? false) ? .pdf : .image
        importer(donnees: donnees, genre: genre)
    }

    /// Importe un fichier déjà lu. Une photo est gardée en JPEG ; un PDF tel quel.
    /// Sur une carte déjà là, seul le fichier change : millésime, association, date et rappel restent.
    func importer(donnees: Data, genre: GenreFichierCarte) {
        message = nil
        guard donnees.count <= FichierCarte.tailleMaxOctets else {
            message = TextesCartePeche.fichierTropLourd
            return
        }
        var aGarder = donnees
        switch genre {
        case .image:
            guard let image = UIImage(data: donnees), let jpeg = image.jpegData(compressionQuality: 0.9) else {
                message = TextesCartePeche.fichierIllisible
                return
            }
            aGarder = jpeg
        case .pdf:
            guard let document = PDFDocument(data: donnees), document.pageCount > 0 else {
                message = TextesCartePeche.fichierIllisible
                return
            }
        }
        guard aGarder.count <= FichierCarte.tailleMaxOctets else {
            message = TextesCartePeche.fichierTropLourd
            return
        }

        let jour = aujourdhui()
        let id = fiche?.id ?? UUID()
        let fichier = FichierCarte(nom: "carte-\(UUID().uuidString.lowercased()).\(genre.extensionFichier)", genre: genre)
        let nouvelle: FicheCartePeche
        if var existante = fiche {
            existante.fichier = fichier
            nouvelle = existante
        } else {
            // Valeurs de départ : millésime de l'année, fin de l'année. Le pêcheur les corrige ensuite.
            let finDAnnee = JourCivil(annee: jour.annee, mois: 12, jour: 31) ?? jour
            nouvelle = FicheCartePeche(id: id, millesime: jour.annee, association: nil, expireLe: finDAnnee,
                                       rappelActif: false, fichier: fichier, ajouteeLe: jour)
        }
        do {
            try depot.enregistrer(nouvelle, donnees: aGarder)
        } catch ErreurDepotCarte.fichierTropLourd {
            message = TextesCartePeche.fichierTropLourd
            return
        } catch {
            message = TextesCartePeche.enregistrementImpossible
            return
        }
        fiche = nouvelle
        rechargerFichier()
    }

    // MARK: Modifications

    func changerMillesime(_ millesime: Int) async {
        await appliquer { $0.millesime = millesime }
    }

    func changerExpiration(_ jour: JourCivil) async {
        await appliquer { $0.expireLe = jour }
    }

    /// L'association est un champ libre et facultatif : un champ vide devient « aucune ».
    func changerAssociation(_ texte: String) {
        guard var courante = fiche else { return }
        let net = String(texte.trimmingCharacters(in: .whitespacesAndNewlines).prefix(80))
        let nouvelle: String? = net.isEmpty ? nil : net
        guard courante.association != nouvelle else { return }
        courante.association = nouvelle
        enregistrerFiche(courante)
    }

    /// Applique un changement de millésime ou de date : garde-fous de saisie, enregistrement,
    /// puis le rappel est annulé et reprogrammé s'il est actif.
    private func appliquer(_ changement: (inout FicheCartePeche) -> Void) async {
        guard var courante = fiche else { return }
        changement(&courante)
        let erreurs = ValidationFiche.verifier(millesime: courante.millesime, expireLe: courante.expireLe, aujourdhui: aujourdhui())
        erreursSaisie = erreurs
        guard erreurs.isEmpty else { return }
        enregistrerFiche(courante)
        if courante.rappelActif { await reprogrammer(courante) }
    }

    private func enregistrerFiche(_ nouvelle: FicheCartePeche) {
        do {
            try depot.enregistrer(nouvelle, donnees: nil)
            fiche = nouvelle
        } catch {
            message = TextesCartePeche.enregistrementImpossible
        }
    }

    // MARK: Rappel

    /// Le basculement de « Me prévenir 30 jours avant ». La permission d'iOS n'est demandée qu'ici, en passant à vrai.
    func basculerRappel(_ actif: Bool) async {
        guard var courante = fiche else { return }
        messageRappel = nil
        notificationsCoupees = false
        if !actif {
            await notifieur.annuler(id: courante.identifiantRappel)
            courante.rappelActif = false
            enregistrerFiche(courante)
            return
        }
        // Rien à programmer : on le dit, sans demander la permission.
        if let sans = RappelCartePeche.messageSansRappel(expireLe: courante.expireLe, aujourdhui: aujourdhui(), locale: locale) {
            messageRappel = sans
            return
        }
        guard await notifieur.demanderPermission() else {
            notificationsCoupees = true
            courante.rappelActif = false
            enregistrerFiche(courante)
            return
        }
        courante.rappelActif = true
        enregistrerFiche(courante)
        await reprogrammer(courante)
    }

    /// Annule puis reprogramme. Un jour de rappel déjà passé ne reprogramme rien et l'écran le dit.
    private func reprogrammer(_ courante: FicheCartePeche) async {
        await notifieur.annuler(id: courante.identifiantRappel)
        guard let jour = RappelCartePeche.jourDuRappel(expireLe: courante.expireLe, aujourdhui: aujourdhui()) else {
            // L'interrupteur redevient faux : rien n'est programmé, il ne doit pas dire le contraire.
            var sansRappel = courante
            sansRappel.rappelActif = false
            enregistrerFiche(sansRappel)
            messageRappel = RappelCartePeche.messageSansRappel(expireLe: courante.expireLe, aujourdhui: aujourdhui(), locale: locale)
            return
        }
        messageRappel = nil
        let programme = await notifieur.programmer(
            id: courante.identifiantRappel, jour: jour, heure: Self.heureDuRappel,
            titre: RappelCartePeche.titreLocalise(locale),
            corps: RappelCartePeche.corps(millesime: courante.millesime, expireLe: courante.expireLe, locale: locale))
        if !programme { messageRappel = TextesCartePeche.enregistrementImpossible }
    }

    /// « Rappel programmé pour le 01/12/2026 », ou `nil`.
    var jourDuRappelAffiche: String? {
        guard let fiche, fiche.rappelActif,
              let jour = RappelCartePeche.jourDuRappel(expireLe: fiche.expireLe, aujourdhui: aujourdhui()) else { return nil }
        if locale.language.languageCode?.identifier == "fr" { return TextesCartePeche.rappelProgramme + jour.texte }
        return AnglaisE.f("Rappel programmé pour le %@", locale, JourLocalise.texte(jour, locale))
    }

    // MARK: Suppression

    /// Efface la fiche, le fichier et la notification en attente.
    func supprimer() async {
        if let courante = fiche { await notifieur.annuler(id: courante.identifiantRappel) }
        do {
            try depot.supprimer()
            fiche = nil
            apercu = nil
            donneesFichier = nil
            messageRappel = nil
            erreursSaisie = []
        } catch {
            message = TextesCartePeche.enregistrementImpossible
        }
    }
}
