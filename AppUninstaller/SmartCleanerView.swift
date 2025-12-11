import SwiftUI

struct SmartCleanerView: View {
    @StateObject private var service = SmartCleanerService()
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var selectedCategory: CleanerCategory = .duplicates
    @State private var showDeleteConfirmation = false
    @State private var deleteResult: (success: Int, failed: Int, size: Int64)?
    @State private var showResult = false
    
    // View State
    @State private var isDetailViewActive = false
    @State private var hasScannedOnce = false
    
    var body: some View {
        ZStack {
            if isDetailViewActive {
                detailViewLayout
                    .transition(.move(edge: .trailing))
            } else {
                dashboardLayout
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isDetailViewActive)
        .confirmationDialog(
            loc.currentLanguage == .chinese ? "确认删除" : "Confirm Delete",
            isPresented: $showDeleteConfirmation
        ) {
            Button(loc.currentLanguage == .chinese ? "删除选中文件" : "Delete Selected", role: .destructive) {
                Task {
                    let result = await service.cleanAll()
                    deleteResult = result
                    showResult = true
                    // Reset scan state after clean
                    hasScannedOnce = false
                }
            }
            Button(loc.L("cancel"), role: .cancel) {}
        } message: {
            Text(loc.currentLanguage == .chinese ?
                 "将清理所有选中的垃圾文件，释放空间。" :
                 "Clean all selected files to free up space.")
        }
        .alert(loc.currentLanguage == .chinese ? "清理完成" : "Cleanup Complete", isPresented: $showResult) {
            Button(loc.L("confirm"), role: .cancel) {}
        } message: {
            if let result = deleteResult {
                Text(loc.currentLanguage == .chinese ?
                     "成功删除 \(result.success) 个文件，释放 \(ByteCountFormatter.string(fromByteCount: result.size, countStyle: .file))" :
                     "Deleted \(result.success) files, freed \(ByteCountFormatter.string(fromByteCount: result.size, countStyle: .file))")
            }
        }
        .onAppear {
            // Auto start scan when entering if not scanned
            if !hasScannedOnce && !service.isScanning {
                Task {
                    await service.scanAll()
                    hasScannedOnce = true
                }
            }
        }
    }
    
    // MARK: - Dashboard Layout
    private var dashboardLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(loc.currentLanguage == .chinese ? "智能扫描" : "Smart Scan")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(24)
            
            Spacer()
            
            // Central Scan Circle
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 220, height: 220)
                
                // Progress Circle
                if service.isScanning {
                    Circle()
                        .trim(from: 0, to: service.scanProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: service.scanProgress)
                } else if hasScannedOnce {
                    Circle()
                        .stroke(Color.green, lineWidth: 12)
                        .frame(width: 220, height: 220)
                }
                
