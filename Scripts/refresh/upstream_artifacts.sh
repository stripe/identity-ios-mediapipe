#!/usr/bin/env bash

fetch_upstream_archives() {
  reset_directory "${UPSTREAM_DIR}"
  mkdir -p "${ARCHIVES_DIR}"

  local name
  for name in MediaPipeTasksVision MediaPipeTasksCommon; do
    fetch_upstream_archive "${name}"
  done
}

fetch_upstream_archive() {
  local name="$1"
  local file="${name}-${MEDIAPIPE_VERSION}.tar.gz"
  local archive="${ARCHIVES_DIR}/${file}"
  local sha url

  if ! read -r sha url < <(grep "/${file}\$" "${PACKAGE_ROOT}/MEDIAPIPE_SOURCES"); then
    echo "error: MEDIAPIPE_SOURCES has no entry for ${file}" >&2
    exit 1
  fi

  # Reuse the archive from an earlier run while its checksum still matches.
  if ! echo "${sha}  ${archive}" | shasum -a 256 -c - >/dev/null 2>&1; then
    run_command curl -fsSL -o "${archive}" "${url}"
    echo "${sha}  ${archive}" | shasum -a 256 -c -
  fi

  mkdir -p "${UPSTREAM_DIR}/${name}"
  run_command tar -xzf "${archive}" -C "${UPSTREAM_DIR}/${name}"
}

stage_upstream_frameworks() {
  mkdir -p "${ARTIFACTS_DIR}"

  copy_directory_contents \
    "${UPSTREAM_DIR}/MediaPipeTasksVision/frameworks/MediaPipeTasksVision.xcframework" \
    "${ARTIFACTS_DIR}/MediaPipeTasksVision.xcframework"

  copy_directory_contents \
    "${UPSTREAM_DIR}/MediaPipeTasksCommon/frameworks/MediaPipeTasksCommon.xcframework" \
    "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework"

  strip_intel_simulator_slice "${ARTIFACTS_DIR}/MediaPipeTasksVision.xcframework" "MediaPipeTasksVision"
  strip_intel_simulator_slice "${ARTIFACTS_DIR}/MediaPipeTasksCommon.xcframework" "MediaPipeTasksCommon"

  local framework_name
  for framework_name in MediaPipeTasksVision MediaPipeTasksCommon; do
    write_framework_info_plist \
      "${ARTIFACTS_DIR}/${framework_name}.xcframework/ios-arm64/${framework_name}.framework" \
      "iPhoneOS" \
      "${framework_name}"
    write_framework_info_plist \
      "${ARTIFACTS_DIR}/${framework_name}.xcframework/ios-arm64-simulator/${framework_name}.framework" \
      "iPhoneSimulator" \
      "${framework_name}"
  done
}

stage_mediapipe_license() {
  local vision_license="${UPSTREAM_DIR}/MediaPipeTasksVision/LICENSE"
  local common_license="${UPSTREAM_DIR}/MediaPipeTasksCommon/LICENSE"

  require_file "${vision_license}"
  require_file "${common_license}"

  if ! cmp -s "${vision_license}" "${common_license}"; then
    echo "error: MediaPipe archive licenses differ; preserve both before refreshing artifacts" >&2
    exit 1
  fi

  run_command ditto "${vision_license}" "${PACKAGE_ROOT}/LICENSE-MediaPipe"
}

# The xcframework zips are all Swift Package Manager downloads, so the license
# and the list of changes have to travel inside them.
add_notices_to_artifacts() {
  local xcframework
  for xcframework in "${ARTIFACTS_DIR}"/*.xcframework; do
    run_command cp "${PACKAGE_ROOT}/LICENSE-MediaPipe" "${PACKAGE_ROOT}/NOTICE" "${xcframework}/"
  done
}

mediapipe_graph_libraries_dir() {
  printf '%s\n' "${UPSTREAM_DIR}/MediaPipeTasksCommon/frameworks/graph_libraries"
}
