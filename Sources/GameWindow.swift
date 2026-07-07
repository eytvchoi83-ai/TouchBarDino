import AppKit

/// 게임 화면을 그리고 클릭을 점프로 전달하는 뷰
final class GameClickView: NSView {
    var onMouseDown: (() -> Void)?
    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()
        // 확대해도 픽셀이 뭉개지지 않게
        NSGraphicsContext.current?.imageInterpolation = .none
        image?.draw(in: bounds)
    }

    override func mouseDown(with event: NSEvent) {
        onMouseDown?()
    }

    /// 다른 앱을 쓰다가 바로 클릭해도 그 첫 클릭이 점프가 되게
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// 화면 위에 항상 떠 있는 미니 게임 창.
/// 터치바와 같은 프레임을 표시하고, 마우스 클릭 = 터치바 탭.
/// 포커스를 뺏지 않는 패널이라 작업 중인 앱이 방해받지 않는다.
final class GameWindowController {
    private static let frameName = "GameWindow"
    private static let scale: CGFloat = 1.6

    private let panel: NSPanel
    private let view: GameClickView

    var onTap: (() -> Void)? {
        get { view.onMouseDown }
        set { view.onMouseDown = newValue }
    }
    var isVisible: Bool { panel.isVisible }

    init() {
        let size = NSSize(
            width: GameRenderer.size.width * Self.scale,
            height: GameRenderer.size.height * Self.scale)
        view = GameClickView(frame: NSRect(origin: .zero, size: size))
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.masksToBounds = true

        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true // 배경을 끌면 창 이동
        panel.contentView = view
    }

    func show() {
        if !panel.setFrameUsingName(Self.frameName) {
            // 저장된 위치가 없으면 주 화면 아래 중앙에
            if let screen = NSScreen.main {
                let f = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(
                    x: f.midX - panel.frame.width / 2,
                    y: f.minY + 100))
            }
        }
        panel.orderFront(nil)
        Log.info("game window shown")
    }

    func hide() {
        panel.saveFrame(usingName: Self.frameName)
        panel.orderOut(nil)
        Log.info("game window hidden")
    }

    func update(image: NSImage) {
        view.image = image
    }
}
