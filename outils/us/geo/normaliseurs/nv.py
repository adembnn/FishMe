"""Normaliseurs de NV (US15, groupe ouest-int) : sources fédérales (BLM, USFS, NPS)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _federal_ouest as fed  # noqa: E402


def nv_blm(f, dom=None):
    return fed.blm_rampe(f, "NV")


def nv_usfs(f, dom=None):
    return fed.usfs_site(f, "NV")


def nv_nps(f, dom=None):
    return fed.nps_poi(f, "NV")


NORMALISEURS = {"nv_blm": nv_blm, "nv_usfs": nv_usfs, "nv_nps": nv_nps}
