_iife_bootstrap() {
  unset _iife_bootstrap

  # All variables defined before sourcing can intersect with
  # ones declared in sourced files. Prefix them with something
  # hard to hit (fFmqaZbLA2_)
  local -A fFmqaZbLA2_keep=(
    [self]="$(realpath -- "${BASH_SOURCE[0]}")"
    [lib_loaded]=false
  )
  fFmqaZbLA2_keep[app_dir]="$(dirname -- "$(dirname "${fFmqaZbLA2_keep[self]}")")"

  typeset -f _envar_signature_fFmqaZbLA2 >/dev/null \
    && fFmqaZbLA2_keep[lib_loaded]=true

  local fFmqaZbLA2_file; for fFmqaZbLA2_file in \
    lib/.demo.sh \
    lib/.lib.sh \
    lib/files.sh \
    lib/gen.sh \
    lib/halt.sh \
    lib/init.sh \
    lib/source.sh \
    lib/space.sh \
    lib/stack.sh \
  ; do
    ${fFmqaZbLA2_keep[lib_loaded]} && break
    . "${fFmqaZbLA2_keep[app_dir]}/${fFmqaZbLA2_file}"
  done

  _envar_profiler_init

  # defaults
  ENVAR_PS1_TEMPLATE="${ENVAR_PS1_TEMPLATE-"{{ ps1 }}@ {{ name }} > "}"
  ENVAR_INFO_LEVEL="${ENVAR_INFO_LEVEL-major}"

  # the only way to get to this point is either through desk mode
  # subrequest or with initial bootstrap instantiation from shell.
  # in both cases it's 'import' mode
  _envar_var_set REQUEST_MODE import
  _envar_var_set NONAME '<anonymous>'

  . "${fFmqaZbLA2_keep[app_dir]}/app/extra.sh"

  _envar_profiler_run "Before request"

  if ! _envar_var_get BOOTSTRAPPED >/dev/null; then
    . "${fFmqaZbLA2_keep[app_dir]}/app/initd.sh"
    _ENVAR_SOURCE_LEVEL=minor _envar_source_trap_request
  else
    _envar_source_trap_request
  fi

  _envar_profiler_run "After request"

  # indicator that bootstrap has been loaded
  _envar_var_set BOOTSTRAPPED true
}; _iife_bootstrap "${@}"
