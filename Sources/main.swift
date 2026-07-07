import AppKit

// 렌더링 확인용: TouchBarDino --render-frames <출력 폴더>
// 터치바 없이 대기/플레이/게임오버 화면을 PNG로 저장한다.
if let idx = CommandLine.arguments.firstIndex(of: "--render-frames"),
   CommandLine.arguments.count > idx + 1 {
    let dir = URL(fileURLWithPath: CommandLine.arguments[idx + 1])
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let engine = GameEngine()
    let renderer = GameRenderer()

    func save(_ name: String) {
        guard let image = renderer.render(engine: engine),
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else { print("render failed: \(name)"); return }
        try? png.write(to: dir.appendingPathComponent(name))
        print("saved \(name)")
    }

    save("1-idle.png")
    engine.tap()
    for _ in 0..<160 { engine.step() } // 장애물이 화면에 들어올 때까지 진행
    save("2-running.png")
    engine.tap()
    for _ in 0..<8 { engine.step() } // 점프 상승 중
    save("3-jumping.png")
    while engine.phase == .running { engine.step() } // 충돌할 때까지 방치
    save("4-gameover.png")
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)

// pkill 등 SIGTERM으로 죽어도 터치바 아이템을 정리하고 나가도록
signal(SIGTERM, SIG_IGN)
let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigtermSource.setEventHandler { NSApp.terminate(nil) }
sigtermSource.resume()

app.run()
