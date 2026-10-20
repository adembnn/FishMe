#!/usr/bin/env python3
"""Hook SessionStart : dit à Claude sur quel lot il travaille.

Sur une branche de lot (lot/<nom>), il injecte la ligne du lot, sa fiche, les dossiers permis,
la commande de test et 4 règles. Ailleurs (main, autre branche), il liste les lots.
Dans le cloud (Linux sans swift), il lance scripts/cloud-pret.sh en arrière-plan, sans attendre.

Format : https://code.claude.com/docs/en/hooks (SessionStart, hookSpecificOutput.additionalContext).
"""
import json
import os
import platform
import shutil
import subprocess
import sys

sys.dont_write_bytecode = True  # pas de __pycache__ dans le dépôt
RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BASH = shutil.which("bash") or "bash"  # sous Windows, « bash » seul trouverait celui de WSL
sys.path.insert(0, os.path.join(RACINE, "outils", "atelier"))
import lots as atelier  # noqa: E402

LIMITE = 9000  # Claude Code coupe le contexte d'un hook à 10 000 caractères

REGLES = [
    "Un commit par lot terminé, avec un message en français.",
    "Ne dis jamais « fini », « ça marche » ou « testé » sans coller la sortie de `scripts/verif.sh`.",
    "Ne lis jamais un fichier `.env` : les clés restent sur l'ordinateur de la personne.",
    "La fusion vers main passe seulement par `/fusion` ou `scripts/fusionner.sh`, jamais par `git push` direct.",
]


def lancer_cloud_pret():
    """Dans le cloud, prépare Docker en arrière-plan. Ne bloque jamais le démarrage."""
    script = os.path.join(RACINE, "scripts", "cloud-pret.sh")
    if platform.system() != "Linux" or shutil.which("swift") or not os.path.isfile(script):
        return
    try:
        os.makedirs(os.path.join(RACINE, ".atelier"), exist_ok=True)
        journal = open(os.path.join(RACINE, ".atelier", "cloud-pret.log"), "ab")
        subprocess.Popen([BASH, script], cwd=RACINE, stdin=subprocess.DEVNULL, stdout=journal,
                         stderr=journal, start_new_session=True)
    except OSError:
        pass


def texte_lot(lot):
    permis = ", ".join(f"`{d}`" for d in lot["dossiers"])
    lignes = [
        f"Atelier : tu travailles sur le lot {lot['code']} « {lot['nom']} » (branche `{lot['branche']}`, tenu par {lot['qui']}).",
        f"Étapes du parcours de démo : {lot['etapes']}.",
        f"Tu peux écrire dans : {permis}, et dans les dossiers communs docs/, reports/, CLAUDE.md, README.md. Partout ailleurs, une écriture est refusée.",
        f"Test qui bloque la fusion : {lot['test']}",
        "Commande qui prouve que c'est fini : `scripts/verif.sh` (complet) ; `scripts/verif.sh --rapide` ne lance que ce qui a changé.",
        "Règles du lot :",
    ]
    lignes += [f"{i}. {r}" for i, r in enumerate(REGLES, 1)]
    fiche = os.path.join(RACINE, "docs", "fiches", f"{lot['code']}.md")
    entete = "\n".join(lignes)
    if os.path.isfile(fiche):
        with open(fiche, encoding="utf-8") as f:
            corps = f.read()
        place = LIMITE - len(entete) - 200
        if len(corps) > place:
            corps = corps[:place] + f"\n[… fiche coupée, lis le reste dans docs/fiches/{lot['code']}.md]"
        return f"{entete}\n\n--- Fiche docs/fiches/{lot['code']}.md ---\n{corps}"
    return f"{entete}\n\n(La fiche docs/fiches/{lot['code']}.md n'existe pas : demande-la à A avant de commencer.)"


def texte_sans_lot(branche, lots):
    liste = "\n".join(f"- {l['code']} {l['nom']} (branche `{l['branche']}`, tenu par {l['qui']})" for l in lots)
    nom = f"`{branche}`" if branche else "(tête détachée)"
    return (f"Atelier : tu es sur la branche {nom}, qui n'est pas un lot. Ici, seuls docs/, reports/, CLAUDE.md et README.md "
            "peuvent être écrits ; tout le reste est refusé.\n"
            f"Lots disponibles :\n{liste}\n"
            "Pour travailler : lance `scripts/lot.sh <code>` (par exemple `scripts/lot.sh L3`), puis `cd` dans le dossier "
            "qu'il affiche et relance `claude` là-bas.")


def main():
    try:
        json.load(sys.stdin)
    except (ValueError, OSError):
        pass
    lancer_cloud_pret()
    try:
        lots = atelier.charger()
        branche = atelier.branche_courante(RACINE)
        lot = atelier.lot_de_branche(branche, lots)
        texte = texte_lot(lot) if lot else texte_sans_lot(branche, lots)
    except Exception as erreur:  # un contexte manquant ne doit jamais empêcher la session de démarrer
        texte = f"Atelier : le contexte du lot n'a pas pu être lu ({erreur}). Lis docs/lots.md et docs/fiches/ à la main."
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": texte}}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
