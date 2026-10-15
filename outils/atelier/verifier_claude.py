"""Vérifie les relecteurs (.claude/agents/) et les commandes (.claude/skills/).

Bibliothèque standard seulement. Sort 0 et affiche « relecteurs et commandes : N fichiers conformes »,
sinon affiche la liste des problèmes et sort 1.

Ce qui est contrôlé :
  - chaque agent : en-tête (entre deux lignes ---), `name` égal au nom du fichier, `description`,
    `tools`, `model` parmi sonnet, opus, haiku (jamais inherit) ;
  - chaque commande : en-tête, `name` égal au nom du dossier, `description` ;
  - les valeurs de l'en-tête sont du YAML valide (un « : » dans une valeur sans guillemets fait
    sauter le fichier sans message, voir https://code.claude.com/docs/en/sub-agents) ;
  - les champs inconnus (Claude Code les ignore sans le dire, donc une faute de frappe passe inaperçue) ;
  - chaque script `scripts/*.sh` cité est dans la liste du contrat ;
  - les relecteurs et le testeur n'ont pas Write ni Edit (lecture seule) ;
  - chaque nom d'agent cité existe ;
  - les agents et les commandes attendus sont là (dont le banc d'essai) ;
  - aucune ligne ne contient « Poké » sans le mot « marque », ni de tiret cadratin.

Usage : python3 outils/atelier/verifier_claude.py [--racine DOSSIER]
"""
import os
import re
import sys
import unicodedata

RACINE = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

# Scripts que les agents et les commandes ont le droit de citer (contrat de l'atelier).
SCRIPTS_DU_CONTRAT = {"verif.sh", "fusionner.sh", "lot.sh", "envoi.sh"}

AGENTS_ATTENDUS = {"relecteur-apple", "relecteur-code", "relecteur-regles", "testeur-ecran", "revue-finale",
                   "banc-utilisateur", "banc-avocat", "codeur", "petites-mains",
                   "testeur-identification", "revue-ux-2taps", "coupeur", "verificateur-wording"}
COMMANDES_ATTENDUES = {"lot", "fusion", "ecran", "envoi", "point", "banc"}

MODELES = {"sonnet", "opus", "haiku"}

# Champs documentés sur https://code.claude.com/docs/en/sub-agents et .../skills (lus le 13 oct. 2026).
CHAMPS_AGENT = {
    "name", "description", "tools", "disallowedTools", "model", "permissionMode", "skills", "mcpServers",
    "hooks", "maxTurns", "memory", "background", "omitClaudeMd", "effort", "isolation", "color",
    "initialPrompt", "experimental",
}
CHAMPS_COMMANDE = {
    "name", "description", "when_to_use", "argument-hint", "arguments", "disable-model-invocation",
    "user-invocable", "allowed-tools", "disallowed-tools", "model", "effort", "context", "agent",
    "background", "hooks", "paths", "shell",
}

# Ces agents ne modifient jamais le code : ni Write, ni Edit.
OUTILS_INTERDITS_EN_LECTURE = {"Write", "Edit", "MultiEdit", "NotebookEdit"}

TIRET_CADRATIN = "—"
NOM_VALIDE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
SCRIPT_CITE = re.compile(r"scripts/([A-Za-z0-9_.\-]+\.sh)")
AGENT_CITE = re.compile(r"\b(relecteur-[a-z]+|testeur-ecran|testeur-identification|revue-finale|revue-ux-2taps|verificateur-wording|banc-[a-z]+)\b")
MARQUE_NINTENDO = re.compile(r"\bpok[eé]", re.IGNORECASE)


def lire(chemin):
    with open(chemin, encoding="utf-8") as f:
        return unicodedata.normalize("NFC", f.read())


def lire_entete(texte):
    """Rend (champs, erreurs). `champs` va du nom du champ à sa valeur brute (une chaîne)."""
    lignes = texte.split("\n")
    if not lignes or lignes[0].rstrip() != "---":
        return None, ["la première ligne doit être --- (l'en-tête commence au tout début du fichier)"]
    fin = next((i for i in range(1, len(lignes)) if lignes[i].rstrip() == "---"), None)
    if fin is None:
        return None, ["l'en-tête n'est pas refermé par une deuxième ligne ---"]
    champs, erreurs, cle = {}, [], None
    for ligne in lignes[1:fin]:
        if not ligne.strip() or ligne.lstrip().startswith("#"):
            continue
        if ligne[0] in " \t":
            if cle is None:
                erreurs.append(f"ligne d'en-tête mal placée : {ligne.strip()!r}")
                continue
            suite = ligne.strip()
            if suite.startswith("- "):
                suite = suite[2:].strip()
                champs[cle] = (champs[cle] + ", " if champs[cle] else "") + suite
            else:
                champs[cle] = (champs[cle] + " " if champs[cle] else "") + suite
            continue
        m = re.match(r"^([A-Za-z][A-Za-z0-9_-]*):(?:\s+(.*))?$", ligne)
        if not m:
            erreurs.append(f"ligne d'en-tête illisible : {ligne.strip()!r} (attendu : nom: valeur)")
            cle = None
            continue
        cle = m.group(1)
        brut = (m.group(2) or "").strip()
        if cle in champs:
            erreurs.append(f"champ {cle} écrit deux fois")
        if brut in {">", ">-", "|", "|-", ">+", "|+"}:
            brut = ""
        else:
            erreurs += controler_valeur_yaml(cle, brut)
        champs[cle] = brut
    return champs, erreurs


