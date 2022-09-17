# @HELP
# Source paths. By default load sourced environment in a new
# desk (shell process)
# * for a file path, just source the file
# * for a directory path, source *.env and *.sh files from it
#
# USAGE
# =====
#   envar_source [-d] [-n NAME] [-f PATHFILE...] [--] [PATH...]
#
# OPTIONS
# =======
# --              End of options
# -d, --deskless  Deskless mode (i.e. same shell)
# -f, --pathfile  File to load paths from. One path per line,
#                 empty lines and started with # are ignored.
#                 Pathfile will not be evaluated with bash,
#                 meaning that `~`, `$(pwd)` or `${HOME}`
#                 will not expend to values
# -n, --name      Name environment. Takes priority over
#                 ENVAR_NAME variable. To reset name set with
#                 this option pass it an empty string `-n ''`
#
# ENVIRONMENT VARIABLES
# =====================
# ENVAR_NAME          Environment name
# ENVAR_PS1_TEMPLATE  Template for PS1 when altered by
# .  ENVAR_NAME variable. Defaults to "{{ ps1 }}@ {{ name }} > "
# .  where {{ ps1 }} is substituted by original PS1 and
# .  {{ name }} by environment name
# @/HELP

# ENV VARS:
#   USED BY USERS:
#   * ENVAR_NAME          - environment name
#   * ENVAR_PS1_TEMPLATE  - PS1 template
#   * ENVAR_INFO_LEVEL    - logging level
#
#   USED BY SYSTEM:
#   * #REQUEST_MODE   requested environment type
#   * #REQUEST_PATHS  requested paths
#   * #BASE_PS1       base PS1 string
#   * #STACK          desks stack
#   * #FILES          all loaded files list
#   * _ENVAR_VAR        vars keeper struct (#), created with
#                       the first `envar_source` command
#   * _ENVAR_FROM_DESK  transitional bool variable to denote
#                       subsequent from desk mode request

envar_source() {
  _envar_trap_help_opt _envar_source_help "${@}" && return $? || {
    local fFmqaZbLA2_rc=$?
    [[ $fFmqaZbLA2_rc -gt 1 ]] && return $fFmqaZbLA2_rc
  }

  declare -A fFmqaZbLA2_OPTS
  _envar_source_parse_opts fFmqaZbLA2_OPTS "${@}" || return $rc

  if ! _envar_var_get REQUEST_MODE >/dev/null; then
    # initial source request
    _envar_var_set REQUEST_MODE "${fFmqaZbLA2_OPTS[mode]}"
  else
    _envar_var_unset REQUEST_PATHS
    _envar_var_set REQUEST_MODE sub
  fi

  [[ -n "${fFmqaZbLA2_OPTS[paths]+x}" ]] \
    && _envar_var_set REQUEST_PATHS "${fFmqaZbLA2_OPTS[paths]}"

  _envar_source_trap_request "${@}"
}

_envar_source_trap_request() {
  local -A fFmqaZbLA2_func_map=(
    [desk]=_envar_source_trap_request_desk
    [import]=_envar_source_trap_request_import
    [sub]=_envar_source_trap_request_sub
  )

  # ensure unexport before trap_request_* function
  export -n _ENVAR_VAR \
            ENVAR_NAME \
            ENVAR_PS1_TEMPLATE

  "${fFmqaZbLA2_func_map["$(_envar_var_get REQUEST_MODE)"]}" "${@}"
}

_envar_source_trap_request_desk() {
  local shell=bash
  local last_rc

  # unset REQUEST_MODE for 'desk' to get to
  # 'import' mode (see bootstrap file)
  _envar_var_unset REQUEST_MODE

  declare -A OPTS
  _envar_source_parse_opts OPTS "${@}" || return $rc

  # isolate setting of request name in a sub-process
    _ENVAR_VAR="$(
      # if name is set and empty, reset request name, for non-empty set it to request name
      [[ -n "${OPTS[name]+x}" ]]  && _envar_var_unset REQUEST_NAME
      [[ -n "${OPTS[name]}" ]]    && _envar_var_set REQUEST_NAME "${OPTS[name]}"
      _envar_var
    )" \
    _ENVAR_FROM_DESK=true \
    ENVAR_NAME="${ENVAR_NAME}" \
    ENVAR_PS1_TEMPLATE="${ENVAR_PS1_TEMPLATE}" \
    "${shell}"

  last_rc=$?

  [[ ${last_rc} -eq 69 ]] && envar_halt

  _envar_source_purge_request
}

