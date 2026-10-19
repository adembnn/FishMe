import Core
import SwiftUI

/// « Ma fédération » : la fédération du département du spot, trois liens qui s'ouvrent dans Safari,
/// les numéros utiles et le texte fixe sur les règles locales. Hors ligne pour tout sauf les liens.
/// Posée dans le Profil par L21 (demande dans `docs/fiches/N5.md`).
struct MaFederationView: View {
    let federation: MaFederation

    init(federation: MaFederation) {
        self.federation = federation
    }

    /// Depuis le code du département du spot (« 94 ») et son nom, quand l'appelant le connaît.
    init(codeDepartement: String, nomDepartement: String? = nil) {
        self.federation = MaFederation.embarquee(code: codeDepartement, nom: nomDepartement)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                entete
                liens
                NumerosUtilesView()
                pied
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle(TextesMaFederation.titre)
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("ma-federation")
    }

    // MARK: Blocs

    private var entete: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(TextesMaFederation.titre)
                .font(Police.grandTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            if let departement = libelleDepartement {
                Text(departement).font(Police.sousTitre).foregroundStyle(Palette.encre)
            }
            if let libelle = federation.libelleFederation {
                Text(libelle).font(Police.detail).foregroundStyle(Palette.encreDouce)
            }
        }
    }

    /// « Val-de-Marne · 94 », ou le code seul quand le nom manque.
    private var libelleDepartement: String? {
        let nom = federation.nomDepartement.trimmingCharacters(in: .whitespacesAndNewlines)
        if federation.code.isEmpty { return nil }
        return nom.isEmpty ? "Département \(federation.code)" : "\(nom) · \(federation.code)"
    }

    private var liens: some View {
        VStack(spacing: 0) {
            if let site = federation.site {
                LigneLien(titre: TextesMaFederation.siteFederation, icone: "globe", url: site, identifiant: "lien-site")
                separateur
            }
            if let evenements = federation.evenements {
                LigneLien(titre: TextesMaFederation.evenements, icone: "calendar", url: evenements, identifiant: "lien-evenements")
                separateur
            }
            if let cartes = federation.cartesNationales {
                LigneLien(titre: TextesMaFederation.cartesNationales, icone: "creditcard", url: cartes, identifiant: "lien-cartes")
            }
        }
        .tuileFishMe()
    }

    private var separateur: some View {
        Rectangle().fill(Palette.filet).frame(height: 0.5).padding(.leading, Espace.l)
    }

    private var pied: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(TextesMaFederation.reglesLocales)
            Text(TextesMaFederation.renseigneToi)
            if federation.verifie, let jour = federation.releveLe {
                Text(TextesMaFederation.releveLe(jour.texte))
            }
            ForEach(federation.notes, id: \.self) { note in
                Text(note)
            }
        }
        .font(Police.legende)
        .foregroundStyle(Palette.encreDouce)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Une ligne à un toucher qui ouvre un site dans Safari (jamais dans l'app).
private struct LigneLien: View {
    let titre: String
    let icone: String
    let url: URL
    let identifiant: String

    var body: some View {
        Link(destination: url) {
            HStack(spacing: Espace.m) {
                Image(systemName: icone)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                Text(titre)
                    .font(Police.corps).foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .padding(.vertical, Espace.s)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .accessibilityHint(TextesMaFederation.ouvreSafari)
        .accessibilityIdentifier(identifiant)
    }
}
