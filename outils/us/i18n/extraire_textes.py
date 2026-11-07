#!/usr/bin/env python3
"""Inventaire des textes français affichés par FishMe (lot us-i18n).

Lecture seule : le script ne modifie aucun fichier de l'app. Il parcourt
App/, WidgetAquarium/, Widget/ et Packages/Core/Sources, repère les littéraux
Swift affichés (Text, Label, Button, navigationTitle, accessibilityLabel,
alertes, String(localized:), intents...) et les textes des JSON de ressources
(phrases de règles, conseils, noms d'espèces...), puis écrit :

  inventaire.csv       une ligne par texte hors règles (fichier, ligne, texte, type, interpolations, drapeaux)
  inventaire-regles.csv  idem pour les 98 fichiers regles/*.json (15 Mo, non versionné)
  formats.csv          dates, nombres et unités écrits en dur dans le code
  statistiques.json    tous les chiffres de l'audit
  termes.csv           fréquence des mots et des couples de mots (base du glossaire)

Usage : python3 outils/us/i18n/extraire_textes.py [--racine .] [--sortie reports/us/i18n]
Python 3.9+, bibliothèque standard seulement.
"""
import argparse
import csv
import json
import os
import re
import sys
from collections import Counter, defaultdict

DOSSIERS = ["App", "WidgetAquarium", "Widget", "Packages/Core/Sources"]
EXCLUS_CHEMIN = (".xcassets", ".mlpackage", ".colorset", ".build/", "/Tests/")

# --- Lexeur Swift minimal -----------------------------------------------------

class Litteral:
    __slots__ = ("debut", "fin", "ligne", "texte", "interpolations", "brut")

    def __init__(self, debut, fin, ligne, texte, interpolations, brut):
        self.debut, self.fin, self.ligne = debut, fin, ligne
        self.texte, self.interpolations, self.brut = texte, interpolations, brut


def _fin_interpolation(src, i):
    """src[i] est le premier caractère après `\\(` ; rend l'indice de la `)` fermante."""
    profondeur = 1
    n = len(src)
    while i < n:
        c = src[i]
        if c == '"':
            _, i = lire_chaine(src, i, 0)  # chaîne imbriquée
            continue
        if c == "(":
            profondeur += 1
        elif c == ")":
            profondeur -= 1
            if profondeur == 0:
                return i
        i += 1
    return n


def lire_chaine(src, i, ligne0):
    """Lit un littéral à partir du guillemet ouvrant src[i] (ou des # qui précèdent déjà consommés ailleurs).
    Rend (Litteral, indice_apres). Gère \"\"\", #\"...\"#, interpolations imbriquées."""
    n = len(src)
    # Dièses précédents.
    j = i
    while j > 0 and src[j - 1] == "#":
        j -= 1
    hashes = i - j
    debut = j
    multi = src.startswith('"""', i)
    ouv = 3 if multi else 1
    k = i + ouv
    fermeture = ('"""' if multi else '"') + "#" * hashes
    interp_tag = "\\" + "#" * hashes + "("
    texte = []
    interpolations = []
    while k < n:
        if src.startswith(interp_tag, k):
            debut_expr = k + len(interp_tag)
            fin = _fin_interpolation(src, debut_expr)
            expr = src[debut_expr:fin]
            interpolations.append(expr)
            texte.append("\\(" + expr + ")")
            k = fin + 1
            continue
        if src.startswith(fermeture, k):
            k += len(fermeture)
            break
        if src[k] == "\\" and hashes == 0 and k + 1 < n:
            suiv = src[k + 1]
            texte.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\", "'": "'"}.get(suiv, "\\" + suiv))
            k += 2
            continue
        if not multi and src[k] == "\n":  # littéral non fermé : on s'arrête
            break
        texte.append(src[k])
        k += 1
    brut = src[debut:k]
    return Litteral(debut, k, 0, "".join(texte), interpolations, brut), k


def analyser(src):
    """Rend (litteraux, masque). masque = source sans commentaires ni contenu de chaînes, même longueur."""
    n = len(src)
    masque = list(src)
    litteraux = []
    i = 0
    while i < n:
        c = src[i]
        if c == "/" and i + 1 < n and src[i + 1] == "/":
            fin = src.find("\n", i)
            fin = n if fin < 0 else fin
            for k in range(i, fin):
                masque[k] = " "
            i = fin
            continue
        if c == "/" and i + 1 < n and src[i + 1] == "*":
            fin = src.find("*/", i + 2)
            fin = n if fin < 0 else fin + 2
            for k in range(i, fin):
                if masque[k] != "\n":
                    masque[k] = " "
            i = fin
            continue
        if c == '"':
            lit, apres = lire_chaine(src, i, 0)
            lit.ligne = src.count("\n", 0, lit.debut) + 1
            litteraux.append(lit)
            for k in range(lit.debut + 1, apres - 1):
                if masque[k] != "\n":
                    masque[k] = " "
            i = apres
            continue
        i += 1
    return litteraux, "".join(masque)


