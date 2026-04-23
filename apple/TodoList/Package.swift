// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TodoListApp",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(name: "TodoListApp", targets: ["TodoListApp"])
    ],
    targets: [
        .executableTarget(
            name: "TodoListApp",
            path: "Sources",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
