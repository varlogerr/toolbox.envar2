# @HELP
# Generate demo directory
#
# USAGE
# =====
#   _envar_demo DEST
#
# DEMO
# ====
#   _envar_demo ./demodir
# @/HELP

_envar_demo() {
  _envar_trap_help_opt _envar_demo_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -a PASSTHROUGH
  _envar_demo_parse_opts PASSTHROUGH "${@}" || return $rc

  local curdir="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"
  local demodir="$(realpath -- "${curdir}/../.demo")"
  local demofiles
  local -a files_arr

  demofiles="$(cd "${demodir}";  find . -type f)"
  mapfile -t files_arr <<< "${demofiles}"

  local src
  local f; for f in "${files_arr[@]}"; do
    src="${demodir}/${f}"
    f="$(realpath -m --relative-to . -s -- "${PASSTHROUGH[0]}/${f}")"
    _envar_file2dest -- "${src}" "${f}"
  done
}

_envar_demo_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_demo_parse_opts() {
  local -n _opts="${1}"
  local -a _errbag
  shift

  while :; do
    [[ -n "${1+x}" ]] || break
    _opts+=("${1}")
    shift
  done

  [[ ${#_opts[@]} -gt 1 ]] && _errbag+=("Only 1 DEST is allowed")
  [[ -z "${_opts[0]}" ]] && _errbag+=("DEST requires a non-blank value")

  [[ ${#_errbag[@]} -lt 1 ]] || {
    _envar_log_err "${_errbag[@]}"
    return 1
  }
}
