#!/usr/bin/env python3
"""Essai de l'atelier : prouve que chaque garde-fou bloque son erreur, et que chaque cas permis passe.

Il ne touche pas au dépôt courant. Il fabrique dans un dossier temporaire :
  - un faux dépôt distant (git init --bare) ;
  - un clone de l'état courant du dépôt (fichiers non commités compris) ;
  - de fausses commandes (swift, docker, gh, xcodebuild…) qui répondent vert ou rouge sur commande.
Puis il appelle les hooks de Claude Code comme Claude Code le fait (la commande lue dans .claude/settings.json,
lancée par sh -c, avec le JSON sur l'entrée standard), et les crochets de git pour de vrai.

Bibliothèque standard seulement. Aucun appel à un modèle d'IA. Moins de 2 minutes sous Linux.
Usage : python3 outils/atelier/essai.py [--detail]   (--detail : une ligne par vérification ; ESSAI_GARDER=1 garde le dossier temporaire)
Sortie : « atelier : N/N vérifications passent » et code 0 ; sinon la liste des échecs et code 1.
"""
import json
import os
import platform
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from types import SimpleNamespace

sys.dont_write_bytecode = True  # pas de __pycache__ dans le dépôt
RACINE = Path(__file__).resolve().parents[2]
# Sous Windows, « bash » seul trouverait celui de WSL (System32) : on prend celui du PATH (Git Bash).
BASH = shutil.which("bash") or "bash"
sys.path.insert(0, str(RACINE / "outils" / "atelier"))
import lots as atelier  # noqa: E402

# ---------------------------------------------------------------------------
# Bilan
# ---------------------------------------------------------------------------


class Bilan:
    """Compte les vérifications par section. Les échecs s'impriment tout de suite, avec leur détail.
    Par défaut, les réussites sont résumées par section ; avec --detail (ou ESSAI_DETAIL=1), chacune a sa ligne."""

    def __init__(self, detail=False):
        self.detail = detail
        self.total = 0
        self.echecs = []
        self.sections = []  # [nom, réussies, total]

    def section(self, nom):
        self.sections.append([nom, 0, 0])
        if self.detail:
            print(f"\n== {nom}")

    def verifier(self, nom, condition, detail=""):
        self.total += 1
        if not self.sections:
            self.section("général")
        self.sections[-1][2] += 1
        if condition:
            self.sections[-1][1] += 1
            if self.detail:
                print(f"✓ {nom}")
        else:
            self.echecs.append(nom)
            print(f"✗ {nom}")
            if detail:
                print("    " + str(detail).strip()[-900:].replace("\n", "\n    "))
        return bool(condition)

    def saute(self, nom, raison):
        print(f"· sauté : {nom} ({raison})")

    def resume(self):
        for nom, bons, total in self.sections:
            if total:
                print(f"{'✓' if bons == total else '✗'} {nom} : {bons}/{total}")


bilan = Bilan(detail="--detail" in sys.argv[1:] or os.environ.get("ESSAI_DETAIL") == "1")

# ---------------------------------------------------------------------------
# Fausses commandes
# ---------------------------------------------------------------------------

FAUX = {}
FAUX["swift"] = r'''#!/usr/bin/env bash
etat="$ESSAI_ETAT"
echo "swift $*" >> "$etat/appels"
case "$1" in
  format) exit 0 ;;
  test)
    if [ -f "$etat/avant-test.sh" ]; then bash "$etat/avant-test.sh"; rm -f "$etat/avant-test.sh"; fi
    if [ "$(cat "$etat/swift-resultat" 2>/dev/null)" = rouge ]; then
      for i in $(seq 1 60); do echo "[$i/60] compilation du test $i"; done
      echo "Test failed : testVerdict() à la ligne 12"; echo "✘ Test run with 1 test failed"; exit 1
    fi
    echo "✔ Test run with 3 tests passed after 0.001 seconds."; exit 0 ;;
esac
exit 0
'''
FAUX["docker"] = r'''#!/usr/bin/env bash
etat="$ESSAI_ETAT"
case "$1" in
  info) [ -f "$etat/docker-up" ]; exit $? ;;
  image) [ -f "$etat/image" ]; exit $? ;;
  pull) echo "docker $*" >> "$etat/appels"; touch "$etat/image"; echo "pulled"; exit 0 ;;
  run)
    echo "docker $*" >> "$etat/appels"
    if [ "$(cat "$etat/swift-resultat" 2>/dev/null)" = rouge ]; then echo "✘ Test run with 1 test failed"; exit 1; fi
    echo "✔ Test run with 3 tests passed after 0.001 seconds."; exit 0 ;;
esac
exit 0
'''
FAUX["dockerd"] = r'''#!/usr/bin/env bash
echo "dockerd" >> "$ESSAI_ETAT/appels"
sleep 1
touch "$ESSAI_ETAT/docker-up"
'''
FAUX["sudo"] = '#!/usr/bin/env bash\nexec "$@"\n'
FAUX["xcodebuild"] = r'''#!/usr/bin/env bash
etat="$ESSAI_ETAT"
echo "xcodebuild $*" >> "$etat/appels"
case "$1" in
  -list) echo '{"project":{"name":"Projet","schemes":["Pesche"],"targets":["Pesche"]}}'; exit 0 ;;
  test)
    if [ "$(cat "$etat/xcode-resultat" 2>/dev/null)" = rouge ]; then echo "Testing failed: testCarte()"; exit 65; fi
    echo "** TEST SUCCEEDED **"; exit 0 ;;
esac
exit 0
'''
FAUX["xcrun"] = r'''#!/usr/bin/env bash
if [ "$1" = simctl ] && [ "$2" = list ]; then
  echo "== Devices =="; echo "-- iOS 27.0 --"
  echo "    iPhone 17 Pro (11111111-2222-3333-4444-555555555555) (Shutdown)"
fi
exit 0
'''
FAUX["gh"] = r'''#!/usr/bin/env bash
etat="$ESSAI_ETAT"
echo "gh $*" >> "$etat/appels"
mode=$(cat "$etat/gh-mode" 2>/dev/null)
if [ "$1" = release ] && [ "$2" = view ]; then
  if [ "$mode" = ok ]; then echo "donnees"; exit 0; fi
  echo "release not found" >&2; exit 1
fi
if [ "$1" = release ] && [ "$2" = download ]; then
  dir=.
  while [ $# -gt 0 ]; do [ "$1" = --dir ] && dir="$2"; shift; done
  mkdir -p "$dir"; echo '[]' > "$dir/stations-especes.json"; echo '{}' > "$dir/rarete-departements.json"; exit 0
fi
exit 0
'''


