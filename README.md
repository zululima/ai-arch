# ai-arch

An Arch Linux install USB stick that opens the Claude desktop app on boot. You say "install arch",
answer a few questions, and Claude prepares archinstall and the apps you asked for.

1. Plug a USB stick of 2 GB or more into a Mac or a Linux machine and paste this into Claude Code:

   ```text
   clone https://github.com/zululima/ai-arch into ~/Projects/ai-arch, read its CLAUDE.md and make me an arch install usb stick
   ```

2. Claude downloads and verifies the latest Arch ISO, adds your keyboard layout and timezone, and
   gives you the command that writes the stick.
3. Boot the target machine from the stick with Secure Boot off and a network cable in. The Claude
   desktop app opens after a few minutes.
4. Sign in by email, open the Code tab and say "install arch". Claude asks how you want Arch.
5. Run archinstall in the app's terminal with the config Claude wrote, and type your passwords.
6. Claude adds your apps from the AUR, offers to format the stick as exFAT, and you reboot.

| Part | What it does |
| --- | --- |
| `scripts/build-iso.sh` | downloads and verifies the ISO, adds the settings partition |
| `scripts/write-stick.sh` | writes the ISO to the stick; you run it yourself |
| `stick/ai-arch` | on the stick: installs and opens the Claude desktop app |
| `stick/CLAUDE.md` | on the stick: the install procedure Claude follows |

Reasons and rough edges: [docs/design.md](docs/design.md). A full boot is not tested yet. Scripts
are AGPL-3.0-or-later, the text CC BY-SA 4.0 ([LICENSE-PROSE](LICENSE-PROSE)).
