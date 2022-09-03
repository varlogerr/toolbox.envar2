ENVAR_NAME=mainenv2
ENVAR_PS1_TEMPLATE='{{ ps1 }}@ {{ name }} # '

MAIN2_VAR=main2
echo "${MAIN2_VAR}"

local curdir="$(dirname "${BASH_SOURCE[0]}")"
envar_source "${curdir}/../sub/sub2-1.sh"
