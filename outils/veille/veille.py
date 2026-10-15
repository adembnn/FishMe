#!/usr/bin/env python3
"""Veille des règles de pêche (lot L11) : signale qu'un texte source a peut-être changé, ou qu'un fichier de règles va expirer.

Ce que fait le script, chaque nuit (voir veille.yml.exemple) :
  1. Lit les `textes` (titre, URL) des fichiers de règles : un par département, plus national.json.
  2. Télécharge chaque page, garde le texte utile (sans script, menus, compteurs de visites, « mis à jour le ... »)
     et calcule son empreinte sha256. Un PDF est empreint tel quel (octets).
  3. Compare à l'empreinte de la veille (empreintes.json, hors de git). Une page changée donne une alerte :
     « l'arrêté du 94 a peut-être changé ». Une page vue pour la première fois ne donne rien.
  4. Donne une alerte quand l'`expire_min` d'un fichier (le plus petit `expire_le` de ses règles) est à moins de 30 jours
     (une seule fois par date d'expiration).

Une alerte n'est PAS une preuve : une page peut changer sans que la règle change. Un humain tranche, avec la procédure
imprimée sous les alertes (deux lectures, consensus.py, chargement par D1, relecture, cas d'or, publication).
La veille ne promet pas de voir tous les arrêtés temporaires (sécheresse, pollution).

Codes de sortie : 0 rien à signaler ; 1 au moins une alerte ; 2 erreur d'usage ou de lecture des fichiers de règles.
Une page injoignable n'est pas un changement : elle est listée à part et son empreinte reste celle de la veille.

Usage :
  python3 -I outils/veille/veille.py                      # la veille, sur les fichiers de règles du dépôt
  python3 -I outils/veille/veille.py --generer-sources    # écrit sources.json (liste des pages surveillées)
  python3 -I outils/veille/veille.py --essai              # essai sur des pages d'essai, sans réseau

Bibliothèque standard seulement. Aucune clé, aucun compte : la version des articles R436 par l'API PISTE n'est pas
branchée (elle demande qu'Adem ouvre un compte ; la clé irait dans un secret GitHub et dans .env, jamais dans le chat).
"""
import argparse
import hashlib
import html.parser
import json
import os
import re
import shutil
import sys
import tempfile
import time
import unicodedata
import urllib.error
import urllib.request
from datetime import date, datetime
from pathlib import Path

ICI = Path(__file__).resolve().parent
RACINE = ICI.parent.parent
REGLES_PAR_DEFAUT = RACINE / "Packages" / "Core" / "Sources" / "Core" / "Resources" / "regles"
EMPREINTES_PAR_DEFAUT = ICI / "empreintes.json"
SEUIL_JOURS = 30
TAILLE_MAX = 30 * 1024 * 1024
AGENT = "FishMe-veille-regles/1.0"

PROCEDURE = """\
Procédure (deux paires d'yeux) :
1. Lire le nouveau texte (ouvrir le lien, comparer avec la citation du fichier de règles).
2. Le faire lire deux fois, indépendamment, par la consigne de D3 (outils/regles/consigne-departement.md).
3. Comparer les deux lectures avec outils/regles/consensus.py.
4. Charger le fichier avec outils/verifier_donnees.py --charger <code> (D1, fusion prudente).
5. Faire relire par un humain pour l'Île-de-France (75, 92, 93, 94, 77).
6. Rejouer les cas d'or (swift test), puis publier le seul fichier du département et l'index.
Une alerte n'est pas une preuve : la page a peut-être changé sans que la règle change. Un humain tranche."""

# Lignes jetées avant l'empreinte : elles changent sans que la règle change.
LIGNE_VOLATILE = re.compile(
    r"(mis[e]? à jour|dernière (mise à jour|modification|actualisation)|modifié le|actualisé le|publié le|consulté le|"
    r"nombre de visite|visiteurs?|visites?\b|compteur|©|copyright|cookies?|\bimprimer\b|partager sur|"
    r"aujourd'hui nous sommes)", re.I)
BALISES_IGNOREES = {"script", "style", "noscript", "template", "svg", "nav", "footer", "header", "aside", "form", "head"}
BALISES_BLOC = {"p", "div", "br", "li", "tr", "h1", "h2", "h3", "h4", "h5", "h6", "section", "article", "table", "ul", "ol"}


# --- empreinte d'une page -----------------------------------------------------------------------------------------------

