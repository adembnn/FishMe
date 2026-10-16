import Foundation
import Testing
import Core
@testable import BuildChallenge

private let maintenant = Date(timeIntervalSince1970: 1_792_065_600)

@MainActor
struct ResolveurEtatTests {
    @Test func accesSelonLeStatut() {
        #expect(ResolveurEtat.etat(statut: .abonne, maintenant: maintenant).donneAcces)
        #expect(ResolveurEtat.etat(statut: .delaiDeGrace(fin: nil), maintenant: maintenant).donneAcces)
        #expect(!ResolveurEtat.etat(statut: .relancePaiement, maintenant: maintenant).donneAcces)
        #expect(!ResolveurEtat.etat(statut: .expire, maintenant: maintenant).donneAcces)
        #expect(!ResolveurEtat.etat(statut: .rembourse, maintenant: maintenant).donneAcces)
        #expect(!ResolveurEtat.etat(statut: .revoque, maintenant: maintenant).donneAcces)
    }

    @Test func leDelaiDeGraceGardeSaDateOuPrendSeizeJours() {
        let fin = maintenant.addingTimeInterval(3 * 86_400)
        #expect(ResolveurEtat.etat(statut: .delaiDeGrace(fin: fin), maintenant: maintenant) == .delaiDeGrace(fin: fin))
        #expect(ResolveurEtat.etat(statut: .delaiDeGrace(fin: nil), maintenant: maintenant)
                == .delaiDeGrace(fin: maintenant.addingTimeInterval(16 * 86_400)))
    }

    @Test func plusieursAbonnementsLAccesOuvertGagne() {
        #expect(ResolveurEtat.etat(statuts: [.expire, .abonne], maintenant: maintenant) == .abonne)
        #expect(ResolveurEtat.etat(statuts: [], maintenant: maintenant) == .nonAbonne)
        #expect(ResolveurEtat.etat(statuts: [.expire, .rembourse], maintenant: maintenant) == .expire)
    }

    @Test func sansReseauLeDernierEtatVerifieSert() {
        #expect(ResolveurEtat.sansReseau(dernierEtat: .abonne) == .sansReseau(dernierEtatAbonne: true))
        #expect(ResolveurEtat.sansReseau(dernierEtat: .expire) == .sansReseau(dernierEtatAbonne: false))
        #expect(ResolveurEtat.sansReseau(dernierEtat: .sansReseau(dernierEtatAbonne: true)).donneAcces)
    }
}

@MainActor
struct OffresTests {
    private func offre(_ produit: String, _ centimes: Int, fondateur: Bool) -> OffreAffichee {
        OffreAffichee(produit: produit, prixCentimes: centimes, tarifFondateur: fondateur)
    }

    @Test func lAnnuelFondateurEstEnPremierEtLeMensuelSuitSiIlEstChoisi() {
        let sans = ProduitsMontres(offre: offre(IdentifiantsProduits.annuelFondateur, 3499, fondateur: true), mensuel: nil)
        #expect(sans.identifiants == [IdentifiantsProduits.annuelFondateur])
        let avec = ProduitsMontres(offre: offre(IdentifiantsProduits.annuelFondateur, 3499, fondateur: true), mensuel: IdentifiantsProduits.mensuel699)
        #expect(avec.identifiants == [IdentifiantsProduits.annuelFondateur, IdentifiantsProduits.mensuel699])
        #expect(avec.tarifFondateur)
    }

    @Test func apresLeTarifFondateurLeProduitMontreEstCeluiDeCore() {
        let apres = ProduitsMontres(offre: offre(IdentifiantsProduits.annuelApres, 4999, fondateur: false), mensuel: nil)
        #expect(apres.annuel == IdentifiantsProduits.annuelApres)
        #expect(!apres.tarifFondateur)
    }

    @Test func leMensuelRetenuNEstPasEncoreChoisi() {
        #expect(ChoixOffres.mensuelRetenu == nil)
    }

    @Test func dureeOfferteSeLitDansLOffre() {
        #expect(TextesPaywall.dureeOfferte(valeur: 1, unite: .semaine) == "1 semaine offerte")
        #expect(TextesPaywall.dureeOfferte(valeur: 2, unite: .semaine) == "2 semaines offertes")
        #expect(TextesPaywall.dureeOfferte(valeur: 7, unite: .jour) == "7 jours offerts")
    }

