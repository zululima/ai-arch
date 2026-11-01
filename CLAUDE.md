# ai-arch

Builds an Arch Linux install USB stick that opens the Claude desktop app on boot. This file is
what Claude runs on the machine that builds the stick. `stick/CLAUDE.md` is what Claude follows on
the stick.

## Build a stick

1. Run `scripts/host-info.sh`, which prints this machine's keyboard layouts, timezone and SSH
   public keys, and `scripts/build-iso.sh --check-tools`. When a build tool is missing, it prints
   the install command, which needs sudo: ask before the person runs it in their own terminal.
2. Ask which keyboard layout the stick should use, recommending the one `host-info.sh` found,
   then ask whether the timezone it detected is right. Turn the layout into two names: a Linux
   console keymap, such as `fi`, `us`, `uk`, `de-latin1` or `sv-latin1`, and an XKB layout for
   the desktop app and the installed desktop, such as `fi`, `us`, `gb`, `de` or `eu` for EurKEY.
   A layout the console has no keymap for, such as EurKEY, takes the keymap of the layout it
   builds on: `us` for EurKEY.
3. Say that the ISO is about 1.6 GB before the first download, and ask first on a metered or
   mobile connection.
4. Run `scripts/build-iso.sh --keymap <keymap> --xkb-layout <layout> --timezone <zone>`, with an
   option below only when the person asks for what it gives.
5. Give the person the write step, which they run in their own terminal because it needs sudo
   and erases a disk: `<repo>/scripts/write-stick.sh <iso>`. Never run it yourself, and never run
   `dd` or anything else that writes to a disk.
6. Tell them how it goes on the stick. They boot it with the firmware's boot menu key (often
   F11, F12 or F8) and Secure Boot off, since the official ISO does not support it, with a network
   cable in. The stick installs the Claude desktop app, a few minutes, and opens it. They sign in
   by email, open the Code tab and say "install arch". Without a network at boot, they connect
   on the console, with `iwctl` for Wi-Fi, and type `ai-arch`.

## Options

- `--firefox` puts Firefox on the stick, about 90 MB more per boot, for a person who signs in to
  claude.ai with Google or SSO: the app hands that sign-in to a browser.
- `--token-file ~/.config/ai-arch/token` logs Claude Code in on the console, the fallback when the
  app fails, where a login link cannot be copied. The person runs
  `<repo>/scripts/save-token.sh` in their own terminal: it runs `claude setup-token`, asks for
  the token without showing it, and offers a passphrase, which the stick asks for before Claude
  uses the token. You never run it, and never read, print or copy the token file. Without a
  passphrase, whoever holds the stick before its first boot holds a token to the person's Claude
  plan, valid for a year; on first boot the stick moves it into RAM and erases it from itself,
  `write-stick.sh` deletes the ISO that holds it, and Claude on the stick has the person revoke
  it.
- `--github-keys <user>` or `--ssh-key <file>` let another device log in to the stick over SSH:
  the first allows every key the GitHub user registered (`gh api user --jq .login`), the second
  one key. A key that exists only in the SSH agent goes to a file with
  `ssh-add -L | sed -n <n>p > <scratch>/key.pub`.

## Rules

- Ask one question at a time, with a recommended answer.
- Only macOS and Linux hosts are supported.

## Check a change

- `bash -n` and `shellcheck` on every changed script.
- `scripts/build-iso.sh --keymap us --xkb-layout us --timezone UTC --cidata-only --out <scratch>`
  builds only the CIDATA image and `user-data`; check `user-data` with
  `cloud-init schema --config-file`.
