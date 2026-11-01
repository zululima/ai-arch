# ai-arch

An Arch Linux install USB stick that boots into the Claude desktop app, where Claude installs Arch with you.

1. Plug a USB stick of 2 GB or more into a Mac or Linux machine and paste this into Claude Code:
   ```text
   clone https://github.com/zululima/ai-arch into ~/Projects/ai-arch, read its CLAUDE.md and make me an arch install usb stick
   ```
2. Claude asks your keyboard layout, checks the timezone it detected, and you write the image to the stick.
3. Boot from the stick with Secure Boot off and a network cable in. The Claude desktop app opens.
4. Sign in by email, open the Code tab and say "install arch". Claude asks what you want on the new system.
5. Run archinstall in the app's terminal with the config Claude wrote, and type your passwords there.
6. Claude adds your apps from the AUR, offers to format the stick as exFAT, and you reboot.

| Part | What it does |
| --- | --- |
| `scripts/build-iso.sh` | downloads and verifies the ISO, adds the settings partition |
| `scripts/write-stick.sh` | writes the ISO to the stick; you run it yourself |
| `stick/ai-arch` | on the stick: installs and opens the Claude desktop app |
| `stick/CLAUDE.md` | on the stick: the install procedure Claude follows |

A full boot is not tested yet. Rough edges: [docs/design.md](docs/design.md). Scripts AGPL-3.0-or-later,
text [CC BY-SA 4.0](LICENSE-PROSE).
