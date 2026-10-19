import Core
import CoreGraphics
import Foundation
import Testing
import UIKit
@testable import BuildChallenge

// Tests écrits, non exécutés (pas de Mac pendant l'écriture) : S les lance sur le Mac.

/// Faux dépôt en mémoire : jamais le disque réel.
nonisolated final class FauxDepotCartePeche: DepotCartePeche, @unchecked Sendable {
    private let verrou = NSLock()
    private var fiche: FicheCartePeche?
    private var fichiers: [String: Data] = [:]
    private(set) var suppressions = 0

    func lire() throws -> FicheCartePeche? { verrou.withLock { fiche } }

    func lireDonnees(de fiche: FicheCartePeche) throws -> Data {
        try verrou.withLock {
            guard let d = fichiers[fiche.fichier.nom] else { throw ErreurDepotCarte.illisible }
            return d
        }
    }

    func enregistrer(_ nouvelle: FicheCartePeche, donnees: Data?) throws {
        verrou.withLock {
            if let donnees { fichiers[nouvelle.fichier.nom] = donnees }
            fiche = nouvelle
        }
    }

    func supprimer() throws {
        verrou.withLock {
            fiche = nil
            fichiers = [:]
            suppressions += 1
        }
    }

    var nombreDeFichiers: Int { verrou.withLock { fichiers.count } }
}

/// Faux notifieur : garde les notifications en attente en mémoire.
nonisolated final class FauxNotifieurCartePeche: NotifieurCartePeche, @unchecked Sendable {
    struct Programmee: Equatable { var id: String; var jour: JourCivil; var heure: Int; var titre: String; var corps: String }

    private let verrou = NSLock()
    private var etat = (demandes: 0, programmees: [Programmee]())
    let reponse: Bool

    init(accorde: Bool = true) { reponse = accorde }

    var demandesDePermission: Int { verrou.withLock { etat.demandes } }
    var programmees: [Programmee] { verrou.withLock { etat.programmees } }

    func demanderPermission() async -> Bool {
        verrou.withLock { etat.demandes += 1 }
        return reponse
    }

    func programmer(id: String, jour: JourCivil, heure: Int, titre: String, corps: String) async -> Bool {
        verrou.withLock {
            etat.programmees.removeAll { $0.id == id }
            etat.programmees.append(Programmee(id: id, jour: jour, heure: heure, titre: titre, corps: corps))
        }
        return true
    }

    func annuler(id: String) async {
        verrou.withLock { etat.programmees.removeAll { $0.id == id } }
    }

    func enAttente() async -> [String] { verrou.withLock { etat.programmees.map(\.id) } }
}

@MainActor
struct ModeleCartePecheTests {
    private let aujourdhui = JourCivil(annee: 2026, mois: 10, jour: 19)!

    private func modele(depot: FauxDepotCartePeche = FauxDepotCartePeche(),
                        notifieur: FauxNotifieurCartePeche = FauxNotifieurCartePeche()) -> ModeleCartePeche {
        let jour = aujourdhui
        return ModeleCartePeche(depot: depot, notifieur: notifieur, aujourdhui: { jour })
    }

