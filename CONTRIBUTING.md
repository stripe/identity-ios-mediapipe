# Contributing

Contributions of any kind are welcome! If you've found a bug or have a feature request, please feel free to [open an issue](https://github.com/stripe/identity-ios-mediapipe/issues). 

<!-- We will try and respond to your issue or pull request within a week. -->

To make changes yourself, follow these steps:

1. [Fork](https://help.github.com/articles/fork-a-repo/) this repository and [clone](https://help.github.com/articles/cloning-a-repository/) it locally.
2. Install the tools. Building requires macOS with Xcode 16.3 or later; releases are built with Xcode 26.4.1. The test step below also needs [CocoaPods](https://cocoapods.org) (`gem install cocoapods`).
3. Build the xcframeworks with `Scripts/refresh_artifacts.sh`. It downloads the MediaPipe archives listed in `MEDIAPIPE_SOURCES`, checks their SHA-256, and writes the repackaged frameworks to `Artifacts/`.
4. Make your changes
5. Test your changes. There is no test suite, so rebuild with `Scripts/refresh_artifacts.sh`, then point an app that uses `StripeIdentity` at your checkout with `pod 'StripeMediaPipe', :path => '<path to your clone>'` and check that selfie capture still detects a face on a device and on the simulator.
6. Submit a [pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/)

## Releasing

Releases are cut by hand. `main` is protected, so every change, including the
checksum update, goes through a pull request reviewed by a code owner.

1. On a branch, update `VERSION` and the version table in `README.md`. When
   upgrading MediaPipe, also update `MEDIAPIPE_VERSION` and put the URL and
   SHA-256 of Google's new archives in `MEDIAPIPE_SOURCES`.
2. Build the release assets on macOS with Xcode 26.4.1:

   ```bash
   Scripts/refresh_artifacts.sh
   Scripts/make_release.sh
   ```

   `make_release.sh` writes the assets to `Dist/` and updates the checksums in
   `Package.swift` and the version in `StripeMediaPipe.podspec`.
3. Commit those changes, open a pull request, and get it approved and merged.
   Keep `Dist/` as it is. Rebuilding produces different checksums.
4. Tag the merge commit and publish the assets from step 2:

   ```bash
   git fetch origin
   git tag <version> <merge commit SHA>
   git push origin <version>
   gh release create <version> Dist/* --verify-tag --title <version> \
     --notes "MediaPipeTasksVision <MediaPipe version>"
   pod trunk push StripeMediaPipe.podspec
   ```

   Run `pod trunk push` from a checkout of the tag.
5. Update the dependency in `stripe-ios`: `Package.swift`,
   `StripeIdentity.podspec`, and `StripeIdentity.xcodeproj`.

Swift Package Manager downloads the three xcframework archives from the release.
Each xcframework carries `LICENSE-MediaPipe` and `NOTICE` at its root.
CocoaPods uses `StripeMediaPipe-<version>.zip`, containing the frameworks,
wrapper sources, licenses and `NOTICE`.

## Contributor License Agreement ([CLA](https://en.wikipedia.org/wiki/Contributor_License_Agreement))

Once you have submitted a pull request, sign the CLA by clicking on the badge in the comment from [@CLAassistant](https://github.com/CLAassistant).

<img width="910" alt="image" src="https://user-images.githubusercontent.com/62121649/198740836-70aeb322-5755-49fc-af55-93c8e8a39058.png">

<br />
Thanks for contributing to Stripe! :sparkles:
