import CoreGraphics
import Foundation

enum ScreenshotService {
    static func hasPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestPermission() {
        openSystemSettings()
    }

    static func openSystemSettings() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"]
        try? process.run()
    }

    static func captureInteractive() async throws -> String {
        guard hasPermission() else {
            throw ScreenshotError.permissionRequired
        }

        try FileManager.default.createDirectory(
            at: SharedDatabaseLocation.screenshotsDirectoryURL,
            withIntermediateDirectories: true
        )

        let fileURL = SharedDatabaseLocation.screenshotsDirectoryURL
            .appendingPathComponent("\(UUID().uuidString).png", isDirectory: false)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", fileURL.path]

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                if process.terminationStatus == 0, FileManager.default.fileExists(atPath: fileURL.path) {
                    continuation.resume(returning: fileURL.path)
                } else {
                    continuation.resume(throwing: CancellationError())
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

enum ScreenshotError: LocalizedError {
    case permissionRequired

    var errorDescription: String? {
        switch self {
        case .permissionRequired:
            return LocalizedText.string(.screenshotPermissionRequired)
        }
    }
}
