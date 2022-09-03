envar_files() {
  _envar_func_trap_help _envar_files_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_files_parse_opts OPTS "${@}" || return $rc

  _envar_var_get FILES
}

_envar_files_push() {
  local new_files="${1}"
  [[ -n "${new_files}" ]] || return

  new_files="$(tac <<< "${new_files}")"
  old_files="$(envar_files)"
  _envar_var_set FILES "$(
    _envar_func_uniq <<< "${new_files}${old_files:+$'\n'${old_files}}"
  )"
}

_envar_files_help() {
  _envar_func_print 'Print all loaded files'
}

_envar_files_parse_opts() {
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
