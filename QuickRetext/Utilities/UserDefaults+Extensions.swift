import Foundation

extension UserDefaults {
    var isClipboardAutoLoadEnabled: Bool {
        get { object(forKey: "isClipboardAutoLoadEnabled") as? Bool ?? true }
        set { set(newValue, forKey: "isClipboardAutoLoadEnabled") }
    }
}
