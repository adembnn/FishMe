import Core
import PhotosUI
import SwiftUI
import UIKit

/// Ajout d'une prise à la main, depuis une photo de la photothèque (retour du chef de projet, 16 oct.).
/// Trois étapes sobres : la photo, l'espèce (choisie par le pêcheur, l'IA ne propose rien ici),
/// puis taille, date et département. Aucune coordonnée ni lieu exact n'est demandé ni gardé.
struct AjoutManuelPriseView: View {
    /// Les espèces pêchables, la liste fermée de l'app (la même que la grille de la prise).
    let especes: [EspecePechable]
    /// Enregistre la carte : photo brute (nettoyée sans GPS à l'écriture), espèce, taille en cm, date, lieu flou.
    let creer: (Data, Espece, Int?, Date, String?) async -> Void

    private enum Etape: Int { case photo = 1, espece, details }

    @Environment(\.dismiss) private var dismiss
    @State private var etape = Etape.photo
    @State private var choix: PhotosPickerItem?
    @State private var photo: Data?
    @State private var apercu: UIImage?
    @State private var chargement = false
    @State private var recherche = ""
    @State private var espece: EspecePechable?
    @State private var avecTaille = false
    @State private var tailleCm = 40.0
    @State private var guideMesure = false
    @State private var date = Date()
    @State private var departement: DepartementChoix?
    @State private var choixDepartement = false
    @State private var pasUnPoisson = false
    @State private var enCours = false

