import Core
import SwiftUI

/// La page « Amis » de l'onglet Communauté : un gros bouton pour inviter, la liste des amis, puis le fil des cartes
/// que les amis ont publiées pour leurs amis. Tout vient de `GestionAmis` (invitations, cache, règle 1.2 d'Apple).
/// Pour un ami, seuls le mois et l'année d'une carte comptent : le fil écrit donc « octobre 2026 », pas un jour exact.
struct AmisPageView: View {
    let gestion: GestionAmis?
    /// Mode démo (réglages) : sans iCloud non plus, la page montre ses amis de démo.
    @AppStorage("demo.communaute") private var demo = false

    init(gestion: GestionAmis?) {
        self.gestion = gestion
    }

    var body: some View {
        if let gestion {
            AmisPageContenu(gestion: gestion)
        } else if demo {
            ScrollView {
                DemoAmisContenu(avecInviter: true)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, Espace.xl)
            }
            .scrollIndicators(.hidden)
        } else {
            ContentUnavailableView("Amis", systemImage: "person.2.slash",
                                   description: Text("Tes amis ne peuvent pas s'ouvrir pour l'instant."))
        }
    }
}

/// Une carte du fil avec l'ami qui l'a publiée.
private struct CarteDuFil: Identifiable {
    let ami: Ami
    let carte: CartePartagee
    var id: UUID { carte.id }
}

/// Ce que la personne est en train de confirmer pour un ami.
private enum ActionSurAmi {
    case retirer(Ami)
    case bloquer(Ami)

    var ami: Ami {
        switch self {
        case .retirer(let ami), .bloquer(let ami): return ami
        }
    }

    var question: String {
        switch self {
        case .retirer(let ami): return "Retirer \(ami.nom) de tes amis ?"
        case .bloquer(let ami): return "Bloquer \(ami.nom) ? Ses cartes disparaissent et il ne voit plus les tiennes."
        }
    }
}

private struct AmisPageContenu: View {
    let gestion: GestionAmis

    @State private var amiOuvert: Ami?
    @State private var carteOuverte: CarteDuFil?
    @State private var action: ActionSurAmi?
    @State private var confirmerSuppression = false
    @Environment(\.openURL) private var ouvrirURL
    /// Mode démo : amis et fil d'exemple, locaux à la vue (voir `DemoAmis.swift`).
    @AppStorage("demo.communaute") private var demo = false

