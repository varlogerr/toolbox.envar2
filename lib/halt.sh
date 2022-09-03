envar_halt() {
  _envar_func_trap_help _envar_halt_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_halt_parse_opts OPTS "${@}" || return $rc

  envar_stack >/dev/null && exit 69 2>/dev/null
}

_envar_halt_help() {
  _envar_func_print 'Leave all desks'
}

_envar_halt_parse_opts() {
  local -n _opts="${1}"
  shift

  local -a _inval
  while :; do
    [[ -n "${1+x}" ]] || break

    case "${1}" in
      * ) _inval+=("${1}") ;;
    esac

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
    _envar_func_print_err "${_errbag[@]}"
    return 1
  }
}
