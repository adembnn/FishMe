import Core
import SwiftUI

/// Mode démo de la page Club, piloté par `@AppStorage("demo.communaute")`.
/// Les clubs, membres, cartes et records ci-dessous sont écrits en dur pour la démo :
/// ils ne viennent ni de CloudKit ni d'une vraie personne, et ne sont jamais enregistrés dans `MesClubs`.
/// Quelques cartes montrent une photo libre de droits de `App/Demo/Photos` (crédits dans Réglages, « Crédits photos »), les autres l'illustration de l'espèce. Chaque club porte « Démo » dans son nom. Aucune position GPS.
/// Petite pastille « Démo » : tout élément de démonstration la porte, rien n'y passe pour une vraie prise.
struct PastilleDemo: View {
  var body: some View {
    Text("Démo")
      .font(Police.taille(11, .heavy))
      .foregroundStyle(Palette.marine)
      .padding(.horizontal, Espace.s)
      .padding(.vertical, 2)
      .background(Palette.marineDoux, in: Capsule())
      .accessibilityLabel("Contenu de démonstration")
  }
}

#if DEBUG
enum DemoClub {
  /// Clé de réglage (UserDefaults) de l'interrupteur.
  static let cle = "demo.communaute"
  private static let idEssec = UUID(uuidString: "D0D0D0D0-0000-4000-8000-000000000002")!
  private static let idVal = UUID(uuidString: "D0D0D0D0-0000-4000-8000-000000000001")!

  /// Les 2 clubs de la démo : « Les pêcheurs de l'ESSEC » (déjà rejoint, donc choisi à l'ouverture) puis « Les Carnassiers du 94 ».
  static let clubs: [ClubLocal] = [
    ClubLocal(id: idEssec, nom: "Les pêcheurs de l'ESSEC · Démo", poissonId: "sandre"),
    ClubLocal(id: idVal, nom: "AAPPMA du Val-de-Marne · Démo", poissonId: "brochet"),
  ]

  /// Dans le club de l'ESSEC, l'utilisateur (Titouan) fait partie des 3 membres : pas de pastille « Moi » à part.
  static func utilisateurEstMembre(_ club: ClubLocal?) -> Bool {
    club?.id == idEssec
  }

  static func estDemo(_ club: ClubLocal?) -> Bool {
    guard let club else { return false }
    return clubs.contains { $0.id == club.id }
  }

  static func membres(pour club: ClubLocal) -> [MembreClub] {
    if club.id == idEssec {
      return [
        MembreClub(id: "demo-e1", nom: "Adem", nombreDeCartes: 14),
        MembreClub(id: "demo-e2", nom: "Sullyvan", nombreDeCartes: 9),
        MembreClub(id: "demo-e3", nom: "Titouan", nombreDeCartes: 11),
      ]
    }
    return [
      MembreClub(id: "demo-v1", nom: "Léa", nombreDeCartes: 18),
      MembreClub(id: "demo-v2", nom: "Malo", nombreDeCartes: 14),
      MembreClub(id: "demo-v3", nom: "Inès", nombreDeCartes: 11),
      MembreClub(id: "demo-v4", nom: "Nathan", nombreDeCartes: 7),
      MembreClub(id: "demo-v5", nom: "Jade", nombreDeCartes: 3),
    ]
  }

  static func dernieresCartes(pour club: ClubLocal) -> [CarteRecenteClub] {
    if club.id == idEssec {
      return [
        CarteRecenteClub(
          id: "demo-ec1", membre: "Hugo", espece: "Silure glane", jour: "lundi",
          tailleCm: 118, image: "silure-glane", niveau: .legendaire),
        CarteRecenteClub(
          id: "demo-ec2", membre: "Camille", espece: "Perche", jour: "dim.",
          tailleCm: 27, image: "perche-commune", niveau: .commun),
        CarteRecenteClub(
          id: "demo-ec3", membre: "Titouan", espece: "Sandre", jour: "sam.",
          tailleCm: 61, image: "sandre", niveau: .rare, photo: "sandre-1"),
        CarteRecenteClub(
          id: "demo-ec4", membre: "Adem", espece: "Black-bass", jour: "ven.",
          tailleCm: 38, image: "black-bass", niveau: .peuCommun, photo: "black-bass-1"),
        CarteRecenteClub(
          id: "demo-ec5", membre: "Théo", espece: "Carpe commune", jour: "jeu.",
          tailleCm: 72, image: "carpe-commune", niveau: .peuCommun),
        CarteRecenteClub(
          id: "demo-ec6", membre: "Titouan", espece: "Omble de fontaine (saumon de fontaine)",
          jour: "mer.", tailleCm: 34, image: "omble-de-fontaine", niveau: .rare),
      ]
    }
    return [
      CarteRecenteClub(
        id: "demo-vc1", membre: "Léa", espece: "Sandre", jour: "lundi",
        tailleCm: 52, image: "sandre", niveau: .rare, photo: "sandre-1"),
      CarteRecenteClub(
        id: "demo-vc2", membre: "Malo", espece: "Brochet", jour: "dim.",
        tailleCm: 74, image: "brochet", niveau: .rare, photo: "brochet-1"),
      CarteRecenteClub(
        id: "demo-vc3", membre: "Inès", espece: "Perche", jour: "sam.",
        tailleCm: 29, image: "perche-commune", niveau: .commun, photo: "perche-commune-1"),
      CarteRecenteClub(
        id: "demo-vc4", membre: "Nathan", espece: "Truite fario", jour: "ven.",
        tailleCm: 33, image: "truite-fario", niveau: .peuCommun, photo: "truite-fario-1"),
      CarteRecenteClub(
        id: "demo-vc5", membre: "Jade", espece: "Gardon", jour: "jeu.",
        tailleCm: 24, image: "gardon", niveau: .commun),
    ]
  }

  static func record(pour club: ClubLocal) -> RecordClub {
    if club.id == idEssec {
      return RecordClub(
        titre: "Plus gros silure", membre: "Hugo", tailleCm: 118, image: "silure-glane",
        niveau: .legendaire)
    }
    return RecordClub(
      titre: "Plus gros brochet", membre: "Malo", tailleCm: 74, image: "brochet",
      niveau: .rare)
  }
}
#else
/// Release : aucune donnée de démonstration. Les appels existent encore mais ne sont jamais atteints (`demo` vaut toujours faux).
enum DemoClub {
  static let cle = "demo.communaute"
  static let clubs: [ClubLocal] = []
  static func utilisateurEstMembre(_ club: ClubLocal?) -> Bool { false }
  static func estDemo(_ club: ClubLocal?) -> Bool { false }
  static func membres(pour club: ClubLocal) -> [MembreClub] { [] }
  static func dernieresCartes(pour club: ClubLocal) -> [CarteRecenteClub] { [] }
  static func record(pour club: ClubLocal) -> RecordClub {
    preconditionFailure("DemoClub n'existe pas en Release")
  }
}
#endif
