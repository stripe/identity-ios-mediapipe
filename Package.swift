// swift-tools-version:6.1
import PackageDescription

let version = "1.0.0"
let assets = "https://github.com/stripe/identity-ios-mediapipe/releases/download/\(version)"

let package = Package(
    name: "MediaPipeSPM",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "MediaPipeSPM",
            targets: ["MediaPipeSPMRuntime"]
        ),
    ],
    targets: [
        .target(
            name: "MediaPipeSPMRuntime",
            dependencies: [
                "MediaPipeSPMGraphReferences",
                "MediaPipeSPMLinkSupport",
                "MediaPipeTasksVision",
            ]
        ),
        .target(
            name: "MediaPipeSPMGraphReferences",
            dependencies: [
                "MediaPipeCommonGraphLibraries",
                "MediaPipeTasksCommon",
            ],
            publicHeadersPath: "include"
        ),
        .target(
            name: "MediaPipeSPMLinkSupport",
            dependencies: [
                "MediaPipeCommonGraphLibraries",
                "MediaPipeTasksCommon",
                "MediaPipeTasksVision",
            ],
            linkerSettings: [
                .linkedFramework("CoreMedia"),
                .linkedFramework("CoreVideo"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Accelerate"),
                .linkedLibrary("c++"),
                .linkedLibrary("z"),
            ]
        ),
        .binaryTarget(
            name: "MediaPipeTasksVision",
            url: "\(assets)/MediaPipeTasksVision.xcframework.zip",
            checksum: "3dcc943a34f7030b96642fac31445774e6fbdc3fe9e9fb07a0a55cdda280befe"
        ),
        .binaryTarget(
            name: "MediaPipeCommonGraphLibraries",
            url: "\(assets)/MediaPipeCommonGraphLibraries.xcframework.zip",
            checksum: "a846be9722d833fa7a527eeac3c50efeb036d4de7e59afbfce725a627b628984"
        ),
        .binaryTarget(
            name: "MediaPipeTasksCommon",
            url: "\(assets)/MediaPipeTasksCommon.xcframework.zip",
            checksum: "35e2bb263416ece83ad6186efea9846c4bc90ca744d6ca4adfba699f6f86bdd5"
        ),
    ]
)
