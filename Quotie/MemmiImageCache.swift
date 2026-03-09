import UIKit

// MARK: - MemmiImageCache
//
// The Memmi mood PNGs are RGB (no alpha channel) with a solid black background.
// This cache processes each image once per app session: it converts near-black
// pixels to transparent using a soft threshold, then caches the result so we
// never do the work twice.

enum MemmiImageCache {

    // Thread-safe static cache: asset name → processed UIImage
    private static var cache = [String: UIImage]()
    private static let lock = NSLock()

    /// Returns a background-removed version of the named asset, cached after first load.
    static func image(named name: String) -> UIImage? {
        lock.lock()
        if let cached = cache[name] { lock.unlock(); return cached }
        lock.unlock()

        guard let original = UIImage(named: name) else { return nil }
        let processed = original.removingBlackBackground()

        lock.lock()
        cache[name] = processed
        lock.unlock()

        return processed
    }
}

// MARK: - UIImage + background removal

private extension UIImage {

    /// Returns a copy of the receiver with near-black pixels made transparent.
    ///
    /// - Parameter threshold: Brightness 0–1 below which pixels are treated as
    ///   background. Pixels just above threshold fade in smoothly to avoid hard edges.
    func removingBlackBackground(threshold: Float = 0.15) -> UIImage {
        guard let cgImage = cgImage else { return self }

        let width  = cgImage.width
        let height = cgImage.height
        let bpr    = width * 4          // bytes per row (RGBA)

        // Allocate an RGBA pixel buffer and draw the (possibly RGB-only) source into it.
        var pixels = [UInt8](repeating: 0, count: height * bpr)

        guard let ctx = CGContext(
            data: &pixels,
            width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Walk every pixel and compute a soft alpha based on brightness.
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let r = Float(pixels[i])     / 255.0
            let g = Float(pixels[i + 1]) / 255.0
            let b = Float(pixels[i + 2]) / 255.0

            // Perceptual luminance weights give a more natural result than a simple average.
            let lum = 0.299 * r + 0.587 * g + 0.114 * b

            if lum < threshold {
                // Ramp from 0 (pure black) to 255 (at the threshold) — smooth edge.
                let alpha = UInt8(min(lum / threshold, 1.0) * 255.0)
                pixels[i + 3] = alpha
            }
            // Pixels at or above the threshold keep their existing alpha (255 from the draw).
        }

        guard let outImage = ctx.makeImage() else { return self }
        return UIImage(cgImage: outImage, scale: scale, orientation: imageOrientation)
    }
}
