import SwiftUI

enum SFC {
    enum Color {
        static let electricBlue = SwiftUI.Color(hex: "007AFF")
        static let deepBlack = SwiftUI.Color(hex: "0A0A0A")
        static let performanceGreen = SwiftUI.Color(hex: "00FF7F")
        static let energyOrange = SwiftUI.Color(hex: "FF7A00")
        static let cardBackground = SwiftUI.Color(hex: "141414")
        static let cardBorder = SwiftUI.Color.white.opacity(0.08)
        static let textPrimary = SwiftUI.Color.white
        static let textSecondary = SwiftUI.Color.white.opacity(0.6)
        static let textTertiary = SwiftUI.Color.white.opacity(0.35)

        static let zone1 = SwiftUI.Color(hex: "5AC8FA")
        static let zone2 = SwiftUI.Color(hex: "34C759")
        static let zone3 = SwiftUI.Color(hex: "FFCC00")
        static let zone4 = SwiftUI.Color(hex: "FF9500")
        static let zone5 = SwiftUI.Color(hex: "FF3B30")
    }

    enum Font {
        static func title(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        static func headline(_ size: CGFloat = 17) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .rounded)
        }
        static func body(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func metric(_ size: CGFloat = 32) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded).monospacedDigit()
        }
        static func caption(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }
}

extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct SFCCardStyle: ViewModifier {
    var accent: SwiftUI.Color = SFC.Color.electricBlue

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: SFC.Radius.lg)
                    .fill(SFC.Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: SFC.Radius.lg)
                            .stroke(SFC.Color.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: accent.opacity(0.12), radius: 16, y: 8)
            )
    }
}

extension View {
    func sfcCard(accent: SwiftUI.Color = SFC.Color.electricBlue) -> some View {
        modifier(SFCCardStyle(accent: accent))
    }
}