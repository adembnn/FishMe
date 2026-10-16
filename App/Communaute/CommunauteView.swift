import SwiftUI

/// Troisième onglet : « Communauté ». Deux pages qu'on glisse ou qu'on choisit en haut : Amis et Club.
/// Les réglages et le profil sont sur la page Carte (pastille du profil, en haut à gauche).
struct CommunauteView<PageAmis: View, PageClub: View>: View {
  enum Page: Int, CaseIterable, Identifiable {
    case amis, club
    var id: Int { rawValue }
    var titre: String { self == .amis ? "Amis" : "Club" }
  }

  @State private var page: Page = .amis
  private let amis: PageAmis
  private let club: PageClub

  init(@ViewBuilder amis: () -> PageAmis, @ViewBuilder club: () -> PageClub) {
    self.amis = amis()
    self.club = club()
  }

  var body: some View {
    VStack(spacing: 0) {
      entete
      TabView(selection: $page) {
        amis.tag(Page.amis)
        club.tag(Page.club)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .ignoresSafeArea(edges: .bottom)
    }
    .background(Palette.fond.ignoresSafeArea())
  }

  private var entete: some View {
    VStack(alignment: .leading, spacing: Espace.s) {
      Text("Communauté")
        .font(Police.grandTitre)
        .foregroundStyle(Palette.encre)
        .accessibilityAddTraits(.isHeader)
      Picker("Page", selection: $page.animation()) {
        ForEach(Page.allCases) { Text($0.titre).tag($0) }
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
  }
}
