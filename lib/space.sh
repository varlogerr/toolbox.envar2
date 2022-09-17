# @HELP
# Shortcut for loading environments from ${ENVAR_SPACE_PATH}
# directory. Environment name is forced to SPACE.
#
# USAGE
# =====
#   envar_space SPACE
#   envar_space -l
#
# OPTIONS
# =======
# -l, --list  List available spaces
#
# DEMO
# ====
#   # list available spaces
#   envar_space --list
#
#   # run demo space
#   envar_space demo.sh
#
#   # same done with `envar_source`
#   envar_source -n demo.sh "${ENVAR_SPACE_PATH}/demo.sh"
# @/HELP

envar_space() {
  _envar_trap_help_opt _envar_space_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  _envar_space_trap_list_opt "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_space_parse_opts OPTS "${@}" || return $rc

  local name
  # name="$(sed -E 's/\.(sh|env)$//' <<< "${OPTS[path]}")"
  name="${OPTS[path]}"

  envar_source --name "${name}" -- "$(_envar_space_filepath "${OPTS[path]}")"
}

_envar_space_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_space_list() {
  (
    cd -- "${ENVAR_SPACE_PATH}" 2>/dev/null && {
      find -L . \( -type f -or -type l \) -readable \
        \( -name '*.env' -or -name '*.sh' \) \
        -printf "%h\n" 2>/dev/null | sort -u \
      | while read -r path; do
        printf -- '%s\n' "${path}"
        find -L "${path}" \( -type f -or -type l \) -readable \
          \( -name '*.env' -or -name '*.sh' \) 2>/dev/null
      done | sort -u | sort -n | sed 's/^\.\/\?//' | grep -vFx ''
    }
  )
}

_envar_space_filepath() {
  printf -- '%s' "${ENVAR_SPACE_PATH}/${1}"
}

_envar_space_parse_opts() {
  local -n _opts="${1}"
  shift

  local -a _errbag
  while :; do
    [[ -n "${1+x}" ]] || break

    case "${1}" in
      * )
        if [[ -n "${_opts[path]+x}" ]]; then
          [[ ${#_errbag[@]} -lt 1 ]] && _errbag+=("Only 1 SPACE is allowed")
        else
          _opts[path]="${1}"
        fi
        ;;
    esac

    shift
  done

  [[ -n "${_opts[path]}" ]] || {
    _errbag+=("SPACE requires a non-blank value")
  }

  local filepath="$(realpath -m -- "$(_envar_space_filepath "${_opts[path]}")" 2>/dev/null)"

  [[ ${#_errbag[@]} -lt 1 ]] && {
    local errmsg="SPACE must be a readable file or directory: ${_opts[path]}"

    if false \
      || [[ (-f "${filepath}" && -r "${filepath}") ]] \
      || [[ (-d "${filepath}" && -r "${filepath}" && -x "${filepath}") ]] \
    ; then
      :
    else
      _errbag+=("${errmsg}")
    fi
  }

  [[ ${#_errbag[@]} -lt 1 ]] || {
    _envar_log_err "${_errbag[@]}"
    return 1
  }
}

_envar_space_trap_list_opt() {
  local is_list=false

  [[ "${1}" =~ ^(-l|--list)$ ]] \
    && is_list=true && shift

  local -a inval
  while :; do
    [[ -n "${1+x}" ]] || break
    inval+=("${1}")
    shift
  done

  ! ${is_list} && return 1

  ${is_list} && [[ ${#inval[@]} -gt 0 ]] && {
    _envar_print_stdout \
      "Invalid or incompatible arguments:" \
      "$(printf -- '* %s\n' "${inval[@]}")" \
    | _envar_log_err
    return 2
  }

  _envar_space_list

  return 0
}

_envar_space_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case ${COMP_CWORD} in
    1) COMPREPLY=($(compgen -W "$(_envar_space_list)" "${cur}" 2>/dev/null)) ;;
    *) COMPREPLY=() ;;
  esac
}

complete -o default -F _envar_space_complete envar_space 2>/dev/null
