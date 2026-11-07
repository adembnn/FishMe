import Core
import SwiftUI

/// Le bloc des règles de pêche américaines pour une espèce et un lieu (lot US12). Une seule vue, réutilisée par l'écran de résultat de la prise,
/// la collection et la fiche de la carte (US10).
///
/// POINT D'ENTRÉE POUR US10 (fiche de la carte, une ligne à insérer, sans autre branchement) :
///
///     BlocReglesUS(espece: "walleye", nomEspece: "Walleye", etat: CodeEtat(rawValue: "WI"))
///     BlocReglesUS(espece: "walleye", nomEspece: "Walleye", etat: CodeEtat(rawValue: "WI"),
///                  juridiction: IdJuridiction(rawValue: "US-WI/northern-zone"), tailleCm: 40, tailleEstimee: false)
///
/// - `espece` : l'identifiant d'espèce des fichiers `regles-us/` (« walleye », « northern-pike »…) ; `nomEspece` : le nom affiché, facultatif.
/// - `etat` : l'État du lieu (`nil` s'il est inconnu : le bloc propose alors de le choisir). `juridiction` : une zone ou un plan d'eau plus précis, facultatif.
/// - `tailleCm` : la taille du poisson en centimètres (le verdict se calcule en métrique) ; `tailleEstimee` : vrai si elle vient d'une estimation.
/// - Unités et langue : celles de la région active (`RegionCourante` de l'environnement ; sans elle, pouces, livres et anglais).
///
/// Ce que le bloc montre, dans l'ordre :
/// 1. l'état de tête, EXACTEMENT un de trois : « interdit » (il faut relâcher), « à vérifier » (pastille orange, vérifie auprès de l'agence),
///    « donnée absente ». Jamais de verdict qui dise qu'on peut garder le poisson : le moteur de `Core` n'en produit pas ;
/// 2. un dépliant fermé par défaut avec les lignes de règles lues (taille, limites, saison, matériel) ;
/// 3. toujours le lien de l'agence de l'État, la source et sa date.
struct BlocReglesUS: View {
    let espece: String
    let nomEspece: String?
    let etat: CodeEtat?
    let juridiction: IdJuridiction?
    let tailleCm: Double?
    let tailleEstimee: Bool
    let date: Date

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    @AppStorage("reglesUS.etatChoisi") private var etatChoisi = ""
    @State private var deplie: Bool
    @State private var chargee = false

    init(espece: String, nomEspece: String? = nil, etat: CodeEtat?, juridiction: IdJuridiction? = nil, tailleCm: Double? = nil,
         tailleEstimee: Bool = false, date: Date = Date(), deplieAuDepart: Bool = false) {
        self.espece = espece
        self.nomEspece = nomEspece
        self.etat = etat
        self.juridiction = juridiction
        self.tailleCm = tailleCm
        self.tailleEstimee = tailleEstimee
        self.date = date
        _deplie = State(initialValue: deplieAuDepart)
    }

    private var format: FormatRegion { regionCourante?.format ?? FormatRegion(region: .etatsUnis) }
    private var textes: TextesReglesUS { TextesReglesUS(locale: format.locale) }
    private var etatEffectif: CodeEtat? { etat ?? CodeEtat(rawValue: etatChoisi) }

    private var presentation: PresentationReglesUS {
        guard let e = etatEffectif else { return .sansEtat(format: format) }
        let question = PresentationReglesUS.question(espece: espece, etat: e, juridiction: etat == nil ? nil : juridiction, date: date,
                                                     tailleCm: tailleCm, tailleEstimee: tailleEstimee)
        return .construire(question: question, etat: e, evaluateur: ServiceReglesUS.evaluateur, format: format)
    }

    var body: some View {
        Group {
            if chargee { contenu(presentation) } else { attente }
        }
        // Les fichiers de règles se lisent hors du fil principal ; la vue ne montre aucun verdict avant.
        .task {
            _ = await Task.detached(priority: .userInitiated) { ServiceReglesUS.evaluateur }.value
            chargee = true
        }
    }

    private var attente: some View {
        RoundedRectangle(cornerRadius: Rayon.m, style: .continuous)
            .fill(Palette.tuile)
            .frame(height: 88)
            .accessibilityHidden(true)
    }

    private func contenu(_ p: PresentationReglesUS) -> some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            tete(p)
            depliant(p)
            pied(p)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 1. L'état de tête : trois verdicts, pas un de plus

