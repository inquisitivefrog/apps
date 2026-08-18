#!/usr/bin/env bash
# Writes the api module's full test-scope classpath to a file, for use compiling/running ad hoc
# diagnostic Java programs (e.g. reproducing a library's behavior in isolation) against the same
# dependency versions the real test suite uses.
#
# Usage: scripts/build-test-classpath.sh [output-file]
set -euo pipefail
cd "$(dirname "$0")/../api"

OUTPUT_FILE="${1:-/tmp/grid-meter-api-test-classpath.txt}"
mvn -q dependency:build-classpath -Dmdep.outputFile="$OUTPUT_FILE" -DincludeScope=test
echo "Classpath written to $OUTPUT_FILE"
