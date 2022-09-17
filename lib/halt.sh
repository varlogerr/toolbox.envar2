# @HELP
# Leave all desks
# @/HELP

envar_halt() {
  _envar_trap_help_opt _envar_halt_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_halt_parse_opts OPTS "${@}" || return $rc

  envar_stack >/dev/null && exit 69 2>/dev/null
}

_envar_halt_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_halt_parse_opts() {
  local -n _opts="${1}"
  shift

  local -a _inval
  while :; do
    [[ -n "${1+x}" ]] || break
    _inval+=("${1}")
    shift
  done

  local -a _errbag
  [[ ${#_inval[@]} -gt 0 ]] && {
    _errbag+=(
      "Invalid or incompatible arguments:"
      "$(printf -- '* %s\n' "${_inval[@]}")"
    )
  }

  [[ ${#_errbag[@]} -lt 1 ]] || {
    _envar_log_err "${_errbag[@]}"
    return 1
  }
}
