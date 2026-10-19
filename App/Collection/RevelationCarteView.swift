import Core
import SwiftUI
import UIKit

/// E6 : la carte d'une prise confirmée se révèle en plein écran, « Le dos de la carte » (variation B choisie par Adem).
/// La photo du pêcheur rétrécit vers le dos gravé de la carte, qui tremble selon la rareté, s'ouvre sur une ligne de lumière,
/// se retourne d'un ressort et montre le recto ; puis le mot de rareté, le badge, les points et le bouton arrivent.
/// Un toucher pendant l'attente saute directement à la carte posée ; ensuite un toucher montre la photo au verso.
/// La carte est déjà enregistrée par `DepotCartes` : cette vue ne fait que la montrer.
struct RevelationCarteView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    /// Conservé pour ne pas changer l'appel : le rythme vient maintenant de `ChronoRevelation`.
    /// Un délai nul ou négatif montre tout de suite la carte posée (essais, captures).
    var delaiAuto: Double = 1.4
    let ranger: () -> Void

    /// Révélations déjà montrées pendant cette session de l'app.
    @MainActor private static var dejaRevelees = 0
    /// Vrai à partir de la 2e révélation, ou pour un « commun » déjà possédé : version courte, sans tremblement.
    var dejaPossedee = false

    private enum Face { case recto, verso }

    /// ⚠ à trancher par Adem : la photo du pêcheur qui rétrécit vers le dos de la carte (variation B, E6) est la seule image de la photo
    /// visible avant la bascule recto/verso. Elle est gardée (c'est l'ouverture choisie de la révélation) ; mettre `false` la retire.
    private static let photoRetrecitAuDepart = true

    @State private var debut: Date?
    @State private var evenementsJoues: Set<Int> = []
    /// Vrai quand plus rien ne bouge : la scène s'arrête (économie de batterie).
    @State private var auRepos = false
    @State private var visible = true
    @State private var cadre: CGRect = .zero
    @State private var imagePhoto: UIImage?
    @State private var face: Face = .recto
    /// Quart de tour du toucher recto/verso (en plus du retournement d'arrivée).
    @State private var angleBascule: Double = 0
    /// Vrai seulement quand le verso a passé le quart de tour : avant, la photo du verso est préchargée mais invisible (L18).
    @State private var versoAffiche = false
    @State private var enCours = false
    @State private var mouvement = MouvementIPhone()
    @State private var rapide = false
    @State private var fonduReduit = false
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    private var style: StyleRarete { infos.style }
    private var niveau: NiveauRevelation { NiveauRevelation(infos.style) }
    private var chrono: ChronoRevelation { ChronoRevelation(niveau: niveau, rapide: rapide) }

    // MARK: Temps

    /// Millisecondes écoulées depuis le début de la révélation.
    private func temps(_ date: Date) -> Double {
        if reduireAnimations || auRepos { return chrono.duree }
        guard let debut else { return 0 }
        return max(0, date.timeIntervalSince(debut) * 1000)
    }

    private var estTermine: Bool { temps(.now) >= chrono.duree }

    // MARK: Corps

    var body: some View {
        GeometryReader { g in
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: auRepos || !visible || reduireAnimations)) { contexte in
                scene(t: temps(contexte.date), g: g)
            }
        }
        .background { fondNuit.ignoresSafeArea() }
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .verre) { ranger() }.padding(Espace.bord)
        }
        .contentShape(Rectangle())
        .onTapGesture { toucherFond() }
        .onAppear { demarrer() }
        .onDisappear {
            visible = false
            mouvement.arreter()
        }
        .task { await jouerLesSons() }
    }

    /// Le fond : bleu nuit, un peu plus clair au centre.
    private var fondNuit: some View {
        ZStack {
            Palette.nuit
            RadialGradient(colors: [Color(rev: 0x0D4A85, opacite: 0.55), Color(rev: 0x0D4A85, opacite: 0)],
                           center: .center, startRadius: 0, endRadius: 520)
        }
    }

    private func scene(t: Double, g: GeometryProxy) -> some View {
        let etat = chrono.etat(t)
        let u = g.size.width / 390
        let marge = g.safeAreaInsets
        let plein = CGSize(width: g.size.width + marge.leading + marge.trailing,
                           height: g.size.height + marge.top + marge.bottom)
        let centre = CGPoint(x: cadre.midX + marge.leading, y: cadre.midY + marge.top)
        let decalage = CGSize(width: (marge.trailing - marge.leading) / 2, height: (marge.bottom - marge.top) / 2)
        let anime = !reduireAnimations
        let pret = cadre.width > 1
        let opaciteContenu: Double = reduireAnimations ? (fonduReduit ? 1 : 0) : (pret ? 1 : 0)

        return ZStack {
            // Effets sur tout l'écran, sous la carte.
            FondRevelation(niveau: niveau, etat: etat, t: t, centre: centre, tailleCarte: cadre.size,
                           echelle: u, particules: anime)
                .frame(width: plein.width, height: plein.height)
                .offset(decalage)

            contenu(t: t, etat: etat, u: u)
                .opacity(opaciteContenu)

            // Effets devant la carte.
            AvantRevelation(niveau: niveau, etat: etat, t: t, chrono: chrono, centre: centre, tailleCarte: cadre.size,
                            echelle: u, particules: anime)
                .frame(width: plein.width, height: plein.height)
                .offset(decalage)

            // La photo du pêcheur qui rétrécit vers le dos de la carte.
            if Self.photoRetrecitAuDepart, anime, pret, let imagePhoto, etat.photoFondu > 0.001 {
                photoQuiRetrecit(imagePhoto, etat: etat, plein: plein, marge: marge, u: u)
                    .frame(width: plein.width, height: plein.height)
                    .offset(decalage)
            }
        }
        .coordinateSpace(.named("revelation"))
        .frame(width: g.size.width, height: g.size.height)
    }

    // MARK: Contenu : carte, mot de rareté, bouton

    private func contenu(t: Double, etat: EtatRevelation, u: CGFloat) -> some View {
        let reduit = reduireAnimations
        let boutonOpacite: Double = reduit ? 1 : etat.boutonOpacite
        let boutonVisible = boutonOpacite > 0.6
        let boutonDecalage: CGFloat = reduit ? 0 : CGFloat(etat.boutonDecalage) * u
        return VStack(spacing: Espace.l) {
            Spacer(minLength: Espace.xl)
            carte(t: t, etat: etat, u: u)
                .padding(.horizontal, Espace.xl)
            rarete(t: t, etat: etat, u: u)
                .frame(minHeight: Gabarit.zoneTactile)
            Button(action: ranger) {
                Text("Ranger dans le Pescedex")
            }
            .buttonStyle(.principal)
            .padding(.horizontal, Espace.bord)
            .opacity(boutonOpacite)
            .offset(y: boutonDecalage)
            .disabled(!boutonVisible)
            .accessibilityHidden(!boutonVisible)
            Spacer(minLength: 16)
        }
    }

    // MARK: La carte

    @ViewBuilder
    private func carte(t: Double, etat: EtatRevelation, u: CGFloat) -> some View {
        let flip = !reduireAnimations
        let angle: Double = flip ? etat.angle + angleBascule : 0
        let montreLeDos = flip && !etat.arrive
        let enRepos = etat.arrive && t >= chrono.duree
        let flottement: CGFloat = (enRepos && niveau.animeAuRepos && flip) ? CGFloat(sin(t / 1300) * 1.4) * u : 0
        let largeur = max(cadre.width, 1)
        let decalageX: CGFloat = flip ? CGFloat(etat.decalageX) * largeur / 100 : 0
        let decalageY: CGFloat = flip ? CGFloat(etat.soulevement) * u + flottement + CGFloat((1 - etat.opaciteDos) * 30) : 0
        let echelle: CGFloat = flip ? CGFloat(etat.echelle) : 1
        let tremblement: Double = flip ? etat.tremblement : 0
        let opacite: Double = flip ? max(0.0001, etat.opaciteDos) : 1
        let rayonAura: CGFloat = (cadre.width > 1 ? cadre.width : 240) * CGFloat(0.12 + etat.aura * 0.3) / 2
        let couleurAura: Color = niveau.lueur.opacity(etat.aura * (niveau == .commun ? 0.3 : 0.55))

        ZStack {
            if montreLeDos {
                DosCarteGravee(niveau: niveau, etat: etat)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Carte face cachée")
                    .accessibilityHint("Touche pour la révéler tout de suite")
            } else {
                faceVisible(t: t, etat: etat)
                    .rotation3DEffect(.degrees(flip ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            }
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { toucherCarte() }
        .accessibilityAddTraits(.isButton)
        .background {
            // Mesure la place de la carte avant les effets de mouvement.
            Color.clear.onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("revelation"))
            } action: { nouveau in
                cadre = nouveau
            }
        }
        .shadow(color: couleurAura, radius: rayonAura)
        .scaleEffect(echelle)
        .rotationEffect(.degrees(tremblement))
        .offset(x: decalageX, y: decalageY)
        .opacity(opacite)
    }

    /// Recto ou verso, avec l'éclat d'arrivée sur le recto.
    @ViewBuilder
    private func faceVisible(t: Double, etat: EtatRevelation) -> some View {
        switch face {
        case .recto:
            CarteRectoView(infos: infos, anime: true, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                .overlay {
                    EclatsSurRecto(niveau: niveau, etat: etat, t: t, chrono: chrono, anime: !reduireAnimations)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(infos.texteVoixOff)
                .accessibilityHint("Touche pour voir la photo au verso")
                .background {
                    // La photo du verso est décodée dès maintenant, derrière le recto, mais ne se voit pas : opacité 0 (jamais 0,01,
                    // qui laisse une image fantôme), cachée à VoiceOver et sans toucher. Elle passe à 1 au passage de 90 degrés.
                    CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                        .opacity(0)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
        case .verso:
            CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                .opacity(versoAffiche ? 1 : 0)
                .accessibilityHint("Touche pour revoir le recto")
        }
    }

    // MARK: Mot de rareté, badge, points

    private func rarete(t: Double, etat: EtatRevelation, u: CGFloat) -> some View {
        let reduit = reduireAnimations
        let motOpacite: Double = reduit ? 1 : etat.motOpacite
        let motDecalage: CGFloat = reduit ? 0 : CGFloat(etat.motDecalage) * u
        let motEchelle: CGFloat = reduit ? 1 : CGFloat(etat.motEchelle)
        return VStack(spacing: Espace.s) {
            HStack(spacing: Espace.m) {
                BadgeRarete(style: style, taille: 44)
                Text(style.mot.capitalized)
                    .font(Police.taille(34, .heavy))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundStyle(niveau.texteSurNuit)
            }
            .opacity(motOpacite)
            .offset(y: motDecalage)
            .scaleEffect(motEchelle)
            if style != .nonMesuree {
                HStack(spacing: 5) {
                    ForEach(0..<4, id: \.self) { i in
                        pointDeRarete(i, t: t, reduit: reduit)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rareté : \(style.mot)")
    }

    /// Un des quatre points : plein jusqu'au rang, vide ensuite, il apparaît avec un petit ressort.
    private func pointDeRarete(_ i: Int, t: Double, reduit: Bool) -> some View {
        let p = chrono.point(i, t)
        let plein = i < niveau.rang
        let opacite: Double = reduit ? (plein ? 1 : 0.9) : p.opacite
        let echelle: CGFloat = reduit ? 1 : CGFloat(p.echelle)
        return Circle()
            .strokeBorder(niveau.texteSurNuit, lineWidth: 2)
            .background(Circle().fill(plein ? niveau.texteSurNuit : Color.clear))
            .frame(width: 12, height: 12)
            .opacity(opacite)
            .scaleEffect(echelle)
    }

    // MARK: La photo

    private func photoQuiRetrecit(_ image: UIImage, etat: EtatRevelation, plein: CGSize, marge: EdgeInsets, u: CGFloat) -> some View {
        typealias C = CourbesRevelation
        let e = etat.photo
        let largeurCarte = max(cadre.width, 1)
        let hauteurCarte = max(cadre.height, 1)
        // Départ : tout l'écran. Arrivée : la place de la carte.
        let cibleX = Double(cadre.minX + marge.leading)
        let cibleY = Double(cadre.minY + marge.top)
        let gauche = C.lerp(0, cibleX, e)
        let haut = C.lerp(0, cibleY, e)
        let largeur = C.lerp(Double(plein.width), Double(largeurCarte), e)
        let hauteur = C.lerp(Double(plein.height), Double(hauteurCarte), e)
        let rayon = CGFloat(C.lerp(0, Double(largeurCarte) * 0.06, e))
        let ombre = Color(rev: 0x020916, opacite: 0.55 * e)
        return Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: CGFloat(largeur), height: CGFloat(hauteur))
            .clipShape(RoundedRectangle(cornerRadius: rayon, style: .continuous))
            .shadow(color: ombre, radius: CGFloat(e * 17) * u, y: CGFloat(e * 14) * u)
            .scaleEffect(etat.photoEchelle)
            .blur(radius: CGFloat((1 - etat.photoFondu) * 5))
            .opacity(etat.photoFondu)
            .position(x: CGFloat(gauche + largeur / 2), y: CGFloat(haut + hauteur / 2))
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }

    // MARK: Départ, saut, sons

    private func demarrer() {
        rapide = Self.dejaRevelees >= 1 || (dejaPossedee && infos.style == .commun)
        Self.dejaRevelees += 1
        visible = true
        if let donnees = photo { imagePhoto = UIImage(data: donnees) }
        if style.aUnReflet && !reduireAnimations { mouvement.demarrer() }
        if reduireAnimations {
            withAnimation(.easeInOut(duration: 0.4)) { fonduReduit = true }
            auRepos = true
        } else if delaiAuto <= 0 {
            debut = Date.now.addingTimeInterval(-chrono.duree / 1000)
            if !niveau.animeAuRepos { auRepos = true }
        } else {
            debut = .now
        }
    }

    /// Un toucher pendant l'attente : directement à la carte posée, avec le son de la carte seulement.
    private func sauter() {
        guard !reduireAnimations, !estTermine else { return }
        let evenements = chrono.evenements
        for (i, ev) in evenements.enumerated() where !ev.estCarte { evenementsJoues.insert(i) }
        debut = Date.now.addingTimeInterval(-chrono.duree / 1000)
        if !niveau.animeAuRepos { auRepos = true }
    }

    /// Joue les sons et vibrations aux instants de la révélation ; une fois la carte posée, la boucle s'arrête.
    private func jouerLesSons() async {
        if reduireAnimations {
            // Sans animation, les sons restent : seul le moment de la carte.
            jouer(niveau.moment)
            return
        }
        while !Task.isCancelled {
            if let debut {
                let evenements = chrono.evenements
                let t = Date.now.timeIntervalSince(debut) * 1000
                for (i, ev) in evenements.enumerated() where !evenementsJoues.contains(i) && t >= ev.t {
                    evenementsJoues.insert(i)
                    jouer(ev.moment)
                }
                if evenementsJoues.count >= evenements.count {
                    // Une fois la carte posée, les effets sans mouvement s'arrêtent.
                    let reste = chrono.duree - t
                    if reste > 0 { try? await Task.sleep(for: .milliseconds(Int(reste) + 30)) }
                    if !niveau.animeAuRepos { auRepos = true }
                    return
                }
            }
            try? await Task.sleep(for: .milliseconds(16))
        }
    }

    private func jouer(_ moment: MomentSonore) {
        Sons.jouer(moment)
        Vibrations.jouer(moment)
    }

    // MARK: Toucher

    private func toucherFond() {
        if rapide { ranger(); return }
        if !estTermine { sauter() }
    }

    private func toucherCarte() {
        if rapide { ranger(); return }
        if !estTermine { sauter(); return }
        Task { await basculer() }
    }

    /// Recto vers verso (ou l'inverse) : premier quart de tour jusqu'à 90 degrés, changement de face, second quart de tour.
    private func basculer() async {
        guard !enCours else { return }
        enCours = true
        defer { enCours = false }
        let cible: Face = face == .recto ? .verso : .recto
        if reduireAnimations {
            withAnimation(.easeInOut(duration: 0.2)) {
                face = cible
                versoAffiche = cible == .verso
            }
            return
        }
        withAnimation(.easeIn(duration: 0.22)) { angleBascule = 90 }
        try? await Task.sleep(for: .milliseconds(220))
        // Le quart de tour est fait (90 degrés) : seulement maintenant le verso devient visible.
        face = cible
        versoAffiche = cible == .verso
        angleBascule = -90
        withAnimation(.spring(duration: 0.35)) { angleBascule = 0 }
    }
}

#if DEBUG
#Preview("Révélation, légendaire") {
    let prise = Prise(espece: Espece(id: "brochet", codeSandre: nil), longueurCm: 62, date: .now, lieuFlou: "94")
    let infos = InfosCarte(
        detail: CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil),
        espece: EspecePechable(espece: prise.espece, nom: "Brochet", nomLatin: "Esox lucius", image: "brochet"),
        rarete: ResultatRarete(niveau: .legendaire, nPeches: 0, nTotal: 29, anneeDernierReleve: 2023, echelle: .departement),
        departement: Departement(code: "94"), rangDansLaZone: 3, poids: nil, lune: .pleine, consigne: nil, sourceConsigne: nil)
    RevelationCarteView(infos: infos, photo: nil, ranger: {})
}

#Preview("Révélation, rare") {
    let prise = Prise(espece: Espece(id: "brochet", codeSandre: nil), longueurCm: 62, date: .now, lieuFlou: "94")
    let infos = InfosCarte(
        detail: CarteDetaillee(prise: prise, conditions: nil, dureeSecondes: nil),
        espece: EspecePechable(espece: prise.espece, nom: "Brochet", nomLatin: "Esox lucius", image: "brochet"),
        rarete: ResultatRarete(niveau: .rare, nPeches: 9, nTotal: 29, anneeDernierReleve: 2023, echelle: .departement),
        departement: Departement(code: "94"), rangDansLaZone: 3, poids: nil, lune: .pleine, consigne: nil, sourceConsigne: nil)
    RevelationCarteView(infos: infos, photo: nil, ranger: {})
}
#endif
