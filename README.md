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

## Connect it to Lintoria (the "Secure browser" search source)

Lintoria can spin this up for you. Pick **Secure browser ★** in the search-source
dropdown, then **Connect GitHub** once with a token:

1. Go to **GitHub ▸ Settings ▸ Developer settings ▸ Personal access tokens ▸
   Fine-grained tokens ▸ Generate new token**.
2. **Expiration:** choose **No expiration** (or **90 days**). The token is used *every*
   time you open, restart, or check the browser — a short expiry makes the secure
   browser silently stop working. If yours ever lapses, just use **update token** in
   the dropdown to paste a new one.
3. **Repository access:** *Only select repositories* → `secure-browser` (or *All*).
4. **Permissions ▸ Repository ▸ Codespaces: Read and write.**
5. Generate, copy the token, paste it into Lintoria's **Connect GitHub** prompt.

The token is stored encrypted, per-user. Lintoria never shows it again; replace it
anytime with **update token**.