_envar_source_trap_request_import() {
  local -A fFmqaZbLA2_keep=(
    [from_desk]="${_ENVAR_FROM_DESK:-false}"
  )
  unset _ENVAR_FROM_DESK

  declare -A OPTS
  _envar_source_parse_opts OPTS "${@}" || return $rc
  # if name is empty, reset request name, for non-empty set it to request name
  [[ -n "${OPTS[name]+x}" ]]  && _envar_var_unset REQUEST_NAME
  [[ -n "${OPTS[name]}" ]]    && _envar_var_set REQUEST_NAME "${OPTS[name]}"

  # stash PS1 to BASE_PS1 before sourced envars can change it
  [[ -n "${PS1+x}" ]] && {
    local base_ps1="$(_envar_var_get BASE_PS1 "${PS1}")"
    _envar_var_set BASE_PS1 "${base_ps1}"
    PS1="${base_ps1}"
  }

  # it's important to get request paths before old files sourcing
  # because sub-requests from old files can be added to the current
  # request paths
  fFmqaZbLA2_keep[req_paths]="$(_envar_var_get REQUEST_PATHS)" \
    && fFmqaZbLA2_keep[req_files]="$(_envar_source_normalize_request "${fFmqaZbLA2_keep[req_paths]}")"

  # first silently apply old files without adding them again
  # to the sourced files and stack
  fFmqaZbLA2_keep[old_files]="$(envar_files)" && {
    fFmqaZbLA2_keep[norm_old]="$(_envar_source_normalize_request "$(tac <<< "${fFmqaZbLA2_keep[old_files]}")")"
    _ENVAR_SOURCE_LEVEL=minor _envar_source_apply_files "${fFmqaZbLA2_keep[norm_old]}"
  }

  local fFmqaZbLA2_sourced
  _envar_source_apply_files "${fFmqaZbLA2_keep[req_files]}" fFmqaZbLA2_sourced

  _envar_files_push "${fFmqaZbLA2_sourced}"

  _envar_source_apply_ps1
  _envar_source_purge_request

  # No need to prefix variables starting from here,
  # all requested files are already sourced

  # ensure new stack entry for desk and log entrance
  local envname; envname="$(_envar_var_get REQUEST_NAME "${ENVAR_NAME}")"
  envname="${envname:-"$(_envar_var_get NONAME)"}"
  ${fFmqaZbLA2_keep[from_desk]} && {
    _envar_stack_push true "${envname}"
    _envar_log_info "Desk: ${envname}"
  }

  if envar_stack >/dev/null; then
    _envar_stack_push false "${envname}" "${fFmqaZbLA2_sourced}"
  fi
}

_envar_source_trap_request_sub() {
  local -A fFmqaZbLA2_keep

  fFmqaZbLA2_keep[paths]="$(_envar_var_get REQUEST_PATHS)" \
    && fFmqaZbLA2_keep[files]="$(_envar_source_normalize_request "${fFmqaZbLA2_keep[paths]}")"

  _ENVAR_SOURCE_LEVEL=minor _envar_source_apply_files "${fFmqaZbLA2_keep[files]}"
}

