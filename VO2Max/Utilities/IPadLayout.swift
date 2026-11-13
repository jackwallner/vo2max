import SwiftUI
import UIKit

/// iPad layout helpers. Screens keep their phone layout inside a centred
/// readable column; the unfolded split is the only place iPad uses two panes.
enum IPadLayout {
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    /// Widest a screen's content runs on iPad.
    static let columnWidth: CGFloat = 660
}

extension View {
    /// Caps the view at the iPad reading width and centres it. A no-op on iPhone.
    @ViewBuilder
    func iPadReadableColumn(maxWidth: CGFloat = IPadLayout.columnWidth) -> some View {
        if IPadLayout.isPad {
            frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            self
        }
    }
}
