#!/usr/bin/env python3
"""Applique les fichiers outils/us/etats/verifs/<USPS>.json (lectures du 7 nov. 2026 sur les pages officielles)
à outils/us/etats/etats.json.

Règles (décision du 7 nov. n°3 : jamais de fausse donnée) :
- une valeur n'est remplacée que si la vérification en apporte une non vide ; un prix absent de la vérification
  reste tel qu'il était dans etats.json (avec sa qualité d'origine) ;
- `verifie` n'est vrai que si la vérification l'affirme ;
- chaque État garde la trace de ses sources (`sources_rapports`) et les raisons/notes de la vérification.

Usage : python3 appliquer_verifs.py [--ecrire]   (sans option : simulation, rien n'est écrit)
"""
import json
import sys
from pathlib import Path

DOSSIER = Path(__file__).resolve().parent
ETATS = DOSSIER / "etats.json"
VERIFS = DOSSIER / "verifs"


def statut(bloc):
    """Statut d'URL dans le vocabulaire de etats.json."""
    if not isinstance(bloc, dict) or not bloc.get("url"):
        return None
    code = bloc.get("statut_http")
    if code in (200, 301, 302):
        return "ok"
    if code in (401, 403, 429, 503):
        return "bloque_robots"
    note = (bloc.get("note") or "").lower()
    if code == 404 and ("robots" in note or "blocage" in note):
        return "bloque_robots"  # 404 renvoyé seulement aux robots, site vivant d'après la vérification
    if code == 404:
        return "introuvable"
    return "injoignable"


# Corrections que la vérification décrit en note mais n'a pas mises dans le champ d'URL (relues le 7 nov. 2026).
CORRECTIONS_URL = {
    "OR": {"url_agence": ("https://myodfw.com/", "ok")},  # l'ancien domaine dfw.state.or.us est injoignable ; myodfw.com répond 200
}


def prix_depuis(bloc, ancien):
    """Convertit un prix de verification vers le format de etats.json, ou rend l'ancien s'il n'y a pas de montant."""
    if not isinstance(bloc, dict):
        return ancien
    montant = bloc.get("montant_usd", bloc.get("montant"))
    if not isinstance(montant, (int, float)) or isinstance(montant, bool):
        # Valeur lue seulement dans un résumé (jamais sur la page) : on ne la promeut pas, on la garde en note.
        indiquee = bloc.get("valeur_indiquee_non_verifiee")
        if indiquee not in (None, "") and ancien is not None:
            ajout = f"valeur indiquée non vérifiée : {indiquee} (page de localisation : {bloc.get('source_localisation')})"
            if ajout not in (ancien.get("note") or ""):
                ancien = dict(ancien)
                ancien["note"] = ((ancien.get("note") + " ; ") if ancien.get("note") else "") + ajout
        return ancien
    brute = (bloc.get("qualite") or "").strip()
    if brute.lower().startswith("officiel"):
        qualite = "officiel"
    elif brute.lower().startswith("editeur") or brute.lower().startswith("éditeur"):
        qualite = "editeur"
    else:
        # « extrait_de_recherche_… » (page officielle jamais lue), « tiers » et toute valeur libre : jamais présenté comme officiel.
        qualite = "tiers"
    note = bloc.get("note")
    if qualite == "tiers" and brute and brute != "tiers":
        note = ((note + " ; ") if note else "") + f"qualité signalée par la vérification : {brute}"
    if qualite == "officiel" and brute != "officielle" and brute != "officiel":
        note = ((note + " ; ") if note else "") + f"précision de la vérification : {brute}"
    source = bloc.get("url_source") or bloc.get("source") or bloc.get("url") or (ancien or {}).get("source")
    if bloc.get("saison"):
        note = ((note + " ; ") if note else "") + f"saison : {bloc['saison']}"
    if not source or not str(source).startswith("https://"):
        return ancien  # jamais de prix sans source https
    nouveau = {
        "montant": int(montant) if float(montant).is_integer() else montant,
        "monnaie": "USD",
        "annee": bloc.get("annee") if isinstance(bloc.get("annee"), int) else 2026,
        "source": source,
        "qualite": qualite,
        "note": note,
    }
    if bloc.get("citation"):
        nouveau["citation"] = bloc["citation"]
    return nouveau


