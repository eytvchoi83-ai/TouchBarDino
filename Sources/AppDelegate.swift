import AppKit
import IOKit.pwr_mgt

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let touchBarController = TouchBarController()
    private let gameWindow = GameWindowController()
    private let engine = GameEngine()
    private let renderer = GameRenderer()
    private let sound = SoundPlayer()
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var lastActivityPing = Date.distantPast
    private var userHidden = false

    private var showWindow: Bool {
        get { UserDefaults.standard.object(forKey: "showGameWindow") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "showGameWindow") }
    }
    private var sfxEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "sfxEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "sfxEnabled") }
    }
    private var bgmEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "bgmEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "bgmEnabled") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.info("TouchBarDino started")
        setupStatusItem()
        touchBarController.install()
        touchBarController.onTap = { [weak self] in self?.engine.tap() }
        touchBarController.onUserToggle = { [weak self] shown in
            self?.userHidden = !shown
        }
        gameWindow.onTap = { [weak self] in self?.engine.tap() }
        if showWindow { gameWindow.show() }

        sound.sfxEnabled = sfxEnabled
        sound.bgmEnabled = bgmEnabled
        engine.onEvent = { [weak self] event in
            switch event {
            case .jump: self?.sound.play(.jump)
            case .land: self?.sound.play(.land)
            case .die: self?.sound.play(.die)
            case .start: break
            }
        }

        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        touchBarController.present()
    }

    func applicationWillTerminate(_ notification: Notification) {
        touchBarController.teardown()
        timer?.invalidate()
    }

    private func tick() {
        touchBarController.ensureVisible(shouldShow: !userHidden)
        // 터치바도 창도 안 보이면 게임(과 음악) 자동 일시정지
        guard touchBarController.isPresented || gameWindow.isVisible else {
            sound.setBGMActive(false)
            return
        }

        engine.step()
        sound.setBGMActive(engine.phase == .running)
        if engine.phase == .running { keepAwake() }
        if let image = renderer.render(engine: engine) {
            touchBarController.update(image: image)
            gameWindow.update(image: image)
        }
    }

    /// 플레이 중 터치바 유휴 소등·화면 잠자기를 막는다 (권한 불필요)
    private func keepAwake() {
        guard Date().timeIntervalSince(lastActivityPing) > 25 else { return }
        lastActivityPing = Date()
        var assertionID: IOPMAssertionID = 0
        IOPMAssertionDeclareUserActivity(
            "TouchBarDino keep awake" as CFString, kIOPMUserActiveLocal, &assertionID)
    }

    // MARK: - Status item & menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "터치바 공룡")
            if button.image == nil { button.title = "🦖" }
        }
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(disabledItem("최고 기록: \(engine.hiScore)"))
        menu.addItem(.separator())

        let showItem = NSMenuItem(
            title: touchBarController.isPresented ? "터치바에서 숨기기" : "터치바에 게임 표시",
            action: #selector(toggleTouchBar), keyEquivalent: "g")
        showItem.target = self
        menu.addItem(showItem)

        let windowItem = NSMenuItem(
            title: "화면에 게임 창 표시 (마우스로 플레이)",
            action: #selector(toggleWindow), keyEquivalent: "m")
        windowItem.target = self
        windowItem.state = gameWindow.isVisible ? .on : .off
        menu.addItem(windowItem)

        let sfxItem = NSMenuItem(title: "효과음", action: #selector(toggleSfx), keyEquivalent: "")
        sfxItem.target = self
        sfxItem.state = sfxEnabled ? .on : .off
        menu.addItem(sfxItem)

        let bgmItem = NSMenuItem(title: "배경음악", action: #selector(toggleBgm), keyEquivalent: "")
        bgmItem.target = self
        bgmItem.state = bgmEnabled ? .on : .off
        menu.addItem(bgmItem)

        let resetItem = NSMenuItem(title: "최고 기록 초기화", action: #selector(resetHiScore), keyEquivalent: "")
        resetItem.target = self
        resetItem.isEnabled = engine.hiScore > 0
        menu.addItem(resetItem)
        menu.addItem(.separator())

        let log = NSMenuItem(title: "로그 열기", action: #selector(openLog), keyEquivalent: "")
        log.target = self
        menu.addItem(log)
        menu.addItem(NSMenuItem(
            title: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    @objc private func toggleTouchBar() {
        if touchBarController.isPresented {
            touchBarController.minimize()
            userHidden = true
        } else {
            touchBarController.present()
            userHidden = false
        }
    }

    @objc private func toggleWindow() {
        if gameWindow.isVisible {
            gameWindow.hide()
            showWindow = false
        } else {
            gameWindow.show()
            showWindow = true
        }
    }

    @objc private func toggleSfx() {
        sfxEnabled.toggle()
        sound.sfxEnabled = sfxEnabled
    }

    @objc private func toggleBgm() {
        bgmEnabled.toggle()
        sound.bgmEnabled = bgmEnabled
        if !bgmEnabled { sound.setBGMActive(false) }
    }

    @objc private func resetHiScore() {
        engine.resetHiScore()
    }

    @objc private func openLog() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/TouchBarDino.log")
        NSWorkspace.shared.open(url)
    }
}
