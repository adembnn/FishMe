#!/bin/sh
# Xcode Cloud : après le clonage, installer XcodeGen et générer le projet. NON TESTÉ (jamais exécuté).
# Le fichier doit être exécutable dans Git : git update-index --chmod=+x ci_scripts/ci_post_clone.sh
set -e
cd "$CI_PRIMARY_REPOSITORY_PATH"
brew install xcodegen
xcodegen generate
