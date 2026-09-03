import Foundation

protocol PreferencesStore: AnyObject {
    var hiddenComponentIDs: Set<String> { get set }
}

final class UserDefaultsPreferencesStore: PreferencesStore {
    private enum Keys {
        static let hiddenComponentIDs = "hiddenComponentIDs"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hiddenComponentIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Keys.hiddenComponentIDs) ?? []) }
        set { defaults.set(Array(newValue), forKey: Keys.hiddenComponentIDs) }
    }
}
