// Lancer : node --test   (depuis outils/us/proxy). Sans node : python3 banc.py
import test from "node:test";
import { cas } from "./cas.js";

for (const [nom, f] of cas) test(nom, f);
