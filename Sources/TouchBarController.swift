import AppKit

/// 터치바 탭을 손가락이 닿는 순간(touch down)에 전달하는 버튼.
/// 기본 NSButton 액션은 손을 뗄 때 발화해서 점프 반응이 늦다.
final class TouchDownButton: NSButton {
    var onTouchDown: (() -> Void)?

    override func touchesBegan(with event: NSEvent) {
        onTouchDown?()
        super.touchesBegan(with: event)
    }
}

/// 컨트롤 스트립의 게임 버튼과, 그걸 눌렀을 때 뜨는
/// 시스템 모달 터치바(게임 화면)를 관리한다. TouchBarLyrics와 같은 구조.
final class TouchBarController: NSObject, NSTouchBarDelegate {
    static let trayItemIdentifier = NSTouchBarItem.Identifier("com.rainy.touchbardino.tray")
    static let gameItemIdentifier = NSTouchBarItem.Identifier("com.rainy.touchbardino.game")
    static let closeItemIdentifier = NSTouchBarItem.Identifier("com.rainy.touchbardino.close")

    /// 게임 화면이 탭됐을 때 (시작/점프/재시작)
    var onTap: (() -> Void)?
    var onUserToggle: ((Bool) -> Void)?
    private(set) var isPresented = false

    private var lastTouchDown = Date.distantPast
    private lazy var gameButton: TouchDownButton = {
        let button = TouchDownButton(title: "", target: self, action: #selector(gameActionFired))
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleNone
        button.allowedTouchTypes = [.direct]
        button.onTouchDown = { [weak self] in
            self?.lastTouchDown = Date()
            self?.onTap?()
        }
        return button
    }()

    private var trayItem: NSCustomTouchBarItem?
    private var gameConstraintsInstalled = false
    private lazy var gameBar: NSTouchBar = {
        let bar = NSTouchBar()
        bar.delegate = self
        bar.defaultItemIdentifiers = [Self.closeItemIdentifier, Self.gameItemIdentifier]
        return bar
    }()

    func update(image: NSImage) {
        gameButton.image = image
    }

    func install() {
        let item = NSCustomTouchBarItem(identifier: Self.trayItemIdentifier)
        let image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "게임")
            ?? NSImage(named: NSImage.touchBarPlayTemplateName)!
        let button = NSButton(image: image, target: self, action: #selector(trayTapped))
        button.bezelStyle = .rounded
        item.view = button
        trayItem = item
        if TouchBarPrivateAPI.addSystemTrayItem(item) {
            TouchBarPrivateAPI.setControlStripPresence(
                identifier: Self.trayItemIdentifier.rawValue, visible: true)
            Log.info("control strip item installed")
        }
    }

    func present() {
        if TouchBarPrivateAPI.presentSystemModal(
            gameBar, systemTrayItemIdentifier: Self.trayItemIdentifier) {
            if !isPresented { Log.info("game bar presented") }
            isPresented = true
        }
    }

    private var lastEnsure = Date.distantPast
    private var lastLoggedVisibility: Bool?

    /// 터치바가 어떤 이유로든(다른 앱, 시스템) 내려가 있으면 다시 띄운다
    func ensureVisible(shouldShow: Bool) {
        let visible = gameBar.isVisible
        if visible != lastLoggedVisibility {
            Log.info("touch bar visibility -> \(visible)")
            lastLoggedVisibility = visible
        }
        guard shouldShow || isPresented else { return }
        guard !visible, Date().timeIntervalSince(lastEnsure) > 3 else { return }
        lastEnsure = Date()
        Log.info("touch bar not visible; re-presenting")
        present()
    }

    func minimize() {
        guard isPresented else { return }
        TouchBarPrivateAPI.minimizeSystemModal(gameBar)
        isPresented = false
        Log.info("game bar minimized")
    }

    func teardown() {
        TouchBarPrivateAPI.dismissSystemModal(gameBar)
        if let trayItem {
            TouchBarPrivateAPI.setControlStripPresence(
                identifier: Self.trayItemIdentifier.rawValue, visible: false)
            TouchBarPrivateAPI.removeSystemTrayItem(trayItem)
        }
        isPresented = false
    }

    @objc private func trayTapped() {
        if isPresented {
            minimize()
            onUserToggle?(false)
        } else {
            present()
            onUserToggle?(true)
        }
    }

    @objc private func closeTapped() {
        minimize()
        onUserToggle?(false)
    }

    /// touchesBegan이 안 잡히는 환경 대비 폴백.
    /// 같은 탭이 두 번 처리되지 않게 touch down 직후의 액션은 무시한다.
    @objc private func gameActionFired() {
        if Date().timeIntervalSince(lastTouchDown) > 0.3 { onTap?() }
    }

    // MARK: NSTouchBarDelegate

    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case Self.gameItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            item.visibilityPriority = .high // 공간이 부족해도 먼저 탈락되지 않게
            item.view = gameButton
            // 레이아웃이 0×0으로 접어버리지 않게 명시적 제약으로 크기 고정
            if !gameConstraintsInstalled {
                gameConstraintsInstalled = true
                gameButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    gameButton.widthAnchor.constraint(equalToConstant: GameRenderer.size.width),
                    gameButton.heightAnchor.constraint(equalToConstant: GameRenderer.size.height),
                ])
            }
            return item
        case Self.closeItemIdentifier:
            let item = NSCustomTouchBarItem(identifier: identifier)
            let image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: "닫기")
                ?? NSImage(named: NSImage.touchBarGoDownTemplateName)!
            item.view = NSButton(image: image, target: self, action: #selector(closeTapped))
            return item
        default:
            return nil
        }
    }
}
