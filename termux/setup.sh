#!/data/data/com.termux/files/usr/bin/bash
# One-shot Termux setup: packages -> git login -> dependencies -> build -> serve.
#   bash termux/setup.sh              everything
#   bash termux/setup.sh --no-git     skip the git login step
#   bash termux/setup.sh --no-serve   build only
#   bash termux/setup.sh --port 9000  serve on another port
set -e
cd "$(dirname "$0")/.."

GIT=1; SERVE=1; PORT=8080
while [ $# -gt 0 ]; do
	case "$1" in
		--no-git) GIT=0 ;;
		--no-serve) SERVE=0 ;;
		--port) PORT="$2"; shift ;;
		*) echo "Unknown option: $1"; exit 1 ;;
	esac
	shift
done

echo "==> [1/4] Installing Termux packages (nodejs, npm, git)"
install_pkgs() { pkg install -y nodejs npm git; }
pkg update -y || true
if ! install_pkgs; then
	# Seen on Termux: dpkg loses a downloaded .deb mid-install ("cannot access archive ... No such file").
	# Clean the apt cache, finish half-installed packages, and try again.
	echo "Package install failed - cleaning up and retrying once..."
	mkdir -p "$PREFIX/tmp" "$HOME/../cache/apt" 2>/dev/null || true
	apt clean || true
	dpkg --configure -a || true
	apt --fix-broken install -y || true
	pkg update -y || true
	if ! install_pkgs; then
		echo
		echo "Still failing. Check free space ('df -h \$PREFIX'), try 'termux-change-repo' to pick another mirror,"
		echo "then run this script again."
		exit 1
	fi
fi

NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
if [ "$NODE_MAJOR" -lt 20 ]; then
	echo "Node $NODE_MAJOR is too old, Blockbench needs Node 20+. Run: pkg upgrade nodejs"; exit 1
fi

if [ "$GIT" = 1 ]; then
	echo "==> [2/4] Git login"
	bash termux/git-login.sh
else
	echo "==> [2/4] Git login skipped"
fi

echo "==> [3/4] Installing web build dependencies (skips Electron etc.)"
node termux/install-deps.mjs

if ! node --input-type=module -e "const e = await import('esbuild'); await e.transform('1', {})" 2>/dev/null; then
	echo "esbuild could not start on this device (platform: $(node -p 'process.platform+"-"+process.arch'))."
	echo "Try:  rm -rf node_modules && node termux/install-deps.mjs   and re-run this script."
	exit 1
fi

echo "==> [4/4] Building Blockbench (web) + offline service worker"
node build.js --target=web
node scripts/generate_pwa.js || echo "(!) Service worker generation failed - the app works, but not offline/installable until fixed."

echo
echo "Build finished."
if [ "$SERVE" = 1 ]; then
	command -v termux-wake-lock >/dev/null && termux-wake-lock || true
	( sleep 2; command -v termux-open-url >/dev/null && termux-open-url "http://localhost:$PORT" ) >/dev/null 2>&1 &
	exec node termux/serve.mjs --port "$PORT"
else
	echo "Start it later with:  bash termux/run.sh"
fi
