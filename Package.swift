// swift-tools-version: 6.3

import PackageDescription

let package = Package(
  name: "TechBlog",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "BlogCore", targets: ["BlogCore"]),
    .library(name: "BlogRouter", targets: ["BlogRouter"]),
    .library(name: "BlogViews", targets: ["BlogViews"]),
    .library(name: "BlogSite", targets: ["BlogSite"]),
    .executable(name: "BlogBuilder", targets: ["BlogBuilder"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-markdown", from: "0.8.0"),
    .package(
      url: "https://github.com/pointfreeco/swift-html",
      revision: "14d01d19e43598167a8f8965af478285835ca010"
    ),
    .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.7.0"),
  ],
  targets: [
    .target(
      name: "BlogCore",
      dependencies: [
        .product(name: "Markdown", package: "swift-markdown")
      ]
    ),
    .target(
      name: "BlogRouter",
      dependencies: [
        .product(name: "URLRouting", package: "swift-url-routing")
      ]
    ),
    .target(
      name: "BlogViews",
      dependencies: [
        "BlogCore",
        "BlogRouter",
        .product(name: "Html", package: "swift-html"),
        .product(name: "Markdown", package: "swift-markdown"),
      ]
    ),
    .target(
      name: "BlogSite",
      dependencies: [
        "BlogCore",
        "BlogRouter",
        "BlogViews",
      ]
    ),
    .executableTarget(
      name: "BlogBuilder",
      dependencies: [
        "BlogCore",
        "BlogRouter",
        "BlogSite",
      ]
    ),
    .testTarget(name: "BlogCoreTests", dependencies: ["BlogCore"]),
    .testTarget(name: "BlogRouterTests", dependencies: ["BlogRouter"]),
    .testTarget(
      name: "BlogSiteTests",
      dependencies: ["BlogCore", "BlogRouter", "BlogSite"]
    ),
    .testTarget(
      name: "BlogSnapshotTests",
      dependencies: ["BlogCore", "BlogRouter", "BlogViews"]
    ),
  ]
)
