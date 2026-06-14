// swift-tools-version: 6.0
import PackageDescription

// Swift/C++ interoperability is enabled for every Swift target that touches the
// GUDHI facade. The constraint (swift#66156) is that downstream dependents of a
// Cxx-interop target must also enable it, so we keep the surface small.
let cxx: [SwiftSetting] = [.interoperabilityMode(.Cxx)]

let package = Package(
    name: "SwiftGUDHI",
    platforms: [
        // Reference types imported from C++ need macOS 13.3+; we target 14 to
        // match the rest of the swift/ packages. Visualization stays native.
        .macOS(.v14)
    ],
    products: [
        .library(name: "SwiftGUDHI", targets: ["SwiftGUDHI"])
    ],
    dependencies: [
        // DocC static-site generation (package plugin; no target dependency).
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        // The prebuilt C++ facade + GUDHI, as a static-library xcframework.
        // Local path for now; switch to url:+checksum: once published.
        .binaryTarget(
            name: "GudhiCore",
            path: "Frameworks/GudhiCore.xcframework"
        ),
        // Swift-idiomatic wrapper around the imported `gudhi_swift` C++ API.
        .target(
            name: "SwiftGUDHI",
            dependencies: ["GudhiCore"],
            swiftSettings: cxx
        ),
        .testTarget(
            name: "SwiftGUDHITests",
            dependencies: ["SwiftGUDHI"],
            swiftSettings: cxx
        ),
    ],
    cxxLanguageStandard: .cxx17
)
