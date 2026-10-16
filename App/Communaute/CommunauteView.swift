import SwiftUI

/// Troisième onglet : « Communauté ». Deux pages qu'on glisse ou qu'on choisit en haut (Amis, Club),
/// et une roue crantée qui ouvre tous les réglages (fédération, carte de pêche, sécurité, sources, confidentialité).
struct CommunauteView<PageAmis: View, PageClub: View, Reglages: View>: View {
  enum Page: Int, CaseIterable, Identifiable {
    case amis, club
    var id: Int { rawValue }
    var titre: String { self == .amis ? "Amis" : "Club" }
  }

  @State private var page: Page = .amis
  @State private var reglagesOuverts = false
  private let amis: PageAmis
  private let club: PageClub
  private let reglages: Reglages

  init(
    @ViewBuilder amis: () -> PageAmis, @ViewBuilder club: () -> PageClub,
    @ViewBuilder reglages: () -> Reglages
  ) {
    self.amis = amis()
    self.club = club()
    self.reglages = reglages()
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
  } reglages: {
    Text("Réglages")
  }
}
