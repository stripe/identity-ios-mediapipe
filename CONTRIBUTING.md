# Contributing

Contributions of any kind are welcome! If you've found a bug or have a feature request, please feel free to [open an issue](https://github.com/stripe/identity-ios-mediapipe/issues). 

<!-- We will try and respond to your issue or pull request within a week. -->

To make changes yourself, follow these steps:

1. [Fork](https://help.github.com/articles/fork-a-repo/) this repository and [clone](https://help.github.com/articles/cloning-a-repository/) it locally.
2. Install the tools. Building requires macOS with Xcode 16.3 or later; releases are built with Xcode 26.4.1.
3. Build the xcframeworks with `Scripts/refresh_artifacts.sh`. It downloads the MediaPipe archives listed in `MEDIAPIPE_SOURCES`, checks their SHA-256, and writes the repackaged frameworks to `Artifacts/`.
4. Make your changes
5. Test your changes. There is no test suite, so rebuild with `Scripts/refresh_artifacts.sh` and, in `Package.swift`, temporarily replace the `url` and `checksum` of each binary target with `path: "Artifacts/<name>.xcframework"`. Point a `stripe-ios` checkout at your clone with `.package(path: "<path to your clone>")`, enable the `Identity` trait in an app that uses that checkout, and check that selfie capture still detects a face on a device and on the simulator.
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

   `make_release.sh` writes the assets to `Dist/` and updates the version and
   checksums in `Package.swift`.
3. Commit those changes, open a pull request, and get it approved and merged.
   Keep `Dist/` as it is. Rebuilding gives the same checksums only with the
   same Xcode version.
4. Tag the merge commit and publish the assets from step 2:

   ```bash
   git fetch origin
   git tag <version> <merge commit SHA>
   git push origin <version>
   gh release create <version> Dist/* --verify-tag --title <version> \
     --notes "MediaPipeTasksVision <MediaPipe version>, built with <Xcode version>"
   ```
5. Update the dependency in `stripe-ios`: `Package.swift` and
   `StripeIdentity.xcodeproj`.

Swift Package Manager downloads the three xcframework archives from the release.
Each xcframework carries `LICENSE-MediaPipe` and `NOTICE` at its root.

## Contributor License Agreement ([CLA](https://en.wikipedia.org/wiki/Contributor_License_Agreement))

Once you have submitted a pull request, sign the CLA by clicking on the badge in the comment from [@CLAassistant](https://github.com/CLAassistant).

<img width="910" alt="image" src="https://user-images.githubusercontent.com/62121649/198740836-70aeb322-5755-49fc-af55-93c8e8a39058.png">

<br />
Thanks for contributing to Stripe! :sparkles:
