import Foundation
import Testing
@testable import Core

@Suite("Carte de pêche : numéros utiles et Ma fédération")
struct NumerosEtFederationTests {
    // MARK: Numéros utiles

    @Test("Exactement 112, 18, 15, 17 et 114")
    func ensembleExact() {
        #expect(Set(NumerosUtiles.liste.map(\.numero)) == ["112", "18", "15", "17", "114"])
        #expect(NumerosUtiles.liste.count == 5)
    }

    @Test("Principaux et autres")
    func groupes() {
        #expect(NumerosUtiles.principaux.map(\.numero) == ["112", "18", "15"])
        #expect(Set(NumerosUtiles.autres.map(\.numero)) == ["17", "114"])
    }

    @Test("Le sauvetage maritime et le numéro de rappel sont absents")
    func exclus() {
        let numeros = NumerosUtiles.liste.map { $0.numero.replacingOccurrences(of: " ", with: "") }
        #expect(!numeros.contains("196"))
        #expect(!numeros.contains("0800112112"))
        #expect(!NumerosUtiles.liste.contains { $0.libelle.localizedCaseInsensitiveContains("maritime") })
    }

    @Test("Chaque numéro porte une source https et une date de relevé")
    func sources() {
        for n in NumerosUtiles.liste {
            #expect(n.sourceURL.scheme == "https")
            #expect(n.sourceURL.host == "www.service-public.gouv.fr")
            #expect(n.releveLe == NumerosUtiles.releveLe)
            #expect(n.lienTelephone?.absoluteString == "tel:\(n.numero)")
        }
        #expect(NumerosUtiles.releveLe == JourCivil(annee: 2026, mois: 10, jour: 19))
    }

    @Test("Libellés de la source, mot pour mot")
    func libelles() throws {
        let parNumero = Dictionary(uniqueKeysWithValues: NumerosUtiles.liste.map { ($0.numero, $0.libelle) })
        #expect(parNumero["18"] == "Sapeurs-pompiers")
        #expect(parNumero["112"] == "Numéro d'urgence européen")
        #expect(parNumero["15"] == "Samu (Service d'aide médicale d'urgence)")
        #expect(parNumero["17"] == "Police ou gendarmerie")
        #expect(parNumero["114"] == "Urgence pour les personnes sourdes et malentendantes")
    }

    // MARK: Ma fédération

    private func repertoire() throws -> [String: LienDepartement] {
        let donnees = try #require(Ressources.donnees("liens-federations"))
        return RepertoireFederations.lire(donnees)
    }

    @Test("96 départements lus avec leurs vrais champs")
    func lecture() throws {
        let r = try repertoire()
        #expect(r.count == 96)
        let ain = try #require(r["01"])
        #expect(ain.nom == "Ain")
        #expect(ain.liens.siteFederation == "https://www.federation-peche-ain.com/")
        #expect(ain.verifie)
        #expect(ain.releveLe == JourCivil(annee: 2026, mois: 10, jour: 15))
    }

    @Test("Chaque code donne un site non vide et une page de cartes")
    func chaqueCode() throws {
        let r = try repertoire()
        for code in r.keys {
            let f = MaFederation.embarquee(code: code, repertoire: r)
            let site = try #require(f.site, "site absent pour \(code)")
            #expect(!site.absoluteString.isEmpty)
            #expect(f.cartesNationales != nil)
            #expect(f.evenements == f.site)
        }
    }

    @Test("Sans lien : repli national")
    func repli() {
        let f = MaFederation(liens: LiensFederation(), code: "99", nom: "")
        #expect(f.site == MaFederation.siteNational)
        #expect(f.siteDeRepli)
        #expect(f.cartesNationales == MaFederation.cartesNationalesRepli)
        let inconnue = MaFederation.embarquee(code: "ZZ", repertoire: [:])
        #expect(inconnue.siteDeRepli)
    }

