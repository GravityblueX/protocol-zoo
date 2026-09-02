#!/bin/sh
# Validate user-selected capture destinations before a caller performs side effects.
# The repository working tree is assumed not to be mutated concurrently.

pz_capture_path_error() {
  printf 'unsafe %s capture path %s: %s\n' "$2" "$1" "$3" >&2
  return 1
}

pz_require_capture_path() {
  PZ_CAPTURE_PATH=
  PZ_CAPTURE_RELATIVE=

  pz_capture_requested=$2
  pz_capture_kind=$3

  case "$pz_capture_kind" in
    file | directory) ;;
    *)
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'internal error: expected file or directory'
      return 1
      ;;
  esac

  case "$pz_capture_requested" in
    '')
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'path is empty'
      return 1
      ;;
    /* | [A-Za-z]:/* | [A-Za-z]:\\* | \\\\*)
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'absolute paths are not allowed'
      return 1
      ;;
    *\\*)
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'use forward slashes in repository-relative paths'
      return 1
      ;;
    captures | captures/)
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'the captures root itself is not a valid target'
      return 1
      ;;
    captures/*) ;;
    *)
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        'target must be a descendant of captures/'
      return 1
      ;;
  esac

  if [ "$pz_capture_kind" = file ]; then
    case "$pz_capture_requested" in
      */)
        pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
          'a file target cannot end with a slash'
        return 1
        ;;
    esac
  fi

  pz_capture_repo=$(CDPATH='' cd -- "$1" && pwd -P) || {
    pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
      'repository root is unavailable'
    return 1
  }
  if [ ! -d "$pz_capture_repo/captures" ] || [ -L "$pz_capture_repo/captures" ]; then
    pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
      'repository captures/ must be a real directory'
    return 1
  fi
  pz_capture_root=$(CDPATH='' cd -- "$pz_capture_repo/captures" && pwd -P) || {
    pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
      'repository captures/ is unavailable'
    return 1
  }
  if [ "$pz_capture_root" != "$pz_capture_repo/captures" ]; then
    pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
      'repository captures/ does not resolve inside the repository'
    return 1
  fi

  pz_capture_remaining=${pz_capture_requested#captures/}
  pz_capture_relative=
  pz_capture_current=$pz_capture_root

  while [ -n "$pz_capture_remaining" ]; do
    case "$pz_capture_remaining" in
      */*)
        pz_capture_component=${pz_capture_remaining%%/*}
        pz_capture_remaining=${pz_capture_remaining#*/}
        ;;
      *)
        pz_capture_component=$pz_capture_remaining
        pz_capture_remaining=
        ;;
    esac

    case "$pz_capture_component" in
      '' | .) continue ;;
      ..)
        pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
          'parent-directory components are not allowed'
        return 1
        ;;
    esac

    pz_capture_next=$pz_capture_current/$pz_capture_component
    if [ -L "$pz_capture_next" ]; then
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        "symbolic-link component is not allowed: $pz_capture_component"
      return 1
    fi
    if [ -n "$pz_capture_remaining" ] && [ -e "$pz_capture_next" ] && \
       [ ! -d "$pz_capture_next" ]; then
      pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
        "non-directory path component: $pz_capture_component"
      return 1
    fi

    if [ -n "$pz_capture_relative" ]; then
      pz_capture_relative=$pz_capture_relative/$pz_capture_component
    else
      pz_capture_relative=$pz_capture_component
    fi
    pz_capture_current=$pz_capture_next
  done

  if [ -z "$pz_capture_relative" ]; then
    pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
      'the captures root itself is not a valid target'
    return 1
  fi

  case "$pz_capture_kind" in
    file)
      if [ -e "$pz_capture_current" ] && [ ! -f "$pz_capture_current" ]; then
        pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
          'target exists but is not a regular file'
        return 1
      fi
      ;;
    directory)
      if [ -e "$pz_capture_current" ] && [ ! -d "$pz_capture_current" ]; then
        pz_capture_path_error "$pz_capture_requested" "$pz_capture_kind" \
          'target exists but is not a directory'
        return 1
      fi
      ;;
  esac

  # These globals are the function's two return values for POSIX sh callers.
  # shellcheck disable=SC2034
  PZ_CAPTURE_PATH=$pz_capture_current
  # shellcheck disable=SC2034
  PZ_CAPTURE_RELATIVE=captures/$pz_capture_relative
}

pz_require_capture_children() {
  PZ_CAPTURE_CHILD_ROOT=$1
  PZ_CAPTURE_CHILD_DIRECTORY=$2
  shift 2

  for PZ_CAPTURE_CHILD_NAME do
    case "$PZ_CAPTURE_CHILD_NAME" in
      '' | . | .. | */*)
        printf 'unsafe capture child name %s: expected one basename\n' \
          "$PZ_CAPTURE_CHILD_NAME" >&2
        return 1
        ;;
    esac
    pz_require_capture_path \
      "$PZ_CAPTURE_CHILD_ROOT" \
      "$PZ_CAPTURE_CHILD_DIRECTORY/$PZ_CAPTURE_CHILD_NAME" \
      file || return 1
  done
}

pz_require_disjoint_capture_files() {
  PZ_CAPTURE_LEFT=$1
  PZ_CAPTURE_RIGHT=$2

  if ! command -v tr >/dev/null 2>&1; then
    printf 'unable to compare capture file paths safely: missing tr\n' >&2
    return 1
  fi
  PZ_CAPTURE_LEFT_FOLDED=$(printf '%s\n' "$PZ_CAPTURE_LEFT" | \
    LC_ALL=C tr '[:upper:]' '[:lower:]') || return 1
  PZ_CAPTURE_RIGHT_FOLDED=$(printf '%s\n' "$PZ_CAPTURE_RIGHT" | \
    LC_ALL=C tr '[:upper:]' '[:lower:]') || return 1

  # Be conservative for Git Bash on the default case-insensitive filesystem.
  # Linux therefore also rejects output pairs that differ only in ASCII case.
  case "$PZ_CAPTURE_LEFT_FOLDED/" in
    "$PZ_CAPTURE_RIGHT_FOLDED/"*) ;;
    *)
      case "$PZ_CAPTURE_RIGHT_FOLDED/" in
        "$PZ_CAPTURE_LEFT_FOLDED/"*) ;;
        *) return 0 ;;
      esac
      ;;
  esac

  printf 'unsafe capture file paths %s and %s: targets overlap\n' \
    "$PZ_CAPTURE_LEFT" "$PZ_CAPTURE_RIGHT" >&2
  return 1
}
