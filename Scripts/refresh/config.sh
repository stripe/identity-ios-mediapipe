#!/usr/bin/env bash

MEDIAPIPE_VERSION="${MEDIAPIPE_VERSION:-$(tr -d "[:space:]" < "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/MEDIAPIPE_VERSION")}"
MIN_IOS_VERSION="${MIN_IOS_VERSION:-15.0}"
GRAPH_ARTIFACT_NAME="MediaPipeCommonGraphLibraries"

configure_refresh_paths() {
  local script_dir="$1"

  PACKAGE_ROOT="$(cd "${script_dir}/.." && pwd)"
  ARTIFACTS_DIR="${PACKAGE_ROOT}/Artifacts"
  BUILD_ROOT="${PACKAGE_ROOT}/.build/artifact-refresh"
  ARCHIVES_DIR="${BUILD_ROOT}/archives"
  UPSTREAM_DIR="${BUILD_ROOT}/upstream"
  GRAPH_BUILD_ROOT="${BUILD_ROOT}/${GRAPH_ARTIFACT_NAME}"

  export PACKAGE_ROOT ARTIFACTS_DIR BUILD_ROOT ARCHIVES_DIR UPSTREAM_DIR GRAPH_BUILD_ROOT
}
