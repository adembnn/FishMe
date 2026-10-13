#!/usr/bin/env bash
# scripts/docteur.sh : le « docteur » de l'environnement.
#
# Il vérifie que la machine est prête et affiche une ligne par point :
#   ✓ c'est bon      ✗ à réparer (la commande de réparation est sur la ligne dessous)      · facultatif
# Il sort avec le code 1 s'il y a au moins un ✗, et avec le code 0 sinon.
# Il ne modifie rien sur la machine : il regarde seulement.
#
# Usage :   scripts/docteur.sh
# Sur Mac, il contrôle Xcode 27, le simulateur iOS 27, XcodeBuildMCP, fastlane, gh, claude, git, Python.
# Sous Linux (session cloud), il contrôle Docker, l'image swift:6.4, gh et Python.
#
# Écrit pour bash 3.2, le bash livré avec macOS.

set -u
cd "$(dirname "$0")/.." || exit 2

NB_POINTS=0
NB_KO=0

if [ -t 1 ]; then
  VERT=$'\033[32m'; ROUGE=$'\033[31m'; GRIS=$'\033[90m'; FIN=$'\033[0m'
else
  VERT=""; ROUGE=""; GRIS=""; FIN=""
fi

ok()   { NB_POINTS=$((NB_POINTS + 1)); printf '%s✓%s %s\n' "$VERT" "$FIN" "$1"; }
ko()   { NB_POINTS=$((NB_POINTS + 1)); NB_KO=$((NB_KO + 1)); printf '%s✗%s %s\n' "$ROUGE" "$FIN" "$1"; printf '    réparer : %s\n' "$2"; }
info() { printf '%s·%s %s\n' "$GRIS" "$FIN" "$1"; }
existe() { command -v "$1" >/dev/null 2>&1; }

