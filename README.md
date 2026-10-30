# ai-arch

An Arch Linux install USB stick with Claude Code on it, made and used by talking to Claude. The
stick holds the latest official Arch ISO, unchanged, plus a small partition that cloud-init on the
live system reads: your keyboard layout, timezone, SSH key and a launcher that installs the latest
Claude Code at boot. Type `ai-arch` there and Claude asks how you want Arch, then sets up
archinstall for you.

## Start

Paste this into Claude Code on a Mac or a Linux machine:

```text
clone https://github.com/zululima/ai-arch into ~/Projects/ai-arch, read its CLAUDE.md and make me an arch install usb stick
```

You need a USB stick of 2 GB or more (it gets erased), a Claude plan that includes Claude Code,
and for the machine you install on: x86_64, Secure Boot off and a network, a cable being easiest.

## Parts

| File | What it does |
| --- | --- |
| `scripts/host-info.sh` | reads the keyboard layout, timezone and SSH keys of the machine you build on |
| `scripts/build-iso.sh` | downloads and verifies the latest ISO, adds the CIDATA partition |
| `scripts/write-stick.sh` | writes the ISO to a USB stick; you run it yourself |
| `scripts/save-token.sh` | optional: keeps a `claude setup-token` token for a stick that boots logged in |
| `stick/ai-arch` | on the stick: installs Claude Code and starts it |
| `stick/CLAUDE.md` | on the stick: the install procedure Claude follows |

[docs/design.md](docs/design.md) gives the reasons and the rough edges. Status: the scripts are
tested on their own, a full boot of a stick is not yet. Licence: AGPL-3.0-or-later.
