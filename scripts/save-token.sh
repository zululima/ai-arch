#!/usr/bin/env bash
# Gets a token with `claude setup-token` and saves it for build-iso.sh --token-file,
# encrypted with gpg when you give a passphrase.
# Run it yourself, in your own terminal, so the token never passes through Claude.
set -euo pipefail

file=${1:-$HOME/.config/ai-arch/token}
command -v claude >/dev/null || { echo 'Claude Code is not installed on this machine.' >&2; exit 1; }
mkdir -p "$(dirname "$file")"
umask 077

claude setup-token
echo
echo "Copy the token printed above and paste it here. Input is hidden."
read -rsp 'Token: ' token
echo
[[ -n $token ]] || { echo 'No token given. Nothing saved.' >&2; exit 1; }
echo
echo 'A passphrase keeps the token safe on a lost stick: the stick asks for it before Claude'
echo 'uses the token. Four or more random words make a good one. Press Enter for none.'
read -rsp 'Passphrase: ' pass
echo
if [[ -z $pass ]]; then
  printf '%s\n' "$token" >"$file"
else
  read -rsp 'Passphrase again: ' again
  echo
  [[ $pass == "$again" ]] || { echo 'The passphrases differ. Nothing saved.' >&2; exit 1; }
  command -v gpg >/dev/null || { echo 'A passphrase needs gpg, which is not installed. Nothing saved.' >&2; exit 1; }
  gnupg=$(mktemp -d)
  trap 'gpgconf --homedir "$gnupg" --kill all 2>/dev/null; rm -rf "$gnupg"' EXIT
  printf '%s\n' "$token" | gpg --homedir "$gnupg" --batch --yes --quiet --pinentry-mode loopback \
    --passphrase-fd 3 --symmetric --armor --cipher-algo AES256 --s2k-mode 3 \
    --s2k-digest-algo SHA512 --s2k-count 65011712 --output "$file" 3<<<"$pass"
fi
echo "Saved to $file. Later builds can use it again; delete it when you are done."
