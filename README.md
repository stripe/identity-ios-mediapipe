# identity-ios-mediapipe

[MediaPipe Tasks Vision](https://github.com/google-ai-edge/mediapipe),
repackaged so that the [Stripe iOS SDK](https://github.com/stripe/stripe-ios)
can depend on it. It provides face capture for Stripe Identity and is meant to
be used through `stripe-ios`, not on its own.

## Why this exists

`stripe-ios` is installed by version with Swift Package Manager, so everything
it depends on must be installable the same way. MediaPipe's own
packages are not: they only link correctly when the app adds linker flags such
as `-ObjC`, and Swift Package Manager does not let a versioned dependency set
them.

This repository republishes MediaPipe's binaries so that they link without
those flags. No MediaPipe source code is changed. `NOTICE` lists every change
made to the binaries.

## Using it in an app

Apps do not add this package themselves. It comes with Stripe Identity when the
app enables the `Identity` package trait of `stripe-ios-spm`. Apps that leave
the trait off never download this package.

Using this package outside `stripe-ios` is not supported.

## How stripe-ios integrates it

`Package.swift` pins an exact version and links it into `StripeIdentity` only
when the trait is on:

```swift
dependencies: [
    .package(url: "https://github.com/stripe/identity-ios-mediapipe", exact: "1.0.0"),
],
targets: [
    .target(
        name: "StripeIdentity",
        dependencies: [
            .product(
                name: "MediaPipeSPM",
                package: "identity-ios-mediapipe",
                condition: .when(traits: ["Identity"])
            ),
        ]
    ),
]
```

`StripeIdentity.xcodeproj` has its own package reference to the same version.
Both change together on an upgrade.

In code, `StripeIdentity` imports `MediaPipeSPMRuntime`, which re-exports
`MediaPipeTasksVision`, and calls `prepareMediaPipeSPMFaceLandmarkerGraph()`
once before creating a `FaceLandmarker`:

```swift
import MediaPipeSPMRuntime

prepareMediaPipeSPMFaceLandmarkerGraph()
let landmarker = try FaceLandmarker(options: options)
```

The call is what makes the linker keep the Face Landmarker's graphs and
calculators. Without it they are left out of the app and creating the
landmarker fails.

The model file (`face_landmarker.task`) is not part of this package. It ships
in `StripeIdentity`'s resources.

## Limitations

- iOS 15 or later, the same as `stripe-ios`, built with Swift 6.1 (Xcode 16.3)
  or later.
- arm64 only. There is no x86_64 simulator slice, so the simulator works on
  Apple silicon Macs only.
- Only the Face Landmarker task is supported. Other MediaPipe tasks are not
  kept by the linker and are expected to fail at run time.

## Versions

Package and upstream MediaPipe versions are tracked in `VERSION` and
`MEDIAPIPE_VERSION`. `MEDIAPIPE_SOURCES` pins the exact upstream archives.

| identity-ios-mediapipe | MediaPipeTasksVision |
|---|---|
| `1.0.0` | `0.10.21` |

## Issues

- Problems with Stripe Identity: [stripe-ios](https://github.com/stripe/stripe-ios/issues).
- Problems installing or linking this package: [this repository](https://github.com/stripe/identity-ios-mediapipe/issues).
- Problems with MediaPipe itself: [google-ai-edge/mediapipe](https://github.com/google-ai-edge/mediapipe/issues).

To build the artifacts or cut a release, see `CONTRIBUTING.md`.

## License

The scripts and wrapper sources in this repository are available under the MIT
license. See `LICENSE`. The MediaPipe binaries in each release are licensed
under the Apache License, Version 2.0. See `LICENSE-MediaPipe`. `NOTICE` lists
the changes Stripe made to those binaries.
