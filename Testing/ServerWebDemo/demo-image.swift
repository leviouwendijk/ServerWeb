import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Draws the demo mark (one tile per layer) and encodes it as PNG bytes,
/// so the demo serves a real binary asset.
enum DemoImage {
    static let path = "/assets/img/mark.png"

    static func png(
        size: Int = 128
    ) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw DemoImageError.context
        }

        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.16, 0.44, 0.42),
            (0.85, 0.47, 0.20),
            (0.30, 0.38, 0.70),
            (0.62, 0.25, 0.45),
        ]

        let half = CGFloat(size) / 2
        let inset = CGFloat(size) * 0.04

        for (index, color) in colors.enumerated() {
            let x = CGFloat(index % 2) * half
            let y = CGFloat(index / 2) * half
            let tile = CGRect(x: x, y: y, width: half, height: half)
                .insetBy(dx: inset, dy: inset)

            context.setFillColor(red: color.0, green: color.1, blue: color.2, alpha: 1)
            context.addPath(
                CGPath(
                    roundedRect: tile,
                    cornerWidth: inset * 2,
                    cornerHeight: inset * 2,
                    transform: nil
                )
            )
            context.fillPath()
        }

        guard let image = context.makeImage() else {
            throw DemoImageError.image
        }

        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw DemoImageError.encode
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw DemoImageError.encode
        }

        return data as Data
    }
}

enum DemoImageError: Error, LocalizedError {
    case context
    case image
    case encode

    var errorDescription: String? {
        switch self {
        case .context:
            return "Could not create bitmap context"
        case .image:
            return "Could not render demo mark"
        case .encode:
            return "Could not encode demo mark as PNG"
        }
    }
}
