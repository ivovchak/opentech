// Make an app icon with a badge: the source icon plus a rounded blue label in the bottom-right corner.
// Used by install.sh for the OT Claude shortcut, so it is easy to tell from the personal Claude.
// Usage: swift make-icon.swift SOURCE.icns OUTPUT.icns [LABEL]
import AppKit

let args = CommandLine.arguments
guard args.count >= 3, let src = NSImage(contentsOfFile: args[1]) else {
  FileHandle.standardError.write("usage: make-icon.swift SOURCE.icns OUTPUT.icns [LABEL]\n".data(using: .utf8)!)
  exit(1)
}
let output = URL(fileURLWithPath: args[2])
let label = args.count > 3 ? args[3] : "OT"
let blue = NSColor(srgbRed: 0.16, green: 0.38, blue: 0.85, alpha: 1)  // same blue as the ot-claude status line badge

func render(_ px: Int) -> Data {
  let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                             samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                             colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
  rep.size = NSSize(width: px, height: px)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  NSGraphicsContext.current?.imageInterpolation = .high
  let s = CGFloat(px)
  src.draw(in: NSRect(x: 0, y: 0, width: s, height: s))

  // Badge: bottom-right, inside the standard macOS icon grid (content is ~80% of the canvas)
  let h = s * 0.30, w = s * 0.46
  let rect = NSRect(x: s * 0.90 - w, y: s * 0.10, width: w, height: h)
  let path = NSBezierPath(roundedRect: rect, xRadius: h * 0.28, yRadius: h * 0.28)
  NSGraphicsContext.saveGraphicsState()
  let shadow = NSShadow()
  shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
  shadow.shadowBlurRadius = s * 0.02
  shadow.shadowOffset = NSSize(width: 0, height: -s * 0.008)
  shadow.set()
  blue.setFill()
  path.fill()
  NSGraphicsContext.restoreGraphicsState()
  NSColor.white.setStroke()
  path.lineWidth = max(1, s * 0.012)
  path.stroke()

  // Longer labels (profile names) get a smaller font so they stay inside the badge
  var text = NSAttributedString(string: label, attributes: [
    .font: NSFont.systemFont(ofSize: h * 0.62, weight: .heavy), .foregroundColor: NSColor.white])
  if text.size().width > w * 0.84 {
    text = NSAttributedString(string: label, attributes: [
      .font: NSFont.systemFont(ofSize: h * 0.62 * w * 0.84 / text.size().width, weight: .heavy),
      .foregroundColor: NSColor.white])
  }
  let ts = text.size()
  text.draw(at: NSPoint(x: rect.midX - ts.width / 2, y: rect.midY - ts.height / 2))
  NSGraphicsContext.restoreGraphicsState()
  return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
let iconset = fm.temporaryDirectory.appendingPathComponent("ot-icon-\(getpid()).iconset")
try? fm.removeItem(at: iconset)
try fm.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
  try render(base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
  try render(base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try p.run()
p.waitUntilExit()
try? fm.removeItem(at: iconset)
exit(p.terminationStatus)
