# ai-arch

Builds an Arch Linux install USB stick that starts Claude Code on boot. This file is what Claude
runs on the machine that builds the stick. `stick/CLAUDE.md` is what Claude follows on the stick.

## Build a stick

1. Run `scripts/host-info.sh`. It prints this machine's keyboard layouts, timezone and SSH public
   keys.
2. Turn the keyboard layout into a Linux console keymap name, such as `fi`, `us`, `uk`,
   `de-latin1` or `sv-latin1`. Confirm the keymap and the timezone with the person, one question
   each, recommended answer first.
3. Ask which device they will log in from over SSH, since the stick has to trust that device's
   key. When this machine is the one being reinstalled, its own key goes with the reinstall, so
   recommend `--github-keys <user>` with their GitHub user (`gh api user --jq .login`): it allows
   every key they registered on GitHub. A key of this machine that exists only in the SSH agent
   goes to a file with `ssh-add -L | sed -n <n>p > <scratch>/key.pub`. Without any key, logging in
   from another device needs a root password that the person sets on the stick with `passwd`.
4. Ask whether the stick should carry a Claude login token. Recommend no: anyone holding the stick
   before its first boot can use the person's Claude plan for up to a year. Logging in over SSH
   from another device needs no token. If they want one, they run `claude setup-token` and then
   `scripts/save-token.sh` in their own terminal. You never run either, and never read, print or
   copy the token file; pass its path to `--token-file`.
5. Say that the ISO is about 1.6 GB before the first download, and ask first on a metered or
   mobile connection.
6. Run `scripts/build-iso.sh --keymap <keymap> --timezone <zone> [--ssh-key <file>]
   [--github-keys <user>] [--token-file <file>]`. When it reports missing tools, it prints the
   install command: ask the person before installing anything.
7. Give the person the write step, which they run in their own terminal because it needs sudo
   and erases a disk: `<repo>/scripts/write-stick.sh <iso>`. Never run it yourself, and never run
   `dd` or anything else that writes to a disk.
8. Tell them how to boot it: the firmware's boot menu key (often F11, F12 or F8), Secure Boot off,
   since the official ISO does not support it. About a minute after boot, they run
   `ssh root@archiso.local` from the other device and type `ai-arch`, or type `ai-arch` at the
   machine itself.

## Rules

- Ask one question at a time, with a recommended answer.
- Only macOS and Linux hosts are supported.

## Check a change

- `bash -n` and `shellcheck` on every changed script.
- `scripts/build-iso.sh --keymap us --timezone UTC --cidata-only --out <scratch>` builds only the
  CIDATA image and `user-data`; check `user-data` with `cloud-init schema --config-file`.
