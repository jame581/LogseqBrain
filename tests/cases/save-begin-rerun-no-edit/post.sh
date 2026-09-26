! grep -q "^warning:" "$RUN/out" "$RUN/err" || { echo "warned on a rerun with no edit"; exit 1; }
