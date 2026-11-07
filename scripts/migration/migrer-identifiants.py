#!/usr/bin/env python3
"""Migration des identifiants FishMe : du compte MWM vers le compte Developer personnel de Titouan.

Ne contacte aucun service (ni Apple ni autre), ne lit aucun secret, ne contient aucun identifiant d'equipe.

MODE PAR DEFAUT : simulation. Le script inventorie et affiche un rapport, il n'ecrit RIEN.

  python3 scripts/migration/migrer-identifiants.py \
      --nouveau-bundle-id com.exemple.fishme --nouveau-team-id ABCDE12345 \
      --nouveau-conteneur-icloud iCloud.com.exemple.fishme --nouveau-app-group group.com.exemple.fishme \
      --nouveau-id-widget com.exemple.fishme.widget

Les parametres peuvent aussi venir de l'environnement : NOUVEAU_BUNDLE_ID, NOUVEAU_TEAM_ID,
NOUVEAU_CONTENEUR_ICLOUD, NOUVEAU_APP_GROUP, NOUVEAU_ID_WIDGET.

Sans parametres, le rapport d'inventaire marche quand meme (--inventaire).

Application (jamais implicite) :
  --appliquer --copie DOSSIER          copie le depot dans DOSSIER (vide ou absent), remplace dans la copie
  --appliquer --sur-depot-courant      remplace dans le depot lui-meme (explicite, depot git propre exige)
  --portee code|tout                   code (defaut) : sources, config, projet, StoreKit, scripts, outils ;
                                       tout : plus docs/, reports/, CLAUDE.md, .claude/ (documents historiques)

Jamais remplace automatiquement (rapporte seulement, a traiter a la main) : cle Spark, schema d'URL,
adresse de contact, mentions MWM des textes juridiques, cles Info.plist, capacites des entitlements.
Remplacement un a un, une seule passe : un identifiant deja remplace n'est jamais remplace deux fois.
"""
import argparse, json, os, re, shutil, subprocess, sys
from collections import defaultdict

ANCIEN_BASE = "ai.mwm.build.challenge.team.01"
ANCIEN_TEAM = "ZUQ3ZP29N4"
B = re.escape(ANCIEN_BASE)

# Ordre = priorite a la meme position ; les plus longs d'abord. Un seul passage de re.sub.
MOTIF = re.compile("|".join([
    r"(?P<groupe>group\." + B + r")",
    r"(?P<icloud>iCloud\." + B + r")",
    r"(?P<widget>" + B + r"\.widget\b)",
    r"(?P<produit>" + B + r"(?=\.(?:monthly|yearly)\.))",
    r"(?P<app>" + B + r"(?![\w]))",
    r"(?P<tests>ai\.mwm\.BuildChallenge(?:UI)?Tests\b)",
    r"(?P<team>\b" + ANCIEN_TEAM + r"\b)",
]))
# Nu dans Swift : `private static let base = "ai.mwm...01"` est capte par "app" ; les produits
# sont construits avec "\(base).yearly..." : un seul remplacement de base suffit (type app, signale).

SIGNALEMENTS = [  # (type, regex) : rapportes, JAMAIS remplaces
    ("cle_spark (masquee)", re.compile(r"pk_(?:sbox|prod)_[0-9a-f]{32}")),
    ("schema_url (fishme://)", re.compile(r"\bfishme://|<string>fishme</string>")),
    ("contact_email", re.compile(r"[A-Za-z0-9._-]+@(?:gmail\.com|mwm\.ai)")),
    ("url_mwm (mwm.ai)", re.compile(r"https?://[\w.-]*mwm\.ai[^\s)\"'>]*")),
    ("cle_info_plist", re.compile(r"<key>(?:FishMeICloud|ReglesBaseURL|CFBundleURLName)</key>|\$\(FISHME_ICLOUD\)")),
    ("capacite_entitlement", re.compile(r"<key>(?:aps-environment|com\.apple\.developer\.weatherkit|com\.apple\.developer\.icloud-services|com\.apple\.developer\.associated-domains)</key>")),
    ("mention_mwm_juridique", re.compile(r"\b(?:MWM|mwm)\b")),
    ("variables_envoi_asc", re.compile(r"\bASC_(?:KEY_ID|ISSUER_ID|KEY_PATH)\b")),
]
TYPES_AUTO = ["app", "widget", "groupe", "icloud", "produit", "tests", "team"]
LIBELLES = {
    "app": "Bundle ID de l'app", "widget": "Bundle ID du widget", "groupe": "App Group",
    "icloud": "Conteneur iCloud", "produit": "Identifiants de produits d'abonnement (prefixe)",
    "tests": "Bundle ID des cibles de test", "team": "Identifiant d'equipe",
}
EXCLUS_DIRS = {".git", "mwm-spark-flash-sdk", ".build", "DerivedData", "node_modules", "__pycache__", "venv", ".venv", ".swiftpm", "xcuserdata"}
PORTEE_DOCS = ("docs/", "reports/", "CLAUDE.md", ".claude/", "store/", "skills-lock.json", "outils/atelier/", "outils/marche/")
MAX_TAILLE = 2_000_000
EXT_BINAIRES = (".png", ".jpg", ".jpeg", ".gif", ".webp", ".heic", ".woff", ".woff2", ".ttf", ".otf", ".mp4", ".mov", ".pdf", ".zip", ".car", ".a", ".dylib", ".ico", ".svg")
NE_JAMAIS_TOUCHER = {"scripts/migration/"}  # ce script et ses tests citent les anciens identifiants


