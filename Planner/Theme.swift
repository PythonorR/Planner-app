import SwiftUI
import UIKit

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}

extension Color {
    /// A colour that resolves per light / dark appearance.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

/// Every colour in the app comes from here.
enum Theme {
    static let bg    = Color(light: 0xF6F7F9, dark: 0x0B0D10)
    static let fg    = Color(light: 0x0E1116, dark: 0xF2F4F7)
    static let muted = Color(light: 0x646B7A, dark: 0x9AA1AD)
    static let line  = Color(light: 0xE3E5EA, dark: 0x23272E)
    static let due   = Color(light: 0xD1242F, dark: 0xFF6B73)

    static let palette: [Color] = [
        Color(light: 0x0F766E, dark: 0x2DD4BF),   // teal
        Color(light: 0x4B45D6, dark: 0x8B87FF),   // indigo
        Color(light: 0xC2570C, dark: 0xFB923C),   // orange
        Color(light: 0xBE1F5A, dark: 0xFF7AA8),   // rose
        Color(light: 0x4D7C0F, dark: 0xA3E635),   // green
        Color(light: 0x1D6FD6, dark: 0x60A5FA),   // blue
    ]
    static let paletteNames = ["Teal", "Indigo", "Orange", "Rose", "Green", "Blue"]

    /// Subject colour by palette index; nil (no subject) uses the foreground colour.
    static func subject(_ index: Int?) -> Color {
        guard let index else { return fg }
        return palette[((index % 6) + 6) % 6]
    }

    static func color(for subject: Subject?) -> Color { subject.map { self.subject($0.colorIndex) } ?? fg }

    /// Applies Auto / Light / Dark to every window (sheets included).
    static func apply(_ setting: String) {
        let style: UIUserInterfaceStyle = setting == "light" ? .light : setting == "dark" ? .dark : .unspecified
        for scene in UIApplication.shared.connectedScenes {
            (scene as? UIWindowScene)?.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}

// MARK: - Type

/// System font at a fixed design size that still grows with Dynamic Type.
struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight

    init(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight))
    }
}

extension View {
    func scaledFont(_ size: CGFloat, _ weight: Font.Weight = .regular, relativeTo style: Font.TextStyle = .body) -> some View {
        modifier(ScaledFont(size: size, weight: weight, relativeTo: style))
    }

    /// 44 pt bold screen title, tracking −1.
    func screenTitle() -> some View {
        scaledFont(44, .bold, relativeTo: .largeTitle)
            .tracking(-1)
            .foregroundStyle(Theme.fg)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    /// Flat list for sheets: no cards, thin separators, app background.
    func plainList() -> some View {
        listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
    }
}