    private func tete(_ p: PresentationReglesUS) -> some View {
        let interdit = p.verdict == .interdit
        return VStack(alignment: .leading, spacing: Espace.s) {
            HStack(alignment: .top, spacing: Espace.m) {
                pastille(p.verdict)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.etiquette).font(Police.sousTitre)
                    Text(p.phrase).font(Police.corps).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ForEach(p.raisons, id: \.self) { raison in
                Text(raison).font(Police.detail).fixedSize(horizontal: false, vertical: true)
            }
        }
        .foregroundStyle(interdit ? Palette.surMarine : Palette.encre)
        .padding(Espace.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fond(p.verdict), in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func fond(_ v: VerdictUS) -> Color {
        switch v {
        case .interdit: Palette.alerte
        case .aVerifier: Palette.surface
        case .donneeAbsente: Palette.tuile
        }
    }

    @ViewBuilder private func pastille(_ v: VerdictUS) -> some View {
        switch v {
        case .interdit:
            Image(systemName: "arrow.uturn.down").font(.system(size: 22, weight: .bold, design: .rounded)).accessibilityHidden(true)
        case .aVerifier:
            Circle().fill(Palette.alerte).frame(width: 16, height: 16).padding(.top, 4).accessibilityHidden(true)
        case .donneeAbsente:
            Image(systemName: "questionmark.circle").font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.encreDouce).accessibilityHidden(true)
        }
    }

    // MARK: 2. Le dépliant, fermé par défaut

    private func depliant(_ p: PresentationReglesUS) -> some View {
        DisclosureGroup(isExpanded: $deplie) {
            VStack(alignment: .leading, spacing: Espace.l) {
                if p.groupes.isEmpty {
                    Text(textes.aucuneLigne).font(Police.detail).foregroundStyle(Palette.encreDouce)
                }
                ForEach(p.groupes, id: \.id) { g in groupe(g) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Espace.m)
        } label: {
            Text(textes.titreDepliant).font(Police.sousTitre).foregroundStyle(Palette.encre)
                .multilineTextAlignment(.leading).frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }
        .tint(Palette.marine)
        .padding(Espace.m)
        .tuileFishMe()
    }

    private func groupe(_ g: GroupeReglesUS) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(g.portee).font(Police.detail).foregroundStyle(Palette.encreDouce)
            ForEach(g.lignes, id: \.self) { l in
                HStack(alignment: .firstTextBaseline, spacing: Espace.m) {
                    Text(l.titre).font(Police.corps).foregroundStyle(Palette.encre)
                    Spacer(minLength: Espace.s)
                    Text(l.valeur).font(Police.corps.monospacedDigit()).foregroundStyle(Palette.encre).multilineTextAlignment(.trailing)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: 3. Toujours : lien de l'agence, source, date

    private func pied(_ p: PresentationReglesUS) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            if let lien = p.lienAgence {
                Link(destination: lien) {
                    Label(libelleLien(p), systemImage: "link")
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
                .font(Police.corps).foregroundStyle(Palette.marine)
            } else if p.etatInconnu {
                Text(textes.etatInconnu).font(Police.detail).foregroundStyle(Palette.encreDouce)
                choixEtat
            }
            if let texte = p.texteSource {
                if let url = p.sourceURL {
                    Link(destination: url) { Text(texte).multilineTextAlignment(.leading) }
                        .font(Police.detail).foregroundStyle(Palette.marine)
                } else {
                    Text(texte).font(Police.detail).foregroundStyle(Palette.encreDouce)
                }
            }
            Text(p.mention).font(Police.legende).foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func libelleLien(_ p: PresentationReglesUS) -> String {
        guard let nom = p.nomEtat else { return textes.lienAgence }
        return textes.lienAgence + " (" + nom + ")"
    }

    /// État inconnu (position hors des États dont on lit les règles, ou lieu flou sans État) : le pêcheur le choisit, le lien de l'agence suit.
    @ViewBuilder private var choixEtat: some View {
        let liste = (ServiceReglesUS.evaluateur?.niveau1?.etats ?? []).sorted { a, b in a.nom < b.nom }
        if !liste.isEmpty {
            Menu {
                ForEach(liste, id: \.code) { e in
                    Button(e.nom) { etatChoisi = e.code.rawValue }
                }
            } label: {
                Label(textes.choisirEtat, systemImage: "mappin.and.ellipse").frame(minHeight: Gabarit.zoneTactile)
            }
            .font(Police.corps).foregroundStyle(Palette.marine)
        }
    }
}
