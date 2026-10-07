#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/refresh/config.sh"
source "${SCRIPT_DIR}/refresh/commands.sh"
source "${SCRIPT_DIR}/refresh/upstream_artifacts.sh"
source "${SCRIPT_DIR}/refresh/graph_artifact.sh"
source "${SCRIPT_DIR}/refresh/objc_prelink.sh"

main() {
  configure_refresh_paths "${SCRIPT_DIR}"
  require_refresh_tools
  fetch_upstream_archives
  stage_upstream_frameworks
  stage_mediapipe_license
  assemble_graph_artifact

  echo "Merging Objective-C members so consumers do not need -ObjC..."
  prelink_objc_members
  add_notices_to_artifacts

  echo "Refreshed MediaPipeSPM artifacts in ${ARTIFACTS_DIR}"
}

main "$@"