    @Test func essaiSeulementSiLeCompteYADroit() {
        #expect(TextesPaywall.essaiMensuel(valeur: 1, unite: .semaine, prixParMois: "6,99 €", eligible: true)
                == "1 semaine offerte, puis 6,99 € par mois")
        #expect(TextesPaywall.essaiMensuel(valeur: 1, unite: .semaine, prixParMois: "6,99 €", eligible: false) == nil)
    }

    @Test func phraseDeLancementLitLePrixApresOuLOmet() {
        let avec = TextesPaywall.phraseLancement(prixApres: "49,99 €")
        #expect(avec.contains("jusqu'au 31 décembre 2026"))
        #expect(avec.contains("Ensuite 49,99 € par an pour les nouveaux abonnés."))
        #expect(avec.contains("Tu gardes ton prix tant que tu restes abonné."))
        #expect(!TextesPaywall.phraseLancement(prixApres: nil).contains("Ensuite"))
    }

    @Test func aucunMotInterditDansLesTextes() {
        var textes = [TextesPaywall.renouvellement, TextesPaywall.produitIntrouvable, TextesPaywall.rienARestaurer, TextesPaywall.restaure]
        textes += TextesPaywall.comparaison.map(\.texte) + TextesPaywall.gratuit.map(\.texte) + TextesPaywall.pro.map(\.texte) + FonctionPro.allCases.map(TextesPaywall.titre)
        for texte in textes {
            let bas = texte.lowercased()
            #expect(!bas.contains("poké"))
            #expect(!bas.contains("1 mois"))
            #expect(!bas.contains("bon spot"))
            #expect(!bas.contains("meilleure heure"))
            #expect(!bas.contains("rareté"))
        }
        #expect(TextesPaywall.renouvellement.contains("24 h"))
    }

    @Test func laFonctionToucheePasseEnTeteEtLesAutresRestent() {
        for fonction in FonctionPro.allCases {
            let lignes = TextesPaywall.proEnTete(.fonction(fonction))
            #expect(lignes.count == TextesPaywall.pro.count)
            #expect(Set(lignes.map(\.texte)) == Set(TextesPaywall.pro.map(\.texte)))
        }
        #expect(TextesPaywall.proEnTete(.fonction(.septJours)).first?.texte == "7 jours heure par heure")
        #expect(TextesPaywall.proEnTete(.autreSpot).first?.texte == "Des sessions sur d'autres spots")
    }

    @Test func seuleLaFinDeLaPremiereSessionPrometDeContinuerGratuitement() {
        #expect(DeclencheurPaywall.finPremiereSession.texteFermeture.contains("gratuitement"))
        #expect(!DeclencheurPaywall.autreSpot.texteFermeture.contains("gratuitement"))
        #expect(!DeclencheurPaywall.fonction(.septJours).texteFermeture.contains("gratuitement"))
    }
}

/// Le paywall ne dit que ce que le code ferme : chaque ligne de la comparaison est confrontée à `peutUtiliser` de Core
/// (et à `RegleConseils` pour les conseils). Preuve du code : `MoteurSession.peutUtiliser`, `RootView.swift` (`autorise`, `VigilanceEmplacement`).
struct ComparaisonPaywallTests {
    let session = MoteurCore(donnees: .embarque()).session

    private func conseil(_ gratuit: Bool) -> Conseil {
        Conseil(texte: "x", icone: "fish", source: SourceRegle(titre: "essai"), gratuit: gratuit)
    }

    @Test func chaqueLigneDuPaywallDitLaVeriteDuCode() {
        for ligne in TextesPaywall.comparaison {
            switch ligne.verrou {
            case .libre:
                #expect(ligne.gratuit != .non)
            case .surTonSpot(let f):
                #expect(session.peutUtiliser(f, abonne: false, surSonSpot: true))
                #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: false))
                #expect(session.peutUtiliser(f, abonne: true, surSonSpot: false))
                #expect(ligne.gratuit != .non && ligne.gratuit != .oui)
            case .proSeul(let f):
                #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: true))
                #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: false))
                #expect(session.peutUtiliser(f, abonne: true, surSonSpot: false))
                #expect(ligne.gratuit == .non)
            case .partiel(let f):
                #expect(!session.peutUtiliser(f, abonne: false, surSonSpot: true))
                #expect(session.peutUtiliser(f, abonne: true, surSonSpot: false))
                let ferme = RegleConseils.affiches([conseil(true), conseil(false)], toutOuvert: false)
                #expect(ferme.visibles.count == 1 && ferme.nbCaches == 1)
                #expect(ligne.gratuit != .non && ligne.gratuit != .oui)
            }
            #expect(ligne.pro != .non)
        }
    }

    @Test func toutesLesFonctionsProDuCodeSontAnnoncees() {
        let annoncees = TextesPaywall.comparaison.compactMap { ligne -> FonctionPro? in
            switch ligne.verrou {
            case .libre: return nil
            case .surTonSpot(let f), .proSeul(let f), .partiel(let f): return f
            }
        }
        #expect(Set(annoncees) == Set(FonctionPro.allCases))
        #expect(annoncees.count == FonctionPro.allCases.count)
    }
}
