#!/usr/bin/env bash
# Saves a token from `claude setup-token` for build-iso.sh --token-file.
# Run it yourself, in your own terminal, so the token never passes through Claude.
set -euo pipefail

file=${1:-$HOME/.config/ai-arch/token}
mkdir -p "$(dirname "$file")"
umask 077
echo "Run 'claude setup-token' first, then paste the token it printed. Input is hidden."
read -rsp 'Token: ' token
echo
[[ -n $token ]] || { echo 'No token given. Nothing saved.' >&2; exit 1; }
printf '%s\n' "$token" >"$file"
echo "Saved to $file. Delete it once the stick is written if you will not build another."