def controler_valeur_yaml(cle, brut):
    """Repère les valeurs que YAML lirait de travers ou refuserait."""
    if not brut:
        return []
    if brut.startswith('"'):
        if len(brut) < 2 or not brut.endswith('"') or re.search(r'(?<!\\)"', brut[1:-1]):
            return [f"{cle} : guillemets doubles mal fermés (un \" à l'intérieur s'écrit \\\")"]
        return []
    if brut.startswith("'"):
        if len(brut) < 2 or not brut.endswith("'") or "'" in brut[1:-1].replace("''", ""):
            return [f"{cle} : apostrophes simples mal fermées (une apostrophe à l'intérieur s'écrit '')"]
        return []
    if brut[0] in "*&!%@`|>#":
        return [f"{cle} : la valeur ne peut pas commencer par {brut[0]!r} sans guillemets"]
    if ": " in brut or brut.endswith(":") or " #" in brut:
        return [f"{cle} : la valeur contient « : » ou « # » sans guillemets, Claude Code sauterait le fichier"]
    return []


def sans_guillemets(valeur):
    if len(valeur) >= 2 and valeur[0] == valeur[-1] and valeur[0] in "\"'":
        return valeur[1:-1]
    return valeur


def liste_outils(valeur):
    valeur = valeur.strip()
    if valeur.startswith("[") and valeur.endswith("]"):
        valeur = valeur[1:-1]
    return [o.strip() for o in valeur.split(",") if o.strip()]


def verifier_agent(chemin, noms_agents):
    problemes = []
    base = os.path.basename(chemin)
    nom_fichier = base[:-3] if base.endswith(".md") else base
    champs, erreurs = lire_entete(lire(chemin))
    problemes += erreurs
    if champs is None:
        return problemes
    for inconnu in sorted(set(champs) - CHAMPS_AGENT):
        problemes.append(f"champ inconnu « {inconnu} » (Claude Code l'ignore sans le dire)")
    nom = sans_guillemets(champs.get("name", ""))
    if not nom:
        problemes.append("name manquant")
    else:
        if nom != nom_fichier:
            problemes.append(f"name « {nom} » différent du nom du fichier « {nom_fichier} »")
        if not NOM_VALIDE.match(nom):
            problemes.append(f"name « {nom} » : lettres minuscules, chiffres et tirets seulement")
        noms_agents.add(nom)
    if not sans_guillemets(champs.get("description", "")).strip():
        problemes.append("description manquante ou vide")
    outils = liste_outils(sans_guillemets(champs.get("tools", "")))
    if not outils:
        problemes.append("tools manquant ou vide (liste des outils permis)")
    for doublon in sorted({o for o in outils if outils.count(o) > 1}):
        problemes.append(f"tools : {doublon} écrit deux fois")
    if nom_fichier.startswith(("relecteur-", "testeur-", "revue-", "banc-")):
        for interdit in sorted(set(outils) & OUTILS_INTERDITS_EN_LECTURE):
            problemes.append(f"tools : {interdit} interdit (cet agent est en lecture seule)")
    modele = sans_guillemets(champs.get("model", ""))
    if not modele:
        problemes.append("model manquant (règle d'Adem : jamais d'héritage du modèle de la session)")
    elif modele == "inherit":
        problemes.append("model : inherit interdit (écrire sonnet, opus ou haiku)")
    elif modele not in MODELES:
        problemes.append(f"model « {modele} » : attendu sonnet, opus ou haiku")
    return problemes


def verifier_commande(chemin, nom_dossier):
    problemes = []
    champs, erreurs = lire_entete(lire(chemin))
    problemes += erreurs
    if champs is None:
        return problemes
    for inconnu in sorted(set(champs) - CHAMPS_COMMANDE):
        problemes.append(f"champ inconnu « {inconnu} » (Claude Code l'ignore sans le dire)")
    nom = sans_guillemets(champs.get("name", ""))
    if not nom:
        problemes.append("name manquant")
    else:
        if nom != nom_dossier:
            problemes.append(f"name « {nom} » différent du nom du dossier « {nom_dossier} »")
        if not NOM_VALIDE.match(nom):
            problemes.append(f"name « {nom} » : lettres minuscules, chiffres et tirets seulement")
    if not sans_guillemets(champs.get("description", "")).strip():
        problemes.append("description manquante ou vide")
    return problemes


