# RC:
# * 0   - help option detected
# * 1   - no help option
# * > 1 - failure
_envar_func_trap_help() {
  local help_count=0
  local -a rest
  local -a errbag
  local help_func="${1}"
  shift

  while :; do
    [[ -n "${1+x}" ]] || break
    case "${1}" in
      -h|-\?|--help ) (( help_count++ )) ;;
      *             ) rest+=("${1}") ;;
    esac
    shift
  done

  [[ ${help_count} -lt 1 ]] && return 1

  [[ ${help_count} -gt 1 ]] && errbag+=("Only 1 HELP flag is allowed.")
  [[ ${#rest[@]} -gt 0 ]] && {
    errbag+=(
      "Invalid or incompatible arguments:"
      "$(printf -- '* %s\n' "${rest[@]}")"
    )
  }

  [[ ${#errbag[@]} -lt 1 ]] || {
    _envar_func_print_err "${errbag[@]}"
    return 2
  }

  ${help_func}
  return 0
}

_envar_func_print_stderr() {
  local prefix="${1}"
  shift
  while :; do
    [[ -n "${1+x}" ]] || break
    sed -e 's/^/[envar:'"${prefix}"'] /' <<< "${1}"
    shift
  done >/dev/stderr
}

_envar_func_print_info() {
  [[ ! "${ENVAR_INFO}" =~ ^(true|false)$ ]] && {
    _envar_func_print_warn "Invalid ENVAR_INFO value. Falling back to default"
    ENVAR_INFO=true
  }

  if ${ENVAR_INFO}; then
    _envar_func_print_stderr info "${@}"
  fi
}

_envar_func_print_warn() {
  _envar_func_print_stderr warn "${@}"
}

_envar_func_print_err() {
  _envar_func_print_stderr err "${@}"
}

_envar_func_print() {
  cat <<< "${1-(cat -)}" \
  | grep -Ev '^\s*$' \
  | sed -E -e 's/^\s+//' \
    -e 's/\s+$//' \
    -e 's/^\.//'
}

_envar_func_uniq() {
  # https://unix.stackexchange.com/a/194790
  cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2-
}

# https://gist.github.com/varlogerr/2c058af053921f1e9a0ddc39ab854577#file-sed-quote
sed_quote_ptn() {
  local rex="${1-$(cat)}"
  sed -e 's/[]\/$*.^[]/\\&/g' <<< "${rex}"
}
sed_quote_replace() {
  local replace="${1-$(cat)}"
  sed -e 's/[\/&]/\\&/g' <<< "${replace}"
}
