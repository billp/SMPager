// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "SMPager",
    platforms: [
      .iOS(.v9)
    ],
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
