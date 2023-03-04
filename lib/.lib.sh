# {SHLIB_GEN}
  ##### {CONF}
  #####
  #
  # Tool name to be used in log prefix.
  # Leave blank to use only log type for prefix
  _ENVAR_LOG_TOOLNAME="${_ENVAR_LOG_TOOLNAME:-}"
  #
  # This three are used for logging (see logs functions description)
  # Available values:
  # * none    - don't log
  # * major   - log only major
  # * minor   - log everything
  # If not defined or values misspelled, defaults to 'major'
  _ENVAR_LOG_INFO_LEVEL="${_ENVAR_LOG_INFO_LEVEL-major}"
  _ENVAR_LOG_WARN_LEVEL="${_ENVAR_LOG_WARN_LEVEL-major}"
  _ENVAR_LOG_ERR_LEVEL="${_ENVAR_LOG_ERR_LEVEL-major}"
  #
  # Profiler
  _ENVAR_PROFILER_ENABLED="${_ENVAR_PROFILER_ENABLED-false}"
  #
  #####
  ##### {/CONF}

  # FUNCTIONS:
  # * _envar_file2dest [-f] [--tag TAG] [--tag-prefix TAG_PREFIX] [--] SOURCE [DEST...]
  # * _envar_print_stderr MSG...               (stdin MSG is supported)
  # * _envar_print_stdout MSG...               (stdin MSG is supported)
  # * _envar_log_* [-t LEVEL_TAG] [--] MSG...  (stdin MSG is supported)
  # * _envar_text_ltrim TEXT...    (stdin TEXT is supported)
  # * _envar_text_rtrim TEXT...    (stdin TEXT is supported)
  # * _envar_text_trim TEXT...     (stdin TEXT is supported)
  # * _envar_text_rmblank TEXT...  (stdin TEXT is supported)
  # * _envar_text_clean TEXT...    (stdin TEXT is supported)
  # * _envar_text_decore TEXT...   (stdin TEXT is supported)
  # * _envar_trap_help_opt ARG...
  # * _envar_trap_fatal [--decore] [--] RC [MSG...]
  # * _envar_tag_node_set [--prefix PREFIX] [--suffix SUFFIX] [--] TAG CONTENT TEXT...
  #   (stdin TEXT is supported)
  # * _envar_tag_node_get [--prefix PREFIX] [--suffix SUFFIX] [--strip] [--] TAG TEXT...
  #   (stdin TEXT is supported)
  # * _envar_tag_node_rm [--prefix PREFIX] [--suffix SUFFIX] [--] TAG TEXT...
  #   (stdin TEXT is supported)
  # * _envar_rc_add INIT_RC ADD_RC
  # * _envar_rc_has INIT_RC CHECK_RC
  # * _envar_check_bool VALUE
  # * _envar_check_unix_login VALUE
  # * _envar_check_ip4 VALUE
  # * _envar_check_loopback_ip4 VALUE
  # * _envar_gen_rand [--len LEN] [--num] [--special] [--uc]
  # * _envar_uniq_ordered [-r] -- FILE...      (stdin FILE_TEXT is supported)
  # * _envar_template_compile [-o] [-f] [-s] [--KEY VALUE...] [--] FILE...
  #   (stdin FILE_TEXT is supported)
  # * _envar_sed_quote_pattern PATTERN         (stdin PATTERN is supported)
  # * _envar_sed_quote_replace REPLACE         (stdin REPLACE is supported)

  ##############################
  ##### PRINTING / LOGGING #####
  ##############################

  # Print SOURCE file to DEST files. Logging via stderr
  # with prefixed DEST. Prefixes:
  # '{{ success }}' - successfully generated
  # '{{ skipped }}' - already exists, not overridden
  # '{{ failed }}'  - failed to generate files
  #
  # OPTIONS
  # =======
  # --            End of options
  # -f, --force   Force override if DEST exists
  # --tag         Tag to put content to
  # --tag-prefix  Prefix for tag, must be comment symbol, defaults to '#'
  #
  # USAGE:
  #   _envar_file2dest [-f] [--tag TAG] [--tag-prefix TAG_PREFIX] [--] SOURCE [DEST...]
  # RC:
  #   * 0 - all is fine
  #   * 1 - some of destinations are skipped
  #   * 2 - some of destinations are not created
  #   * 4 - source can't be read, fatal, provides no output
  # DEMO:
  #   # copy to files and address all kinds of logs
  #   _envar_file2dest ./lib.sh ./libs/lib{0..9}.sh /dev/null/subzero ~/.bashrc \
  #   2> >(
  #     tee \
  #       >(template_compile -o -f --success 'Success: ' | log_info) \
  #       >(template_compile -o -f --skipped 'Skipped: ' | log_warn) \
  #       >(template_compile -o -f --failed 'Failed: ' | log_err) \
  #       >/dev/null
  #   ) | cat
  _envar_file2dest() {
    local source
    local SOURCE_TXT
    local -a DESTS
    local FORCE=false
    local TAG
    local TAG_PREFIX='#'

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) endopts=true ;;
        -f|--force    ) FORCE=true ;;
        --tag         ) shift; TAG="${1}" ;;
        --tag-prefix  ) shift; TAG_PREFIX="${1}" ;;
        *             )
          [[ -z "${source+x}" ]] \
            && source="${1}" || DESTS+=("${1}")
        ;;
      esac

      shift
    done

    SOURCE_TXT="$(cat -- "${source}" 2>/dev/null)" || return 4

    [[ ${#DESTS[@]} -lt 1 ]] && DESTS+=(/dev/stdout)

    local dir
    local real
    local dest_content
    local rc=0
    local f; for f in "${DESTS[@]}"; do
      real="$(realpath -m -- "${f}" 2>/dev/null)"

      ! ${FORCE} && [[ -f "${real}" ]] && {
        rc=$(_envar_rc_add ${rc} 1)
        _envar_print_stderr "{{ skipped }}${f}"
        continue
      }

      dir="$(dirname -- "${f}" 2>/dev/null)" \
      && mkdir -p -- "${dir}" 2>/dev/null

      [[ -n "${TAG}" ]] && {
        [[ -f "${f}" ]] && dest_content="$(cat "${f}" 2>/dev/null)"
        SOURCE_TXT="$(
          _envar_tag_node_set --prefix "${TAG_PREFIX} {" --suffix '}' \
            -- "${TAG}" "${SOURCE_TXT}" "${dest_content}"
        )"
      }

      (cat <<< "${SOURCE_TXT}" > "${f}") 2>/dev/null && {
        # don't bother logging for generated to stdout and other devnulls
        if [[ -f ${real} ]]; then _envar_print_stderr "{{ success }}${f}"; fi
      } || {
        rc=$(_envar_rc_add ${rc} 2)
        _envar_print_stderr "{{ failed }}${f}"
        continue
      }
    done

    return ${rc}
  }

  _envar_print_stderr() {
    _envar_print_stdout "${@}" >/dev/stderr
  }

  _envar_print_stdout() {
    [[ ${#} -gt 0 ]] && printf -- '%s\n' "${@}" || cat
  }

  # Log to stderr prefixed with ${_ENVAR_LOG_TOOLNAME} and log type
  #
  # OPTIONS
  # =======
  # --          End of options
  # -t, --tag   Log level tag. Available: major, minor
  #             Defaults to major
  #
  # USAGE
  #   _envar_log_* [-t LEVEL_TAG] [--] MSG...
  #   _envar_log_* [-t LEVEL_TAG] <<< MSG
  #   # combined with `_envar_text_decore`
  #   _envar_text_decore MSG... | _envar_log_* [-t LEVEL_TAG]
  # LEVELS
  #   # Configure level you want to log
  #   _ENVAR_LOG_INFO_LEVEL=major
  #
  #   # ... some code here ...
  #
  #   # This will not log
  #   _envar_log_info -t minor "HELLO MINOR"
  #
  #   # And this will, as major is default
  #   _envar_log_info "HELLO MAJOR"
  #
  #   # This will never log
  #   _ENVAR_LOG_INFO_LEVEL=none _envar_log_info "HELLO MAJOR"
  _envar_log_info() {
    LEVEL="${_ENVAR_LOG_INFO_LEVEL}" \
    __envar_log_type info "${@}"
  }
  _envar_log_warn() {
    LEVEL="${_ENVAR_LOG_WARN_LEVEL}" \
    __envar_log_type warn "${@}"
  }
  _envar_log_err() {
    LEVEL="${_ENVAR_LOG_ERR_LEVEL}" \
    __envar_log_type err "${@}"
  }

  __envar_log_type() {
    local TYPE="${1}"
    local TAG=major
    local -a MSGS
    shift

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) endopts=true ;;
        -t|--tag  ) shift; TAG="${1:-${TAG}}" ;;
        *         ) MSGS+=("${1}") ;;
      esac

      shift
    done

    [[ "${TAG}" == none ]] && TAG=major
    LEVEL="${LEVEL:-major}"

    local -A level2num=( [none]=0 [major]=1 [minor]=2 )
    local req_level="${level2num["${LEVEL}"]:-${level2num[major]}}"
    local log_tag="${level2num["${TAG}"]:-${level2num[major]}}"

    # If reqired level is lower then current log tag, nothing to do here
    [[ ${req_level} -lt ${log_tag} ]] && return 0

    local prefix="${_ENVAR_LOG_TOOLNAME:+"${_ENVAR_LOG_TOOLNAME}:"}${TYPE}"
    _envar_print_stdout "${MSGS[@]}" | sed -e 's/^/['"${prefix}"'] /' | _envar_print_stderr
  }

  ################
  ##### TEXT #####
  ################

  _envar_text_ltrim() {
    _envar_print_stdout "${@}" | sed 's/^\s\+//'
  }

  _envar_text_rtrim() {
    _envar_print_stdout "${@}" | sed 's/\s\+$//'
  }

  _envar_text_trim() {
    _envar_print_stdout "${@}" | sed -e 's/^\s\+//' -e 's/\s\+$//'
  }

  # remove blank and space only lines
  _envar_text_rmblank() {
    _envar_print_stdout "${@}" | grep -vx '\s*'
    return 0
  }

  # apply trim and rmblank
  _envar_text_clean() {
    _envar_text_trim "${@}" | _envar_text_rmblank
    return 0
  }

  # Decoreate text:
  # * apply clean
  # * remove starting '.'
  # Prefix line with '.' to preserve empty line or offset
  #
  # USAGE
  #   _envar_text_decore MSG...
  #   _envar_text_decore <<< MSG
  _envar_text_decore() {
    _envar_text_clean "${@}" | sed 's/^\.//'
  }

  ####################
  ##### TRAPPING #####
  ####################

  # Detect one of help options: -h, -?, --help
  #
  # USAGE:
  #   _envar_trap_help_opt ARG...
  # RC:
  #   * 0 - help option detected
  #   * 1 - no help option
  #   * 2 - help option detected, but there are extra args,
  #         invalid args are printed to stdout
  _envar_trap_help_opt() {
    local is_help=false

    [[ "${1}" =~ ^(-h|-\?|--help)$ ]] \
      && is_help=true && shift

    local -a inval
    while :; do
      [[ -n "${1+x}" ]] || break
      inval+=("${1}")
      shift
    done

    ! ${is_help} && return 1

    ${is_help} && [[ ${#inval[@]} -gt 0 ]] && {
      _envar_print_stdout "${inval[@]}"
      return 2
    }

    return 0
  }

  # Exit with RC if it's > 0. If no MSG, no err message will be logged.
  # * RC is required to be numeric!
  # * not to be used in scripts sourced to ~/.bashrc!
  #
  # Options:
  #   --decore  - apply _envar_text_decore over input messages
  # USAGE:
  #   _envar_trap_fatal [--decore] [--] RC [MSG...]
  _envar_trap_fatal() {
    local rc
    local -a msgs
    local decore=false

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"
      case "${arg}" in
        --        ) endopts=true ;;
        --decore  ) decore=true ;;
        *         ) [[ -z "${rc+x}" ]] && rc="${1}" || msgs+=("${1}") ;;
      esac
      shift
    done

    [[ -n "${rc+x}" ]] || return 0
    [[ $rc -gt 0 ]] || return ${rc}

    [[ ${#msgs[@]} -gt 0 ]] && {
      local filter=(_envar_print_stdout)
      ${decore} && filter=(_envar_text_decore)
      "${filter[@]}" "${msgs[@]}" | __envar_log_type fatal
    }

    exit ${rc}
  }

  ################
  ##### TAGS #####
  ################

  # USAGE:
  #   _envar_tag_node_set [--prefix PREFIX] [--suffix SUFFIX] \
  #     [--] TAG CONTENT TEXT...
  #   _envar_tag_node_set [--prefix PREFIX] [--suffix SUFFIX] \
  #     [--] TAG CONTENT <<< TEXT
  _envar_tag_node_set() {
    local tag
    local content
    local text
    local prefix
    local suffix

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) endopts=true ;;
        --prefix  ) shift; prefix="${1}" ;;
        --suffix  ) shift; suffix="${1}" ;;
        *         )
          if [[ -z "${tag+x}" ]]; then
            tag="${1}"
          elif [[ -z "${content+x}" ]]; then
            content="${1}"
          else
            text+="${text:+$'\n'}${1}"
          fi
          ;;
      esac

      shift
    done

    [[ -n "${text+x}" ]] || text="$(cat)"

    local open="$(__envar_tag_mk_openline "${tag}" "${prefix}" "${suffix}")"
    local close="$(__envar_tag_mk_closeline "${tag}" "${prefix}" "${suffix}")"

    local add_text
    add_text="$(printf '%s\n%s\n%s\n' \
      "${open}" "$(sed 's/^/  /' <<< "${content}")" "${close}")"

    local range
    range="$(__envar_tag_get_lines_range "${open}" "${close}" "${text}")" || {
      printf '%s\n' "${text:+${text}$'\n'}${add_text}"
      return
    }

    head -n "$(( ${range%%,*} - 1 ))" <<< "${text}"
    printf '%s\n' "${add_text}"
    tail -n +"$(( ${range##*,} + 1 ))" <<< "${text}"
  }

  # USAGE:
  #   _envar_tag_node_get [--prefix PREFIX] [--suffix SUFFIX] \
  #     [--strip] [--] TAG TEXT...
  #   _envar_tag_node_get [--prefix PREFIX] [--suffix SUFFIX] \
  #     [--strip] [--] TAG <<< TEXT
  # RC:
  #   0 - all is fine content is returned
  #   1 - tag not found
  _envar_tag_node_get() {
    local tag
    local text
    local prefix
    local suffix
    local strip=false

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) endopts=true ;;
        --prefix  ) shift; prefix="${1}" ;;
        --suffix  ) shift; suffix="${1}" ;;
        --strip   ) strip=true ;;
        *         )
          [[ -n "${tag+x}" ]] \
            && text+="${text+$'\n'}${1}" \
            || tag="${1}"
          ;;
      esac

      shift
    done

    [[ -n "${text+x}" ]] || text="$(cat)"

    local open="$(__envar_tag_mk_openline "${tag}" "${prefix}" "${suffix}")"
    local close="$(__envar_tag_mk_closeline "${tag}" "${prefix}" "${suffix}")"

    local range
    range="$(__envar_tag_get_lines_range "${open}" "${close}" "${text}")" || {
      return 1
    }

    local -a filter=(cat)
    ${strip} && filter=(sed -e '1d;$d;s/^  //')

    sed -e "${range}!d" <<< "${text}" | "${filter[@]}"
  }

  # USAGE:
  #   _envar_tag_node_rm [--prefix PREFIX] \
  #     [--suffix SUFFIX] [--] TAG TEXT...
  #   _envar_tag_node_rm [--prefix PREFIX] \
  #     [--suffix SUFFIX] [--] TAG <<< TEXT
  # RC:
  #   0 - all is fine content is returned
  #   1 - tag not found
  _envar_tag_node_rm() {
    local tag
    local text
    local prefix
    local suffix

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) endopts=true ;;
        --prefix  ) shift; prefix="${1}" ;;
        --suffix  ) shift; suffix="${1}" ;;
        *         )
          [[ -n "${tag+x}" ]] \
            && text+="${text+$'\n'}${1}" \
            || tag="${1}"
          ;;
      esac

      shift
    done

    [[ -n "${text+x}" ]] || text="$(cat)"

    local open="$(__envar_tag_mk_openline "${tag}" "${prefix}" "${suffix}")"
    local close="$(__envar_tag_mk_closeline "${tag}" "${prefix}" "${suffix}")"

    local range
    range="$(__envar_tag_get_lines_range "${open}" "${close}" "${text}")" || {
      _envar_print_stdout "${text}"
      return 1
    }

    sed -e "${range}d" <<< "${text}"
  }

  # RC > 0 or comma separated open and close line numbers
  __envar_tag_get_lines_range() {
    local open="${1}"
    local close="${2}"
    local text="${3}"

    local close_rex
    close_rex="$(_envar_sed_quote_pattern "${close}")"

    local lines_numbered
    lines_numbered="$(
      grep -m 1 -n -A 9999999 -Fx "${open}" <<< "${text}" \
      | grep -m 1 -B 9999999 -e "^[0-9]\+-${close_rex}$"
    )" || return $?

    sed -e 's/^\([0-9]\+\).*/\1/' -n -e '1p;$p' <<< "${lines_numbered}" \
    | xargs | tr ' ' ','
  }

  __envar_tag_mk_openline() {
    local tag="${1}"
    local prefix="${2}"
    local suffix="${3}"
    printf -- '%s' "${prefix}${tag}${suffix}"
  }

  __envar_tag_mk_closeline() {
    local tag="${1}"
    local prefix="${2}"
    local suffix="${3}"
    printf -- '%s' "${prefix}/${tag}${suffix}"
  }

  #######################
  ##### RETURN CODE #####
  #######################

  _envar_rc_add() {
    echo $(( ${1} | ${2} ))
  }

  _envar_rc_has() {
    [[ $(( ${1} & ${2} )) -eq ${2} ]]
  }

  ######################
  ##### VALIDATION #####
  ######################

  _envar_check_bool() {
    [[ "${1}" =~ ^(true|false)$ ]]
  }

  _envar_check_unix_login() {
    # https://unix.stackexchange.com/questions/157426/what-is-the-regex-to-validate-linux-users
    local rex='[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)'
    grep -qEx -- "${rex}" <<< "${1}"
  }

  _envar_check_ip4() {
    local seg_rex='(0|[1-9][0-9]*)'

    grep -qxE "(${seg_rex}\.){3}${seg_rex}" <<< "${1}" || return 1

    local segments
    mapfile -t segments <<< "$(tr '.' '\n' <<< "${1}")"
    local seg; for seg in "${segments[@]}"; do
      [[ "${seg}" -gt 255 ]] && return 1
    done

    return 0
  }

  _envar_check_loopback_ip4() {
    _envar_check_ip4 "${1}" && grep -q '^127' <<< "${1}"
  }

  #####################
  ##### PROFILING #####
  #####################

  _envar_profiler_init() {
    ${_ENVAR_PROFILER_ENABLED-false} || return
    [[ -n "${_ENVAR_PROFILER_TIMESTAMP}" ]] && return

    _ENVAR_PROFILER_TIMESTAMP=$(( $(date +%s%N) / 1000000 ))
    export _ENVAR_PROFILER_TIMESTAMP
  }

  _envar_profiler_run() {
    ${_ENVAR_PROFILER_ENABLED-false} || return
    [[ -n "${_ENVAR_PROFILER_TIMESTAMP}" ]] || return

    local message="${1}"

    local time=$(( ($(date +%s%N) / 1000000) - ${_ENVAR_PROFILER_TIMESTAMP} ))

    {
      printf '%6s.%03d' $(( time / 1000 )) $(( time % 1000 ))
      [[ -n "${message}" ]] \
        && printf ' %s\n' "${message}" \
        || printf '\n'
    } | __envar_log_type profile
  }

  ################
  ##### MISC #####
  ################

  # Generate a random value, lower case latters only by default
  # https://unix.stackexchange.com/a/230676
  #
  # OPTIONS
  # =======
  # --len       Value length, defaults to 10
  # --num       Include numbers
  # --special   Include special characters
  # --uc        Include upper case
  #
  # USAGE:
  #   _envar_gen_rand [--len LEN] [--num] [--special] [--uc]
  _envar_gen_rand() {
    local len=10
    local num=false
    local special=false
    local uc=false
    local filter='a-z'

    while :; do
      [[ -n "${1+x}" ]] || break
      case "${1}" in
        --len     ) shift; len="${1}" ;;
        --num     ) num=true ;;
        --special ) special=true ;;
        --uc      ) uc=true ;;
      esac
      shift
    done

    ${num} && filter+='0-9'; ${uc} && filter+='A-Z'
    ${special} && filter+='!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~'
    LC_ALL=C tr -dc "${filter}" </dev/urandom | fold -w "${len}" | head -n 1
  }

  # Get unique lines preserving lines order. By default top unique
  # lines are prioritized
  #
  # OPTIONS
  # =======
  # --              End of options
  # -r, --reverse   Prioritize bottom unique values
  #
  # USAGE:
  #   _envar_uniq_ordered [-r] -- FILE...
  #   _envar_uniq_ordered [-r] <<< FILE_TEXT
  _envar_uniq_ordered() {
    local -a revfilter=(cat)
    local -a files

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --            ) endopts=true ;;
        -r|--reverse  ) revfilter=(tac) ;;
        *             ) files+=("${1}") ;;
      esac

      shift
    done

    # https://unix.stackexchange.com/a/194790
    cat "${files[@]}" | "${revfilter[@]}" \
    | cat -n | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2- \
    | "${revfilter[@]}"
  }

  # Compile template FILE replacing '{{ KEY }}' with VALUE.
  # In case of duplicated --KEY option last wins. Nothing
  # happens if FILE path is invalid.
  # Limitations:
  # * multiline KEY and VALUE are not allowed
  #
  # OPTIONS
  # =======
  # --  End of options
  # -o  Only output affected lines
  # -f  Substitute KEY only when it's first thing in the line
  # -s  Substitute only single occurrence
  #
  # USAGE:
  #   _envar_template_compile [-o] [-f] [-s] [--KEY VALUE...] [--] FILE...
  #   _envar_template_compile [-o] [-f] [-s] [--KEY VALUE...] <<< FILE_TEXT
  # Demo:
  #   # outputs: "account=varlog, password=changeme"
  #   _envar_template_compile --user varlog --pass changeme \
  #     <<< "login={{ user }}, password={{ pass }}"
  _envar_template_compile() {
    local -a files
    local -A kv
    local first=false
    local single=false
    local only=false

    local endopts=false
    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --  ) endopts=true ;;
        -o  ) only=true ;;
        -f  ) first=true ;;
        -s  ) single=true ;;
        --* ) shift; kv[${arg:2}]="${1}" ;;
        *   ) files+=("${1}") ;;
      esac

      shift
    done

    local key
    local value
    for key in "${!kv[@]}"; do
      value="$(_envar_sed_quote_replace "${kv["${key}"]}")"
      kv["${key}"]="${value}"
    done

    local template
    template="$(cat -- "${files[@]}" 2>/dev/null)"

    local -a filter
    local expression
    if ${only}; then
      for key in "${!kv[@]}"; do
        # https://www.cyberciti.biz/faq/unix-linux-sed-print-only-matching-lines-command/
        filter=(sed)
        key="$(_envar_sed_quote_pattern "${key}")"
        expression="{{\s*${key}\s*}}/${kv["${key}"]}"
        ${first} && expression="^${expression}"
        expression="s/${expression}/"
        ! ${single} && expression+='g'
        ${only} && filter+=(-n) && expression+='p'
        filter+=("${expression}")

        template="$("${filter[@]}" <<< "${template}")"
      done
    else
      # lighter than with ONLY option

      # initially passthrough filter
      filter=(sed -e 's/^/&/')

      for key in "${!kv[@]}"; do
        key="$(_envar_sed_quote_pattern "${key}")"
        expression="{{\s*${key}\s*}}/${kv["${key}"]}"
        ${first} && expression="^${expression}"
        filter+=(-e "s/${expression}/g")
      done

      template="$("${filter[@]}" <<< "${template}")"
    fi

    [[ -n "${template}" ]] && cat <<< "${template}"
  }

  # https://gist.github.com/varlogerr/2c058af053921f1e9a0ddc39ab854577#file-sed-quote
  _envar_sed_quote_pattern() {
    sed -e 's/[]\/$*.^[]/\\&/g' <<< "${1-$(cat)}"
  }
  _envar_sed_quote_replace() {
    sed -e 's/[\/&]/\\&/g' <<< "${1-$(cat)}"
  }

  ##########################
  ##### OVERRIDES DEMO #####
  ##########################

  # ## In most cases it's the first candidate for override
  #
  # eval "$(typeset -f _envar_file2dest | sed '1s/ \?(/_overriden_ (/')"
  # _envar_file2dest() {
  #   # https://unix.stackexchange.com/a/43536
  #   _envar_file2dest_overriden_ "${@}" \
  #   2> >(
  #     tee \
  #       >(_envar_template_compile -o -f --success 'Success: ' | _envar_log_info) \
  #       >(_envar_template_compile -o -f --skipped 'Skipped: ' | _envar_log_warn) \
  #       >(_envar_template_compile -o -f --failed 'Failed: ' | _envar_log_err) \
  #       >/dev/null
  #   ) | cat
  #
  #   # https://unix.stackexchange.com/a/73180
  #   return "${PIPESTATUS[0]}"
  # }

  # ## A lighter version of tags, less secure, but fine for personal data
  # ## sets. Disregards suffix and prefix, suffix is hardcoded to '#'
  #
  #__envar_tag_mk_openline() { printf -- '%s' "#${1}"; }
  #__envar_tag_mk_closeline() { printf -- '%s' "#${1}"; }
  #__envar_tag_get_lines_range() {
  #  local open="${1}"
  #  local close="${2}"
  #
  #  local lines_numbered
  #  lines_numbered="$(grep -m 2 -n -Fx "${open}" <<< "${text}")" || return $?
  #
  #  sed -e 's/^\([0-9]\+\).*/\1/' -n -e '1p;$p' <<< "${lines_numbered}" \
  #  | xargs | tr ' ' ','
  #}
