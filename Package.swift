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
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", from: "9.5.0")
    ],
    targets: [
        .target(name: "AdsKitAutoload"),
        .target(
            name: "AdsKit",
            dependencies: [
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                "AdsKitAutoload"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
