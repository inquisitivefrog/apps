#!/usr/bin/env bash
# Prints the most recent published versions for a Maven Central artifact — used to verify a
# dependency version is actually current before pinning it, per this project's version-checking
# convention (see docs/tech-stack-versions.md).
#
# Usage: scripts/check-maven-central-version.sh <groupId> <artifactId> [rows]
set -euo pipefail

GROUP_ID="$1"
ARTIFACT_ID="$2"
ROWS="${3:-5}"

curl -s "https://search.maven.org/solrsearch/select?q=g:${GROUP_ID}+AND+a:${ARTIFACT_ID}&core=gav&rows=${ROWS}&wt=json" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); [print(x['v']) for x in d['response']['docs']]"