# version_ge A B : vrai si la version A est plus récente ou égale à B (ex. 26.6.1 et 26.6).
version_ge() {
  local IFS=.
  local -a a b
  local i x y
  read -r -a a <<<"$1"
  read -r -a b <<<"$2"
  for i in 0 1 2; do
    x=${a[i]:-0}; y=${b[i]:-0}
    x=${x//[^0-9]/}; y=${y//[^0-9]/}
    [ "${x:-0}" -gt "${y:-0}" ] && return 0
    [ "${x:-0}" -lt "${y:-0}" ] && return 1
  done
  return 0
}

# Points communs aux deux systèmes -----------------------------------------------------------

verifier_python() {
  local v
  v=$(python3 --version 2>&1)
  if existe python3 && [[ "$v" == Python\ 3* ]]; then
    ok "$v"
  else
    ko "Python 3 absent" "$(existe brew && echo 'brew install python' || echo 'xcode-select --install')"
  fi
}

# Mac -----------------------------------------------------------------------------------------

verifier_mac() {
  local v xv xp rt sims tel spec npx_v fl_v

  # 1. macOS
  v=$(sw_vers -productVersion 2>/dev/null)
  if [ -n "$v" ] && version_ge "$v" 26.6; then
    ok "macOS $v (Xcode 27 demande 26.6 ou plus)"
  else
    ko "macOS ${v:-inconnu} : Xcode 27 demande 26.6 ou plus" "Réglages Système > Général > Mise à jour de logiciels"
  fi

  # 2. Puce Apple
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then
    ok "Mac à puce Apple (Xcode 27 ne marche que sur ces Mac)"
  else
    ko "Mac sans puce Apple : Xcode 27 ne s'installe pas" "utilise l'autre Mac (A ou B)"
  fi

  # 3. Xcode 27 sélectionné
  xv=$(xcodebuild -version 2>/dev/null | sed -n '1s/^Xcode //p')
  xp=$(xcode-select -p 2>/dev/null)
  if [ -z "$xv" ]; then
    ko "Xcode ne répond pas (xcode-select pointe vers : ${xp:-rien})" "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  elif [ "${xv%%.*}" != "27" ]; then
    ko "Xcode $xv est sélectionné (${xp}), il faut Xcode 27" "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  else
    ok "Xcode $xv sélectionné ($xp)"
    [ "$xv" != "27.0" ] && info "le plan fige Xcode 27.0 : ne mets pas à jour avant d'avoir demandé à A"
  fi

  # 4. Composants et licence d'Xcode
  if xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
    ok "composants et licence d'Xcode installés"
  else
    ko "Xcode n'a pas fini son installation (composants ou licence)" "sudo xcodebuild -runFirstLaunch"
  fi

  # 5. Simulateur iOS 27
  rt=$(xcrun simctl list runtimes 2>/dev/null | grep -E '^iOS 27' | grep -v unavailable | head -1)
  if [ -z "$rt" ]; then
    ko "aucun simulateur iOS 27" "xcodebuild -downloadPlatform iOS"
  else
    sims=$(xcrun simctl list devices available 2>/dev/null \
      | awk '/^-- iOS 27/ {on=1; next} /^-- / {on=0} on && /iPhone/ {sub(/ \(.*/, ""); sub(/^ +/, ""); print}' \
      | head -3 | tr '\n' ',' | sed 's/,$//; s/,/, /g')
    if [ -n "$sims" ]; then
      ok "simulateur iOS 27 présent (iPhone : $sims)"
    else
      ko "iOS 27 est installé mais aucun iPhone virtuel n'existe" "xcodebuild -downloadPlatform iOS   (puis ouvre Xcode > Window > Devices and Simulators)"
    fi
  fi

  # 6. iPhone branché (facultatif)
  tel=$(xcrun devicectl list devices 2>/dev/null | grep -i iphone | grep -E ' (connected|available) ' | head -1 | sed -E 's/  +.*//')
  if [ -n "$tel" ]; then
    ok "iPhone branché : $tel"
  else
    info "aucun iPhone branché (facultatif : branche l'iPhone de test avec le câble et appuie sur « Se fier »)"
  fi

  # 7. Pont MCP d'Xcode
  if xcrun --find mcpbridge >/dev/null 2>&1; then
    ok "pont MCP d'Xcode présent (xcrun mcpbridge)"
  else
    ko "xcrun mcpbridge introuvable (il vient avec Xcode 26.3 et plus)" "sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  fi

  # 8. XcodeBuildMCP : Node + paquet figé par .mcp.json, déjà téléchargé
  spec=$(grep -Eo 'mobilebuildmcp@[0-9][0-9.]*' .mcp.json 2>/dev/null | head -1)
  if [ -z "$spec" ]; then
    ko ".mcp.json absent ou sans serveur XcodeBuildMCP" "git pull   (le fichier vient de la branche main)"
  elif ! existe npx; then
    ko "Node.js absent : XcodeBuildMCP ne peut pas démarrer" "brew install node"
  else
    npx_v=$(cd "${TMPDIR:-/tmp}" && MOBILEBUILDMCP_SENTRY_DISABLED=true npx --offline -y "$spec" --version 2>/dev/null | tail -1)
    if [ -n "$npx_v" ]; then
      ok "XcodeBuildMCP $npx_v installé (paquet $spec)"
    else
      ko "XcodeBuildMCP ($spec) pas encore téléchargé" "npx -y $spec --version"
    fi
  fi

  # 9. fastlane (2.236 ou plus : corrige la recherche du simulateur sous iOS 26.4 et plus)
  if ! existe fastlane; then
    ko "fastlane absent" "brew install fastlane"
  else
    fl_v=$(fastlane --version 2>/dev/null | grep -E '^fastlane [0-9]+\.[0-9]+' | head -1 | awk '{print $2}')
    if [ -n "$fl_v" ] && version_ge "$fl_v" 2.236.0; then
      ok "fastlane $fl_v"
    else
      ko "fastlane ${fl_v:-(version illisible)} est trop ancien ou illisible (il faut 2.236.0 ou plus)" "brew upgrade fastlane"
    fi
  fi

  # 10. gh connecté
  if ! existe gh; then
    ko "gh absent" "brew install gh   puis   gh auth login"
  elif gh auth status >/dev/null 2>&1; then
    ok "gh connecté à GitHub"
  else
    ko "gh n'est pas connecté à GitHub" "gh auth login"
  fi

  # 11. claude présent
  if existe claude; then
    ok "claude présent ($(command -v claude))"
  else
    ko "claude absent" "curl -fsSL https://claude.ai/install.sh | bash   puis ouvre un nouveau terminal"
  fi

  # 12. Crochets de git
  if [ "$(git config core.hooksPath 2>/dev/null)" = ".githooks" ]; then
    ok "crochets de git branchés (.githooks)"
  else
    ko "crochets de git non branchés (les garde-fous ne tournent pas hors de Claude Code)" "git config core.hooksPath .githooks"
  fi

  # 13. Python 3
  verifier_python
}

# Linux (session cloud) ---------------------------------------------------------------------

verifier_linux() {
  local gv

  if ! existe docker; then
    ko "Docker absent" "scripts/cloud-pret.sh"
    ko "image swift:6.4 : impossible à vérifier sans Docker" "scripts/cloud-pret.sh"
  elif ! docker info >/dev/null 2>&1; then
    ko "Docker ne répond pas (le démon est éteint)" "scripts/cloud-pret.sh"
    ko "image swift:6.4 : impossible à vérifier tant que Docker ne répond pas" "scripts/cloud-pret.sh"
  else
    ok "Docker répond"
    if docker image inspect swift:6.4 >/dev/null 2>&1; then
      ok "image swift:6.4 présente"
    else
      ko "image swift:6.4 absente" "scripts/cloud-pret.sh"
    fi
  fi

  if existe gh; then
    gv=$(gh --version 2>/dev/null | head -1)
    ok "${gv:-gh présent}"
  else
    ko "gh absent" "scripts/cloud-pret.sh"
  fi

  verifier_python
}

# Programme principal ------------------------------------------------------------------------

SYSTEME=$(uname -s)
case "$SYSTEME" in
  Darwin) echo "Docteur : Mac"; verifier_mac ;;
  Linux)  echo "Docteur : Linux (session cloud)"; verifier_linux ;;
  *)      echo "Système non pris en charge : $SYSTEME"; exit 2 ;;
esac

echo
if [ "$NB_KO" -eq 0 ]; then
  echo "Tout est vert : $NB_POINTS points sur $NB_POINTS."
  exit 0
else
  echo "$NB_KO point(s) à réparer sur $NB_POINTS : lance les commandes « réparer » ci-dessus, puis relance scripts/docteur.sh."
  exit 1
fi
