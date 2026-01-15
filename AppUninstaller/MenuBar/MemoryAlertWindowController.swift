import SwiftUI
import AppKit

/// 独立的内存警告浮动窗口控制器
/// 当检测到高内存使用时自动从菜单栏图标弹出
class MemoryAlertWindowController: NSObject, ObservableObject {
    private var window: NSWindow?
    private var systemMonitor: SystemMonitorService
    private var statusBarButton: NSStatusBarButton?
    
    init(systemMonitor: SystemMonitorService, statusBarButton: NSStatusBarButton?) {
        self.systemMonitor = systemMonitor
        self.statusBarButton = statusBarButton
        super.init()
        setupObserver()
    }
    
    private func setupObserver() {
        // 监听内存警告状态变化
        systemMonitor.$showHighMemoryAlert
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                if shouldShow {
                    self?.showAlert()
                } else {
                    self?.hideAlert()
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 显示内存警告窗口
    private func showAlert() {
        // 如果窗口已存在，重新定位并显示
        if let existingWindow = window {
            positionWindow(existingWindow)
            existingWindow.orderFrontRegardless()
            return
        }
        
        // 每次显示前都重新获取按钮引用（确保最新）
        statusBarButton = MenuBarManager.shared.statusItem?.button
        print("[MemoryAlert] 获取菜单栏按钮: \(statusBarButton != nil ? "成功" : "失败")")
        
        // 创建警告视图
        let alertView = MemoryAlertFloatingView(
            systemMonitor: systemMonitor,
            onClose: { [weak self] in
                self?.hideAlert()
            },
            onOpenApp: { [weak self] in
                self?.hideAlert()
                MenuBarManager.shared.openMainApp()
            }
        )
        
        let hostingController = NSHostingController(rootView: alertView)
        
        // 创建浮动窗口（调整尺寸更紧凑）
        let alertWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        alertWindow.contentViewController = hostingController
        alertWindow.backgroundColor = .clear
        alertWindow.isOpaque = false
        alertWindow.hasShadow = true
        alertWindow.level = .floating  // 保持在其他窗口之上
        alertWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
        alertWindow.isMovableByWindowBackground = false
        
        // 重要：设置为非激活窗口，避免 canBecomeKeyWindow 警告
        alertWindow.hidesOnDeactivate = false
        alertWindow.ignoresMouseEvents = false
        
        // 定位在菜单栏图标下方
        positionWindow(alertWindow)
        
        // 动画显示（不成为 key window，避免警告）
        alertWindow.alphaValue = 0
        alertWindow.orderFrontRegardless()  // 使用 orderFrontRegardless 替代 makeKeyAndOrderFront
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            alertWindow.animator().alphaValue = 1
        }
        
        self.window = alertWindow
    }
    
    /// 隐藏警告窗口
    private func hideAlert() {
        guard let window = window else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.window = nil
        })
    }
    
    /// 计算窗口位置（菜单栏图标正下方）
    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let fullScreenFrame = screen.frame  // 包含菜单栏的完整屏幕
        
        // 使用固定的窗口尺寸（与创建时一致），避免 SwiftUI 布局延迟导致的 size=0 问题
        let windowSize = CGSize(width: 320, height: 280)
        let menuBarHeight: CGFloat = 24  // macOS 菜单栏高度
        
        print("[MemoryAlert] 屏幕信息 - visible: \(screenFrame), full: \(fullScreenFrame)")
        print("[MemoryAlert] 窗口尺寸 - frame.size: \(window.frame.size), fixed: \(windowSize)")
        
        // 尝试获取菜单栏按钮
        if let button = statusBarButton ?? MenuBarManager.shared.statusItem?.button {
            var buttonScreenX: CGFloat?
            
            // 方法1: 通过 button.window 转换坐标
            if let buttonWindow = button.window {
                let buttonFrameInWindow = button.frame
                let buttonFrameScreen = buttonWindow.convertToScreen(buttonFrameInWindow)
                print("[MemoryAlert] 方法1原始数据: window frame=\(buttonFrameInWindow), screen frame=\(buttonFrameScreen)")
                
                // 检查坐标是否合理（菜单栏图标应该在屏幕上半部分）
                if buttonFrameScreen.minY > screenFrame.midY || buttonFrameScreen.minX < 10 {
                    print("[MemoryAlert] ⚠️ 方法1坐标异常，x=\(buttonFrameScreen.minX), y=\(buttonFrameScreen.minY)")
                    // 坐标不合理，尝试其他方法
                } else {
                    buttonScreenX = buttonFrameScreen.midX
                    print("[MemoryAlert] ✅ 方法1成功: buttonScreenX=\(buttonScreenX!)")
                }
            }
            
            // 方法2: 如果方法1失败，使用鼠标位置推算（当用户点击图标时）
            if buttonScreenX == nil {
                let mouseLocation = NSEvent.mouseLocation
                print("[MemoryAlert] 方法2: 尝试使用鼠标位置=\(mouseLocation)")
                
                // 如果鼠标在屏幕顶部菜单栏区域，说明可能刚点击了图标
                if mouseLocation.y > fullScreenFrame.maxY - menuBarHeight - 5 {
                    buttonScreenX = mouseLocation.x
                    print("[MemoryAlert] ✅ 方法2成功: 使用鼠标位置 x=\(buttonScreenX!)")
                }
            }
            
            // 方法3: 使用 StatusItem 的长度信息推算位置
            if buttonScreenX == nil {
                // 菜单栏图标通常从右向左排列
                // 我们假设图标在右上角区域
                if MenuBarManager.shared.statusItem != nil {
                    // 从右边缘开始估算（假设是第一个或第二个图标）
                    let estimatedX = fullScreenFrame.maxX - 50  // 右边缘 -50px 作为估算
                    buttonScreenX = estimatedX
                    print("[MemoryAlert] 方法3: 使用估算位置 x=\(buttonScreenX!)")
                }
            }
            
            // 如果获取到了 X 坐标，计算窗口位置
            if let buttonX = buttonScreenX {
                let xPos = buttonX - (windowSize.width / 2)
                
                // Y 坐标：在可见区域顶部向下偏移
                // screenFrame.maxY 是可见区域的顶部（菜单栏下方）
                let yPos = screenFrame.maxY - windowSize.height - 8
                
                // 确保不超出屏幕边界
                let finalX = max(screenFrame.minX + 10, min(xPos, screenFrame.maxX - windowSize.width - 10))
                let finalY = max(screenFrame.minY + 10, min(yPos, screenFrame.maxY - windowSize.height - 8))
                
                // 同时设置窗口大小和位置，确保窗口尺寸正确
                window.setFrame(NSRect(x: finalX, y: finalY, width: windowSize.width, height: windowSize.height), display: true)
                print("[MemoryAlert] ✅ 窗口定位成功: x=\(finalX), y=\(finalY), buttonX=\(buttonX)")
                print("[MemoryAlert] 坐标详情: screenFrame.maxY=\(screenFrame.maxY), windowHeight=\(windowSize.height), actualHeight=\(window.frame.height)")
                return
            }
        }
        
        // 方法4: 终极后备方案 - 使用屏幕右上角
        print("[MemoryAlert] ⚠️ 使用终极后备方案")
        let xPos = screenFrame.maxX - windowSize.width - 20
        // 使用可见区域的顶部，确保在菜单栏下方
        let yPos = screenFrame.maxY - windowSize.height - 8
        
        // 同时设置窗口大小和位置
        window.setFrame(NSRect(x: xPos, y: yPos, width: windowSize.width, height: windowSize.height), display: true)
        print("[MemoryAlert] 使用后备位置: x=\(xPos), y=\(yPos), screenFrame.maxY=\(screenFrame.maxY), windowHeight=\(windowSize.height)")
    }
}

