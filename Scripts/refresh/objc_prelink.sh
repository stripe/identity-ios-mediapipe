#!/usr/bin/env bash

# Merging Objective-C members keeps categories linked without consumer -ObjC flags.
# SwiftPM disallows unsafe linker flags in versioned dependencies.

prelink_objc_members() {
  local framework_name slice platform archive

  for framework_name in MediaPipeTasksVision MediaPipeTasksCommon "${GRAPH_ARTIFACT_NAME}"; do
    for slice in ios-arm64 ios-arm64-simulator; do
      archive="${ARTIFACTS_DIR}/${framework_name}.xcframework/${slice}/${framework_name}.framework/${framework_name}"
      [ -f "${archive}" ] || continue

      platform="ios"
      [ "${slice}" = "ios-arm64-simulator" ] && platform="ios-simulator"

      prelink_one_archive "${archive}" arm64 "${platform}" "${framework_name}/${slice}"
    done
  done
}

prelink_one_archive() {
  local archive="$1" arch="$2" platform="$3" label="$4"
  local work
  work="$(mktemp -d)"

  lipo -thin "${arch}" "${archive}" -output "${work}/orig.a" 2>/dev/null || cp "${archive}" "${work}/orig.a"

  xcrun ld -r -ObjC -arch "${arch}" -platform_version "${platform}" "${MIN_IOS_VERSION}" "${MIN_IOS_VERSION}" \
    -why_load -o /dev/null "${work}/orig.a" 2>&1 \
    | sed -nE 's/^-ObjC (forced|caused) load of .*\((.*)\)$/\2/p' | sort -u > "${work}/forced.txt"

  # As of MediaPipe 0.10.21 every archive has Objective-C members, so none means
  # ld changed its -why_load output or MediaPipe moved them.
  if [ ! -s "${work}/forced.txt" ]; then
    echo "error: found no Objective-C members in ${label}" >&2
    exit 1
  fi

  python3 "${SCRIPT_DIR}/refresh/split_ar.py" "${work}/orig.a" "${work}/members" > "${work}/index.txt"

  # Name-based selection cannot distinguish duplicate archive members.
  if comm -12 <(cut -f2 "${work}/index.txt" | sort | uniq -d) "${work}/forced.txt" | grep -q .; then
    echo "error: ${label} repeats the name of an Objective-C member" >&2
    exit 1
  fi

  local keep=() merge=() file name
  while IFS=$'\t' read -r file name; do
    if grep -qxF "${name}" "${work}/forced.txt"; then
      merge+=("${file}")
    else
      keep+=("${file}")
    fi
  done < "${work}/index.txt"

  # Linking the archive would pull in dependencies and duplicate calculator registrations.
  xcrun ld -r -arch "${arch}" -platform_version "${platform}" "${MIN_IOS_VERSION}" "${MIN_IOS_VERSION}" \
    -o "${work}/objc.o" "${merge[@]}"

  # -D leaves build times, user and umask out of the archive, so the release checksums are reproducible.
  xcrun libtool -static -D -o "${work}/new.a" "${work}/objc.o" ${keep[@]+"${keep[@]}"} 2>/dev/null
  # the graph artifact is written read-only, so replace the file rather than write into it
  cp -f "${work}/new.a" "${archive}"

  echo "  ${label}: merged $(wc -l < "${work}/forced.txt" | tr -d ' ') Objective-C members"
  rm -rf "${work}"
}
