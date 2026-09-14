# The eval suite's base fixture graph (evals/fixtures/), materialized for BRAIN_TODAY. Lint must find
# exactly the one finding the fixture plants on purpose: Projects/Legacy has no digest.
sh "$CASE/../../../evals/fixtures/materialize.sh" .