# --- Contexte d'un littéral ----------------------------------------------------

def contexte(masque, pos):
    """Rend (appel, etiquette, premier_positionnel) pour le littéral commençant en pos."""
    profondeur = 0
    k = pos - 1
    seg_debut = None
    ouvreur = None
    while k >= 0:
        c = masque[k]
        if c in ")]}":
            profondeur += 1
        elif c in "([{":
            if profondeur == 0:
                ouvreur = k
                break
            profondeur -= 1
        elif c == "," and profondeur == 0 and seg_debut is None:
            seg_debut = k + 1
        k -= 1
    if seg_debut is None:
        seg_debut = (ouvreur + 1) if ouvreur is not None else max(0, pos - 80)
    segment = masque[seg_debut:pos]
    m = re.match(r"\s*([A-Za-z_]\w*)\s*:(?!:)", segment)
    etiquette = m.group(1) if m else None
    appel = None
    if ouvreur is not None and masque[ouvreur] == "(":
        m2 = re.search(r"([A-Za-z_][\w]*)\s*$", masque[:ouvreur])
        if m2:
            appel = m2.group(1)
    # `: LocalizedStringResource = "..."` ou `IntentDescription = "..."`
    if appel is None:
        avant = masque[max(0, pos - 120):pos]
        m3 = re.search(r"(LocalizedStringResource|IntentDescription)\s*=\s*$", avant)
        if m3:
            appel = m3.group(1)
    return appel, etiquette, (etiquette is None and seg_debut == ((ouvreur or -1) + 1))


APPELS_UI = {
    "Text": "Text", "Label": "Label", "Button": "Button", "Toggle": "Toggle", "TextField": "TextField",
    "SecureField": "TextField", "TextEditor": "TextField", "Picker": "Picker", "Section": "Section", "Menu": "Menu",
    "Link": "Link", "NavigationLink": "Link", "DisclosureGroup": "Section", "Tab": "Tab",
    "ShareLink": "ShareLink", "ContentUnavailableView": "ContentUnavailable", "GroupBox": "Section",
    "LabeledContent": "Label", "Stepper": "Stepper", "DatePicker": "Picker", "ProgressView": "Label",
    "Gauge": "Label", "navigationTitle": "navigationTitle", "navigationBarTitle": "navigationTitle",
    "accessibilityLabel": "accessibilityLabel", "accessibilityHint": "accessibilityHint",
    "accessibilityValue": "accessibilityValue", "accessibilityIdentifier": None,
    "alert": "alerte", "confirmationDialog": "alerte", "LocalizedStringResource": "String(localized:)",
    "localized": "String(localized:)", "IntentDescription": "intent", "configurationDisplayName": "widget",
    "description": "widget", "TypeDisplayRepresentation": "intent", "DisplayRepresentation": "intent",
    "searchable": "TextField", "badge": "Label", "navigationSubtitle": "navigationTitle",
}
ETIQUETTES_TEXTE = {"title", "message", "description", "prompt", "subtitle", "placeholder", "label", "header",
                    "footer", "subject", "text", "name", "legende", "texte", "libelle", "detail", "titre", "corps",
                    "localized"}
ETIQUETTES_NON_TEXTE = {"systemImage", "image", "systemName", "id", "value", "format", "selection", "isPresented",
                        "role", "kind", "key", "name_", "url", "item", "preview", "icon", "icone", "symbole"}
APPELS_BRUIT = {"Logger", "print", "debugPrint", "assertionFailure", "fatalError", "precondition", "Image",
                "NSRegularExpression", "UserDefaults", "AppStorage", "SceneStorage", "URL", "Notification",
                "NSPredicate", "Logger", "os_log", "XCTAssert", "expect", "Locale", "DateFormatter", "Calendar",
                "TimeZone", "Bundle", "NSSortDescriptor", "CKRecord", "CKQuery", "CKSubscription", "Data",
                "systemName", "Color", "Font", "UIImage", "NSItemProvider", "Predicate", "Identifier"}

MOTS_FR = set("""le la les l un une des du de d et ou où pour sur avec sans dans ton ta tes ma mon mes
tu je il elle on nous vous ils est es sont as a ai pas plus ne n ce cet cette ces qui que qu se s en y au aux par
mais donc car si lors depuis déjà bientôt encore aucun aucune tous toutes tout toute chaque entre vers chez très
voir fais fait faire peux peut veux dois il faut jamais toujours aussi ici là lieu prise poisson poissons pêche
carte cartes spot choisir ajouter relâcher garder espèce""".split())
ACCENTS = re.compile(r"[àâäçéèêëîïôöûùüÿœÀÂÇÉÈÊËÎÏÔÛÙÜŒ]")
MOT = re.compile(r"[A-Za-zÀ-ÿŒœ']+")


