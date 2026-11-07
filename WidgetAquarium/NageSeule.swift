import SwiftUI

// Widget + app. LA NAGE DU POISSON UNIQUE (lot widget-fluide, 7 nov. : « un seul poisson, il nage pour de vrai »).
//
// Le widget montre UN poisson, avec les mêmes images que l'aquarium de l'app (`ImagePoisson`, cycle de nage, vues 3D).
// Il suit sa balade de 10 s en perspective (`NageWidget.traversees` : il traverse, change de profondeur, fait demi-tour).
// Technique de Bryce Bostwick (voir AnimationWidget.swift), mais chaque copie n'est pas un widget entier : c'est le poisson
// seul, dans un cadre à sa taille, posé à sa place du trajet. Les masques chronos ont donc la taille du poisson (quelques
// dizaines de points) et non celle du widget : c'est ce qui rend possibles plus d'images par seconde.
//
// Copie k (0 à boucle.copies moins 1) : la pose k du trajet, visible 1/`parSeconde` s par boucle de 10 s, grâce à deux masques
// (`HorlogeAnimation.masques(copie:boucle:)`, polices `FishMeClignoteChiffreK`, un chrono par masque).
struct NageSeule: View {
    let slug: String
    /// Largeur du poisson au premier plan (avant l'échelle de perspective de chaque pose), en points.
    let largeur: CGFloat
    /// Le poisson a-t-il un cycle de nage ? `imagesCycle` images (8 ou 16), prises de `pas` en `pas`.
    let cycle: Bool
    let imagesCycle: Int
    let pas: Int
    /// Images de queue distinctes réellement montrées (1 : une seule image, la queue ondule par transformation).
    let imagesQueue: Int
    /// Lacets rendus en volume (vues 3D de l'app) ; vide : le profil seul.
    let angles: [Int]
    /// Une pose par copie (`boucle.copies` poses sur 10 s).
    let poses: [NageWidget.PoseNage]
    let reference: Date
    let boucle: HorlogeAnimation.Boucle
    /// Taille du widget.
    let l: CGFloat
    let h: CGFloat

    /// Cadre d'une copie, en part de la largeur du poisson à cette pose : la place du corps, de la queue qui ondule et du
    /// tangage. Les copies et leurs masques ne dépassent pas ce cadre.
    static let cadre = CGSize(width: 1.25, height: 0.8)

    var body: some View {
        ZStack {
            ForEach(poses.indices, id: \.self) { k in
                copie(k)
            }
        }
        .frame(width: l, height: h)
        .allowsHitTesting(false)
    }

    private func copie(_ k: Int) -> some View {
        let p = poses[k]
        let w = largeur * p.echelle
        let m = HorlogeAnimation.masques(copie: k, boucle: boucle)
        return poisson(k, largeur: w)
            .frame(width: w * Self.cadre.width, height: w * Self.cadre.height)
            .mask(MasqueClignotant(chiffre: m.a.chiffres[0], reference: reference, decalage: m.a.decalage))
            .mask(MasqueClignotant(chiffre: m.b.chiffres[0], reference: reference, decalage: m.b.decalage))
            .position(x: p.x * l, y: p.y * h)
    }

    /// Le poisson à sa pose : image du cycle, vue 3D la plus proche du lacet, sens, assiette, opacité (il sort du bleu
    /// lointain) et la petite ondulation du corps.
    private func poisson(_ k: Int, largeur w: CGFloat) -> some View {
        let p = poses[k]
        let vue = angles.isEmpty ? 0
            : (NageWidget.melange(lacet: p.lacet, angles: angles).max { $0.poids < $1.poids }?.angle ?? 0)
        let o = Self.ondulation(copie: k, sur: poses.count)
        let image: Int? = cycle
            ? Self.numeroImage(pose: p.image, imagesQueue: imagesQueue, imagesCycle: imagesCycle) * pas : nil
        let sensX: Double = p.sens >= 0 ? 1 : -1
        return ImagePoisson(slug: slug, image: image, largeur: w, sens: p.sens, angle: vue, volume: !angles.isEmpty)
            .scaleEffect(x: 1 - o.flex, y: 1 + o.flex * 0.4)
            .opacity(p.opacite)
            // Il lève un peu le nez quand il monte, plus un léger tangage.
            .rotationEffect(.radians(-(p.assiette * 0.5 + o.tangage) * sensX))
    }

    /// Numéro (0 à imagesCycle moins 1) de l'image montrée pour la pose de cycle `pose` (0 à imagesQueue moins 1) : les
    /// `imagesQueue` images sont réparties sur le cycle de `imagesCycle`.
    static func numeroImage(pose: Int, imagesQueue: Int, imagesCycle: Int) -> Int {
        let q = max(min(imagesQueue, imagesCycle), 1)
        return (((pose % q) + q) % q) * max(imagesCycle, 1) / q
    }

    /// Images de queue distinctes du poisson unique (1 : une seule image rastérisée, la queue ondule par transformation).
    /// En Debug, un fichier `queue-widget.txt` dans l'App Group la remplace (essais de mémoire).
    static var imagesQueueRetenues: Int {
        #if DEBUG
        if let url = DepotAquariumWidget.url()?.deletingLastPathComponent().appendingPathComponent("queue-widget.txt"),
           let texte = try? String(contentsOf: url, encoding: .utf8),
           let n = Int(texte.trimmingCharacters(in: .whitespacesAndNewlines)), n >= 1 {
            return n
        }
        #endif
        return 1
    }

    /// Nombre de battements du corps par boucle de 10 s (un nombre entier : la boucle se referme sans saut).
    static let battements = 15

    /// Le corps qui respire (largeur) et un léger tangage, au rythme du battement. Le trajet fait déjà le déplacement.
    static func ondulation(copie k: Int, sur n: Int) -> (flex: CGFloat, tangage: Double) {
        let a = 2 * Double.pi * Double(battements) * Double(k) / Double(max(n, 1))
        return (CGFloat(sin(a)) * 0.05, cos(a) * 0.04)
    }
}
