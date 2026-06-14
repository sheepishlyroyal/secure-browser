#!/bin/bash
# Bring the desktop up and expose it via a Cloudflare quick tunnel — NO GitHub port
# forwarding (which needs port-visibility perms a fork's codespace token doesn't have).
# cloudflared makes an OUTBOUND connection, so it works on any fork. We then publish the
# tunnel URL into THIS repo (.lintoria-tunnel), tagged with the codespace name, so the
# frontend can pick it up (and ignore a stale URL from a previous boot).
set +e
cd "$(dirname "$0")/.." || exit 0

# 1. start the streamed desktop (KasmVNC on :3000)
docker compose -f .devcontainer/docker-compose.yml up -d

# 2. install cloudflared if needed
if ! command -v cloudflared >/dev/null 2>&1; then
  curl -fsSL -o /tmp/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
  sudo install /tmp/cloudflared /usr/local/bin/cloudflared
fi

# 3. open the tunnel to the desktop and capture its public URL
nohup cloudflared tunnel --no-autoupdate --url http://localhost:3000 > /tmp/cf.log 2>&1 &
URL=""
for i in $(seq 1 90); do
  URL=$(grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf.log | head -1)
  [ -n "$URL" ] && break
  sleep 2
done
[ -z "$URL" ] && { echo "no tunnel url after 3 min"; exit 0; }
echo "tunnel: $URL"

# 4. publish {codespace name, url} into this repo so the frontend can read it
publish() {
  local payload b64 sha
  payload=$(printf '{"name":"%s","url":"%s"}' "$CODESPACE_NAME" "$1")
  b64=$(printf '%s' "$payload" | base64 | tr -d '\n')
  sha=$(gh api "repos/$GITHUB_REPOSITORY/contents/.lintoria-tunnel" --jq .sha 2>/dev/null)
  if [ -n "$sha" ]; then
    gh api "repos/$GITHUB_REPOSITORY/contents/.lintoria-tunnel" -X PUT -f message="tunnel" -f content="$b64" -f sha="$sha" >/dev/null 2>&1
  else
    gh api "repos/$GITHUB_REPOSITORY/contents/.lintoria-tunnel" -X PUT -f message="tunnel" -f content="$b64" >/dev/null 2>&1
  fi
}
publish "$URL"
echo "published"

# 5. if cloudflared reconnects with a new URL, re-publish it
LAST="$URL"
while true; do
  sleep 30
  CUR=$(grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/cf.log | tail -1)
  if [ -n "$CUR" ] && [ "$CUR" != "$LAST" ]; then LAST="$CUR"; publish "$CUR"; echo "re-published $CUR"; fi
done
