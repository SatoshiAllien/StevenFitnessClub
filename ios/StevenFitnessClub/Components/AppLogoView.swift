import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 44
    var showGlow: Bool = true

    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .shadow(color: SFC.Color.electricBlue.opacity(showGlow ? 0.35 : 0), radius: 12, y: 4)
    }
}

struct AppLogoBanner: View {
    var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 220)
            .shadow(color: SFC.Color.electricBlue.opacity(0.25), radius: 20, y: 8)
    }
}