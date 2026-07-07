import Foundation

/// 시스템 언어 설정에 따라 UI 문자열을 고른다.
/// 지원: 한국어, 영어, 일본어, 중국어(간체/번체), 러시아어 — 그 외에는 영어.
enum L10n {
    static let language: String = {
        for lang in Locale.preferredLanguages {
            if lang.hasPrefix("ko") { return "ko" }
            if lang.hasPrefix("ja") { return "ja" }
            if lang.hasPrefix("zh-Hant") || lang.hasPrefix("zh-TW") || lang.hasPrefix("zh-HK") { return "zh-Hant" }
            if lang.hasPrefix("zh") { return "zh-Hans" }
            if lang.hasPrefix("ru") { return "ru" }
            if lang.hasPrefix("en") { return "en" }
        }
        return "en"
    }()

    static func t(_ key: String) -> String {
        tables[language]?[key] ?? tables["en"]?[key] ?? key
    }

    static func f(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }

    private static let tables: [String: [String: String]] = [
        "ko": [
            "menu_hi": "최고 기록: %d",
            "menu_show": "터치바에 게임 표시",
            "menu_hide": "터치바에서 숨기기",
            "menu_window": "화면에 게임 창 표시 (마우스로 플레이)",
            "menu_sfx": "효과음",
            "menu_bgm": "배경음악",
            "menu_reset": "최고 기록 초기화",
            "menu_log": "로그 열기",
            "menu_quit": "종료",
            "ov_idle": "탭/클릭 = 시작 · 달리는 중 탭/클릭 = 점프",
            "ov_hint": "탭/클릭 = 점프",
            "ov_dead": "GAME OVER · 탭/클릭 = 재시작",
        ],
        "en": [
            "menu_hi": "High score: %d",
            "menu_show": "Show game on Touch Bar",
            "menu_hide": "Hide from Touch Bar",
            "menu_window": "Show on-screen game window (mouse play)",
            "menu_sfx": "Sound effects",
            "menu_bgm": "Background music",
            "menu_reset": "Reset high score",
            "menu_log": "Open Log",
            "menu_quit": "Quit",
            "ov_idle": "Tap/click = start · while running = jump",
            "ov_hint": "Tap/click = jump",
            "ov_dead": "GAME OVER · tap/click to restart",
        ],
        "ja": [
            "menu_hi": "ハイスコア: %d",
            "menu_show": "Touch Barにゲームを表示",
            "menu_hide": "Touch Barから隠す",
            "menu_window": "画面にゲームウィンドウを表示（マウスでプレイ）",
            "menu_sfx": "効果音",
            "menu_bgm": "BGM",
            "menu_reset": "ハイスコアをリセット",
            "menu_log": "ログを開く",
            "menu_quit": "終了",
            "ov_idle": "タップ/クリック = 開始 · プレイ中 = ジャンプ",
            "ov_hint": "タップ/クリック = ジャンプ",
            "ov_dead": "GAME OVER · タップ/クリックで再開",
        ],
        "zh-Hans": [
            "menu_hi": "最高分: %d",
            "menu_show": "在触控栏显示游戏",
            "menu_hide": "从触控栏隐藏",
            "menu_window": "显示屏幕游戏窗口（鼠标游玩）",
            "menu_sfx": "音效",
            "menu_bgm": "背景音乐",
            "menu_reset": "重置最高分",
            "menu_log": "打开日志",
            "menu_quit": "退出",
            "ov_idle": "点按/点击 = 开始 · 游戏中 = 跳跃",
            "ov_hint": "点按/点击 = 跳跃",
            "ov_dead": "GAME OVER · 点按/点击重新开始",
        ],
        "zh-Hant": [
            "menu_hi": "最高分: %d",
            "menu_show": "在觸控列顯示遊戲",
            "menu_hide": "從觸控列隱藏",
            "menu_window": "顯示螢幕遊戲視窗（滑鼠遊玩）",
            "menu_sfx": "音效",
            "menu_bgm": "背景音樂",
            "menu_reset": "重設最高分",
            "menu_log": "打開日誌",
            "menu_quit": "結束",
            "ov_idle": "點按/點擊 = 開始 · 遊戲中 = 跳躍",
            "ov_hint": "點按/點擊 = 跳躍",
            "ov_dead": "GAME OVER · 點按/點擊重新開始",
        ],
        "ru": [
            "menu_hi": "Рекорд: %d",
            "menu_show": "Показать игру на Touch Bar",
            "menu_hide": "Скрыть с Touch Bar",
            "menu_window": "Окно игры на экране (мышью)",
            "menu_sfx": "Звуковые эффекты",
            "menu_bgm": "Музыка",
            "menu_reset": "Сбросить рекорд",
            "menu_log": "Открыть журнал",
            "menu_quit": "Выйти",
            "ov_idle": "Тап/клик = старт · в игре = прыжок",
            "ov_hint": "Тап/клик = прыжок",
            "ov_dead": "GAME OVER · тап/клик — заново",
        ],
    ]
}