def ressemble_francais(texte):
    t = re.sub(r"\\\(.*?\)", " ", texte)  # texte sans interpolations
    mots = MOT.findall(t)
    if not mots:
        return False
    if ACCENTS.search(t):
        return True
    if len(mots) >= 2 and any(m.lower() in MOTS_FR for m in mots):
        return True
    if "\\(" in texte and any(m.lower() in ("sur", "de", "et", "par", "pour", "dans") for m in mots):
        return True  # « \(a) sur \(b) » : un seul mot français entre deux interpolations
    return False


def est_texte_utile(texte):
    t = re.sub(r"\\\(.*?\)", "", texte).strip()
    return bool(re.search(r"[A-Za-zÀ-ÿ]", t))


# --- Drapeaux de texte dynamique, unités, dates ----------------------------------

RE_PLURIEL = re.compile(r"""(\?\s*"(s|x|aux)"\s*:\s*"")|(==\s*1\s*\?)|(>\s*1\s*\?)|(>=\s*2\s*\?)|(<=?\s*1\s*\?)|(\?\s*""\s*:\s*"s")|pluriel|plural|\(s\)|\(x\)""")
RE_ACCORD = re.compile(r"""\?\s*"(e|es|ée|ées|ne|elle|ère|rice|euse)?"\s*:\s*"(e|es|ée|ées|ne|elle|ère|rice|euse)?"|\(e\)|\(es\)|·e\b""")
RE_SUR_N = re.compile(r"\\\(.+?\)(?: [^\\\s]+)? sur \\\(")  # « \(a) sur \(b) », « \(a) mot sur \(b) »
RE_SLASH_N = re.compile(r"\\\(.+?\)\s*/\s*\\\(")  # « \(a) / \(b) »
RE_UNITES = [
    ("cm", re.compile(r"(?<![A-Za-z])cm(?![A-Za-z])")),
    ("mm", re.compile(r"(?<![A-Za-z])mm(?![A-Za-z])")),
    ("kg", re.compile(r"(?<![A-Za-z])kg(?![A-Za-z])")),
    ("g", re.compile(r"(?<=[\d\)\s])g(?![A-Za-z])")),
    ("km", re.compile(r"(?<![A-Za-z])km(?![A-Za-z/])")),
    ("km/h", re.compile(r"km/h")),
    ("m", re.compile(r"(?<=[\d\)])\s?m(?![A-Za-z²³])")),
    ("m3/s", re.compile(r"m³/s|m3/s")),
    ("l/s", re.compile(r"(?<![A-Za-z])l/s")),
    ("°C", re.compile(r"°\s?C")),
    ("°", re.compile(r"(?<![nN])(?<![0-9]\s)°(?!\s?C)(?<!\d°)")),
    ("hPa", re.compile(r"hPa")),
    ("m/s", re.compile(r"m/s")),
    ("%", re.compile(r"%")),
]
MOIS = r"(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre|janv\.|févr\.|avr\.|juil\.|sept\.|oct\.|nov\.|déc\.)"
JOURS = r"(lundi|mardi|mercredi|jeudi|vendredi|samedi|dimanche)"
RE_DATE_TXT = re.compile(MOIS + "|" + JOURS + r"|\b1er\b|\b\d{1,2}\s?h(?:\d{2})?\b|\bhier\b|\baujourd'hui\b|\bdemain\b", re.I)

RE_EVITER = [
    ("autoris", re.compile(r"\bautoris", re.I)),
    ("legal", re.compile(r"\b(légal|légale|légaux|légales|légalement|légalité|illégal)", re.I)),
    ("permis", re.compile(r"\bpermis(e|es)?\b(?! de (pêche|peche))|\bpermission|\bpermet|\bpermettre", re.I)),
    ("droit", re.compile(r"\b(avoir le droit|as le droit|a le droit|droit de garder|droit de pêcher)", re.I)),
    ("tu_peux_garder", re.compile(r"\b(tu peux (la |le )?garder|on peut (la |le )?garder|peut être gardé)", re.I)),
]
RE_FORMATS = [
    ("DateFormatter", re.compile(r"\bDateFormatter\b")),
    ("dateFormat", re.compile(r"\bdateFormat\b|\bsetLocalizedDateFormatFromTemplate\b")),
    ("dateStyle", re.compile(r"\b(dateStyle|timeStyle)\b")),
    ("formatted(date)", re.compile(r"\.formatted\(\s*(date|\.dateTime|\.numberFormatter|\.number|\.percent)")),
    ("formatted", re.compile(r"\.formatted\(")),
    ("Locale", re.compile(r"\bLocale\(|\.locale\b|Locale\.current|Locale\.")),
    ("Calendar", re.compile(r"\bCalendar\(identifier|Calendar\.current|firstWeekday")),
    ("TimeZone", re.compile(r"\bTimeZone\b")),
    ("NumberFormatter", re.compile(r"\bNumberFormatter\b")),
    ("String(format:)", re.compile(r"String\(\s*format:")),
    ("Measurement", re.compile(r"\bMeasurement\b|\bUnit(Length|Mass|Temperature|Speed|Pressure)\b|MeasurementFormatter")),
    ("relatif", re.compile(r"RelativeDateTimeFormatter|\.relative\b")),
    ("virgule-decimale", re.compile(r'replacingOccurrences\(of:\s*"\."\s*,\s*with:\s*","')),
]
RE_ID_METRIQUE = re.compile(r"\b[a-z]\w*(Cm|Kg|Celsius|Km|Metres|Mm|Grammes|Gr)\b")


