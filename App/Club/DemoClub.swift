import Core
import SwiftUI

/// Mode démo de la page Club, piloté par `@AppStorage("demo.communaute")`.
/// Les clubs, membres, cartes et records ci-dessous sont des EXEMPLES écrits en dur :
/// ils ne viennent ni de CloudKit ni d'une vraie personne, ne sont jamais enregistrés dans `MesClubs`,
/// et chaque écran qui les montre le dit (bandeau « Données d'exemple pour la démo », « (exemple) » dans les noms).
/// Les images sont des poissons déjà présents dans l'app. Aucune position GPS.
enum DemoClub {
  /// Clé de réglage (UserDefaults) de l'interrupteur.
  static let cle = "demo.communaute"

  private static let idVal = UUID(uuidString: "D0D0D0D0-0000-4000-8000-000000000001")!
  private static let idSeine = UUID(uuidString: "D0D0D0D0-0000-4000-8000-000000000002")!

  /// Les 2 clubs d'exemple. Identifiants fixes pour que la sélection tienne pendant la démo.
  static let clubs: [ClubLocal] = [
    ClubLocal(id: idVal, nom: "AAPPMA du Val-de-Marne (exemple)", poissonId: "brochet"),
    ClubLocal(id: idSeine, nom: "Les pêcheurs de la Seine (exemple)", poissonId: "sandre"),
  ]

  static func estExemple(_ club: ClubLocal?) -> Bool {
    guard let club else { return false }
    return clubs.contains { $0.id == club.id }
  }

  static func membres(pour club: ClubLocal) -> [MembreClub] {
    if club.id == idSeine {
      return [
        MembreClub(id: "demo-s1", nom: "Hugo", nombreDeCartes: 21),
        MembreClub(id: "demo-s2", nom: "Camille", nombreDeCartes: 17),
        MembreClub(id: "demo-s3", nom: "Yanis", nombreDeCartes: 12),
        MembreClub(id: "demo-s4", nom: "Salomé", nombreDeCartes: 9),
        MembreClub(id: "demo-s5", nom: "Théo", nombreDeCartes: 4),
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
    if club.id == idSeine {
      return [
        CarteRecenteClub(
          id: "demo-sc1", membre: "Hugo", espece: "Silure glane", jour: "lundi, exemple",
          tailleCm: 118, image: "silure-glane", niveau: .legendaire),
        CarteRecenteClub(
          id: "demo-sc2", membre: "Camille", espece: "Perche", jour: "dim., exemple",
          tailleCm: 27, image: "perche-commune", niveau: .commun),
        CarteRecenteClub(
          id: "demo-sc3", membre: "Yanis", espece: "Sandre", jour: "sam., exemple",
          tailleCm: 61, image: "sandre", niveau: .rare),
        CarteRecenteClub(
          id: "demo-sc4", membre: "Salomé", espece: "Black-bass", jour: "ven., exemple",
          tailleCm: 38, image: "black-bass", niveau: .peuCommun),
        CarteRecenteClub(
          id: "demo-sc5", membre: "Théo", espece: "Carpe commune", jour: "jeu., exemple",
          tailleCm: 72, image: "carpe-commune", niveau: .peuCommun),
      ]
    }
    return [
      CarteRecenteClub(
        id: "demo-vc1", membre: "Léa", espece: "Sandre", jour: "lundi, exemple",
        tailleCm: 52, image: "sandre", niveau: .rare),
      CarteRecenteClub(
        id: "demo-vc2", membre: "Malo", espece: "Brochet", jour: "dim., exemple",
        tailleCm: 74, image: "brochet", niveau: .rare),
      CarteRecenteClub(
        id: "demo-vc3", membre: "Inès", espece: "Perche", jour: "sam., exemple",
        tailleCm: 29, image: "perche-commune", niveau: .commun),
      CarteRecenteClub(
        id: "demo-vc4", membre: "Nathan", espece: "Truite fario", jour: "ven., exemple",
        tailleCm: 33, image: "truite-fario", niveau: .peuCommun),
      CarteRecenteClub(
        id: "demo-vc5", membre: "Jade", espece: "Carpe commune", jour: "jeu., exemple",
        tailleCm: 64, image: "carpe-commune", niveau: .commun),
    ]
  }

  static func record(pour club: ClubLocal) -> RecordClub {
    if club.id == idSeine {
      return RecordClub(
        titre: "Plus gros silure", membre: "Hugo", tailleCm: 118, image: "silure-glane",
        niveau: .legendaire)
    }
    return RecordClub(
      titre: "Plus gros brochet", membre: "Malo", tailleCm: 74, image: "brochet",
      niveau: .rare)
  }
}

/// Bandeau lisible, en haut de la page Club, tant que le mode démo est actif.
struct BandeauDemoClub: View {
  var body: some View {
    HStack(spacing: Espace.s) {
      Image(systemName: "info.circle.fill")
        .foregroundStyle(Palette.marine)
        .accessibilityHidden(true)
      Text("Données d'exemple pour la démo")
        .font(Police.corps)
        .foregroundStyle(Palette.encre)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, Espace.l)
    .padding(.vertical, Espace.m)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .accessibilityElement(children: .combine)
  }
}
