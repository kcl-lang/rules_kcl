#!/usr/bin/env bash
# Two concurrent wrapper invocations must not share KCL_PKG_PATH.
# kcl locks `$KCL_PKG_PATH/.kpm/config/package-cache`; a shared directory makes
# the second flock fail.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER="${SCRIPT_DIR}/kcl_env.sh"

if [[ ! -f "$WRAPPER" ]]; then
    echo "missing wrapper: $WRAPPER" >&2
    exit 1
fi

tmpdir="$(mktemp -d /tmp/kcl-env-test.XXXXXX)"
cleanup() {
    rm -rf "$tmpdir"
}
trap cleanup EXIT

cat > "$tmpdir/fake_kcl" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
out="$1"
printf '%s\n' "$KCL_PKG_PATH" > "$out.pkg"
printf '%s\n' "$KCL_CACHE_PATH" > "$out.cache"
printf '%s\n' "$HOME" > "$out.home"
mkdir -p "$KCL_PKG_PATH/.kpm/config"
lock="$KCL_PKG_PATH/.kpm/config/package-cache"
touch "$lock"
if command -v flock >/dev/null 2>&1; then
    # Non-blocking: a shared package cache fails this invocation immediately.
    flock -n "$lock" -c "sleep 0.4"
else
    sleep 0.2
fi
EOF
chmod +x "$tmpdir/fake_kcl"

# Values a user might export, or that --action_env would inject. The wrapper
# must replace them so actions do not share a package cache.
export KCL_PKG_PATH="/tmp/should-be-overridden"
export KCL_CACHE_PATH="/tmp/should-be-overridden-cache"
export HOME="/tmp/should-be-overridden-home"

bash "$WRAPPER" "$tmpdir/fake_kcl" "$tmpdir/a" &
pid_a=$!
bash "$WRAPPER" "$tmpdir/fake_kcl" "$tmpdir/b" &
pid_b=$!
wait "$pid_a"
wait "$pid_b"

pkg_a="$(cat "$tmpdir/a.pkg")"
pkg_b="$(cat "$tmpdir/b.pkg")"
cache_a="$(cat "$tmpdir/a.cache")"
cache_b="$(cat "$tmpdir/b.cache")"
home_a="$(cat "$tmpdir/a.home")"

if [[ "$pkg_a" == "$pkg_b" ]]; then
    echo "KCL_PKG_PATH was shared: $pkg_a" >&2
    exit 1
fi
if [[ "$cache_a" == "$cache_b" ]]; then
    echo "KCL_CACHE_PATH was shared: $cache_a" >&2
    exit 1
fi
if [[ "$pkg_a" == "/tmp/should-be-overridden" || "$cache_a" == "/tmp/should-be-overridden-cache" || "$home_a" == "/tmp/should-be-overridden-home" ]]; then
    echo "wrapper kept the caller environment: pkg=$pkg_a cache=$cache_a home=$home_a" >&2
    exit 1
fi
if [[ ! -d "$pkg_a" && ! -d "$cache_a" && ! -d "$pkg_b" && ! -d "$cache_b" ]]; then
    :
else
    echo "temporary caches were not removed" >&2
    exit 1
fi

echo "kcl_env isolation ok"