def fichiers(racine):
    for dp, dns, fns in os.walk(racine):
        dns[:] = [d for d in dns if d not in EXCLUS_DIRS and not d.endswith(".xcassets")]
        for fn in fns:
            p = os.path.join(dp, fn)
            rel = os.path.relpath(p, racine).replace(os.sep, "/")
            if fn.lower().endswith(EXT_BINAIRES) or os.path.islink(p) or any(rel.startswith(x) for x in NE_JAMAIS_TOUCHER):
                continue
            try:
                if os.path.getsize(p) > MAX_TAILLE:
                    continue
                with open(p, "rb") as f:
                    brut = f.read()
            except OSError:
                continue
            if b"\0" in brut:
                continue
            try:
                yield rel, brut.decode("utf-8")
            except UnicodeDecodeError:
                continue


def dans_portee(rel, portee):
    return portee == "tout" or not rel.startswith(PORTEE_DOCS)


def inventaire(racine):
    auto = defaultdict(lambda: defaultdict(int))   # rel -> type -> n
    manuel = defaultdict(lambda: defaultdict(int))
    for rel, texte in fichiers(racine):
        for m in MOTIF.finditer(texte):
            auto[rel][m.lastgroup] += 1
        for nom, rx in SIGNALEMENTS:
            n = len(rx.findall(texte))
            if n:
                # la mention MWM n'est comptee que dans les textes juridiques ; la cle Spark ailleurs aussi
                if nom == "mention_mwm_juridique" and not rel.startswith(("docs/legal/", "App/Abonnement/", "docs/mac-a-faire/cgu")):
                    continue
                if nom == "variables_envoi_asc" and not rel.startswith("scripts/"):
                    continue
                manuel[rel][nom] += n
    return auto, manuel


def totaux(d):
    t = defaultdict(int)
    for r in d.values():
        for k, v in r.items():
            t[k] += v
    return t


def rapport(auto, manuel, portee, as_json=False):
    ta, tm = totaux(auto), totaux(manuel)
    if as_json:
        print(json.dumps({"auto": auto, "manuel": manuel}, indent=1, ensure_ascii=False)); return
    print("== Remplacables automatiquement (portee des documents : %s) ==" % portee)
    for t in TYPES_AUTO:
        fs = sorted(r for r in auto if auto[r].get(t))
        print("\n[%s] %s : %d occurrence(s) dans %d fichier(s)" % (t, LIBELLES[t], ta.get(t, 0), len(fs)))
        for r in fs:
            tag = "" if dans_portee(r, portee) else "   (hors portee 'code')"
            print("   %4d  %s%s" % (auto[r][t], r, tag))
    print("\n== Par fichier (tous types) ==")
    for r in sorted(auto):
        print("   %-60s %s" % (r, ", ".join("%s=%d" % kv for kv in sorted(auto[r].items()))))
    print("\n== A traiter a la main : jamais remplace par le script ==")
    for nom in sorted(tm):
        fs = sorted(r for r in manuel if manuel[r].get(nom))
        print("\n[%s] %d occurrence(s), %d fichier(s)" % (nom, tm[nom], len(fs)))
        for r in fs[:15]:
            print("   %4d  %s" % (manuel[r][nom], r))
        if len(fs) > 15:
            print("   ... et %d autres" % (len(fs) - 15))
    code = sum(v for r, c in auto.items() if dans_portee(r, "code") for v in c.values())
    print("\nTOTAL auto : %d occurrence(s) / %d fichier(s) ; dont portee 'code' : %d" % (sum(ta.values()), len(auto), code))


def valider(p):
    err = []
    rx = re.compile(r"^[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$")
    if not rx.match(p["app"]): err.append("NOUVEAU_BUNDLE_ID invalide (format DNS inverse, lettres, chiffres, tirets)")
    if not rx.match(p["widget"]) or not p["widget"].startswith(p["app"] + "."): err.append("NOUVEAU_ID_WIDGET doit commencer par NOUVEAU_BUNDLE_ID + '.'")
    if not re.match(r"^[A-Z0-9]{10}$", p["team"]): err.append("NOUVEAU_TEAM_ID : 10 caracteres, majuscules et chiffres")
    if not p["icloud"].startswith("iCloud.") or not rx.match(p["icloud"]): err.append("NOUVEAU_CONTENEUR_ICLOUD doit commencer par 'iCloud.'")
    if not p["groupe"].startswith("group.") or not rx.match(p["groupe"]): err.append("NOUVEAU_APP_GROUP doit commencer par 'group.'")
    if p["app"] == ANCIEN_BASE or p["team"] == ANCIEN_TEAM or ANCIEN_BASE in p["icloud"] + p["groupe"] + p["widget"]:
        err.append("une nouvelle valeur reprend un ancien identifiant MWM")
    return err


