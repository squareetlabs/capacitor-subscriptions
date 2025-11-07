// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SquareetlabsCapacitorSubscriptions",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "SquareetlabsCapacitorSubscriptions",
            targets: ["SubscriptionsPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "SubscriptionsPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/SubscriptionsPlugin"),
        .testTarget(
            name: "SubscriptionsPluginTests",
            dependencies: ["SubscriptionsPlugin"],
            path: "ios/Tests/SubscriptionsPluginTests")
    ]
)