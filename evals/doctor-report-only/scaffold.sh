#!/bin/sh
# Build ./graph from the shared fixture plus this case's overlay/ (a page with a bare #44).
here=$(dirname "$0")
exec sh "$here/../fixtures/materialize.sh" graph "$here/overlay"
