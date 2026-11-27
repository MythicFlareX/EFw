#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ -x "./gradlew" ]]; then
  ./gradlew clean build --no-daemon
else
  gradle clean build --no-daemon
fi
