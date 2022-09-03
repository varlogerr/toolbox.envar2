SUB21_VAR=sub21
echo "${SUB21_VAR}"

local curdir="$(dirname "${BASH_SOURCE[0]}")"
envar_source "${curdir}/../subsub/subsub1-1.sh"
