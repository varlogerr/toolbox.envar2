ENVAR_NAME=mainenv1
ENVAR_PS1_TEMPLATE='{{ ps1 }}# {{ name }} > '

MAIN1_VAR=main1
echo "${MAIN1_VAR}"

local curdir="$(dirname "${BASH_SOURCE[0]}")"
envar_source "${curdir}/../sub/"sub1-{1..2}.sh