                // Central Content
                VStack(spacing: 8) {
                    if service.isScanning {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.cyan)
                            .foregroundColor(.cyan)
                            .scaleEffect(service.isScanning ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: service.isScanning)
                        
                        Text("\(Int(service.scanProgress * 100))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else if hasScannedOnce {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                            .transition(.scale.combined(with: .opacity))
                        
                        Text(ByteCountFormatter.string(fromByteCount: service.totalCleanableSize, countStyle: .file))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                         Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(loc.currentLanguage == .chinese ? "准备就绪" : "Ready")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(.bottom, 20)
            
            // Status Text
            Text(statusText)
                .font(.headline)
                .foregroundColor(.secondaryText)
                .padding(.bottom, 40)
            
            Spacer()
            
            // Result Cards
            if hasScannedOnce {
                HStack(spacing: 16) {
                    ResultCard(
                        icon: "doc.on.doc",
                        title: loc.currentLanguage == .chinese ? "重复文件" : "Duplicates",
                        count: service.selectedCount(for: .duplicates),
                        size: service.selectedSize(for: .duplicates),
                        color: .blue
                    )
                    ResultCard(
                        icon: "photo.on.rectangle",
                        title: loc.currentLanguage == .chinese ? "相似照片" : "Similar Photos",
                        count: service.selectedCount(for: .similarPhotos),
                        size: service.selectedSize(for: .similarPhotos),
                        color: .purple
                    )
                    ResultCard(
                        icon: "globe",
                        title: loc.currentLanguage == .chinese ? "多语言" : "Language Files",
                        count: service.selectedCount(for: .localizations),
                        size: service.selectedSize(for: .localizations),
                        color: .orange
                    )
                    ResultCard(
                        icon: "externaldrive.fill",
                        title: loc.currentLanguage == .chinese ? "大文件" : "Large Files",
                        count: service.selectedCount(for: .largeFiles),
                        size: service.selectedSize(for: .largeFiles),
                        color: .pink
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Bottom Action Bar
            HStack {
                if hasScannedOnce && !service.isScanning {
                    Button(action: { isDetailViewActive = true }) {
                        Text(loc.currentLanguage == .chinese ? "查看详情" : "View Details")
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Text(loc.currentLanguage == .chinese ? "一键清理" : "Clean")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 44)
                            .background(
                                LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(22)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(service.totalCleanableSize == 0)
                } else if !service.isScanning {
                    Button(action: {
                        Task {
                            await service.scanAll()
                            hasScannedOnce = true
                        }
                    }) {
                        Text(loc.currentLanguage == .chinese ? "开始扫描" : "Start Scan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 160, height: 44)
                            .background(Color.blue)
                            .cornerRadius(22)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
    }
    
    // MARK: - Detail View Layout (Reused existing list logic)
    private var detailViewLayout: some View {
        VStack(spacing: 0) {
            // Header with Back Button
            HStack {
                Button(action: { isDetailViewActive = false }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(loc.currentLanguage == .chinese ? "返回摘要" : "Back to Summary")
                    }
                    .foregroundColor(.secondaryText)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(loc.currentLanguage == .chinese ? "扫描详情" : "Scan Details")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Invisible spacer to balance title
                Text("Back to Summary").hidden()
            }
            .padding(16)
            .background(Color.black.opacity(0.2))
            
            // Category Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CleanerCategory.allCases, id: \.self) { category in
                        CategoryTabButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: itemCount(for: category),
                            loc: loc
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            
            // Content
            contentView
            
            // Floating Clean Button for Details View
            if service.selectedCount(for: selectedCategory) > 0 {
                VStack {
                    Spacer()
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text(loc.currentLanguage == .chinese ? "清理选定项" : "Clean Selected")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(20)
                        .shadow(radius: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Helper Views & Methods
    
    private var statusText: String {
        if service.isScanning {
            let path = service.currentScanPath
            return (loc.currentLanguage == .chinese ? "正在扫描: " : "Scanning: ") + path
        } else if hasScannedOnce {
            return loc.currentLanguage == .chinese ? "扫描完成，发现可清理项目" : "Scan complete. Junk files found."
        } else {
            return loc.currentLanguage == .chinese ? "点击开始扫描您的系统" : "Click to start scanning your system"
        }
    }
    
    private var contentView: some View {
        Group {
            switch selectedCategory {
            case .duplicates: duplicatesListView
            case .similarPhotos: similarPhotosListView
            case .localizations: localizationsListView
            case .largeFiles: largeFilesListView
            }
        }
    }
    
    // ... (Keep existing List Views: duplicatesListView, similarPhotosListView, etc.)
    
    // MARK: - Duplicates List
    private var duplicatesListView: some View {
        Group {
            if service.duplicateGroups.isEmpty {
                emptyListView
            } else {
                List {
                    ForEach(Array(service.duplicateGroups.enumerated()), id: \.element.id) { groupIndex, group in
                        Section {
                            ForEach(Array(group.files.enumerated()), id: \.element.id) { fileIndex, file in
                                FileRow(file: file, isSelected: file.isSelected) {
                                    service.duplicateGroups[groupIndex].files[fileIndex].isSelected.toggle()
                                }
                            }
                        } header: {
                            HStack {
                                Text(loc.currentLanguage == .chinese ? "重复组 \(groupIndex + 1)" : "Group \(groupIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: group.wastedSize, countStyle: .file))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    Color.clear.frame(height: 60).listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var similarPhotosListView: some View {
        Group {
            if service.similarPhotoGroups.isEmpty {
                emptyListView
            } else {
                List {
                    ForEach(Array(service.similarPhotoGroups.enumerated()), id: \.element.id) { groupIndex, group in
                        Section {
                            ForEach(Array(group.files.enumerated()), id: \.element.id) { fileIndex, file in
                                PhotoRow(file: file, isSelected: file.isSelected) {
                                    service.similarPhotoGroups[groupIndex].files[fileIndex].isSelected.toggle()
                                }
                            }
                        } header: {
                            HStack {
                                Text(loc.currentLanguage == .chinese ? "相似照片组 \(groupIndex + 1)" : "Similar Group \(groupIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                Spacer()
                                Text("\(group.files.count) \(loc.currentLanguage == .chinese ? "张" : "photos")")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    Color.clear.frame(height: 60).listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var localizationsListView: some View {
        Group {
            if service.localizationFiles.isEmpty {
                emptyListView
            } else {
                List {
                    ForEach(Array(service.localizationFiles.enumerated()), id: \.element.id) { index, file in
                        FileRow(file: file, isSelected: file.isSelected) {
                            service.localizationFiles[index].isSelected.toggle()
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                        .listRowBackground(Color.clear)
                    }
                    Color.clear.frame(height: 60).listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var largeFilesListView: some View {
        Group {
            if service.largeFiles.isEmpty {
                emptyListView
            } else {
                List {
                    ForEach(Array(service.largeFiles.enumerated()), id: \.element.id) { index, file in
                        FileRow(file: file, isSelected: file.isSelected) {
                            service.largeFiles[index].isSelected.toggle()
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 24))
                        .listRowBackground(Color.clear)
                    }
                    Color.clear.frame(height: 60).listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var emptyListView: some View {
        VStack {
            Spacer()
            Text(loc.currentLanguage == .chinese ? "未发现相关文件" : "No items found")
                .foregroundColor(.secondaryText)
            Spacer()
        }
    }
    
    private func itemCount(for category: CleanerCategory) -> Int {
        switch category {
        case .duplicates: return service.duplicateGroups.flatMap { $0.files }.count
        case .similarPhotos: return service.similarPhotoGroups.flatMap { $0.files }.count
        case .localizations: return service.localizationFiles.count
        case .largeFiles: return service.largeFiles.count
        }
    }
}

// MARK: - Result Card Component
struct ResultCard: View {
    let icon: String
    let title: String
    let count: Int
    let size: Int64
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondaryText)
            
            Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: 120)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - Existing Components (CategoryTabButton, FileRow, PhotoRow) kept same but ensured available
// ... (Including CategoryTabButton, FileRow, PhotoRow from previous implementation)

struct CategoryTabButton: View {
    let category: CleanerCategory
    let isSelected: Bool
    let count: Int
    @ObservedObject var loc: LocalizationManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(loc.currentLanguage == .chinese ? category.rawValue : category.englishName)
                    .font(.system(size: 13, weight: .medium))
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct FileRow: View {
    let file: CleanerFileItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            
            Image(nsImage: file.icon)
                .resizable()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(file.url.deletingLastPathComponent().path)
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(file.formattedSize)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PhotoRow: View {
    let file: CleanerFileItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .white.opacity(0.3))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            
            if let nsImage = NSImage(contentsOf: file.url) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .cornerRadius(6)
                    .clipped()
            } else {
                Image(systemName: "photo")
                    .frame(width: 48, height: 48)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(file.url.deletingLastPathComponent().path)
                    .font(.system(size: 11))
                    .foregroundColor(.tertiaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(file.formattedSize)
                .font(.system(size: 12))
                .foregroundColor(.secondaryText)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}
