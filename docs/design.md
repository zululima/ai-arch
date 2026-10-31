# Design

## Official ISO plus a CIDATA partition

The official ISO ships cloud-init, sshd, archinstall and iwd. cloud-init reads its settings from a
FAT partition labelled `CIDATA`, which `xorriso -append_partition` adds to the ISO without
touching the rest. The ArchWiki describes the method in
[Install Arch Linux via SSH](https://wiki.archlinux.org/title/Install_Arch_Linux_via_SSH).

This keeps both parts current: each build takes the latest ISO, checked against its PGP signature,
and each boot installs the latest Claude Code with Anthropic's own installer. Nothing is
rebuilt, and no Claude Code binary is redistributed.

A custom ISO built with archiso would bake everything in, but `mkarchiso` needs an Arch host and
the result goes stale.

## Logging in to Claude on the stick

The live console has no clipboard, and a login link is too long to type, so the stick needs a way
in that skips the link.

- **A token from `claude setup-token` (default).** Claude Code documents it for machines without
  a browser: it lasts a year, can only make model requests and is read from
  `CLAUDE_CODE_OAUTH_TOKEN`. The person saves it with `scripts/save-token.sh`, so it never passes
  through Claude. The ISO that holds it is mode 600 and `write-stick.sh` deletes it after
  writing. On first boot the launcher moves the token from the stick into RAM and removes it from
  the stick. Until then, anyone holding the stick holds the token.
- **Over SSH from another device (optional).** The stick trusts the SSH keys chosen at build time,
  from a file or from `github.com/<user>.keys`, so `ssh root@archiso.local` works from those
  devices on the same network, and the login link can be copied there.
- **Copying `~/.claude/.credentials.json`** is not offered. It is a full login rather than a token
  for model requests only, Claude Code manages it through `/login` and `/logout` only, and macOS
  keeps it in the Keychain instead. Two machines holding one login may also log each other out
  when one of them refreshes it; that is not checked.
- **The desktop app (optional).** The app signs in on its own, in its window; see below. The
  ISO's text browser, lynx, cannot run the JavaScript that the claude.ai login page needs.

## The desktop app on the stick

With `--desktop`, the stick runs Claude in Anthropic's desktop app instead of on the console. It
gives Claude a browser, which the ArchWiki needs, since it answers plain downloads with a bot
check. Nothing of it reaches the installed system.

- **Source.** Anthropic publishes the app for Debian and Ubuntu only and sends Arch users to the
  CLI, so on Arch it runs unsupported. The stick takes the newest `.deb` from Anthropic's apt
  repository and checks it the way apt does: `InRelease` signed by the key the docs pin, then
  `Packages` and the `.deb` by sha256. It unpacks the files with `bsdtar` and installs the
  libraries the package depends on with pacman, leaving out the virtual machine that only Cowork
  uses. The AUR package `claude-desktop` does the same repackaging, but building it would need
  `base-devel` in RAM on every boot.
- **Display.** No desktop environment: cage, a small Wayland kiosk compositor, shows the app
  full screen. The app refuses to run as root, so a systemd unit starts cage as the user
  `claude` on tty7 with a PAM session, as cage's wiki describes. That user has sudo without a
  password, since the install needs root. `cage -s` lets Ctrl+Alt+F1 and Ctrl+Alt+F2 reach the
  consoles. cage takes the keyboard layout from `XKB_DEFAULT_LAYOUT`, set from `--xkb-layout`,
  since a layout such as EurKEY has no console keymap to follow.
- **Sign-in.** The token from `setup-token` only works for the CLI, so the app signs in itself on
  every boot; with no keyring it keeps the sign-in until the app closes. With email, a
  third-party guide says the sign-in link opened on another device shows a code to type into the
  app; that is not checked. Google and SSO open a browser, so `--firefox` adds Firefox.
- **Cost.** In an amd64 Arch container, the app and its libraries were 122 MB of packages and a
  161 MB `.deb`, took about 1.1 GB once unpacked, and the running app about 1.4 GB more. The
  ISO already has some of those libraries.
- **Tested.** In that container, the prepare step installed and verified the app, and cage on a
  headless output showed its start screen. Docker blocks the app's sandbox, so that test ran
  with `--no-sandbox`; the stick runs with the sandbox. The systemd unit, the VT switch and the
  sign-in have not run.

## Memory

The live system keeps changes in a RAM disk of 256 MB by default (`cow_spacesize` in
mkinitcpio-archiso), and Claude Code alone takes about 260 MB. cloud-init grows that RAM disk to
75% of the machine's memory before installing Claude Code. Nothing persists between boots: each
boot installs Claude Code again and asks for a login again.

## Rough edges

- Windows cannot build a stick: it has no `dd`, and Claude Code's shell there cannot write a raw
  disk.
- The official ISO does not boot with Secure Boot on.
- Wi-Fi passwords are typed on the stick with `iwctl`, never copied from the build machine.
- A full boot of a stick has not been tested yet.
