"""Utah : espèces signalées par l'agence (UT DWR).
Niveau État : liste des espèces des records de pêche (page officielle des records, noms d'espèces seulement, jamais les noms de pêcheurs).
Plan d'eau : rapport d'empoissonnement du DWR (eau, espèce, date), agrégé (espèce, eau, nombre de lâchers, année la plus récente).
Usage : python3 -I UT.py"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import commun_esp9 as C

RECORDS = "https://wildlife.utah.gov/fishing/records"
STOCK = "https://dwrapps.utah.gov/fishstocking/Fish"
AJAX = "https://dwrapps.utah.gov/fishstocking/FishAjax?y={y}&sort=watername&sortorder=ASC&sortspecific=ALL&whichSpecific=label"
ANNEES = (2024, 2025, 2026)
LIC = "non précisée"


def especes_records(html):
    """Noms d'espèces de la table des records (colonne Species), tous régimes confondus."""
    t = " ".join(C.texte_lignes(html))
    noms = []
    for m in re.finditer(r"([A-Z][A-Z]+(?:, [A-Za-z][A-Za-z ]+?)?)\*?\s+(?:\d{2}/\d{2}/)?\d{4}\s", t):
        noms.append(m.group(1).strip())
    return noms


def nom_record(n):
    """« BASS, Largemouth » -> « largemouth bass » ; « TROUT, Lake » -> « lake trout »."""
    n = n.strip().lower()
    if "," in n:
        a, b = [x.strip() for x in n.split(",", 1)]
        return f"{b} {a}"
    return n


def lignes_empoissonnement(html, annee):
    out = []
    for m in re.finditer(r'class="watername"[^>]*>(.*?)</td>\s*<td class="county"[^>]*>(.*?)</td>\s*<td class="species"[^>]*>(.*?)</td>', html, re.S):
        out.append((m.group(1).strip(), m.group(3).strip(), annee))
    return out


def main():
    sources = [
        {"nom": "Utah DWR, record fish caught in Utah (liste d'espèces)", "url": RECORDS, "licence": LIC, "date": C.DATE},
        {"nom": "Utah DWR, fish stocking reports", "url": STOCK, "licence": LIC, "date": C.DATE},
    ]
    h = C.lire(RECORDS, "ut-records.html")
    vus, entrees, inconnus = set(), [], set()
    for n in especes_records(h):
        esp = C.trouver(nom_record(n))
        if not esp:
            inconnus.add(n)
            continue
        if esp[2] in vus:
            continue
        vus.add(esp[2])
        entrees.append(C.entree(esp, "etat", "UT", "Utah", "liste_agence", 0))
    n_etat = len(entrees)
    lignes = []
    for y in ANNEES:
        lignes += lignes_empoissonnement(C.lire(AJAX.format(y=y), f"ut{y}.html"), y)
    eaux = C.agreger_empoissonnement(lignes, C.trouver, "UT", 1)
    entrees += eaux
    p, taille = C.ecrire("UT", "agence", sources, entrees)
    print(f"UT : {n_etat} espèces (État), {len(eaux)} entrées plan d'eau, {taille} octets ; ignorés (hors table) : {sorted(inconnus)}")


if __name__ == "__main__":
    main()
