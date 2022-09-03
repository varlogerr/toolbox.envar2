# ENV VARS:
#   USED BY USERS:
#   * ENVAR_NAME          - environment name
#   * ENVAR_PS1_TEMPLATE  - PS1 template
#   * ENVAR_INFO          - bool for show info messages
#
#   USED BY SYSTEM:
#   * #REQUEST_MODE   requested environment type
#   * #REQUEST_NAME   requested environment name
#   * #REQUEST_PATHS  requested paths
#   * #BASE_PS1       base PS1 string
#   * #STACK          desks stack
#   * #FILES          all loaded files list
#   * _ENVAR_VAR        vars keeper struct (#), created with
#                       the first `envar_source` command
#   * _ENVAR_FROM_DESK  transitional bool variable to denote
#                       subsequent from desk mode request

envar_source() {
  _envar_func_trap_help _envar_source_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_source_parse_opts OPTS "${@}" || return $rc

  if ! _envar_var_get REQUEST_MODE >/dev/null; then
    # initial source request

    _envar_var_set REQUEST_MODE "${OPTS[mode]}"

    [[ -n "${OPTS[name]+x}" ]]  && _envar_var_set REQUEST_NAME "${OPTS[name]}"
    [[ -n "${OPTS[paths]+x}" ]] && _envar_var_set REQUEST_PATHS "${OPTS[paths]}"
  else
    _envar_var_unset REQUEST_PATHS
    _envar_var_set REQUEST_MODE sub
    [[ -n "${OPTS[paths]+x}" ]] && _envar_var_set REQUEST_PATHS "${OPTS[paths]}"
  fi

  _envar_source_trap_request
}

_envar_source_trap_request() {
  local -A func_map=(
    [desk]=_envar_source_trap_request_desk
    [import]=_envar_source_trap_request_import
    [sub]=_envar_source_trap_request_sub
  )

  # ensure unexport before trap_request_* function
  export -n _ENVAR_VAR \
            ENVAR_NAME \
            ENVAR_PS1_TEMPLATE \
            ENVAR_INFO

  "${func_map["$(_envar_var_get REQUEST_MODE)"]}"
}

_envar_source_trap_request_desk() {
  local shell=bash
  local last_rc

  # unset REQUEST_MODE for 'desk' to get to
  # 'import' mode (see bootstrap file)
  _envar_var_unset REQUEST_MODE

  _ENVAR_VAR="${_ENVAR_VAR}" \
  _ENVAR_FROM_DESK=true \
  ENVAR_NAME="${ENVAR_NAME}" \
  ENVAR_PS1_TEMPLATE="${ENVAR_PS1_TEMPLATE}" \
  ENVAR_INFO="${ENVAR_INFO}" \
  "${shell}"

  last_rc=$?

  [[ ${last_rc} -eq 69 ]] && envar_halt

  _envar_source_purge_request
}

_envar_source_trap_request_import() {
  local old_files
  local req_paths
  local req_files
  local from_desk="${_ENVAR_FROM_DESK:-false}"
  unset _ENVAR_FROM_DESK

  # stash PS1 to BASE_PS1 before sourced envars can change it
  [[ -n "${PS1+x}" ]] && {
    local base_ps1="$(_envar_var_get BASE_PS1 "${PS1}")"
    _envar_var_set BASE_PS1 "${base_ps1}"
    PS1="${base_ps1}"
  }

  # it's important to get request paths before old files sourcing
  # because sub-requests from old files can be added to the current
  # request paths
  req_paths="$(_envar_var_get REQUEST_PATHS)" \
    && req_files="$(_envar_source_normalize_request "${req_paths}")"

  # first silently apply old files without adding them again
  # to the sourced files and stack
  old_files="$(envar_files)" && {
    local norm_old
    norm_old="$(_envar_source_normalize_request "$(tac <<< "${old_files}")")"
    ENVAR_INFO=false _envar_source_apply_files "${norm_old}"
  }

  local sourced
  _envar_source_apply_files "${req_files}" sourced

  _envar_files_push "${sourced}"

  _envar_source_apply_ps1
  _envar_source_purge_request

  # ensure new stack entry for desk and log entrance
  local envname; envname="${ENVAR_NAME:-"$(_envar_var_get NONAME)"}"
  ${from_desk} && {
    _envar_stack_push true "${envname}"
    _envar_func_print_info "Desk: ${envname}"
  }

  if envar_stack >/dev/null; then
    _envar_stack_push false "${envname}" "${sourced}"
  fi
}

