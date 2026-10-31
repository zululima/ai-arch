# ai-arch

Builds an Arch Linux install USB stick that starts Claude Code on boot. This file is what Claude
runs on the machine that builds the stick. `stick/CLAUDE.md` is what Claude follows on the stick.

## Build a stick

1. Run `scripts/host-info.sh`. It prints this machine's keyboard layouts, timezone and SSH public
   keys.
2. Turn the keyboard layout into two names: a Linux console keymap, such as `fi`, `us`, `uk`,
   `de-latin1` or `sv-latin1`, and an XKB layout for the desktop app and the installed desktop,
   such as `fi`, `us`, `gb`, `de` or `eu` for EurKEY. A layout the console has no keymap for,
   such as EurKEY, takes the keymap of the layout it builds on: `us` for EurKEY. Confirm the
   keyboard and the timezone with the person, one question each, recommended answer first.
3. Ask whether Claude on the stick runs in the Claude desktop app or on the console. Recommend the
   app: it gives Claude a browser, which the ArchWiki needs, and the person a window to read and
   click in. Say the cost once: each boot downloads about 280 MB, the app from Anthropic's apt
   repository and the graphics libraries; they take about 1.1 GB of RAM, and the running app
   about 1.4 GB more. Anthropic supports the app on Debian and Ubuntu only, so on Arch it runs
   unsupported. `ai-arch --console` stays as the
   fallback. If yes, pass `--desktop`, then ask how they sign in to claude.ai. With email,
   recommended, they open the sign-in link on their phone and type the code it shows into the
   app. With Google or SSO the app hands sign-in to a browser, so add `--firefox`, about 90 MB
   more per boot.
4. Ask whether the stick should carry a Claude login token, so that Claude on the stick starts
   logged in. Recommend yes: the live console cannot copy a login link, and with the desktop app
   the token keeps the console fallback logged in. Say the cost once: until the stick first
   boots, whoever holds it holds a token to the person's Claude plan, valid for a year; on first
   boot the stick moves it into RAM and erases it from itself, and `write-stick.sh` deletes the
   ISO that holds it. If yes, the person runs
   `<repo>/scripts/save-token.sh` in their own terminal: it runs `claude setup-token` and asks for
   the token without showing it. You never run it, and never read, print or copy the token file;
   pass its path, `~/.config/ai-arch/token`, to `--token-file`.
5. Ask whether they also want to log in over SSH from another device. Recommend no unless they
   bring one up. If yes, the stick has to trust that device's key: `--github-keys <user>` with
   their GitHub user (`gh api user --jq .login`) allows every key they registered on GitHub, and
   `--ssh-key <file>` allows one. A key that exists only in the SSH agent goes to a file with
   `ssh-add -L | sed -n <n>p > <scratch>/key.pub`.
6. Say that the ISO is about 1.6 GB before the first download, and ask first on a metered or
   mobile connection.
7. Run `scripts/build-iso.sh --keymap <keymap> --xkb-layout <layout> --timezone <zone>
   [--ssh-key <file>] [--github-keys <user>] [--token-file <file>] [--desktop] [--firefox]`. When it reports
   missing tools, it prints the install command: ask the person before installing anything.
8. Give the person the write step, which they run in their own terminal because it needs sudo
   and erases a disk: `<repo>/scripts/write-stick.sh <iso>`. Never run it yourself, and never run
   `dd` or anything else that writes to a disk.
9. Tell them how to boot it: the firmware's boot menu key (often F11, F12 or F8), Secure Boot off,
   since the official ISO does not support it. Once the console says it is ready, they type
   `ai-arch` at the machine, which opens the desktop app when the stick has it, or with SSH set
   up, run `ssh root@archiso.local` from the other device and type it there.

## Rules

- Ask one question at a time, with a recommended answer.
- Only macOS and Linux hosts are supported.

## Check a change

- `bash -n` and `shellcheck` on every changed script.
- `scripts/build-iso.sh --keymap us --xkb-layout us --timezone UTC --cidata-only --out <scratch>`
  builds only the CIDATA image and `user-data`; check `user-data` with
  `cloud-init schema --config-file`.
