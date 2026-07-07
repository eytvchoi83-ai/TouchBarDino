import Foundation

/// 러너 게임의 상태와 물리. 좌표 단위는 터치바 포인트(pt), 시간은 프레임(60fps).
final class GameEngine {
    enum Phase { case idle, running, dead }

    struct Obstacle {
        var x: CGFloat
        let w: CGFloat
        let h: CGFloat
    }

    // 420×30pt 스트립 기준 상수 (420 초과 아이템은 터치바가 조용히 탈락시킴 — TouchBarLyrics README 참고)
    static let width: CGFloat = 420
    static let groundY: CGFloat = 4
    static let playerX: CGFloat = 30
    static let playerW: CGFloat = 17 // 충돌 판정 폭 (꼬리 제외)

    private let jumpVelocity: CGFloat = 2.4
    private let gravity: CGFloat = 0.21 // 낮을수록 체공이 길다
    private let baseSpeed: CGFloat = 2.3
    private let maxSpeed: CGFloat = 4.2

    private(set) var phase: Phase = .idle
    private(set) var jumpOffset: CGFloat = 0 // 지면에서 뜬 높이
    private(set) var obstacles: [Obstacle] = []
    private(set) var score: Double = 0
    private(set) var frame = 0 // 다리 애니메이션용
    private(set) var distance: CGFloat = 0 // 지면 점선 스크롤용

    var hiScore: Int {
        get { UserDefaults.standard.integer(forKey: "hiScore") }
        set { UserDefaults.standard.set(newValue, forKey: "hiScore") }
    }

    private var velocity: CGFloat = 0
    private var speed: CGFloat = 2.6
    private var spawnIn = 60
    private var diedAt = Date.distantPast

    /// 터치바 탭 한 번이 문맥에 따라 시작/점프/재시작이 된다
    func tap() {
        switch phase {
        case .idle:
            start()
        case .running:
            if jumpOffset <= 0 { velocity = jumpVelocity }
        case .dead:
            // 죽는 순간 연타하던 탭이 곧바로 재시작으로 새지 않게 잠깐 잠금
            if Date().timeIntervalSince(diedAt) > 0.35 { start() }
        }
    }

    func resetHiScore() {
        hiScore = 0
    }

    private func start() {
        obstacles = []
        score = 0
        speed = baseSpeed
        jumpOffset = 0
        velocity = 0
        spawnIn = 70
        phase = .running
        Log.info("game started")
    }

    /// 1프레임 진행 (60fps 기준). running이 아닐 때는 아무것도 하지 않는다.
    func step() {
        guard phase == .running else { return }
        frame += 1

        if jumpOffset > 0 || velocity > 0 {
            velocity -= gravity
            jumpOffset = max(0, jumpOffset + velocity)
            if jumpOffset == 0 { velocity = 0 }
        }

        speed = min(maxSpeed, speed + 0.0009)
        score += 0.15
        distance += speed

        spawnIn -= 1
        if spawnIn <= 0 { spawn() }

        for i in obstacles.indices { obstacles[i].x -= speed }
        obstacles.removeAll { $0.x < -20 }

        // 발 높이가 장애물보다 낮은 동안 x 구간이 겹치면 사망 (±1~2pt는 판정 관용)
        let left = Self.playerX + 2
        let right = Self.playerX + Self.playerW - 2
        for o in obstacles where right > o.x + 1 && left < o.x + o.w - 1 && jumpOffset < o.h - 1.5 {
            phase = .dead
            diedAt = Date()
            hiScore = max(hiScore, Int(score))
            Log.info("game over: score \(Int(score)) hi \(hiScore)")
            break
        }
    }

    private func spawn() {
        let w = CGFloat.random(in: 4.5...6.5)
        obstacles.append(Obstacle(x: Self.width + 10, w: w, h: .random(in: 5.5...8)))
        // 25% 확률로 두 그루 붙은 군집
        if Bool.random(), Bool.random() {
            obstacles.append(Obstacle(
                x: Self.width + 10 + w + 3,
                w: .random(in: 4.5...6.5), h: .random(in: 5...7)))
        }
        // 속도가 붙을수록 간격이 좁아지되, 점프 체공시간보다는 항상 길게
        spawnIn = max(44, Int(CGFloat.random(in: 70...135) - speed * 6))
    }
}
