"""Télécharge et extrait les textes d'un département, puis écrit son manifeste.

Usage : python -I outils/regles/corpus.py <code>
Lit corpus/<code>/sources.json, une liste d'objets :
  {"fichier": "ap-2026-002.pdf", "titre": "...", "url": "https://...", "signe_le": "AAAA-MM-JJ ou null", "etat": "en vigueur, permanent"}
Pour chaque source : télécharge le fichier s'il manque (curl), extrait le texte à côté (.txt) par la couche texte du PDF,
sinon par l'OCR en français de Windows (ocr.ps1), et écrit corpus/<code>/manifeste.json (titre, URL, signature,
téléchargement, SHA-256). Relançable : ce qui est déjà téléchargé ou extrait n'est pas refait.
"""
import datetime
import hashlib
import html
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.parse

ICI = os.path.dirname(os.path.abspath(__file__))
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36"
MIN_CARS_PAGE = 300  # en dessous, la page est traitée comme un scan


def url_sure(url):
    p = urllib.parse.urlsplit(url)
    return urllib.parse.urlunsplit((p.scheme, p.netloc, urllib.parse.quote(urllib.parse.unquote(p.path), safe="/%:@!$&'()*+,;="), p.query, p.fragment))


def telecharger(url, chemin):
    r = subprocess.run(["curl", "-sSL", "--max-time", "180", "-A", UA, "-o", chemin, "-w", "%{http_code}", url_sure(url)],
                       capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.startswith("2"):
        if os.path.exists(chemin):
            os.remove(chemin)
        raise RuntimeError(f"téléchargement refusé ({r.stdout or r.stderr.strip()}) : {url}")


def texte_pdf(chemin, sortie):
    import pymupdf
    doc = pymupdf.open(chemin)
    pages = [p.get_text() for p in doc]
    # Page par page : un PDF mêle parfois pages scannées et pages à couche texte.
    scans = [i for i, t in enumerate(pages) if len(t.strip()) < MIN_CARS_PAGE]
    if scans:
        with tempfile.TemporaryDirectory() as tmp:
            for i in scans:
                doc[i].get_pixmap(dpi=300).save(os.path.join(tmp, f"page-p{i + 1:03d}.png"))
            ocr = os.path.join(tmp, "ocr.txt")
            subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", os.path.join(ICI, "ocr.ps1"), tmp, ocr],
                           check=True, capture_output=True)
            blocs = re.split(r"^===== page \d+\r?\n", open(ocr, encoding="utf-8-sig").read(), flags=re.M)[1:]
        for i, t in zip(scans, blocs):
            if len(t.strip()) > len(pages[i].strip()):
                pages[i] = t
    with open(sortie, "w", encoding="utf-8") as f:
        for i, t in enumerate(pages, 1):
            f.write(f"===== page {i:02d}\n{t}\n")
    if not scans:
        return "couche-texte"
    return "ocr-windows-fr" if len(scans) == len(pages) else f"mixte : OCR des pages {', '.join(str(i + 1) for i in scans)}"


def texte_html(chemin, sortie):
    brut = open(chemin, encoding="utf-8", errors="replace").read()
    m = re.search(r"<main.*?</main>", brut, re.S)
    t = re.sub(r"<(script|style)[^>]*>.*?</\1>", " ", m.group(0) if m else brut, flags=re.S)
    t = re.sub(r"<br\s*/?>|</p>|</li>|</tr>|</h\d>", "\n", t)
    t = html.unescape(re.sub(r"<[^>]+>", " ", t))
    t = "\n".join(re.sub(r"[ \t]+", " ", l).strip() for l in t.splitlines())
    with open(sortie, "w", encoding="utf-8") as f:
        f.write(re.sub(r"\n{3,}", "\n\n", t))
    return "page-html"


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 1
    code = sys.argv[1]
    dossier = os.path.join(ICI, "corpus", code)
    sources = json.load(open(os.path.join(dossier, "sources.json"), encoding="utf-8"))
    chemin_man = os.path.join(dossier, "manifeste.json")
    ancien = {}
    if os.path.exists(chemin_man):
        ancien = {t["fichier"]: t for t in json.load(open(chemin_man, encoding="utf-8")).get("textes", [])}
    aujourdhui = datetime.date.today().isoformat()
    sortie, erreurs = [], 0
    for s in sources:
        f = s["fichier"]
        p = os.path.join(dossier, f)
        txt = os.path.splitext(p)[0] + ".txt"
        try:
            if not os.path.exists(p):
                telecharger(s["url"], p)
            debut = open(p, "rb").read(512)
            est_pdf = debut.startswith(b"%PDF")
            if f.lower().endswith(".pdf") and not est_pdf:
                raise RuntimeError(f"{f} n'est pas un PDF (page web ou refus) : vérifie l'URL")
            extraction = ancien.get(f, {}).get("extraction")
            if not os.path.exists(txt) or not extraction:
                extraction = texte_pdf(p, txt) if est_pdf else texte_html(p, txt)
        except Exception as e:  # une source en échec n'arrête pas les autres
            print(f"ÉCHEC {f} : {e}")
            erreurs += 1
            continue
        sortie.append({"fichier": f, "texte_extrait": os.path.basename(txt), "extraction": extraction, "titre": s.get("titre"),
                       "url": s.get("url"), "signe_le": s.get("signe_le"), "etat": s.get("etat"),
                       "telecharge_le": ancien.get(f, {}).get("telecharge_le", aujourdhui),
                       "sha256": hashlib.sha256(open(p, "rb").read()).hexdigest(), "octets": os.path.getsize(p),
                       "caracteres_extraits": len(open(txt, encoding="utf-8").read())})
        print(f"OK {f} : {extraction}, {sortie[-1]['caracteres_extraits']} caractères")
    json.dump({"departement": code, "textes": sortie}, open(chemin_man, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"manifeste : {len(sortie)} textes, {erreurs} échecs")
    return 1 if erreurs else 0


if __name__ == "__main__":
    sys.exit(main())
