import SwiftUI
import AppKit

struct SpaceLensView: View {
    @StateObject private var scanner = SpaceLensScanner()
    @State private var viewState: Int = 0 // 0: Landing, 1: Scanning, 2: Results
    
    // UI State
    @State private var navigationStack: [FileNode] = []
    @State private var currentNode: FileNode?
    @State private var bubblePositions: [UUID: CGPoint] = [:]
    @State private var bubbleSizes: [UUID: CGFloat] = [:]
    
    // Selection for landing page
    @State private var selectedDiskPath: URL = URL(fileURLWithPath: "/")
    @State private var selectedDiskName: String = "mac"
    @ObservedObject private var loc = LocalizationManager.shared
    
    var body: some View {
        Group {
            if viewState == 0 {
                landingView
            } else if viewState == 1 {
                scanningView
            } else {
                resultsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundStyles.spaceLens) // Use the Teal-Blue gradient
    }
    
    // MARK: - Landing View
    var landingView: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                // Left Column: Text & Features
                VStack(alignment: .leading, spacing: 40) {
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(loc.currentLanguage == .chinese ? "空间透镜" : "Space Lens")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(loc.currentLanguage == .chinese ? "对文件夹和文件进行视觉大小比较，方便快速清理。" : "Visually compare folders and files for quick cleanup.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 30) {
                        featureRow(icon: "circle.hexagongrid", title: "即时尺寸概览", desc: "浏览存储空间，同时查看什么内容占据最多空间。")
                        featureRow(icon: "airplane", title: "快速决策", desc: "不浪费时间检查要删除内容的大小。")
                    }
                    
                    Spacer()
                        .frame(height: 20)

                    // Disk Selector Card
                    diskSelectorCard
                    
                    Spacer() // Push up
                }
                .padding(.leading, 60)
                .padding(.trailing, 20)
                .frame(maxWidth: 400, alignment: .leading)
                
                Spacer()
                
                // Right Column: Planet Image
                ZStack {
                    if let imagePath = Bundle.main.path(forResource: "kongjianshentou", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 500, maxHeight: 500)
                    } else {
                        // Fallback
                        Circle()
                            .fill(LinearGradient(colors: [.green.opacity(0.8), .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 400, height: 400)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: 0, y: -20)
            }
            .padding(.top, 60)
            
            // Floating Scan Button (Bottom Center)
            Button(action: startScan) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .fill(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text(loc.currentLanguage == .chinese ? "扫描" : "Scan")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Disk Selector
    private var diskSelectorCard: some View {
        Menu {
            Button("mac") {
                selectedDiskPath = URL(fileURLWithPath: "/")
                selectedDiskName = "mac"
            }
            Button(loc.currentLanguage == .chinese ? "用户文件夹" : "User Home") {
                selectedDiskPath = FileManager.default.homeDirectoryForCurrentUser
                selectedDiskName = "Users"
            }
            Divider()
            Button(loc.currentLanguage == .chinese ? "选择文件夹..." : "Select Folder...") {
                selectFolder()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(selectedDiskName == "mac" ? "mac: 245.11 GB" : "\(selectedDiskName): 245.11 GB") // Mock total for now
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.green)
                                .frame(width: geo.size.width * 0.45, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Text(loc.currentLanguage == .chinese ? "已使用 110.55 GB" : "Used 110.55 GB")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .menuStyle(.borderlessButton)
        .frame(width: 300)
    }
    

    
    func featureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.currentLanguage == .chinese ? title : "Instant Overview")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                Text(loc.currentLanguage == .chinese ? desc : "See what takes up space instantly.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Scanning View
    var scanningView: some View {
        ZStack {
            VStack {
                Spacer()
                
                // Pulsating Planet
                ZStack {
                    if let imagePath = Bundle.main.path(forResource: "kongjianshentou", ofType: "png"),
                       let nsImage = NSImage(contentsOfFile: imagePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 300)
                            .scaleEffect(scanner.isScanning ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scanner.isScanning)
                    }
                }
                // Scanning Status Text
                Text(loc.currentLanguage == .chinese ? "构建您的存储图..." : "Building your storage map...")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text(scanner.currentPath)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .frame(width: 500)
                    .padding(.top, 8)
                
                Spacer()
                
                // Stop Button & Size
                HStack(spacing: 20) {
                    Button(action: stopScan) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                .frame(width: 80, height: 80)
                            
                            // Progress Ring
                            Circle()
                                .trim(from: 0, to: scanner.scanProgress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 70, height: 70)
                            
                            Text(loc.currentLanguage == .chinese ? "停止" : "Stop")
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Text(ByteCountFormatter.string(fromByteCount: scanner.totalSize, countStyle: .file))
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 60)
            }
            .onChange(of: scanner.rootNode) { newNode in
                if let root = newNode {
                    self.currentNode = root
                    self.calculateLayout(for: root)
                    withAnimation {
                        self.viewState = 2
                    }
                }
            }
        }
    }
    
    // MARK: - Results View
    var resultsView: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Sidebar List
                VStack(spacing: 0) {
                    // Breadcrumbs / Back
                    HStack {
                        Button(action: goBack) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text(navigationStack.isEmpty ? (loc.currentLanguage == .chinese ? "重新开始" : "Restart") : navigationStack.last?.name ?? "Back")
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    
                    // Current Dir Info
                    HStack {
                        if let icon = iconForFile(currentNode) {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                             Image(systemName: "folder.fill")
                                .foregroundColor(.cyan)
                        }
                        Text(currentNode?.name ?? "Mac")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding()
                    
                    // List
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(currentNode?.children ?? []) { child in
                                FileListRow(node: child, totalSize: currentNode?.size ?? 1)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        enterNode(child)
                                    }
                            }
                        }
                    }
                }
                .frame(width: 260)
                .background(Color.black.opacity(0.15))
                
                // Bubble Chart Area
                ZStack {
                    // Background Circles
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 2)
                        .frame(width: 600, height: 600)
                    Circle()
                        .stroke(Color.white.opacity(0.03), lineWidth: 30)
                        .frame(width: 800, height: 800)
                    
                    if let node = currentNode {
                         bubbleChart(for: node, size: CGSize(width: geometry.size.width - 260, height: geometry.size.height))
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .clipped()
                .overlay(alignment: .bottom) {
                     // Floating Remove Button (Overlay to ensure on top and position)
                     Button(action: {
                          // Remove Logic (Mock for now)
                          print("Remove selected items")
                     }) {
                         ZStack {
                             Circle()
                                 .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                 .frame(width: 90, height: 90)
                             
                             Circle()
                                 .fill(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                                 .frame(width: 80, height: 80)
                                 .overlay(
                                     Circle()
                                         .stroke(Color.white, lineWidth: 2)
                                 )
                                 .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                             
                             Text(loc.currentLanguage == .chinese ? "移除" : "Remove")
                                 .font(.system(size: 16, weight: .semibold))
                                 .foregroundColor(.white)
                         }
                     }
                     .buttonStyle(.plain)
                     .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .clipped()
            }
        }
    }
    
    // MARK: - Bubble Chart Logic
    func bubbleChart(for node: FileNode, size: CGSize) -> some View {
        ZStack {
            // Central Node (Current Directory)
            bubbleView(node: node, isCenter: true)
                .position(x: size.width / 2, y: size.height / 2)
                .zIndex(100)
            
            // Children Nodes (Orbiting)
            ForEach(node.children.prefix(8)) { child in // Use layout logic here
                if let pos = bubblePositions[child.id], let radius = bubbleSizes[child.id] {
                     bubbleView(node: child, isCenter: false, diameter: radius)
                        .position(x: size.width/2 + pos.x, y: size.height/2 + pos.y) // Offset from center
                        .onTapGesture {
                            withAnimation(.spring()) {
                                enterNode(child)
                            }
                        }
                }
            }
            
            // Handle "Other" or small files?
        }
        .onAppear {
             calculateLayout(for: node)
        }
        .onChange(of: node.id) { _ in
             calculateLayout(for: node)
        }
    }
    
    func bubbleView(node: FileNode, isCenter: Bool, diameter: CGFloat = 200) -> some View {
        let size = isCenter ? 220 : diameter
        return ZStack {
             Circle()
                 .fill(
                    LinearGradient(
                        colors: isCenter ? [Color.cyan.opacity(0.8), Color.blue.opacity(0.8)] : [Color.white.opacity(0.15), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                 )
                 .frame(width: size, height: size)
                 .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                 .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
             if isCenter {
                  // Ripple effect for center?
                 Circle()
                     .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                     .frame(width: size + 20, height: size + 20)
             }
            
            VStack(spacing: 4) {
                 if let icon = iconForFile(node) {
                      Image(nsImage: icon)
                         .resizable()
                         .frame(width: isCenter ? 64 : 48, height: isCenter ? 64 : 48)
                 } else {
                      Image(systemName: isCenter ? "folder.fill" : "doc.fill")
                         .font(.system(size: isCenter ? 40 : 30))
                         .foregroundColor(.white)
                 }
                
                Text(node.name)
                    .font(.system(size: isCenter ? 16 : 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: size - 20)
                
                Text(node.formattedSize)
                    .font(.system(size: isCenter ? 14 : 10))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Layout Algorithm
    func calculateLayout(for node: FileNode) {
        // Center is (0,0) relative.
        // We pack children around it.
        // Heuristic:
        // Largest children closest?
        // Let's use a "Flower" pattern for simplicity but effectiveness.
        // Or a fixed set of orbital slots.
        
        let children = node.children.prefix(12) // Limit displayed bubbles
        if children.isEmpty { return }
        
        // Base Unit
        let centerR: CGFloat = 110 // Radius of center bubble
        
        // Arrange in a circle?
        // Spiral?
        // Let's try Spiral packing.
        
        var angle: CGFloat = 0
        var radius: CGFloat = centerR + 20 // Start just outside center
        
        var positions: [UUID: CGPoint] = [:]
        var sizes: [UUID: CGFloat] = [:]
        
        // Normalize sizes for visualization
        // Max bubble size = 180, Min = 60
        let maxSize: CGFloat = 180
        let minSize: CGFloat = 70
        let maxFileSize = children.first?.size ?? 1
        
        for child in children {
            // Calculate scale
            let scale = CGFloat(child.size) / CGFloat(maxFileSize)
            let bubSize = minSize + (maxSize - minSize) * sqrt(scale)
            sizes[child.id] = bubSize
            
            // Position
            // Increase radius based on bubble size to prevent overlap
            let effectiveR = radius + bubSize/2
            let x = cos(angle) * effectiveR
            let y = sin(angle) * effectiveR
            
            positions[child.id] = CGPoint(x: x, y: y)
            
            // Increment angle and radius for spiral
            // Larger bubbles take more angle space
            let angleStep = (bubSize + 20) / effectiveR * 1.5 // approximate arc
            angle += angleStep
            radius += 10 // Spiral out slightly
            
            if angle > .pi * 2 * 2 { // Reset if too far? 
                 // Keep spiraling
            }
        }
        
        self.bubblePositions = positions
        self.bubbleSizes = sizes
    }
    
    // MARK: - Actions
    func startScan() {
        let path = selectedDiskPath
        Task {
            await scanner.scan(targetURL: path)
        }
        withAnimation {
            viewState = 1
        }
    }
    
    func stopScan() {
        scanner.stopScan()
        viewState = 0
    }
    
    func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            self.selectedDiskPath = url
            self.selectedDiskName = url.lastPathComponent
        }
    }
    
    func enterNode(_ node: FileNode) {
        if let current = currentNode {
            navigationStack.append(current)
        }
        currentNode = node
    }
    
    func goBack() {
        if let parent = navigationStack.popLast() {
            currentNode = parent
        } else {
            // Reset to Landing?
            stopScan() // Restart
        }
    }
    
    func iconForFile(_ node: FileNode?) -> NSImage? {
        guard let node = node else { return nil }
        return NSWorkspace.shared.icon(forFile: node.url.path)
    }
}

// MARK: - File List Row
struct FileListRow: View {
    @ObservedObject var node: FileNode
    let totalSize: Int64
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    .frame(width: 16, height: 16)
                if node.isSelected {
                     Circle().fill(Color.blue).frame(width: 10, height: 10)
                }
            }
            .contentShape(Rectangle()) // Hit area
            .onTapGesture {
                node.isSelected.toggle()
            }
            
            let icon = NSWorkspace.shared.icon(forFile: node.url.path)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Size Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(Color.cyan) // Teal bar
                            .frame(width: geo.size.width * CGFloat(node.size) / CGFloat(totalSize), height: 3)
                    }
                }
                .frame(height: 3)
            }
            
            Text(node.formattedSize)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
