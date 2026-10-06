#!/data/data/com.termux/files/usr/bin/bash
set -e

PROJECT_DIR="$HOME/emulateur_quest_3"
REPO="janintibo-art/emulateur-quest-3"

cd "$PROJECT_DIR"

if [ ! -d .git ]; then
  git init
fi

git branch -M main

git add .
if ! git diff --cached --quiet; then
  git commit -m "v1 - base emulateur Quest 3 Android"
fi

if gh repo view "$REPO" >/dev/null 2>&1; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "https://github.com/$REPO.git"
  else
    git remote add origin "https://github.com/$REPO.git"
  fi
  git push -u origin main
else
  gh repo create "$REPO" --public --source=. --remote=origin --push
fi

RUN_ID=""
for _ in $(seq 1 12); do
  RUN_ID=$(gh run list -R "$REPO" --workflow "Build APK Android" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || true)
  if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
    break
  fi
  sleep 5
done

if [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ]; then
  gh run watch "$RUN_ID" -R "$REPO"
else
  gh run list -R "$REPO" --limit 5
fi
