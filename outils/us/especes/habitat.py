#!/usr/bin/env python3
"""Habitat des espèces américaines (eau douce ou non), d'après WoRMS (drapeaux FishBase, CC BY 4.0).

Pourquoi : des listes d'agence larges, des occurrences GBIF et surtout USGS NAS (non indigènes) contiennent des poissons
marins, d'aquarium ou de récif (ex. Hawaï, Californie, Floride). Un lac intérieur ne doit jamais les montrer.

Usage :
  python3 -I habitat.py --collecter     # interroge WoRMS (≥ 0,3 s entre requêtes), écrit habitat-worms.json
  python3 -I habitat.py --filtrer       # retire des fichiers embarqués les entrées non eau douce, écrit le rapport
  python3 -I habitat.py --filtrer --a-blanc
Règle : une entrée reste seulement si WoRMS dit isFreshwater = 1 pour l'espèce (ou, pour un hybride « A × B », pour ses
deux parents ; pour « Genre sp. », si toutes les espèces connues du genre dans les fichiers le sont). Inconnu = retiré.
"""
import argparse, glob, json, os, re, sys, time, urllib.parse, urllib.request

ICI = os.path.dirname(os.path.abspath(__file__))
RES = os.path.normpath(os.path.join(ICI, "../../../Packages/Core/Sources/Core/Resources/especes-us"))
TABLE = os.path.join(ICI, "habitat-worms.json")
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
HYBRIDE = re.compile(r"\s+[×x]\s+")


def fichiers():
    return sorted(f for f in glob.glob(os.path.join(RES, "*.json")))


def noms_latins():
    s = set()
    for f in fichiers():
        for e in json.load(open(f))["entrees"]:
            s.add(e["latin"])
    return s


def noms_simples(latin):
    """Noms d'espèces à interroger pour un nom latin (hybride : les parents ; sous-espèce : l'espèce ; genre : aucun)."""
    l = latin.strip()
    if re.search(r"\b(sp|spp)\.?(\s|$)|\bcf\.|\bor\b|,", l) and not HYBRIDE.search(l):
        return []
    if HYBRIDE.search(l):
        a, b = HYBRIDE.split(l, maxsplit=1)
        genre = a.split()[0]
        if len(b.split()) == 1:
            b = genre + " " + b
        return [" ".join(a.split()[:2]), " ".join(b.split()[:2])]
    p = l.split()
    return [" ".join(p[:2])] if len(p) >= 2 else []


def worms(noms):
    out = {}
    noms = sorted(noms)
    for i in range(0, len(noms), 40):
        lot = noms[i:i + 40]
        q = "&".join("scientificnames[]=" + urllib.parse.quote(n) for n in lot) + "&marine_only=false"
        req = urllib.request.Request("https://www.marinespecies.org/rest/AphiaRecordsByMatchNames?" + q,
                                     headers={"User-Agent": UA})
        for essai in range(3):
            try:
                rep = json.load(urllib.request.urlopen(req, timeout=60))
                break
            except Exception as ex:
                print("erreur", ex, file=sys.stderr); time.sleep(5); rep = None
        if rep is None:
            continue
        for n, recs in zip(lot, rep):
            r = next((x for x in (recs or []) if x.get("status") == "accepted"), (recs or [None])[0])
            if r:
                out[n] = {"eau_douce": r.get("isFreshwater"), "marin": r.get("isMarine"), "saumatre": r.get("isBrackish"),
                          "aphia": r.get("valid_AphiaID"), "nom_valide": r.get("valid_name")}
            else:
                out[n] = None
        time.sleep(0.5)
    return out


def collecter():
    table = json.load(open(TABLE)) if os.path.exists(TABLE) else {"especes": {}}
    voulus = set()
    for l in noms_latins():
        voulus.update(noms_simples(l))
    manquants = [n for n in voulus if n not in table["especes"]]
    print(len(voulus), "noms,", len(manquants), "à interroger")
    table["especes"].update(worms(manquants))
    table["source"] = {"nom": "WoRMS (World Register of Marine Species), drapeaux d'habitat issus de FishBase",
                       "url": "https://www.marinespecies.org/rest/", "licence": "CC-BY-4.0",
                       "date": time.strftime("%Y-%m-%d")}
    json.dump(table, open(TABLE, "w"), ensure_ascii=False, indent=1, sort_keys=True)


def eau_douce(latin, table, genres_ok=None):
    """(vrai/faux, raison)."""
    es = table["especes"]
    noms = noms_simples(latin)
    if not noms:
        genre = latin.split()[0]
        if genres_ok is not None and genres_ok.get(genre):
            return True, "genre sp. : espèces du genre toutes eau douce"
        return False, "nom de genre ou non résolu"
    for n in noms:
        r = es.get(n)
        if r is None:
            return False, "inconnu de WoRMS : " + n
        if r.get("eau_douce") != 1:
            return False, "WoRMS : %s non eau douce (eau_douce=%s, marin=%s)" % (n, r.get("eau_douce"), r.get("marin"))
    return True, "ok"


def genres_eau_douce(table, latins=None):
    par = {}
    for l in (latins if latins is not None else noms_latins()):
        n = noms_simples(l)
        if n and len(l.split()) >= 2:
            g = n[0].split()[0]
            ok, _ = eau_douce(l, table)
            par[g] = par.get(g, True) and ok
    return par


def filtrer(a_blanc):
    table = json.load(open(TABLE))
    genres = genres_eau_douce(table)
    par_etat, raisons, exemples = {}, {}, {}
    for f in fichiers():
        d = json.load(open(f))
        etat = os.path.basename(f).split("-")[0]
        garde = []
        for e in d["entrees"]:
            ok, raison = eau_douce(e["latin"], table, genres)
            if ok:
                garde.append(e)
            else:
                par_etat[etat] = par_etat.get(etat, 0) + 1
                raisons[raison] = raisons.get(raison, 0) + 1
                exemples.setdefault(etat, {}).setdefault(e["nom"] + " (" + e["latin"] + ")", 0)
                exemples[etat][e["nom"] + " (" + e["latin"] + ")"] += 1
        if len(garde) != len(d["entrees"]) and not a_blanc:
            d["entrees"] = garde
            used = {e["src"] for e in garde}
            json.dump(d, open(f, "w"), ensure_ascii=False, indent=None, separators=(",", ":"))
            open(f, "a").write("\n")
    return par_etat, exemples


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--collecter", action="store_true")
    ap.add_argument("--filtrer", action="store_true")
    ap.add_argument("--a-blanc", action="store_true")
    a = ap.parse_args()
    if a.collecter:
        collecter()
    if a.filtrer:
        par, ex = filtrer(a.a_blanc)
        print("entrées retirées par État :", dict(sorted(par.items())))
        json.dump(ex, open("/private/tmp/claude-501/retirees.json", "w"), ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