def remplacer(texte, p):
    def f(m):
        g = m.lastgroup
        if g == "tests":
            return p["app"] + (".BuildChallengeUITests" if "UI" in m.group(0) else ".BuildChallengeTests")
        return {"groupe": p["groupe"], "icloud": p["icloud"], "widget": p["widget"], "produit": p["app"],
                "app": p["app"], "team": p["team"]}[g]
    return MOTIF.subn(f, texte)


def appliquer(racine, p, portee):
    n_f = n_o = 0
    for rel, texte in list(fichiers(racine)):
        if not dans_portee(rel, portee):
            continue
        nouveau, n = remplacer(texte, p)
        if n:
            with open(os.path.join(racine, rel), "w", encoding="utf-8", newline="") as f:
                f.write(nouveau)
            n_f += 1; n_o += n
    return n_f, n_o


def git_propre(racine):
    try:
        r = subprocess.run(["git", "-C", racine, "status", "--porcelain"], capture_output=True, text=True, timeout=60)
        return r.returncode == 0 and r.stdout.strip() == ""
    except Exception:
        return False


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ev = os.environ.get
    ap.add_argument("--nouveau-bundle-id", default=ev("NOUVEAU_BUNDLE_ID"))
    ap.add_argument("--nouveau-team-id", default=ev("NOUVEAU_TEAM_ID"))
    ap.add_argument("--nouveau-conteneur-icloud", default=ev("NOUVEAU_CONTENEUR_ICLOUD"))
    ap.add_argument("--nouveau-app-group", default=ev("NOUVEAU_APP_GROUP"))
    ap.add_argument("--nouveau-id-widget", default=ev("NOUVEAU_ID_WIDGET"))
    ap.add_argument("--depot", default=None, help="racine du depot (defaut : deux niveaux au-dessus du script)")
    ap.add_argument("--portee", choices=["code", "tout"], default="code")
    ap.add_argument("--inventaire", action="store_true", help="rapport seul, sans parametres (simulation)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--appliquer", action="store_true")
    ap.add_argument("--copie", default=None, help="dossier de destination d'une copie (avec --appliquer)")
    ap.add_argument("--sur-depot-courant", action="store_true")
    a = ap.parse_args(argv)

    racine = os.path.abspath(a.depot or os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
    auto, manuel = inventaire(racine)
    rapport(auto, manuel, a.portee, a.json)

    vals = {"app": a.nouveau_bundle_id, "team": a.nouveau_team_id, "icloud": a.nouveau_conteneur_icloud,
            "groupe": a.nouveau_app_group, "widget": a.nouveau_id_widget}
    if not a.appliquer:
        if all(vals.values()):
            e = valider(vals)
            if e:
                print("\nParametres invalides :\n - " + "\n - ".join(e)); return 2
            print("\nSIMULATION : rien n'a ete ecrit. Ajouter --appliquer avec --copie DOSSIER ou --sur-depot-courant.")
        else:
            print("\nSIMULATION (inventaire seul) : rien n'a ete ecrit.")
        return 0

    manquants = [k for k, v in vals.items() if not v]
    if manquants:
        print("\nERREUR : parametres manquants : " + ", ".join(manquants)); return 2
    e = valider(vals)
    if e:
        print("\nParametres invalides :\n - " + "\n - ".join(e)); return 2
    if bool(a.copie) == bool(a.sur_depot_courant):
        print("\nERREUR : --appliquer demande exactement un de --copie DOSSIER ou --sur-depot-courant."); return 2
    cible = racine
    if a.copie:
        cible = os.path.abspath(a.copie)
        if os.path.exists(cible) and os.listdir(cible):
            print("ERREUR : %s existe et n'est pas vide." % cible); return 2
        if cible == racine or cible.startswith(racine + os.sep):
            print("ERREUR : la copie ne peut pas etre dans le depot."); return 2
        shutil.copytree(racine, cible, ignore=shutil.ignore_patterns(".git", "DerivedData", ".build"), dirs_exist_ok=True)
        print("\nCopie faite : " + cible)
    elif not git_propre(racine):
        print("\nERREUR : le depot a des changements non commites (ou n'est pas git). Commit d'abord, ou utilise --copie."); return 2
    nf, no = appliquer(cible, vals, a.portee)
    print("APPLIQUE sur %s : %d occurrence(s) dans %d fichier(s). A relire avec git diff, puis build + tests." % (cible, no, nf))
    print("Reste a la main : cle Spark, schema d'URL, e-mail de contact, textes juridiques, capacites (voir docs/migration-compte.md).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
