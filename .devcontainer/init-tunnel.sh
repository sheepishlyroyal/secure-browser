#!/bin/bash
# Runs FOREGROUND from postStartCommand. Do NOT background this — the lifecycle runner kills
# backgrounded children when it exits (that was the bug: nothing ever ran). The desktop and
# the Cloudflare tunnel are docker CONTAINERS, so they keep running via dockerd after this
# script returns. We bring them up, read the tunnel URL from the cloudflared container's
# logs, and publish it into this repo so the frontend can pick it up.
set +e
exec > /tmp/init-tunnel.log 2>&1
set -x
cd "$(dirname "$0")/.." || exit 0

REPO=$(git remote get-url origin 2>/dev/null | sed -E 's#.*github\.com[:/]+([^/]+/[^/.]+)(\.git)?$#\1#')
[ -z "$REPO" ] && REPO="$GITHUB_REPOSITORY"
echo "REPO=$REPO CS=$CODESPACE_NAME token=$([ -n "$GITHUB_TOKEN" ] && echo set || echo MISSING)"

docker compose -f .devcontainer/docker-compose.yml up -d

URL=""
for i in $(seq 1 80); do
  URL=$(docker compose -f .devcontainer/docker-compose.yml logs tunnel 2>/dev/null | grep -ohE 'https://[a-z0-9-]+\.trycloudflare\.com' | head -1)
  [ -n "$URL" ] && break
  sleep 3
done
echo "URL=$URL"
[ -z "$URL" ] && exit 0

CONTENT=$(printf '{"name":"%s","url":"%s"}' "$CODESPACE_NAME" "$URL" | base64 | tr -d '\n')
SHA=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/contents/.lintoria-tunnel" | grep -o '"sha": *"[0-9a-f]*"' | head -1 | grep -o '[0-9a-f]\{40\}')
if [ -n "$SHA" ]; then
  curl -s -o /dev/null -w "publish %{http_code}\n" -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/contents/.lintoria-tunnel" -d "$(printf '{"message":"tunnel","content":"%s","sha":"%s"}' "$CONTENT" "$SHA")"
else
  curl -s -o /dev/null -w "publish %{http_code}\n" -X PUT -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/contents/.lintoria-tunnel" -d "$(printf '{"message":"tunnel","content":"%s"}' "$CONTENT")"
fi
echo "done"
