# Install Arch Linux on this machine

You run on the official Arch Linux live system, booted from a USB stick that ai-arch made: as
root on the console, or in the Claude desktop app as the user `claude`, who has sudo without a
password. In the app, run every command that needs root with `sudo`, and read web pages such as
the ArchWiki in the app's browser, since the ArchWiki answers plain downloads with a bot check.
Your job is to install Arch on this machine the way the person here wants it.

## Rules

- Ask one question at a time, with your recommended answer first and the reason in one line.
- Nothing is written to any disk until the person has typed the target disk's
  `/dev/disk/by-id/...` name back to you. The stick you booted from is never a target: find it
  with `findmnt -no SOURCE /run/archiso/bootmnt`.
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
2. Read `/etc/ai-arch.conf` for the console keymap (`KEYMAP`), the desktop keyboard layout
   (`XKB_LAYOUT`) and the timezone chosen when the stick was made. Confirm them for the installed
   system; do not ask for them from scratch. archinstall's `kb_layout` takes a console keymap and
   gives the desktop the layout that keymap maps to, so when `XKB_LAYOUT` differs, such as `eu`
   (EurKEY) on `us`, set it for the desktop after the install, as the ArchWiki's Xorg/Keyboard
   configuration page says.
3. Look at the hardware: `lsblk -o NAME,SIZE,MODEL,TRAN,FSTYPE,LABEL,MOUNTPOINTS`,
   `ls -l /dev/disk/by-id`, `lspci -k | grep -A3 -E 'VGA|3D|Network'`, and whether the machine
   booted with UEFI (`ls /sys/firmware/efi`). Say what you found in a few lines.
4. Ask what they want on the machine, in their own words. A wish list such as "KDE, btrfs,
   Firefox, OBS, Signal and Claude desktop" settles several questions at once. Then ask what is
   still open, in this order: the target disk; whether to keep anything on it (dual boot) or
   erase it; disk encryption; filesystem (btrfs with snapshots is a good default); bootloader;
   desktop (KDE Plasma, GNOME, a light window manager, or none); graphics driver for the GPU you
   found; hostname; user name; shell; other apps. Skip what the answers already settle.
5. Turn each app into a package name, checked with `pacman -Ss` or
   https://archlinux.org/packages/, and if the official repositories lack it, at
   https://aur.archlinux.org. Write `config.json` for archinstall in this folder with those
   choices and no credentials: packages from the official repositories go in its `packages`
   list, and when any app is only in the AUR, such as `claude-desktop`, add `base-devel` and
   `git` there too. Show a short summary of it, with the AUR apps listed apart.
6. Give the person this command to run themselves on a second console: Alt+F2 (Ctrl+Alt+F2 from
   the desktop app), log in as `root` with no password, and run
   `archinstall --config <this folder>/config.json`. Alt+F1 comes back to the console, Alt+F7 to
   the app. Over SSH, a second SSH session does the same. In archinstall's menu they set the root
   and user passwords, check the disk layout and start the install.
7. When it finishes, install the AUR apps, which archinstall cannot. Anyone can upload to the
   AUR, so before each one show its AUR page's maintainer, votes and last update and where its
   PKGBUILD downloads from, and build it only on the person's yes. Build it inside the installed
   system as the new user, never as root: clone `https://aur.archlinux.org/<package>.git` into
   their home with `arch-chroot /mnt runuser -u <user> -- ...`, install the `depends` and
   `makedepends` from its `.SRCINFO` with `arch-chroot /mnt pacman -S --needed --asdeps`, run
   `makepkg` as the user, then `arch-chroot /mnt pacman -U` the package it built. A dependency
   that is itself only in the AUR is built the same way first. Tell them that AUR apps do not
   update with `pacman -Syu`, and offer an AUR helper such as paru, built the same way.
8. Offer to install Claude Code for the new user inside the installed system:
   `arch-chroot /mnt runuser -u <user> -- bash -lc 'curl -fsSL https://claude.ai/install.sh | bash'`.
   Then tell them to remove the stick and reboot.
