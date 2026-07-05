import AppKit

private struct IconSize {
    let filename: String
    let pixels: CGFloat
}

private let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1])
private let sizes = [
    IconSize(filename: "icon_16x16.png", pixels: 16),
    IconSize(filename: "icon_16x16@2x.png", pixels: 32),
    IconSize(filename: "icon_32x32.png", pixels: 32),
    IconSize(filename: "icon_32x32@2x.png", pixels: 64),
    IconSize(filename: "icon_128x128.png", pixels: 128),
    IconSize(filename: "icon_128x128@2x.png", pixels: 256),
    IconSize(filename: "icon_256x256.png", pixels: 256),
    IconSize(filename: "icon_256x256@2x.png", pixels: 512),
    IconSize(filename: "icon_512x512.png", pixels: 512),
    IconSize(filename: "icon_512x512@2x.png", pixels: 1024),
]

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for size in sizes {
    let image = drawIcon(size: size.pixels)
    let destination = outputDirectory.appendingPathComponent(size.filename)
    try writePNG(image, to: destination)
}

try writePNG(
    drawIcon(size: 1024),
    to: outputDirectory.deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("AppIcon.png")
)

private func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    NSGraphicsContext.current?.imageInterpolation = .high
    let scale = size / 1024
    let rect = NSRect(x: 0, y: 0, width: size, height: size)

    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
    shadow.shadowBlurRadius = 38 * scale
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)

    let tile = NSBezierPath(roundedRect: rect.insetBy(dx: 64 * scale, dy: 64 * scale), xRadius: 212 * scale, yRadius: 212 * scale)
    shadow.set()
    NSColor(calibratedWhite: 0.97, alpha: 1).setFill()
    tile.fill()
    NSShadow().set()

    fill(tile, with: [
        (0.00, NSColor(calibratedRed: 0.98, green: 0.995, blue: 1.0, alpha: 1)),
        (0.44, NSColor(calibratedRed: 0.78, green: 0.93, blue: 1.0, alpha: 1)),
        (1.00, NSColor(calibratedRed: 0.18, green: 0.55, blue: 0.94, alpha: 1)),
    ], angle: -38)

    NSColor.white.withAlphaComponent(0.38).setStroke()
    tile.lineWidth = 3 * scale
    tile.stroke()

    drawFallingFiles(in: rect, scale: scale)
    drawBucket(in: rect, scale: scale)

    return image
}

private func drawFinderFace(in rect: NSRect, scale: CGFloat) {
    let split = NSBezierPath()
    split.move(to: NSPoint(x: 512 * scale, y: 118 * scale))
    split.curve(to: NSPoint(x: 508 * scale, y: 910 * scale), controlPoint1: NSPoint(x: 542 * scale, y: 326 * scale), controlPoint2: NSPoint(x: 470 * scale, y: 676 * scale))
    NSColor.white.withAlphaComponent(0.24).setStroke()
    split.lineWidth = 10 * scale
    split.stroke()

    let smile = NSBezierPath()
    smile.move(to: NSPoint(x: 314 * scale, y: 404 * scale))
    smile.curve(to: NSPoint(x: 710 * scale, y: 408 * scale), controlPoint1: NSPoint(x: 420 * scale, y: 334 * scale), controlPoint2: NSPoint(x: 594 * scale, y: 336 * scale))
    NSColor(calibratedRed: 0.07, green: 0.25, blue: 0.45, alpha: 0.2).setStroke()
    smile.lineWidth = 18 * scale
    smile.lineCapStyle = .round
    smile.stroke()

    for x in [344, 666] as [CGFloat] {
        let eye = NSBezierPath(ovalIn: NSRect(x: x * scale, y: 600 * scale, width: 46 * scale, height: 58 * scale))
        NSColor(calibratedRed: 0.05, green: 0.22, blue: 0.42, alpha: 0.18).setFill()
        eye.fill()
    }
}

