import Core
import SwiftUI

/// Une carte partagée par un membre, lue depuis CloudKit : l'image (PNG sans GPS), le surnom de l'auteur et un menu de 44 pt.
/// Le menu : « Signaler la carte » et « Bloquer » pour les cartes des autres (règle 1.2), « Retirer du club » pour les miennes.
struct CarteEnLigneClubView: View {
    let carte: CartePartageeClub
    let auteur: String
    let estMoi: Bool
    let signaler: () -> Void
    let bloquer: () -> Void
    let retirer: () -> Void

    private var libelle: String {
        var morceaux = [carte.espece.isEmpty ? "Carte" : carte.espece]
        if let taille = carte.tailleCm { morceaux.append("\(Int(taille.rounded())) cm") }
        if let rarete = carte.rarete { morceaux.append(StyleRarete(rarete).mot) }
        morceaux.append("par \(estMoi ? "moi" : auteur)")
        return morceaux.joined(separator: ", ")
    }

    var body: some View {
        VStack(spacing: Espace.xs) {
            VignetteMaCarteClub(carte: CarteAPartager(id: carte.id, titre: carte.espece, png: carte.image ?? Data()))
                .accessibilityLabel(libelle)
            HStack(spacing: 0) {
                Text(estMoi ? "Moi" : auteur)
                    .font(Police.detail).foregroundStyle(Palette.encre)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Menu {
                    if estMoi {
                        Button("Retirer du club", systemImage: "minus.circle", role: .destructive, action: retirer)
                    } else {
                        Button("Signaler la carte", systemImage: "flag", action: signaler)
                        Button("Bloquer \(auteur)", systemImage: "hand.raised", role: .destructive, action: bloquer)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(Police.taille(20))
                        .foregroundStyle(Palette.encreDouce)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Options de la carte")
            }
        }
    }
}

/// Le record du club lu depuis CloudKit : la plus grande carte, son espèce, sa taille, son auteur.
struct RecordEnLigneClubView: View {
    let carte: CartePartageeClub
    let auteur: String

    var body: some View {
        HStack(alignment: .center, spacing: Espace.l) {
            VignetteMaCarteClub(carte: CarteAPartager(id: carte.id, titre: carte.espece, png: carte.image ?? Data()))
                .frame(width: 130)
            VStack(alignment: .leading, spacing: 2) {
                Text(carte.espece).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(3)
                if let taille = carte.tailleCm {
                    Text("\(Int(taille.rounded())) cm").font(Police.titre.monospacedDigit()).foregroundStyle(Palette.marine)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                Text(auteur).font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Record du club : \(carte.espece), \(carte.tailleCm.map { "\(Int($0.rounded())) cm" } ?? ""), \(auteur)")
    }
}

/// Le choix du motif d'un signalement : liste fermée (L21), pas de texte libre. Le choix masque la carte et ouvre l'e-mail prérempli.
struct SignalerCarteClubView: View {
    let carte: CartePartageeClub
    let choisir: (MotifSignalementClub) -> Void

    @Environment(\.dismiss) private var fermer

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("La carte sera masquée tout de suite. Un e-mail prérempli s'ouvre : envoie-le pour que l'équipe la regarde.")
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .padding(.horizontal, Espace.l).padding(.bottom, Espace.m)
                    GroupeClub {
                        ForEach(Array(MotifSignalementClub.allCases.enumerated()), id: \.element.id) { rang, motif in
                            if rang > 0 { FiletClub() }
                            Button {
                                choisir(motif)
                                fermer()
                            } label: {
                                HStack(spacing: Espace.m) {
                                    Image(systemName: motif.symbole).foregroundStyle(Palette.marine).frame(width: 28)
                                    Text(motif.titre).font(Police.corps).foregroundStyle(Palette.encre)
                                        .multilineTextAlignment(.leading)
                                    Spacer(minLength: 0)
                                }
                                .frame(minHeight: 52)
                                .padding(.horizontal, Espace.l)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.l)
            }
            .scrollIndicators(.hidden)
            .background(Palette.fond.ignoresSafeArea())
            .navigationTitle("Signaler la carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annuler") { fermer() } }
            }
        }
        .tint(Palette.marine)
        .presentationDetents([.large])
    }
}
