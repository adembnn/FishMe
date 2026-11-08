"""Normaliseurs d'AZ (US15, groupe ouest-int) : sources fédérales (BLM, USFS, NPS)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import _federal_ouest as fed  # noqa: E402


def az_blm(f, dom=None):
    return fed.blm_rampe(f, "AZ")


def az_usfs(f, dom=None):
    return fed.usfs_site(f, "AZ")


def az_nps(f, dom=None):
    return fed.nps_poi(f, "AZ")


NORMALISEURS = {"az_blm": az_blm, "az_usfs": az_usfs, "az_nps": az_nps}