// MARK: - 浮动警告视图（参考 CleanMyMac 设计）
struct MemoryAlertFloatingView: View {
    @ObservedObject var systemMonitor: SystemMonitorService
    let onClose: () -> Void
    let onOpenApp: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 指示三角形（指向菜单栏图标）
            Triangle()
                .fill(Color(hex: "F2F2F7"))
                .frame(width: 20, height: 10)
                .padding(.bottom, -1)
            
            // 主内容区域
            VStack(alignment: .leading, spacing: 16) {
                // 标题
                VStack(alignment: .leading, spacing: 8) {
                    Text("内存占用过高")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.85))
                    
                    Text("Mac优化大师 发现您 Mac 的物理内存和虚拟内存占用率过高。让我们为您修复此问题！")
                        .font(.system(size: 13))
                        .foregroundColor(Color.black.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                
                // 启动应用按钮
                Button(action: onOpenApp) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14))
                        Text("启动 Mac优化大师")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color.black)
                }
                .buttonStyle(.plain)
                
                // 内存可视化卡片
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "FFFFFF"))
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    HStack(spacing: 12) {
                        // RAM 图标
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "00C7BE"))
                                .frame(width: 40, height: 40)
                            
                            Text("RAM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: -5)
                            
                            // Mock "pins" or chip look
                            VStack(spacing: 2) {
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(0..<5) { _ in
                                        Rectangle()
                                            .fill(Color.white.opacity(0.5))
                                            .frame(width: 2, height: 6)
                                    }
                                }
                                .padding(.bottom, 4)
                            }
                            .frame(width: 40, height: 40)
                        }
                        
                        // Progress
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("RAM + Swap")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.black.opacity(0.85))
                                Spacer()
                                Text(systemMonitor.memoryUsage > 0.9 ? "快满了" : "正常")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "FF6B6B"))
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color(hex: "FF9F6B"), Color(hex: "FF6B6B")]), startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geometry.size.width * CGFloat(systemMonitor.memoryUsage), height: 8)
                                        .animation(.easeInOut, value: systemMonitor.memoryUsage)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .padding(12)
                }
                .frame(height: 72)
                .background(Color(hex: "F2F2F7"))
                
                Divider()
                    .background(Color.gray.opacity(0.2))
                
                // 底部操作按钮
                HStack {
                    // 忽略菜单
                    Menu {
                        Button("10 分钟后提醒") {
                            systemMonitor.snoozeAlert(minutes: 10)
                            onClose()
                        }
                        Button("1 小时后提醒") {
                            systemMonitor.snoozeAlert(minutes: 60)
                            onClose()
                        }
                        Divider()
                        Button("从不提醒") {
                            systemMonitor.ignoreAppPermanently()
                            onClose()
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("忽略")
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    Spacer()
                    
                    // 释放按钮
                    Button(action: {
                        systemMonitor.terminateHighMemoryApp()
                        onClose()
                    }) {
                        Text("释放")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.8))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(Color(hex: "F2F2F7"))
            .cornerRadius(16)
        }
        .frame(width: 320)
        .compositingGroup()
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

import Combine
