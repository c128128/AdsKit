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
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0")
    ],
    targets: [
        .binaryTarget(name: "GoogleAppMeasurement", path: "Sources/GoogleMobileAds/GoogleAppMeasurement.xcframework"),
        .binaryTarget(name: "GoogleAppMeasurementIdentitySupport", path: "Sources/GoogleMobileAds/GoogleAppMeasurementIdentitySupport.xcframework"),
        .binaryTarget(name: "GoogleMobileAds", path: "Sources/GoogleMobileAds/GoogleMobileAds.xcframework"),
        .binaryTarget(name: "GoogleUtilities", path: "Sources/GoogleMobileAds/GoogleUtilities.xcframework"),
        .binaryTarget(name: "nanopb", path: "Sources/GoogleMobileAds/nanopb.xcframework"),
        .binaryTarget(name: "PromisesObjC", path: "Sources/GoogleMobileAds/PromisesObjC.xcframework"),
        .binaryTarget(name: "UserMessagingPlatform", path: "Sources/GoogleMobileAds/UserMessagingPlatform.xcframework"),
        .target(name: "AdsKitAutoload"),
        .target(
            name: "AdsKit",
            dependencies: [
                .byName(name: "GoogleAppMeasurement", condition: .when(platforms: [.iOS])),
                .byName(name: "GoogleAppMeasurementIdentitySupport", condition: .when(platforms: [.iOS])),
                .byName(name: "GoogleMobileAds", condition: .when(platforms: [.iOS])),
                .byName(name: "GoogleUtilities", condition: .when(platforms: [.iOS])),
                .byName(name: "nanopb", condition: .when(platforms: [.iOS])),
                .byName(name: "PromisesObjC", condition: .when(platforms: [.iOS])),
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
