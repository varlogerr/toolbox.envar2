_iife_extra() {
  unset _iife_extra

  ENVAR_ALIAS_ENABLED="${ENVAR_ALIAS_ENABLED-true}"
  ENVAR_SPACE_PATH="${ENVAR_SPACE_PATH-$(printf -- '%s' ~/.envar/spaces)}"

  while :; do
    [[ -n "${1+x}" ]] || break
    case "${1}" in
      --no-alias    ) ENVAR_ALIAS_ENABLED=false ;;
      --space-path  ) shift; ENVAR_SPACE_PATH="${1}" ;;
    esac
    shift
  done

  _envar_check_bool "${ENVAR_ALIAS_ENABLED}" || {
    _envar_log_warn "Invalid ENVAR_ALIAS_ENABLED value. Falling back to default"
    ENVAR_ALIAS_ENABLED=true
  }

  [[ -z "${ENVAR_SPACE_PATH}" ]] && {
    _envar_log_warn "ENVAR_SPACE_PATH requires a non-blank value. Falling back to default"
    ENVAR_SPACE_PATH="$(printf -- '%s' ~/.envar/spaces)"
  }

  if ${ENVAR_ALIAS_ENABLED}; then
    . "${fFmqaZbLA2_keep[app_dir]}/lib/.short.sh"
  fi
}; _iife_extra "${@}"