def verifier_texte(chemin):
    """Contrôles valables pour tout fichier texte : scripts cités, marque, tiret cadratin."""
    problemes = []
    for numero, ligne in enumerate(lire(chemin).split("\n"), 1):
        for script in SCRIPT_CITE.findall(ligne):
            if script not in SCRIPTS_DU_CONTRAT:
                problemes.append(
                    f"ligne {numero} : scripts/{script} n'est pas dans le contrat "
                    f"({', '.join(sorted(SCRIPTS_DU_CONTRAT))})"
                )
        if MARQUE_NINTENDO.search(ligne) and "marque" not in ligne.lower():
            problemes.append(f"ligne {numero} : mot de marque de Nintendo sans le mot « marque » sur la même ligne")
        if TIRET_CADRATIN in ligne:
            problemes.append(f"ligne {numero} : tiret cadratin (à remplacer par une virgule, un point ou deux-points)")
    return problemes


def fichiers_texte(dossier):
    for racine, _, noms in os.walk(dossier):
        for nom in sorted(noms):
            yield os.path.join(racine, nom)


def verifier(racine):
    """Rend (liste de problèmes, nombre de fichiers conformes)."""
    problemes = []
    claude = os.path.join(racine, ".claude")
    dossier_agents = os.path.join(claude, "agents")
    dossier_commandes = os.path.join(claude, "skills")
    rel = lambda p: os.path.relpath(p, racine).replace(os.sep, "/")  # noqa: E731

    agents = sorted(f for f in os.listdir(dossier_agents)) if os.path.isdir(dossier_agents) else []
    commandes = sorted(d for d in os.listdir(dossier_commandes)) if os.path.isdir(dossier_commandes) else []
    if not os.path.isdir(dossier_agents):
        problemes.append(".claude/agents : dossier absent")
    if not os.path.isdir(dossier_commandes):
        problemes.append(".claude/skills : dossier absent")

    par_fichier = {}  # chemin relatif -> liste de problèmes
    noms_agents = set()
    for f in agents:
        chemin = os.path.join(dossier_agents, f)
        if not f.endswith(".md"):
            par_fichier[rel(chemin)] = ["un agent est un fichier .md"]
            continue
        par_fichier[rel(chemin)] = verifier_agent(chemin, noms_agents)
    for d in commandes:
        dossier = os.path.join(dossier_commandes, d)
        if not os.path.isdir(dossier):
            par_fichier[rel(dossier)] = ["une commande est un dossier qui contient SKILL.md"]
            continue
        chemin = os.path.join(dossier, "SKILL.md")
        if not os.path.isfile(chemin):
            par_fichier[rel(chemin)] = ["SKILL.md manquant"]
            continue
        par_fichier[rel(chemin)] = verifier_commande(chemin, d)

    # Contrôles de texte sur tous les fichiers des deux dossiers.
    for dossier in (dossier_agents, dossier_commandes):
        if not os.path.isdir(dossier):
            continue
        for chemin in fichiers_texte(dossier):
            try:
                texte = lire(chemin)
            except (UnicodeDecodeError, OSError):
                par_fichier.setdefault(rel(chemin), []).append("fichier illisible en UTF-8")
                continue
            p = par_fichier.setdefault(rel(chemin), [])
            p += verifier_texte(chemin)
            for cite in sorted(set(AGENT_CITE.findall(texte)) - noms_agents):
                if noms_agents:
                    p.append(f"cite l'agent « {cite} » qui n'existe pas dans .claude/agents")

    for manquant in sorted(AGENTS_ATTENDUS - noms_agents):
        problemes.append(f".claude/agents/{manquant}.md : agent attendu, absent")
    for manquant in sorted(COMMANDES_ATTENDUES - set(commandes)):
        problemes.append(f".claude/skills/{manquant}/SKILL.md : commande attendue, absente")

    conformes = 0
    for chemin, liste in sorted(par_fichier.items()):
        if liste:
            problemes += [f"{chemin} : {p}" for p in liste]
        elif chemin.endswith(".md"):
            conformes += 1
    return problemes, conformes


def main(argv):
    racine = RACINE
    if len(argv) == 2 and argv[0] == "--racine":
        racine = os.path.abspath(argv[1])
    elif argv:
        print(__doc__, file=sys.stderr)
        return 2
    problemes, conformes = verifier(racine)
    if problemes:
        print("relecteurs et commandes : à corriger")
        for p in problemes:
            print(f"  - {p}")
        print(f"{len(problemes)} problème(s)")
        return 1
    print(f"relecteurs et commandes : {conformes} fichiers conformes")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