private func drawFallingFiles(in rect: NSRect, scale: CGFloat) {
    struct FilePage {
        let center: NSPoint
        let size: NSSize
        let rotation: CGFloat
        let alpha: CGFloat
        let tint: NSColor
    }

    let pages = [
        FilePage(center: NSPoint(x: 274, y: 820), size: NSSize(width: 128, height: 156), rotation: -20, alpha: 0.76, tint: NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.00, alpha: 1)),
        FilePage(center: NSPoint(x: 474, y: 848), size: NSSize(width: 116, height: 146), rotation: -7, alpha: 0.88, tint: NSColor.white),
        FilePage(center: NSPoint(x: 682, y: 816), size: NSSize(width: 130, height: 158), rotation: 17, alpha: 0.78, tint: NSColor(calibratedRed: 0.93, green: 0.985, blue: 1.00, alpha: 1)),
        FilePage(center: NSPoint(x: 384, y: 718), size: NSSize(width: 110, height: 138), rotation: -13, alpha: 0.86, tint: NSColor.white),
        FilePage(center: NSPoint(x: 612, y: 714), size: NSSize(width: 112, height: 140), rotation: 12, alpha: 0.86, tint: NSColor(calibratedRed: 0.96, green: 0.99, blue: 1.00, alpha: 1)),
        FilePage(center: NSPoint(x: 506, y: 650), size: NSSize(width: 102, height: 128), rotation: 2, alpha: 0.96, tint: NSColor.white),
    ]

    let stream = NSBezierPath()
    stream.move(to: NSPoint(x: 250 * scale, y: 894 * scale))
    stream.curve(to: NSPoint(x: 506 * scale, y: 608 * scale), controlPoint1: NSPoint(x: 356 * scale, y: 780 * scale), controlPoint2: NSPoint(x: 430 * scale, y: 678 * scale))
    stream.curve(to: NSPoint(x: 782 * scale, y: 886 * scale), controlPoint1: NSPoint(x: 592 * scale, y: 690 * scale), controlPoint2: NSPoint(x: 672 * scale, y: 786 * scale))
    stream.curve(to: NSPoint(x: 506 * scale, y: 608 * scale), controlPoint1: NSPoint(x: 662 * scale, y: 794 * scale), controlPoint2: NSPoint(x: 588 * scale, y: 690 * scale))
    stream.curve(to: NSPoint(x: 250 * scale, y: 894 * scale), controlPoint1: NSPoint(x: 420 * scale, y: 686 * scale), controlPoint2: NSPoint(x: 338 * scale, y: 790 * scale))
    stream.close()
    fill(stream, with: [
        (0.00, NSColor.white.withAlphaComponent(0.03)),
        (0.50, NSColor.white.withAlphaComponent(0.24)),
        (1.00, NSColor(calibratedRed: 0.56, green: 0.82, blue: 1.0, alpha: 0.08)),
    ], angle: -90)

    for page in pages {
        drawFilePage(
            center: NSPoint(x: page.center.x * scale, y: page.center.y * scale),
            size: NSSize(width: page.size.width * scale, height: page.size.height * scale),
            rotation: page.rotation,
            alpha: page.alpha,
            tint: page.tint,
            scale: scale
        )
    }

}

private func drawFilePage(center: NSPoint, size: NSSize, rotation: CGFloat, alpha: CGFloat, tint: NSColor, scale: CGFloat) {
    NSGraphicsContext.saveGraphicsState()
    let transform = NSAffineTransform()
    transform.translateX(by: center.x, yBy: center.y)
    transform.rotate(byDegrees: rotation)
    transform.translateX(by: -center.x, yBy: -center.y)
    transform.concat()

    let rect = NSRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    let page = NSBezierPath(roundedRect: rect, xRadius: 16 * scale, yRadius: 16 * scale)

    let shadow = NSShadow()
    shadow.shadowOffset = NSSize(width: 0, height: -8 * scale)
    shadow.shadowBlurRadius = 14 * scale
    shadow.shadowColor = NSColor(calibratedRed: 0.03, green: 0.18, blue: 0.36, alpha: 0.18 * alpha)
    shadow.set()
    tint.withAlphaComponent(alpha).setFill()
    page.fill()
    NSShadow().set()

    NSColor(calibratedRed: 0.18, green: 0.55, blue: 0.90, alpha: 0.24 * alpha).setStroke()
    page.lineWidth = 3 * scale
    page.stroke()

    let dogEar = NSBezierPath()
    dogEar.move(to: NSPoint(x: rect.maxX - 34 * scale, y: rect.maxY))
    dogEar.line(to: NSPoint(x: rect.maxX, y: rect.maxY - 34 * scale))
    dogEar.line(to: NSPoint(x: rect.maxX - 34 * scale, y: rect.maxY - 34 * scale))
    dogEar.close()
    NSColor(calibratedRed: 0.70, green: 0.88, blue: 1.0, alpha: 0.58 * alpha).setFill()
    dogEar.fill()

    NSColor(calibratedRed: 0.22, green: 0.58, blue: 0.94, alpha: 0.34 * alpha).setStroke()
    for offset in [42, 68, 94] as [CGFloat] {
        let line = NSBezierPath()
        line.move(to: NSPoint(x: rect.minX + 24 * scale, y: rect.maxY - offset * scale))
        line.line(to: NSPoint(x: rect.maxX - 26 * scale, y: rect.maxY - offset * scale))
        line.lineWidth = 6 * scale
        line.lineCapStyle = .round
        line.stroke()
    }

    NSGraphicsContext.restoreGraphicsState()
}

