# Blockbench on your phone (Termux)

Blockbench already ships a touch UI (it switches on automatically on phones). This
folder builds the web version locally and serves it so you can install it as an app.

## One-time

1. Install Termux from **F-Droid** or GitHub (the Play Store build is outdated and `pkg` is broken there).
2. Copy `blockbench-mobile.zip` to your phone's Downloads folder, then in Termux:

```bash
termux-setup-storage          # tap "Allow"
```

## Build + git login + run (one command)

```bash
pkg install -y unzip && cd ~ && unzip -o ~/storage/downloads/blockbench-mobile.zip && cd blockbench-mobile && bash termux/setup.sh
```

It will: install Node + git -> ask for your git name/email and log you into GitHub ->
install only the web build dependencies -> build -> start the server and open
`http://localhost:8080` in your browser.

In Chrome: menu -> **Install app** / **Add to Home screen**. After that Blockbench
works offline from the home screen without Termux running.

## Handy commands

| Command | What it does |
| --- | --- |
| `bash termux/run.sh` | Start the already-built app |
| `bash termux/run.sh --port 9000` | Use another port |
| `bash termux/git-login.sh` | Redo git identity / GitHub login only |
| `bash termux/setup.sh --no-git` | Build without the git step |
| `bash termux/setup.sh --no-serve` | Build only |
| `npm run build-mobile` | Rebuild after changing source |

`node termux/serve.mjs --host 0.0.0.0` also exposes it to other devices on your Wi-Fi
(PWA install only works from `localhost` or HTTPS, so use that only for testing).

## Git login details

`git-login.sh` uses the GitHub CLI (`gh`). Option 1 shows a one-time code and opens
github.com/login/device; option 2 takes a personal access token. Afterwards
`gh auth setup-git` makes plain `git clone/push` use that login. Nothing is stored
in this project folder.
