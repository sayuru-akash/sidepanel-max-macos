import Foundation

enum AppVersion {
    static let current: String = resolvedVersion()

    static var buildConfiguration: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }

    static var settingsLabel: String {
        "Version \(current)"
    }

    static var settingsDetail: String {
        "\(buildConfiguration) build"
    }

    private static func resolvedVersion() -> String {
        if let bundleVersion = bundleVersion(), isSemanticVersion(bundleVersion) {
            return bundleVersion
        }

        if let fileVersion = fileVersionFromVersionFile() {
            return fileVersion
        }

        return "dev"
    }

    private static func bundleVersion() -> String? {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        for candidate in [shortVersion, buildVersion] {
            guard let candidate else { continue }
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$(") {
                return trimmed
            }
        }

        return nil
    }

    private static func fileVersionFromVersionFile() -> String? {
        for directory in searchDirectories() {
            if let version = versionInHierarchy(startingAt: directory) {
                return version
            }
        }

        return nil
    }

    private static func searchDirectories() -> [URL] {
        var directories: [URL] = []

        if let executableURL = Bundle.main.executableURL {
            directories.append(executableURL.deletingLastPathComponent())
        }

        directories.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true))

        if let resourceURL = Bundle.main.resourceURL {
            directories.append(resourceURL)
        }

        var uniqueDirectories: [URL] = []
        var seenPaths = Set<String>()

        for directory in directories {
            let path = directory.standardizedFileURL.path
            if seenPaths.insert(path).inserted {
                uniqueDirectories.append(directory.standardizedFileURL)
            }
        }

        return uniqueDirectories
    }

    private static func versionInHierarchy(startingAt directory: URL) -> String? {
        var currentDirectory = directory.standardizedFileURL

        for _ in 0..<8 {
            let candidate = currentDirectory.appendingPathComponent("version.txt")
            if let contents = try? String(contentsOf: candidate, encoding: .utf8) {
                let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
                if isSemanticVersion(trimmed) {
                    return trimmed
                }
            }

            let parentDirectory = currentDirectory.deletingLastPathComponent()
            if parentDirectory.path == currentDirectory.path {
                break
            }
            currentDirectory = parentDirectory
        }

        return nil
    }

    private static func isSemanticVersion(_ value: String) -> Bool {
        value.range(of: #"^\d+\.\d+\.\d+$"#, options: .regularExpression) != nil
    }
}
