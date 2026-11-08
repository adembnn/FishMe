import Core
import PhotosUI
import SwiftUI

/// Feuille « Nouveau repère » : nom (obligatoire), icône, note et photos facultatives.
/// Avec la position courante : bouton, nom, enregistrer = 3 touchers. Au 4e repère sans Pro, le paywall s'ouvre et la saisie reste.
struct NouveauRepereView: View {
    @Environment(\.locale) private var locale
    let position: Coordonnee
    var surAjout: (Repere) -> Void = { _ in }
    var modele: ModeleReperes = .partage
    var contexte: ContexteReperes = .courant

    @Environment(\.dismiss) private var dismiss
    @State private var nom = ""
    @State private var icone: IconeRepere = .poste
    @State private var note = ""
    @State private var choix: [PhotosPickerItem] = []
    @State private var photos: [Data] = []
    @State private var enCours = false
    @State private var message: String?
    @State private var paywallOuvert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text(TextesReperes.t(TextesReperes.nouveauTitre, locale)).font(Police.titre).foregroundStyle(Palette.encre)
                Text(TextesReperes.t(TextesReperes.prive, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                bandeauOffre
                ChampsRepere(nom: $nom, icone: $icone, note: $note)
                sectionPhotos
                if let message {
                    Text(message).font(Police.detail).foregroundStyle(Palette.alerte)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(action: enregistrer) {
                    Text(TextesReperes.t(TextesReperes.enregistrer, locale)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.principal)
                .disabled(enCours || Repere.nomPropre(nom) == nil)
                Button(TextesReperes.t(TextesReperes.annuler, locale)) { dismiss() }
                    .buttonStyle(.secondaire)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: choix) { _, nouveaux in Task { await charger(nouveaux) } }
        .task { await modele.chargerSiBesoin() }
        .interactiveDismissDisabled(enCours)
        .sheet(isPresented: $paywallOuvert) {
            if let vue = contexte.vuePaywall { vue { paywallOuvert = false } }
        }
    }

    /// Le paywall : présenté ici s'il y a une vue à présenter (la feuille est déjà ouverte), sinon par la racine.
    private func demanderPro() {
        if contexte.vuePaywall != nil { paywallOuvert = true } else { contexte.ouvrirPaywall?() }
    }

    /// Dit avant la saisie que la limite gratuite est atteinte (le contrôle de fond se refait à l'enregistrement).
    @ViewBuilder private var bandeauOffre: some View {
        switch modele.decision(abonne: contexte.abonne) {
        case .oui:
            EmptyView()
        case .paywall:
            VStack(alignment: .leading, spacing: Espace.s) {
                Text(TextesReperes.t(TextesReperes.paywallTitre, locale)).font(Police.sousTitre).foregroundStyle(Palette.encre)
                Text(TextesReperes.t(TextesReperes.paywallTexte, locale)).font(Police.detail).foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                if contexte.vuePaywall != nil || contexte.ouvrirPaywall != nil {
                    Button(TextesReperes.t(TextesReperes.voirPro, locale)) { demanderPro() }
                        .buttonStyle(.secondaire)
                }
            }
            .padding(Espace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.alerteDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        case .plafond:
            Text(TextesReperes.t(TextesReperes.plafondTexte, locale)).font(Police.detail).foregroundStyle(Palette.alerte)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var sectionPhotos: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(TextesReperes.t(TextesReperes.photosDuRepere, locale)).font(Police.legende).foregroundStyle(Palette.encreDouce)
            if !photos.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: Espace.s) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, donnees in
                            VignettePhotoRepere(charger: { donnees }, surRetrait: { photos.remove(at: index) })
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
            PhotosPicker(selection: $choix, maxSelectionCount: LimitesReperes.photosMax, matching: .images) {
                Label(TextesReperes.t(TextesReperes.ajouterPhotos, locale), systemImage: "photo.on.rectangle.angled")
                    .font(Police.detail)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
            }
        }
    }

    private func charger(_ elements: [PhotosPickerItem]) async {
        var lues: [Data] = []
        for element in elements.prefix(LimitesReperes.photosMax) {
            if let donnees = try? await element.loadTransferable(type: Data.self) { lues.append(donnees) }
        }
        photos = lues
    }

    private func enregistrer() {
        guard !enCours else { return }
        enCours = true
        message = nil
        Task {
            defer { enCours = false }
            do {
                let repere = try await modele.ajouter(nom: nom, note: note, icone: icone, position: position, photos: photos,
                                                      abonne: contexte.abonne)
                surAjout(repere)
                dismiss()
            } catch ErreurAjoutRepere.paywall {
                // La saisie reste à l'écran : le paywall s'ouvre par-dessus.
                message = TextesReperes.t(TextesReperes.paywallTexte, locale)
                demanderPro()
            } catch ErreurAjoutRepere.plafond {
                message = TextesReperes.t(TextesReperes.plafondTexte, locale)
            } catch ErreurAjoutRepere.invalide(let erreur) {
                message = TextesReperes.message(erreur, locale: locale)
            } catch ErreurAjoutRepere.lectureSeule {
                message = TextesReperes.t(TextesReperes.lectureSeule, locale)
            } catch {
                message = TextesReperes.t(TextesReperes.enregistrementImpossible, locale)
            }
        }
    }
}
