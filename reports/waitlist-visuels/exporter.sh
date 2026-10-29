#!/bin/bash
# Exporte couverture.html en PNG (1170 x 990), l'image de couverture de la page d'attente.
cd "$(dirname "$0")"
for n in couverture; do
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
    --allow-file-access-from-files --force-device-scale-factor=3 --window-size=390,330 --virtual-time-budget=6000 \
    --screenshot="$PWD/$n.png" "file://$PWD/$n.html" >/dev/null 2>&1
done
sips -s format jpeg -s formatOptions 86 "$PWD/couverture.png" --out "$PWD/couverture.jpg" >/dev/null
