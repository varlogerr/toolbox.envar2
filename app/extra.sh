#
# enable extra features
#

_iife_extra() {
  unset _iife_extra

  ENVAR_ALIAS_ENABLED="${ENVAR_ALIAS_ENABLED-true}"
  ENVAR_INITD_ENABLED="${ENVAR_INITD_ENABLED-true}"
  ENVAR_INITD_PATH="${ENVAR_INITD_PATH-$(printf -- '%s' ~/.envar/init.d)}"
  ENVAR_SPACE_PATH="${ENVAR_SPACE_PATH-$(printf -- '%s' ~/.envar/spaces)}"

  while :; do
    [[ -n "${1+x}" ]] || break
    case "${1}" in
      --no-alias    ) ENVAR_ALIAS_ENABLED=false ;;
      --no-initd    ) ENVAR_INITD_ENABLED=false ;;
      --initd-path  ) shift; ENVAR_INITD_PATH="${1}" ;;
      --space-path  ) shift; ENVAR_SPACE_PATH="${1}" ;;
    esac
    shift
  done

  [[ ! "${ENVAR_ALIAS_ENABLED}" =~ ^(true|false)$ ]] && {
    _envar_func_print_warn "Invalid ENVAR_ALIAS_ENABLED value. Falling back to default"
    ENVAR_ALIAS_ENABLED=true
  }

  [[ ! "${ENVAR_INITD_ENABLED}" =~ ^(true|false)$ ]] && {
    _envar_func_print_warn "Invalid ENVAR_INITD_ENABLED value. Falling back to default"
    ENVAR_INITD_ENABLED=true
  }

  "${ENVAR_INITD_ENABLED}" && {
    _envar_var_set SYS_INITD /etc/envar/init.d

    [[ -z "${ENVAR_INITD_PATH}" ]] && {
      _envar_func_print_warn "ENVAR_INITD_PATH requires a non-blank value. Falling back to default"
      ENVAR_INITD_PATH="$(printf -- '%s' ~/.envar/init.d)"
    }
  }

  [[ -z "${ENVAR_SPACE_PATH}" ]] && {
    _envar_func_print_warn "ENVAR_SPACE_PATH requires a non-blank value. Falling back to default"
    ENVAR_SPACE_PATH="$(printf -- '%s' ~/.envar/spaces)"
  }

  if ${ENVAR_ALIAS_ENABLED}; then
    . "${app_dir}/lib/.short.sh"
  fi

  if ! _envar_var_get BOOTSTRAPPED >/dev/null; then
    if ${ENVAR_INITD_ENABLED}; then
      local -a init_dirs=("$(_envar_var_get SYS_INITD)")
      local -a to_source

      init_dirs+=("${ENVAR_INITD_PATH}")

      local real
      local d; for d in "${init_dirs[@]}"; do
        real="$(realpath -m -- "${d}" 2>/dev/null)" || continue
        [[ (-d "${real}" && -r "${real}" && -x "${real}") ]] && to_source+=("${d}")
      done

      ENVAR_INFO=false envar_source -d "${to_source[@]}"
    fi
  fi
}; _iife_extra "${@}"
