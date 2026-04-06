import Foundation

extension UserDefaults {
    public var isClipboardAutoLoadEnabled: Bool {
        get { object(forKey: "isClipboardAutoLoadEnabled") as? Bool ?? true }
        set { set(newValue, forKey: "isClipboardAutoLoadEnabled") }
    }
}
