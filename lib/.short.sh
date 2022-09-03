envar() {
  # can't use trap help function here as `-h` flag
  # can be transpassed to an action
  [[ "${1}" =~ ^(-h|-\?|--help)$ ]] \
    && _envar_help "${@}" && return 0

  declare -A OPTS
  _envar_parse_opts OPTS "${@}" || return $?
  shift

  local func="envar_${OPTS[action]}"
  "${func}" "${@}"
}

_envar_short_actions() {
  echo '.'
  typeset -F | rev | cut -d' ' -f1 | rev | grep '^envar_' \
  | cut -d '_' -f2-
}

_envar_help() {
  _envar_func_print "
    Alias for all envar_* functions. \`.\` action is a synonym of
    \`source\`. Use \`envar ACTION -h\` to view an action help
   .
    USAGE
    =====
    envar [ACTION] [ACTION_ARGS]
   .
    ACTIONS
    =======
  "
  _envar_short_actions
}

_envar_parse_opts() {
  local -n _opts="${1}"
  shift

  grep -qFxf <(_envar_short_actions) <<< "${1}" || {
    _envar_func_print_err "Invalid action: ${1}"
    return 1
  }

  _opts[action]="${1}"
  [[ "${_opts[action]}" == '.' ]] && _opts[action]=source
  return 0
}

_envar_complete() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case ${COMP_CWORD} in
    1) COMPREPLY=($(compgen -W "$(_envar_short_actions | xargs)" "${cur}" 2>/dev/null)) ;;
    2)
      if [[ "${prev}" == space ]]; then
        local envs="$(
          cd -- "${ENVAR_SPACE_PATH}" 2>/dev/null && {
            find -L . \( -type f -or -type l \) -readable \
              \( -name '*.env' -or -name '*.sh' \) \
              -printf "%h\n" 2>/dev/null \
            | while read -r path; do
              printf -- '%s\n' "${path}"
              find -L "${path}" \( -type f -or -type l \) -readable \
                \( -name '*.env' -or -name '*.sh' \) 2>/dev/null
            done | sort -u | sort -n | sed -E 's/^\.\/?//' | grep -vFx ''
          }
        )"
        COMPREPLY=($(compgen -W "${envs}" "${cur}" 2>/dev/null))
      else
        COMPREPLY=()
      fi
      ;;
    *) COMPREPLY=() ;;
  esac
}

complete -o default -F _envar_complete envar 2>/dev/null
