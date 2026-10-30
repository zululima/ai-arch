#!/usr/bin/env bash
# Prints what build-iso.sh needs from this machine, as KEY=value lines.
set -uo pipefail

layouts=
case $(uname -s) in
  Darwin)
    layouts=$(defaults read com.apple.HIToolbox AppleSelectedInputSources 2>/dev/null |
      sed -n 's/.*"KeyboardLayout Name" = "\{0,1\}\([^";]*\)"\{0,1\};.*/\1/p' | paste -sd, -)
    ;;
  Linux)
    if [[ -f ~/.config/kxkbrc ]]; then
      layouts=$(sed -n 's/^LayoutList=//p' ~/.config/kxkbrc)
    fi
    if [[ -z $layouts ]] && command -v gsettings >/dev/null; then
      layouts=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null |
        grep -o "'xkb', '[^']*'" | sed "s/'xkb', '\(.*\)'/\1/" | paste -sd, -)
    fi
    if [[ -z $layouts ]]; then
      layouts=$(localectl status 2>/dev/null | sed -n -E 's/^ *(VC Keymap|X11 Layout): //p' | paste -sd, -)
    fi
    ;;
esac
echo "KEYBOARD=${layouts:-unknown}"

tz=$(readlink /etc/localtime 2>/dev/null | sed 's|.*zoneinfo/||')
echo "TIMEZONE=${tz:-unknown}"

for f in ~/.ssh/id_ed25519.pub ~/.ssh/id_ecdsa.pub ~/.ssh/id_rsa.pub; do
  [[ -f $f ]] && echo "SSH_KEY_FILE=$f"
done
n=0
while read -r type key comment; do
  n=$((n + 1))
  echo "SSH_AGENT_KEY_$n=$type ${key:0:20}... $comment"
done < <(ssh-add -L 2>/dev/null | grep -E '^(ssh|ecdsa|sk)-')
