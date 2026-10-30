#!/usr/bin/env bash
# Builds an Arch install ISO with an extra CIDATA partition that cloud-init on
# the live system reads: SSH key, keymap, timezone and the ai-arch launcher.
# The method is the ArchWiki's "Install Arch Linux via SSH", single USB drive.
set -euo pipefail

PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin:/opt/homebrew/sbin
repo=$(cd "$(dirname "$0")/.." && pwd)
mirror=${AI_ARCH_MIRROR:-https://geo.mirror.pkgbuild.com/iso/latest}
signer=${AI_ARCH_SIGNER:-pierre@archlinux.org}
signer_fpr=${AI_ARCH_SIGNER_FPR:-3E80CA1A8B89F69CBA57D98A76A5EF9054449A5C}
out=$HOME/Downloads/ai-arch
keymap=
timezone=
ssh_key=
token_file=
cidata_only=

usage() {
  cat <<'EOF'
Usage: build-iso.sh --keymap NAME --timezone ZONE [--ssh-key FILE.pub]
                    [--token-file FILE] [--out DIR] [--cidata-only]

  --keymap       console keymap for the live system, such as fi, us or de-latin1
  --timezone     zone name, such as Europe/Helsinki
  --ssh-key      public key that may log in as root over SSH
  --token-file   file holding a token from `claude setup-token`
  --out          folder for the ISO (default ~/Downloads/ai-arch)
  --cidata-only  build only the small CIDATA image, to check what goes on the stick
EOF
}

die() {
  echo "build-iso: $*" >&2
  exit 1
}

while (($#)); do
  case $1 in
    --keymap) keymap=${2:?--keymap needs a value}; shift 2 ;;
    --timezone) timezone=${2:?--timezone needs a value}; shift 2 ;;
    --ssh-key) ssh_key=${2:?--ssh-key needs a file}; shift 2 ;;
    --token-file) token_file=${2:?--token-file needs a file}; shift 2 ;;
    --out) out=${2:?--out needs a folder}; shift 2 ;;
    --cidata-only) cidata_only=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