    /// Combien de cartes le fil montre au plus.
    private static let longueurDuFil = 30

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                entete
                if demo {
                    if gestion.compte == .disponible { inviter }
                    DemoAmisContenu()
                } else {
                    if let message = texteDuMessage { bandeau(message) }
                    if let invitation = gestion.invitationRecue { demande(invitation) }
                    if gestion.compte == .disponible { inviter }
                    if gestion.proposerInvitationEnRetour { enRetour }
                    listeDesAmis
                    fil
                    if gestion.partageActif { suppression }
                }
                Text("Tu ne vois que les collections de tes amis. Le lieu d'une prise s'arrête au département.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
            .padding(.bottom, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .task { await gestion.actualiser() }
        .task { await gestion.surveillerLeReseau() }
        .task { prendreLInvitation() }
        .fullScreenCover(item: $amiOuvert) { ami in
            PescedexAmiView(gestion: gestion, ami: ami, fermer: { amiOuvert = nil })
        }
        .sheet(item: $carteOuverte) { element in
            CarteAmiDetail(carte: element.carte, nomEspece: gestion.espece(element.carte.espece)?.nom ?? "") {
                if let url = gestion.urlDeSignalement(ami: element.ami, carte: element.carte) { ouvrirURL(url) }
            }
        }
        .confirmationDialog(action?.question ?? "", isPresented: confirmationAffichee, titleVisibility: .visible,
                            presenting: action) { action in
            switch action {
            case .retirer(let ami):
                Button("Retirer", role: .destructive) { Task { await gestion.retirer(ami) } }
            case .bloquer(let ami):
                Button("Bloquer", role: .destructive) { Task { await gestion.bloquer(ami) } }
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var confirmationAffichee: Binding<Bool> {
        Binding(get: { action != nil }, set: { if !$0 { action = nil } })
    }

    // MARK: En-tête, messages, invitations

    private var entete: some View {
        HStack {
            Text("Amis")
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
            Spacer()
            Button {
                Task { await gestion.actualiser() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.marine)
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
            }
            .accessibilityLabel("Actualiser")
        }
    }

    private var texteDuMessage: String? {
        if gestion.cartesEnAttente > 0 {
            return gestion.cartesEnAttente == 1 ? "1 carte part au retour du réseau." : "\(gestion.cartesEnAttente) cartes partent au retour du réseau."
        }
        switch gestion.message {
        case .iCloudIndisponible: return "Connecte-toi à iCloud pour voir tes amis. Ton Pescedex reste là."
        case .horsLigne: return "Pas de réseau : les dernières cartes de tes amis restent lisibles."
        case .iCloudPlein: return "Ton iCloud est plein."
        case .echec: return "Ça n'a pas marché. Réessaie avec Actualiser."
        case nil: return nil
        }
    }

    private func bandeau(_ texte: String) -> some View {
        HStack(spacing: Espace.m) {
            Text(texte)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
            if gestion.compte == .indisponible, let reglages = URL(string: UIApplication.openSettingsURLString) {
                Link("Réglages", destination: reglages)
                    .font(Police.detail)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tuileFishMe()
    }

    private func demande(_ invitation: InvitationRecue) -> some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Demande")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
            HStack(spacing: Espace.m) {
                Avatar(nom: invitation.nomAmi)
                Text("\(invitation.nomAmi) veut partager sa collection avec toi")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
            }
            HStack(spacing: Espace.m) {
                Button("Accepter") { Task { await gestion.accepterLInvitation() } }
                    .buttonStyle(.principal)
                Button("Refuser") { gestion.refuserLInvitation() }
                    .buttonStyle(.secondaire)
            }
        }
        .padding(Espace.l)
        .tuileFishMe()
    }

    /// Le gros bouton du haut : le lien d'invitation est un partage iCloud réservé aux personnes invitées, en lecture seule.
    private var inviter: some View {
        ShareLink(item: lienDInvitation, preview: SharePreview("Mon Pescedex")) {
            Label("Inviter un ami", systemImage: "person.badge.plus")
                .font(Police.sousTitre)
                .padding(.vertical, Espace.s)
        }
        .buttonStyle(.principal)
    }

    private var enRetour: some View {
        HStack {
            ShareLink(item: lienDInvitation, preview: SharePreview("Mon Pescedex")) {
                Label("Inviter en retour", systemImage: "arrow.uturn.right")
                    .font(Police.corps)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            Spacer()
            Button {
                gestion.fermerLaProposition()
            } label: {
                Image(systemName: "xmark")
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
            }
            .accessibilityLabel("Fermer")
        }
    }

    private var lienDInvitation: InvitationPescedex {
        let gestion = self.gestion
        return InvitationPescedex(conteneur: gestion.configuration.conteneur) {
            try await gestion.preparerLePartage()
        }
    }

    // MARK: Liste des amis

    private var listeDesAmis: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Tes amis")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            if gestion.amis.isEmpty {
                videHonnete("Aucun ami pour l'instant. Invite-en un pour voir ses cartes ici.", symbole: "person.2")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(gestion.amis.enumerated()), id: \.element.id) { index, ami in
                        rangee(ami)
                        if index < gestion.amis.count - 1 { Divider() }
                    }
                }
                .padding(.leading, Espace.l)
                .tuileFishMe()
            }
        }
    }

