_iife_initd() {
  unset _iife_initd

  while :; do
    [[ -n "${1+x}" ]] || break
    case "${1}" in
      --no-initd    ) ENVAR_INITD_ENABLED=false ;;
      --initd-path  ) shift; ENVAR_INITD_PATH="${1}" ;;
    esac
    shift
  done

  _envar_check_bool "${ENVAR_INITD_ENABLED}" || {
    _envar_log_warn "Invalid ENVAR_INITD_ENABLED value. Falling back to default"
    ENVAR_INITD_ENABLED=true
  }

  "${ENVAR_INITD_ENABLED}" && {
    _envar_var_set SYS_INITD /etc/envar/init.d

    [[ -z "${ENVAR_INITD_PATH}" ]] && {
      _envar_log_warn "ENVAR_INITD_PATH requires a non-blank value. Falling back to default"
      ENVAR_INITD_PATH="$(printf -- '%s' ~/.envar/init.d)"
    }

    local -a init_dirs=("$(_envar_var_get SYS_INITD)")
    local -a to_source

    init_dirs+=("${ENVAR_INITD_PATH}")

    local real
    local d; for d in "${init_dirs[@]}"; do
      real="$(realpath -m -- "${d}" 2>/dev/null)" || continue
      [[ (-d "${real}" && -r "${real}" && -x "${real}") ]] && to_source+=("${d}")
    done

    [[ ${#to_source[@]} -gt 0 ]] && {
      # simulate sourcing in import mode
      _envar_var_set REQUEST_MODE import
      _envar_var_set REQUEST_PATHS "$(printf -- '%s\n' "${to_source[@]}")"
    }
  }
}; _iife_initd "${@}"
