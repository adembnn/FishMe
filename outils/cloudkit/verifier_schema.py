#!/usr/bin/env python3
"""Contrôle hors réseau : le .ckdb couvre-t-il les types et les index que le code de App/ utilise ?
Usage : python3 -I outils/cloudkit/verifier_schema.py   (depuis la racine du dépôt)
Limite : lecture par expressions régulières, pas par compilateur ; ne prouve pas que Apple accepte le fichier."""
import re, sys
from pathlib import Path

RACINE = Path(__file__).resolve().parents[2]
CKDB = Path(__file__).with_name("schema-development.ckdb")
# Types créés par l'app seule (champs chiffrés non exprimables en .ckdb) : acceptés absents, à signaler.
CHIFFRES = {"Repere", "PhotoRepere"}

def lire_schema():
    types = {}
    for m in re.finditer(r"RECORD TYPE (\w+) \((.*?)\n\);", CKDB.read_text(), re.S):
        champs = {}
        for l in m.group(2).splitlines():
            f = re.match(r'\s*"?(\w+)"?\s+([A-Z0-9<>_]+)((?:\s+(?:QUERYABLE|SORTABLE|SEARCHABLE))*)\s*,?\s*$', l)
            if f and not l.strip().startswith("GRANT"):
                champs[f.group(1)] = set(f.group(3).split())
        types[m.group(1)] = champs
    return types

def constantes(sources):
    c = {}
    for s in sources.values():
        for m in re.finditer(r'static let (type\w*|repere|photo|carte|bredouille|profil)\s*(?::\s*\w+)?\s*=\s*"(\w+)"', s):
            c[m.group(1)] = m.group(2)
    return c

def main():
    schema = lire_schema()
    sources = {p: p.read_text() for p in sorted((RACINE / "App").rglob("*.swift"))}
    const = constantes(sources)
    trous = []
    utilises = set(const.values())
    for t in sorted(utilises - CHIFFRES):
        if t not in schema: trous.append(f"type absent du .ckdb : {t}")
    for t in sorted(utilises & CHIFFRES):
        print(f"info : {t} créé par l'app (champs chiffrés), absent du .ckdb voulu")
    for p, s in sources.items():
        lignes = s.splitlines()
        nom = p.relative_to(RACINE)
        dyn = re.findall(r'champ\s*=\s*"(\w+)"', s)
        for i, l in enumerate(lignes):
            m = re.search(r"CKQuery\(recordType:\s*([^,]+),", l)
            if not m: continue
            ref = m.group(1).strip()
            if "type(de" in ref:
                types = {"MessageClub", "MessageAmi"}
            elif ref == "type":  # variable de boucle : on lit la liste « for type in [...] » juste au-dessus
                boucle = re.findall(r"for type in \[(.*?)\]", "\n".join(lignes[max(0, i - 4): i + 1]))
                noms = re.findall(r"\w+\.(\w+)", boucle[-1]) if boucle else []
                types = {const.get(n, n) for n in noms}
                if not types:  # paramètre de fonction (chat) : on contrôle les deux types de message
                    types = {"MessageClub", "MessageAmi"}
            else:
                k = re.sub(r"^\w+\.", "", ref)
                types = {const.get(k, k.strip('"'))}
            fen = "\n".join(lignes[max(0, i - 6): i + 4])
            champs = set()
            for f in re.finditer(r'NSPredicate\(format:\s*"(.*?)"', fen):
                for x in re.finditer(r"(%K|\w+)\s*(==|IN|BEGINSWITH|<|>|CONTAINS)\s", f.group(1)):
                    champs.add(("dyn" if x.group(1) == "%K" else x.group(1), "Q"))
            for f in re.finditer(r'NSSortDescriptor\(key:\s*"(\w+)"', fen):
                champs.add((f.group(1), "S"))
            for c, mode in champs:
                cibles = dyn if c == "dyn" else [{"creatorUserRecordID": "___createdBy"}.get(c, c)]
                for t in types:
                    if t not in schema:
                        trous.append(f"{nom}:{i+1} type absent : {t}"); continue
                    for cc in cibles:
                        need = "QUERYABLE" if mode == "Q" else "SORTABLE"
                        if need not in schema[t].get(cc, set()):
                            trous.append(f"{nom}:{i+1} {t}.{cc} doit être {need}")
            if "NSPredicate(value: true)" in fen:
                for t in types:
                    if "QUERYABLE" not in schema.get(t, {}).get("___recordID", set()):
                        trous.append(f"{nom}:{i+1} {t}.___recordID doit être QUERYABLE (TRUEPREDICATE)")
    # Signalement : aucune lecture publique.
    brut = CKDB.read_text()
    bloc = re.search(r"RECORD TYPE Signalement \(.*?\n\);", brut, re.S)
    if not bloc or "READ" in bloc.group(0): trous.append("Signalement ne doit avoir aucun droit READ")
    if trous:
        print(f"{len(trous)} trou(s) :"); [print(" -", t) for t in trous]; sys.exit(1)
    print(f"0 trou ({len(schema)} types dans le .ckdb, {len(utilises)} types cités dans App/)")

main()
