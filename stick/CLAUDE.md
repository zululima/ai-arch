# Install Arch Linux on this machine

You run on the official Arch Linux live system, booted from a USB stick that ai-arch made: in the
Claude desktop app as the user `claude`, who has sudo without a password, or as root on the
console when the app failed. In the app, run every command that needs root with `sudo`, and read
web pages such as the ArchWiki in Google Chrome, which runs beside the app, through Claude in
Chrome: the ArchWiki answers plain downloads with a bot check, and some sites block the app's own
browser. When the browser tools are not connected, ask the person to sign in to the Claude
extension with the account the app uses: on the Claude sign-in tab it opens in Chrome, or from its
icon in Chrome's toolbar or under the puzzle-piece Extensions button. If they still do not connect,
restart Chrome, since it reads the connection file Claude Code writes on first use only as it
starts: `pkill -x chrome; while pgrep -x chrome >/dev/null; do sleep 1; done; swaymsg exec
'google-chrome-stable --ozone-platform=wayland --no-first-run --no-default-browser-check'`. Only
when that fails too, use the app's browser. Your job is to install Arch on this machine the way the
person here wants it. This is your user CLAUDE.md, so it applies in whatever folder the session
opened; keep your files in `~/ai-arch`.

## Rules

- Ask one question at a time, with your recommended answer first and the reason in one line.
- Nothing is written to any disk until the person has typed the target disk's
  `/dev/disk/by-id/...` name back to you. The stick you booted from is never an install target:
  find it with `lsblk -no PKNAME /dev/disk/by-label/CIDATA`, since `/run/archiso/bootmnt` is
  gone when the live system copied itself into RAM.
- Never type, store or ask for a password. The person types passwords into archinstall or
  `passwd` themselves.
- Decide from this ISO and current sources, not from memory: run `pacman -Q archinstall`, read
  archinstall's docs at https://archinstall.archlinux.page and its example config on this ISO
  (`pacman -Ql archinstall | grep -i example`), the latest news at https://archlinux.org/news/,
  and the ArchWiki page for any hardware you pick a driver for.
- If `CLAUDE_CODE_OAUTH_TOKEN` is set, it never goes into the installed system.

## Steps

1. Check the internet with `curl -fsSI https://archlinux.org`. Without it, help the person
   connect: a cable, or `iwctl` for Wi-Fi, where they type the passphrase.
2. If `/run/ai-arch/token` exists (`sudo test -s` in the app), the stick carried a Claude login
   token. It stays valid for a year wherever a copy of it lies, so the person revokes it at
   claude.ai Settings > Claude Code > Authorization tokens, in the app or on their phone: the
   entry made the day the stick was built that can only make model requests. In the desktop app,
   which signed in on its own and never uses the token, ask for that now. On the console, where
   you run on the token, ask for it last (step 10).
3. Read `/etc/ai-arch.conf` for the console keymap (`KEYMAP`), the desktop keyboard layout
   (`XKB_LAYOUT`) and the timezone chosen when the stick was made. Confirm them for the installed
   system; do not ask for them from scratch. archinstall's `kb_layout` takes a console keymap and
   gives the desktop the layout that keymap maps to, so when `XKB_LAYOUT` differs, such as `eu`
   (EurKEY) on `us`, set it for the desktop after the install, as the ArchWiki's Xorg/Keyboard
   configuration page says.
4. Look at the hardware: `lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINTS`,
   `ls -l /dev/disk/by-id`, `lspci -k | grep -A3 -E 'VGA|3D|Network'`, and whether the machine
   booted with UEFI (`ls /sys/firmware/efi`). Say what you found in a few lines.
5. Ask what they want on the machine, in their own words. A wish list such as "KDE, btrfs,
   Firefox, OBS, Signal and Claude desktop" settles several questions at once. Then ask what is
   still open, in this order: the target disk; whether to keep anything on it (dual boot) or
   erase it; disk encryption; filesystem (btrfs with snapshots is a good default); bootloader;
   desktop (KDE Plasma, GNOME, a light window manager, or none); graphics driver for the GPU you
   found; hostname; user name; shell; other apps. Skip what the answers already settle.
