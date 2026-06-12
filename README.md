# secure-browser

A real **Chromium** running in a GitHub Codespace, reachable from your browser — so
sites that block the Lintoria proxy (ChatGPT, Google sign-in, YouTube login) work
normally, because this *is* a real browser on the real origin.

## Use it
1. Click **Code ▸ Codespaces ▸ Create codespace on main** (or the badge below).
2. Wait ~1–2 min for it to build and for Chromium to start.
3. When **port 3000** forwards, open it (Ports tab ▸ the globe icon, or the popup).
4. You get a full Chromium in the page — log into ChatGPT/Google as normal.

Your logins persist in `./config` for the life of the codespace.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/sheepishlyroyal/secure-browser)

## Notes
- Codespaces is free up to ~60 core-hours/month and **idle-stops after ~30 min** —
  it's a spin-up-when-you-need-it tool, not always-on. Stop it from the Codespaces
  page when done to save hours.
- Linux only (no Windows — Codespaces can't run a Windows desktop).
- Google may ask "verify it's you" once because the IP is a datacenter; complete it
  and you're in.
