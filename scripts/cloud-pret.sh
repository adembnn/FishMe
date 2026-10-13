#!/usr/bin/env bash
# Cloud (Linux sans Swift) : prépare Docker et l'image Swift, pour que scripts/verif.sh puisse lancer swift test.
# Idempotent : si tout est prêt, il ne dit rien. Lancé en arrière-plan par le hook de démarrage de session.
# Sur Mac, ou avec Swift installé : rien à faire.

IMAGE="${IMAGE_SWIFT:-swift:6.4}"
JOURNAL="${ATELIER_JOURNAL_DOCKERD:-/tmp/atelier-dockerd.log}"

[ "$(uname -s)" = "Linux" ] || exit 0
command -v swift >/dev/null 2>&1 && exit 0

if ! command -v docker >/dev/null 2>&1; then
  echo "✗ Docker n'est pas installé dans ce cloud : impossible de lancer swift test." >&2
  exit 1
fi

# Un seul cloud-pret à la fois (la session peut le lancer plusieurs fois de suite).
# Le verrou (descripteur 9) n'est pas transmis à dockerd, sinon il ne se libérerait jamais.
if command -v flock >/dev/null 2>&1; then
  exec 9>/tmp/atelier-cloud-pret.lock
  flock 9
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker ne répond pas : je le démarre (journal : $JOURNAL)."
  if [ "$(id -u)" -eq 0 ] || ! command -v sudo >/dev/null 2>&1; then
    dockerd >"$JOURNAL" 2>&1 9>&- &
  else
    sudo dockerd >"$JOURNAL" 2>&1 9>&- &
  fi
  for _ in $(seq 1 60); do
    docker info >/dev/null 2>&1 && break
    sleep 1
  done
  if ! docker info >/dev/null 2>&1; then
    echo "✗ Docker ne répond toujours pas après 60 s. À faire : lis $JOURNAL, puis relance scripts/cloud-pret.sh." >&2
    exit 1
  fi
fi

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Je télécharge l'image $IMAGE (une seule fois, quelques minutes)."
  docker pull "$IMAGE" || { echo "✗ Le téléchargement de $IMAGE a échoué. À faire : relance scripts/cloud-pret.sh." >&2; exit 1; }
fi
exit 0
