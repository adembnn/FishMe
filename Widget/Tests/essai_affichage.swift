import Foundation

// Essai hors Xcode : swiftc Widget/Session/EtatSession.swift Widget/Tests/essai_affichage.swift -o /tmp/essai && /tmp/essai
// (nom de fichier sans main.swift : on utilise @main).
@main
struct Essai {
    static func verifier(_ ok: Bool, _ nom: String) {
        print(ok ? "ok  " : "ECHEC", nom)
        if !ok { exit(1) }
    }
    static func main() {
        let t0 = Date(timeIntervalSince1970: 1_792_065_600)
        let fin = t0.addingTimeInterval(2 * 60)
        let e = EtatSession(debut: t0, finLegale: fin, prises: 0)
        verifier(e.affichage(maintenant: t0, perime: false) == .compteARebours(jusqua: fin), "compte à rebours au départ")
        verifier(e.affichage(maintenant: fin.addingTimeInterval(-1), perime: false) == .compteARebours(jusqua: fin), "compte à rebours avant la fin")
        verifier(e.affichage(maintenant: fin, perime: false) == .finLegale(fin), "fin légale à l'heure")
        verifier(e.affichage(maintenant: t0, perime: true) == .finLegale(fin), "fin légale quand le système périme")
        verifier(e.heurePerimee(maintenant: t0) == fin, "staleDate = fin légale")
        verifier(e.heurePerimee(maintenant: fin) == nil, "pas de staleDate passée")
        let ferme = EtatSession(debut: t0, finLegale: t0.addingTimeInterval(-1800), prises: 0)
        verifier(ferme.affichage(maintenant: t0, perime: false) == .pecheFermee, "départ hors fenêtre : pêche fermée")
        verifier(ferme.heurePerimee(maintenant: t0) == nil, "hors fenêtre : pas de staleDate")
        let inconnu = EtatSession(debut: t0, finLegale: nil, prises: 2)
        verifier(inconnu.affichage(maintenant: t0, perime: false) == .finInconnue(depuis: t0), "fin inconnue : aucune fausse heure")
        let json = String(data: try! JSONEncoder().encode(e), encoding: .utf8)!
        verifier(!json.lowercased().contains("lat") && !json.lowercased().contains("lon"), "aucune coordonnée dans l'état")
    }
}