private func drawBucket(in rect: NSRect, scale: CGFloat) {
    let bucketShadow = NSShadow()
    bucketShadow.shadowOffset = NSSize(width: 0, height: -14 * scale)
    bucketShadow.shadowBlurRadius = 24 * scale
    bucketShadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
    bucketShadow.set()

    let body = NSBezierPath()
    body.move(to: NSPoint(x: 260 * scale, y: 612 * scale))
    body.line(to: NSPoint(x: 764 * scale, y: 612 * scale))
    body.line(to: NSPoint(x: 682 * scale, y: 230 * scale))
    body.curve(to: NSPoint(x: 342 * scale, y: 230 * scale), controlPoint1: NSPoint(x: 604 * scale, y: 184 * scale), controlPoint2: NSPoint(x: 420 * scale, y: 184 * scale))
    body.close()

    fill(body, with: [
        (0.00, NSColor(calibratedRed: 0.96, green: 0.985, blue: 1.0, alpha: 1)),
        (0.40, NSColor(calibratedRed: 0.73, green: 0.90, blue: 1.0, alpha: 1)),
        (1.00, NSColor(calibratedRed: 0.12, green: 0.48, blue: 0.88, alpha: 1)),
    ], angle: -22)
    NSShadow().set()

    let inner = NSBezierPath()
    inner.move(to: NSPoint(x: 304 * scale, y: 580 * scale))
    inner.line(to: NSPoint(x: 720 * scale, y: 580 * scale))
    inner.line(to: NSPoint(x: 662 * scale, y: 316 * scale))
    inner.curve(to: NSPoint(x: 362 * scale, y: 316 * scale), controlPoint1: NSPoint(x: 590 * scale, y: 278 * scale), controlPoint2: NSPoint(x: 434 * scale, y: 278 * scale))
    inner.close()
    fill(inner, with: [
        (0.00, NSColor.white.withAlphaComponent(0.62)),
        (1.00, NSColor(calibratedRed: 0.26, green: 0.66, blue: 0.98, alpha: 0.34)),
    ], angle: 20)

    let lip = NSBezierPath(roundedRect: NSRect(x: 206 * scale, y: 568 * scale, width: 612 * scale, height: 104 * scale), xRadius: 50 * scale, yRadius: 50 * scale)
    fill(lip, with: [
        (0.00, NSColor.white),
        (0.58, NSColor(calibratedRed: 0.70, green: 0.89, blue: 1.0, alpha: 1)),
        (1.00, NSColor(calibratedRed: 0.22, green: 0.56, blue: 0.93, alpha: 1)),
    ], angle: -18)

    let opening = NSBezierPath(roundedRect: NSRect(x: 268 * scale, y: 604 * scale, width: 488 * scale, height: 42 * scale), xRadius: 21 * scale, yRadius: 21 * scale)
    NSColor(calibratedRed: 0.04, green: 0.20, blue: 0.40, alpha: 0.26).setFill()
    opening.fill()

    let rim = NSBezierPath(roundedRect: NSRect(x: 206 * scale, y: 568 * scale, width: 612 * scale, height: 104 * scale), xRadius: 50 * scale, yRadius: 50 * scale)
    NSColor.white.withAlphaComponent(0.82).setStroke()
    rim.lineWidth = 8 * scale
    rim.stroke()

    let outline = NSBezierPath()
    outline.move(to: NSPoint(x: 260 * scale, y: 612 * scale))
    outline.line(to: NSPoint(x: 764 * scale, y: 612 * scale))
    outline.line(to: NSPoint(x: 682 * scale, y: 230 * scale))
    outline.curve(to: NSPoint(x: 342 * scale, y: 230 * scale), controlPoint1: NSPoint(x: 604 * scale, y: 184 * scale), controlPoint2: NSPoint(x: 420 * scale, y: 184 * scale))
    outline.close()
    NSColor(calibratedRed: 0.02, green: 0.22, blue: 0.48, alpha: 0.24).setStroke()
    outline.lineWidth = 10 * scale
    outline.stroke()
}

private func fill(_ path: NSBezierPath, with stops: [(CGFloat, NSColor)], angle: CGFloat) {
    let gradient: NSGradient?
    switch stops.count {
    case 2:
        gradient = NSGradient(colorsAndLocations: (stops[0].1, stops[0].0), (stops[1].1, stops[1].0))
    case 3:
        gradient = NSGradient(colorsAndLocations: (stops[0].1, stops[0].0), (stops[1].1, stops[1].0), (stops[2].1, stops[2].0))
    default:
        gradient = NSGradient(colors: stops.map(\.1))
    }
    guard let gradient else { return }
    gradient.draw(in: path, angle: angle)
}

private func writePNG(_ image: NSImage, to url: URL) throws {
    guard let source = image.tiffRepresentation, let sourceRep = NSBitmapImageRep(data: source) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let width = Int(image.size.width)
    let height = Int(image.size.height)
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        throw CocoaError(.fileWriteUnknown)
    }

    bitmap.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    sourceRep.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    try data.write(to: url)
}
