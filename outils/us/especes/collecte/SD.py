"""SD : South Dakota Game, Fish and Parks. Niveau Etat : tableau « Fish species found in South Dakota » du
« Guide to Common Fishes of South Dakota » (GFP, imprime 2022), avec noms latins fournis par l'agence.

Usage :
  1. telecharger https://gfp.sd.gov/userdocs/docs/GuidetoCommonFishes.pdf dans /private/tmp/claude-501/brut-us/especes/esp-7/sdguide.pdf
  2. extraire le texte (macOS, PDFKit) :  swiftc pdf.swift -o pdftxt && ./pdftxt sdguide.pdf > sdguide.txt
     (pdf.swift : `import PDFKit; print(PDFDocument(url: URL(fileURLWithPath: CommandLine.arguments[1]))!.string ?? "")`)
  3. python3 -I SD.py [sdguide.txt]

Seules les especes de peche (genres listes ci-dessous) sont gardees ; les petits cyprinides, dards, etc. sont ecartes."""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _commun import DATE, ecrire, resoudre  # noqa: E402

BRUT = "/private/tmp/claude-501/brut-us/especes/esp-7"
URL = "https://gfp.sd.gov/userdocs/docs/GuidetoCommonFishes.pdf"
SOURCES = [{"nom": "SD GFP, Guide to Common Fishes of South Dakota (tableau des espèces)", "url": URL,
            "licence": "non précisée", "date": DATE}]
# Genres de pêche gardés (sport, poissons-chats, grosses espèces de rivière, carpes et catostomidés pêchés)
GENRES = {"Acipenser", "Scaphirhynchus", "Polyodon", "Lepisosteus", "Hiodon", "Dorosoma", "Cyprinus", "Ctenopharyngodon",
          "Hypophthalmichthys", "Carpiodes", "Ictiobus", "Cycleptus", "Catostomus", "Moxostoma", "Ameiurus", "Ictalurus",
          "Pylodictis", "Osmerus", "Coregonus", "Oncorhynchus", "Salmo", "Salvelinus", "Esox", "Lota", "Morone",
          "Ambloplites", "Lepomis", "Micropterus", "Pomoxis", "Perca", "Sander", "Aplodinotus"}
# Coquille de l'imprimé (Percina maculate) corrigée ; hors genres gardés de toute façon
LIGNE = re.compile(r"^([A-Z][A-Za-z' \-]+?) ([A-Z][a-z]+) ([a-z]{3,}) (Yes|No)\b")


def parser_tableau(texte):
    """-> liste de (nom commun, latin, 'Yes'|'No' natif) du tableau final du guide."""
    out = []
    debut = texte.find("Fish species found in South Dakota")
    # le tableau est apres la table des matieres : on prend la derniere occurrence de « CATOSTOMIDAE » etc. en lisant tout le texte
    for l in texte.split("\n"):
        m = LIGNE.match(l.strip())
        if m:
            out.append((m.group(1), f"{m.group(2)} {m.group(3)}", m.group(4)))
    return out


def main(chemin=None):
    chemin = chemin or os.path.join(BRUT, "sdguide.txt")
    texte = open(chemin, encoding="utf-8").read()
    # ne garder que le tableau final (apres « Native SD Status »)
    i = texte.find("Native SD Status")
    lignes = parser_tableau(texte[i:])
    vus, entrees, ecartes = set(), [], []
    for nom, latin, nat in lignes:
        if latin.split()[0] not in GENRES or latin in vus:
            continue
        vus.add(latin)
        slug, lat_table, propre = resoudre(nom)
        entrees.append({"slug": slug, "nom": nom, "latin": lat_table if (lat_table and slug) else latin,
                        "zone": {"type": "etat", "id": "SD", "nom": "South Dakota"},
                        "preuve": "liste_agence", "src": 0, "confiance": "officielle"})
    p, taille = ecrire("SD", "agence", SOURCES, entrees)
    print(p, taille, "octets ; lignes du tableau:", len(lignes), "; entrees (peche):", len(entrees))
    print("sans slug:", [e["nom"] for e in entrees if e["slug"] is None])


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else None)
