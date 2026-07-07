import AppKit

/// 게임 한 프레임을 비트맵 이미지로 굽는다 (레티나 터치바용 2x).
/// 이 시스템의 터치바에서는 커스텀 뷰가 합성되지 않아, TouchBarLyrics와
/// 같은 방식으로 구운 이미지를 테두리 없는 NSButton에 표시한다.
final class GameRenderer {
    static let size = NSSize(width: GameEngine.width, height: 30)

    private let dinoColor = NSColor(white: 0.91, alpha: 1)
    private let deadDinoColor = NSColor(white: 0.5, alpha: 1)
    private let cactusColor = NSColor(white: 0.62, alpha: 1)
    private let groundColor = NSColor(white: 0.28, alpha: 1)
    private let textColor = NSColor(white: 0.9, alpha: 1)
    private let dimTextColor = NSColor(white: 0.45, alpha: 1)
    private var lastKey: String?

    /// 내용이 안 바뀌는 정지 화면(대기/사망)은 nil을 반환해 다시 굽지 않는다
    func render(engine: GameEngine) -> NSImage? {
        switch engine.phase {
        case .idle, .dead:
            let key = "\(engine.phase)|\(Int(engine.score))|\(engine.hiScore)"
            if key == lastKey { return nil }
            lastKey = key
        case .running:
            lastKey = nil
        }

        let size = Self.size
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width) * 2, pixelsHigh: Int(size.height) * 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { return nil }
        rep.size = size

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

        NSColor.black.setFill()
        NSRect(origin: .zero, size: size).fill()

        drawGround(engine: engine)
        drawObstacles(engine: engine)
        drawDino(engine: engine)
        drawScore(engine: engine)
        drawOverlayText(engine: engine)

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }

    private func drawGround(engine: GameEngine) {
        groundColor.setFill()
        let gy = GameEngine.groundY
        var x = -engine.distance.truncatingRemainder(dividingBy: 14)
        while x < Self.size.width {
            NSRect(x: x, y: gy - 1.5, width: 7, height: 1).fill()
            x += 14
        }
    }

    private func drawObstacles(engine: GameEngine) {
        cactusColor.setFill()
        let gy = GameEngine.groundY
        for o in engine.obstacles {
            NSRect(x: o.x, y: gy, width: o.w, height: o.h).fill()
            NSRect(x: o.x - 2.5, y: gy + o.h * 0.45, width: 2.5, height: 2).fill()
            NSRect(x: o.x + o.w, y: gy + o.h * 0.6, width: 2.5, height: 2).fill()
        }
    }

    private func drawDino(engine: GameEngine) {
        let px = GameEngine.playerX
        let py = GameEngine.groundY + engine.jumpOffset
        (engine.phase == .dead ? deadDinoColor : dinoColor).setFill()

        NSRect(x: px, y: py + 3, width: 14, height: 8).fill() // 몸통
        NSRect(x: px + 9, y: py + 9, width: 10, height: 7).fill() // 머리
        NSRect(x: px - 4, y: py + 6, width: 5, height: 3).fill() // 꼬리

        // 달리는 동안 두 다리가 번갈아 든다 (공중/정지 상태는 둘 다 내림)
        let stride = engine.phase == .running && engine.jumpOffset <= 0
            ? (engine.frame / 5) % 2 : 0
        if stride == 0 {
            NSRect(x: px + 2, y: py, width: 3, height: 4).fill()
            NSRect(x: px + 9, y: py + 1, width: 3, height: 3).fill()
        } else {
            NSRect(x: px + 2, y: py + 1, width: 3, height: 3).fill()
            NSRect(x: px + 9, y: py, width: 3, height: 4).fill()
        }

        NSColor.black.setFill()
        NSRect(x: px + 15, y: py + 12.5, width: 2, height: 2).fill() // 눈
    }

    private func drawScore(engine: GameEngine) {
        guard engine.phase != .idle || engine.hiScore > 0 else { return }
        let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)

        var x = Self.size.width - 8
        if engine.phase != .idle {
            let text = String(format: "%05d", Int(engine.score))
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
            let w = text.size(withAttributes: attrs).width
            x -= w
            text.draw(at: NSPoint(x: x, y: 15), withAttributes: attrs)
        }
        if engine.hiScore > 0 {
            let text = String(format: "HI %05d", engine.hiScore)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: dimTextColor]
            x -= text.size(withAttributes: attrs).width + 10
            text.draw(at: NSPoint(x: x, y: 15), withAttributes: attrs)
        }
    }

    private func drawOverlayText(engine: GameEngine) {
        let message: String
        var color = textColor
        switch engine.phase {
        case .idle: message = "탭/클릭 = 시작 · 달리는 중 탭/클릭 = 점프"
        case .dead: message = "GAME OVER · 탭/클릭 = 재시작"
        case .running:
            // 시작 직후 2초 동안 조작법 힌트를 흐리게 보여준다
            guard engine.score < 18 else { return }
            message = "탭/클릭 = 점프"
            color = dimTextColor
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: color,
        ]
        let textSize = message.size(withAttributes: attrs)
        message.draw(
            at: NSPoint(x: (Self.size.width - textSize.width) / 2,
                        y: (Self.size.height - textSize.height) / 2),
            withAttributes: attrs)
    }
}
