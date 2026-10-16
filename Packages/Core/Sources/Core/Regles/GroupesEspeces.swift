import Foundation

/// Les espèces que les règles nomment en groupe ou sous un nom courant (`truite`, `salmonides`, `carnassiers`, `ecrevisse`...).
/// Les fichiers de règles (`Resources/regles/*.json`) écrivent ces mots dans `especes` ; ils ne sont ni un identifiant de
/// `especes.json` ni un code Sandre. Chaque groupe se lit sur les phrases des règles (par exemple « 3 carnassiers : sandre,
/// brochet, black-bass », « 6 salmonidés par jour (hors saumon et truite de mer) »).
/// Un mot absent de cette table ne vise aucune espèce : la règle ne s'affiche pas, elle ne vise jamais « tout » par erreur.
enum GroupesEspeces {
    private static let truites = ["truite-fario", "truite-arc-en-ciel", "truite-de-mer"]
    private static let ecrevissesExotiques = ["ecrevisse-americaine", "ecrevisse-signal", "ecrevisse-calicot", "ecrevisse-de-louisiane",
                                              "ecrevisse-marbree", "ecrevisse-virile", "ecrevisse-a-taches-rouges"]
    private static let ecrevissesNatives = ["ecrevisse-pattes-blanches", "ecrevisse-pattes-rouges", "ecrevisse-pattes-greles",
                                            "ecrevisse-des-torrents"]
    private static let carpes = ["carpe-commune", "carpe-koi", "carpe-amour", "carpe-argentee", "carpe-grosse-tete"]

    /// Clé du mot (voir `RegleDonnee.cleNom`) : identifiants d'espèces qu'il couvre.
    static let table: [String: [String]] = [
        // Groupes
        "salmonides": ["truite-fario", "truite-arc-en-ciel", "truite-tigre", "ombre-commun", "omble-de-fontaine", "omble-chevalier",
                       "cristivomer", "huchon", "coregones"],
        "carnassiers": ["brochet", "brochet-aquitain", "sandre", "black-bass", "black-bass-petite-bouche"],
        "truite": truites,
        "truites": truites,
        "ecrevisse": ecrevissesExotiques + ecrevissesNatives,
        "ecrevisses": ecrevissesExotiques + ecrevissesNatives,
        "autres ecrevisses": ecrevissesExotiques,
        "ecrevisses exotiques": ecrevissesExotiques,
        "ecrevisses americaines": ["ecrevisse-americaine", "ecrevisse-virile", "ecrevisse-signal", "ecrevisse-de-louisiane"],
        "carpe": carpes,
        "carpes": carpes,
        "anguille": ["anguille-jaune", "anguille-argentee", "civelle"],
        "lamproie": ["lamproie-marine", "lamproie-fluviatile", "lamproie-de-planer"],
        "lamproies": ["lamproie-marine", "lamproie-fluviatile", "lamproie-de-planer"],
        "carassin": ["carassin-commun", "carassin-argente"],
        "esturgeon": ["esturgeon-europeen", "esturgeon-oscietre", "esturgeon-siberien", "sterlet"],
        "alose": ["grande-alose", "alose-feinte"],
        "grenouilles autres": ["grenouille-rieuse", "grenouille-taureau"],
        "autres grenouilles": ["grenouille-rieuse", "grenouille-taureau"],
        "breme": ["breme-commune", "breme-bordeliere"],
        "barbeau": ["barbeau-fluviatile", "barbeau-meridional"],
        // Noms courants qui ne sont pas l'identifiant exact
        "coregone": ["coregones"],
        "ombre": ["ombre-commun"],
        "omble fontaine": ["omble-de-fontaine"],
        "saumon de fontaine": ["omble-de-fontaine"],
        "perche": ["perche-commune"],
        "silure": ["silure-glane"],
        "truite de lac": ["truite-fario"],
        "truite lacustre": ["truite-fario"],
        "anguille civelle": ["civelle"],
        "ecrevisse louisiane": ["ecrevisse-de-louisiane"],
        "ecrevisse californie": ["ecrevisse-signal"],
        "ecrevisse torrents": ["ecrevisse-des-torrents"],
        "ecrevisse americaine virile": ["ecrevisse-virile"],
        "bar commun": ["bar"],
        "loup": ["bar"],
        "gobie tache noire": ["gobie-a-taches-noires"],
        "gobie taches noires": ["gobie-a-taches-noires"],
        "goujon asiatique": ["pseudorasbora"],
        "gambusie ouest": ["gambusie"],
    ]

    /// Le mot d'une règle sans son préfixe `nom:` ou `autre:`, en clé de comparaison.
    static func cle(_ jeton: String) -> String {
        var s = jeton
        for p in ["nom:", "autre:"] where s.hasPrefix(p) { s = String(s.dropFirst(p.count)) }
        return RegleDonnee.cleNom(s)
    }

    /// Vrai si le mot de la règle désigne cette espèce : identifiant, code Sandre, nom, ou groupe qui la contient.
    static func vise(_ jeton: String, espece: Espece, nom: String?) -> Bool {
        if jeton == espece.id { return true }
        if let code = espece.codeSandre, jeton == code { return true }
        let k = cle(jeton)
        if k.isEmpty { return false }
        if k == RegleDonnee.cleNom(espece.id) { return true }
        if let nom, k == RegleDonnee.cleNom(nom) { return true }
        return table[k]?.contains(espece.id) ?? false
    }
}
