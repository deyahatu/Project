#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
#  push.sh — automate staging, committing, and pushing changes to GitHub
#
#  Usage:
#    ./push.sh "Commit message here"
#    ./push.sh                       # uses a default timestamped message
#
#  The script:
#    1. Verifies it is inside a git repository
#    2. Shows what is about to be committed
#    3. Stages everything, commits, and pushes to the current branch
#    4. Aborts gracefully if there is nothing to commit
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# Move to the script's directory so the script works from anywhere
cd "$(dirname "$0")"

# 1. Make sure we are inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: not inside a git repository."
    echo "Run 'git init && git remote add origin <url>' first."
    exit 1
fi

# 2. Determine commit message
if [ "$#" -ge 1 ] && [ -n "$1" ]; then
    MESSAGE="$1"
else
    MESSAGE="auto: update at $(date '+%Y-%m-%d %H:%M:%S')"
fi

# 3. Show identity that will appear on the commit
AUTHOR_NAME="$(git config user.name || echo 'unset')"
AUTHOR_EMAIL="$(git config user.email || echo 'unset')"
echo "Committing as: ${AUTHOR_NAME} <${AUTHOR_EMAIL}>"

# 4. Show changes
echo "Working tree status:"
git status --short

# 5. Stage everything
git add -A

# 6. Bail out cleanly if nothing changed
if git diff --cached --quiet; then
    echo "Nothing to commit. Working tree clean."
    exit 0
fi

# 7. Commit
git commit -m "${MESSAGE}"

# 8. Determine current branch and push
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Set upstream automatically the first time
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
    git push
else
    echo "No upstream set — pushing with -u origin ${BRANCH}"
    git push -u origin "${BRANCH}"
fi

echo "Push complete on branch '${BRANCH}'."
