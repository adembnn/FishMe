import Foundation
import Testing
import Core
@testable import BuildChallenge

/// La logique du bloc de règles (L19) sur des lignes synthétiques de forme `Core`. Écrit sans Mac : à lancer sur le Mac (non exécuté).
@MainActor
struct BlocReglesLogiqueTests {
    private func ligne(_ type: TypeRegle, _ etat: EtatLigne, raison: RaisonAVerifier? = nil, phrase: String = "p") -> LigneControle {
        LigneControle(type: type, etat: etat, raison: raison, phrase: phrase, sources: [SourceRegle(titre: "Source", url: nil, citation: "c")])
    }

    // MARK: Les deux états de tête

    @Test func uneRegleNonRespecteeDonneRelacher() {
        let taille = ligne(.taille, .nonRespectee, phrase: "55 cm, maille à 60 cm")
        let t = BlocReglesLogique.tete(lignes: [taille, ligne(.periode, .respectee)], consigne: .relacheLa, especeConfirmee: true)
        #expect(t == .relacher(raison: "55 cm, maille à 60 cm", ligne: taille))
    }

    @Test func laRaisonLaPlusForteGagne() {
        let taille = ligne(.taille, .nonRespectee, phrase: "taille")
        let periode = ligne(.periode, .nonRespectee, phrase: "fermée jusqu'au 25/04")
        let quota = ligne(.quota, .nonRespectee, phrase: "quota du jour atteint")
        #expect(BlocReglesLogique.plusForte([taille, quota, periode]) == periode)
        #expect(BlocReglesLogique.plusForte([taille, quota]) == quota)
        #expect(BlocReglesLogique.plusForte([ligne(.taille, .respectee)]) == nil)
    }

    @Test func laConsigneRelacheLaSeuleDonneRelacher() {
        let t = BlocReglesLogique.tete(lignes: [], consigne: .relacheLa, especeConfirmee: true)
        #expect(t == .relacher(raison: Consigne.relacheLa.texte, ligne: nil))
    }

    @Test func uneEspeceNonConfirmeeDonneRelacher() {
        let t = BlocReglesLogique.tete(lignes: [ligne(.taille, .respectee)], consigne: .verifieLArrete, especeConfirmee: false)
        #expect(t == .relacher(raison: BlocReglesLogique.raisonEspeceNonConfirmee, ligne: nil))
    }

    @Test func toutLeResteDonneLaReglementationFermee() {
        let lignes = [ligne(.taille, .respectee), ligne(.consommation, .information)]
        #expect(BlocReglesLogique.tete(lignes: lignes, consigne: .aucuneRegleSaisieNeLInterdit, especeConfirmee: true) == .reglementation(aVerifier: false))
    }

    @Test func uneLigneAVerifierMetLaPastilleSansChangerDEtat() {
        let lignes = [ligne(.taille, .aVerifierSurPlace, raison: .tropPresDeLaMaille)]
        #expect(BlocReglesLogique.tete(lignes: lignes, consigne: .mesureLaSurUneToise, especeConfirmee: true) == .reglementation(aVerifier: true))
        #expect(BlocReglesLogique.consigneSousLeTitre(lignes: lignes, consigne: .mesureLaSurUneToise) == "Mesure-la sur une toise")
        #expect(BlocReglesLogique.consigneSousLeTitre(lignes: [ligne(.taille, .respectee)], consigne: .verifieLArrete) == nil)
    }

    // MARK: Les trois groupes

    @Test func chaqueTypeVaDansSonGroupe() {
        for t: TypeRegle in [.taille, .periode, .quota, .consommation] { #expect(BlocReglesLogique.groupe(de: t) == .garderOuRelacher) }
        #expect(BlocReglesLogique.groupe(de: .nuit) == .horaires)
        for t: TypeRegle in [.modeDePeche, .transportVivant, .reserve] { #expect(BlocReglesLogique.groupe(de: t) == .materielEtPratique) }
    }

    @Test func unGroupeVideNExistePasEtLOrdreEstFixe() {
        let lignes = [ligne(.reserve, .aVerifierSurPlace, raison: .reserve), ligne(.taille, .respectee), ligne(.nuit, .information)]
        #expect(BlocReglesLogique.groupes(lignes).map(\.groupe) == [.garderOuRelacher, .horaires, .materielEtPratique])
        #expect(BlocReglesLogique.groupes([ligne(.taille, .respectee)]).map(\.groupe) == [.garderOuRelacher])
        #expect(BlocReglesLogique.groupes([]).isEmpty)
    }

    @Test func lesTitresDesGroupesSontCeuxDeLaFiche() {
        #expect(BlocReglesLogique.Groupe.allCases.map(\.titre) == ["Garder ou relâcher", "Horaires", "Matériel et pratique"])
        #expect(BlocReglesLogique.titreRelacher == "Il faut relâcher le poisson")
        #expect(BlocReglesLogique.titreReglementation == "Voir la réglementation en vigueur sur ce poisson")
    }

    // MARK: Mots interdits

    @Test func aucunTexteDuBlocNeDitTuPeuxLaGarderOuAutorise() {
        var textes = [BlocReglesLogique.titreRelacher, BlocReglesLogique.titreReglementation, BlocReglesLogique.raisonEspeceNonConfirmee,
                      BlocReglesLogique.mentionFoi]
        textes += BlocReglesLogique.Groupe.allCases.map(\.titre)
        textes += [EtatLigne.respectee, .nonRespectee, .aVerifierSurPlace, .information].compactMap { BlocReglesLogique.motDEtat($0) }
        textes += [Consigne.relacheLa, .mesureLaSurUneToise, .verifieLArrete].map(\.texte)
        let tout = textes.joined(separator: " ").lowercased()
        #expect(!tout.contains("tu peux la garder"))
        #expect(!tout.contains("autorisé"))
    }
}
