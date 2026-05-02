import SwiftUI

enum WidgetTheme {
    static let appName       = "Goalio"

    static let surface          = Color(red: 0x1E/255, green: 0x29/255, blue: 0x3B/255)
    static let surfaceElevated  = Color(red: 0x0F/255, green: 0x17/255, blue: 0x23/255)
    static let pill             = Color(red: 0x0A/255, green: 0x0F/255, blue: 0x1A/255)

    static let textPrimary      = Color.white
    static let textSecondary    = Color(red: 0x94/255, green: 0xA3/255, blue: 0xB8/255)
    static let divider          = Color.white.opacity(0.10)

    static let accent           = Color(red: 0x34/255, green: 0xD3/255, blue: 0x99/255)
    static let live             = Color(red: 0xEF/255, green: 0x44/255, blue: 0x44/255)

    static let onAccentText     = Color(red: 0x0F/255, green: 0x17/255, blue: 0x2A/255)
}

extension UIColor {
    static let widgetSurface = UIColor(red: 0x1E/255, green: 0x29/255, blue: 0x3B/255, alpha: 1)
}