def unites(texte):
    t = re.sub(r"\\\(.*?\)", "0", texte)
    out = []
    for nom, rx in RE_UNITES:
        if nom == "%":
            continue
        if rx.search(t):
            out.append(nom)
    return out


# --- Extraction Swift ------------------------------------------------------------

def chemin_ok(rel):
    return not any(x in rel for x in EXCLUS_CHEMIN)


def fichiers(racine, extensions):
    for dossier in DOSSIERS:
        base = os.path.join(racine, dossier)
        for r, ds, fs in os.walk(base):
            ds[:] = [d for d in ds if not d.endswith((".xcassets", ".mlpackage", ".build", ".colorset", ".imageset"))]
            for f in sorted(fs):
                if f.endswith(extensions):
                    p = os.path.join(r, f)
                    rel = os.path.relpath(p, racine)
                    if chemin_ok(rel):
                        yield rel


def groupe_dossier(rel):
    p = rel.split("/")
    if p[0] == "App":
        return "App/" + p[1] if len(p) > 2 else "App"
    if p[0] == "Packages":
        return "Core/" + p[4] if len(p) > 5 else "Core"
    return p[0]


def dossier_racine(rel):
    p = rel.split("/")
    return "Core" if p[0] == "Packages" else p[0]


def drapeaux(texte, interpolations):
    d = []
    interp_txt = " ".join(interpolations)
    if RE_PLURIEL.search(texte) or RE_PLURIEL.search(interp_txt):
        d.append("pluriel")
    if RE_ACCORD.search(interp_txt) or "(e)" in texte or "·e" in texte:
        d.append("accord")
    if RE_SUR_N.search(texte):
        d.append("x_sur_n")
    if RE_SLASH_N.search(texte):
        d.append("x_slash_n")
    if any(ressemble_francais(m) for m in re.findall(r'"([^"]+)"', interp_txt)):
        d.append("fragment_fr_dans_interpolation")
    u = unites(texte)
    for x in u:
        d.append("unite:" + x)
    if RE_DATE_TXT.search(re.sub(r"\\\(.*?\)", " ", texte)):
        d.append("date_ou_heure_en_clair")
    for nom, rx in RE_EVITER:
        if rx.search(texte):
            d.append("evite:" + nom)
    return d


