# The eval fixture's digest-bearing page: its committed Map must stay exact after date substitution
# (the tokens are 10 bytes, like the dates that replace them).
sh "$CASE/../../../evals/fixtures/materialize.sh" .
