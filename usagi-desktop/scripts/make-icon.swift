import AppKit

// Package the supplied poster as an icon, preserving the complete image.
let source = CommandLine.arguments[1]
let output = CommandLine.arguments[2]
guard let poster = NSImage(contentsOfFile: source),
      let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024,
        pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not load poster or create icon canvas")
}
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high
let tile = NSRect(x: 32, y: 32, width: 960, height: 960)
let clip = NSBezierPath(roundedRect: tile, xRadius: 190, yRadius: 190)
clip.addClip()
NSColor(calibratedRed: 0.85, green: 0.93, blue: 0.73, alpha: 1).setFill()
clip.fill()
let scale = min(tile.width / poster.size.width, tile.height / poster.size.height)
let size = NSSize(width: poster.size.width * scale, height: poster.size.height * scale)
poster.draw(in: NSRect(x: 512 - size.width / 2, y: 512 - size.height / 2,
                      width: size.width, height: size.height),
            from: .zero, operation: .sourceOver, fraction: 1)
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
