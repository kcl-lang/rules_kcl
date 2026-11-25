#!/usr/bin/env bash
# Wrap the KCL CLI so each Bazel action gets a private package cache.
#
# `kcl run` locks `$KCL_PKG_PATH/.kpm/config/package-cache` for the whole
# process (kpm AcquirePackageCacheLock). A shared KCL_PKG_PATH, including the
# default `$HOME/.kcl/kpm`, makes concurrent kcl_run actions wait on that file.
# A fresh directory per invocation keeps those actions parallel and writable
# inside the Bazel sandbox, so callers do not pass --action_env.
set -euo pipefail

export PATH="/usr/bin:/bin${PATH:+:$PATH}"

# kclvm is unpacked under $HOME/go and init.lock is held only during that
# install. A stable per-user home keeps the unpack shared across actions.
# `kcl run` then holds $KCL_PKG_PATH/.kpm/config/package-cache until it exits,
# so the package and compilation caches have to be private or parallel
# kcl_run actions queue on that file.
home="/tmp/rules_kcl-home.${UID:-0}"
mkdir -p "$home"
pkg_path="$(mktemp -d /tmp/kcl-pkg.XXXXXX)"
cache_path="$(mktemp -d /tmp/kcl-cache.XXXXXX)"
cleanup() {
    rm -rf "$pkg_path" "$cache_path"
}
# Do not exec the KCL binary: exec would replace this shell and skip cleanup.
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

export HOME="$home"
export KCL_PKG_PATH="$pkg_path"
export KCL_CACHE_PATH="$cache_path"

"$@"
