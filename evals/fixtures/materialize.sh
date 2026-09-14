#!/bin/sh
# Materialize the eval fixture graph into DEST: copy base-graph/, then OVERLAY_DIR over it, then
# replace the date tokens (dates.awk) in file contents and file names.
# Usage: sh materialize.sh DEST [OVERLAY_DIR]     today = $BRAIN_TODAY, else the system date.
# Runs outside the eval sandbox (from a case's scaffold.sh), so it writes nothing outside DEST.
set -u
LC_ALL=C; export LC_ALL
AWK=${BRAIN_AWK:-awk}          # the golden tests run this under every awk CI tests the helper with
fail() { echo "materialize: $*" >&2; exit 1; }
[ $# -ge 1 ] && [ $# -le 2 ] || { echo "usage: sh materialize.sh DEST [OVERLAY_DIR]" >&2; exit 2; }
FIX=$(cd "$(dirname "$0")" && pwd) || fail "cannot locate the fixture directory from $0"
BASE="$FIX/base-graph"
[ -f "$BASE/pages/Index.md" ] || fail "base fixture not found at $BASE"
DEST=$1; OVERLAY=${2:-}
[ -z "$OVERLAY" ] || [ -d "$OVERLAY" ] || fail "overlay not found: $OVERLAY"
TODAY=${BRAIN_TODAY:-$(date +%Y-%m-%d)}
case $TODAY in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) fail "today is not yyyy-MM-dd: $TODAY" ;; esac
mkdir -p "$DEST" || fail "cannot create $DEST"
cp -R "$BASE/." "$DEST/" || fail "copying the base fixture failed"
if [ -n "$OVERLAY" ]; then cp -R "$OVERLAY/." "$DEST/" || fail "copying the overlay failed"; fi
LIST="$DEST/.materialize-list"
find "$DEST" -type f \( -name '*.md' -o -name '*.edn' \) > "$LIST" || fail "listing $DEST failed"
while IFS= read -r f; do
  $AWK -v BINMODE=3 -v today="$TODAY" -f "$FIX/dates.awk" "$f" > "$f.tmp" && mv "$f.tmp" "$f" \
    || fail "date substitution failed on $f"
  name=$(basename "$f")
  case $name in
    *@TODAY_*)
      new=$(printf '%s\n' "$name" | $AWK -v BINMODE=3 -v today="$TODAY" -f "$FIX/dates.awk") \
        || fail "renaming $f failed"
      mv "$f" "$(dirname "$f")/$new" || fail "renaming $f failed" ;;
  esac
done < "$LIST"
rm -f "$LIST"
if grep -rl '@TODAY' "$DEST" > /dev/null 2>&1; then fail "unsubstituted date token left in $DEST"; fi
exit 0
