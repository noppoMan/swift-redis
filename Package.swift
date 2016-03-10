import PackageDescription

let package = Package(
    name: "SwiftRedis",
    dependencies: [
      .Package(url: "https://github.com/noppoMan/CLibUv.git", majorVersion: 0, minor: 1),
      .Package(url: "https://github.com/noppoMan/CHiredis.git", majorVersion: 0, minor: 1)
   ]
)
