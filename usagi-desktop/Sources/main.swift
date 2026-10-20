import AppKit

enum PetStyle: Int, CaseIterable {
    case video = 0, cheerleader = 1, rakko = 2
    var title: String {
        switch self {
        case .video: return "우사기춤"
        case .cheerleader: return "치어리더 우사기"
        case .rakko: return "모찌 먹는 랏코"
        }
    }
}

final class PetView: NSView {
    var style = PetStyle(rawValue: UserDefaults.standard.integer(forKey: "petStyle")) ?? .video
    var dancing = true
    var speed = 1.0
    var playbackTime = 0.0
    var held = false
    var downPoint = NSPoint.zero
    var downOrigin = NSPoint.zero
    var dragged = false
    var onMenu: (() -> Void)?
    override var acceptsFirstResponder: Bool { true }

    private let cheerImage = PetView.loadImage("usagi-dance")
    private let idleImage = PetView.loadImage("usagi-idle")
    private static func loadImage(_ name: String) -> NSImage {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            fatalError("Missing character image: \(name)")
        }
        return image
    }

    private let danceFrames = PetView.loadFrames("DanceFrames", count: 24)
    private let rakkoFrames = PetView.loadFrames("RakkoFrames", count: 48)
    private static func loadFrames(_ directory: String, count: Int) -> [NSImage] {
        (0..<count).map { index in
        let name = String(format: "frame-%03d", index)
        guard let url = Bundle.main.url(forResource: name, withExtension: "png",
                                        subdirectory: directory),
              let image = NSImage(contentsOf: url),
              let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else {
            fatalError("Missing or invalid dance frame: \(name).png")
        }
        // Decode once, rather than repeatedly reading PNG data during playback.
        let decoded = NSImage(size: image.size)
        decoded.addRepresentation(bitmap)
        return decoded
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current?.imageInterpolation = .high
        let scale = bounds.width / 240
        (AffineTransform(scaleByX: scale, byY: scale) as NSAffineTransform).concat()
        if style == .cheerleader {
            let beat = playbackTime * 7
            let sway = dancing ? sin(beat) : 0
            let bounce = dancing ? abs(cos(beat)) * 13 : 0
            (AffineTransform(translationByX: 120 + sway * 8,
                             byY: 128 + bounce + (held ? 12 : 0)) as NSAffineTransform).concat()
            var rotation = AffineTransform()
            rotation.rotate(byDegrees: held ? -12 : sway * 10)
            (rotation as NSAffineTransform).concat()
            let squash = dancing ? sin(beat * 2) * 0.035 : 0
            (AffineTransform(scaleByX: 1 + squash, byY: 1 - squash) as NSAffineTransform).concat()
            (dancing ? cheerImage : idleImage).draw(
                in: NSRect(x: -106, y: -106, width: 212, height: 212),
                from: .zero, operation: .sourceOver, fraction: 1)
            return
        }
        (AffineTransform(translationByX: 120,
                         byY: 132 + (held ? 12 : 0)) as NSAffineTransform).concat()
        var rotation = AffineTransform()
        rotation.rotate(byDegrees: held ? -12 : 0)
        (rotation as NSAffineTransform).concat()
        let frames = style == .rakko ? rakkoFrames : danceFrames
        let frame = Int(playbackTime * 30) % frames.count
        let rect = style == .rakko
            ? NSRect(x: -95, y: -116, width: 190, height: 232)
            : NSRect(x: -105, y: -114.5, width: 210, height: 229)
        frames[frame].draw(in: rect,
                   from: .zero, operation: .sourceOver, fraction: 1)
    }
    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { onMenu?(); return }
        downPoint = NSEvent.mouseLocation
        downOrigin = window?.frame.origin ?? .zero
        dragged = false
    }
    override func mouseDragged(with event: NSEvent) {
        let point = NSEvent.mouseLocation
        let dx = point.x - downPoint.x, dy = point.y - downPoint.y
        guard dragged || hypot(dx, dy) > 4 else { return }
        dragged = true; held = true
        window?.setFrameOrigin(NSPoint(x: downOrigin.x + dx, y: downOrigin.y + dy))
    }
    override func mouseUp(with event: NSEvent) {
        held = false
        if !dragged { dancing.toggle() }
        if let window = window {
            let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
            if let screen = screen {
                let frame = screen.visibleFrame
                window.setFrameOrigin(NSPoint(
                    x: min(max(window.frame.minX, frame.minX), frame.maxX - window.frame.width),
                    y: min(max(window.frame.minY, frame.minY), frame.maxY - window.frame.height)))
            }
            UserDefaults.standard.set(window.frame.origin.x, forKey: "petX")
            UserDefaults.standard.set(window.frame.origin.y, forKey: "petY")
        }
    }
    override func rightMouseDown(with event: NSEvent) { onMenu?() }
}

