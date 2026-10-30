# ai-arch

Builds an Arch Linux install USB stick that starts Claude Code on boot. This file is what Claude
runs on the machine that builds the stick. `stick/CLAUDE.md` is what Claude follows on the stick.

## Build a stick

1. Run `scripts/host-info.sh`. It prints this machine's keyboard layouts, timezone and SSH public
   keys.
2. Turn the keyboard layout into a Linux console keymap name, such as `fi`, `us`, `uk`,
   `de-latin1` or `sv-latin1`. Confirm the keymap and the timezone with the person, one question
   each, recommended answer first.
3. Ask whether the stick should carry a Claude login token, so that Claude on the stick starts
   logged in. Recommend yes: the live console cannot copy a login link. Say the cost once: until
   the stick first boots, whoever holds it holds a token to the person's Claude plan, valid for a
   year; on first boot the stick moves it into RAM and erases it from itself, and
   `write-stick.sh` deletes the ISO that holds it. If yes, the person runs
   `<repo>/scripts/save-token.sh` in their own terminal: it runs `claude setup-token` and asks for
   the token without showing it. You never run it, and never read, print or copy the token file;
   pass its path, `~/.config/ai-arch/token`, to `--token-file`.
4. Ask whether they also want to log in over SSH from another device. Recommend no unless they
   bring one up. If yes, the stick has to trust that device's key: `--github-keys <user>` with
   their GitHub user (`gh api user --jq .login`) allows every key they registered on GitHub, and
   `--ssh-key <file>` allows one. A key that exists only in the SSH agent goes to a file with
   `ssh-add -L | sed -n <n>p > <scratch>/key.pub`.
5. Say that the ISO is about 1.6 GB before the first download, and ask first on a metered or
   mobile connection.
6. Run `scripts/build-iso.sh --keymap <keymap> --timezone <zone> [--ssh-key <file>]
   [--github-keys <user>] [--token-file <file>]`. When it reports missing tools, it prints the
   install command: ask the person before installing anything.
7. Give the person the write step, which they run in their own terminal because it needs sudo
   and erases a disk: `<repo>/scripts/write-stick.sh <iso>`. Never run it yourself, and never run
   `dd` or anything else that writes to a disk.
8. Tell them how to boot it: the firmware's boot menu key (often F11, F12 or F8), Secure Boot off,
   since the official ISO does not support it. About a minute after boot, they type `ai-arch` at
   the machine, or with SSH set up, run `ssh root@archiso.local` from the other device and type it
   there.

## Rules

- Ask one question at a time, with a recommended answer.
- Only macOS and Linux hosts are supported.

## Check a change

- `bash -n` and `shellcheck` on every changed script.
- `scripts/build-iso.sh --keymap us --timezone UTC --cidata-only --out <scratch>` builds only the
  CIDATA image and `user-data`; check `user-data` with `cloud-init schema --config-file`.
