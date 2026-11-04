#!/usr/bin/env bash
# Boots an ai-arch ISO in a QEMU virtual machine the way a PC boots the stick,
# with a blank disk to install on, so the whole install can be tried first.
# Without an ISO it boots that disk alone, to try the installed system.
# --screenshot saves the running VM's screen as a PNG.
set -euo pipefail

dir=$HOME/.cache/ai-arch-vm
disk=$dir/disk.qcow2
monitor=$dir/qmp.sock
os=$(uname -s)

die() {
  echo "test-vm: $*" >&2
  exit 1
}

if [[ ${1:-} == --screenshot ]]; then
  [[ -S $monitor ]] || die "no VM is running"
  python3 - "$monitor" "$dir/screen.png" <<'EOF' || die "no VM is running"
import json, socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect(sys.argv[1])
f = s.makefile("rw")
f.readline()
for cmd in ({"execute": "qmp_capabilities"},
            {"execute": "screendump", "arguments": {"filename": sys.argv[2], "format": "png"}}):
    f.write(json.dumps(cmd) + "\n")
    f.flush()
    while not {"return", "error"} & (reply := json.loads(f.readline())).keys():
        pass
    if "error" in reply:
        sys.exit(reply["error"]["desc"])
EOF
  echo "$dir/screen.png"
  exit 0
fi

iso=${1:-}
[[ -z $iso || -f $iso ]] || die "no such file: $iso"

install_hint() {
  echo "test-vm: QEMU or its UEFI firmware is missing. Install them with:" >&2
  if [[ $os == Darwin ]]; then
    echo "  brew install qemu" >&2
  elif command -v pacman >/dev/null; then
    echo "  sudo pacman -S --needed qemu-desktop edk2-ovmf" >&2
  elif command -v apt-get >/dev/null; then
    echo "  sudo apt-get install qemu-system-x86 qemu-utils ovmf" >&2
  elif command -v dnf >/dev/null; then
    echo "  sudo dnf install qemu-system-x86 qemu-img edk2-ovmf" >&2
  fi
  exit 1
}

if ! command -v qemu-system-x86_64 >/dev/null || ! command -v qemu-img >/dev/null; then
  install_hint
fi
# UEFI firmware without Secure Boot, which the official ISO does not support,
# and the blank variable store that goes with it.
code='' vars=''
for pair in \
  /usr/share/edk2/x64/OVMF_CODE.4m.fd:/usr/share/edk2/x64/OVMF_VARS.4m.fd \
  /usr/share/OVMF/OVMF_CODE_4M.fd:/usr/share/OVMF/OVMF_VARS_4M.fd \
  /usr/share/edk2/ovmf/OVMF_CODE.fd:/usr/share/edk2/ovmf/OVMF_VARS.fd \
  /opt/homebrew/share/qemu/edk2-x86_64-code.fd:/opt/homebrew/share/qemu/edk2-i386-vars.fd \
  /usr/local/share/qemu/edk2-x86_64-code.fd:/usr/local/share/qemu/edk2-i386-vars.fd; do
  if [[ -f ${pair%%:*} && -f ${pair#*:} ]]; then
    code=${pair%%:*} vars=${pair#*:}
    break
  fi
done
[[ -n $code ]] || install_hint

[[ -n $iso || -f $disk ]] || die "give the ISO to boot"
mkdir -p "$dir"
[[ -f $disk ]] || qemu-img create -q -f qcow2 "$disk" 40G
[[ -f $dir/vars.fd ]] || cp "$vars" "$dir/vars.fd"

if [[ $os == Darwin ]]; then
  mem_mib=$(($(sysctl -n hw.memsize) / 1048576))
  cpus=$(sysctl -n hw.ncpu)
else
  mem_mib=$(($(awk '/^MemTotal:/ {print $2}' /proc/meminfo) / 1024))
  cpus=$(nproc)
fi
# 8 GiB holds the live system, the desktop app and Chrome; leave the host 3 GiB.
mem_mib=$((mem_mib - 3072 < 8192 ? mem_mib - 3072 : 8192))
((mem_mib >= 4096)) || die "this machine has too little memory for the VM"
cpus=$((cpus / 2 > 1 ? cpus / 2 : 2))

if [[ -w /dev/kvm ]]; then
  accel=(-accel kvm -cpu host)
elif [[ $os == Darwin && $(uname -m) == x86_64 ]]; then
  accel=(-accel hvf -cpu host)
else
  accel=(-accel tcg -cpu max)
  echo "test-vm: no hardware virtualisation for an x86 PC here, so QEMU emulates one;" \
    "expect the boot and the apps to take many times longer than on a PC." >&2
fi

display=()
if [[ $os == Linux && -z ${DISPLAY:-} && -z ${WAYLAND_DISPLAY:-} ]]; then
  display=(-display none -vnc 127.0.0.1:0)
  echo "test-vm: no desktop here, so the VM's screen is at VNC localhost:5900." >&2
fi

stick=()
# snapshot=on keeps the ISO file as it is, whatever the VM writes to its stick.
[[ -n $iso ]] && stick=(-drive "if=none,id=stick,format=raw,snapshot=on,file=$iso"
  -device "usb-storage,drive=stick,bootindex=0")

exec qemu-system-x86_64 -machine q35 "${accel[@]}" -smp "$cpus" -m "$mem_mib" \
  -drive "if=pflash,format=raw,readonly=on,file=$code" \
  -drive "if=pflash,format=raw,file=$dir/vars.fd" \
  -device qemu-xhci -device usb-tablet ${stick[@]+"${stick[@]}"} \
  -drive "if=virtio,format=qcow2,file=$disk" \
  -nic user,model=virtio-net-pci -device virtio-vga \
  -qmp "unix:$monitor,server,nowait" ${display[@]+"${display[@]}"}