final class PetApp: NSObject, NSApplicationDelegate {
    var window: NSPanel!
    var pet: PetView!
    var status: NSStatusItem!
    var timer: Timer?
    var previousTick = ProcessInfo.processInfo.systemUptime
    var followsMouse = UserDefaults.standard.bool(forKey: "followsMouse")
    var menuIsOpen = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let side = CGFloat(UserDefaults.standard.double(forKey: "petSize"))
        let width: CGFloat = side > 0 ? side : 210
        window = NSPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: width * 1.16),
                         styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.backgroundColor = .clear; window.isOpaque = false; window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false; window.isReleasedWhenClosed = false
        pet = PetView(frame: NSRect(origin: .zero, size: window.frame.size))
        pet.autoresizingMask = [.width, .height]
        pet.toolTip = "클릭: 움직임 정지·재개 / 드래그: 이동 / 우클릭: 메뉴"
        pet.setAccessibilityLabel(pet.style.title)
        pet.onMenu = { [weak self] in self?.showMenu() }
        window.contentView = pet
        resetPosition(nil)
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "petX") != nil {
            let saved = NSRect(x: defaults.double(forKey: "petX"), y: defaults.double(forKey: "petY"),
                               width: width, height: width * 1.16)
            if NSScreen.screens.contains(where: { $0.visibleFrame.contains(saved) }) {
                window.setFrameOrigin(saved.origin)
            }
        }
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        status.button?.title = "🐰"
        status.button?.toolTip = "Usagi Desktop"
        status.button?.target = self; status.button?.action = #selector(showMenu)
        window.orderFrontRegardless()
        timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let now = ProcessInfo.processInfo.systemUptime
            let elapsed = min(now - self.previousTick, 0.1)
            self.previousTick = now
            if self.window.isVisible && self.pet.dancing && !self.pet.held {
                self.pet.playbackTime += elapsed * self.pet.speed
            }
            if self.window.isVisible {
                self.followMouse(elapsed: elapsed)
                self.pet.needsDisplay = true
                // Empty margins pass clicks through to the app behind the pet.
                let mouse = self.window.convertPoint(fromScreen: NSEvent.mouseLocation)
                let scale = self.pet.bounds.width / 240
                let region = NSRect(x: 43 * scale, y: 24 * scale, width: 154 * scale, height: 243 * scale)
                self.window.ignoresMouseEvents = !self.pet.held && !region.contains(mouse)
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(screenChanged), name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    func followMouse(elapsed: TimeInterval) {
        guard followsMouse, !menuIsOpen, !pet.held,
              NSEvent.pressedMouseButtons == 0 else { return }
        let cursor = NSEvent.mouseLocation
        // Let the user catch, click or right-click the pet without it fleeing.
        guard !window.frame.contains(cursor),
              let screen = NSScreen.screens.first(where: { $0.frame.contains(cursor) }) else { return }
        let area = screen.visibleFrame
        let size = window.frame.size
        let gap: CGFloat = 24
        var x = cursor.x + gap
        if x + size.width > area.maxX { x = cursor.x - gap - size.width }
        let y = cursor.y - size.height * 0.65
        let target = NSPoint(
            x: max(area.minX, min(x, area.maxX - size.width)),
            y: max(area.minY, min(y, area.maxY - size.height)))
        let origin = window.frame.origin
        let dx = target.x - origin.x, dy = target.y - origin.y
        // Frame-rate independent easing; snap the final fraction of a point.
        let blend = 1 - exp(-5 * elapsed)
        let next = hypot(dx, dy) < 0.5 ? target :
            NSPoint(x: origin.x + dx * blend, y: origin.y + dy * blend)
        window.setFrameOrigin(next)
    }
    func savePosition() {
        UserDefaults.standard.set(window.frame.origin.x, forKey: "petX")
        UserDefaults.standard.set(window.frame.origin.y, forKey: "petY")
    }
    func item(_ title: String, _ action: Selector, tag: Int = 0) -> NSMenuItem {
        let result = NSMenuItem(title: title, action: action, keyEquivalent: "")
        result.target = self; result.tag = tag; return result
    }
    @objc func showMenu() {
        menuIsOpen = true
        defer { menuIsOpen = false }
        let menu = NSMenu()
        let heading = NSMenuItem(title: "USAGI · 작은 춤 친구", action: nil, keyEquivalent: "")
        menu.addItem(heading); menu.addItem(.separator())
        let characters = NSMenu()
        for style in PetStyle.allCases {
            let entry = item(style.title, #selector(selectStyle(_:)), tag: style.rawValue)
            entry.state = pet.style == style ? .on : .off
            characters.addItem(entry)
        }
        let characterItem = NSMenuItem(title: "캐릭터 선택", action: nil, keyEquivalent: "")
        characterItem.submenu = characters
        menu.addItem(characterItem)
        menu.addItem(item(pet.dancing ? "움직임 멈추기" : "움직임 재개", #selector(toggleDance)))
        let followItem = item("마우스 따라가기", #selector(toggleFollowMouse))
        followItem.state = followsMouse ? .on : .off
        menu.addItem(followItem)
        menu.addItem(item(window.isVisible ? "잠깐 숨기기" : "우사기 불러오기", #selector(toggleVisible)))
        let sizes = NSMenu()
        for (name, value) in [("작게", 150), ("보통", 210), ("크게", 290)] {
            let entry = item(name, #selector(resizePet(_:)), tag: value)
            entry.state = Int(window.frame.width) == value ? .on : .off
            sizes.addItem(entry)
        }
        let sizeItem = NSMenuItem(title: "크기", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizes; menu.addItem(sizeItem)
        let speeds = NSMenu()
        for (name, value) in [("느긋하게", 65), ("신나게", 100), ("아주 신나게", 145)] {
            let entry = item(name, #selector(changeSpeed(_:)), tag: value)
            entry.state = Int((pet.speed * 100).rounded()) == value ? .on : .off
            speeds.addItem(entry)
        }
        let speedItem = NSMenuItem(title: "재생 속도", action: nil, keyEquivalent: "")
        speedItem.submenu = speeds; menu.addItem(speedItem)
        menu.addItem(item("화면 구석으로 데려오기", #selector(resetPosition(_:))))
        menu.addItem(.separator())
        menu.addItem(item("종료", #selector(quit)))
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
    @objc func toggleDance() { pet.dancing.toggle() }
    @objc func selectStyle(_ sender: NSMenuItem) {
        guard let style = PetStyle(rawValue: sender.tag) else { return }
        pet.style = style
        pet.setAccessibilityLabel(style.title)
        pet.playbackTime = 0
        pet.needsDisplay = true
        UserDefaults.standard.set(style.rawValue, forKey: "petStyle")
    }
    @objc func toggleFollowMouse() {
        followsMouse.toggle()
        UserDefaults.standard.set(followsMouse, forKey: "followsMouse")
        if !followsMouse { savePosition() }
    }
    @objc func toggleVisible() {
        if window.isVisible { window.orderOut(nil) } else { window.orderFrontRegardless() }
    }
    @objc func resizePet(_ sender: NSMenuItem) {
        let width = CGFloat(sender.tag)
        window.setContentSize(NSSize(width: width, height: width * 1.16))
        UserDefaults.standard.set(width, forKey: "petSize")
        screenChanged()
    }
    @objc func changeSpeed(_ sender: NSMenuItem) { pet.speed = Double(sender.tag) / 100 }
    @objc func resetPosition(_ sender: Any?) {
        if sender != nil {
            followsMouse = false
            UserDefaults.standard.set(false, forKey: "followsMouse")
        }
        guard let screen = NSScreen.main else { return }
        window.setFrameOrigin(NSPoint(x: screen.visibleFrame.maxX - window.frame.width - 28,
                                      y: screen.visibleFrame.minY + 20))
        if sender != nil { savePosition() }
    }
    @objc func screenChanged() {
        if !NSScreen.screens.contains(where: { $0.visibleFrame.contains(window.frame) }) { resetPosition(nil) }
    }
    @objc func quit() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) { savePosition() }
}

let app = NSApplication.shared
if CommandLine.arguments.contains("--preview") {
    let view = PetView(frame: NSRect(x: 0, y: 0, width: 480, height: 557))
    view.style = CommandLine.arguments.contains("--cheerleader") ? .cheerleader : .video
    if CommandLine.arguments.contains("--rakko") { view.style = .rakko }
    view.playbackTime = 0.6
    let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds, to: bitmap)
    let output = CommandLine.arguments.last!
    try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
} else {
    app.setActivationPolicy(.accessory)
    let delegate = PetApp()
    app.delegate = delegate
    app.run()
}
