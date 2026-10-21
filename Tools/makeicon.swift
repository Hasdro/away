import CoreGraphics
import Foundation
import ImageIO

let output = CommandLine.arguments.dropFirst().first ?? "icon.png"
let pixels = 1024
let s = CGFloat(pixels)
let space = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

guard let ctx = CGContext(
    data: nil,
    width: pixels,
    height: pixels,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("no bitmap context")
}

let inset = s * 0.024
let tile = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
ctx.addPath(CGPath(roundedRect: tile, cornerWidth: s * 0.218, cornerHeight: s * 0.218, transform: nil))
ctx.clip()

let background = CGGradient(
    colorsSpace: space,
    colors: [color(0x15161A), color(0x07080A)] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(background, start: CGPoint(x: 0, y: s), end: CGPoint(x: 0, y: 0), options: [])

let center = CGPoint(x: s * 0.5, y: s * 0.55)
let glow = CGGradient(
    colorsSpace: space,
    colors: [color(0xE7A45C, 0.16), color(0xE7A45C, 0)] as CFArray,
    locations: [0, 1]
)!
ctx.drawRadialGradient(
    glow,
    startCenter: center,
    startRadius: 0,
    endCenter: center,
    endRadius: s * 0.44,
    options: []
)

let left = CGPoint(x: s * 0.18, y: s * 0.55)
let right = CGPoint(x: s * 0.82, y: s * 0.55)
let eye = CGMutablePath()
eye.move(to: left)
eye.addCurve(
    to: right,
    control1: CGPoint(x: s * 0.36, y: s * 0.735),
    control2: CGPoint(x: s * 0.64, y: s * 0.735)
)
eye.addCurve(
    to: left,
    control1: CGPoint(x: s * 0.64, y: s * 0.365),
    control2: CGPoint(x: s * 0.36, y: s * 0.365)
)
eye.closeSubpath()
ctx.addPath(eye)
ctx.setStrokeColor(color(0xF2EDE3, 0.95))
ctx.setLineWidth(s * 0.052)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)
ctx.strokePath()

ctx.setFillColor(color(0xE7A45C))
ctx.fillEllipse(in: CGRect(
    x: center.x - s * 0.105, y: center.y - s * 0.105,
    width: s * 0.21, height: s * 0.21
))

ctx.setFillColor(color(0x0A0B0D))
ctx.fillEllipse(in: CGRect(
    x: center.x - s * 0.042, y: center.y - s * 0.042,
    width: s * 0.084, height: s * 0.084
))

ctx.setFillColor(color(0xF2EDE3, 0.9))
ctx.fillEllipse(in: CGRect(
    x: center.x - s * 0.062, y: center.y + s * 0.02,
    width: s * 0.026, height: s * 0.026
))

guard
    let image = ctx.makeImage(),
    let destination = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: output) as CFURL,
        "public.png" as CFString,
        1,
        nil
    )
else {
    fatalError("could not write \(output)")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("could not finalize \(output)") }
print("wrote \(output)")