    private func rangee(_ ami: Ami) -> some View {
        HStack(spacing: 0) {
            if ami.enAttente && !ami.jeVoisSaCollection {
                contenuDeRangee(ami, detail: "invitation envoyée", ouvrable: false)
            } else {
                Button { amiOuvert = ami } label: { contenuDeRangee(ami, detail: detail(de: ami), ouvrable: true) }
                    .buttonStyle(.plain)
            }
            // Signaler, bloquer et retirer restent à portée de toucher pour chaque ami (règle 1.2 d'Apple).
            Menu {
                if let url = gestion.urlDeSignalement(ami: ami) {
                    Link(destination: url) { Label("Signaler", systemImage: "flag") }
                }
                Button(role: .destructive) { action = .bloquer(ami) } label: { Label("Bloquer", systemImage: "hand.raised") }
                Button(role: .destructive) { action = .retirer(ami) } label: {
                    Label("Retirer cet ami", systemImage: "person.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Plus d'actions pour \(ami.nom)")
        }
    }

    private func contenuDeRangee(_ ami: Ami, detail: String, ouvrable: Bool) -> some View {
        HStack(spacing: Espace.m) {
            Avatar(nom: ami.nom)
            VStack(alignment: .leading, spacing: 2) {
                Text(ami.nom).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(1).minimumScaleFactor(0.7)
                Text(detail).font(Police.detail).foregroundStyle(Palette.encreDouce).lineLimit(2)
            }
            Spacer(minLength: Espace.s)
            if ouvrable { Image(systemName: "chevron.right").foregroundStyle(Palette.encreDouce) }
        }
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Le nombre de cartes n'est donné que si la collection de l'ami est lisible ici.
    private func detail(de ami: Ami) -> String {
        guard ami.jeVoisSaCollection else { return "voit ta collection" }
        let n = gestion.collections.first { $0.id == ami.id }?.cartes.filter { !$0.bredouille }.count ?? 0
        return n == 1 ? "1 carte" : "\(n) cartes"
    }

    // MARK: Fil des nouvelles cartes

    /// Les cartes des amis dont je vois la collection, les plus récentes d'abord. Une sortie bredouille n'est pas une carte.
    private var cartesDuFil: [CarteDuFil] {
        let toutes = gestion.collections.flatMap { collection in
            collection.cartes.filter { !$0.bredouille }.map { CarteDuFil(ami: collection.ami, carte: $0) }
        }
        let tries = toutes.sorted {
            $0.carte.date != $1.carte.date ? $0.carte.date > $1.carte.date : $0.id.uuidString < $1.id.uuidString
        }
        return Array(tries.prefix(Self.longueurDuFil))
    }

    @ViewBuilder
    private var fil: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Nouvelles cartes")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            let cartes = cartesDuFil
            if cartes.isEmpty {
                videHonnete(gestion.amis.isEmpty
                            ? "Aucun ami pour l'instant. Invite-en un pour voir ses cartes ici."
                            : "Tes amis n'ont pas encore publié de carte.",
                            symbole: "rectangle.stack")
            } else {
                GrilleCartesAmis(cartes: cartes.map(elementDeGrille)) { choisie in
                    carteOuverte = cartes.first { $0.id.uuidString == choisie.id }
                }
            }
        }
    }

    /// La carte du fil, au dessin des cartes d'Adem : cadre de rareté, poisson, prénom et mois dessous.
    private func elementDeGrille(_ element: CarteDuFil) -> CarteAmiGrille {
        let carte = element.carte
        let espece = gestion.espece(carte.espece)
        return CarteAmiGrille(id: carte.id.uuidString, prenom: element.ami.nom, mois: JetonAmis.date(carte.date),
                              style: StyleRarete(carte.rarete), nomEspece: espece?.nom ?? "Espèce",
                              imageEspece: espece?.image, imageCarte: carte.image, tailleCm: carte.tailleCm)
    }

    // MARK: Pièces communes

    private func videHonnete(_ texte: String, symbole: String) -> some View {
        VStack(spacing: Espace.s) {
            Image(systemName: symbole)
                .font(Police.titre)
                .foregroundStyle(Palette.silhouette)
            Text(texte)
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Espace.xl)
        .tuileFishMe()
        .accessibilityElement(children: .combine)
    }

    private var suppression: some View {
        Button("Supprimer mes cartes partagées", role: .destructive) { confirmerSuppression = true }
            .font(Police.detail)
            .frame(minHeight: Gabarit.zoneTactile)
            .confirmationDialog("Tes amis ne verront plus tes cartes. Ton Pescedex reste sur ton iPhone.",
                                isPresented: $confirmerSuppression, titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { Task { await gestion.supprimerMesCartesPartagees() } }
                Button("Garder", role: .cancel) {}
            }
    }

    private func prendreLInvitation() {
        if let invitation = RelaisInvitations.partage.enAttente { gestion.invitationRecue = invitation }
    }
}

#if DEBUG
/// Aperçu sans réseau : faux service en mémoire, deux amis de démonstration (jamais compilés hors DEBUG).
nonisolated private struct CollectionDApercu: CollectionCartes {
    func cartes() async -> [Prise] { [] }
    func imagePNG(de carte: Prise) async -> Data? { nil }
}

@MainActor
private func gestionDApercu(avecAmis: Bool) -> GestionAmis? {
    let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("apercu-amis-\(UUID().uuidString)")
    guard let conteneur = try? CacheAmis.creerConteneur(enMemoire: true) else { return nil }
    let recues: [CollectionAmi] = avecAmis ? [
        CollectionAmi(ami: Ami(id: "apercu-lea", nom: "Léa", sens: .recu), cartes: [
            CartePartagee(id: UUID(), espece: "brochet", rarete: .rare, date: CartePartagee.moisEtAnnee(Date()), tailleCm: 62,
                          bredouille: false, departement: "94"),
            CartePartagee(id: UUID(), espece: "perche", rarete: .commun, date: CartePartagee.moisEtAnnee(Date()), tailleCm: 28,
                          bredouille: false, departement: "94"),
        ]),
        CollectionAmi(ami: Ami(id: "apercu-sam", nom: "Sam", sens: .recu), cartes: [
            CartePartagee(id: UUID(), espece: "sandre", rarete: .peuCommun, date: CartePartagee.moisEtAnnee(Date(timeIntervalSinceNow: -40 * 86_400)),
                          tailleCm: nil, bredouille: false, departement: "77"),
        ]),
    ] : []
    return GestionAmis(service: FauxServiceAmis(recues: recues),
                       cache: CacheAmis(conteneur: conteneur, dossierImages: dossier.appendingPathComponent("img")),
                       file: FileEnvoi(dossier: dossier.appendingPathComponent("file")),
                       collection: CollectionDApercu(), especes: EspecesFaux(),
                       configuration: ConfigurationAmis(contact: "contact@exemple.invalid"))
}

#Preview("Avec des amis") {
    AmisPageView(gestion: gestionDApercu(avecAmis: true))
}

#Preview("Aucun ami") {
    AmisPageView(gestion: gestionDApercu(avecAmis: false))
}

#Preview("Indisponible") {
    AmisPageView(gestion: nil)
}
#endif
