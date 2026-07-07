import AppKit

/// 앱이 포커스되지 않아도 터치바에 항상 표시하기 위한 비공개 API 래퍼.
/// (Pock 등에서 쓰는 것과 같은 방식: DFRFoundation + NSTouchBar 비공개 셀렉터)
enum TouchBarPrivateAPI {
    private static let dfrHandle: UnsafeMutableRawPointer? = dlopen(
        "/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY)

    /// 컨트롤 스트립(터치바 오른쪽 고정 영역)에 아이템 표시 여부 설정
    static func setControlStripPresence(identifier: String, visible: Bool) {
        guard let handle = dfrHandle,
              let sym = dlsym(handle, "DFRElementSetControlStripPresenceForIdentifier")
        else {
            Log.info("DFRElementSetControlStripPresenceForIdentifier not available")
            return
        }
        typealias Fn = @convention(c) (CFString, Bool) -> Void
        unsafeBitCast(sym, to: Fn.self)(identifier as CFString, visible)
    }

    static func addSystemTrayItem(_ item: NSTouchBarItem) -> Bool {
        let sel = NSSelectorFromString("addSystemTrayItem:")
        let cls: AnyObject = NSTouchBarItem.self
        guard cls.responds(to: sel) else {
            Log.info("NSTouchBarItem.addSystemTrayItem: not available")
            return false
        }
        _ = cls.perform(sel, with: item)
        return true
    }

    static func removeSystemTrayItem(_ item: NSTouchBarItem) {
        let sel = NSSelectorFromString("removeSystemTrayItem:")
        let cls: AnyObject = NSTouchBarItem.self
        guard cls.responds(to: sel) else { return }
        _ = cls.perform(sel, with: item)
    }

    static func presentSystemModal(_ touchBar: NSTouchBar, systemTrayItemIdentifier: NSTouchBarItem.Identifier) -> Bool {
        let cls: AnyObject = NSTouchBar.self
        let newSel = NSSelectorFromString("presentSystemModalTouchBar:systemTrayItemIdentifier:")
        if cls.responds(to: newSel) {
            _ = cls.perform(newSel, with: touchBar, with: systemTrayItemIdentifier.rawValue)
            return true
        }
        let oldSel = NSSelectorFromString("presentSystemModalFunctionBar:systemTrayItemIdentifier:")
        if cls.responds(to: oldSel) {
            _ = cls.perform(oldSel, with: touchBar, with: systemTrayItemIdentifier.rawValue)
            return true
        }
        Log.info("presentSystemModalTouchBar not available")
        return false
    }

    static func minimizeSystemModal(_ touchBar: NSTouchBar) {
        let cls: AnyObject = NSTouchBar.self
        for name in ["minimizeSystemModalTouchBar:", "minimizeSystemModalFunctionBar:"] {
            let sel = NSSelectorFromString(name)
            if cls.responds(to: sel) {
                _ = cls.perform(sel, with: touchBar)
                return
            }
        }
    }

    static func dismissSystemModal(_ touchBar: NSTouchBar) {
        let cls: AnyObject = NSTouchBar.self
        for name in ["dismissSystemModalTouchBar:", "dismissSystemModalFunctionBar:"] {
            let sel = NSSelectorFromString(name)
            if cls.responds(to: sel) {
                _ = cls.perform(sel, with: touchBar)
                return
            }
        }
    }
}
