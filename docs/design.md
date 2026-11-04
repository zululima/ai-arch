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

The stick runs Claude in Anthropic's desktop app, which signs in in its own window: by email, or
with Google or SSO through Chrome. Claude Code on the console is the
fallback when the app fails, and it needs a way in that skips the login link, since the console
has no clipboard and the link is too long to type.

- **A token from `claude setup-token` (optional).** Claude Code documents it for machines without
  a browser: it lasts a year, can only make model requests and is read from
  `CLAUDE_CODE_OAUTH_TOKEN`. The person saves it with `scripts/save-token.sh`, so it never passes
  through Claude. The ISO that holds it is mode 600 and `write-stick.sh` deletes it after
  writing. On first boot the launcher moves the token from the stick into RAM and removes it from
  the stick. Until then, anyone holding the stick holds the token, unless the person gave
  `save-token.sh` a passphrase: then it is gpg's symmetric encryption, and `ai-arch` asks for the
  passphrase before Claude Code uses it. The CIDATA partition itself cannot be encrypted, since
  cloud-init reads it at boot before anyone can type. Claude on the stick has the person revoke
  the token in claude.ai's settings once it is no longer needed: right after the desktop app
  signs in, or at the end of a console install.
- **Over SSH from another device (optional).** The stick trusts the SSH keys chosen at build time,
  from a file or from `github.com/<user>.keys`, so `ssh root@archiso.local` works from those
  devices on the same network, and the login link can be copied there.
- **Copying `~/.claude/.credentials.json`** is not offered. It is a full login rather than a token
  for model requests only, Claude Code manages it through `/login` and `/logout` only, and macOS
  keeps it in the Keychain instead. Two machines holding one login may also log each other out
  when one of them refreshes it; that is not checked. The ISO's text browser, lynx, cannot run
  the JavaScript that the claude.ai login page needs.

## The desktop app on the stick

The app gives the person a window with a terminal, where they run archinstall and type its
passwords. Google Chrome beside it gives Claude a browser through Claude in Chrome: the ArchWiki
answers plain downloads with a bot check, and some sites block the app's own browser. Nothing of
either reaches the installed system. Once cloud-init has installed them at boot, the launcher
opens them, and the install procedure is the `claude` user's own CLAUDE.md, so a Code session in
any folder follows it when the person says "install arch".

- **Source.** Anthropic publishes the app for Debian and Ubuntu only and sends Arch users to the
  CLI, so on Arch it runs unsupported. The stick takes the newest `.deb` from Anthropic's apt
  repository and checks it the way apt does: `InRelease` signed by the key the docs pin, then
  `Packages` and the `.deb` by sha256. It unpacks the files with `bsdtar` and installs the
  libraries the package depends on with pacman, leaving out the virtual machine that only Cowork
  uses. The AUR package `claude-desktop` does the same repackaging, but building it would need
  `base-devel` in RAM on every boot.
- **Chrome.** The stick takes `google-chrome-stable` from Google's apt repository the same way,
  with Google's Linux package signing key pinned by its primary fingerprint, since Google signs
  with yearly subkeys. Its libraries are the ones the AUR's `google-chrome` depends on. The
  unpack skips the archive's own `./` entry, whose mode 750 would otherwise land on `/` and stop
  every user but root from running anything. A policy in `/etc/opt/chrome/policies/managed`
  force-installs Claude in Chrome from the Chrome Web Store, and the extension opens its own
  sign-in tab. Claude Code's Chrome docs give the Linux path of the connection file Chrome reads
  as it starts, need the extension signed in to the same account, and leave Chrome integration
  off for a `setup-token` login, so the console fallback has no browser.
- **Display.** No desktop environment: sway, a tiling Wayland compositor, shows the app and
  Chrome side by side. cage, which showed the app alone, keeps the newest window on top with no
  way back to the others. The app refuses to run as root, so a systemd unit starts sway as the
  user `claude` on tty7 with a PAM session, as cage's wiki describes for its compositor. That user
  has sudo without a password, since the install needs root. sway itself lets Ctrl+Alt+F1 and
  Ctrl+Alt+F2 reach the consoles, and its config takes the keyboard layout from `--xkb-layout`,
  since a layout such as EurKEY has no console keymap to follow.
- **Sign-in.** The token from `setup-token` only works for the CLI, so the app signs in itself on
  every boot; with no keyring it keeps the sign-in until the app closes. With email, a
  third-party guide says the sign-in link opened on another device shows a code to type into the
  app; that is not checked. Google and SSO open Chrome, which `mimeapps.list` makes the default
  browser. The app's code takes the Google sign-in back as a `claude://` link, which Chrome hands
  to `xdg-open` and `xdg-open` to the app's own `.desktop` entry, since that claims the scheme. A
  policy lets claude.ai open such links without Chrome asking first. The person signs in to the
  extension too, on the tab it opens.
- **Cost.** In an amd64 Arch container, the app and its libraries were 122 MB of packages and a
  161 MB `.deb`, took about 1.1 GB once unpacked, and the running app about 1.4 GB more. Chrome
  adds a 146 MB `.deb` that unpacks to about 450 MB, and sway a few MB. The ISO already has some of
  those libraries.
- **Tested.** In that container, the prepare step installed and verified both packages and
  refused Chrome's repository under the app's key. sway on a headless output showed the app and
  Chrome side by side, the extension installed itself and opened its sign-in tab, and the
  restart command in `stick/CLAUDE.md` brought Chrome back. Chrome also passed a `claude://` link
  from a page the policy allows to a stand-in for the app, without asking. Docker blocks the
  sandboxes, so the apps ran with `--no-sandbox`; the stick runs with them. The systemd unit, the
  VT switch and sway on a real display ran in a virtual machine, as below. Both sign-ins and
  Claude Code reaching the extension have not run.

## Memory

The live system keeps changes in a RAM disk of 256 MB by default (`cow_spacesize` in
mkinitcpio-archiso), and Claude Code alone takes about 260 MB. cloud-init grows that RAM disk to
75% of the machine's memory before installing Claude Code and the app. Nothing persists between
boots: each boot installs them again and asks for a sign-in again.

## Trying it in a virtual machine

`scripts/test-vm.sh` boots the ISO in QEMU the way a PC boots the stick: UEFI firmware without
Secure Boot, the ISO as a USB stick on an xHCI controller, where cloud-init finds its CIDATA
partition as on the real stick, a blank 40 GB virtio disk and a user-mode network. `snapshot=on`
leaves the ISO file as it was. The disk and the firmware's variables stay in
`~/.cache/ai-arch-vm`, so a run without the ISO boots what was installed. A QMP socket lets
`--screenshot` save the screen as a PNG, so Claude can look at the VM without its window. With KVM
on a Linux PC it runs at close to full speed. A Mac with Apple silicon has no hardware
virtualisation for an x86 PC, so QEMU emulates one.

- **Tested.** In an arm64 Debian container on a Mac with Apple silicon, emulated, the script
  booted an ISO built for EurKEY and Europe/Helsinki to sway in about 17 minutes, with the desktop
  app and Chrome side by side and the extension's sign-in tab open. That ran the prepare step under
  cloud-init, the systemd unit, the switch to tty7 and sway on virtio-gpu. KVM and QEMU from
  Homebrew on macOS have not run, and no install has run to its end.

## Rough edges

- Windows cannot build a stick: it has no `dd`, and Claude Code's shell there cannot write a raw
  disk.
- The official ISO does not boot with Secure Boot on.
- Wi-Fi passwords are typed on the stick with `iwctl`, never copied from the build machine.
- A full boot has run only in an emulated virtual machine, not yet from a stick on a PC.
