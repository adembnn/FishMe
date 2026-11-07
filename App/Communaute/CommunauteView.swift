import SwiftUI

/// Troisième onglet : « Communauté ». Des pages qu'on glisse ou qu'on choisit en haut : le fil à gauche (L23), puis Amis et Club.
/// Les réglages et le profil sont sur la page Carte (pastille du profil, en haut à gauche).
/// Sans `fil`, l'écran reste celui d'avant (Amis et Club) : `RootView.swift` compile tel quel jusqu'à ce que A branche le fil.
struct CommunauteView<PageFil: View, PageAmis: View, PageClub: View>: View {
  enum Page: Int, CaseIterable, Identifiable {
    case fil, amis, club
    var id: Int { rawValue }
    var titre: String {
      switch self {
      case .fil: "Fil"
      case .amis: "Amis"
      case .club: "Club"
      }
    }
  }

  @State private var page: Page
  private let fil: PageFil?
  private let amis: PageAmis
  private let club: PageClub

  init(fil: PageFil?, @ViewBuilder amis: () -> PageAmis, @ViewBuilder club: () -> PageClub) {
    self.fil = fil
    self.amis = amis()
    self.club = club()
    _page = State(initialValue: fil == nil ? .amis : .fil)
  }

  private var pages: [Page] { Page.allCases.filter { $0 != .fil || fil != nil } }

  var body: some View {
    VStack(spacing: 0) {
      entete
      TabView(selection: $page) {
        if let fil { fil.tag(Page.fil) }
        amis.tag(Page.amis)
        club.tag(Page.club)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      // Sans `ignoresSafeArea` : les pages gardent la marge de la barre d'onglets (elle recouvrait « J'aime / Commenter »).
    }
    .background(Palette.fond.ignoresSafeArea())
  }

  private var entete: some View {
    VStack(alignment: .leading, spacing: Espace.s) {
      Text(c: "Communauté")
        .font(Police.grandTitre)
        .foregroundStyle(Palette.encre)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityAddTraits(.isHeader)
      Picker(selection: $page.animation()) {
        ForEach(pages) { Text(c: $0.titre).tag($0) }
      } label: {
        Text(c: "Page")
      }
      .pickerStyle(.segmented)
    }
    .padding(.horizontal, Espace.bord)
    .padding(.top, Espace.s)
    .padding(.bottom, Espace.s)
  }
}

extension CommunauteView where PageFil == EmptyView {
  /// L'appel d'avant L23 : deux pages, Amis et Club.
  init(@ViewBuilder amis: () -> PageAmis, @ViewBuilder club: () -> PageClub) {
    self.init(fil: nil, amis: amis, club: club)
  }
}

#Preview("Avec le fil") {
  CommunauteView(fil: Text("Fil").frame(maxWidth: .infinity, maxHeight: .infinity)) {
    Text("Amis").frame(maxWidth: .infinity, maxHeight: .infinity)
  } club: {
    Text("Club").frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview("Sans le fil") {
  CommunauteView {
    Text("Amis").frame(maxWidth: .infinity, maxHeight: .infinity)
  } club: {
    Text("Club").frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
