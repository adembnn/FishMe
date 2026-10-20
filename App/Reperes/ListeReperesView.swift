import Core
import SwiftUI

/// « Mes repères » : la liste, son tri, le compteur gratuit et l'ajout (position courante ou point choisi sur une mini-carte).
struct ListeReperesView: View {
    var modele: ModeleReperes = .partage
    var contexte: ContexteReperes = .courant

    enum Tri: String, CaseIterable, Identifiable {
        case nom = "Nom"
        case passage = "Dernier passage"
        var id: String { rawValue }
    }

    private struct PointAjoute: Identifiable {
        let id = UUID()
        let position: Coordonnee
    }

    @Environment(\.dismiss) private var dismiss
    @State private var tri: Tri = .nom
    @State private var fiche: Repere?
    @State private var ajout: PointAjoute?
    @State private var choixSurCarte = false
    @State private var recherchePosition = false
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                enTete
                if modele.lectureSeule {
                    Text(TextesReperes.lectureSeule).font(Police.detail).foregroundStyle(Palette.alerte)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if modele.fichierIllisible {
                    Text(TextesReperes.fichierIllisible).font(Police.detail).foregroundStyle(Palette.alerte)
                        .fixedSize(horizontal: false, vertical: true)
                }
                boutonsAjout
                if let message {
                    Text(message).font(Police.detail).foregroundStyle(Palette.alerte)
                }
                if modele.reperes.isEmpty && modele.charge {
                    Text(TextesReperes.etatVide).font(Police.corps).foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    LazyVStack(spacing: Espace.s) {
                        ForEach(tries) { repere in ligne(repere) }
                    }
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond)
        .task { await modele.chargerSiBesoin() }
        .sheet(item: $fiche) { repere in
            FicheRepereView(repere: repere, modele: modele, contexte: contexte)
        }
        .sheet(item: $ajout) { point in
            NouveauRepereView(position: point.position, modele: modele, contexte: contexte)
        }
        .fullScreenCover(isPresented: $choixSurCarte) {
            ChoixPointRepereView { position in
                choixSurCarte = false
                ajout = PointAjoute(position: position)
            }
        }
    }

    private var enTete: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            HStack {
                Text(TextesReperes.titreListe).font(Police.titre).foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                if !contexte.abonne {
                    Text(TextesReperes.compteur(actifs: modele.actifs))
                        .font(Police.detail).foregroundStyle(Palette.encreDouce)
                        .accessibilityLabel("\(modele.actifs) repères sur \(LimitesReperes.gratuits) gratuits")
                }
            }
            Picker("Tri", selection: $tri) {
                ForEach(Tri.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(minHeight: Gabarit.zoneTactile)
        }
    }

    private var boutonsAjout: some View {
        VStack(spacing: Espace.s) {
            Button { ajouterIci() } label: {
                Label(TextesReperes.ajouterIci, systemImage: "mappin.and.ellipse").frame(maxWidth: .infinity)
            }
            .buttonStyle(.principal)
            .disabled(recherchePosition || modele.lectureSeule)
            Button { choixSurCarte = true } label: {
                Label(TextesReperes.ajouterSurLaCarte, systemImage: "map").frame(maxWidth: .infinity)
            }
            .buttonStyle(.secondaire)
            .disabled(modele.lectureSeule)
        }
    }

    private func ligne(_ repere: Repere) -> some View {
        Button { fiche = repere } label: {
            HStack(spacing: Espace.m) {
                // Icône de 24 pt dans une zone de 44 pt de large (la zone s'élargit si l'icône grossit avec le texte).
                IconeRepereView(type: repere.icone, taille: 24, suitLeTexte: true, decoratif: true)
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                VStack(alignment: .leading, spacing: Espace.xs) {
                    Text(repere.nom).font(Police.corps).foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading)
                    Text(sousTitre(repere)).font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(Police.legende).foregroundStyle(Palette.encreDouce)
                    .accessibilityHidden(true)
            }
            .padding(Espace.m)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
            .tuileFishMe()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(repere.nom), \(TextesReperes.libelle(repere.icone)), \(sousTitre(repere))")
        .accessibilityHint("Ouvre la fiche")
    }

    private func sousTitre(_ repere: Repere) -> String {
        if let date = repere.dernierPassage(prises: contexte.prises()) {
            return "\(TextesReperes.dernierPassage) : \(date.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR"))))"
        }
        return TextesReperes.libelle(repere.icone)
    }

    private var tries: [Repere] {
        switch tri {
        case .nom:
            return modele.reperes.sorted { $0.nom.localizedCaseInsensitiveCompare($1.nom) == .orderedAscending }
        case .passage:
            let prises = contexte.prises()
            return modele.reperes.sorted {
                ($0.dernierPassage(prises: prises) ?? .distantPast) > ($1.dernierPassage(prises: prises) ?? .distantPast)
            }
        }
    }

    private func ajouterIci() {
        message = nil
        recherchePosition = true
        Task {
            defer { recherchePosition = false }
            if let position = await PositionCourante.lire() {
                ajout = PointAjoute(position: position)
            } else {
                message = TextesReperes.positionIndisponible
            }
        }
    }
}
