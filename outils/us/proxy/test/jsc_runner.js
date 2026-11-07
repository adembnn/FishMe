import { cas } from "./cas.js";
let echecs = 0;
for (const [nom, f] of cas) {
  try { f(); print("ok   " + nom); } catch (e) { echecs++; print("ECHEC " + nom + " -> " + e.message); }
}
print(echecs === 0 ? `${cas.length} cas passés` : `${echecs} échec(s)`);
if (echecs) throw new Error("échecs");
