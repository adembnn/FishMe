#!/usr/bin/env python3
"""Contrôle de la table d'espèces américaines (schéma, doublons, latin, sources).

Usage : python3 -I verifier.py [dossier]   (code 0 = « 0 trou »)
"""
import json
import sys
from pathlib import Path

STATUTS = {"native", "introduite", "invasive"}
CHAMPS = {"slug": str, "nom_en": str, "nom_fr": str, "latin": str, "famille": str, "statut": str,
          "regions": dict, "groupe_confusion": str, "categorie": str, "type": str, "hybride": bool,
          "remarques": str, "protection_a_verifier": bool, "verifie": dict, "source": list}


def charger(dossier, nom):
    return json.loads((Path(dossier) / nom).read_text(encoding="utf-8"))


def table_francaise(dossier):
    """Slugs de la table française si le dépôt est autour du dossier, sinon None."""
    for parent in Path(dossier).resolve().parents:
        f = parent / "Packages/Core/Sources/Core/Resources/especes.json"
        if f.exists():
            return {e["id"] for e in json.loads(f.read_text(encoding="utf-8"))}
    return None


def controler(dossier):
    err = []
    es = charger(dossier, "especes-us.json")
    groupes = charger(dossier, "groupes-confusion.json")["groupes"]
    corr = charger(dossier, "correspondance-fr.json")
    slugs, latins = set(), set()
    for e in es:
        s = e.get("slug", "?")
        for k, t in CHAMPS.items():
            if k not in e:
                err.append(f"{s}: champ {k} manquant")
            elif not isinstance(e[k], t):
                err.append(f"{s}: {k} de mauvais type")
        if s in slugs:
            err.append(f"{s}: slug en double")
        slugs.add(s)
        lat = (e.get("latin") or "").strip()
        if not lat:
            err.append(f"{s}: latin vide")
        elif lat.lower() in latins:
            err.append(f"{s}: latin en double ({lat})")
        latins.add(lat.lower())
        for k in ("nom_en", "nom_fr", "famille", "categorie"):
            if not (e.get(k) or "").strip():
                err.append(f"{s}: {k} vide")
        if e.get("statut") not in STATUTS:
            err.append(f"{s}: statut inconnu")
        r = e.get("regions") or {}
        if not r.get("natif") or not r.get("introduit"):
            err.append(f"{s}: regions.natif/introduit manquant")
        v = e.get("verifie") or {}
        a_verifier = str(e.get("a_verifier", ""))
        src = e.get("source") or []
        if not src and not a_verifier.startswith("[?]"):
            err.append(f"{s}: ni source ni marque [?]")
        for x in src:
            if not str(x.get("url", "")).startswith("https://"):
                err.append(f"{s}: source sans URL https")
        if not (v.get("latin") and v.get("statut")) and not a_verifier.startswith("[?]"):
            err.append(f"{s}: non vérifié mais sans [?]")
        if v.get("latin") and not src:
            err.append(f"{s}: latin vérifié sans source")
    ids = {g["id"] for g in groupes}
    for g in groupes:
        for x in g["especes"]:
            if x not in slugs:
                err.append(f"groupe {g['id']}: espèce inconnue {x}")
    for e in es:
        g = e.get("groupe_confusion")
        if g == "aucun":
            continue
        if g not in ids:
            err.append(f"{e['slug']}: groupe {g} absent de groupes-confusion.json")
        elif e["slug"] not in next(x for x in groupes if x["id"] == g)["especes"]:
            err.append(f"{e['slug']}: absent de son groupe {g}")
    fr = table_francaise(dossier)
    for cle in ("identiques", "proches", "pieges_de_nom"):
        for r in corr[cle]:
            if r["slug_us"] not in slugs:
                err.append(f"correspondance: slug US inconnu {r['slug_us']}")
            if fr is not None and r["slug_fr"] not in fr:
                err.append(f"correspondance: slug FR inconnu {r['slug_fr']}")
    for s in corr["sans_equivalent"]:
        if s not in slugs:
            err.append(f"correspondance: slug US inconnu {s}")
    return err, es


def main(dossier):
    err, es = controler(dossier)
    ok = sum(1 for e in es if e["verifie"]["latin"] and e["verifie"]["statut"])
    print(f"{len(es)} espèces, {ok} vérifiées (latin + statut), {len(es) - ok} [?]")
    for m in err:
        print("TROU:", m)
    print(f"{len(err)} trou" if err else "0 trou")
    return 1 if err else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).parent)))