_envar_source_trap_request_sub() {
  local req_paths
  local req_files

  req_paths="$(_envar_var_get REQUEST_PATHS)" \
    && req_files="$(_envar_source_normalize_request "${req_paths}")"

  ENVAR_INFO=false _envar_source_apply_files "${req_files}"
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
      _envar_func_print_warn "Invalid path: ${path}"
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

    _envar_func_print_warn "Must be readable file or directory: ${path}"
  done
}

_envar_source_apply_files() {
  local requested_files="${1}"
  local all_files="${requested_files}"
  local -a files_arr
  [[ -n "${all_files}" ]] && mapfile -t files_arr <<< "${all_files}"

  [[ -n "${2}" ]] \
    && local -n _sourced="${2}" \
    || local _sourced
  local file; for file in "${files_arr[@]}"; do
    # source file inside a function for better isolation
    _iife() { unset _iife; . -- "${file}"; }; _iife

    _sourced+="${_sourced:+$'\n'}${file}"
    _envar_func_print_info "Sourced: ${file}"
  done
}

_envar_source_apply_ps1() {
  local base_ps1

  base_ps1="$(_envar_var_get BASE_PS1)" || return

  [[ "${base_ps1}" != "${PS1}" ]] && {
    # PS1 is modified with loaded env files
    _envar_var_set BASE_PS1 "${PS1}"
    base_ps1="${PS1}"
  }

  # request name wins over the one from previous state
  local envname
  envname="$(_envar_var_get REQUEST_NAME "${ENVAR_NAME}")" && ENVAR_NAME="${envname}"

  local ps1_string="${base_ps1}"
  [[ -n "${envname}" ]] && {
    local escaped_name="$(sed_quote_replace "${envname}")"
    local escaped_ps1="$(sed_quote_replace "${base_ps1}")"
    ps1_string="$(sed -e 's/{{\s*ps1\s*}}/'"${escaped_ps1}"'/' \
      -e 's/{{\s*name\s*}}/'"${escaped_name}"'/' <<< "${ENVAR_PS1_TEMPLATE}")"
  }

  PS1="${ps1_string}"
}

_envar_source_purge_request() {
  # unset request carriers
  _envar_var_unset \
    REQUEST_MODE \
    REQUEST_NAME \
    REQUEST_PATHS
}

_envar_source_help() {
  _envar_func_print '
    Source paths. By default load sourced environment in a new
    desk (shell process)
    * for a file path, just source the file
    * for a directory path, source *.env and *.sh files from it
   .
    USAGE
    =====
    envar_source [-d] [-n NAME] [-f PATHFILE...] [--] [PATH...]
   .
    OPTIONS
    =======
    --              End of options
    -d, --deskless  Deskless mode (i.e. same shell)
    -f, --pathfile  File to load paths from. One path per line,
   .                empty lines and started with # are ignored.
   .                Pathfile will not be evaluated with bash,
   .                meaning that `~`, `$(pwd)` or `${HOME}`
   .                will not expend to values
    -n, --name      Name environment
   .
    ENVIRONMENT VARIABLES
    =====================
    ENVAR_NAME          Environment name
    ENVAR_PS1_TEMPLATE  Template for PS1 when altered by
   .  ENVAR_NAME variable. Defaults to
   .  "{{ ps1 }}@{{ name }} > " where {{ ps1 }} is substituted
   .  by original PS1 and {{ name }} by environment name
    ENVAR_INFO          true of false, defaults to true. Enable
   .  info messages on sourced files
  '
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
    _envar_func_print_err "${_errbag[@]}"
    return 1
  }
}
