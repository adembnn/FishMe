import Observation
import SwiftUI

/// La recherche d'un ami par son surnom : 3 lettres au moins, requête `BEGINSWITH` côté CloudKit.
/// `discoverUserIdentities` n'est pas utilisé (déprécié depuis iOS 17). Les profils bloqués et le mien n'apparaissent pas.
@MainActor
@Observable
final class RechercheProfils {
    enum Etat: Equatable {
        case repos
        case chargement
        case resultats
        case horsLigne
        case echec
    }

    static let lettresMin = 3

    private(set) var texte = ""
    private(set) var resultats: [ProfilModele] = []
    private(set) var etat: Etat = .repos

    private let service: any ServiceProfil
    private let profil: GestionProfil
    private let attente: Duration
    private var tache: Task<Void, Never>?

    init(service: any ServiceProfil, profil: GestionProfil, attente: Duration = .milliseconds(300)) {
        self.service = service
        self.profil = profil
        self.attente = attente
    }

    var assezLong: Bool { Surnom.normaliser(texte).count >= Self.lettresMin }

    /// Appelé à chaque frappe : relance la recherche après une courte pause.
    func saisir(_ nouveau: String) {
        guard nouveau != texte else { return }
        texte = nouveau
        lancer()
    }

    private func lancer() {
        tache?.cancel()
        guard assezLong else {
            resultats = []
            etat = .repos
            return
        }
        tache = Task { await chercher() }
    }

    /// Cherche maintenant (les tests l'appellent sans attendre).
    func chercher() async {
        let saisie = texte
        guard Surnom.normaliser(saisie).count >= Self.lettresMin else { return }
        etat = .chargement
        do {
            try await Task.sleep(for: attente)
            let trouves = try await service.chercher(prefixe: saisie)
            guard !Task.isCancelled, saisie == texte else { return }
            let moi = profil.monID
            resultats = trouves.filter { $0.id != moi && !profil.estCache($0.id) }
            etat = .resultats
        } catch is CancellationError {
            return
        } catch {
            guard saisie == texte else { return }
            resultats = []
            etat = (error as? ErreurProfil) == .reseau ? .horsLigne : .echec
        }
    }
}

/// Le champ de recherche de la page Amis et ses résultats : avatar, surnom, un toucher ouvre la page du profil.
struct RechercheAmisView: View {
    let recherche: RechercheProfils
    let choisir: (ProfilModele) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            HStack(spacing: Espace.s) {
                Image(systemName: "magnifyingglass").foregroundStyle(Palette.encreDouce)
                TextField("Chercher un ami par son surnom", text: Binding(get: { recherche.texte }, set: { recherche.saisir($0) }))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Police.corps)
                    .accessibilityIdentifier("profil.recherche")
            }
            .padding(Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            contenu
        }
    }

    @ViewBuilder private var contenu: some View {
        switch recherche.etat {
        case .repos:
            if !recherche.texte.isEmpty {
                note("Écris 3 lettres au moins.")
            }
        case .chargement:
            ProgressView().frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        case .horsLigne:
            note("Pas de réseau. Réessaie plus tard.")
        case .echec:
            note("La recherche n'a pas marché. Réessaie.")
        case .resultats:
            if recherche.resultats.isEmpty {
                note("Personne avec ce surnom.")
            } else {
                VStack(spacing: 0) {
                    ForEach(recherche.resultats) { profil in
                        Button { choisir(profil) } label: {
                            HStack(spacing: Espace.m) {
                                AvatarSurnom(surnom: profil.surnom, image: profil.avatar)
                                Text(profil.surnom).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(2)
                                Spacer(minLength: Espace.s)
                                Image(systemName: "chevron.right").foregroundStyle(Palette.encreDouce)
                            }
                            .frame(minHeight: 60)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(profil.surnom)
                        if profil.id != recherche.resultats.last?.id { Divider() }
                    }
                }
                .padding(.horizontal, Espace.l)
                .tuileFishMe()
            }
        }
    }

    private func note(_ texte: String) -> some View {
        Text(texte).font(Police.detail).foregroundStyle(Palette.encreDouce)
    }
}