def extraire_swift(racine):
    lignes = []
    formats = []
    identifiants_metriques = Counter()
    compo = []
    for rel in fichiers(racine, (".swift",)):
        with open(os.path.join(racine, rel), encoding="utf-8", errors="replace") as f:
            src = f.read()
        litteraux, masque = analyser(src)
        for lit in litteraux:
            if not lit.texte.strip() or not est_texte_utile(lit.texte):
                continue
            appel, etiquette, premier = contexte(masque, lit.debut)
            type_ = None
            cible = APPELS_UI.get(appel) if appel else None
            if appel in APPELS_UI and cible:
                if etiquette is None and (premier or appel in ("Text", "navigationTitle", "accessibilityLabel", "accessibilityHint")):
                    type_ = cible
                elif etiquette in ETIQUETTES_TEXTE:
                    type_ = cible if cible not in ("Label",) or etiquette in ("title", "text") else cible
                elif etiquette is None and appel in ("Button", "Label", "Link", "Picker", "Toggle", "TextField", "Section", "alert") and ressemble_francais(lit.texte):
                    type_ = cible
            elif etiquette in ETIQUETTES_TEXTE and appel not in APPELS_BRUIT and etiquette not in ETIQUETTES_NON_TEXTE and not re.fullmatch(r"[a-z0-9_.-]+", lit.texte.strip()):
                if ressemble_francais(lit.texte) or (etiquette in ("title", "message", "description", "prompt", "placeholder", "subtitle", "legende", "texte", "libelle") and re.search(r"[A-Za-zÀ-ÿ]{3}", lit.texte) and " " not in lit.texte.strip() and lit.texte[:1].isupper()):
                    type_ = "parametre:" + etiquette
            if type_ is None:
                if appel in APPELS_BRUIT or etiquette in ETIQUETTES_NON_TEXTE:
                    continue
                if lit.brut.startswith("#"):  # regex et chaînes brutes
                    continue
                if re.search(r"\[[^\]]*[0-9a-z]-[^\]]*\]|\\\\[sdwb]", lit.texte):  # regex
                    continue
                if not ressemble_francais(lit.texte):
                    continue
                if re.fullmatch(r"[\w./:%@#-]+", lit.texte.strip()) and not ACCENTS.search(lit.texte):
                    continue
                if re.search(r"/(Validation\w*|FichierReglesMaj)\.swift$", rel):
                    type_ = "interne-dev"
                elif rel.startswith("Packages/Core/Sources/Core/Regles") or rel.startswith("Packages/Core/Sources/Core/Conseils"):
                    type_ = "phrase-moteur"
                elif dossier_racine(rel) == "Core":
                    type_ = "candidat-core"
                else:
                    type_ = "candidat-app"
            dr = drapeaux(lit.texte, lit.interpolations)
            lignes.append({
                "fichier": rel, "ligne": lit.ligne, "texte": lit.texte.replace("\n", "\\n"), "type": type_,
                "interpolations": len(lit.interpolations), "expressions": " | ".join(e.strip() for e in lit.interpolations),
                "drapeaux": ";".join(dr), "dossier": groupe_dossier(rel), "racine": dossier_racine(rel), "origine": "swift",
                "localisable": "oui" if type_ in ("String(localized:)", "intent", "widget") and appel in ("LocalizedStringResource", "localized", "IntentDescription") else "",
            })
        # Formats en dur (hors littéraux : on lit le masque).
        for no, ligne in enumerate(masque.split("\n"), 1):
            for nom, rx in RE_FORMATS:
                if rx.search(ligne):
                    if nom == "formatted" and any(f["fichier"] == rel and f["ligne"] == no and f["type"] == "formatted(date)" for f in formats):
                        continue
                    formats.append({"fichier": rel, "ligne": no, "type": nom,
                                    "code": src.split("\n")[no - 1].strip()[:140], "dossier": groupe_dossier(rel)})
        for no, ligne in enumerate(src.split("\n"), 1):
            if ligne.lstrip().startswith("//"):
                continue
            for m in RE_TERN.finditer(ligne):
                a, b = m.group(1), m.group(2)
                kind = paire_flexion(a, b)
                if kind:
                    compo.append({"fichier": rel, "ligne": no, "type": kind, "code": ligne.strip()[:140], "dossier": groupe_dossier(rel)})
        # Les formats « formatted » génériques ne comptent que s'ils portent une locale ou une date : on garde tout, on trie à l'audit.
        for m in RE_ID_METRIQUE.finditer(masque):
            identifiants_metriques[m.group(0)] += 1
    # Dates de format explicites (dateFormat = "dd/MM") : lire dans les littéraux voisins.
    return lignes, formats, identifiants_metriques, compo


RE_TERN = re.compile(r'\?\s*"([^"\\]*)"\s*:\s*"([^"\\]*)"')


def paire_flexion(a, b):
    """pluriel-ternaire : "s" : "" ou "jours" : "jour" ; accord-ternaire : "e" : "" ou "offertes" : "offerts"... ; sinon None."""
    if a == b:
        return None
    for x, y in ((a, b), (b, a)):
        if x.endswith(("s", "x")) and x[:-1] == y and re.search(r"[a-zéèê]|^$", x[:-1] or "a"):
            return "pluriel-ternaire"
        if x in ("s", "x") and y == "":
            return "pluriel-ternaire"
        if x in ("aux",) and y.endswith("al"):
            return "pluriel-ternaire"
        if x.endswith("e") and x[:-1] == y and (x[:-1] or "") != "" and y.endswith(("é", "t", "r", "n", "u", "i")):
            return "accord-ternaire"
        if x in ("e", "es", "ée", "ées", "le", "ne") and y in ("", "s", "é", "és", "u", "el"):
            return "accord-ternaire"
    return None


def formats_litteraux(racine):
    """Chaînes de format de date ou de nombre écrites en dur (dateFormat = "d MMMM", "%.1f")."""
    sorties = []
    rx_date = re.compile(r"""dateFormat\s*=\s*"([^"]+)"|setLocalizedDateFormatFromTemplate\("([^"]+)"|\.dateTime\.([^)\n]+)""")
    rx_fmt = re.compile(r"""String\(\s*format:\s*"([^"]+)""")
    for rel in fichiers(racine, (".swift",)):
        with open(os.path.join(racine, rel), encoding="utf-8", errors="replace") as f:
            for no, ligne in enumerate(f, 1):
                for m in rx_date.finditer(ligne):
                    sorties.append({"fichier": rel, "ligne": no, "type": "format-date", "code": [g for g in m.groups() if g][0]})
                for m in rx_fmt.finditer(ligne):
                    if re.search(r"%[-\d.]*[fdg]", m.group(1)):
                        sorties.append({"fichier": rel, "ligne": no, "type": "format-nombre", "code": m.group(1)})
    return sorties


