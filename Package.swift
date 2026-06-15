// swift-tools-version: 6.0
import PackageDescription

// GPL-3.0 "full" flavor (full-gpl branch): adds the CGAL-backed Alpha,
// Tangential and Euclidean-Witness modules. Linking it makes your app GPL-3.0 —
// use the permissive `SwiftGUDHI` (main branch) for closed-source apps.
let cxx: [SwiftSetting] = [.interoperabilityMode(.Cxx)]

let package = Package(
    name: "SwiftGUDHIFull",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SwiftGUDHIFull", targets: ["SwiftGUDHIFull"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        // GPL-3.0 binary (CGAL/GMP/MPFR), fetched from the builder's release.
        // For local iteration: .binaryTarget(name: "GudhiCoreFull",
        // path: "Frameworks/GudhiCoreFull.xcframework").
        .binaryTarget(
            name: "GudhiCoreFull",
            url: "https://github.com/mnmly/gudhi-xcframework-builder/releases/download/v0.4.0-gpl/GudhiCoreFull.xcframework.zip",
            checksum: "44014b58c5bfb54c24d66b069dc0ae8b654120d51a6d791a0a6d6d913a826c71"
        ),
        .target(
            name: "SwiftGUDHIFull",
            dependencies: ["GudhiCoreFull"],
            swiftSettings: cxx
        ),
        .testTarget(
            name: "SwiftGUDHIFullTests",
            dependencies: ["SwiftGUDHIFull"],
            swiftSettings: cxx
        ),
    ],
    cxxLanguageStandard: .cxx17
)
