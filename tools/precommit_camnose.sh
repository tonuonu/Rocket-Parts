#!/bin/bash
# Pre-commit guard for the camera/canard nose CAD. Installed by tools/install_hooks.sh.
# Runs only when the staged change touches a .scad file used by the cam nose
# (PeregrineCamNose/Canards/Bay.scad and anything they include or use) or a
# path under "STL Files/PeregrineCamNose/". It then checks the STAGED content:
#   a. tools/verify_camnose_canards.py, verify_camnose.py, verify_camnose_bay.py
#   b. every committed camnose STL against a fresh render of the staged source
#   c. warns about stale .3mf slicer projects (never modifies them)
# Environment: CAMNOSE_PYTHON = interpreter with numpy, trimesh, manifold3d, networkx.
# Emergency bypass: git commit --no-verify
set -u
NOSE="STL Files/PeregrineCamNose/"
OPENSCAD=/Applications/OpenSCAD-dev.app/Contents/MacOS/OpenSCAD
t0=$(date +%s)

# ---- fast path: no git work beyond one diff unless a candidate path is staged
want=0; scad_changed=0
while IFS= read -r -d '' f; do
  case "$f" in
    "$NOSE"*) want=1 ;;
    tools/verify_camnose*.py|tools/check_camnose_stls.py|tools/precommit_camnose.sh) want=1 ;;
    *.scad) scad_changed=1 ;;
  esac
done < <(git diff --cached --name-only -z --no-renames)
[ $want = 0 ] && [ $scad_changed = 0 ] && exit 0

# ---- which .scad files does the cam nose use? (include/use closure, from the index)
if [ $want = 0 ]; then
  seen=$'\n'; queue=$'PeregrineCamNose.scad\nPeregrineCamCanards.scad\nPeregrineCamBay.scad'
  while [ -n "$queue" ]; do
    f=${queue%%$'\n'*}
    if [ "$queue" = "$f" ]; then queue=""; else queue=${queue#*$'\n'}; fi
    [ -z "$f" ] && continue
    case "$seen" in *$'\n'"$f"$'\n'*) continue ;; esac
    seen="$seen$f"$'\n'
    git cat-file -e ":$f" 2>/dev/null || continue
    deps=$(git show ":$f" | sed -En 's/^[[:space:]]*(include|use)[[:space:]]*<([^>]*)>.*/\2/p')
    [ -n "$deps" ] && queue="$queue"$'\n'"$deps"
  done
  while IFS= read -r -d '' f; do
    case "$f" in *.scad) case "$seen" in *$'\n'"$f"$'\n'*) want=1 ;; esac ;; esac
  done < <(git diff --cached --name-only -z --no-renames)
  [ $want = 0 ] && exit 0
fi

fail() { echo "camnose guard: $*" >&2; exit 1; }
WT=$(git rev-parse --show-toplevel) || fail "not in a git work tree"

# ---- interpreter
MODS="import numpy, trimesh, manifold3d, networkx"
PY=""
if [ -n "${CAMNOSE_PYTHON:-}" ]; then
  "$CAMNOSE_PYTHON" -c "$MODS" 2>/dev/null \
    || fail "CAMNOSE_PYTHON=$CAMNOSE_PYTHON lacks numpy/trimesh/manifold3d/networkx (pip install -r tools/requirements-camnose.txt)"
  PY=$CAMNOSE_PYTHON
else
  for c in "$(git config --get camnose.python 2>/dev/null)" "$HOME/.cache/camnose-venv/bin/python" \
           /tmp/camnose-venv/bin/python "$(command -v python3 2>/dev/null)"; do
    [ -n "$c" ] && [ -x "$c" ] && "$c" -c "$MODS" 2>/dev/null && { PY=$c; break; }
  done
  [ -n "$PY" ] || fail "no Python with numpy, trimesh, manifold3d, networkx found.
  Fix: python3 -m venv ~/.cache/camnose-venv && ~/.cache/camnose-venv/bin/pip install -r tools/requirements-camnose.txt
  or set CAMNOSE_PYTHON=/path/to/python (or: git config camnose.python /path/to/python)."
fi
[ -x "$OPENSCAD" ] || fail "OpenSCAD not found at $OPENSCAD"

# ---- staged content in a temp tree; the working tree is not touched
TMP=$(mktemp -d "${TMPDIR:-/tmp}/camnose-guard.XXXXXX") || fail "mktemp failed"
trap 'rm -rf "$TMP"' EXIT
git ls-files -z -- ':(glob)*.scad' tools "$NOSE" | git checkout-index -z --stdin --prefix="$TMP/tree/" \
  || fail "could not check out the index"
[ -f "$TMP/tree/PeregrineCamNose.scad" ] || fail "PeregrineCamNose.scad is not in the index"
[ -f "$TMP/tree/tools/verify_camnose_canards.py" ] || fail "tools/verify_camnose_canards.py is not in the index"
cd "$TMP/tree" || exit 1
export PYTHONWARNINGS=ignore PYTHONDONTWRITEBYTECODE=1
O="$TMP/out"; mkdir -p "$O"

# ---- a + b renders, in parallel
"$PY" tools/verify_camnose_canards.py --output-dir "$O/canards" --json "$O/canards.json" >"$O/a1.log" 2>&1 & p1=$!
( "$PY" tools/verify_camnose.py --output-dir "$O/meshes" >"$O/a2.log" 2>&1 \
  && "$PY" tools/verify_camnose_bay.py "$O/meshes" --report "$O/bay.json" >"$O/a3.log" 2>&1 ) & p2=$!
"$PY" tools/check_camnose_stls.py render-extra "$O/extra" >"$O/x.log" 2>&1 & p3=$!
wait $p1; s1=$?; wait $p2; s2=$?; wait $p3; s3=$?

rc=0
show() { grep -E '^(FAIL|WARN|Traceback|[A-Za-z]*Error)' "$1" | head -20; tail -5 "$1"; }
[ $s1 = 0 ] || { echo "FAIL verify_camnose_canards.py"; show "$O/a1.log"; rc=1; }
[ $s2 = 0 ] || { echo "FAIL verify_camnose.py / verify_camnose_bay.py"; show "$O/a2.log"; [ -f "$O/a3.log" ] && show "$O/a3.log"; rc=1; }
[ $s3 = 0 ] || { echo "FAIL render of Canard_Span20"; cat "$O/x.log"; rc=1; }
if [ $rc = 0 ]; then
  "$PY" tools/check_camnose_stls.py compare --meshes "$O/meshes" --canards "$O/canards" \
        --extra "$O/extra" --worktree "$WT" >"$O/b.log" 2>&1 || rc=1
  grep -E '^(FAIL|WARN|note)|Traceback|Error' "$O/b.log"
fi

n1=$(grep -Eo '[0-9]+/[0-9]+ checks passed' "$O/a1.log" | tail -1)
n2=$(grep -Eo '[0-9]+/[0-9]+ checks passed' "$O/a3.log" 2>/dev/null | tail -1)
n3=$(grep -Eo '^STLS .*' "$O/b.log" 2>/dev/null | sed 's/^STLS //')
echo "camnose guard: $([ $rc = 0 ] && echo PASS || echo FAIL) | canards ${n1:-?} | bay ${n2:-?} | STLs ${n3:-not compared} | $(( $(date +%s) - t0 ))s"
[ $rc = 0 ] || echo "(emergency bypass: git commit --no-verify)" >&2
exit $rc
