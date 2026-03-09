import UIKit
import SwiftUI

// MARK: - MemmiImageCache
//
// The Memmi mood PNGs are RGB (no alpha channel) with a solid black background.
// This cache processes each image once per app session and stores separate variants
// for light and dark mode — light mode uses a hard cutoff to avoid a dark fringe
// on bright backgrounds, while dark mode uses a soft ramp for smoother edges.

enum MemmiImageCache {

    private static var cache = [String: UIImage]()
    private static let lock = NSLock()

    /// Returns a background-removed image for the given asset name and color scheme.
    static func image(named name: String, scheme: ColorScheme) -> UIImage? {
        let key = "\(name)_\(scheme == .dark ? "d" : "l")"

        lock.lock()
        if let cached = cache[key] { lock.unlock(); return cached }
        lock.unlock()

        guard let original = UIImage(named: name) else { return nil }
        let processed = original.removingBlackBackground(
            threshold: scheme == .dark ? 0.15 : 0.22,
            softEdge:  scheme == .dark          // soft ramp in dark, hard cut in light
        )

        lock.lock()
        cache[key] = processed
        lock.unlock()

        return processed
    }
}

// MARK: - UIImage + background removal

private extension UIImage {

    /// Returns a copy of the receiver with near-black pixels made transparent.
    ///
    /// - Parameters:
    ///   - threshold: Brightness 0–1 below which pixels are considered background.
    ///   - softEdge:  If true, pixels ramp from 0→1 across [0, threshold] (dark mode).
    ///               If false, all sub-threshold pixels are hard-cut to alpha 0 (light mode).
    func removingBlackBackground(threshold: Float, softEdge: Bool) -> UIImage {
        guard let cgImage = cgImage else { return self }

        let width  = cgImage.width
        let height = cgImage.height
        let bpr    = width * 4

        var pixels = [UInt8](repeating: 0, count: height * bpr)

        guard let ctx = CGContext(
            data: &pixels,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for i in stride(from: 0, to: pixels.count, by: 4) {
            let r   = Float(pixels[i])     / 255.0
            let g   = Float(pixels[i + 1]) / 255.0
            let b   = Float(pixels[i + 2]) / 255.0
            let lum = 0.299 * r + 0.587 * g + 0.114 * b   // perceptual luminance

            if lum < threshold {
                if softEdge {
                    // Smooth ramp: fully transparent at 0, fully opaque at threshold
                    pixels[i + 3] = UInt8(min(lum / threshold, 1.0) * 255.0)
                } else {
                    // Hard cut: anything below threshold → fully transparent
                    pixels[i + 3] = 0
                }
            }
            // Above threshold → keep existing alpha (255, set by the draw call)
        }

        guard let outImage = ctx.makeImage() else { return self }
        return UIImage(cgImage: outImage, scale: scale, orientation: imageOrientation)
    }
}
