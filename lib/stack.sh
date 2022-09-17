# @HELP
# Print desks stack
#
# USAGE
# =====
#   envar_stack [-q] [-f]
#
# OPTIONS
# =======
# -f, --files   Print only files. Incompatible with `-q`
# -q, --quiet   Print only desk names. Incompatible with `-f`
# --notab       Remove prefix before file paths. Automatically
#               applied with `-f`
# @/HELP


envar_stack() {
  _envar_trap_help_opt _envar_stack_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  local -A OPTS
  _envar_stack_parse_opts OPTS "${@}" || return $rc

  local -a filter1=(cat)
  local -a filter2=(cat)
  local -a filter3=(cat)

  ${OPTS[notab]} \
    || filter1=(sed 's/^[^@]/  &/')
  ${OPTS[quiet]} \
    && filter2=(grep '^@')
  ${OPTS[files]} \
    && filter2=(grep -v '^@') \
    && filter3=(_envar_uniq_ordered)

  local stack
  stack="$(_envar_var_get STACK)" || return $?

  "${filter1[@]}" <<< "${stack}" | "${filter2[@]}" | "${filter3[@]}"
}

_envar_stack_push() {
  local is_new="${1:-true}"
  local envname; envname="${2:-"$(_envar_var_get NONAME)"}"
  local files="${3}"
  files="$(tac <<< "${files}")"

  local old_stack; old_stack="$(envar_stack --notab)"
  local head_title
  local head_body
  local tail
  if ${is_new}; then
    # push to stack directly
    head_title="@${envname}"
    head_body="${files:+$'\n'${files}}"
    tail="${old_stack}"
  else
    # alter top stack entry if the stack is not empty
    [[ -n "${old_stack}" ]] || return

    local head
    if [[ $(grep '^@' -c <<< "${old_stack}") -eq 1 ]]; then
      # only entry in the stack
      head="${old_stack}"
      tail=""
    else
      # get all lines from 1st '@'-starting to 2nd '@'-starting (inclusive)
      # and remove last line
      head="$(grep -m 2 -B 999999 '^@' <<< "${old_stack}" | head -n -1)"
      # remove 1st '@' line
      tail="$(sed '1{/^@/d;}' <<< "${old_stack}" | grep -A 999999 '^@')"
    fi

    head_title="$(head -n 1 <<< "${head}")"
    head_body="$(tail -n +2 <<< "${head}")"

    [[ -n "${envname}" ]] && head_title="@${envname}"

    head_body="$(_envar_uniq_ordered <<< "${files:+${files}$'\n'}${head_body}")"
  fi

  _envar_var_set STACK "${head_title}${head_body:+$'\n'${head_body}}${tail:+$'\n'${tail}}"
}

_envar_stack_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_stack_parse_opts() {
  local -n _opts="${1}"
  shift

  local -a _inval
  while :; do
    [[ -n "${1+x}" ]] || break

    case "${1}" in
      -q|--quiet  ) _opts[quiet]=true ;;
      -f|--files  ) _opts[files]=true ;;
      --notab     ) _opts[notab]=true ;;
      *           ) _inval+=("${1}") ;;
    esac

    shift
  done

  # apply defaults
  _opts+=(
    [quiet]="${_opts[quiet]-false}"
    [files]="${_opts[files]-false}"
    [notab]="${_opts[notab]-false}"
  )
  ${_opts[files]} && _opts[notab]=true

  local -a _errbag
  ${_opts[files]} && ${_opts[quiet]} \
    && _errbag+=('QUIET and FILES flags are incompatible.')
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
