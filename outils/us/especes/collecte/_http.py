"""Petit client HTTP poli pour les collectes d'especes US (pause 0,25 s, User-Agent FishMe)."""
import gzip
import time
import urllib.request
import urllib.error

UA = "FishMe-data/1.0 (fishme.app@gmail.com)"
_dernier = [0.0]


def telecharger(url, timeout=40):
    """Renvoie (code, octets). Ne contourne jamais un blocage : un 403 reste un 403."""
    attente = 0.3 - (time.time() - _dernier[0])
    if attente > 0:
        time.sleep(attente)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = r.read()
            code = r.status
    except urllib.error.HTTPError as e:
        data = e.read() if hasattr(e, "read") else b""
        code = e.code
    except Exception:
        data, code = b"", 0
    if data[:2] == b"\x1f\x8b":
        try:
            data = gzip.decompress(data)
        except Exception:
            pass
    _dernier[0] = time.time()
    return code, data
