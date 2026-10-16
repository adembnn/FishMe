import Core
import Foundation

/// Lit et écrit, sur l'iPhone, ce que le profil iCloud transporte : niveau, premier lancement, clubs et sorties.
/// La session en cours et le spot gratuit (trousseau, coordonnée exacte) ne sont jamais touchés.
/// Sur le fil principal, comme `SuiviSession` qui lit le même fichier.
struct ProfilLocal {
    var stockage: StockageFichier = StockageFichier()
    private static let cleClubs = "club.mesClubs"
    private static let cleDernier = "compte.dernierProfil"

    func lire() -> ProfilSauvegarde {
        let d = UserDefaults.standard
        let fichier = stockage.charger()
        var profil = ProfilSauvegarde(
            niveau: d.string(forKey: ClesConseils.niveau),
            questionVue: d.bool(forKey: ClesConseils.questionVue),
            tunnelVu: d.bool(forKey: ClesConseils.tunnelVu),
            clubs: d.data(forKey: Self.cleClubs),
            sorties: fichier.terminees,
            sessionsTerminees: fichier.sessionsTerminees)
        // Date de modification : celle de la dernière synchro si rien n'a bougé depuis, sinon maintenant.
        if let dernier = Self.dernier(), Self.memeContenu(dernier, profil) {
            profil.modifie = dernier.modifie
        } else if !profil.estVide {
            profil.modifie = Date()
        }
        return profil
    }

    /// Écrit le profil fusionné. La session en cours, s'il y en a une, reste telle quelle.
    func ecrire(_ profil: ProfilSauvegarde) {
        let d = UserDefaults.standard
        if let niveau = profil.niveau { d.set(niveau, forKey: ClesConseils.niveau) }
        if profil.questionVue { d.set(true, forKey: ClesConseils.questionVue) }
        if profil.tunnelVu { d.set(true, forKey: ClesConseils.tunnelVu) }
        if let clubs = profil.clubs { d.set(clubs, forKey: Self.cleClubs) }
        var fichier = stockage.charger()
        fichier.terminees = profil.sorties
        fichier.sessionsTerminees = profil.sessionsTerminees
        stockage.ecrire(fichier)
        if let json = try? JSONEncoder().encode(profil) { d.set(json, forKey: Self.cleDernier) }
    }

    private static func dernier() -> ProfilSauvegarde? {
        UserDefaults.standard.data(forKey: cleDernier).flatMap { try? JSONDecoder().decode(ProfilSauvegarde.self, from: $0) }
    }

    private static func memeContenu(_ a: ProfilSauvegarde, _ b: ProfilSauvegarde) -> Bool {
        var a = a, b = b
        a.modifie = .distantPast
        b.modifie = .distantPast
        return a == b
    }
}
