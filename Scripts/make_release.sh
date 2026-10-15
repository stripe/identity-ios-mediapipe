#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
MEDIAPIPE_VERSION="$(tr -d '[:space:]' < "$ROOT/MEDIAPIPE_VERSION")"

ARTIFACTS="$ROOT/Artifacts"
DIST="$ROOT/Dist"

[ -d "$ARTIFACTS" ] || { echo "No Artifacts/. Run Scripts/refresh_artifacts.sh first." >&2; exit 1; }

missing=0
while IFS= read -r framework; do
  [ -f "$framework/Info.plist" ] || { echo "error: $framework has no Info.plist" >&2; missing=1; }
done < <(find "$ARTIFACTS" -type d -name "*.framework")
while IFS= read -r plist; do
  xcframework="$(dirname "$plist")"
  count="$(plutil -extract AvailableLibraries raw "$plist")"
  for ((i = 0; i < count; i++)); do
    id="$(plutil -extract "AvailableLibraries.$i.LibraryIdentifier" raw "$plist")"
    path="$(plutil -extract "AvailableLibraries.$i.LibraryPath" raw "$plist")"
    [ -e "$xcframework/$id/$path" ] || { echo "error: $plist lists $id/$path, which does not exist" >&2; missing=1; }
  done
done < <(find "$ARTIFACTS" -path "*.xcframework/Info.plist")
[ "$missing" -eq 0 ] || { echo "Run Scripts/refresh_artifacts.sh to rebuild the artifacts." >&2; exit 1; }

# The wrapper sources name MediaPipe symbols that change between versions.
# A stale name only fails when an app links, so check them here.
for slice in ios-arm64 ios-arm64-simulator; do
  undefined="$(comm -23 \
    <(grep -ho '"__Z[^"]*"' "$ROOT"/Sources/MediaPipeSPMGraphReferences/*.c | tr -d '"' | sort -u) \
    <(for name in MediaPipeTasksVision MediaPipeCommonGraphLibraries MediaPipeTasksCommon; do
        nm -gU "$ARTIFACTS/$name.xcframework/$slice/$name.framework/$name" 2>/dev/null
      done | awk '{print $NF}' | sort -u))"
  [ -z "$undefined" ] || { echo "error: $slice does not define:" >&2; echo "$undefined" >&2; missing=1; }
done
[ "$missing" -eq 0 ] || { echo "Update Sources/MediaPipeSPMGraphReferences for MediaPipe $MEDIAPIPE_VERSION." >&2; exit 1; }

rm -rf "$DIST" && mkdir -p "$DIST"

# zip records file times, owners and directory order, so the same files would
# give a different zip, and a different checksum, on every build.
reproducible_zip() {
  python3 - "$@" <<'PY'
import os, shutil, stat, sys, zipfile
archive, root, *paths = sys.argv[1:]
names = []
for path in paths:
    names.append(path)
    for parent, dirs, files in os.walk(os.path.join(root, path)):
        relative = os.path.relpath(parent, root)
        # Finder creates .DS_Store files, which would make the zip depend on the machine.
        names += [os.path.join(relative, d) for d in dirs] + [os.path.join(relative, f) for f in files if f != ".DS_Store"]
with zipfile.ZipFile(archive, "w") as z:
    for name in sorted(names):
        full = os.path.join(root, name)
        if os.path.islink(full):
            sys.exit("error: %s is a symlink" % name)
        # 1980-01-01 is the earliest time a zip can store.
        if os.path.isdir(full):
            info = zipfile.ZipInfo(name + "/", (1980, 1, 1, 0, 0, 0))
            info.external_attr = (stat.S_IFDIR | 0o755) << 16
            z.writestr(info, b"")
            continue
        info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
        info.external_attr = (stat.S_IFREG | (0o755 if os.access(full, os.X_OK) else 0o644)) << 16
        info.compress_type = zipfile.ZIP_DEFLATED
        with open(full, "rb") as source, z.open(info, "w") as target:
            shutil.copyfileobj(source, target)
PY
}

for name in MediaPipeTasksVision MediaPipeCommonGraphLibraries MediaPipeTasksCommon; do
  reproducible_zip "$DIST/$name.xcframework.zip" "$ARTIFACTS" "$name.xcframework"
  sum="$(swift package compute-checksum "$DIST/$name.xcframework.zip")"
  echo "$name  $sum"
  python3 - "$ROOT/Package.swift" "$name" "$sum" <<'PY'
import re, sys
path, name, checksum = sys.argv[1:4]
s = open(path).read()
pattern = r'(name: "%s",\n            url: "[^"]*",\n            checksum: ")[0-9a-f]{64}(")' % name
s, n = re.subn(pattern, r'\g<1>%s\g<2>' % checksum, s)
if n != 1:
    sys.exit("could not write the checksum for %s" % name)
open(path, "w").write(s)
PY
done

reproducible_zip "$DIST/StripeMediaPipe-$VERSION.zip" "$ROOT" Artifacts Sources LICENSE LICENSE-MediaPipe NOTICE

sed -i '' "s|^let version = \".*\"|let version = \"$VERSION\"|" "$ROOT/Package.swift"
sed -i '' "s|^  s.version                  = '.*'|  s.version                  = '$VERSION'|" "$ROOT/StripeMediaPipe.podspec"

# The checksums only reproduce with the same Xcode, so the release notes record it.
XCODE="$(xcodebuild -version | head -1) ($(xcodebuild -version | awk '/Build version/ {print $3}'))"

echo
echo "Assets are in Dist/. Commit Package.swift in a pull request. After it merges, run:"
echo "  git tag $VERSION <merge commit SHA> && git push origin $VERSION"
echo "  gh release create $VERSION Dist/* --verify-tag --title $VERSION --notes \"MediaPipeTasksVision $MEDIAPIPE_VERSION, built with $XCODE\""
echo "  pod trunk push StripeMediaPipe.podspec"
