// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PenggieCore",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "PenggieCore", targets: ["PenggieCore"])
    ],
    targets: [
        .target(
            name: "PenggieCore",
            path: "Penggie/Sources",
            exclude: [
                "PenggieApp.swift",
                "PenggieComposerTextView.swift",
                "PenggieGhosttySession.swift",
                "PenggieGhosttySubstrate.swift",
                "PenggieInteractionKeyCaptureView.swift",
                "PenggieRootView.swift",
                "PenggieSessionModel.swift",
                "PenggieThemeController.swift"
            ],
            sources: [
                "PenggieComposerNativeTrigger.swift",
                "PenggieCodexScreenKind.swift",
                "PenggieDisplayAST.swift",
                "PenggieDisplayASTRenderer.swift",
                "PenggieDisplayRuleEngine.swift",
                "PenggieDisplayTranscriptReconciler.swift",
                "PenggieNativeInteractionPhase.swift",
                "PenggieNativeInteractionProjection.swift",
                "PenggieReadingTranscript.swift",
                "PenggieSessionLifecyclePolicy.swift",
                "PenggieTerminalFrameNormalizer.swift",
                "PenggieTheme.swift"
            ]
        ),
        .testTarget(
            name: "PenggieCoreTests",
            dependencies: ["PenggieCore"],
            path: "Tests/PenggieCoreTests",
            exclude: [
                "Fixtures"
            ]
        )
    ]
)