# --- Extraction JSON -----------------------------------------------------------

CLES_AFFICHEES = {"phrase", "texte", "nom", "pourquoi", "utilise_pour", "attribution", "mention_licence", "note", "lecture",
                  "a_valider", "description", "resume", "libelle"}
CLES_SOURCE = {"titre", "citation"}
JSON_SANS_TEXTE = ("coins-osm.geojson", "departements.geojson", "lacs.geojson")


def parcourir_json(obj, chemin, sortie, fichier_cls):
    if isinstance(obj, dict):
        for k, v in obj.items():
            parcourir_json(v, chemin + [k], sortie, fichier_cls)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            parcourir_json(v, chemin + [i], sortie, fichier_cls)
    elif isinstance(obj, str):
        cle = next((c for c in reversed(chemin) if isinstance(c, str)), "")
        sortie.append((cle, "/".join(str(c) for c in chemin), obj))


def extraire_json(racine):
    lignes = []
    non_texte = []
    base = os.path.join(racine, "Packages/Core/Sources/Core")
    for r, ds, fs in os.walk(base):
        for f in sorted(fs):
            if not f.endswith((".json", ".geojson")):
                continue
            p = os.path.join(r, f)
            rel = os.path.relpath(p, racine)
            region_dep = "regles/" in rel or f in ("especes.json", "conseils.json", "liens-federations.json", "cas-verdicts.json",
                                                    "longueur-poids.json", "credits.json", "departements.geojson", "coins-osm.geojson")
            with open(p, encoding="utf-8") as fh:
                texte_brut = fh.read()
            try:
                data = json.loads(texte_brut)
            except ValueError:
                continue
            if f in JSON_SANS_TEXTE:
                non_texte.append({"fichier": rel, "octets": len(texte_brut.encode("utf-8")), "raison": "géométrie / noms de lieux"})
                continue
            valeurs = []
            parcourir_json(data, [], valeurs, rel)
            for cle, chemin, valeur in valeurs:
                v = valeur.strip()
                if not v or not re.search(r"[A-Za-zÀ-ÿ]", v) or v.startswith(("http://", "https://")):
                    continue
                if re.fullmatch(r"\d{4}-\d{2}-\d{2}(\.\d+)?", v):
                    continue
                if cle in CLES_AFFICHEES:
                    type_ = "json:" + cle
                elif cle in CLES_SOURCE:
                    type_ = "json-source:" + cle
                else:
                    continue
                if f == "especes.json" and cle != "nom":
                    continue
                if f == "longueur-poids.json" and cle not in ("note",):
                    continue
                if f == "liens-federations.json" and cle != "nom":
                    continue
                if f == "credits.json" and cle in ("note",):
                    type_ = "json-source:note"
                dr = drapeaux(v, [])
                lignes.append({
                    "fichier": rel, "ligne": chemin, "texte": v.replace("\n", "\\n"), "type": type_, "interpolations": 0,
                    "expressions": "", "drapeaux": ";".join(dr), "dossier": ("Core/Resources/regles" if "regles/" in rel else os.path.dirname(rel).split("Core/")[-1] and "Core/" + os.path.dirname(rel).split("Core/", 1)[-1]),
                    "racine": "Core", "origine": "json", "localisable": "region" if region_dep else "",
                })
    return lignes, non_texte


# --- Termes ---------------------------------------------------------------------

STOP = set("""le la les l un une des du de d et ou où au aux en dans sur par pour avec sans ce cet cette ces qui que qu
se s y a à ne n pas plus est sont il elle on tu te t je j m me nous vous ton ta tes mon ma mes son sa ses leur
leurs si mais donc car ni comme the of and to""".split())


def termes(lignes):
    mots = Counter()
    couples = Counter()
    for l in lignes:
        if l["type"].startswith("json-source") or l["origine"] == "json" and l["type"] in ("json:note", "json:lecture", "json:a_valider"):
            continue
        t = re.sub(r"\\\(.*?\)", " ", l["texte"])
        seq = [m.lower() for m in MOT.findall(t)]
        seq = [re.sub(r"^[ldjmtsn]'", "", m) for m in seq]
        util = [m for m in seq if m not in STOP and len(m) > 2 and not m.isdigit()]
        for m in set(util):
            mots[m] += 1
        for a, b in zip(seq, seq[1:]):
            if a not in STOP and b not in STOP and len(a) > 2 and len(b) > 2:
                couples[a + " " + b] += 1
    return mots, couples


