import AppKit
import SwiftUI

/// Light or dark, chosen in the panel and remembered. Light is the default and the
/// system setting is not followed: the choice is the user's, made with the toggle.
enum PanelAppearance: String {
    case light
    case dark

    static let storageKey = "panelAppearance"

    static var stored: PanelAppearance {
        UserDefaults.standard.string(forKey: storageKey).flatMap(PanelAppearance.init) ?? .light
    }

    var toggled: PanelAppearance { self == .light ? .dark : .light }

    var colorScheme: ColorScheme { self == .light ? .light : .dark }

    /// The symbol shows the mode a click switches to.
    var toggleSymbol: String { self == .light ? "moon" : "sun.max" }
    var toggleHelp: String { self == .light ? "Switch to dark" : "Switch to light" }

    /// Setting it on the application is what reaches the AppKit window behind the panel;
    /// a SwiftUI color scheme on its own does not always do.
    func apply() {
        NSApp.appearance = NSAppearance(named: self == .light ? .aqua : .darkAqua)
    }
}
