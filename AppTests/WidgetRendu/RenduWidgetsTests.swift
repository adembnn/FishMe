#if DEBUG
import Foundation
import SwiftUI
import Testing
import WidgetKit
@testable import BuildChallenge

// L15 : rend les widgets de FishMe en PNG avec ImageRenderer, pour les montrer sans passer par la galerie de widgets.
// Limite connue : Button(intent:), widgetURL et containerBackground restent sans effet hors widget (d'où fondVisible: true).
// Les images sont écrites dans reports/ecrans/L15/ à la racine du dépôt.

private enum TailleRendu {
    case petit, moyen, grand, rectangulaire, rond

    var taille: CGSize {
        switch self {
        case .petit: CGSize(width: 170, height: 170)
        case .moyen: CGSize(width: 364, height: 170)
        case .grand: CGSize(width: 364, height: 382)
        case .rectangulaire: CGSize(width: 172, height: 76)
        case .rond: CGSize(width: 76, height: 76)
        }
    }

    var famille: WidgetFamily {
        switch self {
        case .petit: .systemSmall
        case .moyen: .systemMedium
        case .grand: .systemLarge
        case .rectangulaire: .accessoryRectangular
        case .rond: .accessoryCircular
        }
    }

    var estAccessoire: Bool { self == .rectangulaire || self == .rond }
}

@MainActor
private func dossierSortie() throws -> URL {
    // #filePath = <racine>/AppTests/WidgetRendu/RenduWidgetsTests.swift
    let racine = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // WidgetRendu
        .deletingLastPathComponent() // AppTests
        .deletingLastPathComponent() // racine du dépôt
    let dossier = racine.appendingPathComponent("reports/ecrans/L15", isDirectory: true)
    try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
    return dossier
}

@MainActor
private func rendreEtEcrire<Contenu: View>(_ contenu: Contenu, format: TailleRendu, nom: String) throws {
    let largeur = format.taille.width
    let hauteur = format.taille.height

    let cadre = contenu.frame(width: largeur, height: hauteur)
    let image: AnyView
    if format.estAccessoire {
        // Simule l'écran verrouillé : fond gris foncé, mode sombre, texte blanc.
        image = AnyView(
            cadre
                .foregroundStyle(Color.white)
                .background(Color(red: 0x1C / 255, green: 0x2A / 255, blue: 0x33 / 255))
                .environment(\.colorScheme, .dark)
        )
    } else {
        image = AnyView(cadre.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous)))
    }

    let rendu = ImageRenderer(content: image)
    rendu.scale = 3
    let donnees = rendu.uiImage?.pngData()
    #expect(donnees != nil, "Rendu impossible : \(nom)")

    let fichier = try dossierSortie().appendingPathComponent(nom)
    if let donnees {
        try donnees.write(to: fichier, options: .atomic)
    }
    let taille = (try? FileManager.default.attributesOfItem(atPath: fichier.path)[.size] as? Int) ?? 0
    #expect(FileManager.default.fileExists(atPath: fichier.path), "Fichier absent : \(nom)")
    #expect(taille > 1024, "Fichier trop léger (\(taille) octets) : \(nom)")
}

@MainActor
@Suite("L15 Rendu des widgets en images")
struct RenduWidgetsTests {
    // MARK: Aquarium

    private func aquarium(_ entree: EntreeAquarium, _ format: TailleRendu, _ nom: String) throws {
        try rendreEtEcrire(
            VueAquariumWidget(entree: entree, famille: format.famille, fondVisible: true, anime: false),
            format: format, nom: nom)
    }

    @Test func aquariumPetit() throws {
        try aquarium(.exempleRendu(pro: true), .petit, "aquarium-petit.png")
    }

    @Test func aquariumMoyen() throws {
        try aquarium(.exempleRendu(pro: true), .moyen, "aquarium-moyen.png")
    }

    @Test func aquariumMoyenSansPro() throws {
        try aquarium(.exempleRendu(pro: false), .moyen, "aquarium-moyen-sans-pro.png")
    }

    @Test func aquariumGrand() throws {
        try aquarium(.exempleRendu(pro: true), .grand, "aquarium-grand.png")
    }

    @Test func aquariumGrandRepas() throws {
        try aquarium(.exempleRendu(pro: true, repas: true), .grand, "aquarium-grand-repas.png")
    }

    @Test func aquariumVerrouRectangulaire() throws {
        try aquarium(.exempleRendu(pro: true), .rectangulaire, "aquarium-verrou-rect.png")
    }

    @Test func aquariumVerrouRond() throws {
        try aquarium(.exempleRendu(pro: true), .rond, "aquarium-verrou-rond.png")
    }

    // MARK: Carte

    private func carte(_ entree: EntreeCarte, _ format: TailleRendu, _ nom: String) throws {
        try rendreEtEcrire(
            VueCarteWidget(entree: entree, famille: format.famille, fondVisible: true),
            format: format, nom: nom)
    }

    @Test func cartePetitRectoLegendaire() throws {
        try carte(.exempleRendu(verso: false, rarete: 3), .petit, "carte-petit-recto.png")
    }

    @Test func carteGrandRectoRare() throws {
        try carte(.exempleRendu(verso: false, rarete: 2), .grand, "carte-grand-recto.png")
    }

    @Test func carteGrandVerso() throws {
        try carte(.exempleRendu(verso: true, rarete: 2), .grand, "carte-grand-verso.png")
    }

    // MARK: Session

    private func session(_ entree: EntreeSessionWidget, _ format: TailleRendu, _ nom: String) throws {
        try rendreEtEcrire(
            VueSessionWidget(entree: entree, famille: format.famille, fondVisible: true),
            format: format, nom: nom)
    }

    @Test func sessionPetitEnCours() throws {
        try session(.exempleRendu(enCours: true), .petit, "session-petit.png")
    }

    @Test func sessionMoyenEnCours() throws {
        try session(.exempleRendu(enCours: true), .moyen, "session-moyen.png")
    }

    @Test func sessionPetitSansSession() throws {
        try session(.exempleRendu(enCours: false), .petit, "session-petit-vide.png")
    }

    @Test func sessionVerrouRectangulaireEnCours() throws {
        try session(.exempleRendu(enCours: true), .rectangulaire, "session-verrou-rect.png")
    }
}
#endif
