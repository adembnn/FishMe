"""Kentucky Fish and Wildlife (KDFWR) : Ky_Fish_Wildlife_WGS84WM, couches 0 (tout bateau), 1 (petits bateaux, portage), 2 (pêche depuis la rive).
Champs « Directions » et « Notes » jamais copiés."""


def _txt(v):
    s = str(v).strip() if v is not None else ""
    return s or None


def _faire(prefixe, fixe=None, table=None):
    def norm(f, dom=None):
        p = f["properties"]
        ident = p.get("ASID")
        if ident is None or p.get("display") == 0:
            return None
        t = fixe or (table or {}).get(_txt(p.get("Type")) or "", "acces")
        pr = {"id": f"{prefixe}:{ident}", "nom": _txt(p.get("SiteName")) or _txt(p.get("NAME")), "type": t,
              "coin": "peche" if t == "peche_rive" else "acces", "eau": _txt(p.get("WaterBody"))}
        return {"type": "Feature", "geometry": f["geometry"], "properties": {k: v for k, v in pr.items() if v is not None}}
    return norm


NORMALISEURS = {"acces_ky_bateau": _faire("ky-boat", "rampe"),
                "acces_ky_petit": _faire("ky-small", table={"Carrydown Only": "acces_portage", "Small Boat Only": "rampe"}),
                "acces_ky_rive": _faire("ky-bank", "peche_rive")}
