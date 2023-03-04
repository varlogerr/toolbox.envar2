# @HELP
# Generate a demo env file to stdout or DEST
#
# USAGE
# =====
#   envar_gen [-f] [--] [DEST...]
#
# OPTIONS
# =======
# --            End of options
# -f, --force   Override DEST. Not applicable without DEST
#
# DEMO
# =====
#   # Generate demo to stdout
#   envar_gen
#
#   # Generate to files
#   envar_gen my1.sh my2.sh
# @/HELP

# @SAMPLE
# # Remove everithing you don't need and add / modify
# # what you want to use.
# #
# # SPECIFICS:
# # * internally environment file is loaded inside an immediately
# #   invoked function with all possible side effects, like:
# #   * you can use `local` keyword to create variables only
# #     visible in the current environment file
# #   * variables created with `declare` are only visible inside
# #     the current file
# # * You can source another environment (sub-environment), but:
# #   * sub-environment is not registered in envar stack and files
# #   * sub-environment is forced to deskless mode
# #   * `-n` option is not applicable for sub-environment
#
#
# # # Create a variable only visible in the current file.
# # # `local` can also be used instead of `declare`
# # declare CURDIR; CURDIR="$(realpath -- "$(dirname -- "${BASH_SOURCE[0]}")")"
#
# # # Extend environment by sourcing another
# # # environment file if it exists
# # envar_source -- "${CURDIR}/another.env"
#
# # # Configure env name
# # ENVAR_NAME="$(basename -- "$(pwd)")"
#
# # # Configure PS1 template
# # ENVAR_PS1_TEMPLATE='{{ ps1-template }}'
#
# # # Create a nice environment
# # {
# #   MEANING_OF_LIFE=69
# #
# #   reverse_meaning_of_life() {
# #     echo "${MEANING_OF_LIFE: -1}${MEANING_OF_LIFE:0:1}"
# #   }
# # }
# @/SAMPLE

envar_gen() {
  _envar_trap_help_opt _envar_gen_help "${@}" && return $? || {
    local rc=$?
    [[ $rc -gt 1 ]] && return $rc
  }

  declare -a PASSTHROUGH
  _envar_gen_parse_opts PASSTHROUGH "${@}" || return $rc

  _envar_file2dest <(_envar_gen_sample) "${PASSTHROUGH[@]}"
}

_envar_gen_sample() {
  _envar_comment_tag_get SAMPLE "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter \
  | _envar_template_compile --ps1-template "${ENVAR_PS1_TEMPLATE}"
}

_envar_gen_help() {
  _envar_comment_tag_get HELP "${BASH_SOURCE[@]}" \
  | _envar_tag_comment_strip_filter
}

_envar_gen_parse_opts() {
  local -n _opts="${1}"
  shift

  while :; do
    [[ -n "${1+x}" ]] || break
    case "${_key}" in
      --          ) _opts+=("${1}") ;;
      -f|--force  ) _opts+=("${1}") ;;
      -*          ) _inval+=("${1}") ;;
      *           ) _opts+=("${1}") ;;
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
