import SwiftUI

struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.divider)
            .frame(height: Theme.Size.hairline)
    }
}