def ecrire_executable(chemin, texte):
    chemin.write_text(texte, encoding="utf-8")
    chemin.chmod(chemin.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


# ---------------------------------------------------------------------------
# Outils d'appel
# ---------------------------------------------------------------------------


DELAI = int(os.environ.get("ESSAI_DELAI", "1"))  # multiplicateur des délais : 8 sous Windows (14 000 fichiers copiés et ajoutés)


def lancer(cmd, cwd, env, entree=None, timeout=90):
    timeout = timeout * DELAI
    cmd = [BASH] + list(cmd[1:]) if cmd and cmd[0] == "bash" else cmd
    try:
        return subprocess.run(cmd, cwd=str(cwd), env=env, input=entree, text=True, capture_output=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        return SimpleNamespace(returncode=124, stdout=(e.stdout or ""), stderr="délai dépassé : " + str(cmd))


def sortie(p):
    return (p.stdout or "") + (p.stderr or "")


def git(args, cwd, env, **kw):
    return lancer(["git"] + [str(a) for a in args], cwd, env, **kw)


def matche(matcher, nom):
    """Même règle que Claude Code : liste exacte si seulement lettres, chiffres, _ - espace , | ; sinon expression régulière."""
    if not matcher or matcher == "*":
        return True
    if re.fullmatch(r"[A-Za-z0-9_\- ,|]+", matcher):
        return nom in [m.strip() for m in re.split(r"[|,]", matcher)]
    return re.search(matcher, nom) is not None


def commandes_declarees(dossier, evenement, cible=""):
    settings = json.loads((Path(dossier) / ".claude" / "settings.json").read_text(encoding="utf-8"))
    commandes = []
    for groupe in settings.get("hooks", {}).get(evenement, []):
        if matche(groupe.get("matcher"), cible):
            commandes += [h["command"] for h in groupe.get("hooks", []) if h.get("type") == "command"]
    return commandes


def appeler(dossier, evenement, entree, cible, env, timeout=120):
    """Appelle le hook comme Claude Code : commande lue dans settings.json, sh -c, JSON sur l'entrée standard."""
    commandes = commandes_declarees(dossier, evenement, cible)
    if not commandes:
        return SimpleNamespace(returncode=-1, stdout="", stderr=f"aucun hook déclaré pour {evenement} / {cible}")
    e = dict(env, CLAUDE_PROJECT_DIR=str(dossier))
    base = {"session_id": "essai", "transcript_path": "", "cwd": str(dossier), "permission_mode": "default",
            "hook_event_name": evenement}
    base.update(entree)
    return lancer(["/bin/sh", "-c", commandes[0]], dossier, e, json.dumps(base), timeout)


def ecriture(dossier, chemin, env, outil="Write", champ="file_path", **extra):
    entree = {"tool_name": outil, "tool_input": {champ: str(chemin), "content": "x"}}
    return appeler(dossier, "PreToolUse", entree, outil, dict(env, **extra))


def json_ou_none(texte):
    try:
        return json.loads(texte)
    except ValueError:
        return None


def ecrire(dossier, chemin, texte="import Foundation\n"):
    f = Path(dossier) / chemin
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(texte, encoding="utf-8")
    return f


# ---------------------------------------------------------------------------
# 1. Vérifications sur les fichiers eux-mêmes
# ---------------------------------------------------------------------------


def verifications_statiques():
    bilan.section("fichiers : syntaxe, JSON, réglages, permissions, workflow")
    scripts = sorted(RACINE.glob("scripts/*.sh")) + sorted(p for p in (RACINE / ".githooks").glob("*") if p.is_file()) \
        + sorted((RACINE / ".claude" / "hooks").glob("*.sh"))
    for s in scripts:
        p = subprocess.run([BASH, "-n", str(s)], capture_output=True, text=True)
        bilan.verifier(f"syntaxe bash : {s.relative_to(RACINE)}", p.returncode == 0, p.stderr)
    for s in sorted((RACINE / ".claude" / "hooks").glob("*.py")) + sorted((RACINE / "outils" / "atelier").glob("*.py")):
        try:
            compile(s.read_text(encoding="utf-8"), str(s), "exec")
            bilan.verifier(f"syntaxe python : {s.relative_to(RACINE)}", True)
        except SyntaxError as e:
            bilan.verifier(f"syntaxe python : {s.relative_to(RACINE)}", False, e)

    for nom in (".claude/settings.json", ".mcp.json"):
        f = RACINE / nom
        if f.exists():
            try:
                json.loads(f.read_text(encoding="utf-8"))
                bilan.verifier(f"JSON valide : {nom}", True)
            except ValueError as e:
                bilan.verifier(f"JSON valide : {nom}", False, e)
        elif nom == ".claude/settings.json":
            bilan.verifier(f"JSON valide : {nom}", False, "fichier absent")

    settings = json.loads((RACINE / ".claude" / "settings.json").read_text(encoding="utf-8"))
    hooks = settings.get("hooks", {})
    attendus = {"SessionStart": "contexte.py", "PreToolUse": "garde-lot.py", "PostToolUse": "formate.sh", "Stop": "preuve.py"}
    for evenement, script in attendus.items():
        cmds = [h.get("command", "") for g in hooks.get(evenement, []) for h in g.get("hooks", [])]
        ok = any(script in c and "$CLAUDE_PROJECT_DIR" in c for c in cmds) and (RACINE / ".claude" / "hooks" / script).is_file()
        bilan.verifier(f"settings.json : {evenement} lance {script} avec $CLAUDE_PROJECT_DIR", ok, cmds)
    bilan.verifier("settings.json : le garde de dossier couvre Edit, Write, MultiEdit et NotebookEdit",
                   all(commandes_declarees(RACINE, "PreToolUse", t) for t in ("Edit", "Write", "MultiEdit", "NotebookEdit"))
                   and not commandes_declarees(RACINE, "PreToolUse", "Read"))
    bilan.verifier("settings.json : le démarrage de session couvre startup, resume, clear et compact",
                   all(commandes_declarees(RACINE, "SessionStart", s) for s in ("startup", "resume", "clear", "compact")))
    stop = [h for g in hooks.get("Stop", []) for h in g.get("hooks", [])]
    bilan.verifier("settings.json : le contrôle de fin de tour a un délai assez long pour Swift sous Docker (au moins 600 s)",
                   bool(stop) and all(h.get("timeout", 0) >= 600 for h in stop))

    perm = settings.get("permissions", {})
    deny, allow = "\n".join(perm.get("deny", [])), "\n".join(perm.get("allow", []))
    for motif in ("Read(.env", "Bash(cat .env", "Bash(grep", "Bash(less", "Bash(head", "git push --force", "Bash(git push origin main", "Bash(git commit --no-verify"):
        bilan.verifier(f"permissions : refus de « {motif} »", motif in deny)
    for motif in ("Bash(scripts/*)", "Bash(python3 outils/atelier/*)", "git status", "git diff", "git log", "git add", "git commit",
                  "git fetch", "git merge", "git worktree", "swift test", "swift build", "xcodebuild", "xcrun simctl", "docker run"):
        bilan.verifier(f"permissions : autorisé sans question « {motif} »", motif in allow)

    # Aucun dossier de lot écrit en dur : tout se lit dans docs/lots.md.
    textes = ""
    for s in scripts + sorted((RACINE / ".claude" / "hooks").glob("*.py")) + [RACINE / ".claude" / "settings.json"]:
        textes += s.read_text(encoding="utf-8") + "\n"
    dossiers = [d for lot in atelier.charger() if lot["code"] not in atelier.LOTS_ATELIER for d in lot["dossiers"] if d.endswith("/")]
    en_dur = [d for d in dossiers if d in textes]
    bilan.verifier("aucun dossier de lot écrit en dur dans les scripts et les hooks (tout vient de docs/lots.md)", not en_dur, en_dur)

    # Lots du backlog (fiches N1 à N6 du 19 oct., D2 bis) : lus dans la vraie table du dépôt, pas dans celle de l'essai.
    reels = atelier.charger()
    bilan.verifier("docs/lots.md : branches et dossiers disjoints, tout lot du backlog compris", not atelier.verifier(reels), atelier.verifier(reels))
    for code, branche, chemin in (("N1", "lot/skins-aquarium", "App/Aquarium/Skins/Galerie.swift"),
                                  ("N2", "lot/envies", "App/Envies/EnviesView.swift"),
                                  ("N3", "lot/mesures", "Packages/Core/Sources/Core/Conditions/Mesures.swift"),
                                  ("N4", "lot/records", "App/Records/RecordsView.swift"),
                                  ("N5", "lot/ma-federation", "App/CartePeche/CarteView.swift"),
                                  ("N6", "lot/reperes", "Packages/Core/Sources/Core/Reperes/Repere.swift"),
                                  ("D2B", "lot/hubeau-temperature", "outils/hubeau-temperature/collecter.py")):
        lot = next((l for l in reels if l["code"] == code), None)
        bilan.verifier(f"docs/lots.md : le lot {code} est au tableau, sur {branche}, et possède {chemin}",
                       lot is not None and lot["branche"] == branche and atelier.proprietaire(chemin, reels) == code,
                       str(lot and (lot["branche"], atelier.proprietaire(chemin, reels))))
        bilan.verifier(f"docs/lots.md : la branche {branche} se lit comme le lot {code}", (atelier.lot_de_branche(branche, reels) or {}).get("code") == code)

    wf = RACINE / ".github" / "workflows" / "verif.yml"
    t = wf.read_text(encoding="utf-8") if wf.exists() else ""
    bilan.verifier("workflow GitHub : sur push et pull_request, conteneur swift:6.4, lance scripts/verif.sh",
                   "push:" in t and "pull_request:" in t and "swift:6.4" in t and "scripts/verif.sh" in t and "ubuntu-latest" in t)
    bilan.verifier("workflow GitHub : aucun appel à un modèle d'IA", not re.search(r"anthropic|claude|openai", t, re.I))
    try:
        import yaml  # facultatif
        yaml.safe_load(t)
        bilan.verifier("workflow GitHub : YAML valide", True)
    except ImportError:
        pass
    except Exception as e:  # noqa: BLE001
        bilan.verifier("workflow GitHub : YAML valide", False, e)

    verifier_claude = RACINE / "outils" / "atelier" / "verifier_claude.py"
    if verifier_claude.exists():
        p = subprocess.run([sys.executable, str(verifier_claude)], cwd=str(RACINE), capture_output=True, text=True)
        bilan.verifier("verifier_claude.py (relecteurs, skills) sort 0", p.returncode == 0, sortie(p))
    else:
        bilan.saute("verifier_claude.py", "absent de cette branche")


# ---------------------------------------------------------------------------
# 2. Le monde d'essai : faux distant, clone, fausses commandes
# ---------------------------------------------------------------------------


def construire_monde(tmp):
    etat = tmp / "etat"
    etat.mkdir()
    faux, faux_swift = tmp / "bin-faux", tmp / "bin-swift"
    faux.mkdir()
    faux_swift.mkdir()
    for nom, texte in FAUX.items():
        ecrire_executable((faux_swift if nom == "swift" else faux) / nom, texte)
    (tmp / "home").mkdir()

    env = {k: v for k, v in os.environ.items()
           if not k.startswith("ATELIER_") and k not in ("CLAUDE_PROJECT_DIR", "CI", "GITHUB_ACTIONS", "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")}
    env.update(HOME=str(tmp / "home"), GIT_CONFIG_GLOBAL=os.devnull, GIT_CONFIG_NOSYSTEM="1", GIT_TERMINAL_PROMPT="0",
               GIT_AUTHOR_NAME="Essai", GIT_AUTHOR_EMAIL="essai@atelier.invalid",
               GIT_COMMITTER_NAME="Essai", GIT_COMMITTER_EMAIL="essai@atelier.invalid",
               ATELIER_ESSAI="1", ESSAI_ETAT=str(etat), LC_ALL="C.UTF-8")
    chemin = env.get("PATH", "")
    swift_reel = shutil.which("swift") is not None
    env_sans = dict(env, PATH=f"{faux}{os.pathsep}{chemin}")
    env_avec = dict(env, PATH=f"{faux_swift}{os.pathsep}{faux}{os.pathsep}{chemin}")

    origin, app = tmp / "origin.git", tmp / "app"
    git(["init", "-q", "--bare", "-b", "main", origin], tmp, env)
    app.mkdir()
    git(["init", "-q", "-b", "main"], app, env)
    code = subprocess.run(["git", "-C", str(RACINE), "ls-files", "-co", "--exclude-standard", "-z"], capture_output=True)
    fichiers = [f for f in code.stdout.decode("utf-8").split("\0") if f] if code.returncode == 0 else []
    if not fichiers:
        ignores = {".git", ".atelier", "__pycache__", ".build"}
        fichiers = [str(p.relative_to(RACINE)) for p in RACINE.rglob("*") if p.is_file() and not ignores & set(p.parts)]
    for f in fichiers:
        src = RACINE / f
        if src.is_file():
            (app / f).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, app / f)
    # L'essai joue sur sa propre table de lots (celle du 15-16 oct.), jamais sur celle du dépôt : H1, 19 oct.
    shutil.copy2(RACINE / "outils" / "atelier" / "essai-lots.md", app / "docs" / "lots.md")
    git(["add", "-A"], app, env)
    git(["commit", "-q", "-m", "base de l'essai"], app, env)
    git(["remote", "add", "origin", origin], app, env)
    git(["push", "-q", "origin", "main"], app, env)
    git(["fetch", "-q", "origin"], app, env)
    tiers = tmp / "tiers"
    git(["clone", "-q", origin, tiers], tmp, env)
    return SimpleNamespace(tmp=tmp, etat=etat, env=env, env_sans=env_sans, env_avec=env_avec, swift_reel=swift_reel,
                           origin=origin, app=app, tiers=tiers)


def etat_de(m, nom, valeur):
    (m.etat / nom).write_text(valeur, encoding="utf-8")


def appels(m):
    f = m.etat / "appels"
    return f.read_text(encoding="utf-8") if f.exists() else ""


def vider_appels(m):
    (m.etat / "appels").write_text("", encoding="utf-8")


def sha_distant(m, ref="main"):
    p = git(["ls-remote", m.origin, f"refs/heads/{ref}"], m.tmp, m.env)
    return (p.stdout.split() or [""])[0]


def pousser_tiers(m, fichier, texte):
    """Une autre personne fusionne dans main : commit poussé depuis le clone « tiers »."""
    git(["pull", "-q", "origin", "main"], m.tiers, m.env)
    f = m.tiers / fichier
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text(texte, encoding="utf-8")
    git(["add", "-A"], m.tiers, m.env)
    git(["commit", "-q", "--no-verify", "-m", f"tiers : {fichier}"], m.tiers, m.env)
    return git(["push", "-q", "origin", "HEAD:main"], m.tiers, m.env)


# ---------------------------------------------------------------------------
# 3. lot.sh
# ---------------------------------------------------------------------------


def essai_lot_sh(m):
    bilan.section("scripts/lot.sh")
    app = m.app
    p = lancer(["bash", "scripts/lot.sh", "l3"], app, m.env)
    m.l3 = app.parent / "app-l3"
    bilan.verifier("lot.sh L3 : crée ../app-l3 sur la branche lot/prise", p.returncode == 0 and m.l3.is_dir()
                   and git(["symbolic-ref", "--short", "HEAD"], m.l3, m.env).stdout.strip() == "lot/prise", sortie(p))
    bilan.verifier("lot.sh : affiche les 2 commandes suivantes (cd puis claude)", f'cd "{m.l3}"' in p.stdout and "claude" in p.stdout, p.stdout)
    bilan.verifier("lot.sh : branche les crochets de git (core.hooksPath = .githooks)",
                   git(["config", "core.hooksPath"], m.l3, m.env).stdout.strip() == ".githooks")
    bilan.verifier("lot.sh : la branche part de origin/main",
                   git(["rev-parse", "HEAD"], m.l3, m.env).stdout == git(["rev-parse", "origin/main"], app, m.env).stdout)
    p2 = lancer(["bash", "scripts/lot.sh", "L3"], app, m.env)
    bilan.verifier("lot.sh : relancé, il dit que le lot est déjà prêt (sans erreur)", p2.returncode == 0 and "déjà prêt" in p2.stdout, sortie(p2))
    p3 = lancer(["bash", "scripts/lot.sh", "ZZ"], app, m.env)
    bilan.verifier("lot.sh : un code inconnu est refusé avec la liste des lots", p3.returncode != 0 and "L3" in sortie(p3), sortie(p3))
    # branche déjà existante : réutilisée
    lancer(["bash", "scripts/lot.sh", "L7"], app, m.env)
    l7 = app.parent / "app-l7"
    git(["worktree", "remove", "--force", l7], app, m.env)
    p4 = lancer(["bash", "scripts/lot.sh", "L7"], app, m.env)
    bilan.verifier("lot.sh : réutilise la branche si elle existe déjà", p4.returncode == 0 and l7.is_dir(), sortie(p4))
    git(["worktree", "remove", "--force", l7], app, m.env)
    for code, attr in (("C0", "c0"), ("D1", "d1"), ("S1", "s1")):
        p = lancer(["bash", "scripts/lot.sh", code], app, m.env)
        setattr(m, attr, app.parent / f"app-{attr}")
        if p.returncode != 0:
            bilan.verifier(f"lot.sh {code}", False, sortie(p))


# ---------------------------------------------------------------------------
# 4. Hooks de Claude Code
# ---------------------------------------------------------------------------


def essai_garde(m):
    bilan.section("hook PreToolUse : garde de dossier")
    l3, app, env = m.l3, m.app, m.env
    r = ecriture(l3, l3 / "App/Prise/Vue.swift", env)
    bilan.verifier("garde : écrire dans son dossier (App/Prise/) est permis", r.returncode == 0, sortie(r))
    r = ecriture(l3, l3 / "AppTests/Prise/VueTests.swift", env)
    bilan.verifier("garde : écrire dans les tests de son dossier (AppTests/Prise/) est permis", r.returncode == 0, sortie(r))
    r = ecriture(l3, l3 / "App/Carte/Vue.swift", env)
    bilan.verifier("garde : écrire dans le dossier d'un autre lot est refusé (code 2)", r.returncode == 2, sortie(r))
    bilan.verifier("garde : le refus nomme le lot propriétaire (L2), sa fiche, et dit quoi faire",
                   "L2" in r.stderr and "docs/fiches/L2.md" in r.stderr and "À faire" in r.stderr, r.stderr)
    r = ecriture(l3, l3 / "App/Prise/../Carte/Vue.swift", env)
    bilan.verifier("garde : un détour par « .. » ne contourne pas la frontière", r.returncode == 2, sortie(r))
    r = ecriture(l3, "App/Carte/Vue.swift", env, outil="Edit")
    bilan.verifier("garde : un chemin relatif hors du lot est refusé (Edit)", r.returncode == 2, sortie(r))
    r = ecriture(l3, l3 / "App/Carte/Vue.swift", env, outil="MultiEdit")
    bilan.verifier("garde : MultiEdit est contrôlé aussi", r.returncode == 2, sortie(r))
    r = ecriture(l3, l3 / "App/Carte/Cahier.ipynb", env, outil="NotebookEdit", champ="notebook_path")
    bilan.verifier("garde : NotebookEdit (champ notebook_path) est contrôlé aussi", r.returncode == 2, sortie(r))
    for commun in ("docs/note.md", "reports/note.md", "CLAUDE.md", "README.md"):
        r = ecriture(l3, l3 / commun, env)
        bilan.verifier(f"garde : écrire dans {commun} (commun) est permis", r.returncode == 0, sortie(r))
    r = ecriture(l3, "/tmp/hors-du-depot/essai.txt", env)
    bilan.verifier("garde : écrire hors du dépôt est permis", r.returncode == 0, sortie(r))
    r = ecriture(l3, l3 / "Makefile", env)
    bilan.verifier("garde : un fichier qu'aucun lot ne possède est refusé, avec la marche à suivre (docs/lots.md)",
                   r.returncode == 2 and "docs/lots.md" in r.stderr, sortie(r))
    for secret in (l3 / ".env", l3 / ".env.local", l3 / "App/Prise/.env", Path("/tmp/hors-du-depot/.env")):
        r = ecriture(l3, secret, env)
        bilan.verifier(f"garde : {secret.name} est refusé même dans {'un dossier du lot' if 'Prise' in str(secret) else 'son emplacement'}",
                       r.returncode == 2 and "secrets" in r.stderr, sortie(r))
    r = ecriture(l3, l3 / "Projet.xcodeproj/project.pbxproj", env)
    bilan.verifier("garde : un fichier .pbxproj est refusé (A règle le projet dans Xcode)", r.returncode == 2 and "Xcode" in r.stderr, sortie(r))
    r = ecriture(l3, l3 / "App/Carte/Vue.swift", env, ATELIER_LIBRE="1")
    j = json_ou_none(r.stdout) or {}
    bilan.verifier("garde : ATELIER_LIBRE=1 lève le contrôle de dossier et le dit",
                   r.returncode == 0 and "ATELIER_LIBRE" in j.get("systemMessage", ""), sortie(r))
    r = ecriture(l3, l3 / "App/Prise/Vue.swift", env, ATELIER_LIBRE="1")
    bilan.verifier("garde : ATELIER_LIBRE=1 le dit à chaque écriture, même dans le lot", "ATELIER_LIBRE" in (json_ou_none(r.stdout) or {}).get("systemMessage", ""), sortie(r))
    r = ecriture(l3, l3 / ".env", env, ATELIER_LIBRE="1")
    bilan.verifier("garde : ATELIER_LIBRE=1 ne rouvre pas le .env", r.returncode == 2, sortie(r))
    r = ecriture(app, app / "App/Prise/Vue.swift", env)
    bilan.verifier("garde : sur main (pas un lot), écrire dans App/ est refusé et dit de lancer scripts/lot.sh",
                   r.returncode == 2 and "scripts/lot.sh" in r.stderr, sortie(r))
    r = ecriture(app, app / "docs/note.md", env)
    bilan.verifier("garde : sur main, les dossiers communs restent permis", r.returncode == 0, sortie(r))
    # La règle vient de docs/lots.md : si on y déplace le dossier du lot, le garde suit sans qu'on touche à un script.
    lots_md = l3 / "docs/lots.md"
    lots_md.write_text(lots_md.read_text(encoding="utf-8").replace("`App/Prise/`", "`App/Peche/`", 1), encoding="utf-8")
    ancien = ecriture(l3, l3 / "App/Prise/Vue.swift", env)
    nouveau = ecriture(l3, l3 / "App/Peche/Vue.swift", env)
    git(["checkout", "--", "docs/lots.md"], l3, env)
    bilan.verifier("garde : la règle est relue dans docs/lots.md (dossier du lot déplacé -> l'ancien est refusé, le nouveau permis)",
                   ancien.returncode == 2 and nouveau.returncode == 0, sortie(ancien) + sortie(nouveau))


def essai_contexte(m):
    bilan.section("hook SessionStart : contexte du lot")
    l3, app, env = m.l3, m.app, m.env
    fiche = (l3 / "docs/fiches/L3.md").read_text(encoding="utf-8")
    titre = fiche.splitlines()[0]
    for source in ("startup", "resume", "clear", "compact"):
        r = appeler(l3, "SessionStart", {"source": source}, source, env)
        j = json_ou_none(r.stdout) or {}
        ctx = j.get("hookSpecificOutput", {}).get("additionalContext", "")
        bilan.verifier(f"contexte ({source}) : injecte le lot L3, sa fiche, ses dossiers, sa commande de test et les 4 règles",
                       r.returncode == 0 and j.get("hookSpecificOutput", {}).get("hookEventName") == "SessionStart"
                       and "lot L3" in ctx and titre in ctx and "App/Prise/" in ctx and "AppTests/Prise/" in ctx
                       and "scripts/verif.sh" in ctx and "Un commit par lot terminé" in ctx and "fini" in ctx
                       and ".env" in ctx and "/fusion" in ctx and "scripts/fusionner.sh" in ctx, sortie(r) + ctx[:300])
    r = appeler(app, "SessionStart", {"source": "startup"}, "startup", env)
    ctx = (json_ou_none(r.stdout) or {}).get("hookSpecificOutput", {}).get("additionalContext", "")
    bilan.verifier("contexte : sur main, liste les lots et dit de lancer scripts/lot.sh",
                   "scripts/lot.sh" in ctx and "L3" in ctx and "lot/prise" in ctx and "Fiche docs/fiches" not in ctx, ctx[:300])

    # Cloud : Linux sans swift -> scripts/cloud-pret.sh part en arrière-plan sans bloquer.
    if platform.system() == "Linux" and not m.swift_reel:
        stub = m.app / "scripts" / "cloud-pret.sh"
        original = stub.read_text(encoding="utf-8")
        ecrire_executable(stub, '#!/usr/bin/env bash\necho lancé > "$ESSAI_ETAT/cloud-marqueur"\nsleep 3\n')
        marqueur = m.etat / "cloud-marqueur"
        if marqueur.exists():
            marqueur.unlink()
        debut = time.time()
        r = appeler(app, "SessionStart", {"source": "startup"}, "startup", m.env_sans)
        duree = time.time() - debut
        for _ in range(50):
            if marqueur.exists():
                break
            time.sleep(0.1)
        bilan.verifier("contexte : dans le cloud (Linux sans swift), lance cloud-pret.sh en arrière-plan sans bloquer",
                       r.returncode == 0 and marqueur.exists() and duree < 2.5, f"durée {duree:.1f} s ; {sortie(r)}")
        marqueur.unlink()
        r = appeler(app, "SessionStart", {"source": "startup"}, "startup", m.env_avec)
        time.sleep(0.8)
        bilan.verifier("contexte : avec swift installé (Mac), cloud-pret.sh n'est pas lancé", r.returncode == 0 and not marqueur.exists())
        stub.write_text(original, encoding="utf-8")
        git(["checkout", "--", "scripts/cloud-pret.sh"], app, env)
        time.sleep(3)  # laisse finir le stub avant la suite
    else:
        bilan.saute("contexte : lancement de cloud-pret.sh", "ce n'est pas un Linux sans swift")


def essai_formate(m):
    bilan.section("hook PostToolUse : formatage Swift")
    l3 = m.l3
    f = ecrire(l3, "App/Prise/Vue.swift")
    vider_appels(m)
    r = appeler(l3, "PostToolUse", {"tool_name": "Write", "tool_input": {"file_path": str(f)}}, "Write", m.env_avec)
    bilan.verifier("formate : un fichier .swift passe par `swift format --in-place`", r.returncode == 0 and f"swift format --in-place {f}" in appels(m), appels(m))
    vider_appels(m)
    t = ecrire(l3, "docs/note.md", "# note\n")
    r = appeler(l3, "PostToolUse", {"tool_name": "Write", "tool_input": {"file_path": str(t)}}, "Write", m.env_avec)
    bilan.verifier("formate : un fichier qui n'est pas .swift est laissé tranquille", r.returncode == 0 and "format" not in appels(m))
    if not m.swift_reel:
        vider_appels(m)
        r = appeler(l3, "PostToolUse", {"tool_name": "Write", "tool_input": {"file_path": str(f)}}, "Write", m.env_sans)
        bilan.verifier("formate : sans swift (cloud), il ne fait rien et ne bloque pas", r.returncode == 0 and appels(m) == "")
    r = lancer(["/bin/sh", "-c", commandes_declarees(l3, "PostToolUse", "Edit")[0]], l3, dict(m.env_avec, CLAUDE_PROJECT_DIR=str(l3)), "pas du json")
    bilan.verifier("formate : une entrée illisible ne bloque pas non plus", r.returncode == 0)
    os.remove(f)
    os.remove(t)


def essai_preuve(m):
    bilan.section("hook Stop : preuve avant l'arrêt")
    c0, env = m.c0, m.env_avec
    entree = lambda active, session="s1": {"session_id": session, "stop_hook_active": active}  # noqa: E731
    r = appeler(c0, "Stop", entree(False), "", env)
    bilan.verifier("preuve : rien n'a changé -> l'agent peut s'arrêter, sans bruit", r.returncode == 0 and r.stdout.strip() == "", sortie(r))

    ecrire(c0, "Packages/Core/Package.swift", "// swift-tools-version: 6.0\n")
    ecrire(c0, "Packages/Core/Sources/Core/Modele/Modele.swift", "public struct Modele {}\n")
    etat_de(m, "swift-resultat", "rouge")
    verdicts = []
    for i, active in enumerate((False, True, True, True), 1):
        r = appeler(c0, "Stop", entree(active), "", env)
        verdicts.append((r.returncode, json_ou_none(r.stdout) or {}, r))
    ok_blocs = all(code == 0 and j.get("decision") == "block" for code, j, _ in verdicts[:3])
    bilan.verifier("preuve : test rouge -> les 3 premiers arrêts sont refusés (decision: block)", ok_blocs, [v[2].stdout for v in verdicts])
    raison = verdicts[0][1].get("reason", "")
    bilan.verifier("preuve : le refus renvoie la fin de la sortie de verif.sh (✗ Core, verif : ROUGE)",
                   "✗ Core" in raison and "verif : ROUGE" in raison and "refus 1 sur 3" in raison, raison)
    bilan.verifier("preuve : le 3e refus exige d'écrire « ROUGE » à la personne",
                   "ROUGE :" in verdicts[2][1].get("reason", ""), verdicts[2][1].get("reason", ""))
    code4, j4, r4 = verdicts[3]
    bilan.verifier("preuve : au 4e essai l'agent est libéré, et la personne reçoit un avertissement ROUGE",
                   code4 == 0 and j4.get("decision") != "block" and "ROUGE" in j4.get("systemMessage", ""), r4.stdout)
    r = appeler(c0, "Stop", entree(False, "s2"), "", env)
    bilan.verifier("preuve : une autre session repart de zéro (refusée de nouveau)", (json_ou_none(r.stdout) or {}).get("decision") == "block", sortie(r))
    etat_de(m, "swift-resultat", "vert")
    r = appeler(c0, "Stop", entree(True, "s2"), "", env)
    bilan.verifier("preuve : test vert -> l'agent peut s'arrêter", r.returncode == 0 and (json_ou_none(r.stdout) or {}).get("decision") != "block" and r.stdout.strip() == "", sortie(r))

    # L'agent peut poser une question ou avouer un rouge ; il ne peut pas dire « fini » sur un rouge.
    etat_de(m, "swift-resultat", "rouge")
    question = {"session_id": "s4", "stop_hook_active": False, "last_assistant_message": "Je garde la grille ou l'IA d'abord ?"}
    r = appeler(c0, "Stop", question, "", env)
    bilan.verifier("preuve : rouge, mais l'agent pose une question -> il peut s'arrêter", r.returncode == 0 and r.stdout.strip() == "", sortie(r))
    aveu = {"session_id": "s4", "stop_hook_active": False, "last_assistant_message": "ROUGE : le test du verdict 3 échoue."}
    r = appeler(c0, "Stop", aveu, "", env)
    bilan.verifier("preuve : rouge annoncé « ROUGE : » -> il peut s'arrêter", r.returncode == 0 and r.stdout.strip() == "", sortie(r))
    faux = {"session_id": "s5", "stop_hook_active": False, "last_assistant_message": "C'est fini, tu veux tester ?"}
    r = appeler(c0, "Stop", faux, "", env)
    bilan.verifier("preuve : rouge, et l'agent dit « fini » -> refusé même avec une question", (json_ou_none(r.stdout) or {}).get("decision") == "block", sortie(r))
    etat_de(m, "swift-resultat", "vert")

    # Un 2e type de rouge : docs/lots.md incohérent (deux lots se partagent un dossier).
    lots_md = c0 / "docs/lots.md"
    lots_md.write_text(lots_md.read_text(encoding="utf-8").replace("`App/Prise/`", "`App/Carte/`", 1), encoding="utf-8")
    r = appeler(c0, "Stop", entree(False, "s3"), "", env)
    raison = (json_ou_none(r.stdout) or {}).get("reason", "")
    bilan.verifier("preuve : docs/lots.md incohérent -> refus, avec « ✗ lots »", "✗ lots" in raison, r.stdout)
    git(["checkout", "--", "docs/lots.md"], c0, env)


def essai_verif(m):
    bilan.section("scripts/verif.sh")
    c0, env = m.c0, m.env_avec
    etat_de(m, "swift-resultat", "vert")
    p = lancer(["bash", "scripts/verif.sh"], c0, env)
    lignes = [l for l in p.stdout.splitlines() if l.strip()]
    marques = [l for l in lignes if not l.startswith("    ") and not l.startswith("verif :")]
    bilan.verifier("verif.sh : chaque partie imprime ✓, ✗ ou « · sauté : raison » (jamais un vert silencieux)",
                   marques and all(l[0] in "✓✗·" for l in marques) and all(l.startswith("· sauté : ") for l in marques if l[0] == "·"), p.stdout)
    for partie in ("documents", "lots", "atelier", "Core", "App"):
        bilan.verifier(f"verif.sh : la partie « {partie} » apparaît", any(partie in l for l in marques), p.stdout)
    bilan.verifier("verif.sh : tout vert -> sort 0, résumé « verif : VERT »", p.returncode == 0 and lignes[-1].startswith("verif : VERT"), p.stdout)
    bilan.verifier("verif.sh : Core tourne avec swift et affiche son résumé", any(l.startswith("✓ Core") and "Swift natif" in l for l in lignes), p.stdout)

    etat_de(m, "swift-resultat", "rouge")
    p = lancer(["bash", "scripts/verif.sh", "--rapide"], c0, env)
    bilan.verifier("verif.sh --rapide : test rouge -> sort 1, ligne ✗ Core et résumé « ROUGE »",
                   p.returncode == 1 and "✗ Core" in p.stdout and "verif : ROUGE" in p.stdout, p.stdout)
    etat_de(m, "swift-resultat", "vert")

    # En --rapide, seules les parties touchées tournent.
    p = lancer(["bash", "scripts/verif.sh", "--rapide"], m.d1, env)
    bilan.verifier("verif.sh --rapide : rien n'a changé -> Core et documents sautés, vert",
                   p.returncode == 0 and "· sauté : Core" in p.stdout and "· sauté : documents" in p.stdout, p.stdout)

    # App sous Linux : refus si la branche touche App/, sauf en CI.
    ecrire(c0, "App/Carte/X.swift")
    if platform.system() == "Linux":
        p = lancer(["bash", "scripts/verif.sh"], c0, env)
        bilan.verifier("verif.sh : sous Linux, une branche qui touche App/ -> ✗ « à vérifier sur un Mac »",
                       p.returncode == 1 and "✗ App" in p.stdout and "à vérifier sur un Mac" in p.stdout, p.stdout)
        p = lancer(["bash", "scripts/verif.sh"], c0, dict(env, CI="true"))
        bilan.verifier("verif.sh : en CI (GitHub), la partie App est déclarée sautée", p.returncode == 0 and "· sauté : App" in p.stdout, p.stdout)
    # App sur Mac simulé : xcodebuild test avec le premier simulateur iPhone.
    (c0 / "Projet.xcodeproj").mkdir(exist_ok=True)
    vider_appels(m)
    p = lancer(["bash", "scripts/verif.sh"], c0, dict(env, ATELIER_SYSTEME="Darwin"))
    a = appels(m)
    bilan.verifier("verif.sh : sur Mac, lance xcodebuild test (schéma trouvé, simulateur iPhone, id du simulateur)",
                   "✓ App" in p.stdout and "xcodebuild test -project ./Projet.xcodeproj -scheme Pesche" in a
                   and "id=11111111-2222-3333-4444-555555555555" in a, p.stdout + a)
    vider_appels(m)
    lancer(["bash", "scripts/verif.sh"], c0, dict(env, ATELIER_SYSTEME="Darwin", SCHEMA="Autre"))
    bilan.verifier("verif.sh : la variable SCHEMA choisit le schéma Xcode", "-scheme Autre" in appels(m), appels(m))
    etat_de(m, "xcode-resultat", "rouge")
    p = lancer(["bash", "scripts/verif.sh"], c0, dict(env, ATELIER_SYSTEME="Darwin"))
    bilan.verifier("verif.sh : sur Mac, un xcodebuild rouge -> ✗ App, sort 1", p.returncode == 1 and "✗ App" in p.stdout, p.stdout)
    etat_de(m, "xcode-resultat", "vert")
    shutil.rmtree(c0 / "Projet.xcodeproj")
    os.remove(c0 / "App/Carte/X.swift")

    # Core sans swift : via Docker, ou ✗ avec la commande de réparation.
    if m.swift_reel or platform.system() == "Windows":
        bilan.saute("verif.sh : Core via Docker", "swift est installé sur cette machine")
    else:
        sans = m.env_sans
        for f in ("docker-up", "image"):
            if (m.etat / f).exists():
                (m.etat / f).unlink()
        p = lancer(["bash", "scripts/verif.sh"], c0, sans)
        bilan.verifier("verif.sh : ni Swift ni Docker -> ✗ Core avec la commande de réparation scripts/cloud-pret.sh",
                       p.returncode == 1 and "✗ Core" in p.stdout and "scripts/cloud-pret.sh" in p.stdout, p.stdout)
        etat_de(m, "docker-up", "")
        p = lancer(["bash", "scripts/verif.sh"], c0, sans)
        bilan.verifier("verif.sh : Docker répond mais l'image manque -> ✗ Core avec scripts/cloud-pret.sh",
                       p.returncode == 1 and "✗ Core" in p.stdout and "scripts/cloud-pret.sh" in p.stdout, p.stdout)
        etat_de(m, "image", "")
        vider_appels(m)
        p = lancer(["bash", "scripts/verif.sh"], c0, sans)
        attendu = f'docker run --rm -v {c0}:/w -w /w swift:6.4 swift test --package-path Packages/Core'
        bilan.verifier("verif.sh : sans swift mais avec Docker, Core tourne dans swift:6.4",
                       "✓ Core" in p.stdout and attendu in appels(m), p.stdout + appels(m))
        for f in ("docker-up", "image"):
            (m.etat / f).unlink()


def essai_cloud_pret(m):
    bilan.section("scripts/cloud-pret.sh")
    if platform.system() != "Linux" or m.swift_reel:
        bilan.saute("cloud-pret.sh", "il ne sert que sous Linux sans swift")
        return
    c0 = m.c0
    for f in ("docker-up", "image"):
        if (m.etat / f).exists():
            (m.etat / f).unlink()
    vider_appels(m)
    p = lancer(["bash", "scripts/cloud-pret.sh"], c0, m.env_sans)
    a = appels(m)
    bilan.verifier("cloud-pret.sh : Docker éteint -> il le démarre, attend qu'il réponde, puis télécharge swift:6.4",
                   p.returncode == 0 and "dockerd" in a and "docker pull swift:6.4" in a and a.index("dockerd") < a.index("pull"), sortie(p) + a)
    vider_appels(m)
    p = lancer(["bash", "scripts/cloud-pret.sh"], c0, m.env_sans)
    bilan.verifier("cloud-pret.sh : relancé, il est silencieux et ne refait rien (idempotent)", p.returncode == 0 and sortie(p).strip() == "" and appels(m) == "", sortie(p) + appels(m))
    vider_appels(m)
    p = lancer(["bash", "scripts/cloud-pret.sh"], c0, m.env_avec)
    bilan.verifier("cloud-pret.sh : avec swift installé, il ne fait rien", p.returncode == 0 and sortie(p).strip() == "" and appels(m) == "")
    for f in ("docker-up", "image"):
        (m.etat / f).unlink()


def essai_donnees_gitignore(m):
    bilan.section("scripts/donnees.sh et .gitignore")
    app = m.app
    etat_de(m, "gh-mode", "sans-release")
    p = lancer(["bash", "scripts/donnees.sh"], app, m.env_sans)
    bilan.verifier("donnees.sh : sans release « donnees », il le dit clairement et sort 1",
                   p.returncode == 1 and "release" in p.stderr and "donnees" in p.stderr and "pas encore" in p.stderr, sortie(p))
    etat_de(m, "gh-mode", "ok")
    p = lancer(["bash", "scripts/donnees.sh"], app, m.env_sans)
    dossier = app / "Packages/Core/Sources/Core/Resources"
    bilan.verifier("donnees.sh : avec la release, télécharge les 2 fichiers dans Resources/",
                   p.returncode == 0 and (dossier / "stations-especes.json").is_file() and (dossier / "rarete-departements.json").is_file(), sortie(p))
    bilan.verifier("donnees.sh : les fichiers téléchargés ne sont pas vus par git (.gitignore)", git(["status", "--porcelain"], app, m.env).stdout.strip() == "",
                   git(["status", "--porcelain"], app, m.env).stdout)
    shutil.rmtree(app / "Packages")
    for chemin in (".env", ".env.local", "App/.env.prod", "Packages/Core/Sources/Core/Resources/stations-especes.json",
                   "Packages/Core/Sources/Core/Resources/rarete-departements.json", "reports/ecrans/a.png", "build/x", "App/build/y",
                   "DerivedData/z", "Projet.xcodeproj/xcuserdata/a", "Projet.xcodeproj/project.xcworkspace/xcuserdata/a/UserInterfaceState.xcuserstate",
                   ".DS_Store", "App/.DS_Store", "fastlane/report.xml", "fastlane/screenshots/a.png", ".atelier/preuve-x.json"):
        ignore = git(["check-ignore", "-q", chemin], app, m.env).returncode == 0
        bilan.verifier(f".gitignore : {chemin} est ignoré", ignore)
    bilan.verifier(".gitignore : docs/ et App/ ne sont pas ignorés", git(["check-ignore", "-q", "docs/a.md"], app, m.env).returncode != 0
                   and git(["check-ignore", "-q", "App/Prise/a.swift"], app, m.env).returncode != 0)


# ---------------------------------------------------------------------------
# 5. Crochets de git
# ---------------------------------------------------------------------------


def commit(dossier, env, message="essai"):
    return git(["commit", "-m", message], dossier, env)


def essai_crochets_git(m):
    bilan.section("crochets de git (pre-commit, pre-merge-commit, pre-push)")
    l3, app, s1, d1, env = m.l3, m.app, m.s1, m.d1, m.env
    # hors dossier
    ecrire(l3, "App/Carte/Hors.swift")
    git(["add", "-A"], l3, env)
    p = commit(l3, env)
    bilan.verifier("pre-commit : un fichier hors du lot est refusé, avec le nom du lot propriétaire", p.returncode != 0 and "L2" in sortie(p) and "App/Carte/Hors.swift" in sortie(p), sortie(p))
    git(["reset", "-q"], l3, env)
    os.remove(l3 / "App/Carte/Hors.swift")
    # dans le lot
    ecrire(l3, "App/Prise/Vue.swift")
    ecrire(l3, "docs/note.md", "# note\n")
    git(["add", "-A"], l3, env)
    p = commit(l3, env, "Prise : première vue")
    bilan.verifier("pre-commit : un fichier du lot (App/Prise/) et un fichier commun (docs/) passent", p.returncode == 0, sortie(p))
    # Poké
    ecrire(l3, "App/Prise/Textes.swift", 'let titre = "Ma collection Pokémon"\n')
    git(["add", "-A"], l3, env)
    p = commit(l3, env)
    bilan.verifier("pre-commit : « Pokémon » dans App/ est refusé (marque de Nintendo)", p.returncode != 0 and "Nintendo" in sortie(p) and "Pescedex" in sortie(p), sortie(p))
    for mot in ("POKEDEX", "Poke\u0301mon"):  # majuscules ; « e » suivi d'un accent combiné
        ecrire(l3, "App/Prise/Textes.swift", 'let a = "' + mot + '"\n')
        git(["add", "-A"], l3, env)
        p = commit(l3, env)
        bilan.verifier(f"pre-commit : la variante {mot!r} est refusée aussi", p.returncode != 0 and "Nintendo" in sortie(p), sortie(p))
    ecrire(l3, "App/Prise/Textes.swift", 'let titre = "Ma collection Pescedex"\n')
    git(["add", "-A"], l3, env)
    p = commit(l3, env, "Prise : textes")
    bilan.verifier("pre-commit : « Pescedex » (le nom de la collection) passe", p.returncode == 0, sortie(p))
    ecrire(s1, "store/fiche.md", "# Fiche\nTous les Pokédex du monde\n")
    git(["add", "-A"], s1, env)
    p = commit(s1, env)
    bilan.verifier("pre-commit : « Pokédex » dans store/ est refusé aussi", p.returncode != 0 and "Nintendo" in sortie(p), sortie(p))
    git(["reset", "-q", "--hard"], s1, env)
    git(["clean", "-qfd"], s1, env)
    # .env et données fabriquées
    ecrire(l3, ".env", "CLE=\n")
    git(["add", "-f", ".env"], l3, env)
    p = commit(l3, env)
    bilan.verifier("pre-commit : un fichier .env est refusé même ajouté de force (git add -f)", p.returncode != 0 and "secrets" in sortie(p), sortie(p))
    git(["reset", "-q"], l3, env)
    os.remove(l3 / ".env")
    ecrire(d1, "Packages/Core/Sources/Core/Resources/stations-especes.json", "[]\n")
    git(["add", "-f", "Packages"], d1, env)
    p = commit(d1, env)
    bilan.verifier("pre-commit : un fichier de données fabriqué (stations-especes.json) est refusé même dans le dossier de son lot",
                   p.returncode != 0 and "scripts/donnees.sh" in sortie(p), sortie(p))
    git(["reset", "-q", "--hard"], d1, env)
    git(["clean", "-qfd"], d1, env)
    # main
    ecrire(app, "docs/direct.md", "# direct\n")
    git(["add", "-A"], app, env)
    p = commit(app, env)
    bilan.verifier("pre-commit : un commit direct sur main est refusé", p.returncode != 0 and "main" in sortie(p) and "scripts/lot.sh" in sortie(p), sortie(p))
    git(["reset", "-q"], app, env)
    os.remove(app / "docs/direct.md")
    # fusion directe dans main
    p = git(["merge", "--no-ff", "--no-edit", "lot/prise"], app, env)
    bilan.verifier("pre-merge-commit : fusionner un lot directement dans main est refusé", p.returncode != 0 and "main" in sortie(p), sortie(p))
    git(["merge", "--abort"], app, env)
    # envoi vers main
    p = git(["push", "origin", "HEAD:main"], l3, env)
    bilan.verifier("pre-push : un envoi direct vers main est refusé (seul fusionner.sh y envoie)", p.returncode != 0 and "fusionner.sh" in sortie(p), sortie(p))
    p = git(["push", "-q", "origin", "lot/prise"], l3, env)
    bilan.verifier("pre-push : l'envoi de la branche du lot est permis", p.returncode == 0, sortie(p))

    # Une fusion de main dans la branche ne doit pas être prise pour une sortie du lot (les autres lots ont changé main).
    pousser_tiers(m, "App/Carte/Z.swift", "let z = 1\n")
    pousser_tiers(m, "docs/conflit.md", "version de main\n")
    ecrire(l3, "docs/conflit.md", "version du lot\n")
    git(["add", "-A"], l3, env)
    commit(l3, env, "docs : conflit")
    git(["fetch", "-q", "origin"], l3, env)
    p = git(["merge", "--no-edit", "origin/main"], l3, env)
    bilan.verifier("fusion de main : un conflit est signalé par git", p.returncode != 0 and "CONFLICT" in sortie(p), sortie(p))
    ecrire(l3, "docs/conflit.md", "résolu\n")
    git(["add", "docs/conflit.md"], l3, env)
    p = git(["commit", "--no-edit"], l3, env)
    bilan.verifier("pre-commit : le commit qui termine une fusion de main passe (le travail des autres lots n'est pas contrôlé ici)",
                   p.returncode == 0, sortie(p))
    pousser_tiers(m, "App/Carte/Y.swift", "let y = 1\n")
    git(["fetch", "-q", "origin"], l3, env)
    p = git(["merge", "--no-edit", "origin/main"], l3, env)
    bilan.verifier("pre-merge-commit : une fusion automatique de main dans la branche du lot passe", p.returncode == 0, sortie(p))


# ---------------------------------------------------------------------------
# 6. fusionner.sh
# ---------------------------------------------------------------------------


def essai_fusionner(m):
    bilan.section("scripts/fusionner.sh")
    app, l3, c0, d1, env = m.app, m.l3, m.c0, m.d1, m.env_avec
    p = lancer(["bash", "scripts/fusionner.sh"], app, env)
    bilan.verifier("fusionner.sh : refuse de tourner hors d'une branche de lot (main)", p.returncode != 0 and "d'aucun lot" in p.stderr, sortie(p))

    avant = sha_distant(m)
    ecrire(l3, "App/Prise/Sale.swift")
    p = lancer(["bash", "scripts/fusionner.sh"], l3, env)
    bilan.verifier("fusionner.sh : refuse un arbre non propre", p.returncode != 0 and "non commités" in p.stderr and sha_distant(m) == avant, sortie(p))
    os.remove(l3 / "App/Prise/Sale.swift")

    ecrire(l3, "App/Carte/Hors.swift")
    git(["add", "-A"], l3, env)
    git(["commit", "-q", "--no-verify", "-m", "hors lot (contourne le crochet)"], l3, env)
    p = lancer(["bash", "scripts/fusionner.sh"], l3, env)
    bilan.verifier("fusionner.sh : un fichier hors du lot est refusé, nommé avec son propriétaire, et rien n'est envoyé",
                   p.returncode != 0 and "App/Carte/Hors.swift" in sortie(p) and "L2" in sortie(p) and sha_distant(m) == avant, sortie(p))
    git(["reset", "-q", "--hard", "HEAD~1"], l3, env)

    # test rouge
    ecrire(c0, "Packages/Core/Package.swift", "// swift-tools-version: 6.0\n")
    ecrire(c0, "Packages/Core/Sources/Core/Modele/Modele.swift", "public struct Modele {}\n")
    git(["add", "-A"], c0, env)
    p = git(["commit", "-q", "-m", "Contrats : modèle"], c0, env)
    etat_de(m, "swift-resultat", "rouge")
    p = lancer(["bash", "scripts/fusionner.sh"], c0, env)
    bilan.verifier("fusionner.sh : un test rouge empêche la fusion (✗ Core, rien n'est envoyé à main)",
                   p.returncode != 0 and "✗ Core" in p.stdout and "rien n'est envoyé" in p.stderr and sha_distant(m) == avant, sortie(p))
    etat_de(m, "swift-resultat", "vert")
    p = lancer(["bash", "scripts/fusionner.sh"], c0, env)
    tete = git(["rev-parse", "HEAD"], c0, env).stdout.strip()
    bilan.verifier("fusionner.sh : lot propre et vert -> main reçoit la fusion (git push origin HEAD:main)",
                   p.returncode == 0 and sha_distant(m) == tete, sortie(p))
    bilan.verifier("fusionner.sh : la branche du lot est envoyée aussi", sha_distant(m, "lot/contrats") == tete)
    fin = [l for l in p.stdout.strip().splitlines() if l.strip()][-3:]
    bilan.verifier("fusionner.sh : se termine par un point de 3 lignes (fusionné, vérification, suite)",
                   len(fin) == 3 and fin[0].startswith("Fusionné") and fin[1].startswith("Vérification : verif : VERT") and fin[2].startswith("Suite"), "\n".join(fin))

    # quelqu'un fusionne entre-temps
    ecrire(d1, "Packages/Core/Sources/Core/Resources/regles.json", "{}\n")
    git(["add", "-A"], d1, env)
    git(["commit", "-q", "-m", "Données : règles"], d1, env)
    (m.etat / "avant-test.sh").write_text(
        f'cd "{m.tiers}" && git pull -q origin main && echo c > docs/course.md && git add -A && git commit -q --no-verify -m course && git push -q origin HEAD:main\n',
        encoding="utf-8")
    p = lancer(["bash", "scripts/fusionner.sh"], d1, env)
    bilan.verifier("fusionner.sh : si quelqu'un a fusionné entre-temps, il le dit et demande de relancer",
                   p.returncode != 0 and "entre-temps" in p.stderr and "Relance" in p.stderr, sortie(p))
    p = lancer(["bash", "scripts/fusionner.sh"], d1, env)
    bilan.verifier("fusionner.sh : relancé, il reprend la dernière version de main et fusionne",
                   p.returncode == 0 and sha_distant(m) == git(["rev-parse", "HEAD"], d1, env).stdout.strip(), sortie(p))
    sujet = git(["log", "--merges", "--format=%s", "-1"], d1, env).stdout
    bilan.verifier("fusionner.sh : main est repris par un merge (commit de fusion « origin/main into lot/donnees »), jamais par un rebase",
                   "origin/main" in sujet and "lot/donnees" in sujet, sujet)


def essai_mise_a_jour(m):
    bilan.section("scripts/fusionner.sh : lots de la mise à jour")
    env = m.env_avec
    lots = __import__("json").loads(lancer(["python3", "outils/atelier/lots.py", "json"], m.app, env).stdout)
    branches = [l["branche"] for l in lots if l.get("mise_a_jour")]
    bilan.verifier("lots.py : les lots de la mise à jour se lisent dans docs/lots.md", len(branches) >= 1, str(branches))
    soumis = next(l["branche"] for l in lots if not l.get("mise_a_jour") and l["branche"].startswith("lot/"))
    for branche in branches + [soumis]:
        git(["checkout", "-q", "-B", branche, "main"], m.app, env)
        ecrire(m.app, "docs/sale-essai.md", "sale\n")
        p = lancer(["bash", "scripts/fusionner.sh"], m.app, env)
        if branche in branches:
            bilan.verifier(f"fusionner.sh : sans l'étiquette v1.0-soumise, {branche} est refusé et le message dit pourquoi",
                           p.returncode != 0 and "v1.0-soumise" in p.stderr and "non commités" not in p.stderr, sortie(p))
        else:
            bilan.verifier(f"fusionner.sh : {branche} (version soumise) n'attend pas l'étiquette",
                           "v1.0-soumise" not in sortie(p) and "non commités" in p.stderr, sortie(p))
        os.remove(m.app / "docs/sale-essai.md")
    git(["tag", "v1.0-soumise"], m.app, env)
    git(["checkout", "-q", "-B", branches[0], "main"], m.app, env)
    ecrire(m.app, "docs/sale-essai.md", "sale\n")
    p = lancer(["bash", "scripts/fusionner.sh"], m.app, env)
    bilan.verifier(f"fusionner.sh : avec l'étiquette, {branches[0]} passe à la suite de ses contrôles",
                   "✓ Mise à jour" in p.stdout and "non commités" in p.stderr, sortie(p))
    os.remove(m.app / "docs/sale-essai.md")
    git(["tag", "-d", "v1.0-soumise"], m.app, env)
    git(["checkout", "-q", "main"], m.app, env)


def essai_env(m):
    bilan.section("scripts/env.sh : le .env aux noms vides")
    d = Path(tempfile.mkdtemp(prefix="atelier-env-"))
    try:
        (d / "scripts").mkdir()
        shutil.copy(RACINE / "scripts" / "env.sh", d / "scripts" / "env.sh")
        shutil.copy(RACINE / "env.exemple", d / "env.exemple")
        env = dict(os.environ, ATELIER_SANS_EDITEUR="1")
        p = lancer(["bash", "scripts/env.sh"], d, env)
        noms = [l.split("=")[0] for l in (RACINE / "env.exemple").read_text(encoding="utf-8").splitlines() if l and not l.startswith("#")]
        contenu = (d / ".env").read_text(encoding="utf-8") if (d / ".env").exists() else ""
        bilan.verifier("env.sh : crée .env avec chaque nom de env.exemple, valeur vide", p.returncode == 0 and all(f"{n}=\n" in contenu for n in noms), sortie(p))
        bilan.verifier("env.sh : .env n'est lisible que par son propriétaire (600)", oct((d / ".env").stat().st_mode & 0o777) == "0o600")
        (d / ".env").write_text(contenu.replace(f"{noms[0]}=\n", f"{noms[0]}=valeur-secrete\n"), encoding="utf-8")
        p = lancer(["bash", "scripts/env.sh"], d, env)
        apres = (d / ".env").read_text(encoding="utf-8")
        bilan.verifier("env.sh : relancé, il garde les valeurs remplies et n'ajoute aucun doublon",
                       f"{noms[0]}=valeur-secrete" in apres and apres.count(f"{noms[0]}=") == 1, apres.replace("valeur-secrete", "***"))
        bilan.verifier("env.sh : n'affiche jamais une valeur", "valeur-secrete" not in p.stdout + p.stderr)
    finally:
        shutil.rmtree(d, ignore_errors=True)


# ---------------------------------------------------------------------------
# Programme
# ---------------------------------------------------------------------------


def main():
    debut = time.time()
    verifications_statiques()
    tmp = Path(tempfile.mkdtemp(prefix="atelier-essai-"))
    garder = os.environ.get("ESSAI_GARDER") == "1"
    try:
        m = construire_monde(tmp)
        essai_lot_sh(m)
        essai_garde(m)
        essai_contexte(m)
        essai_formate(m)
        essai_crochets_git(m)
        essai_donnees_gitignore(m)
        essai_preuve(m)
        essai_verif(m)
        essai_cloud_pret(m)
        essai_fusionner(m)
        essai_mise_a_jour(m)
        essai_env(m)
    except Exception as erreur:  # noqa: BLE001 - un plantage de l'essai est un échec de l'essai
        import traceback
        bilan.verifier("l'essai lui-même ne plante pas", False, traceback.format_exc())
    finally:
        if garder or bilan.echecs:
            print(f"(dossier de l'essai gardé pour regarder : {tmp})")
        else:
            shutil.rmtree(tmp, ignore_errors=True)
    reussis = bilan.total - len(bilan.echecs)
    print()
    bilan.resume()
    print()
    if bilan.echecs:
        print("Échecs :")
        for nom in bilan.echecs:
            print(f"  - {nom}")
    print(f"(durée de l'essai : {time.time() - debut:.0f} s)")
    print(f"atelier : {reussis}/{bilan.total} vérifications passent", flush=True)
    return 0 if not bilan.echecs else 1


if __name__ == "__main__":
    sys.exit(main())
