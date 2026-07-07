import AVFoundation

/// 합성된 칩튠 효과음(점프·착지·사망)과 배경음악 루프 재생.
/// 소리 파일은 scripts/make_sounds.py 가 만들어 Resources/Sounds 에 둔다.
final class SoundPlayer {
    enum Effect: String, CaseIterable {
        case jump, land, die

        var volume: Float {
            switch self {
            case .jump: return 0.5
            case .land: return 0.4
            case .die: return 0.6
            }
        }
    }

    var sfxEnabled = true
    var bgmEnabled = true

    private var players: [Effect: AVAudioPlayer] = [:]
    private var bgm: AVAudioPlayer?

    init() {
        guard let dir = Self.locateSounds() else {
            Log.info("sounds directory not found; audio disabled")
            return
        }
        for effect in Effect.allCases {
            let url = dir.appendingPathComponent("\(effect.rawValue).wav")
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = effect.volume
                player.prepareToPlay()
                players[effect] = player
            }
        }
        let bgmURL = dir.appendingPathComponent("bgm.wav")
        if let player = try? AVAudioPlayer(contentsOf: bgmURL) {
            player.volume = 0.28
            player.numberOfLoops = -1
            player.prepareToPlay()
            bgm = player
        }
        Log.info("sounds loaded: \(players.count) sfx, bgm \(bgm != nil)")
    }

    func play(_ effect: Effect) {
        guard sfxEnabled, let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    /// 게임 진행 상태에 맞춰 배경음악을 켜고 끈다 (매 프레임 호출해도 안전)
    func setBGMActive(_ active: Bool) {
        guard let bgm else { return }
        if active, bgmEnabled {
            if !bgm.isPlaying { bgm.play() }
        } else {
            if bgm.isPlaying { bgm.pause() }
        }
    }

    private static func locateSounds() -> URL? {
        let fm = FileManager.default
        var candidates: [URL] = []
        if let res = Bundle.main.resourceURL {
            candidates.append(res.appendingPathComponent("Sounds"))
        }
        // 개발용: 소스 트리에서 직접 실행할 때
        candidates.append(
            URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent() // Sources
                .deletingLastPathComponent() // project root
                .appendingPathComponent("Resources/Sounds"))
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }
}
