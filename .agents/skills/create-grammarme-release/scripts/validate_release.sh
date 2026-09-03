#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <semver>" >&2
  exit 64
fi

release_version="$1"
case "$release_version" in
  ''|*[!0-9A-Za-z.+-]*)
    echo "invalid SemVer: $release_version" >&2
    exit 65
    ;;
esac

if ! printf '%s\n' "$release_version" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'; then
  echo "invalid SemVer: $release_version" >&2
  exit 65
fi

repository_root=$(git rev-parse --show-toplevel)
cd "$repository_root"

if [ -n "$(git status --porcelain)" ]; then
  echo "working tree must be clean" >&2
  exit 66
fi

build_settings=$(xcodebuild -project GrammarMe.xcodeproj -scheme GrammarMe -configuration Release -showBuildSettings 2>/dev/null) || {
  echo "xcodebuild -showBuildSettings failed" >&2
  exit 69
}

resolved_version=$(printf '%s\n' "$build_settings" | awk '/^[[:space:]]*MARKETING_VERSION = / { print $3; exit }')
resolved_build=$(printf '%s\n' "$build_settings" | awk '/^[[:space:]]*CURRENT_PROJECT_VERSION = / { print $3; exit }')

if [ -z "$resolved_version" ] || [ -z "$resolved_build" ]; then
  echo "failed to resolve MARKETING_VERSION/CURRENT_PROJECT_VERSION from build settings" >&2
  exit 69
fi
if [ "$resolved_version" != "$release_version" ]; then
  echo "MARKETING_VERSION is $resolved_version; expected $release_version" >&2
  exit 67
fi

if ! printf '%s\n' "$resolved_build" | grep -Eq '^[1-9][0-9]*$'; then
  echo "CURRENT_PROJECT_VERSION must be a positive integer; found $resolved_build" >&2
  exit 68
fi

echo "GrammarMe $release_version (build $resolved_build) version settings are valid."
