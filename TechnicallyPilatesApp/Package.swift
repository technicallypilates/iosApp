// swift-tools-version: 5.7.1
import PackageDescription

let package = Package(
    name: "TechnicallyPilates",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "TechnicallyPilates",
            targets: ["TechnicallyPilates"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "TechnicallyPilates",
            dependencies: [
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ]
        )
    ]
) 