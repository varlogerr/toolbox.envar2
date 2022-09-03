envar_space() {
  _envar_func_trap_help _envar_space_help "${@}" && return $? || {
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
  _envar_func_print "
    Shortcut for loading environments from \${ENVAR_SPACE_PATH}
    directory. Environment name is forced to SPACE.
   .
    USAGE
    =====
    envar_space SPACE
   .
    DEMO
    ====
    \`\`\`sh
    # run demo space
    envar_space demo.sh
   .
    # same done with \`envar_source\`
    envar_source -n demo.sh \"\${ENVAR_SPACE_PATH}/demo.sh\"
    \`\`\`
  "
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
    _envar_func_print_err "${_errbag[@]}"
    return 1
  }
}
