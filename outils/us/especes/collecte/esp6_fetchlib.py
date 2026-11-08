"""Outils communs de collecte US16 (agence) : GET poli, cache hors git."""
import os, time, urllib.request, urllib.error, hashlib
UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
BRUT = "/private/tmp/claude-501/brut-us/especes"
_dernier = [0.0]


def get(url, cache=True, timeout=40):
    """Retourne (code, texte). Pause >= 0,25 s. Jamais de contournement : 403 reste 403."""
    os.makedirs(BRUT, exist_ok=True)
    f = os.path.join(BRUT, hashlib.md5(url.encode()).hexdigest() + ".txt")
    if cache and os.path.exists(f):
        return 200, open(f, encoding="utf-8").read()
    d = time.time() - _dernier[0]
    if d < 0.3:
        time.sleep(0.3 - d)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            t = r.read().decode("utf-8", "replace")
            code = r.status
    except urllib.error.HTTPError as e:
        code, t = e.code, ""
    except Exception:
        code, t = 0, ""
    _dernier[0] = time.time()
    if code == 200 and cache:
        open(f, "w", encoding="utf-8").write(t)
    return code, t
