#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write) : met en forme les fichiers .swift avec `swift format`.
# Sans `swift` (cloud Linux), il ne fait rien. Jamais bloquant : sort toujours 0.
# Entrée : le JSON de Claude Code sur l'entrée standard (champ tool_input.file_path).

command -v swift >/dev/null 2>&1 || exit 0
chemin=$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")' 2>/dev/null) || exit 0
case "$chemin" in
  *.swift) ;;
  *) exit 0 ;;
esac
[ -f "$chemin" ] || exit 0
swift format --in-place "$chemin" >/dev/null 2>&1
exit 0