    var body: some View {
        VStack(spacing: 0) {
            enTete
            Group {
                switch etape {
                case .photo: etapePhoto
                case .espece: etapeEspece
                case .details: etapeDetails
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord)
        }
        .interactiveDismissDisabled(enCours)
        .alert("Seuls les poissons font des cartes", isPresented: $pasUnPoisson) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text("Rien n'a été importé. Tu peux choisir une autre photo quand tu veux.")
        }
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            Task { await lire(nouveau) }
        }
    }

    // MARK: En-tête

    private var enTete: some View {
        VStack(spacing: Espace.xs) {
            Text("Ajouter une prise")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Text("Étape \(etape.rawValue) sur 3")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile + Espace.bord * 2)
        .padding(.horizontal, Gabarit.zoneTactile + Espace.bord * 2)
        .accessibilityElement(children: .combine)
    }

    // MARK: Étape 1, la photo

    private var etapePhoto: some View {
        VStack(spacing: Espace.l) {
            Group {
                if let apercu {
                    Image(uiImage: apercu)
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel("Photo choisie")
                } else {
                    ZStack {
                        Palette.tuile
                        if chargement {
                            ProgressView()
                        } else {
                            Image(systemName: "photo")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.silhouette)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))

            Text("Choisis la photo de ta prise dans ta photothèque. Le lieu éventuel de la photo n'est pas gardé.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)

            PhotosPicker(selection: $choix, matching: .images) {
                Label(photo == nil ? "Choisir une photo" : "Changer de photo", systemImage: "photo.on.rectangle")
            }
            .buttonStyle(.secondaire)

            Button("Continuer") { etape = .espece }
                .buttonStyle(.principal)
                .disabled(photo == nil)
                .opacity(photo == nil ? 0.5 : 1)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.l)
    }

    private func lire(_ item: PhotosPickerItem) async {
        chargement = true
        defer { chargement = false }
        guard let donnees = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: donnees) else { return }
        photo = donnees
        apercu = image
    }

    // MARK: Étape 2, l'espèce

    private var especesFiltrees: [EspecePechable] {
        let q = recherche.trimmingCharacters(in: .whitespaces)
        let tri = especes.sorted { $0.nom.localizedCompare($1.nom) == .orderedAscending }
        guard !q.isEmpty else { return tri }
        return tri.filter {
            $0.nom.localizedStandardContains(q) || $0.nomLatin.localizedStandardContains(q)
        }
    }

    private var etapeEspece: some View {
        VStack(spacing: Espace.s) {
            HStack(spacing: Espace.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
                TextField("Chercher une espèce", text: $recherche)
                    .font(Police.corps)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .tuileFishMe()
            .padding(.horizontal, Espace.bord)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(especesFiltrees, id: \.espece.id) { e in
                        ligneEspece(e)
                    }
                    if especesFiltrees.isEmpty {
                        Text("Aucune espèce ne correspond.")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .padding(Espace.xl)
                    }
                }
                .tuileFishMe()
                .padding(.horizontal, Espace.bord)
            }

            Button { pasUnPoisson = true } label: {
                Text("Ce n'est pas un poisson")
                    .font(Police.detail)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: Espace.s) {
                Button("Retour") { etape = .photo }
                    .buttonStyle(.secondaire)
                Button("Continuer") { etape = .details }
                    .buttonStyle(.principal)
                    .disabled(espece == nil)
                    .opacity(espece == nil ? 0.5 : 1)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.l)
        }
    }

    private func ligneEspece(_ e: EspecePechable) -> some View {
        let choisie = espece?.espece.id == e.espece.id
        return Button { espece = e } label: {
            HStack(spacing: Espace.m) {
                Image(e.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 36)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.nom)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                    Text(e.nomLatin)
                        .font(Police.legende)
                        .italic()
                        .foregroundStyle(Palette.encreDouce)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if choisie {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Espace.l)
            .padding(.vertical, Espace.s)
            .frame(minHeight: 56)
            .background(choisie ? Palette.marineDoux : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }

    // MARK: Étape 3, taille, date, lieu

    private var etapeDetails: some View {
        ScrollView {
            VStack(spacing: Espace.l) {
                if let espece {
                    HStack(spacing: Espace.m) {
                        Image(espece.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 44)
                            .accessibilityHidden(true)
                        Text(espece.nom)
                            .font(Police.sousTitre)
                            .foregroundStyle(Palette.encre)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                VStack(alignment: .leading, spacing: Espace.s) {
                    Toggle(isOn: $avecTaille) {
                        Text("Je connais la taille").font(Police.corps).foregroundStyle(Palette.encre)
                    }
                    .frame(minHeight: Gabarit.zoneTactile)
                    if avecTaille {
                        HStack {
                            Text("\(Int(tailleCm)) cm")
                                .font(Police.chiffreMoyen)
                                .foregroundStyle(Palette.encre)
                            Spacer()
                            Stepper("Taille", value: $tailleCm, in: 5...300, step: 1).labelsHidden()
                        }
                        Slider(value: $tailleCm, in: 5...150, step: 1)
                            .accessibilityLabel("Taille en centimètres")
                        // N5 : le geste de mesure (guide de « Ma fédération »), discret. // ⚠ à vérifier
                        Button("Comment mesurer ?") { guideMesure = true }
                            .font(Police.detail).foregroundStyle(Palette.marine)
                            .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                            .accessibilityIdentifier("comment-mesurer")
                    }
                }
                .padding(Espace.l)
                .tuileFishMe()

                DatePicker("Date de la prise", selection: $date, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    .font(Police.corps)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .padding(Espace.l)
                    .tuileFishMe()

                VStack(alignment: .leading, spacing: Espace.xs) {
                    Button { choixDepartement = true } label: {
                        HStack {
                            Text(departement?.libelle ?? "Choisir le département (facultatif)")
                                .font(Police.corps)
                                .foregroundStyle(departement == nil ? Palette.encreDouce : Palette.encre)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: Espace.s)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.encreDouce)
                                .accessibilityHidden(true)
                        }
                        .frame(minHeight: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Text("Seul le département est gardé, jamais un lieu précis.")
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
                .padding(Espace.l)
                .tuileFishMe()
                .sheet(isPresented: $choixDepartement) {
                    ChoixDepartementView(choisi: $departement)
                }
                .sheet(isPresented: $guideMesure) {
                    MesureGuideView()
                        .presentationDetents([.medium, .large])
                }

                HStack(spacing: Espace.s) {
                    Button("Retour") { etape = .espece }
                        .buttonStyle(.secondaire)
                        .disabled(enCours)
                    Button { Task { await valider() } } label: {
                        if enCours { ProgressView() } else { Text("Créer la carte") }
                    }
                    .buttonStyle(.principal)
                    .disabled(enCours || photo == nil || espece == nil)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.l)
        }
    }

    private func valider() async {
        guard let photo, let espece else { return }
        enCours = true
        await creer(photo, espece.espece, avecTaille ? Int(tailleCm) : nil, date, departement?.libelle)
        enCours = false
        dismiss()
    }
}

/// Un département métropolitain choisi dans la liste : le seul « lieu » que l'ajout manuel garde.
struct DepartementChoix: Hashable, Identifiable {
    let code: String
    let nom: String
    var id: String { code }
    /// Le lieu flou enregistré avec la carte, comme pour les autres prises : « Val-de-Marne · 94 ».
    var libelle: String { "\(nom) · \(code)" }

    /// Les départements métropolitains (01 à 95, 2A et 2B).
    static let metropole: [DepartementChoix] = [
        ("01", "Ain"), ("02", "Aisne"), ("03", "Allier"), ("04", "Alpes-de-Haute-Provence"), ("05", "Hautes-Alpes"),
        ("06", "Alpes-Maritimes"), ("07", "Ardèche"), ("08", "Ardennes"), ("09", "Ariège"), ("10", "Aube"),
        ("11", "Aude"), ("12", "Aveyron"), ("13", "Bouches-du-Rhône"), ("14", "Calvados"), ("15", "Cantal"),
        ("16", "Charente"), ("17", "Charente-Maritime"), ("18", "Cher"), ("19", "Corrèze"), ("2A", "Corse-du-Sud"),
        ("2B", "Haute-Corse"), ("21", "Côte-d'Or"), ("22", "Côtes-d'Armor"), ("23", "Creuse"), ("24", "Dordogne"),
        ("25", "Doubs"), ("26", "Drôme"), ("27", "Eure"), ("28", "Eure-et-Loir"), ("29", "Finistère"),
        ("30", "Gard"), ("31", "Haute-Garonne"), ("32", "Gers"), ("33", "Gironde"), ("34", "Hérault"),
        ("35", "Ille-et-Vilaine"), ("36", "Indre"), ("37", "Indre-et-Loire"), ("38", "Isère"), ("39", "Jura"),
        ("40", "Landes"), ("41", "Loir-et-Cher"), ("42", "Loire"), ("43", "Haute-Loire"), ("44", "Loire-Atlantique"),
        ("45", "Loiret"), ("46", "Lot"), ("47", "Lot-et-Garonne"), ("48", "Lozère"), ("49", "Maine-et-Loire"),
        ("50", "Manche"), ("51", "Marne"), ("52", "Haute-Marne"), ("53", "Mayenne"), ("54", "Meurthe-et-Moselle"),
        ("55", "Meuse"), ("56", "Morbihan"), ("57", "Moselle"), ("58", "Nièvre"), ("59", "Nord"),
        ("60", "Oise"), ("61", "Orne"), ("62", "Pas-de-Calais"), ("63", "Puy-de-Dôme"), ("64", "Pyrénées-Atlantiques"),
        ("65", "Hautes-Pyrénées"), ("66", "Pyrénées-Orientales"), ("67", "Bas-Rhin"), ("68", "Haut-Rhin"), ("69", "Rhône"),
        ("70", "Haute-Saône"), ("71", "Saône-et-Loire"), ("72", "Sarthe"), ("73", "Savoie"), ("74", "Haute-Savoie"),
        ("75", "Paris"), ("76", "Seine-Maritime"), ("77", "Seine-et-Marne"), ("78", "Yvelines"), ("79", "Deux-Sèvres"),
        ("80", "Somme"), ("81", "Tarn"), ("82", "Tarn-et-Garonne"), ("83", "Var"), ("84", "Vaucluse"),
        ("85", "Vendée"), ("86", "Vienne"), ("87", "Haute-Vienne"), ("88", "Vosges"), ("89", "Yonne"),
        ("90", "Territoire de Belfort"), ("91", "Essonne"), ("92", "Hauts-de-Seine"), ("93", "Seine-Saint-Denis"),
        ("94", "Val-de-Marne"), ("95", "Val-d'Oise"),
    ].map { DepartementChoix(code: $0.0, nom: $0.1) }
}

/// Liste cherchable des départements (par nom ou par code).
private struct ChoixDepartementView: View {
    @Binding var choisi: DepartementChoix?
    @Environment(\.dismiss) private var dismiss
    @State private var recherche = ""

    private var filtres: [DepartementChoix] {
        let q = recherche.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return DepartementChoix.metropole }
        return DepartementChoix.metropole.filter {
            $0.nom.localizedStandardContains(q) || $0.code.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        VStack(spacing: Espace.s) {
            Text("Département")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile + Espace.bord * 2)
            HStack(spacing: Espace.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
                TextField("Chercher un nom ou un code", text: $recherche)
                    .font(Police.corps)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .tuileFishMe()
            .padding(.horizontal, Espace.bord)
            ScrollView {
                LazyVStack(spacing: 0) {
                    ligne(titre: "Aucun département", selectionne: choisi == nil) { choisi = nil }
                    ForEach(filtres) { d in
                        ligne(titre: d.libelle, selectionne: choisi == d) { choisi = d }
                    }
                    if filtres.isEmpty {
                        Text("Aucun département ne correspond.")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .padding(Espace.xl)
                    }
                }
                .tuileFishMe()
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.l)
            }
        }
        .background(Palette.fond.ignoresSafeArea())
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .verre).padding(Espace.bord)
        }
    }

    private func ligne(titre: String, selectionne: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            dismiss()
        } label: {
            HStack {
                Text(titre)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if selectionne {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(selectionne ? Palette.marineDoux : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selectionne ? .isSelected : [])
    }
}
