#!/usr/bin/env bash
# Writes an ai-arch ISO to a USB stick. Run it yourself, in your own terminal:
# it erases the stick and asks for your sudo password.
set -euo pipefail

iso=${1:?usage: write-stick.sh ISO [DEVICE]}
dev=${2:-}
[[ -f $iso ]] || { echo "No such file: $iso" >&2; exit 1; }
os=$(uname -s)

list_usb_disks() {
  case $os in
    Darwin) diskutil list external physical ;;
    Linux) lsblk -d -o PATH,TRAN,SIZE,MODEL | awk 'NR == 1 || $2 == "usb"' ;;
    *) echo "Only macOS and Linux are supported." >&2; exit 1 ;;
  esac
}

is_whole_usb_disk() {
  case $os in
    Darwin)
      local info
      info=$(diskutil info "$1" 2>/dev/null) || return 1
      grep -Eq 'Whole: +Yes' <<<"$info" &&
        grep -Eq 'Device Location: +External' <<<"$info" &&
        grep -Eq 'Protocol: +USB' <<<"$info"
      ;;
    Linux)
      [[ $(lsblk -dno TYPE "$1" 2>/dev/null) == disk && $(lsblk -dno TRAN "$1" 2>/dev/null) == usb ]]
      ;;
  esac
}

echo "USB disks on this machine:"
list_usb_disks
echo
if [[ -z $dev ]]; then
  read -rp 'Device to erase, such as /dev/sdb or /dev/disk4: ' dev
fi
is_whole_usb_disk "$dev" || { echo "$dev is not a whole USB disk. Nothing was written." >&2; exit 1; }

case $os in
  Darwin) diskutil info "$dev" | grep -E 'Media Name|Disk Size' ;;
  Linux) lsblk -o NAME,SIZE,MODEL,FSTYPE,LABEL,MOUNTPOINTS "$dev" ;;
esac
read -rp "Everything on $dev will be erased. Type $dev again to go on: " again
[[ $again == "$dev" ]] || { echo "That did not match. Nothing was written." >&2; exit 1; }

case $os in
  Darwin)
    diskutil unmountDisk "$dev"
    sudo dd if="$iso" of="${dev/disk/rdisk}" bs=4m status=progress
    sync
    diskutil eject "$dev"
    ;;
  Linux)
    while read -r part; do
      sudo umount "$part" 2>/dev/null || true
    done < <(lsblk -lnpo NAME "$dev" | tail -n +2)
    sudo dd if="$iso" of="$dev" bs=4M conv=fsync oflag=direct status=progress
    sync
    ;;
esac
echo "Done: $dev now holds $(basename "$iso")."

if [[ $iso == *-with-token.iso ]]; then
  rm -f "$iso"
  echo "Deleted $iso, since it holds your Claude token."
fi
