// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "SMPager",
    products: [
        .library(
            name: "SMPager",
            targets: ["SMPager"])
    ],
		dependencies: [],
    targets: [
        .target(
            name: "SMPager",
						dependencies: [],
						path: "SMPager")
    ],
		swiftLanguageVersions: [.v5]
)
