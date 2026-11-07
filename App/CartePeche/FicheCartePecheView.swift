import Core
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// « Ma carte de pêche » : une copie personnelle de la carte (photo ou PDF), son millésime, l'association,
/// la date d'expiration et un rappel 30 jours avant. Ce n'est pas une carte officielle et rien ne se synchronise.
/// Posée dans le Profil par L21 (demande dans `docs/fiches/N5.md`).
struct FicheCartePecheView: View {
    @StateObject private var modele: ModeleCartePeche
    @State private var selectionPhoto: PhotosPickerItem?
    @State private var choixPDFOuvert = false
    @State private var pleinEcranOuvert = false
    @State private var confirmationOuverte = false
    @State private var association = ""
    @Environment(\.locale) private var locale

    init(modele: ModeleCartePeche? = nil) {
        _modele = StateObject(wrappedValue: modele ?? ModeleCartePeche.reel())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                Text(AnglaisE.t(TextesCartePeche.titre, locale))
                    .font(Police.grandTitre).foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)

                if let message = modele.message {
                    Text(AnglaisE.t(message, locale))
                        .font(Police.detail).foregroundStyle(Palette.alerte)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("carte-message")
                }

                if let fiche = modele.fiche {
                    contenu(fiche)
                } else {
                    vide
                }

