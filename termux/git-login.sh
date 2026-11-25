#!/data/data/com.termux/files/usr/bin/bash
# Sets up git + GitHub login in Termux.
#   bash termux/git-login.sh
# Installs git/gh, stores your commit name+email, signs in to GitHub (device code
# in the browser, or a pasted personal access token) and wires gh in as git's
# credential helper so `git push` / `git clone` of private repos just work.
set -e

ask() { # ask "Prompt" VAR [default]
	local reply
	read -r -p "$1${3:+ [$3]}: " reply </dev/tty
	printf -v "$2" '%s' "${reply:-$3}"
}

echo "==> Installing git, GitHub CLI and openssh"
pkg install -y git gh openssh >/dev/null

echo "==> Git identity"
ask "Name for commits" GIT_NAME "$(git config --global user.name || true)"
ask "Email for commits" GIT_EMAIL "$(git config --global user.email || true)"
[ -n "$GIT_NAME" ]  && git config --global user.name "$GIT_NAME"
[ -n "$GIT_EMAIL" ] && git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main

echo "==> GitHub login"
if gh auth status >/dev/null 2>&1; then
	echo "Already logged in to GitHub:"
	gh auth status 2>&1 | sed 's/^/    /'
else
	echo "  1) Browser / one-time code (recommended)"
	echo "  2) Paste a personal access token"
	ask "Choose" METHOD 1
	if [ "$METHOD" = "2" ]; then
		echo "Create a token at https://github.com/settings/tokens (scopes: repo, read:org)."
		read -r -s -p "Token (hidden): " TOKEN </dev/tty; echo
		printf '%s' "$TOKEN" | gh auth login --hostname github.com --git-protocol https --with-token
		unset TOKEN
	else
		# gh prints a one-time code, then opens github.com/login/device in your phone browser
		export GH_BROWSER=termux-open-url BROWSER=termux-open-url
		gh auth login --hostname github.com --git-protocol https --web
	fi
fi

gh auth setup-git
echo "==> Logged in as: $(gh api user --jq .login 2>/dev/null || echo '?')"

# Offer to turn this folder into a repo and push it
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -d "$PROJECT_DIR/.git" ]; then
	ask "Push this project to a GitHub repo now? Paste the repo URL (empty = skip)" REMOTE ""
	if [ -n "$REMOTE" ]; then
		cd "$PROJECT_DIR"
		git init -q -b main
		git add -A
		git commit -q -m "Blockbench mobile build" || true
		git remote add origin "$REMOTE"
		git push -u origin main
	fi
fi
echo "Git login done."
