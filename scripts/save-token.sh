#!/usr/bin/env bash
# Gets a token with `claude setup-token` and saves it for build-iso.sh --token-file.
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
printf '%s\n' "$token" >"$file"
echo "Saved to $file. Later builds can use it again; delete it when you are done."
