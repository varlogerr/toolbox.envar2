envar_gen() {
  _envar_func_trap_help _envar_gen_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -A OPTS
  _envar_gen_parse_opts OPTS "${@}" || return $rc

  local -a paths; mapfile -t paths <<< "${OPTS[paths]}"

  local dir
  local real
  local path; for path in "${paths[@]}"; do
    real="$(realpath -m -- "${path}" 2>/dev/null)"

    ! ${OPTS[force]} && [[ -f "${real}" ]] && {
      _envar_func_print_info "Skipping: ${path}"
      continue
    }

    : \
    && dir="$(dirname -- "${path}" 2>/dev/null)" \
    && mkdir -p -- "${dir}" 2>/dev/null \
      || _envar_func_print_warn "Failed creating directory: ${dir}"

    # cd to the dir in order to generate correct ENVAR_NAME in the sample
    (cd -- "${dir}" && _envar_gen_sample > "$(basename -- "${path}")") 2>/dev/null && {
      # don't bother logging for generated to /dev/stdout etc
      if [[ -f ${real} ]]; then _envar_func_print_info "Generated: ${path}"; fi
    } || {
      _envar_func_print_warn "Failed generating: ${path}"
      continue
    }
  done
}

_envar_gen_sample() {
  _envar_func_print "
    # Remove everithing you don't need and add / modify
    # what you want to use.
    #
    # SPECIFICS:
    # * internally environment file is loaded inside an immediately
    #   invoked function with all possible side effects, like:
    #   * you can use \`local\` keyword to create variables only
    #     visible in the current environment file
    #   * variables created with \`declare\` are only visible inside
    #     the current file
    # * You can source another environment (sub-environment), but:
    #   * sub-environment is not registered in envar stack and files
    #   * sub-environment is forced to deskless mode
    #   * \`-n\` option is not applicable for sub-environment
   .
    # Create a variable only visible in the current file. \`declare\`
    # can also be used instead of \`local\`
    local curdir=\"\$(dirname \"\${BASH_SOURCE[0]}\")\"
   .
    # Configure env name and PS1 template
    ENVAR_NAME="$(basename "$(pwd)")"
    ENVAR_PS1_TEMPLATE='${ENVAR_PS1_TEMPLATE}'
   .
    # Create a nice environment
    MEANING_OF_LIFE=69
   .
    reverse_meaning_of_life() {
   .  echo \"\${MEANING_OF_LIFE: -1}\${MEANING_OF_LIFE:0:1}\"
    }
   .
    # Uncomment sourcing another environment if it exists
    #envar_source \"\${curdir}/another.env\"
  "
}

_envar_gen_help() {
  _envar_func_print '
    Generate a demo env file to stdout or DEST
   .
    USAGE
    =====
    envar_gen [-f] [--] [DEST...]
   .
    OPTIONS
    =======
    --            End of options
    -f, --force   Override DEST. Not applicable without DEST
   .
    DEMO
    =====
    ```sh
    # Generate demo to stdout
    envar_gen
   .
    # Generate to files
    envar_gen my1.sh my2.sh
    ```
  '
}

_envar_gen_parse_opts() {
  local -n _opts="${1}"
  shift

  _opts+=(
    [force]=false
  )

  local -a _errbag
  local -a _inval
  local _endopts=false
  local _key
  while :; do
    [[ -n "${1+x}" ]] || break
    ${_endopts} && _key="*" || _key="${1}"

    case "${_key}" in
      --          ) _endopts=true ;;
      -f|--force  ) _opts[force]=true ;;
      -*          ) _inval+=("${1}") ;;
      *           )
        if [[ -n "${1}" ]]; then
          _opts[paths]+="${_opts[paths]+$'\n'}${1}"
        else
          [[ ${#_errbag[@]} -lt 1 ]] && _errbag+=("DEST requires a non-blank value")
        fi
        ;;
    esac

    shift
  done

  [[ ${#_inval[@]} -gt 0 ]] && {
    _errbag+=(
      "Invalid or incompatible arguments:"
      "$(printf -- '* %s\n' "${_inval[@]}")"
    )
  }

  ${_opts[force]} && [[ -z "${_opts[paths]+x}" ]] && {
    _errbag+=("FORCE is not applicable without DEST")
  }

  # apply defaults
  _opts+=(
    [paths]="${_opts[paths]-/dev/stdout}"
  )

  [[ ${#_errbag[@]} -lt 1 ]] || {
    _envar_func_print_err "${_errbag[@]}"
    return 1
  }
}
