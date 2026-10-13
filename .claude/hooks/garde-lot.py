#!/usr/bin/env python3
"""Hook PreToolUse (Edit, Write, MultiEdit, NotebookEdit) : refuse d'écrire hors des dossiers du lot.

Règles (toutes lues dans docs/lots.md par outils/atelier/lots.py) :
- chemin hors du dépôt : permis ;
- dossiers communs (docs/, reports/, CLAUDE.md, README.md) : permis ;
- dossiers du lot de la branche courante : permis ; branche qui n'est pas un lot : seuls les communs ;
- `.env*` et `*.pbxproj` : toujours refusés (même avec ATELIER_LIBRE=1) ;
- ATELIER_LIBRE=1 lève le contrôle de dossier, et le dit à chaque écriture.

Format : https://code.claude.com/docs/en/hooks (PreToolUse : entrée tool_input.file_path, sortie code 2 + stderr = refus).
"""
import json
import os
import sys

sys.dont_write_bytecode = True  # pas de __pycache__ dans le dépôt
RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(RACINE, "outils", "atelier"))
import lots as atelier  # noqa: E402


def refuser(message):
    print(message, file=sys.stderr)
    return 2


def chemin_demande(entree):
    ti = entree.get("tool_input") or {}
    # Edit, Write et MultiEdit donnent file_path ; NotebookEdit donne notebook_path (champ non listé dans la doc, géré par prudence).
    return ti.get("file_path") or ti.get("notebook_path") or ti.get("path") or ""


def main():
    try:
        entree = json.load(sys.stdin)
    except ValueError:
        return 0  # entrée illisible : on ne bloque pas le travail à cause du garde-fou
    brut = chemin_demande(entree)
    if not brut:
        return 0
    base = entree.get("cwd") or RACINE
    absolu = brut if os.path.isabs(brut) else os.path.join(base, brut)
    nom = os.path.basename(absolu)

    # Interdits absolus, où que soit le fichier.
    if atelier.est_secret(absolu):
        return refuser(f"Refusé : `{nom}` est un fichier de secrets (clés). Un agent ne l'écrit pas et ne le lit pas, même avec ATELIER_LIBRE=1.\n"
                       "À faire : laisse la personne créer et remplir le `.env` elle-même (`code .env` ou `open -e .env`), puis continue sans lire son contenu.")
    if atelier.est_projet_xcode(absolu):
        return refuser(f"Refusé : `{nom}` (réglages du projet Xcode) ne se modifie jamais par un agent, même avec ATELIER_LIBRE=1.\n"
                       "À faire : A règle les cibles, capacités et clés Info dans Xcode. Décris le réglage voulu dans reports/ et demande-le à A.")

    try:
        relatif = atelier.relatif(absolu, RACINE)
        if relatif is None:
            return 0  # hors du dépôt : permis
        lots = atelier.charger()
        branche = atelier.branche_courante(RACINE)
        lot = atelier.lot_de_branche(branche, lots)
        proprio = atelier.proprietaire(relatif, lots)
        permis = proprio == "commun" or (lot is not None and proprio == lot["code"])
    except Exception as erreur:  # le garde-fou est en panne : on le dit, on ne bloque pas
        print(json.dumps({"systemMessage": f"Atelier : le garde-fou de dossier est en panne ({erreur}). L'écriture est permise ; préviens A."}, ensure_ascii=False))
        return 0

    if os.environ.get("ATELIER_LIBRE") == "1":
        quoi = "aurait été refusée" if not permis else "est dans le lot"
        avis = f"ATELIER_LIBRE=1 : le contrôle de dossier est levé. Écriture de `{relatif}` ({quoi})."
        print(json.dumps({"systemMessage": avis,
                          "hookSpecificOutput": {"hookEventName": "PreToolUse",
                                                 "additionalContext": avis + " Dis-le à la personne : ce mode est réservé aux urgences."}},
                         ensure_ascii=False))
        return 0
    if permis:
        return 0
    return refuser(atelier.message_hors_lot(relatif, proprio, branche, lots)
                   + "\nUrgence seulement : relancer `claude` avec ATELIER_LIBRE=1 lève ce contrôle (chaque écriture est signalée).")


if __name__ == "__main__":
    sys.exit(main())
