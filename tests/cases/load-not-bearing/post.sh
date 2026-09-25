! grep -q '^== activity' "$RUN/out" || { echo "an activity block was printed"; exit 1; }
