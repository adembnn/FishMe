#!/usr/bin/env python3
"""Hook Stop : l'agent ne s'arrête pas tant que `scripts/verif.sh --rapide` est rouge.

- Rien n'a changé dans le dépôt (par rapport à la base commune avec origin/main, plus le non commité) : on laisse passer.
- Sinon on lance `scripts/verif.sh --rapide`. Vert : on laisse passer. Rouge : on empêche l'arrêt et on renvoie
  les 40 dernières lignes de la sortie.
- Au bout de 3 refus dans la même session, on laisse s'arrêter, mais l'agent doit écrire « ROUGE » à la personne,
  et la personne voit un avertissement. Le compteur repart à zéro dès que la vérification est verte.

Format : https://code.claude.com/docs/en/hooks (Stop : champ stop_hook_active, sortie {"decision": "block", "reason": "..."}).
"""
import json
import os
import re
import subprocess
import sys
import time

RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
sys.path.insert(0, os.path.join(RACINE, "outils", "atelier"))
import lots as atelier  # noqa: E402

REFUS_MAX = 3
DUREE_MAX = 840  # secondes ; le hook a 900 s dans settings.json
ETAT = os.path.join(RACINE, ".atelier")


def fichier_etat(session):
    return os.path.join(ETAT, "preuve-" + re.sub(r"[^A-Za-z0-9_-]", "_", session or "sans-session") + ".json")


def lire_compteur(session):
    try:
        with open(fichier_etat(session), encoding="utf-8") as f:
            return int(json.load(f).get("refus", 0))
    except (OSError, ValueError, AttributeError):
        return 0


def ecrire_compteur(session, refus):
    try:
        os.makedirs(ETAT, exist_ok=True)
        if refus <= 0:
            if os.path.exists(fichier_etat(session)):
                os.remove(fichier_etat(session))
            return
        with open(fichier_etat(session), "w", encoding="utf-8") as f:
            json.dump({"refus": refus}, f)
        for nom in os.listdir(ETAT):  # ménage : les états de plus d'un jour ne servent plus
            chemin = os.path.join(ETAT, nom)
            if nom.startswith("preuve-") and time.time() - os.path.getmtime(chemin) > 86400:
                os.remove(chemin)
    except OSError:
        pass


def lancer_verif():
    """Lance scripts/verif.sh --rapide. Rend (code, 40 dernières lignes)."""
    script = os.path.join(RACINE, "scripts", "verif.sh")
    if not os.path.isfile(script):
        return 0, ""
    try:
        p = subprocess.run(["bash", script, "--rapide"], cwd=RACINE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                           timeout=DUREE_MAX)
        code, sortie = p.returncode, p.stdout.decode("utf-8", "replace")
    except subprocess.TimeoutExpired:
        code, sortie = 1, f"✗ verif.sh a dépassé {DUREE_MAX} s et a été arrêté. Lance `scripts/verif.sh --rapide` à la main."
    lignes = [l[:300] for l in sortie.splitlines()][-40:]
    return code, "\n".join(lignes)


def main():
    try:
        entree = json.load(sys.stdin)
    except ValueError:
        entree = {}
    session = entree.get("session_id") or ""
    if not atelier.fichiers_changes(RACINE):
        return 0
    code, fin = lancer_verif()
    if code == 0:
        ecrire_compteur(session, 0)
        return 0
    refus = lire_compteur(session)
    if refus >= REFUS_MAX:
        avis = (f"Atelier : `scripts/verif.sh --rapide` est encore ROUGE après {REFUS_MAX} refus. L'agent s'arrête quand même. "
                "Ne fusionne pas ce travail tant que la vérification n'est pas verte.")
        print(json.dumps({"systemMessage": avis}, ensure_ascii=False))
        return 0
    refus += 1
    ecrire_compteur(session, refus)
    consigne = (f"`scripts/verif.sh --rapide` est ROUGE (refus {refus} sur {REFUS_MAX}). Tu ne peux pas t'arrêter : "
                "corrige ce qui est marqué ✗, relance `scripts/verif.sh --rapide`, et colle sa sortie.")
    if refus == REFUS_MAX:
        consigne += (" C'est le dernier refus : si tu ne peux pas corriger, ta réponse finale doit commencer par « ROUGE : » "
                     "et dire à la personne quelle vérification échoue et pourquoi.")
    print(json.dumps({"decision": "block", "reason": f"{consigne}\n\nFin de la sortie :\n{fin}"}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
