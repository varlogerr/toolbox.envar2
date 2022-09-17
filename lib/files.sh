# @HELP
# Print all loaded files
# @/HELP

envar_files() {
  _envar_trap_help_opt _envar_files_help "${@}" && return $? || {
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
    _envar_uniq_ordered <<< "${new_files}${old_files:+$'\n'${old_files}}"
  )"
}

_envar_files_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_files_parse_opts() {
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