class _Texte(html.parser.HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.morceaux = []
        self.profondeur_ignoree = 0

    def handle_starttag(self, tag, attrs):
        if tag in BALISES_IGNOREES:
            self.profondeur_ignoree += 1
        elif tag in BALISES_BLOC:
            self.morceaux.append("\n")

    def handle_endtag(self, tag):
        if tag in BALISES_IGNOREES:
            self.profondeur_ignoree = max(0, self.profondeur_ignoree - 1)
        elif tag in BALISES_BLOC:
            self.morceaux.append("\n")

    def handle_data(self, data):
        if not self.profondeur_ignoree:
            self.morceaux.append(data)


def nettoyer(contenu, type_contenu=""):
    """Le texte utile d'une page : sans balises, menus, scripts ni lignes qui changent à chaque visite."""
    texte = contenu.decode(_charset(type_contenu, contenu), errors="replace")
    if re.search(r"<\s*(html|body|p|div|table)\b", texte, re.I):
        analyseur = _Texte()
        analyseur.feed(re.sub(r"<!--.*?-->", " ", texte, flags=re.S))
        texte = "".join(analyseur.morceaux)
    texte = unicodedata.normalize("NFKC", texte).replace(" ", " ").lower()
    lignes = []
    for ligne in texte.splitlines():
        ligne = re.sub(r"\s+", " ", ligne).strip()
        if ligne and not LIGNE_VOLATILE.search(ligne):
            lignes.append(ligne)
    return "\n".join(lignes)


def _charset(type_contenu, contenu):
    m = re.search(r"charset=([\w-]+)", type_contenu or "", re.I) or re.search(rb"charset=[\"']?([\w-]+)", contenu[:2048], re.I)
    if m:
        nom = m.group(1)
        nom = nom.decode("ascii", "ignore") if isinstance(nom, bytes) else nom
        try:
            "".encode(nom)
            return nom
        except LookupError:
            pass
    return "utf-8"


def empreinte_page(contenu, type_contenu=""):
    """sha256 du texte nettoyé ; pour un PDF (ou tout contenu binaire), sha256 des octets."""
    if contenu[:5] == b"%PDF-" or "pdf" in (type_contenu or "").lower():
        return hashlib.sha256(contenu).hexdigest()
    return hashlib.sha256(nettoyer(contenu, type_contenu).encode("utf-8")).hexdigest()


def lire_page(url, delai=30):
    """(contenu, type de contenu) d'une page, ou une exception. Accepte http(s) et file:// (essai)."""
    requete = urllib.request.Request(url, headers={"User-Agent": AGENT})
    with urllib.request.urlopen(requete, timeout=delai) as reponse:
        contenu = reponse.read(TAILLE_MAX + 1)
        if len(contenu) > TAILLE_MAX:
            raise ValueError("page trop grosse")
        type_contenu = reponse.headers.get("Content-Type", "") if hasattr(reponse, "headers") else ""
    return contenu, type_contenu


# --- fichiers de règles -------------------------------------------------------------------------------------------------

def lire_fichiers_regles(dossier):
    """{code: contenu JSON} pour chaque <code>.json (et national.json) du dossier ; index.json est ignoré."""
    dossier = Path(dossier)
    if not dossier.is_dir():
        raise FileNotFoundError(f"dossier de règles introuvable : {dossier}")
    fichiers = {}
    for chemin in sorted(dossier.glob("*.json")):
        if chemin.stem == "index":
            continue
        fichiers[chemin.stem] = json.loads(chemin.read_text(encoding="utf-8"))
    return fichiers


def tirer_sources(fichiers):
    """Les pages à surveiller, tirées des `textes` des fichiers : [{departement, id, titre, url}], sans doublon."""
    sources, vus = [], set()
    for code, fichier in sorted(fichiers.items()):
        for texte in fichier.get("textes", []):
            url = (texte.get("url") or "").strip()
            if url and (code, url) not in vus:
                vus.add((code, url))
                sources.append({"departement": code, "id": texte.get("id", ""), "titre": texte.get("titre", ""), "url": url})
    return sources


def expire_min(fichier):
    """Le plus petit expire_le des règles du fichier (« aaaa-mm-jj »), ou None si aucune règle n'expire."""
    dates = [r["expire_le"] for r in fichier.get("regles", []) if r.get("expire_le")]
    return min(dates) if dates else None


# --- la veille ----------------------------------------------------------------------------------------------------------

def nom_du_texte(code):
    return "le socle national (Code de l'environnement)" if code == "national" else f"l'arrêté du {code}"


def veiller(sources, fichiers, chemin_empreintes, aujourdhui, jours=SEUIL_JOURS, lire=lire_page, pause=0.0):
    """Une veille. Retourne {"alertes": [...], "injoignables": [...], "nouvelles": n}. Met à jour les empreintes."""
    try:
        memoire = json.loads(Path(chemin_empreintes).read_text(encoding="utf-8"))
    except (OSError, ValueError):
        memoire = {}
    pages = memoire.setdefault("pages", {})
    signalees = memoire.setdefault("expirations_signalees", {})

    alertes, injoignables, nouvelles = [], [], 0
    cache = {}  # une même URL citée par plusieurs départements n'est lue qu'une fois
    for source in sources:
        url = source["url"]
        if url not in cache:
            if cache and pause:
                time.sleep(pause)
            try:
                contenu, type_contenu = lire(url)
                cache[url] = empreinte_page(contenu, type_contenu)
            except Exception as erreur:  # réseau, 403, 404, délai : jamais un changement
                cache[url] = None
                injoignables.append(f"{url} ({type(erreur).__name__})")
        courante = cache[url]
        if courante is None:
            continue
        connue = pages.get(url, {}).get("empreinte")
        if connue is None:
            nouvelles += 1
        elif connue != courante:
            alertes.append({
                "type": "texte", "departement": source["departement"], "url": url,
                "phrase": f"{nom_du_texte(source['departement'])} a peut-être changé : « {source['titre']} » ({url})",
            })
        pages[url] = {"empreinte": courante, "vu_le": aujourdhui.isoformat()}

    for code, fichier in sorted(fichiers.items()):
        echeance = expire_min(fichier)
        if not echeance:
            continue
        reste = (date.fromisoformat(echeance) - aujourdhui).days
        if reste < jours and signalees.get(code) != echeance:
            quand = f"dans {reste} jours" if reste >= 0 else f"depuis {-reste} jours"
            alertes.append({
                "type": "expiration", "departement": code, "echeance": echeance,
                "phrase": f"le fichier de règles de {'national' if code == 'national' else 'département ' + code} expire "
                          f"le {echeance[8:]}/{echeance[5:7]}/{echeance[:4]} ({quand}) : relire les textes de la nouvelle année, "
                          f"sinon ses règles passeront à « vérifie l'arrêté ».",
            })
            signalees[code] = echeance

    chemin = Path(chemin_empreintes)
    chemin.parent.mkdir(parents=True, exist_ok=True)
    tmp = chemin.with_suffix(".tmp")
    tmp.write_text(json.dumps(memoire, ensure_ascii=False, indent=1, sort_keys=True), encoding="utf-8")
    os.replace(tmp, chemin)
    return {"alertes": alertes, "injoignables": injoignables, "nouvelles": nouvelles}


def texte_des_alertes(resultat):
    lignes = [f"- {a['phrase']}" for a in resultat["alertes"]]
    return "\n".join(lignes) + "\n\n" + PROCEDURE + "\n" if lignes else ""


# --- essai --------------------------------------------------------------------------------------------------------------

def _regle(expire):
    return {"id": "essai-1", "type": "ouverture", "expire_le": expire}


def essai():
    """Essai sur des pages d'essai (outils/veille/essai/), sans réseau. 0 si tout est conforme."""
    echecs = []

    def verifier(condition, message):
        print(("OK     " if condition else "ÉCHEC  ") + message)
        if not condition:
            echecs.append(message)

    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        stable, mobile = tmp / "stable.html", tmp / "mobile.html"
        shutil.copy(ICI / "essai" / "page-stable.html", stable)
        shutil.copy(ICI / "essai" / "page-avant.html", mobile)
        fichiers = {
            "94": {"textes": [{"id": "t1", "titre": "Arrêté d'essai du 94", "url": stable.as_uri()}], "regles": [_regle("2027-06-30")]},
            "75": {"textes": [{"id": "t1", "titre": "Arrêté d'essai du 75", "url": mobile.as_uri()}], "regles": [_regle("2027-06-30")]},
            "2A": {"textes": [{"id": "t1", "titre": "Page absente", "url": (tmp / "absente.html").as_uri()}], "regles": [_regle("2026-11-01")]},
            "national": {"textes": [], "regles": [_regle(None)]},
        }
        sources = tirer_sources(fichiers)
        empreintes = tmp / "empreintes.json"
        jour = date(2026, 10, 15)

        verifier(len(sources) == 3, "sources tirées des textes des fichiers de règles (3 pages)")

        r = veiller(sources, fichiers, empreintes, jour)
        verifier(r["nouvelles"] == 2, "première veille : 2 empreintes enregistrées, aucune alerte de texte")
        verifier([a["type"] for a in r["alertes"]] == ["expiration"] and r["alertes"][0]["departement"] == "2A",
                 "expire_min du 2A à 17 jours : une alerte d'expiration")
        verifier(len(r["injoignables"]) == 1, "page absente : listée comme injoignable, pas comme un changement")

        r = veiller(sources, fichiers, empreintes, jour)
        verifier(r["alertes"] == [], "pages inchangées : silence (l'expiration n'est signalée qu'une fois)")

        stable.write_text(stable.read_text(encoding="utf-8").replace("1234", "9876").replace("3 novembre", "12 décembre"),
                          encoding="utf-8")
        r = veiller(sources, fichiers, empreintes, jour)
        verifier(r["alertes"] == [], "compteur de visites et « mis à jour le » changés : silence (pas de fausse alerte)")

        shutil.copy(ICI / "essai" / "page-apres.html", mobile)
        r = veiller(sources, fichiers, empreintes, jour)
        verifier(len(r["alertes"]) == 1 and r["alertes"][0]["type"] == "texte" and "l'arrêté du 75 a peut-être changé" in r["alertes"][0]["phrase"]
                 and "Arrêté d'essai du 75" in r["alertes"][0]["phrase"], "texte d'une page changé : une alerte qui nomme le texte (75)")
        verifier("Procédure" in texte_des_alertes(r) and "consensus.py" in texte_des_alertes(r), "l'alerte porte la procédure")

        r = veiller(sources, fichiers, empreintes, jour)
        verifier(r["alertes"] == [], "changement déjà signalé : silence la nuit suivante")

        for avance, attendu in [(date(2026, 11, 30), 0), (date(2026, 12, 1), 0), (date(2026, 12, 2), 1)]:
            sous = tmp / f"exp-{avance}.json"
            r = veiller([], {"94": {"regles": [_regle("2026-12-31")]}}, sous, avance)
            verifier(len(r["alertes"]) == attendu, f"expire_min au 31/12/2026, veille du {avance.isoformat()} : "
                     f"{'alerte' if attendu else 'silence'} (seuil : moins de {SEUIL_JOURS} jours)")

    print("essai : tout est conforme." if not echecs else f"essai : {len(echecs)} échec(s).")
    return 0 if not echecs else 1


# --- ligne de commande --------------------------------------------------------------------------------------------------

def main(argv=None):
    p = argparse.ArgumentParser(description="Veille des règles de pêche (L11).")
    p.add_argument("--essai", action="store_true", help="essai sur des pages d'essai, sans réseau")
    p.add_argument("--generer-sources", action="store_true", help="écrit sources.json (pages surveillées) et s'arrête")
    p.add_argument("--regles", default=str(REGLES_PAR_DEFAUT), help="dossier des fichiers de règles")
    p.add_argument("--sources", default=str(ICI / "sources.json"), help="fichier des sources écrit par --generer-sources")
    p.add_argument("--empreintes", default=str(EMPREINTES_PAR_DEFAUT), help="empreintes de la veille (hors de git)")
    p.add_argument("--sortie-alertes", help="écrit les alertes (Markdown) dans ce fichier, pour ouvrir une alerte du dépôt")
    p.add_argument("--aujourdhui", help="aaaa-mm-jj (essais ; par défaut la date du jour)")
    p.add_argument("--jours", type=int, default=SEUIL_JOURS, help="alerte d'expiration sous ce nombre de jours")
    p.add_argument("--pause", type=float, default=1.0, help="secondes entre deux pages")
    a = p.parse_args(argv)

    if a.essai:
        return essai()
    try:
        fichiers = lire_fichiers_regles(a.regles)
        aujourdhui = date.fromisoformat(a.aujourdhui) if a.aujourdhui else date.today()
    except (OSError, ValueError) as erreur:
        print(f"Erreur : {erreur}", file=sys.stderr)
        return 2
    sources = tirer_sources(fichiers)
    if a.generer_sources:
        Path(a.sources).write_text(json.dumps({"sources": sources}, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"{len(sources)} pages écrites dans {a.sources}")
        return 0
    if not sources and not fichiers:
        print("Erreur : aucun fichier de règles à surveiller.", file=sys.stderr)
        return 2

    resultat = veiller(sources, fichiers, a.empreintes, aujourdhui, a.jours, pause=a.pause)
    for url in resultat["injoignables"]:
        print(f"page injoignable (pas un changement) : {url}", file=sys.stderr)
    texte = texte_des_alertes(resultat)
    if texte:
        print(texte)
        if a.sortie_alertes:
            Path(a.sortie_alertes).write_text(texte, encoding="utf-8")
        return 1
    print(f"Rien à signaler ({len(sources)} pages, {resultat['nouvelles']} nouvelles empreintes, "
          f"{len(resultat['injoignables'])} injoignables).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
