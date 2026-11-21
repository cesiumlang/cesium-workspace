#!/usr/bin/env bash
# SessionStart hook: the environment of the workspace's .envrc files, through
# direnv, for every command of the session (written to CLAUDE_ENV_FILE).
# Does nothing without direnv (on PATH or in buildtools' opt/).
[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd) || exit 0
lib=$root/cesium-src/buildtools/utils/direnv_load.sh
[ -f "$lib" ] || exit 0
# shellcheck source=../../cesium-src/buildtools/utils/direnv_load.sh
source "$lib"
exe=$(direnv_find) || exit 0
cd "$root" || exit 0

# write what direnv changes in the exported variables
export DIRENV_LOG_FORMAT=
declare -A old
for name in $(compgen -e); do old[$name]=${!name}; done
direnv_load "$exe"
{
  for name in $(compgen -e); do
    [[ -v old[$name] && ${old[$name]} == "${!name}" ]] || declare -p "$name"
    unset "old[$name]"
  done
  for name in "${!old[@]}"; do echo "unset $name"; done
} >> "$CLAUDE_ENV_FILE"
exit 0
