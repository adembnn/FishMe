import Foundation

// Le budget de performance des décors dessinés en code. Foundation seulement : compile aussi sous Linux (tests).
// Fichier PARTAGÉ app + widget. Exigence n°1 : l'aquarium reste fluide, sans à-coups, même sur un iPhone ancien.
// Ce fichier fixe les plafonds ET déclare ce que dessine chaque décor à chaque image ; `BudgetDecorTests` vérifie que
// la charge de chaque décor tient dans le budget. Un futur décor, ou un ajout à un décor existant, doit d'abord
// mettre à jour `charge(_:)` : si le total dépasse le budget, le test échoue.
//
// Règles de dessin (détail dans App/Aquarium/Skins/LISEZMOI-N1.md) :
//  1. tout ce qui est statique (sol, galets, dégradés, plans flous, rais fixes) est rendu UNE fois en image et mis en cache ;
//  2. aucun flou sur une couche animée : les plans flous sont flous une fois, dans l'image mise en cache ;
//  3. seules quelques couches légères bougent (lames, reflets, rubans, bokeh, bulles, particules) ;
//  4. 20 images par seconde au plus, 10 en mode économie d'énergie, rien quand l'aquarium n'est pas à l'écran ;
//  5. « Réduire les animations » : une seule image fixe.

