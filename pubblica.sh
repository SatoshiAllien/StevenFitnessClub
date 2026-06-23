#!/bin/bash
set -e

export PATH="/home/workbench/.local/bin:$PATH"
cd "$(dirname "$0")"

REPO_NAME="StevenFitnessClub"

echo "=== Pubblicazione StevenFitnessClub (app + sito) ==="

if ! gh auth status &>/dev/null; then
  echo "Autenticazione GitHub richiesta..."
  gh auth login -h github.com -p https -w
fi

echo "Push su GitHub..."
git push -u origin main

echo "Abilitazione GitHub Pages..."
gh api "repos/{owner}/$REPO_NAME/pages" -X POST -f build_type=workflow 2>/dev/null || \
  gh api "repos/{owner}/$REPO_NAME/pages" -X PUT -f build_type=workflow 2>/dev/null || true

OWNER=$(gh api user -q .login)
echo ""
echo "✓ Pubblicato!"
echo "  Repository:  https://github.com/$OWNER/$REPO_NAME"
echo "  Sito web:      https://$OWNER.github.io/$REPO_NAME/"
echo "  Release app:   https://github.com/$OWNER/$REPO_NAME/releases"
echo ""
echo "Attendi 1-2 minuti per il deploy del sito."