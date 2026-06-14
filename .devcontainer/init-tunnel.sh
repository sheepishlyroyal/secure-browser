#!/bin/bash
# Expose the desktop via a Cloudflare quick tunnel — NO GitHub port forwarding (works on
# any fork). Order matters: start the tunnel and PUBLISH its URL FIRST (fast), THEN bring
# up the heavy desktop image — so the frontend gets the URL in ~1 min instead of waiting
# out the multi-minute docker pull. The URL serves 502 until the desktop is up.
set +e
exec > /tmp/init-tunnel.log 2>&1   # everything to a log we can read over ssh
set -x
cd "$(dirname "$0")/.." || exit 0

# don't double-run if a previous hook already started it
if pgrep -x cloudflared >/dev/null 2>&1; then echo "already running"; exit 0; fi

REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
[ -z "$REPO" ] && REPO="$GITHUB_REPOSITORY"
echo "REPO=$REPO CODESPACE_NAME=$CODESPACE_NAME"
gh auth status

# 1. install cloudflared
if ! command -v cloudflared >/dev/null 2>&1; then
  curl -fsSL -o /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  sudo install /tmp/cloudflared /usr/local/bin/cloudflared
fi

# 2. open the tunnel and capture its URL
nohup cloudflared tunnel --no-autoupdate --url http://localhost:3000 > /tmp/cf.log 2>&1 &
URL=""
for i in $(seq 1 60); do
  URL=$(grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf.log | head -1)
  [ -n "$URL" ] && break
  sleep 2
done
echo "URL=$URL"

# 3. publish {codespace name, url} into this repo so the frontend can read it
publish() {
  local payload b64 sha
  payload=$(printf '{"name":"%s","url":"%s"}' "$CODESPACE_NAME" "$1")
  b64=$(printf '%s' "$payload" | base64 | tr -d '\n')
  sha=$(gh api "repos/$REPO/contents/.lintoria-tunnel" --jq .sha 2>/dev/null)
  if [ -n "$sha" ]; then
    gh api "repos/$REPO/contents/.lintoria-tunnel" -X PUT -f message="tunnel" -f content="$b64" -f sha="$sha"
  else
    gh api "repos/$REPO/contents/.lintoria-tunnel" -X PUT -f message="tunnel" -f content="$b64"
  fi
}
[ -n "$URL" ] && publish "$URL"
echo "published rc=$?"

# 4. NOW bring up the streamed desktop (slow first pull; the tunnel 502s until it's up)
docker compose -f .devcontainer/docker-compose.yml up -d
echo "compose rc=$?"