# --- Principal --------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--racine", default=".")
    ap.add_argument("--sortie", default="reports/us/i18n")
    ap.add_argument("--stdout", action="store_true", help="n'écrit pas de fichier, imprime les statistiques")
    a = ap.parse_args()
    racine = os.path.abspath(a.racine)
    for d in DOSSIERS:
        if not os.path.isdir(os.path.join(racine, d)):
            sys.exit("Dossier absent : %s (lance depuis la racine du dépôt ou passe --racine)" % d)

    swift, formats, ident, compo = extraire_swift(racine)
    fmt_lit = formats_litteraux(racine)
    js, non_texte = extraire_json(racine)
    tout = swift + js

    stats = {}
    stats["total_textes"] = len(tout)
    stats["swift_total"] = len(swift)
    stats["json_total"] = len(js)
    stats["par_origine_type"] = dict(Counter("%s/%s" % (l["origine"], l["type"].split(":")[0] if l["origine"] == "swift" else l["type"]) for l in tout).most_common())
    stats["par_type_swift"] = dict(Counter(l["type"] for l in swift).most_common())
    stats["par_racine"] = dict(Counter(l["racine"] for l in tout))
    stats["par_racine_swift_ui"] = dict(Counter(l["racine"] for l in swift if not l["type"].startswith(("candidat", "phrase"))))
    par_dossier = defaultdict(lambda: Counter())
    for l in swift:
        par_dossier[l["dossier"]]["ui" if not l["type"].startswith(("candidat", "phrase")) else "candidat"] += 1
    stats["par_dossier_swift"] = {k: dict(v) for k, v in sorted(par_dossier.items(), key=lambda kv: -sum(kv[1].values()))}
    stats["fichiers_swift_avec_texte"] = len({l["fichier"] for l in swift})
    stats["fichiers_swift_scannes"] = sum(1 for _ in fichiers(racine, (".swift",)))
    stats["fichiers_swift_scannes_par_racine"] = dict(Counter(dossier_racine(r) for r in fichiers(racine, (".swift",))))
    stats["litteraux_localisables_deja"] = [{"fichier": l["fichier"], "ligne": l["ligne"], "texte": l["texte"]} for l in swift if l["localisable"] == "oui"]
    stats["avec_interpolation"] = sum(1 for l in tout if l["interpolations"])
    stats["avec_interpolation_ui"] = sum(1 for l in swift if l["interpolations"] and not l["type"].startswith(("candidat", "phrase")))
    cnt = Counter()
    for l in tout:
        for d in l["drapeaux"].split(";"):
            if d:
                cnt[d.split(":")[0] if d.startswith("unite:") else d] += 1
                if d.startswith("unite:"):
                    cnt[d] += 1
    stats["drapeaux"] = dict(cnt.most_common())
    stats["drapeaux_swift"] = dict(Counter(d if not d.startswith("unite:") else d for l in swift for d in l["drapeaux"].split(";") if d).most_common())
    stats["drapeaux_json"] = dict(Counter(d for l in js for d in l["drapeaux"].split(";") if d).most_common())
    stats["json_par_fichier"] = dict(Counter(("Core/Resources/regles/*.json" if "regles/" in l["fichier"] else l["fichier"]) for l in js).most_common())
    stats["json_par_chemin"] = dict(Counter(("regles/*" if "regles/" in l["fichier"] else os.path.basename(l["fichier"])) + " : " + re.sub(r"\d+", "N", l["ligne"]) + " (" + l["type"] + ")" for l in js).most_common())
    stats["json_par_type"] = dict(Counter(l["type"] for l in js).most_common())
    stats["json_regles_fichiers"] = sum(1 for r, _, fs in os.walk(os.path.join(racine, "Packages/Core/Sources/Core/Resources/regles")) for f in fs if f.endswith(".json"))
    stats["json_sans_texte"] = non_texte
    groupes = {
        "swift_ui": [l for l in swift if not l["type"].startswith(("candidat", "phrase", "interne"))],
        "swift_candidats": [l for l in swift if l["type"].startswith(("candidat", "phrase"))],
        "swift_interne_dev": [l for l in swift if l["type"].startswith("interne")],
        "json_affiche": [l for l in js if l["type"].startswith("json:")],
        "json_source": [l for l in js if l["type"].startswith("json-source")],
    }
    stats["xcode_extractibles"] = sum(1 for l in groupes["swift_ui"] if not l["type"].startswith("parametre"))
    stats["a_convertir_en_localise"] = sum(1 for l in groupes["swift_ui"] if l["type"].startswith("parametre")) + len(groupes["swift_candidats"])
    stats["accessibilite"] = sum(1 for l in swift if l["type"].startswith("accessibility"))
    stats["groupes"] = {k: len(v) for k, v in groupes.items()}
    stats["groupes_uniques"] = {k: len({l["texte"] for l in v}) for k, v in groupes.items()}
    stats["evites_par_groupe"] = {k: dict(Counter(d for l in v for d in l["drapeaux"].split(";") if d.startswith("evite:")).most_common()) for k, v in groupes.items()}
    stats["evites_lignes_par_groupe"] = {k: sum(1 for l in v if "evite:" in l["drapeaux"]) for k, v in groupes.items()}
    stats["unites_par_groupe"] = {k: dict(Counter(d for l in v for d in l["drapeaux"].split(";") if d.startswith("unite:")).most_common()) for k, v in groupes.items()}
    stats["unites_lignes_par_groupe"] = {k: sum(1 for l in v if "unite:" in l["drapeaux"]) for k, v in groupes.items()}
    stats["dates_lignes_par_groupe"] = {k: sum(1 for l in v if "date_ou_heure_en_clair" in l["drapeaux"]) for k, v in groupes.items()}
    stats["json_phrases_par_dossier_regles"] = len({l["fichier"] for l in js if l["type"] == "json:phrase"})
    stats["compositions"] = dict(Counter(c["type"] for c in compo))
    stats["compositions_fichiers"] = len({c["fichier"] for c in compo})
    stats["formats"] = dict(Counter(f["type"] for f in formats).most_common())
    stats["formats_par_dossier"] = dict(Counter(f["dossier"] for f in formats if f["type"] in ("DateFormatter", "dateFormat", "dateStyle", "formatted(date)", "Locale", "NumberFormatter", "String(format:)", "Measurement", "relatif", "virgule-decimale")).most_common())
    stats["formats_litteraux"] = dict(Counter(f["type"] for f in fmt_lit))
    stats["formats_date_distincts"] = dict(Counter(f["code"] for f in fmt_lit if f["type"] == "format-date").most_common())
    stats["formats_nombre_distincts"] = dict(Counter(f["code"] for f in fmt_lit if f["type"] == "format-nombre").most_common())
    stats["identifiants_metriques"] = dict(ident.most_common(25))
    stats["identifiants_metriques_total"] = sum(ident.values())
    stats["textes_uniques_swift_ui"] = len({l["texte"] for l in swift if not l["type"].startswith(("candidat", "phrase"))})
    stats["textes_uniques_total"] = len({l["texte"] for l in tout})

    corpus = {"ui": [l for l in swift if not l["type"].startswith("interne")],
              "regles": [l for l in js if l["type"] in ("json:phrase", "json:texte")],
              "conseils": [l for l in js if "conseils.json" in l["fichier"] and l["type"] == "json:texte"]}
    freq = {k: termes(v) for k, v in corpus.items()}

    if a.stdout:
        print(json.dumps(stats, ensure_ascii=False, indent=1))
        return
    os.makedirs(os.path.join(racine, a.sortie), exist_ok=True)
    sortie = os.path.join(racine, a.sortie)
    champs = ["fichier", "ligne", "texte", "type", "interpolations", "expressions", "drapeaux", "dossier", "racine", "origine", "localisable"]
    # Les 68 000 phrases et citations des règles françaises pèsent 15 Mo : fichier à part, ignoré par git.
    for nom, sel in (("inventaire.csv", lambda l: "regles/" not in l["fichier"]), ("inventaire-regles.csv", lambda l: "regles/" in l["fichier"])):
        with open(os.path.join(sortie, nom), "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=champs)
            w.writeheader()
            for l in tout:
                if sel(l):
                    w.writerow({c: l[c] for c in champs})
    with open(os.path.join(sortie, ".gitignore"), "w", encoding="utf-8") as f:
        f.write("inventaire-regles.csv\n")
    with open(os.path.join(sortie, "formats.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["fichier", "ligne", "type", "code", "dossier"])
        w.writeheader()
        for x in formats + compo + [dict(x, dossier=groupe_dossier(x["fichier"])) for x in fmt_lit]:
            w.writerow(x)
    with open(os.path.join(sortie, "termes.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["corpus", "terme", "type", "textes_contenant"])
        for k, (mots, couples) in freq.items():
            for t, n in mots.most_common(300):
                w.writerow([k, t, "mot", n])
            for t, n in couples.most_common(100):
                w.writerow([k, t, "couple", n])
    with open(os.path.join(sortie, "statistiques.json"), "w", encoding="utf-8") as f:
        json.dump(stats, f, ensure_ascii=False, indent=1)
    print("%d textes (%d Swift, %d JSON) ; %d formats ; écrit dans %s" % (len(tout), len(swift), len(js), len(formats) + len(fmt_lit), sortie))


if __name__ == "__main__":
    main()
