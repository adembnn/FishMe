"""Pousse les règles confirmées (consensus/<code>.json) et leurs rapports sur la branche de données `regles/local`.

Usage : python3 -I outils/regles/pousser.py [code ...]      (sans code : tous les départements qui ont un consensus)

Règles d'Adem (15 oct., fiches/D3.md) : la branche `regles/local` n'est JAMAIS fusionnée dans `main` ; on n'y pousse que
les fichiers confirmés par les deux lectures et leurs rapports, jamais dep/, dep-b/ ni corpus/. D1 les récupère avec
`git archive origin/regles/local docs/regles-local | tar -x -C <dossier>` puis `REGLES_DIR=<dossier>/docs/regles-local`.
Les fichiers sont rangés sous docs/ parce que l'atelier ne permet que docs/ et reports/ sur une branche qui n'est pas un lot.
"""
import glob
import os
import shutil
import subprocess
import sys

ICI = os.path.dirname(os.path.abspath(__file__))
DEPOT = os.path.abspath(os.path.join(ICI, "..", ".."))
BRANCHE = "regles/local"
DOSSIER_COPIE = os.path.join(os.path.dirname(DEPOT), "repo-regles-local")


def git(*args, cwd=DEPOT, check=True):
    r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and r.returncode != 0:
        sys.exit(f"git {' '.join(args)} a échoué : {r.stderr.strip() or r.stdout.strip()}")
    return r


def preparer_copie():
    git("fetch", "origin", "--quiet", check=False)
    if os.path.isdir(os.path.join(DOSSIER_COPIE, ".git")) or os.path.exists(os.path.join(DOSSIER_COPIE, ".git")):
        git("pull", "--ff-only", "--quiet", "origin", BRANCHE, cwd=DOSSIER_COPIE, check=False)
        return
    distante = git("ls-remote", "--heads", "origin", BRANCHE).stdout.strip()
    if distante:
        git("worktree", "add", "--quiet", "-B", BRANCHE, DOSSIER_COPIE, f"origin/{BRANCHE}")
    else:
        # première fois : branche sans historique commun avec le code (données seulement)
        git("worktree", "add", "--quiet", "--detach", DOSSIER_COPIE, "HEAD")
        git("checkout", "--quiet", "--orphan", BRANCHE, cwd=DOSSIER_COPIE)
        git("rm", "-rf", "--quiet", ".", cwd=DOSSIER_COPIE, check=False)
        for reste in os.listdir(DOSSIER_COPIE):
            if reste != ".git":
                chemin = os.path.join(DOSSIER_COPIE, reste)
                shutil.rmtree(chemin) if os.path.isdir(chemin) else os.remove(chemin)


def main():
    codes = sys.argv[1:]
    consensus = sorted(glob.glob(os.path.join(ICI, "consensus", "*.json")))
    if codes:
        consensus = [c for c in consensus if os.path.basename(c)[:-5] in codes]
    if not consensus:
        sys.exit("aucun fichier consensus/<code>.json à pousser")
    preparer_copie()
    dest_c = os.path.join(DOSSIER_COPIE, "docs", "regles-local", "consensus")
    dest_r = os.path.join(DOSSIER_COPIE, "docs", "regles-local", "rapports")
    os.makedirs(dest_c, exist_ok=True)
    os.makedirs(dest_r, exist_ok=True)
    pousses = []
    for f in consensus:
        code = os.path.basename(f)[:-5]
        shutil.copy2(f, os.path.join(dest_c, f"{code}.json"))
        for rap in glob.glob(os.path.join(DEPOT, "reports", "regles-local", f"{code}-*.md")):
            shutil.copy2(rap, os.path.join(dest_r, os.path.basename(rap)))
        pousses.append(code)
    git("add", "docs/regles-local", cwd=DOSSIER_COPIE)
    if not git("status", "--porcelain", cwd=DOSSIER_COPIE).stdout.strip():
        print("rien de nouveau à pousser")
        return
    git("commit", "--quiet", "-m", f"Règles confirmées sur le PC : {', '.join(pousses)}", cwd=DOSSIER_COPIE)
    git("push", "--quiet", "origin", f"HEAD:refs/heads/{BRANCHE}", cwd=DOSSIER_COPIE)
    print(f"poussé sur {BRANCHE} : {len(pousses)} département(s) : {', '.join(pousses)}")


if __name__ == "__main__":
    main()
