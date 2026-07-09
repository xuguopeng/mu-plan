// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DesktopPetPlanner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PetPlannerCore", targets: ["PetPlannerCore"]),
        .executable(name: "DesktopPetPlanner", targets: ["DesktopPetPlannerApp"])
    ],
    targets: [
        .target(name: "PetPlannerCore"),
        .executableTarget(
            name: "DesktopPetPlannerApp",
            dependencies: ["PetPlannerCore"]
        ),
        .testTarget(
            name: "PetPlannerCoreTests",
            dependencies: ["PetPlannerCore"]
        )
    ]
)
