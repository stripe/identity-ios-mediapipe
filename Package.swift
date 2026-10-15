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
            checksum: "d2f67cf7079f0865fc2df23b3f49607b205cdb3f49d005c15d68a5f2ede32949"
        ),
        .binaryTarget(
            name: "MediaPipeCommonGraphLibraries",
            url: "\(assets)/MediaPipeCommonGraphLibraries.xcframework.zip",
            checksum: "ed20dbe20a89f16f51c154943650a43d62ff18716e100db22b3bc1ea4ced2343"
        ),
        .binaryTarget(
            name: "MediaPipeTasksCommon",
            url: "\(assets)/MediaPipeTasksCommon.xcframework.zip",
            checksum: "959fd8c32afef7b26668d0c9fc1531913eab4ab300b61991ba4c6755bfdf362a"
        ),
    ]
)
