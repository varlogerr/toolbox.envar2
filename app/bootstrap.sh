_iife_bootstrap() {
  unset _iife_bootstrap

  local self="$(realpath -- "${BASH_SOURCE[0]}")"
  local app_dir="$(dirname -- "$(dirname "${self}")")"

  local f; for f in \
    "lib/.demo.sh" \
    "lib/.func.sh" \
    "lib/.var.sh" \
    "lib/files.sh" \
    "lib/gen.sh" \
    "lib/halt.sh" \
    "lib/init.sh" \
    "lib/source.sh" \
    "lib/space.sh" \
    "lib/stack.sh" \
  ; do . "${app_dir}/${f}"; done

  # defaults
  ENVAR_NAME="${ENVAR_NAME-}"
  ENVAR_PS1_TEMPLATE="${ENVAR_PS1_TEMPLATE-"{{ ps1 }}@ {{ name }} > "}"
  ENVAR_INFO="${ENVAR_INFO-true}"

  # the only way to get to this point is either through desk mode
  # subrequest or with initial bootstrap instantiation from shell.
  # in both cases it's 'import' mode
  _envar_var_set REQUEST_MODE import
  _envar_var_set NONAME '<anonymous>'

  _envar_source_trap_request

  . "${app_dir}/app/extra.sh"

  # indicator that bootstrap has been loaded
  _envar_var_set BOOTSTRAPPED true
}; _iife_bootstrap "${@}"
