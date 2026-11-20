#!/bin/bash
# Installs the repo's pre-commit hook (shared by all worktrees). The hook runs
# tools/precommit_camnose.sh only in work trees that have that file, and chains
# to any pre-commit hook that was there before (kept as pre-commit.orig).
set -eu
cd "$(git rev-parse --show-toplevel)"
# git resolves core.hooksPath (including ~ and relative paths) and worktrees.
HOOKS=$(git rev-parse --git-path hooks)
mkdir -p "$HOOKS"
HOOKS=$(cd "$HOOKS" && pwd)
HOOK=$HOOKS/pre-commit
MARK="# camnose-guard"
if [ -e "$HOOK" ] && ! grep -q "^$MARK" "$HOOK"; then
  [ -e "$HOOK.orig" ] && { echo "refusing: $HOOK exists and so does $HOOK.orig" >&2; exit 1; }
  mv "$HOOK" "$HOOK.orig"
  echo "existing pre-commit moved to $HOOK.orig (it is still run first)"
fi
cat >"$HOOK" <<'HOOKEOF'
#!/bin/sh
# camnose-guard (installed by tools/install_hooks.sh; safe to re-run it)
here=$(dirname "$0")
if [ -x "$here/pre-commit.orig" ]; then "$here/pre-commit.orig" "$@" || exit $?; fi
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
if [ -f "$root/tools/precommit_camnose.sh" ]; then bash "$root/tools/precommit_camnose.sh" "$@" || exit $?; fi
exit 0
HOOKEOF
chmod +x "$HOOK"
echo "installed $HOOK"

# make sure some interpreter can run the checks
MODS="import numpy, trimesh, manifold3d, networkx"
for c in "${CAMNOSE_PYTHON:-}" "$(git config --get camnose.python || true)" "$HOME/.cache/camnose-venv/bin/python" \
         /tmp/camnose-venv/bin/python "$(command -v python3 || true)"; do
  [ -n "$c" ] && [ -x "$c" ] && "$c" -c "$MODS" 2>/dev/null && {
    git config camnose.python "$c"; echo "python for the guard: $c"; exit 0; }
done
echo "no Python with numpy/trimesh/manifold3d/networkx found; creating ~/.cache/camnose-venv"
python3 -m venv "$HOME/.cache/camnose-venv"
"$HOME/.cache/camnose-venv/bin/pip" install -q -r tools/requirements-camnose.txt
git config camnose.python "$HOME/.cache/camnose-venv/bin/python"
echo "python for the guard: $HOME/.cache/camnose-venv/bin/python"
