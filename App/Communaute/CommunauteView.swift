import SwiftUI

/// Troisième onglet : « Communauté ». Deux pages qu'on glisse ou qu'on choisit en haut (Amis, Club),
/// une troisième « Découvrir » seulement en mode démo, et une roue crantée qui ouvre tous les réglages
/// (fédération, carte de pêche, sécurité, sources, confidentialité).
struct CommunauteView<PageAmis: View, PageClub: View, PageDecouvrir: View, Reglages: View>: View {
  enum Page: Int, CaseIterable, Identifiable {
    case amis, club, decouvrir
    var id: Int { rawValue }
    var titre: String {
      switch self {
      case .amis: "Amis"
      case .club: "Club"
      case .decouvrir: "Découvrir"
      }
    }
  }

  @State private var page: Page = .amis
  @State private var reglagesOuverts = false
  /// Mode démo (réglages) : amis, club et fil d'exemple, tous marqués « Exemple ».
  @AppStorage("demo.communaute") private var demo = false
  private let amis: PageAmis
  private let club: PageClub
  private let decouvrir: PageDecouvrir
  private let reglages: Reglages

  init(
    @ViewBuilder amis: () -> PageAmis, @ViewBuilder club: () -> PageClub,
    @ViewBuilder decouvrir: () -> PageDecouvrir, @ViewBuilder reglages: () -> Reglages
  ) {
    self.amis = amis()
    self.club = club()
    self.decouvrir = decouvrir()
    self.reglages = reglages()
  }

  private var pages: [Page] { demo ? Page.allCases : [.amis, .club] }

  var body: some View {
    VStack(spacing: 0) {
      entete
      TabView(selection: $page) {
        amis.tag(Page.amis)
        club.tag(Page.club)
        if demo { decouvrir.tag(Page.decouvrir) }
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .ignoresSafeArea(edges: .bottom)
    }
    .background(Palette.fond.ignoresSafeArea())
    .onChange(of: demo) { _, actif in
      if !actif && page == .decouvrir { page = .amis }
    }
    .sheet(isPresented: $reglagesOuverts) { reglages }
  }

  private var entete: some View {
    VStack(alignment: .leading, spacing: Espace.s) {
      HStack {
        Text("Communauté")
          .font(Police.grandTitre)
          .foregroundStyle(Palette.encre)
          .accessibilityAddTraits(.isHeader)
        Spacer()
        Button {
          reglagesOuverts = true
        } label: {
          Image(systemName: "gearshape.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(Palette.marine)
            .frame(width: 44, height: 44)
            .background(.regularMaterial, in: Circle())
        }
        .accessibilityLabel("Réglages")
      }
      Picker("Page", selection: $page.animation()) {
        ForEach(pages) { Text($0.titre).tag($0) }
      }
      .pickerStyle(.segmented)
    }
    .padding(.horizontal, Espace.bord)
    .padding(.top, Espace.s)
    .padding(.bottom, Espace.s)
  }
}

#Preview {
  CommunauteView {
    Text("Amis").frame(maxWidth: .infinity, maxHeight: .infinity)
  } club: {
    Text("Club").frame(maxWidth: .infinity, maxHeight: .infinity)
  } decouvrir: {
    Text("Découvrir").frame(maxWidth: .infinity, maxHeight: .infinity)
  } reglages: {
    Text("Réglages")
  }
}
