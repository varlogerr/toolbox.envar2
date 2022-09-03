_envar_demo() {
  _envar_func_trap_help _envar_demo_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  local curdir="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"
  local demodir="$(realpath -- "${curdir}/../.demo")"

  declare -A OPTS
  _envar_demo_parse_opts OPTS "${@}" || return $rc

  cp -Tr "${demodir}" -- "${OPTS[path]}" 2>/dev/null && {
    _envar_func_print_info "Generated: ${OPTS[path]}"
  } || {
    _envar_func_print_warn "Failed generating: ${OPTS[path]}"
  }
}

_envar_demo_help() {
  _envar_func_print "
    Generate demo directory
   .
    USAGE
    =====
    _envar_demo DEST
   .
    DEMO
    ====
    \`\`\`sh
    _envar_demo ./mydemodir
    \`\`\`
  "
}

_envar_demo_parse_opts() {
  local -n _opts="${1}"
  shift

  local -a _errbag
  while :; do
    [[ -n "${1+x}" ]] || break

    case "${1}" in
      * )
        if [[ -n "${_opts[path]+x}" ]]; then
          [[ ${#_errbag[@]} -lt 1 ]] && _errbag+=("Only 1 DEST is allowed")
        else
          _opts[path]="${1}"
        fi
        ;;
    esac

    shift
  done

  [[ -n "${_opts[path]}" ]] || {
    _errbag+=("DEST requires a non-blank value")
  }

  [[ ${#_errbag[@]} -lt 1 ]] || {
    _envar_func_print_err "${_errbag[@]}"
    return 1
  }
}
