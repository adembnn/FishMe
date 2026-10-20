import Core
import Foundation

/// Lit et écrit, sur l'iPhone, ce que le profil iCloud transporte : niveau, premier lancement, clubs, sorties et envies.
/// La session en cours et le spot gratuit (trousseau, coordonnée exacte) ne sont jamais touchés.
/// Sur le fil principal, comme `SuiviSession` qui lit le même fichier.
struct ProfilLocal {
    var stockage: StockageFichier = StockageFichier()
    /// N2 : le fichier de « Mes envies » (le même que celui du modèle `EnviesModele`, voir `ParcoursApp.envies`).
    static var fichierEnvies: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("envies.json")
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("envies.json")
    }
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
            sessionsTerminees: fichier.sessionsTerminees,
            envies: StockageEnviesFichier(url: Self.fichierEnvies).lire().envies)
        // Date de modification : celle de la dernière synchro si rien n'a bougé depuis, sinon maintenant.
        // Jamais synchronisé (iPhone neuf) : date la plus ancienne, pour que le niveau et les clubs d'iCloud gagnent.
        if let dernier = Self.dernier() {
            profil.modifie = Self.memeContenu(dernier, profil) ? dernier.modifie : Date()
        } else {
            profil.modifie = .distantPast
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
        // N2 : les envies fusionnées (pierres tombales comprises). `EnviesModele.relire()` suit, voir `SauvegardeAvecReperes`.
        // ⚠ à vérifier : écrit seulement si la liste diffère de celle du fichier, pour ne pas toucher au fichier sans raison.
        let stockageEnvies = StockageEnviesFichier(url: Self.fichierEnvies)
        let fusionnees = ListeEnvies(envies: profil.envies)
        if fusionnees != stockageEnvies.lire() { stockageEnvies.ecrire(fusionnees) }
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
