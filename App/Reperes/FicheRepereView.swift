import Core
import SwiftUI

/// La fiche d'un repère : nom, icône, note, photos, dernier passage, avertissement de réserve, « Y aller », « Règles ici »,
/// « Modifier », « Supprimer ». Rien ne part de l'iPhone d'ici : pas de bouton « Partager ».
struct FicheRepereView: View {
    @Environment(\.locale) private var locale
    let repere: Repere
    var modele: ModeleReperes = .partage
    var contexte: ContexteReperes = .courant
    var surSuppression: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var ouvrirURL
    @State private var lieu: LieuDuRepere?
    @State private var photosDesPrises: [PhotoDePrise] = []
    @State private var edition = false
    @State private var suppressionDemandee = false
    @State private var choixDestination = false
    @State private var confirmation: DestinationRepere?
    @State private var messageApplication: String?
    @State private var messageErreur: String?

    /// La version la plus récente (après une modification), à défaut celle reçue.
    private var courant: Repere { modele.repere(id: repere.id) ?? repere }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                entete
                if !courant.note.isEmpty {
                    Text(courant.note).font(Police.corps).foregroundStyle(Palette.encre)
                        .fixedSize(horizontal: false, vertical: true)
                }
                passage
                photos
                reserve
                actions
                if let messageApplication {
                    Text(messageApplication).font(Police.detail).foregroundStyle(Palette.alerte)
                }
                if let messageErreur {
                    Text(messageErreur).font(Police.detail).foregroundStyle(Palette.alerte)
                }
                Text(TextesReperes.t(TextesReperes.prive, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        // Recalculé à chaque ouverture, jamais stocké : un verdict stocké se périmerait.
        .task(id: courant.position) { await calculerLieu() }
        .task(id: courant.idsPrises) { await chargerPhotosDesPrises() }
        .sheet(isPresented: $edition) { ModifierRepereView(repere: courant, modele: modele) }
        .confirmationDialog(TextesReperes.t(TextesReperes.supprimerQuestion, locale), isPresented: $suppressionDemandee, titleVisibility: .visible) {
            Button(TextesReperes.t(TextesReperes.supprimer, locale), role: .destructive) { supprimer() }
            Button(TextesReperes.t(TextesReperes.annuler, locale), role: .cancel) {}
        } message: {
            Text(TextesReperes.t(TextesReperes.supprimerExplication, locale))
        }
        .confirmationDialog(TextesReperes.t(TextesReperes.yAller, locale), isPresented: $choixDestination, titleVisibility: .visible) {
            ForEach(DestinationRepere.allCases) { destination in
                Button(destination.nom) { choisir(destination) }
            }
            Button(TextesReperes.t(TextesReperes.annuler, locale), role: .cancel) {}
        }
        .alert(confirmation.map { TextesReperes.confirmerTiers($0.nom, locale: locale) } ?? "", isPresented: confirmationOuverte) {
            Button("Continuer") {
                if let destination = confirmation { ouvrir(destination) }
                confirmation = nil
            }
            Button(TextesReperes.t(TextesReperes.annuler, locale), role: .cancel) { confirmation = nil }
        }
    }

    private var confirmationOuverte: Binding<Bool> {
        Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } })
    }

    // MARK: Parties

    private var entete: some View {
        HStack(alignment: .center, spacing: Espace.m) {
            IconeRepereView(type: courant.icone, taille: Gabarit.zoneTactile, suitLeTexte: true, decoratif: true)
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(courant.nom).font(Police.titre).foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                Text(TextesReperes.libelle(courant.icone, locale: locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                if let lieu { Text(lieu.lieuFlou).font(Police.legende).foregroundStyle(Palette.encreDouce) }
            }
            Spacer(minLength: 0)
            BoutonRond(role: .fermer) { dismiss() }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(courant.nom), \(TextesReperes.libelle(courant.icone, locale: locale))")
    }

    private var passage: some View {
        HStack {
            Text(TextesReperes.t(TextesReperes.dernierPassage, locale)).font(Police.detail).foregroundStyle(Palette.encreDouce)
            Spacer(minLength: Espace.s)
            Text(texteDernierPassage).font(Police.detail).foregroundStyle(Palette.encre)
        }
        .accessibilityElement(children: .combine)
    }

    private var texteDernierPassage: String {
        guard let date = courant.dernierPassage(prises: contexte.prises()) else { return TextesReperes.t(TextesReperes.jamaisNote, locale) }
        return date.formatted(.dateTime.day().month(.wide).year().locale(locale))
    }

    @ViewBuilder private var photos: some View {
        if !courant.photos.isEmpty || !photosDesPrises.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                if !courant.photos.isEmpty {
                    Text(TextesReperes.t(TextesReperes.photosDuRepere, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                    ScrollView(.horizontal) {
                        HStack(spacing: Espace.s) {
                            ForEach(courant.photos, id: \.self) { nom in
                                VignettePhotoRepere(charger: { await modele.photo(nom) })
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
                if !photosDesPrises.isEmpty {
                    Text(TextesReperes.t(TextesReperes.photosDesPrises, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                    ScrollView(.horizontal) {
                        HStack(spacing: Espace.s) {
                            ForEach(photosDesPrises) { photo in
                                VignettePhotoRepere(charger: { photo.donnees })
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    @ViewBuilder private var reserve: some View {
        if let lieu {
            AvertissementReserveView(avertissement: lieu.avertissement, horsDeFrance: lieu.horsDeFrance)
        }
    }

    private var actions: some View {
        VStack(spacing: Espace.s) {
            Button { choixDestination = true } label: {
                Label(TextesReperes.t(TextesReperes.yAller, locale), systemImage: "location.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.principal)

            if let reglesIci = contexte.reglesIci {
                Button { reglesIci(courant.position) } label: {
                    Label(TextesReperes.t(TextesReperes.reglesIci, locale), systemImage: "list.bullet.clipboard").frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondaire)
            }

            Button { noterPassage() } label: {
                Label(TextesReperes.t(TextesReperes.noterPassage, locale), systemImage: "calendar.badge.plus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondaire)

            HStack(spacing: Espace.s) {
                Button { edition = true } label: {
                    Label(TextesReperes.t(TextesReperes.modifier, locale), systemImage: "pencil").frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondaire)
                Button(role: .destructive) { suppressionDemandee = true } label: {
                    Label(TextesReperes.t(TextesReperes.supprimer, locale), systemImage: "trash").frame(maxWidth: .infinity)
                }
                .buttonStyle(.secondaire)
            }
        }
        .disabled(modele.lectureSeule)
    }

    // MARK: Actions

    private func calculerLieu() async {
        guard let geo = contexte.geo else { return }
        let position = courant.position
        let chargeur = contexte.chargeur
        // Lecture des fichiers de règles hors du fil principal.
        lieu = await Task.detached(priority: .userInitiated) {
            EvaluationReserve.evaluer(position: position, geo: geo, chargeur: chargeur)
        }.value
    }

    private func chargerPhotosDesPrises() async {
        guard let source = contexte.photosDesPrises, !courant.idsPrises.isEmpty else { photosDesPrises = []; return }
        photosDesPrises = await source.photos(de: courant.idsPrises)
    }

    private func choisir(_ destination: DestinationRepere) {
        messageApplication = nil
        if destination.demandeConfirmation { confirmation = destination } else { ouvrir(destination) }
    }

    private func ouvrir(_ destination: DestinationRepere) {
        guard let url = AllerAuRepere.url(pour: destination, position: courant.position) else { return }
        // ⚠ à vérifier : isolation de la fermeture de `OpenURLAction` selon le SDK ; la remise sur le fil principal est explicite.
        ouvrirURL(url) { accepte in
            Task { @MainActor in
                if !accepte { messageApplication = TextesReperes.t(TextesReperes.applicationAbsente, locale) }
            }
        }
    }

    private func noterPassage() {
        Task {
            do { try await modele.noterPassage(id: courant.id) } catch { messageErreur = TextesReperes.t(TextesReperes.enregistrementImpossible, locale) }
        }
    }

    private func supprimer() {
        Task {
            do {
                try await modele.supprimer(id: courant.id)
                surSuppression()
                dismiss()
            } catch {
                messageErreur = TextesReperes.t(TextesReperes.enregistrementImpossible, locale)
            }
        }
    }
}

/// « Modifier le repère » : nom, icône, note et photos. La position ne change pas.
struct ModifierRepereView: View {
    @Environment(\.locale) private var locale
    let repere: Repere
    var modele: ModeleReperes = .partage

    @Environment(\.dismiss) private var dismiss
    @State private var nom: String
    @State private var icone: IconeRepere
    @State private var note: String
    @State private var message: String?

    init(repere: Repere, modele: ModeleReperes = .partage) {
        self.repere = repere
        self.modele = modele
        _nom = State(initialValue: repere.nom)
        _icone = State(initialValue: repere.icone)
        _note = State(initialValue: repere.note)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text(TextesReperes.t(TextesReperes.modifierTitre, locale)).font(Police.titre).foregroundStyle(Palette.encre)
                ChampsRepere(nom: $nom, icone: $icone, note: $note)
                if let message {
                    Text(message).font(Police.detail).foregroundStyle(Palette.alerte)
                }
                Button(TextesReperes.t(TextesReperes.enregistrer, locale)) { enregistrer() }
                    .buttonStyle(.principal)
                    .disabled(Repere.nomPropre(nom) == nil)
                Button(TextesReperes.t(TextesReperes.annuler, locale)) { dismiss() }
                    .buttonStyle(.secondaire)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .scrollDismissesKeyboard(.interactively)
    }

    private func enregistrer() {
        Task {
            do {
                try await modele.modifier(id: repere.id, nom: nom, note: note, icone: icone)
                dismiss()
            } catch ErreurAjoutRepere.invalide(let erreur) {
                message = TextesReperes.message(erreur, locale: locale)
            } catch {
                message = TextesReperes.t(TextesReperes.enregistrementImpossible, locale)
            }
        }
    }
}
