sb_block current-plan > "$RUN/cp.got"
sh "$BRAIN" --graph "$G" tail Projects/Big 'Current Plan' --max 8192 > "$RUN/cp.want"
diff "$RUN/cp.want" "$RUN/cp.got" || { echo "current-plan block is not the 8192-byte tail"; exit 1; }
grep -q '^coverage: last ' "$RUN/cp.got" || { echo "no coverage line"; exit 1; }
