# @HELP
# Basic initialization of the tool
#
# USAGE
# =====
#   envar_init
# @/HELP

# @DEMO_SPACE
# ENVAR_DEMO="It's a useless demo space!"
# echo "${ENVAR_DEMO}"
# @/DEMO_SPACE

envar_init() {
  _envar_trap_help_opt _envar_init_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_init_parse_opts OPTS "${@}" || return $rc

  local -a user_dirs
  local -a user_spaces

  "${ENVAR_INITD_ENABLED}" && [[ -n "${ENVAR_INITD_PATH}" ]] \
    && user_dirs+=("${ENVAR_INITD_PATH}")
  [[ -n "${ENVAR_SPACE_PATH}" ]] && {
    user_dirs+=("${ENVAR_SPACE_PATH}")
    user_spaces+=("${ENVAR_SPACE_PATH}/demo.sh")
  }

  local dir; for dir in "${user_dirs[@]}"; do
    mkdir -p "${dir}" 2>/dev/null \
      && _envar_log_info "Created: ${dir}" \
      || _envar_log_warn "Failed creating: ${dir}"
  done

  local file; for file in "${user_spaces[@]}"; do
    [[ -f "${file}" ]] && continue
    _envar_init_get_space \
    | tee "${file}" >/dev/null 2>&1 \
      && _envar_log_info "Created: ${file}" \
      || _envar_log_warn "Failed creating: ${file}"
  done
}

_envar_init_get_space() {
  _envar_comment_tag_get DEMO_SPACE "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_init_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_init_parse_opts() {
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
