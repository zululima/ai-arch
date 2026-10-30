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
- **A browser on the stick.** The ISO's text browser, lynx, cannot run the JavaScript that the
  claude.ai login page needs. The `claude-desktop` package in the AUR repackages Anthropic's
  official Debian package and would bring a real browser view, but it needs a graphical session,
  a user other than root and an AUR build on every boot. The installed system gets it instead.

## The desktop app on the installed system

The stick offers the AUR package `claude-desktop` when the person picks a desktop. Its `PKGBUILD`
takes the file payload of Anthropic's `.deb` from `downloads.claude.ai`, checked by sha256, and
leaves out the Debian install scripts. The app is Electron, so it needs a graphical session; it
keeps its login through the Secret Service or KWallet and talks to the desktop through
`xdg-desktop-portal`. `plasma-meta` brings `kwallet-pam` and `xdg-desktop-portal-kde`, and the
`gnome` group brings `gnome-keyring` and `xdg-desktop-portal-gnome`; a window manager needs them
added. On x86_64 the package also depends on `qemu-system-x86` and `edk2-ovmf`, for the virtual
machine that Cowork runs in. With no AUR helper, it updates only when rebuilt.

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