[[ $keymap =~ ^[A-Za-z0-9_.-]+$ ]] || die "give --keymap, such as fi or us"
[[ $timezone =~ ^[A-Za-z0-9_+/-]+$ ]] || die "give --timezone, such as Europe/Helsinki"
pubkey=
if [[ -n $ssh_key ]]; then
  [[ -f $ssh_key ]] || die "no such key file: $ssh_key"
  pubkey=$(head -n 1 "$ssh_key")
  [[ $pubkey =~ ^(ssh|ecdsa|sk)-[A-Za-z0-9@.-]+\ [A-Za-z0-9+/=]+(\ [^\']*)?$ ]] ||
    die "$ssh_key does not look like an SSH public key"
fi
if [[ -n $token_file ]]; then
  [[ -s $token_file ]] || die "token file is missing or empty: $token_file"
fi

need() {
  local missing=() t
  for t in "$@"; do
    command -v "$t" >/dev/null || missing+=("$t")
  done
  ((${#missing[@]} == 0)) && return 0
  echo "build-iso: missing ${missing[*]}. Install them with:" >&2
  if [[ $(uname -s) == Darwin ]]; then
    echo "  brew install xorriso mtools dosfstools gnupg" >&2
  elif command -v pacman >/dev/null; then
    echo "  sudo pacman -S --needed libisoburn mtools dosfstools gnupg" >&2
  elif command -v apt-get >/dev/null; then
    echo "  sudo apt-get install xorriso mtools dosfstools gnupg" >&2
  elif command -v dnf >/dev/null; then
    echo "  sudo dnf install xorriso mtools dosfstools gnupg2" >&2
  fi
  exit 1
}

sha256() {
  if command -v sha256sum >/dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

b64() { base64 <"$1" | tr -d '\n'; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

build_cidata() {
  {
    echo '#cloud-config'
    if [[ -n $pubkey ]]; then
      printf "users:\n  - name: root\n    ssh_authorized_keys:\n      - '%s'\n" "$pubkey"
    fi
    cat <<EOF
write_files:
  - path: /usr/local/bin/ai-arch
    permissions: '0755'
    encoding: b64
    content: $(b64 "$repo/stick/ai-arch")
  - path: /root/ai-arch/CLAUDE.md
    encoding: b64
    content: $(b64 "$repo/stick/CLAUDE.md")
  - path: /etc/ai-arch.conf
    content: |
      KEYMAP=$keymap
      TIMEZONE=$timezone
  - path: /etc/motd
    append: true
    content: |

      ai-arch: type ai-arch to install Arch Linux with Claude Code.
runcmd:
  - [mount, -o, 'remount,size=75%', /run/archiso/cowspace]
  - [localectl, set-keymap, '$keymap']
  - [loadkeys, '$keymap']
  - [timedatectl, set-timezone, '$timezone']
  - [/usr/local/bin/ai-arch, --prepare]
EOF
  } >"$work/user-data"
  : >"$work/meta-data"
  printf 'version: 2\nconfig: disabled\n' >"$work/network-config"

  local files=("$work/meta-data" "$work/user-data" "$work/network-config")
  if [[ -n $token_file ]]; then
    (umask 077 && cp "$token_file" "$work/token")
    files+=("$work/token")
  fi
  mkfs.fat -C -n CIDATA "$work/cidata.img" 2048 >/dev/null
  mcopy -i "$work/cidata.img" "${files[@]}" ::
}

mkdir -p "$out"

if [[ -n $cidata_only ]]; then
  need mkfs.fat mcopy base64
  build_cidata
  cp "$work/cidata.img" "$work/user-data" "$out/"
  echo "Built $out/cidata.img and $out/user-data"
  exit 0
fi

need curl gpg xorriso mkfs.fat mcopy base64

sums=$(curl -fsSL "$mirror/sha256sums.txt") || die "could not read $mirror/sha256sums.txt"
iso_name=$(awk '$2 ~ /^archlinux-[0-9.]+-x86_64\.iso$/ {print $2; exit}' <<<"$sums")
[[ -n $iso_name ]] || die "no dated ISO in $mirror/sha256sums.txt"
iso_sum=$(awk -v n="$iso_name" '$2 == n {print $1}' <<<"$sums")
iso=$out/$iso_name

if [[ -f $iso && $(sha256 "$iso") == "$iso_sum" ]]; then
  echo "Using $iso, already downloaded."
else
  echo "Downloading $iso_name (about 1.6 GB) from $mirror"
  curl -fL --retry 3 -C - -o "$iso" "$mirror/$iso_name"
  [[ $(sha256 "$iso") == "$iso_sum" ]] || die "checksum mismatch for $iso; delete it and run again"
fi
curl -fsSL -o "$iso.sig" "$mirror/$iso_name.sig"

gnupg=$work/gnupg
mkdir -m 700 "$gnupg"
gpg --homedir "$gnupg" --quiet --auto-key-locate clear,wkd --locate-external-key "$signer" >/dev/null 2>&1 ||
  die "could not fetch the signing key of $signer"
status=$(gpg --homedir "$gnupg" --status-fd 1 --verify "$iso.sig" "$iso" 2>/dev/null) || true
gpgconf --homedir "$gnupg" --kill all 2>/dev/null || true
grep -q "^\[GNUPG:\] VALIDSIG .*$signer_fpr" <<<"$status" ||
  die "the signature on $iso_name is not from $signer_fpr; see https://archlinux.org/download/"
echo "Signature by $signer checks out."

build_cidata

result=$out/ai-arch-${iso_name#archlinux-}
[[ -n $token_file ]] && result=${result%.iso}-with-token.iso
rm -f "$result"
xorriso -indev "$iso" -outdev "$result" \
  -append_partition 3 0x0c "$work/cidata.img" \
  -boot_image any replay >"$work/xorriso.log" 2>&1 || {
  cat "$work/xorriso.log" >&2
  die "xorriso failed"
}
[[ -n $token_file ]] && chmod 600 "$result"

echo "Built $result"
echo "Write it to a USB stick in your own terminal (it asks for sudo):"
echo "  $repo/scripts/write-stick.sh '$result'"
