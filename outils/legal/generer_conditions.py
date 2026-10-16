#!/usr/bin/env python3
"""Génère App/Abonnement/TexteConditions.swift depuis docs/legal/conditions-fishme.md.

Format de la source :
  <!-- version: 16 octobre 2026 | numero: 1 -->
  ## N. Titre
  paragraphes séparés par des lignes vides ; les lignes « - » deviennent des paragraphes « • ... »
  <!-- fin -->   (arrête la lecture)
Tout ce qui précède le premier « ## » est ignoré (sauf la ligne de version).
"""
import argparse
import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
SOURCE = RACINE / "docs/legal/conditions-fishme.md"
SORTIE = RACINE / "App/Abonnement/TexteConditions.swift"
RE_VERSION = re.compile(r"<!--\s*version:\s*(.+?)\s*\|\s*numero:\s*(\d+)\s*-->")
RE_TITRE = re.compile(r"^##\s+(?:(\d+)\.\s*)?(.+?)\s*$")


def echapper(texte):
    """Littéral de chaîne Swift : antislashs et guillemets échappés."""
    return texte.replace("\\", "\\\\").replace('"', '\\"')


def lire(texte):
    version, numero = None, None
    articles = []  # [titre, [paragraphes]]
    courant = None  # paragraphe en cours : liste de lignes
    est_puce = False

    def clore():
        nonlocal courant, est_puce
        if courant and articles:
            phrase = " ".join(courant)
            articles[-1][1].append(("• " + phrase) if est_puce else phrase)
        courant, est_puce = None, False

    for brut in texte.splitlines():
        ligne = brut.strip()
        m = RE_VERSION.search(ligne)
        if m:
            version, numero = m.group(1), int(m.group(2))
            continue
        if ligne == "<!-- fin -->":
            break
        t = RE_TITRE.match(ligne)
        if t:
            clore()
            articles.append([t.group(2), []])
            continue
        if not articles:
            continue
        if not ligne:
            clore()
        elif ligne.startswith("- "):
            clore()
            courant, est_puce = [ligne[2:].strip()], True
        elif courant is None:
            courant = [ligne]
        else:
            courant.append(ligne)
    clore()
    if version is None:
        sys.exit("Ligne <!-- version: ... | numero: N --> absente.")
    if not articles:
        sys.exit("Aucun article « ## » trouvé.")
    return version, numero, articles


def swift(version, numero, articles):
    sortie = [
        "// Généré depuis docs/legal/conditions-fishme.md par outils/legal/generer_conditions.py : ne pas modifier à la main.",
        "",
        "import Foundation",
        "",
        "/// Un article des conditions d'utilisation : un titre et ses paragraphes (markdown en ligne permis).",
        "struct ArticleConditions: Identifiable, Sendable {",
        "    let id: Int",
        "    let titre: String",
        "    let paragraphes: [String]",
        "}",
        "",
        "/// Le texte des conditions, embarqué dans l'app pour se lire hors ligne.",
        "enum TexteConditions {",
        "    /// Date affichée.",
        f'    static let version = "{echapper(version)}"',
        "    /// Monte à chaque changement qui doit être ré-accepté.",
        f"    static let numeroVersion = {numero}",
        "    static let articles: [ArticleConditions] = [",
    ]
    for i, (titre, paragraphes) in enumerate(articles, start=1):
        sortie.append(f'        ArticleConditions(id: {i}, titre: "{echapper(titre)}", paragraphes: [')
        for p in paragraphes:
            sortie.append(f'            "{echapper(p)}",')
        sortie.append("        ]),")
    sortie += ["    ]", "}", ""]
    return "\n".join(sortie)


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--source", type=Path, default=SOURCE)
    p.add_argument("--sortie", type=Path, default=SORTIE)
    a = p.parse_args()
    version, numero, articles = lire(a.source.read_text(encoding="utf-8"))
    a.sortie.write_text(swift(version, numero, articles), encoding="utf-8")
    print(f"{len(articles)} articles, version {version} (n° {numero}) -> {a.sortie}")


if __name__ == "__main__":
    main()
