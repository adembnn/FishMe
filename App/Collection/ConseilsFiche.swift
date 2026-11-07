import Core
import SwiftUI

/// Une ligne de fiche : icône marine, libellé, valeur à droite (P27 B, P28 B).
struct LigneIconeFiche: View {
    let icone: String
    let titre: String
    let valeur: String

    var body: some View {
        HStack(spacing: Espace.m) {
            Image(systemName: icone)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.marine)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(titre).font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: Espace.s)
            Text(valeur)
                .font(Police.taille(17, .bold))
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.s)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }
}

/// P27 B, « Pour toi · quelques sorties » : une ligne Appât / Hameçon / Technique / Moment, les vrais conseils de Core.
/// Un type sans conseil n'a pas de ligne ; aucun conseil du tout, aucun bloc.
struct BlocPourToi: View {
    let parType: [TypeConseil: Conseil]
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue
    @Environment(\.locale) private var locale
    private var t: AnglaisD { AnglaisD(locale) }

    private var types: [TypeConseil] { TypeConseil.allCases.filter { parType[$0] != nil } }

    var body: some View {
        Group {
            if !types.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    enteteDeGroupe(t("Pour toi · %@", NiveauPecheur.depuis(niveauBrut).motPecheur.lowercased()), haut: 22)
                    VStack(spacing: 0) {
                        ForEach(Array(types.enumerated()), id: \.element) { index, type in
                            if index > 0 { Divider().overlay(Palette.filet).padding(.leading, 52) }
                            if let conseil = parType[type] {
                                LigneIconeFiche(icone: IconesConseils.parDefaut(type), titre: type.libelle, valeur: conseil.texte)
                            }
                        }
                    }
                    .tuileFishMe(rayon: Rayon.m)
                    .padding(.top, Espace.s)
                }
            }
        }
    }
}

/// Noms des départements en toutes lettres, pour « Val-de-Marne · 94 ». `nil` si le code est inconnu.
enum NomsDepartements {
    static func nom(code: String) -> String? { table[code.uppercased()] }

    private static let table: [String: String] = [
        "01": "Ain", "02": "Aisne", "03": "Allier", "04": "Alpes-de-Haute-Provence", "05": "Hautes-Alpes",
        "06": "Alpes-Maritimes", "07": "Ardèche", "08": "Ardennes", "09": "Ariège", "10": "Aube", "11": "Aude",
        "12": "Aveyron", "13": "Bouches-du-Rhône", "14": "Calvados", "15": "Cantal", "16": "Charente",
        "17": "Charente-Maritime", "18": "Cher", "19": "Corrèze", "2A": "Corse-du-Sud", "2B": "Haute-Corse",
        "21": "Côte-d'Or", "22": "Côtes-d'Armor", "23": "Creuse", "24": "Dordogne", "25": "Doubs", "26": "Drôme",
        "27": "Eure", "28": "Eure-et-Loir", "29": "Finistère", "30": "Gard", "31": "Haute-Garonne", "32": "Gers",
        "33": "Gironde", "34": "Hérault", "35": "Ille-et-Vilaine", "36": "Indre", "37": "Indre-et-Loire",
        "38": "Isère", "39": "Jura", "40": "Landes", "41": "Loir-et-Cher", "42": "Loire", "43": "Haute-Loire",
        "44": "Loire-Atlantique", "45": "Loiret", "46": "Lot", "47": "Lot-et-Garonne", "48": "Lozère",
        "49": "Maine-et-Loire", "50": "Manche", "51": "Marne", "52": "Haute-Marne", "53": "Mayenne",
        "54": "Meurthe-et-Moselle", "55": "Meuse", "56": "Morbihan", "57": "Moselle", "58": "Nièvre", "59": "Nord",
        "60": "Oise", "61": "Orne", "62": "Pas-de-Calais", "63": "Puy-de-Dôme", "64": "Pyrénées-Atlantiques",
        "65": "Hautes-Pyrénées", "66": "Pyrénées-Orientales", "67": "Bas-Rhin", "68": "Haut-Rhin", "69": "Rhône",
        "70": "Haute-Saône", "71": "Saône-et-Loire", "72": "Sarthe", "73": "Savoie", "74": "Haute-Savoie",
        "75": "Paris", "76": "Seine-Maritime", "77": "Seine-et-Marne", "78": "Yvelines", "79": "Deux-Sèvres",
        "80": "Somme", "81": "Tarn", "82": "Tarn-et-Garonne", "83": "Var", "84": "Vaucluse", "85": "Vendée",
        "86": "Vienne", "87": "Haute-Vienne", "88": "Vosges", "89": "Yonne", "90": "Territoire de Belfort",
        "91": "Essonne", "92": "Hauts-de-Seine", "93": "Seine-Saint-Denis", "94": "Val-de-Marne", "95": "Val-d'Oise",
    ]
}
