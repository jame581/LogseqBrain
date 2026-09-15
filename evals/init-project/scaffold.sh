#!/bin/sh
# Build ./graph from the shared fixture (evals/fixtures/materialize.sh). Runs outside the sandbox.
exec sh "$(dirname "$0")/../fixtures/materialize.sh" graph
