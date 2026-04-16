import Carbon.HIToolbox
import AppKit

/// Registers system-wide keyboard shortcuts using the Carbon HotKey API.
/// Shortcuts work even when SidePanel is not the active application.
final class GlobalHotkeyManager {

    static let shared = GlobalHotkeyManager()

    private var eventHandler: EventHandlerRef?
    private var registeredHotkeys: [UInt32: () -> Void] = [:]

    private let cmdShift: UInt32 = UInt32(cmdKey | shiftKey)

    private init() {}

    // MARK: - Registration

    func registerHotkeys() {
        // Install the Carbon event handler once.
        installEventHandler()

        // Cmd+Shift+S -- toggle sidebar
        register(keyCode: UInt32(kVK_ANSI_S), modifiers: cmdShift, id: 1) {
            NotificationCenter.default.post(name: .toggleSidebar, object: nil)
        }

        // Cmd+Shift+N -- new tab
        register(keyCode: UInt32(kVK_ANSI_N), modifiers: cmdShift, id: 2) {
            NotificationCenter.default.post(name: .newTab, object: nil)
        }

        // Cmd+Shift+W -- close tab
        register(keyCode: UInt32(kVK_ANSI_W), modifiers: cmdShift, id: 3) {
            NotificationCenter.default.post(name: .closeTab, object: nil)
        }

        // Cmd+Shift+[ -- previous tab
        register(keyCode: UInt32(kVK_ANSI_LeftBracket), modifiers: cmdShift, id: 4) {
            NotificationCenter.default.post(name: .previousTab, object: nil)
        }

        // Cmd+Shift+] -- next tab
        register(keyCode: UInt32(kVK_ANSI_RightBracket), modifiers: cmdShift, id: 5) {
            NotificationCenter.default.post(name: .nextTab, object: nil)
        }

        // Cmd+Shift+L -- focus address bar
        register(keyCode: UInt32(kVK_ANSI_L), modifiers: cmdShift, id: 6) {
            NotificationCenter.default.post(name: .focusAddressBar, object: nil)
        }
    }

    // MARK: - Private Helpers

    private func register(keyCode: UInt32, modifiers: UInt32, id: Int, action: @escaping () -> Void) {
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x5350_4B42), // "SPKB"
            id: UInt32(id)
        )
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            registeredHotkeys[UInt32(id)] = action
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, userData -> OSStatus in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard status == noErr else { return status }

                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                if let action = manager.registeredHotkeys[hotKeyID.id] {
                    DispatchQueue.main.async { action() }
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }
}
