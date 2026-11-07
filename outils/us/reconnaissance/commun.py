"""Briques communes du lot us-reco : User-Agent honnête, requêtes espacées, licences, découpe par observateur.
Aucune photo ni donnée volumineuse n'est écrite dans le dépôt (voir DONNEES)."""
import hashlib, json, os, subprocess, time, urllib.error, urllib.parse, urllib.request

UA = "FishMe-recherche/0.1 (reconnaissance de poissons, jeu d'entrainement prive ; contact b00833159@essec.edu)"
DONNEES = "/private/tmp/claude-501/us-reco"
DATASET_INAT_GBIF = "50c9509d-22c7-4a22-a47d-8c48425ef4a7"  # « iNaturalist Research-grade Observations » sur GBIF
GBIF = "https://api.gbif.org/v1"

# Classes de licence. « libre » = noyau d'entraînement clair ; « entrainement_seul » = non libre, jamais publié ni vendu.
LIBRES = {"CC0_1_0", "CC_BY_4_0", "CC_BY_3_0"}
EXCLUES = {"CC_BY_ND", "CC_BY_NC_ND"}  # on n'y touche pas (rapport especes-reconnaissance §2.1)


def code_licence(texte):
    """Normalise une licence GBIF (URL ou code) en code court ; 'INCONNUE' sinon."""
    t = (texte or "").strip().lower().rstrip("/")
    if not t:
        return "INCONNUE"
    if t.startswith("cc") and "_" in t and "/" not in t:
        return texte.strip().upper()
    if "publicdomain/zero" in t:
        return "CC0_1_0"
    if "creativecommons.org/licenses/" in t:
        part = t.split("/licenses/")[1].split("/")
        nom, ver = part[0], (part[1] if len(part) > 1 else "4.0")
        if nom.endswith("legalcode"):
            nom = nom[:-9]
        return "CC_" + nom.upper().replace("-", "_") + "_" + ver.replace(".", "_")
    return "INCONNUE"


def classe_licence(code):
    if any(code.startswith(e) for e in EXCLUES):
        return "exclue"
    if code in LIBRES:
        return "libre"
    if code == "INCONNUE":
        return "exclue"
    return "entrainement_seul"


def decoupe_observateur(observateur, graine="fishme-us-1", parts=(("train", 0.70), ("val", 0.15), ("test", 0.15))):
    """Part déterministe d'un observateur : toutes ses photos, de toutes les espèces, dans le même lot."""
    h = int(hashlib.sha256((graine + "|" + observateur).encode()).hexdigest()[:12], 16) / float(16 ** 12)
    cumul = 0.0
    for nom, p in parts:
        cumul += p
        if h < cumul:
            return nom
    return parts[-1][0]


_dernier = {}


def get(url, params=None, pause=0.6, essais=4, binaire=False, timeout=60):
    """GET poli : User-Agent honnête, une pause minimale par hôte, reprise sur 429/5xx."""
    if params:
        url += ("&" if "?" in url else "?") + urllib.parse.urlencode(params, doseq=True)
    hote = urllib.parse.urlparse(url).netloc
    for i in range(essais):
        attente = _dernier.get(hote, 0) + pause - time.time()
        if attente > 0:
            time.sleep(attente)
        _dernier[hote] = time.time()
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": UA}), timeout=timeout) as r:
                data = r.read()
            return data if binaire else json.loads(data)
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504) and i < essais - 1:
                time.sleep(5 * (i + 1))
                continue
            raise
        except (urllib.error.URLError, TimeoutError):
            if i == essais - 1:
                raise
            time.sleep(3 * (i + 1))


def dans_un_depot_git(chemin):
    d = os.path.abspath(chemin)
    while not os.path.isdir(d):
        d = os.path.dirname(d)
    return subprocess.run(["git", "-C", d, "rev-parse", "--is-inside-work-tree"], capture_output=True).returncode == 0
