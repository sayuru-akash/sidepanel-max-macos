#!/usr/bin/env swift

import AppKit

let outputPath = CommandLine.arguments.dropFirst().first ?? "Assets/AppIcon/SidePanel-1024.png"
let size: CGFloat = 1024
let canvas = NSRect(x: 0, y: 0, width: size, height: size)

let image = NSImage(size: canvas.size)
image.lockFocus()

NSColor.clear.setFill()
canvas.fill()

let baseRect = canvas.insetBy(dx: 48, dy: 48)
let basePath = NSBezierPath(roundedRect: baseRect, xRadius: 220, yRadius: 220)

let baseGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.05, blue: 0.22, alpha: 1.0),
    NSColor(calibratedRed: 0.33, green: 0.15, blue: 0.60, alpha: 1.0),
    NSColor(calibratedRed: 0.77, green: 0.35, blue: 0.97, alpha: 1.0)
])
baseGradient?.draw(in: basePath, angle: 58)

let topGlow = NSBezierPath(ovalIn: NSRect(x: 180, y: 620, width: 660, height: 280))
let glowGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.98, green: 0.86, blue: 1.0, alpha: 0.35),
    NSColor(calibratedRed: 0.98, green: 0.86, blue: 1.0, alpha: 0.0)
])
glowGradient?.draw(in: topGlow, relativeCenterPosition: NSPoint(x: 0, y: 0))

let panelShadow = NSShadow()
panelShadow.shadowBlurRadius = 32
panelShadow.shadowColor = NSColor(calibratedRed: 0.05, green: 0.02, blue: 0.12, alpha: 0.55)
panelShadow.shadowOffset = NSSize(width: 0, height: -10)
panelShadow.set()

let panelRect = NSRect(x: 260, y: 230, width: 504, height: 564)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 78, yRadius: 78)
NSColor(calibratedRed: 0.13, green: 0.08, blue: 0.28, alpha: 0.92).setFill()
panelPath.fill()

NSGraphicsContext.current?.saveGraphicsState()
let panelClip = NSBezierPath(roundedRect: panelRect.insetBy(dx: 20, dy: 20), xRadius: 56, yRadius: 56)
panelClip.addClip()

let surfaceGradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.75, green: 0.57, blue: 0.99, alpha: 0.9),
    NSColor(calibratedRed: 0.44, green: 0.24, blue: 0.75, alpha: 0.9)
])
surfaceGradient?.draw(in: panelClip, angle: -90)
NSGraphicsContext.current?.restoreGraphicsState()

let railRect = NSRect(x: panelRect.minX + 26, y: panelRect.minY + 26, width: 118, height: panelRect.height - 52)
let railPath = NSBezierPath(roundedRect: railRect, xRadius: 44, yRadius: 44)
NSColor(calibratedRed: 0.19, green: 0.10, blue: 0.35, alpha: 0.82).setFill()
railPath.fill()

func drawCapsule(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, alpha: CGFloat) {
    let path = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: width, height: height), xRadius: height / 2, yRadius: height / 2)
    NSColor(calibratedRed: 0.96, green: 0.90, blue: 1.0, alpha: alpha).setFill()
    path.fill()
}

drawCapsule(x: panelRect.minX + 188, y: panelRect.maxY - 132, width: 286, height: 40, alpha: 0.66)
drawCapsule(x: panelRect.minX + 188, y: panelRect.maxY - 206, width: 250, height: 34, alpha: 0.52)
drawCapsule(x: panelRect.minX + 188, y: panelRect.maxY - 270, width: 218, height: 30, alpha: 0.44)

let accentCircle = NSBezierPath(ovalIn: NSRect(x: 660, y: 650, width: 120, height: 120))
NSColor(calibratedRed: 1.0, green: 0.86, blue: 1.0, alpha: 0.75).setFill()
accentCircle.fill()

let ringPath = NSBezierPath(ovalIn: NSRect(x: 692, y: 682, width: 56, height: 56))
ringPath.lineWidth = 8
NSColor(calibratedRed: 0.39, green: 0.18, blue: 0.68, alpha: 0.95).setStroke()
ringPath.stroke()

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render icon image.\n", stderr)
    exit(1)
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
do {
    try pngData.write(to: outputURL)
    print("Generated icon PNG at \(outputPath)")
} catch {
    fputs("Failed to write icon PNG: \(error)\n", stderr)
    exit(1)
}