# {/SHLIB_GEN}

# {SHLIB_OVERRIDES}

eval "$(typeset -f _envar_file2dest | sed '1s/ \?(/_overriden_ (/')"
_envar_file2dest() {
  # https://unix.stackexchange.com/a/43536
  _envar_file2dest_overriden_ "${@}" \
  2> >(
    tee \
      >(_envar_template_compile -o -f --success 'Success: ' | _envar_log_info) \
      >(_envar_template_compile -o -f --skipped 'Skipped: ' | _envar_log_warn) \
      >(_envar_template_compile -o -f --failed 'Failed: ' | _envar_log_err) \
      >/dev/null
  ) | cat

  # https://unix.stackexchange.com/a/73180
  return "${PIPESTATUS[0]}"
}

# better log handling
eval "$(typeset -f _envar_trap_help_opt | sed '1s/ \?(/_overriden_ (/')"
_envar_trap_help_opt() {
  local result
  local func="${1}"
  shift

  result="$(_envar_trap_help_opt_overriden_ "${@}")" || {
    local rc=$?
    [[ $rc -eq 2 ]] \
      && _envar_print_stdout \
        "Invalid or incompatible arguments:" \
        "$(sed 's/^/* /' <<< "${result}")" \
      | _envar_log_err

    return ${rc}
  }

  "${func}"; return 0
}

