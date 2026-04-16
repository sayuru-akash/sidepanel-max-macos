import SwiftData
import Foundation

/// Sets up the SwiftData model container and provides auto-save.
final class PersistenceController {

    static let shared = PersistenceController()

    let container: ModelContainer

    private var autoSaveTimer: Timer?

    private init() {
        let schema = Schema([
            Tab.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Preview / testing container (in-memory).
    static var preview: PersistenceController {
        let controller = PersistenceController(inMemory: true)
        return controller
    }

    private init(inMemory: Bool) {
        let schema = Schema([Tab.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    // MARK: - Auto-Save

    func startAutoSave(interval: TimeInterval = 30) {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.save()
        }
    }

    func save() {
        Task { @MainActor in
            try? container.mainContext.save()
        }
    }
}