    @Test("75, 92, 93, 94 : fédération interdépartementale, URL http gardée telle quelle")
    func interdepartementale() throws {
        let r = try repertoire()
        for code in ["75", "92", "93", "94"] {
            let f = MaFederation.embarquee(code: code, repertoire: r)
            #expect(f.interdepartementale)
            #expect(f.libelleFederation == "Fédération de Paris, Hauts-de-Seine, Seine-Saint-Denis et Val-de-Marne")
            #expect(f.site?.scheme == "http")
        }
        let paris = MaFederation.embarquee(code: "75", repertoire: r)
        #expect(paris.site?.absoluteString == "http://www.federation-peche-paris.fr")
        #expect(MaFederation.embarquee(code: "01", repertoire: r).interdepartementale == false)
    }

    @Test("2B : la note du fichier est renvoyée, non vérifié")
    func corseDuNord() throws {
        let f = MaFederation.embarquee(code: "2B", repertoire: try repertoire())
        #expect(f.notes.count == 1)
        #expect(f.verifie == false)
    }

    @Test("Le nom donné par l'appelant prime, sinon celui du fichier")
    func nomDuDepartement() throws {
        let r = try repertoire()
        #expect(MaFederation.embarquee(code: "01", nom: "Ain (test)", repertoire: r).libelleFederation == "Fédération de Ain (test)")
        #expect(MaFederation.embarquee(code: "01", repertoire: r).libelleFederation == "Fédération de Ain")
        #expect(MaFederation(liens: LiensFederation(), code: "99", nom: "").libelleFederation == nil)
    }

    // MARK: Fiche

    @Test("La fiche ne porte ni nom, ni prénom, ni numéro d'adhérent")
    func ficheSansIdentite() throws {
        let jour = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        let fiche = FicheCartePeche(millesime: 2026, association: "AAPPMA test", expireLe: jour,
                                    fichier: FichierCarte(nom: "carte.jpg", genre: .image), ajouteeLe: jour)
        let donnees = try JSONEncoder().encode(fiche)
        let objet = try #require(try JSONSerialization.jsonObject(with: donnees) as? [String: Any])
        let cles = Set(objet.keys.map { $0.lowercased() })
        #expect(cles == ["id", "millesime", "association", "expirele", "rappelactif", "fichier", "ajouteele"])
        for interdit in ["nom", "prenom", "prénom", "numero", "numéro", "adherent", "adhérent"] {
            #expect(!cles.contains(interdit))
        }
        #expect(try JSONDecoder().decode(FicheCartePeche.self, from: donnees) == fiche)
        #expect(fiche.identifiantRappel == "cartepeche-\(fiche.id.uuidString)")
    }

    @Test("Un nom de fichier ne peut pas être un chemin")
    func nomDeFichierSur() {
        #expect(FichierCarte(nom: "carte-1.jpg", genre: .image).nomEstSur)
        #expect(!FichierCarte(nom: "../secret.jpg", genre: .image).nomEstSur)
        #expect(!FichierCarte(nom: "/etc/passwd", genre: .pdf).nomEstSur)
        #expect(!FichierCarte(nom: "a\\b.pdf", genre: .pdf).nomEstSur)
        #expect(!FichierCarte(nom: "", genre: .pdf).nomEstSur)
        #expect(FichierCarte.tailleMaxOctets == 15 * 1024 * 1024)
    }

    // MARK: Mots interdits dans les textes affichés du Core

    @Test("Aucune chaîne du dossier CartePeche ne porte un mot interdit")
    func motsInterdits() throws {
        // …/Packages/Core/Tests/CoreTests/CartePeche/ce-fichier.swift
        var racine = URL(fileURLWithPath: #filePath)
        for _ in 0..<4 { racine.deleteLastPathComponent() }
        let dossier = racine.appendingPathComponent("Sources/Core/CartePeche")
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        #expect(!fichiers.isEmpty)
        let motif = try NSRegularExpression(pattern: "\"[^\"\\n]*\"")
        let interdits = ["poké", "pokédex", "pokemon", "valide", "en règle", "tu peux pêcher", "officielle", "validée"]
        for fichier in fichiers {
            let source = try String(contentsOf: fichier, encoding: .utf8)
            let plage = NSRange(source.startIndex..., in: source)
            for m in motif.matches(in: source, range: plage) {
                guard let r = Range(m.range, in: source) else { continue }
                let chaine = source[r].lowercased()
                for mot in interdits {
                    #expect(!chaine.contains(mot), "« \(mot) » dans \(fichier.lastPathComponent) : \(chaine)")
                }
            }
        }
    }
}
