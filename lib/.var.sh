# _envar_var_set VARNAME VALUE...
# _envar_var_get VARNAME DEFAULT_VALUE || echo "no variable"
# _envar_var_append VARNAME APPEND_VALUE...
# _envar_var_prepend VARNAME PREPEND_VALUE...
# _envar_var_unset VARNAME...

_envar_var() {
  [[ -n "${_ENVAR_VAR+x}" ]] || return 1
  printf -- '%s\n' "${_ENVAR_VAR}"
}

_envar_var_set() {
  __envar_var_arity_check _envar_var_set 2 ${#}
  local key="${1}"
  local ptn="$(__envar_var_ptn "${key}")"
  shift

  _envar_var_unset "${key}"

  _ENVAR_VAR+="${_ENVAR_VAR:+$'\n'}"
  _ENVAR_VAR+="${ptn}"$'\n'
  _ENVAR_VAR+="$(printf -- '%s\n' "${@}" | sed 's/^/  /')"
  _ENVAR_VAR+=$'\n'"${ptn}"
}

_envar_var_get() {
  __envar_var_arity_check _envar_var_get 1 ${#}
  local key="${1}"
  local ptn="$(__envar_var_ptn "${key}")"
  local val

  val="$(
    cat <<< "${_ENVAR_VAR}" \
    | grep -m 1 -A 9999999 -Fx -- "${ptn}"  \
    | grep -m 2 -B 9999999 -Fx -- "${ptn}" \
    | grep -vFx -- "${ptn}" \
    | cat
  )"

  [[ -n "${val}" ]] || {
    [[ -n "${2+x}" ]] && printf -- '%s\n' "${2}"
    return 1
  }
  sed 's/^  //' <<< "${val}"
  return 0
}

_envar_var_append() {
  __envar_var_arity_check _envar_var_append 2 ${#}
  local key="${1}"
  shift
  local vals=("${@}")
  local old_val

  old_val="$(_envar_var_get "${key}")" \
    && vals=("${old_val}" "${vals[@]}")
  _envar_var_set "${key}" "${vals[@]}"
}

_envar_var_prepend() {
  __envar_var_arity_check _envar_var_prepend 2 ${#}
  local key="${1}"
  shift
  local vals=("${@}")
  local old_val

  old_val="$(_envar_var_get "${key}")" \
    && vals+=("${old_val}")
  _envar_var_set "${key}" "${vals[@]}"
}

_envar_var_unset() {
  __envar_var_arity_check _envar_var_unset 1 ${#}
  local ptn
  local lines
  local key; for key in "${@}"; do
    ptn="$(__envar_var_ptn "${key}")"
    lines="$(grep -n -Fx -- "${ptn}" <<< "${_ENVAR_VAR}" | cut -d':' -f1)"
    [[ $(wc -l <<< "${lines}") -lt 2 ]] && continue

    _ENVAR_VAR="$(
      head -n $(( $(head -n 1 <<< "${lines}") - 1 )) <<< "${_ENVAR_VAR}"
      tail -n +$(( $(tail -n 1 <<< "${lines}") + 1 )) <<< "${_ENVAR_VAR}"
    )"
  done
}

__envar_var_ptn() {
  local key="${1}"
  local prefix='$'
  printf -- '%s%s\n' "${prefix}" "${key}"
}

__envar_var_arity_check() {
  local func="${1}"
  local min_args="${2}"
  local act_args="${3}"

  [[ ${min_args} -le ${act_args} ]] && return 0

  _envar_func_print_stderr "warn:${func}" \
    "Minimum args: ${min_args}, actual: ${act_args}." \
    "Results are unpredictable!"
  return 1
}