nonisolated public enum BudgetDecor {
    // MARK: Cadence

    /// Images par seconde au plus (comme les autres couches animées de l'aquarium).
    public static let imagesParSeconde = 20
    /// Mode économie d'énergie : la moitié.
    public static let imagesParSecondeEconomie = 10

    public static func imagesParSeconde(economie: Bool) -> Int {
        economie ? imagesParSecondeEconomie : imagesParSeconde
    }

    /// L'intervalle minimal entre deux images (secondes), pour `TimelineView(.animation(minimumInterval:))`.
    public static func intervalle(economie: Bool) -> Double {
        1.0 / Double(imagesParSeconde(economie: economie))
    }

    // MARK: Calques

    /// Vues animées (`TimelineView`) par décor : une derrière les poissons, une devant.
    public static let vuesAnimeesMax = 2
    /// Images pré-rendues et mises en cache par décor : fond fixe, avant-plan fixe, reflets du sol.
    public static let imagesFixesMax = 3
    /// Images pré-rendues qu'on fait glisser (`offset`) sans les redessiner.
    public static let imagesMobilesMax = 2

    // MARK: Éléments animés

    public static let rubansMax = 6
    public static let bokehMax = 12
    public static let bullesMax = 15
    public static let anneauxMax = 6
    public static let particulesMax = 24
    public static let plaquesMax = 7
    public static let halosMax = 16
    public static let lamesMax = 64
    public static let raisMax = 5
    public static let caustiquesLignesMax = 9
    public static let brumeMax = 10

    /// Répartition des particules des décors existants : derrière les poissons, puis devant (plus grosses).
    public static let particulesFondParDefaut = 16
    public static let particulesProchesParDefaut = 8
    /// Les trois points d'où montent les bulles, deux bulles chacun : six bulles au plus à la fois.
    public static let bullesAmbiance = 6

    // MARK: Coût par image

    /// Opérations de dessin (un remplissage, un trait, une image) par image, au plus, deux couches animées comprises.
    public static let operationsParImageMax = 360
    /// Opérations par seconde au plus : `operationsParImageMax` x `imagesParSeconde`.
    public static let operationsParSecondeMax = 7200
    /// En mode économie d'énergie : le budget baisse de moitié environ.
    public static let operationsParSecondeEconomieMax = 4000

    /// Ce qu'un décor dessine à chaque image (les images fixes ne comptent pas : elles sont rendues une fois).
    public struct Charge: Equatable, Sendable {
        public var rais = 0
        public var caustiquesLignes = 0
        /// Particules, derrière et devant les poissons.
        public var particules = 0
        /// Vrai si les particules sont des feuilles (un remplissage et un trait chacune).
        public var particulesFeuilles = false
        /// Bulles visibles en même temps.
        public var bulles = 0
        public var anneaux = 0
        public var plaques = 0
        public var halos = 0
        /// Lames d'herbe sans nervure (remplissage et trait).
        public var lamesSimples = 0
        /// Lames d'herbe avec nervure (remplissage, trait et nervure).
        public var lamesNervurees = 0
        public var brinsNus = 0
        /// Brins fleuris (le brin, les pétales d'un seul tracé, le cœur de la fleur).
        public var brinsFleuris = 0
        public var brume = 0
        public var rubans = 0
        public var bokeh = 0
        /// Images pré-rendues qui glissent.
        public var imagesMobiles = 0
        /// Autres petits tracés animés (racines qui balancent…).
        public var autres = 0
        /// Vues animées (`TimelineView`).
        public var vues = 2

        public init(rais: Int = 0, caustiquesLignes: Int = 0, particules: Int = 0, particulesFeuilles: Bool = false,
                    bulles: Int = 0, anneaux: Int = 0, plaques: Int = 0, halos: Int = 0, lamesSimples: Int = 0,
                    lamesNervurees: Int = 0, brinsNus: Int = 0, brinsFleuris: Int = 0, brume: Int = 0, rubans: Int = 0,
                    bokeh: Int = 0, imagesMobiles: Int = 0, autres: Int = 0, vues: Int = 2) {
            self.rais = rais
            self.caustiquesLignes = caustiquesLignes
            self.particules = particules
            self.particulesFeuilles = particulesFeuilles
            self.bulles = bulles
            self.anneaux = anneaux
            self.plaques = plaques
            self.halos = halos
            self.lamesSimples = lamesSimples
            self.lamesNervurees = lamesNervurees
            self.brinsNus = brinsNus
            self.brinsFleuris = brinsFleuris
            self.brume = brume
            self.rubans = rubans
            self.bokeh = bokeh
            self.imagesMobiles = imagesMobiles
            self.autres = autres
            self.vues = vues
        }

        public var lames: Int { lamesSimples + lamesNervurees + brinsNus + brinsFleuris }

        /// Opérations de dessin par image. En mode économie : moitié de particules, de bokeh et d'anneaux, pas de bulles,
        /// une seule famille de reflets (les lignes de reflets comptent deux traits au lieu de quatre).
        public func operations(economie: Bool = false) -> Int {
            let moitie: (Int) -> Int = { economie ? ($0 + 1) / 2 : $0 }
            var total = rais
            total += caustiquesLignes * (economie ? 2 : 4)
            total += moitie(particules) * (particulesFeuilles ? 2 : 1)
            total += economie ? 0 : bulles * 3
            total += moitie(anneaux)
            total += plaques + halos + brume + autres + imagesMobiles
            total += lamesSimples * 2 + lamesNervurees * 3 + brinsNus + brinsFleuris * 4
            total += rubans * 2
            total += moitie(bokeh)
            return total
        }

        public func operationsParSeconde(economie: Bool) -> Int {
            operations(economie: economie) * BudgetDecor.imagesParSeconde(economie: economie)
        }

        /// Vrai si cette charge tient dans le budget (normal et économie d'énergie).
        public var tientDansLeBudget: Bool { depassements.isEmpty }

        /// Ce qui dépasse le budget, en clair (vide : tout va bien).
        public var depassements: [String] {
            var liste: [String] = []
            func verifie(_ nom: String, _ valeur: Int, _ max: Int) {
                if valeur > max { liste.append("\(nom) : \(valeur) > \(max)") }
            }
            verifie("vues animées", vues, BudgetDecor.vuesAnimeesMax)
            verifie("images mobiles", imagesMobiles, BudgetDecor.imagesMobilesMax)
            verifie("rubans", rubans, BudgetDecor.rubansMax)
            verifie("bokeh", bokeh, BudgetDecor.bokehMax)
            verifie("bulles", bulles, BudgetDecor.bullesMax)
            verifie("anneaux", anneaux, BudgetDecor.anneauxMax)
            verifie("particules", particules, BudgetDecor.particulesMax)
            verifie("plaques", plaques, BudgetDecor.plaquesMax)
            verifie("halos", halos, BudgetDecor.halosMax)
            verifie("lames", lames, BudgetDecor.lamesMax)
            verifie("rais", rais, BudgetDecor.raisMax)
            verifie("lignes de reflets", caustiquesLignes, BudgetDecor.caustiquesLignesMax)
            verifie("brume", brume, BudgetDecor.brumeMax)
            verifie("opérations par image", operations(), BudgetDecor.operationsParImageMax)
            verifie("opérations par seconde", operationsParSeconde(economie: false), BudgetDecor.operationsParSecondeMax)
            verifie("opérations par seconde (économie d'énergie)", operationsParSeconde(economie: true),
                    BudgetDecor.operationsParSecondeEconomieMax)
            return liste
        }
    }

    /// Ce que dessine chaque décor à chaque image. `nil` : pas un décor dessiné.
    /// ⚠ À tenir à jour avec le code de `DecorsDessinesScenes.swift` et `DecorsDessinesEte.swift` : `BudgetDecorTests`
    /// compare les nombres de rais, de reflets et de particules aux réglages réels.
    public static func charge(_ skin: String) -> Charge? {
        switch skin {
        case "sous-bois":
            return Charge(rais: 5, caustiquesLignes: 9, particules: 24, bulles: 6, lamesSimples: 16, autres: 5)
        case "etang":
            return Charge(rais: 4, caustiquesLignes: 9, particules: 24, bulles: 6, lamesNervurees: 22, brinsNus: 16)
        case "grotte":
            return Charge(rais: 3, caustiquesLignes: 9, particules: 24, bulles: 6, halos: 1)
        case "halloween":
            return Charge(rais: 4, caustiquesLignes: 9, particules: 24, particulesFeuilles: true, bulles: 6, halos: 2, brume: 10)
        case "noel":
            return Charge(rais: 4, caustiquesLignes: 9, particules: 24, bulles: 6, plaques: 7, halos: 15, lamesSimples: 7)
        case "ouverture-truite":
            return Charge(rais: 5, caustiquesLignes: 9, particules: 24, bulles: 6, plaques: 7, brinsFleuris: 44)
        case "ete":
            // Rais fixes (dans l'image), reflets du sol = deux images qui glissent, quatre rubans de lumière,
            // douze bokehs pleins, six anneaux autour des bouées, un peu de pollen, six bulles.
            return Charge(particules: 18, bulles: 6, anneaux: 6, rubans: 4, bokeh: 12, imagesMobiles: 2)
        default:
            return nil
        }
    }
}