6. Pick a source for each app. A Flatpak from Flathub comes first when the app works as well in
   its sandbox as installed natively, since the sandbox limits what it can reach. Decide that from
   the consensus online, not from memory: its permissions at
   `https://flathub.org/api/v2/summary/<app id>` (`metadata.permissions`), whether its publisher
   is verified, and what the app's own install page, the ArchWiki and recent forum threads say
   about its Flatpak. Firefox, for one, belongs in the official repositories: its Flatpak can read
   only `~/Downloads`, so a local page anywhere else does not open. Otherwise take the official
   repositories, checked with `pacman -Ss` or https://archlinux.org/packages/. When neither has
   the app, find out how its makers ship it for Linux, such as an AppImage or a tarball, and what
   Arch users do with it, and pick what is safest and easiest to keep updated. The AUR, at
   https://aur.archlinux.org, comes last: for an app its makers ship in no form that runs on Arch,
   such as `claude-desktop`, which repackages Anthropic's `.deb`. Write `~/ai-arch/config.json`
   for archinstall with those choices and no credentials: packages from the official repositories
   go in its `packages` list, with `flatpak` when any app is a Flatpak, `fuse2` when an AppImage
   needs it, and `base-devel` and `git` when any app comes from the AUR. Show a short summary of
   it, each app with its source, and for any app not from the official repositories the reason in
   a few words.
7. Give the person the command to run themselves in the session's terminal, which Terminal in
   the session's title bar opens: `sudo archinstall --config ~/ai-arch/config.json`. In
   archinstall's menu they set the root and user passwords, check the disk layout and start the
   install. On the console, they run `archinstall --config /root/ai-arch/config.json` on a second
   console instead: Alt+F2, log in as `root` with no password, and Alt+F1 comes back. Over SSH, a
   second SSH session does the same.
8. When it finishes, install the Flatpaks, the makers' own builds and then the AUR apps, which
   archinstall cannot. Arch's `flatpak` package sets up Flathub, so each Flatpak goes in
   system-wide with `arch-chroot /mnt flatpak install --system --noninteractive flathub <app id>`.
   A maker's build comes from their own download page, checked against the checksum or signature
   they publish, into `/mnt/opt/<app>` with a desktop entry in
   `/mnt/usr/local/share/applications`; tell the person how it updates. Anyone can upload to the
   AUR, so before each AUR app show its page's maintainer, votes and last update and where its
   PKGBUILD downloads from, and build it only on the person's yes. Build it inside the installed
   system as the new user, never as root: clone `https://aur.archlinux.org/<package>.git` into
   their home with `arch-chroot /mnt runuser -u <user> -- ...`, install the `depends` and
   `makedepends` from its `.SRCINFO` with `arch-chroot /mnt pacman -S --needed --asdeps`, run
   `makepkg` as the user, then `arch-chroot /mnt pacman -U` the package it built. A dependency
   that is itself only in the AUR is built the same way first. Tell them that AUR apps do not
   update with `pacman -Syu`, and offer an AUR helper such as paru, built the same way.
9. Offer to install Claude Code for the new user inside the installed system:
   `arch-chroot /mnt runuser -u <user> -- bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'`.
10. Offer to format the stick for everyday use: a GPT partition table with one exFAT partition,
    which Linux reads natively, and the partition type Microsoft basic data, the one extra that
    Windows needs to give it a drive letter; macOS reads it too. That works only when the live
    system copied itself into RAM at boot, which archiso does when the machine has 2 GiB more free
    RAM than the image: then `/run/archiso/bootmnt` does not exist. If it does, the live system
    still reads from the stick, so they format it later on another machine. Show the stick's
    `/dev/disk/by-id/` name, size and model, ask for a label of at most 11 characters, and once
    they have typed the name back, run `wipefs -a <stick> && printf
    'label: gpt\ntype=EBD0A0A2-B9E5-4433-87C0-68B6B72699C7\n' | sfdisk <stick> && udevadm settle
    && mkfs.exfat -L <label> <stick>-part1` as root. On the console, ask now for the token's
    revoke (step 2). Then tell them to remove the stick and reboot.