def appliquer(etat, v):
    changes = []
    for cle in ("url_agence", "url_regles_eau_douce", "url_permis"):
        bloc = v.get(cle)
        if isinstance(bloc, dict) and bloc.get("url") and bloc["url"].startswith("https://"):
            if etat.get(cle) != bloc["url"]:
                changes.append(f"{cle}: {etat.get(cle)} -> {bloc['url']}")
            etat[cle] = bloc["url"]
            s = statut(bloc)
            if s:
                etat.setdefault("urls_statut", {})[cle] = s
    for cle, (url, st) in CORRECTIONS_URL.get(etat["usps"], {}).items():
        etat[cle] = url
        etat.setdefault("urls_statut", {})[cle] = st
        changes.append(f"{cle}: corrigée vers {url}")
    for cle in ("prix_resident", "prix_non_resident"):
        avant = etat.get(cle)
        nouveau = prix_depuis(v.get(cle), avant)
        if nouveau != avant:
            changes.append(f"{cle}: {(avant or {}).get('montant')} -> {(nouveau or {}).get('montant')} ({(nouveau or {}).get('qualite')})")
        etat[cle] = nouveau
    timbres = v.get("timbres")
    if isinstance(timbres, list) and timbres:
        source_defaut = (etat.get("url_permis") or etat.get("url_agence") or "")
        convertis, non_chiffres = [], []
        for t in timbres:
            m = t.get("montant_usd", t.get("montant"))
            src = t.get("source") or t.get("url_source") or source_defaut
            if isinstance(m, (int, float)) and not isinstance(m, bool) and str(src).startswith("https://"):
                brute = (t.get("qualite") or "").strip().lower()
                convertis.append({
                    "nom": t.get("nom"), "montant": int(m) if float(m).is_integer() else m, "annee": 2026,
                    "source": src,
                    "qualite": "officiel" if brute.startswith("officiel") else ("editeur" if brute.startswith(("editeur", "éditeur")) else "tiers"),
                    "note": t.get("note"),
                })
            else:
                non_chiffres.append(f"{t.get('nom')} : {m if m is not None else 'montant non lu'}")
        if convertis:
            etat["timbres"] = convertis
            changes.append(f"timbres: {len(convertis)}")
        if non_chiffres:
            ajout = "Timbres non chiffrables en un seul montant (vérification du 7 nov. 2026) : " + " | ".join(non_chiffres)
            if ajout not in (etat.get("notes") or ""):
                etat["notes"] = ((etat.get("notes") or "") + (" " if etat.get("notes") else "") + ajout).strip()
    appli = v.get("appli_officielle")
    if isinstance(appli, dict) and ((appli.get("nom") or "[?]") != "[?]" or appli.get("url")):
        etat["appli_officielle"] = appli
    recip = v.get("reciprocite_eaux_tribales")
    if recip:
        etat["eaux_tribales_reciprocite"] = recip
    if v.get("licence_reutilisation"):
        etat["licence_reutilisation"] = v["licence_reutilisation"]
    if isinstance(v.get("verifie"), bool):
        if etat.get("verifie") != v["verifie"]:
            changes.append(f"verifie: {etat.get('verifie')} -> {v['verifie']}")
        etat["verifie"] = v["verifie"]
    etat["date_lecture"] = v.get("date_lecture") or etat.get("date_lecture")
    trace = f"outils/us/etats/verifs/{etat['usps']}.json"
    sources = etat.setdefault("sources_rapports", [])
    if trace not in sources:
        sources.append(trace)
    morceaux = [m for m in (v.get("raison"), v.get("notes")) if m]
    if morceaux:
        ajout = "Vérification du 7 nov. 2026 : " + " | ".join(morceaux)
        if ajout not in (etat.get("notes") or ""):
            etat["notes"] = ((etat.get("notes") or "") + (" " if etat.get("notes") else "") + ajout).strip()
    return changes


def main():
    ecrire = "--ecrire" in sys.argv
    donnees = json.loads(ETATS.read_text(encoding="utf-8"))
    par_code = {e["usps"]: e for e in donnees["etats"]}
    vus = 0
    for f in sorted(VERIFS.glob("*.json")):
        v = json.loads(f.read_text(encoding="utf-8"))
        code = v.get("usps") or f.stem
        if code not in par_code:
            print(f"IGNORÉ {f.name} : État inconnu")
            continue
        ch = appliquer(par_code[code], v)
        vus += 1
        print(f"{code}: {len(ch)} changement(s)" + ("" if not ch else " ; " + " ; ".join(ch)[:240]))
    print(f"{vus} fichiers de vérification lus ; vérifiés maintenant : {sum(1 for e in donnees['etats'] if e.get('verifie'))}/{len(donnees['etats'])}")
    if ecrire:
        donnees["date_lecture"] = "2026-11-07"
        ETATS.write_text(json.dumps(donnees, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print("etats.json écrit")
    else:
        print("simulation : rien d'écrit (ajouter --ecrire)")


if __name__ == "__main__":
    main()