# override logger name and info level
unset _ENVAR_LOG_TOOLNAME
unset _ENVAR_LOG_INFO_LEVEL
eval "$(typeset -f __envar_log_type | sed '1s/ \?(/_overriden_ (/')"
eval "$(typeset -f _envar_log_info | sed '1s/ \?(/_overriden_ (/')"
__envar_log_type() { _ENVAR_LOG_TOOLNAME=envar __envar_log_type_overriden_ "${@}"; }
_envar_log_info() { _ENVAR_LOG_INFO_LEVEL="${ENVAR_INFO_LEVEL:-major}" _envar_log_info_overriden_ "${@}"; }

# {/SHLIB_OVERRIDES}


#######################
##### CUSTOM CODE #####
#######################


_envar_var() {
  [[ -n "${_ENVAR_VAR+x}" ]] || return 1
  printf -- '%s\n' "${_ENVAR_VAR}"
}

_envar_var_set() {
  __envar_var_arity_check _envar_var_set 2 ${#}

  local tag="${1}"
  local open="@${tag}"
  local close="@${tag}"
  shift

  _envar_var_unset "${tag}"

  _ENVAR_VAR+="${_ENVAR_VAR:+$'\n'}"
  _ENVAR_VAR+="${open}"$'\n'
  _ENVAR_VAR+="$(_envar_print_stdout "${@}" | sed 's/^/  /')"$'\n'
  _ENVAR_VAR+="${close}"
}

_envar_var_get() {
  __envar_var_arity_check _envar_var_get 1 ${#}
  local tag="${1}"

  local open="@${tag}"
  local close="@${tag}"

  # performance boost overrid
  local start
  start="$(grep -Fx -A 9999999 -m 1 -e "${open}" <<< "${_ENVAR_VAR}")" || {
    local rc=$?
    [[ -n "${2+x}" ]] && printf -- '%s\n' "${2}"
    return $rc
  }

  grep -Fx -B 999 -m 2 -e "${close}" <<< "${start}" | sed -e '1d;$d;s/^  //'
  return 0
}

_envar_var_unset() {
  __envar_var_arity_check _envar_var_unset 1 ${#}

  local open
  local close
  local tag; for tag in "${@}"; do
    open="@${tag}"
    close="@${tag}"

    _ENVAR_VAR="$(sed -e "/^${open}$/,/^${close}$/d" <<< "${_ENVAR_VAR}")"
  done
}

__envar_var_arity_check() {
  local func="${1}"
  local min_args="${2}"
  local act_args="${3}"

  [[ ${min_args} -le ${act_args} ]] && return 0

  _envar_log_warn "${func}" \
    "Minimum args: ${min_args}, actual: ${act_args}." \
    "Results are unpredictable!"
  return 1
}

# USAGE;
#   _envar_comment_tag_get TAG FILE
#   _envar_comment_tag_get TAG <<< TEXT
_envar_comment_tag_get() {
  local tag="${1}"; shift
  cat -- "${@}" | _envar_tag_node_get \
    --prefix '# @' -- "${tag}"
}

_envar_tag_comment_strip_filter() {
  sed -e '1d;$d' -e 's/^# \?//'
}

# signature function with pseudo-rand suffix
_envar_signature_fFmqaZbLA2() { :; }
