// Renders the FuzzyBar app icon. Run: swift Assets/make_icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments[1]

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()
guard let ctx = NSGraphicsContext.current?.cgContext else { exit(1) }

// macOS icon grid: body inset ~10%, corner radius ~22.4% of body.
let inset: CGFloat = size * 0.1
let body = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = body.width * 0.224

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.012), blur: size * 0.03,
              color: NSColor.black.withAlphaComponent(0.35).cgColor)
ctx.addPath(CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil))
ctx.setFillColor(NSColor.black.cgColor)
ctx.fillPath()
ctx.restoreGState()

// Background gradient (deep indigo -> violet)
ctx.saveGState()
ctx.addPath(CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil))
ctx.clip()
let colors = [NSColor(calibratedRed: 0.36, green: 0.30, blue: 0.95, alpha: 1).cgColor,
              NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.55, alpha: 1).cgColor] as CFArray
let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: body.minX, y: body.maxY),
                       end: CGPoint(x: body.maxX, y: body.minY), options: [])
// Soft top highlight
let hl = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [NSColor.white.withAlphaComponent(0.18).cgColor,
                             NSColor.white.withAlphaComponent(0).cgColor] as CFArray,
                    locations: [0, 1])!
ctx.drawLinearGradient(hl, start: CGPoint(x: body.midX, y: body.maxY),
                       end: CGPoint(x: body.midX, y: body.midY), options: [])
ctx.restoreGState()

// Clock face
let center = CGPoint(x: body.midX, y: body.midY)
let faceR = body.width * 0.33
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.006), blur: size * 0.02,
              color: NSColor.black.withAlphaComponent(0.3).cgColor)
ctx.setFillColor(NSColor(calibratedWhite: 0.98, alpha: 1).cgColor)
ctx.fillEllipse(in: CGRect(x: center.x - faceR, y: center.y - faceR, width: faceR * 2, height: faceR * 2))
ctx.restoreGState()

// Hour ticks: bold at 12/3/6/9, soft ("fuzzy") elsewhere
for i in 0..<12 {
    let a = CGFloat(i) / 12 * 2 * .pi
    let major = i % 3 == 0
    let len = major ? faceR * 0.14 : faceR * 0.08
    let w = major ? faceR * 0.05 : faceR * 0.03
    let r1 = faceR * 0.86, r2 = r1 - len
    ctx.setStrokeColor(NSColor(calibratedRed: 0.16, green: 0.12, blue: 0.55, alpha: major ? 0.9 : 0.35).cgColor)
    ctx.setLineWidth(w); ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: center.x + sin(a) * r1, y: center.y + cos(a) * r1))
    ctx.addLine(to: CGPoint(x: center.x + sin(a) * r2, y: center.y + cos(a) * r2))
    ctx.strokePath()
}

// Hands at 8:40 ("twenty to nine")
func hand(angleDeg: CGFloat, length: CGFloat, width: CGFloat, color: NSColor) {
    let a = angleDeg * .pi / 180
    ctx.setStrokeColor(color.cgColor); ctx.setLineWidth(width); ctx.setLineCap(.round)
    ctx.move(to: CGPoint(x: center.x - sin(a) * length * 0.18, y: center.y - cos(a) * length * 0.18))
    ctx.addLine(to: CGPoint(x: center.x + sin(a) * length, y: center.y + cos(a) * length))
    ctx.strokePath()
}
let ink = NSColor(calibratedRed: 0.13, green: 0.10, blue: 0.45, alpha: 1)
let accent = NSColor(calibratedRed: 0.98, green: 0.45, blue: 0.40, alpha: 1)
hand(angleDeg: (8 + 40.0/60) * 30, length: faceR * 0.5, width: faceR * 0.09, color: ink)
hand(angleDeg: 40 * 6, length: faceR * 0.72, width: faceR * 0.065, color: ink)
// Center cap
ctx.setFillColor(accent.cgColor)
let cap = faceR * 0.09
ctx.fillEllipse(in: CGRect(x: center.x - cap, y: center.y - cap, width: cap * 2, height: cap * 2))

img.unlockFocus()
let tiff = img.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))