    private func jpeg() throws -> Data {
        let rendu = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 60))
        let image = rendu.image { contexte in
            UIColor.systemBlue.setFill()
            contexte.fill(CGRect(x: 0, y: 0, width: 40, height: 60))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    private func pdf(pages: Int = 3) -> Data {
        let rendu = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 300))
        return rendu.pdfData { contexte in
            for _ in 0..<pages { contexte.beginPage() }
        }
    }

    // MARK: Import

    @Test func importerUnePhotoCreeLaFicheAvecDesValeursDeDepart() throws {
        let m = modele()
        m.importer(donnees: try jpeg(), genre: .image)
        let fiche = try #require(m.fiche)
        #expect(fiche.millesime == 2026)
        #expect(fiche.expireLe == JourCivil(annee: 2026, mois: 12, jour: 31))
        #expect(fiche.association == nil)
        #expect(!fiche.rappelActif)
        #expect(fiche.fichier.genre == .image)
        #expect(fiche.fichier.nomEstSur)
        #expect(m.apercu != nil)
        #expect(m.message == nil)
    }

    @Test func unPDFDeTroisPagesGardeSonApercu() throws {
        let m = modele()
        m.importer(donnees: pdf(pages: 3), genre: .pdf)
        #expect(m.fiche?.fichier.genre == .pdf)
        #expect(m.apercu != nil)
        #expect(m.donneesFichier != nil)
    }

    @Test func unFichierTropLourdEstRefuse() {
        let depot = FauxDepotCartePeche()
        let m = modele(depot: depot)
        m.importer(donnees: Data(count: FichierCarte.tailleMaxOctets + 1), genre: .pdf)
        #expect(m.fiche == nil)
        #expect(m.message == "Fichier trop lourd. Prends une photo plus petite.")
        #expect(depot.nombreDeFichiers == 0)
    }

    @Test func unFichierIllisibleEstRefuse() {
        let m = modele()
        m.importer(donnees: Data("pas une image".utf8), genre: .image)
        #expect(m.fiche == nil)
        #expect(m.message == TextesCartePeche.fichierIllisible)
    }

    @Test func remplacerLeFichierGardeLesChamps() async throws {
        let m = modele()
        m.importer(donnees: try jpeg(), genre: .image)
        m.changerAssociation("AAPPMA test")
        await m.changerMillesime(2025)
        let avant = try #require(m.fiche)
        m.importer(donnees: pdf(pages: 1), genre: .pdf)
        let apres = try #require(m.fiche)
        #expect(apres.id == avant.id)
        #expect(apres.association == "AAPPMA test")
        #expect(apres.millesime == 2025)
        #expect(apres.fichier.genre == .pdf)
    }

    // MARK: Persistance

    @Test func uneNouvelleInstanceRetrouveLaFiche() throws {
        let depot = FauxDepotCartePeche()
        let premier = modele(depot: depot)
        premier.importer(donnees: try jpeg(), genre: .image)
        let second = modele(depot: depot)
        second.charger()
        #expect(second.fiche == premier.fiche)
        #expect(second.apercu != nil)
    }

    // MARK: Saisie

    @Test func l_associationVideDevientAucune() throws {
        let m = modele()
        m.importer(donnees: try jpeg(), genre: .image)
        m.changerAssociation("  AAPPMA test  ")
        #expect(m.fiche?.association == "AAPPMA test")
        m.changerAssociation("   ")
        #expect(m.fiche?.association == nil)
    }

    @Test func uneDateTropLointaineEstRefusee() async throws {
        let m = modele()
        m.importer(donnees: try jpeg(), genre: .image)
        let avant = try #require(m.fiche)
        await m.changerExpiration(try #require(JourCivil(annee: 2035, mois: 1, jour: 1)))
        #expect(m.fiche == avant)
        #expect(m.erreursSaisie.contains(.expirationTropLointaine))
    }

    @Test func lEtatSEcritSansVerdict() async throws {
        let m = modele()
        m.importer(donnees: try jpeg(), genre: .image)
        #expect(m.libelleEtat == "Jusqu'au 31/12/2026")
        await m.changerExpiration(aujourdhui.ajouter(jours: 12))
        #expect(m.libelleEtat == "Expire dans 12 jours")
        await m.changerMillesime(2025)
        await m.changerExpiration(aujourdhui.ajouter(jours: -5))
        #expect(m.libelleEtat == "Expirée le \(aujourdhui.ajouter(jours: -5).texte)")
        #expect(m.libelleEtat?.lowercased().contains("valide") == false)
    }

    // MARK: Rappel

    @Test func aucunePermissionAvantLeBasculement() async throws {
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 45))
        #expect(notifieur.demandesDePermission == 0)
        #expect(notifieur.programmees.isEmpty)
    }

    @Test func lePremierBasculementDemandeLaPermissionEtProgramme9h() async throws {
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        let expire = aujourdhui.ajouter(jours: 45)
        await m.changerExpiration(expire)
        await m.basculerRappel(true)
        #expect(notifieur.demandesDePermission == 1)
        let fiche = try #require(m.fiche)
        #expect(fiche.rappelActif)
        let programmee = try #require(notifieur.programmees.first)
        #expect(notifieur.programmees.count == 1)
        #expect(programmee.id == fiche.identifiantRappel)
        #expect(programmee.jour == aujourdhui.ajouter(jours: 15))
        #expect(programmee.heure == 9)
        #expect(programmee.titre == "Ta carte de pêche expire dans 30 jours")
        #expect(programmee.corps == "Millésime 2026 · expire le \(expire.texte).")
        #expect(await notifieur.enAttente() == [fiche.identifiantRappel])
    }

    @Test func unRefusRemetLInterrupteurAFaux() async throws {
        let notifieur = FauxNotifieurCartePeche(accorde: false)
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 45))
        await m.basculerRappel(true)
        #expect(m.fiche?.rappelActif == false)
        #expect(m.notificationsCoupees)
        #expect(notifieur.programmees.isEmpty)
    }

    @Test func moinsDeTrenteJoursAucunRappelEtUnMessage() async throws {
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 10))
        await m.basculerRappel(true)
        #expect(notifieur.demandesDePermission == 0)
        #expect(notifieur.programmees.isEmpty)
        #expect(m.fiche?.rappelActif == false)
        #expect(m.messageRappel == "Moins de 30 jours : pas de rappel, ta carte expire dans 10 jours.")
    }

    @Test func changerLaDateReprogramme() async throws {
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 45))
        await m.basculerRappel(true)
        await m.changerExpiration(aujourdhui.ajouter(jours: 60))
        #expect(notifieur.programmees.count == 1)
        #expect(notifieur.programmees.first?.jour == aujourdhui.ajouter(jours: 30))
        // La date devient trop proche : plus rien en attente, l'interrupteur redevient faux.
        await m.changerExpiration(aujourdhui.ajouter(jours: 5))
        #expect(notifieur.programmees.isEmpty)
        #expect(m.fiche?.rappelActif == false)
    }

    @Test func eteindreLInterrupteurAnnule() async throws {
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 45))
        await m.basculerRappel(true)
        await m.basculerRappel(false)
        #expect(notifieur.programmees.isEmpty)
        #expect(m.fiche?.rappelActif == false)
    }

    // MARK: Suppression

    @Test func supprimerEffaceFicheFichierEtNotification() async throws {
        let depot = FauxDepotCartePeche()
        let notifieur = FauxNotifieurCartePeche()
        let m = modele(depot: depot, notifieur: notifieur)
        m.importer(donnees: try jpeg(), genre: .image)
        await m.changerExpiration(aujourdhui.ajouter(jours: 45))
        await m.basculerRappel(true)
        #expect(notifieur.programmees.count == 1)
        await m.supprimer()
        #expect(m.fiche == nil)
        #expect(m.apercu == nil)
        #expect(try depot.lire() == nil)
        #expect(depot.nombreDeFichiers == 0)
        #expect(notifieur.programmees.isEmpty)
    }

    // MARK: Textes

    @Test func lesTextesNeDisentJamaisValideNiEnRegle() {
        let textes = [TextesCartePeche.nonOfficiel, TextesCartePeche.sauvegarde, TextesCartePeche.pleinEcranMention,
                      TextesCartePeche.vide, TextesCartePeche.rappelExplication, TextesCartePeche.confirmationMessage,
                      TextesMaFederation.reglesLocales, TextesMaFederation.mesureLegende, TextesMaFederation.mesureRepere]
        for texte in textes {
            let bas = texte.lowercased()
            #expect(!bas.contains("valide"))
            #expect(!bas.contains("en règle"))
            #expect(!bas.contains("poké"))
        }
        #expect(TextesCartePeche.pleinEcranMention == "Copie personnelle · pas une carte officielle")
    }

    @Test func leGuideDeMesureNAucuneTailleChiffree() {
        let tout = TextesMaFederation.mesureEtapes + [TextesMaFederation.mesureLegende, TextesMaFederation.mesureRepere,
                                                      TextesMaFederation.mesureDessin]
        for texte in tout {
            #expect(texte.range(of: #"[0-9]+ ?cm"#, options: .regularExpression) == nil)
            #expect(!texte.lowercased().contains("trop petit"))
        }
        #expect(TextesMaFederation.mesureEtapes.count == 3)
    }
}
