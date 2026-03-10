import UIKit
import SwiftUI

// Transparent mood art now lives directly in the asset catalog.
// Keep this tiny wrapper so the rest of the UI doesn't need to know
// whether the assets are processed or raw.

enum MemmiImageCache {
    static func image(named name: String, scheme: ColorScheme) -> UIImage? {
        UIImage(named: name)
    }
}
