import SwiftUI

/// La feuille de consentement de la migration : pour chaque club local, « Mettre en ligne » ou « Garder sur cet iPhone ».
/// R2 (`migration-clubs.md`) : un club local était privé ; en ligne, quiconque a son lien lit son nom, son image et ses cartes.
/// Pas de migration silencieuse. Sans profil (L21) : « Finis ton profil » d'abord, rien d'autre n'est bloqué.
struct MigrationClubsView: View {
    let migration: MigrationClubs
    let cartes: [CarteAPartager]
    var poissons: [PoissonClub] = []

    @Environment(\.dismiss) private var fermer
    @State private var enAttente: [ClubLocal] = []
    @State private var erreur: ErreurClub?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Mets ton club en ligne")
                    .font(Police.titre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Text("En ligne, quiconque a le lien du club voit son nom, son image et les cartes que tu y as partagées. Ton coin exact ne part jamais. Tu peux aussi le garder sur cet iPhone.")
                    .font(Police.corps).foregroundStyle(Palette.encreDouce)
                if !migration.peutMigrer {
                    Text("Finis ton profil d'abord : il donne ton surnom aux membres.")
                        .font(Police.corps).foregroundStyle(Palette.encre)
                }
                ForEach(enAttente) { club in
                    VStack(alignment: .leading, spacing: Espace.m) {
                        HStack(spacing: Espace.m) {
                            VignetteClub(club: club, poissons: poissons, taille: 44)
                            Text(club.nom).font(Police.sousTitre).foregroundStyle(Palette.encre)
                        }
                        .accessibilityElement(children: .combine)
                        Button("Mettre en ligne") { Task { await mettreEnLigne(club) } }
                            .buttonStyle(.principal)
                            .disabled(!migration.peutMigrer || migration.enCours)
                        Button("Garder sur cet iPhone") {
                            migration.garderEnLocal(club)
                            actualiser()
                        }
                        .buttonStyle(.secondaire)
                    }
                    .padding(Espace.l)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                }
                if let erreur {
                    Text(texte(pour: erreur)).font(Police.legende).foregroundStyle(Palette.alerte)
                }
                Button("Plus tard") { fermer() }
                    .font(Police.corps).foregroundStyle(Palette.marine)
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.large])
        .onAppear { actualiser() }
    }

    private func actualiser() {
        enAttente = migration.enAttente
        if enAttente.isEmpty { fermer() }
    }

    private func mettreEnLigne(_ club: ClubLocal) async {
        let issues = await migration.migrer([club], cartes: cartes)
        switch issues[club.id] {
        case .echec(let e)?: erreur = e
        case .cartesPasPretes?: erreur = .reseau
        default: erreur = nil
        }
        actualiser()
    }

    private func texte(pour erreur: ErreurClub) -> String {
        erreur == .reseau ? "Pas de réseau, ou tes cartes ne sont pas prêtes. Réessaie dans un instant." : GestionClubs.message(pour: erreur).texte
    }
}
