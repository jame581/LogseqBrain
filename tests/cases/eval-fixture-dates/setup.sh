# dates.awk across month, year, leap-day and century boundaries; then the materialized journal's
# file name, which the command below reads: @TODAY_05@ must become 2026_09_06 for BRAIN_TODAY 2026-09-11.
fx="$CASE/../../../evals/fixtures"
for c in 2026-09-11:@TODAY-40@:2026-08-02 2027-01-03:@TODAY-05@:2026-12-29 2028-03-01:@TODAY-01@:2028-02-29 \
         2026-03-01:@TODAY-01@:2026-02-28 2000-03-01:@TODAY-01@:2000-02-29 2100-03-01:@TODAY-01@:2100-02-28 \
         2026-09-11:@TODAY-00@:2026-09-11 2026-09-11:@TODAY_05@:2026_09_06; do
  t=${c%%:*}; rest=${c#*:}; tok=${rest%%:*}; want=${rest#*:}
  got=$(printf '%s\n' "$tok" | ${BRAIN_AWK:-awk} -v BINMODE=3 -v today="$t" -f "$fx/dates.awk")
  [ "$got" = "$want" ] || { echo "dates.awk: today $t, $tok gave '$got', want $want" >&2; return 1; }
done
sh "$fx/materialize.sh" .
