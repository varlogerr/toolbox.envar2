# @HELP
# Alias for all envar_* functions. `.` action is a synonym of
# `source`. Use `envar ACTION -h` to view an action help
#
# USAGE
# =====
#   envar [ACTION] [ACTION_ARGS]
#
# ACTIONS
# =======
# {{ short_actions }}
#
# DEV FEATURES
# ============
# {{ help_dev }}
# @/HELP

# @HELP_DEV
# _ENVAR_PROFILER_ENABLED (boolean)
#   control for profiler
# ENVAR_INFO_LEVEL (none, major, minor)
#   control inro log level
# _envar_demo
#   generate demo stub
# _envar_var
#   print complete _ENVAR_VAR structure
# @/HELP_DEV

envar() {
  _envar_trap_help_opt _envar_help "${@}" && return $? || {
    local fFmqaZbLA2_rc=$?
    [[ $fFmqaZbLA2_rc -gt 1 ]] && return $fFmqaZbLA2_rc
  }

  local -A fFmqaZbLA2_OPTS
  _envar_parse_opts fFmqaZbLA2_OPTS "${@}" || return $?
  shift

  "envar_${fFmqaZbLA2_OPTS[action]}" "${@}"
}

_envar_short_actions() {
  local self="$(realpath -- "${BASH_SOURCE[0]}")"
  local dir="$(dirname "${self}")"
  echo '.'
  cat "${dir}"/*.sh | grep -o -e '^envar_[^ |(]\+' | cut -d_ -f2
}

_envar_help() {
  local short_actions; short_actions="$(_envar_short_actions)"
  local help_dev; help_dev="$(_envar_help_dev)"
  local help_msg; help_msg="$(
    _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
    | _envar_tag_comment_strip_filter
  )"

  local short_actions_line; short_actions_line="$(
    grep -n '^{{\s*short_actions\s*}}\s*$' <<< "${help_msg}" \
    | head -n 1 | cut -d: -f1
  )"

  help_msg="$(
    printf -- '%s\n' "${help_msg}" | head -n $(( short_actions_line - 1 ))
    printf -- '%s\n' "${short_actions}"
    printf -- '%s\n' "${help_msg}" | sed -n "$(( short_actions_line + 1 ))"',$p'
  )"

  local help_dev_line; help_dev_line="$(
    grep -n '^{{\s*help_dev\s*}}\s*$' <<< "${help_msg}" \
    | head -n 1 | cut -d: -f1
  )"

  help_msg="$(
    printf -- '%s\n' "${help_msg}" | head -n $(( help_dev_line - 1 ))
    printf -- '%s\n' "${help_dev}"
    printf -- '%s\n' "${help_msg}" | sed -n "$(( help_dev_line + 1 ))"',$p'
  )"

  printf -- '%s\n' "${help_msg}"
}

_envar_help_dev() {
  _envar_comment_tag_get HELP_DEV "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_parse_opts() {
  local -n _opts="${1}"
  shift

  grep -qFxf <(_envar_short_actions) <<< "${1}" || {
    _envar_log_err "Invalid action: ${1}"
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
        COMPREPLY=($(compgen -W "$(_envar_space_list)" "${cur}" 2>/dev/null))
      else
        COMPREPLY=()
      fi
      ;;
    *) COMPREPLY=() ;;
  esac
}

complete -o default -F _envar_complete envar 2>/dev/null