_envar_source_normalize_request() {
  local -a request_arr
  mapfile -t request_arr <<< "${1}"

  local real
  local path; for path in "${request_arr[@]}"; do
    # print if readable named pipe
    [[ (-p "${path}" && -r "${path}" ) ]] \
      && { realpath -s -- "${path}"; continue; }

    real="$(realpath -m -- "${path}" 2> /dev/null)" || {
      _envar_log_warn "Invalid path: ${path}"
      continue
    }

    # print if readable file
    [[ (-f "${real}" && -r "${real}") ]] \
      && { realpath -s -- "${path}"; continue; }

    # print all readable files from the directory
    [[ (-d "${real}" && -r "${real}" && -x "${real}") ]] && {
      # `-L` flag to work nice with symlinks: https://unix.stackexchange.com/a/93858
      find -L "${path}" \( -type f -or -type l \) -readable \
        \( -name '*.env' -or -name '*.sh' \) 2>/dev/null \
      | sort -n | while read -r path; do realpath -s -- "${path}"; done
      continue
    }

    _envar_log_warn "Must be readable file or directory: ${path}"
  done
}

_envar_source_apply_files() {
  local -A fFmqaZbLA2_keep=(
    [all_files]="${1}"
    [log_level]="${_ENVAR_SOURCE_LEVEL:-major}"
  )
  export -n _ENVAR_SOURCE_LEVEL

  local -a fFmqaZbLA2_files_arr
  [[ -n "${fFmqaZbLA2_keep[all_files]}" ]] \
    && mapfile -t fFmqaZbLA2_files_arr <<< "${fFmqaZbLA2_keep[all_files]}"

  [[ -n "${2}" ]] \
    && local -n _fFmqaZbLA2_sourced="${2}" \
    || local _fFmqaZbLA2_sourced
  local fFmqaZbLA2_file; for fFmqaZbLA2_file in "${fFmqaZbLA2_files_arr[@]}"; do
    # source file inside a function for better isolation
    _iife() { unset _iife; . -- "${fFmqaZbLA2_file}"; }; _iife

    _fFmqaZbLA2_sourced+="${_fFmqaZbLA2_sourced:+$'\n'}${fFmqaZbLA2_file}"
    _envar_log_info -t "${fFmqaZbLA2_keep[log_level]}" "Sourced: ${fFmqaZbLA2_file}"
  done
}

_envar_source_apply_ps1() {
  local base_ps1; base_ps1="$(_envar_var_get BASE_PS1)" || return

  [[ "${base_ps1}" != "${PS1}" ]] && {
    # PS1 is modified with loaded env files
    _envar_var_set BASE_PS1 "${PS1}"
    base_ps1="${PS1}"
  }

  local ps1_string="${base_ps1}"
  local envname; envname="$(_envar_var_get REQUEST_NAME "${ENVAR_NAME}")"
  [[ -n "${envname}" ]] && ps1_string="$(
    _envar_template_compile --ps1 "${base_ps1}" \
      --name "${envname}" <<< "${ENVAR_PS1_TEMPLATE}"
  )"

  PS1="${ps1_string}"
}

_envar_source_purge_request() {
  # unset request carriers
  _envar_var_unset \
    REQUEST_MODE \
    REQUEST_PATHS
}

_envar_source_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_source_parse_opts() {
  local -n _opts="${1}"
  shift

  _opts=(
    [mode]=desk
  )

  local -a _errbag
  local _endopts=false
  local -a _inval
  local _key
  local fcontent
  while :; do
    [[ -n "${1+x}" ]] || break
    ${_endopts} && _key="*" || _key="${1}"

    case "${_key}" in
      -d|--deskless ) _opts[mode]=import ;;
      -f|--pathfile )
        shift
        fcontent="$(grep -Ev '^\s*(#.*)?$' -- "${1}" 2>/dev/null)" \
          && _opts[paths]+="${_opts[paths]:+$'\n'}${fcontent}" \
          || { [[ $? -gt 1 ]] && _errbag+=("Must be readable file or pipe: ${1}"); }
        ;;
      -n|--name )
        shift
        [[ -n "${1+x}" ]] \
          && _opts[name]="${1}" \
          || _errbag+=("NAME requires a value")
        ;;
      --  ) _endopts=true ;;
      -*  ) _inval+=("${1}") ;;
      *   ) _opts[paths]+="${_opts[paths]:+$'\n'}${1}" ;;
    esac

    shift
  done

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