                mentions
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .navigationTitle(AnglaisE.t(TextesCartePeche.titre, locale))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            modele.locale = locale
            modele.charger()
            association = modele.fiche?.association ?? ""
        }
        .onChange(of: selectionPhoto) { _, choix in
            guard let choix else { return }
            Task {
                if let donnees = try? await choix.loadTransferable(type: Data.self) {
                    modele.importer(donnees: donnees, genre: .image)
                    association = modele.fiche?.association ?? ""
                } else {
                    modele.message = TextesCartePeche.fichierIllisible
                }
                selectionPhoto = nil
            }
        }
        .fileImporter(isPresented: $choixPDFOuvert, allowedContentTypes: [.pdf, .image]) { resultat in
            if case .success(let url) = resultat {
                modele.importer(depuis: url)
                association = modele.fiche?.association ?? ""
            }
        }
        .fullScreenCover(isPresented: $pleinEcranOuvert) {
            if let fiche = modele.fiche, let donnees = modele.donneesFichier {
                CartePechePleinEcranView(genre: fiche.fichier.genre, donnees: donnees)
            }
        }
        .confirmationDialog(AnglaisE.t(TextesCartePeche.supprimer, locale) + (locale.language.languageCode?.identifier == "fr" ? " ?" : "?"), isPresented: $confirmationOuverte, titleVisibility: .visible) {
            Button(AnglaisE.t(TextesCartePeche.supprimer, locale), role: .destructive) {
                Task {
                    await modele.supprimer()
                    association = ""
                }
            }
            Button(AnglaisE.t(TextesCartePeche.annuler, locale), role: .cancel) {}
        } message: {
            Text(AnglaisE.t(TextesCartePeche.confirmationMessage, locale))
        }
        .onChange(of: locale) { _, nouvelle in modele.locale = nouvelle }
        .accessibilityIdentifier("fiche-carte-peche")
    }

    // MARK: Pas encore de carte

    private var vide: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text(AnglaisE.t(TextesCartePeche.vide, locale))
                .font(Police.corps).foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            boutonsImport(remplacement: false)
        }
    }

    @ViewBuilder
    private func boutonsImport(remplacement: Bool) -> some View {
        VStack(spacing: Espace.s) {
            if remplacement {
                PhotosPicker(selection: $selectionPhoto, matching: .images) {
                    Text(AnglaisE.t(TextesCartePeche.remplacer, locale))
                }
                .buttonStyle(.secondaire)
                .accessibilityIdentifier("carte-choisir-photo")
            } else {
                PhotosPicker(selection: $selectionPhoto, matching: .images) {
                    Text(AnglaisE.t(TextesCartePeche.choisirPhoto, locale))
                }
                .buttonStyle(.principal)
                .accessibilityIdentifier("carte-choisir-photo")
            }

            Button(AnglaisE.t(TextesCartePeche.choisirPDF, locale)) { choixPDFOuvert = true }
                .buttonStyle(.secondaire)
                .accessibilityIdentifier("carte-choisir-pdf")
        }
    }

    // MARK: Une carte est là

    @ViewBuilder
    private func contenu(_ fiche: FicheCartePeche) -> some View {
        apercu(fiche)

        VStack(spacing: 0) {
            ligneMillesime(fiche)
            separateur
            ligneAssociation
            separateur
            ligneExpiration(fiche)
        }
        .tuileFishMe()

        if !modele.erreursSaisie.isEmpty {
            VStack(alignment: .leading, spacing: Espace.xs) {
                ForEach(modele.erreursSaisie, id: \.self) { erreur in
                    Text(erreur.messageLocalise(locale))
                }
            }
            .font(Police.detail).foregroundStyle(Palette.alerte)
            .fixedSize(horizontal: false, vertical: true)
        }

        if let etat = modele.libelleEtat {
            Text(etat)
                .font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityIdentifier("carte-etat")
        }

        rappel(fiche)

        Button(AnglaisE.t(TextesCartePeche.afficherEnGrand, locale)) { pleinEcranOuvert = true }
            .buttonStyle(.principal)
            .disabled(modele.donneesFichier == nil)
            .accessibilityIdentifier("carte-afficher-en-grand")

        boutonsImport(remplacement: true)

        Button(AnglaisE.t(TextesCartePeche.supprimer, locale), role: .destructive) { confirmationOuverte = true }
            .font(Police.corps)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            .accessibilityIdentifier("carte-supprimer")
    }

    private var separateur: some View {
        Rectangle().fill(Palette.filet).frame(height: 0.5).padding(.leading, Espace.l)
    }

    private func apercu(_ fiche: FicheCartePeche) -> some View {
        Group {
            if let image = modele.apercu {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    .accessibilityLabel(TextesCartePeche.accessibiliteApercu(genre: fiche.fichier.genre == .pdf ? "PDF" : "photo", locale: locale))
            } else {
                Image(systemName: "doc")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.silhouette)
                    .frame(maxWidth: .infinity, minHeight: 160)
                    .accessibilityHidden(true)
            }
        }
        .padding(Espace.s)
        .tuileFishMe()
    }

    private func ligneMillesime(_ fiche: FicheCartePeche) -> some View {
        let maintenant = modele.jourDAujourdhui.annee
        let choix = Array((ValidationFiche.premierMillesime...(maintenant + 1)).reversed())
        return HStack {
            Text(AnglaisE.t(TextesCartePeche.millesime, locale)).font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: Espace.s)
            Picker(AnglaisE.t(TextesCartePeche.millesime, locale), selection: Binding(
                get: { fiche.millesime },
                set: { nouveau in Task { await modele.changerMillesime(nouveau) } }
            )) {
                ForEach(choix, id: \.self) { annee in Text(String(annee)).tag(annee) }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("carte-millesime")
        }
        .padding(.horizontal, Espace.l)
        .frame(minHeight: Gabarit.zoneTactile + 8)
    }

    private var ligneAssociation: some View {
        HStack {
            Text(AnglaisE.t(TextesCartePeche.association, locale)).font(Police.corps).foregroundStyle(Palette.encre)
            TextField(AnglaisE.t(TextesCartePeche.associationExemple, locale), text: $association)
                .font(Police.corps)
                .multilineTextAlignment(.trailing)
                .submitLabel(.done)
                .onChange(of: association) { _, texte in modele.changerAssociation(texte) }
                .accessibilityIdentifier("carte-association")
        }
        .padding(.horizontal, Espace.l)
        .frame(minHeight: Gabarit.zoneTactile + 8)
    }

    private func ligneExpiration(_ fiche: FicheCartePeche) -> some View {
        DatePicker(
            AnglaisE.t(TextesCartePeche.expiration, locale),
            selection: Binding(
                get: { fiche.expireLe.date(calendrier: .current) ?? Date() },
                set: { date in
                    let jour = JourCivil(date: date, calendrier: .current)
                    Task { await modele.changerExpiration(jour) }
                }),
            displayedComponents: .date
        )
        .font(Police.corps)
        .padding(.horizontal, Espace.l)
        .frame(minHeight: Gabarit.zoneTactile + 8)
        .accessibilityIdentifier("carte-expiration")
    }

    // MARK: Rappel

    private func rappel(_ fiche: FicheCartePeche) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Toggle(isOn: Binding(
                get: { fiche.rappelActif },
                set: { actif in Task { await modele.basculerRappel(actif) } }
            )) {
                Text(AnglaisE.t(TextesCartePeche.rappel, locale)).font(Police.corps).foregroundStyle(Palette.encre)
            }
            .tint(Palette.marine)
            .frame(minHeight: Gabarit.zoneTactile)
            .accessibilityIdentifier("carte-rappel")

            Text(AnglaisE.t(TextesCartePeche.rappelExplication, locale))
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)

            if let programme = modele.jourDuRappelAffiche {
                Text(programme).font(Police.detail).foregroundStyle(Palette.encre)
            }
            if let message = modele.messageRappel {
                Text(message)
                    .font(Police.detail).foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("carte-message-rappel")
            }
            if modele.notificationsCoupees {
                Text(AnglaisE.t(TextesCartePeche.notificationsCoupees, locale))
                    .font(Police.detail).foregroundStyle(Palette.alerte)
                    .fixedSize(horizontal: false, vertical: true)
                if let reglages = URL(string: UIApplication.openSettingsURLString) {
                    Link(AnglaisE.t(TextesCartePeche.ouvrirReglages, locale), destination: reglages)
                        .font(Police.corps).foregroundStyle(Palette.marine)
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
            }
        }
        .padding(Espace.l)
        .tuileFishMe()
    }

    // MARK: Mentions

    private var mentions: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(AnglaisE.t(TextesCartePeche.nonOfficiel, locale))
            Text(AnglaisE.t(TextesCartePeche.sauvegarde, locale))
        }
        .font(Police.legende)
        .foregroundStyle(Palette.encreDouce)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("carte-mentions")
    }
}
