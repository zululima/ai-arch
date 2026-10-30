# ai-arch

An Arch Linux install USB stick that starts Claude Code on boot. It holds the latest official ISO,
unchanged, plus a small partition with your keyboard layout, timezone and a Claude login token.
Type `ai-arch` on the stick and Claude asks how you want Arch, then prepares archinstall for you.
It can also put Claude Code and the Claude desktop app on the new system.

## Start

Plug in a USB stick of 2 GB or more and paste this into Claude Code on a Mac or a Linux machine:

```text
clone https://github.com/zululima/ai-arch into ~/Projects/ai-arch, read its CLAUDE.md and make me an arch install usb stick
```

The machine you install on needs x86_64, Secure Boot off and a network; a cable is easiest.

## Parts

| File | What it does |
| --- | --- |
| `scripts/build-iso.sh` | downloads and verifies the latest ISO, adds the settings partition |
| `scripts/write-stick.sh` | writes the ISO to the stick; you run it yourself |
| `stick/ai-arch` | on the stick: installs Claude Code and starts it |
| `stick/CLAUDE.md` | on the stick: the install procedure Claude follows |

Reasons and rough edges: [docs/design.md](docs/design.md). A full boot is not tested yet.
Licence: AGPL-3.0-or-later.
