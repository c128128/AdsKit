// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "AdsKit",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "AdsKit", targets: ["AdsKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
        .package(name: "nanopb", url: "https://github.com/firebase/nanopb.git", .exact("2.30908.0")),
        .package(name: "GoogleUtilities", url: "https://github.com/google/GoogleUtilities.git", .exact("7.6.0")),
        .package(name: "Promises", url: "https://github.com/google/promises.git", .exact("2.0.0")),
        .package(name: "GoogleAppMeasurement", url: "https://github.com/google/GoogleAppMeasurement.git", .exact("8.9.1"))
    ],
    targets: [
        .binaryTarget(name: "GoogleMobileAds", path: "Sources/GoogleMobileAds/GoogleMobileAds.xcframework"),
        .binaryTarget(name: "UserMessagingPlatform", path: "Sources/GoogleMobileAds/UserMessagingPlatform.xcframework"),
        .target(name: "AdsKitAutoload"),
        .target(
            name: "AdsKit",
            dependencies: [
                .product(name: "GoogleAppMeasurement", package: "GoogleAppMeasurement", condition: .when(platforms: [.iOS, .macOS, .tvOS])),
                // We are not sure that products did Google linked from GoogleUtilities, so we link them all.
                .product(name: "GULAppDelegateSwizzler", package: "GoogleUtilities"),
                .product(name: "GULEnvironment", package: "GoogleUtilities"),
                .product(name: "GULLogger", package: "GoogleUtilities"),
                .product(name: "GULISASwizzler", package: "GoogleUtilities"),
                .product(name: "GULMethodSwizzler", package: "GoogleUtilities"),
                .product(name: "GULNetwork", package: "GoogleUtilities"),
                .product(name: "GULNSData", package: "GoogleUtilities"),
                .product(name: "GULReachability", package: "GoogleUtilities"),
                .product(name: "GULUserDefaults", package: "GoogleUtilities"),
                "nanopb",
                .product(name: "FBLPromises", package: "Promises"),
                .byName(name: "GoogleMobileAds", condition: .when(platforms: [.iOS])),
                .byName(name: "UserMessagingPlatform", condition: .when(platforms: [.iOS])),
                "RxSwift",
                .product(name: "RxCocoa", package: "RxSwift"),
                "AdsKitAutoload"
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("JavaScriptCore"),
                .linkedLibrary("c++"),
                .linkedFramework("iAd")
            ]
        )
    ]
)
