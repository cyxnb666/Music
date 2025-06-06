//
//  SongListView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI
import AVFoundation

// MARK: - 歌曲列表界面
struct SongListView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @EnvironmentObject var songLibrary: SongLibrary
    @State private var showingFolderPicker = false
    @State private var searchText = "" // 搜索文本
    @State private var isSearching = false // 是否正在搜索
    
    // 过滤后的歌曲列表
    private var filteredSongs: [Song] {
        if searchText.isEmpty {
            return songLibrary.songs
        } else {
            return songLibrary.songs.filter { song in
                song.title.localizedCaseInsensitiveContains(searchText) ||
                song.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 歌曲列表
            if songLibrary.songs.isEmpty {
                // 空状态
                emptyStateView
            } else {
                // 歌曲列表
                songListContent
            }
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderDocumentPicker { folderURL in
                if let folderURL = folderURL {
                    songLibrary.importMusicFolder(folderURL)
                }
            }
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("暂无歌曲")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("导入更多音乐文件夹来添加歌曲")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingFolderPicker = true
            }) {
                Label("导入更多歌曲", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 歌曲列表内容
    private var songListContent: some View {
        VStack(spacing: 0) {
            // 列表头部信息
            listHeaderView
            
            // 搜索栏
            searchBarView
            
            // 播放控制按钮区域
            playControlButtonsView

            // 歌曲列表
            List {
                ForEach(Array(filteredSongs.enumerated()), id: \.element.id) { index, song in
                    SongRowView(
                        song: song,
                        isPlaying: musicPlayer.currentSong?.id == song.id && musicPlayer.isPlaying,
                        isCurrentSong: musicPlayer.currentSong?.id == song.id,
                        onDelete: {
                            // 删除操作的触觉反馈
                            HapticManager.shared.operationConfirm()
                            deleteSong(song)
                        },
                        onPlay: {
                            // 选择歌曲的触觉反馈
                            HapticManager.shared.listSelection()
                            playSong(song)
                        }
                    )
                    .animation(
                        AppleAnimations.staggeredListAnimation(index: index),
                        value: filteredSongs.count
                    )
                    .onTapGesture {
                        HapticManager.shared.listSelection()
                        playSong(song)
                    }
                }
            }
            .listStyle(PlainListStyle())
            // 移除可能导致冲突的配置
            // .scrollContentBackground(.hidden) // 注释掉这行
            // .drawingGroup() // 注释掉这行
            .background(AppColors.adaptiveBackground)
            // 为迷你播放器留出底部空间
            .padding(.bottom, musicPlayer.currentSong != nil ? 80 : 0)
            .animation(AppleAnimations.standardTransition, value: musicPlayer.currentSong != nil)
        }
    }
    
    // MARK: - 列表头部
    private var listHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("我的音乐库")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("\(songLibrary.songs.count) 首歌曲")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingFolderPicker = true
            }) {
                Image(systemName: "folder.badge.plus")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding()
        .padding(.top, 8) // 额外的顶部间距替代导航标题
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 搜索栏视图
    private var searchBarView: some View {
        VStack(spacing: 0) {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)
                    
                    TextField("搜索歌曲或艺术家", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onTapGesture {
                            withAnimation(AppleAnimations.microInteraction) {
                                isSearching = true
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            withAnimation(AppleAnimations.microInteraction) {
                                searchText = ""
                                isSearching = false
                            }
                            // 隐藏键盘
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.body)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.adaptiveSecondaryBackground)
                )
                .scaleEffect(isSearching ? 1.02 : 1.0)
                .animation(AppleAnimations.microInteraction, value: isSearching)
                
                if isSearching {
                    Button("取消") {
                        HapticManager.shared.buttonTap()
                        withAnimation(AppleAnimations.standardTransition) {
                            searchText = ""
                            isSearching = false
                        }
                        // 隐藏键盘
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(AppColors.primary)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .animation(AppleAnimations.standardTransition, value: isSearching)
            
            // 搜索结果提示
            if !searchText.isEmpty {
                HStack {
                    Text("找到 \(filteredSongs.count) 首歌曲")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(AppleAnimations.quickMicro, value: filteredSongs.count)
            }
        }
        .padding(.vertical, 12)
        .background(AppColors.adaptiveBackground)
    }
    
    // MARK: - 播放控制按钮区域
    private var playControlButtonsView: some View {
        VStack(spacing: 16) {
            // 如果有搜索结果或没有搜索时显示按钮
            if !filteredSongs.isEmpty {
                HStack(spacing: 12) {
                    // 播放按钮（从第一首开始）
                    Button(action: {
                        HapticManager.shared.playControl()
                        playFromBeginning()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("播放")
                                .fontWeight(.medium)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                    }
                    .scaleEffect(1.0)
                    .animation(AppleAnimations.microInteraction, value: filteredSongs.count)
                    .accessibilityLabel("播放所有歌曲")
                    
                    // 随机播放按钮
                    Button(action: {
                        HapticManager.shared.modeToggle()
                        playRandomly()
                    }) {
                        HStack {
                            Image(systemName: "shuffle")
                            Text("随机播放")
                                .fontWeight(.medium)
                        }
                        .font(.headline)
                        .foregroundColor(AppColors.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primaryOpacity08)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColors.primary, lineWidth: 1)
                        )
                    }
                    .scaleEffect(1.0)
                    .animation(AppleAnimations.microInteraction, value: filteredSongs.count)
                    .accessibilityLabel("随机播放所有歌曲")
                }
                .padding(.horizontal)
            }
            
            // 如果有搜索但没有结果，显示提示
            if !searchText.isEmpty && filteredSongs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    
                    Text("未找到匹配的歌曲")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("尝试其他关键词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
                .transition(.scale.combined(with: .opacity))
                .animation(AppleAnimations.standardTransition, value: filteredSongs.isEmpty)
            }
        }
        .background(AppColors.adaptiveBackground)
    }
    
    // MARK: - 播放歌曲
    private func playSong(_ song: Song) {
        print("播放歌曲: \(song.title)")
        
        // 使用当前显示的歌曲列表（可能是搜索结果）
        let songsToPlay = filteredSongs
        
        // 找到歌曲在当前显示列表中的索引
        guard let songIndex = songsToPlay.firstIndex(where: { $0.id == song.id }) else {
            print("未找到歌曲索引")
            return
        }
        
        // 先设置为顺序播放模式，避免随机逻辑干扰
        musicPlayer.playbackMode = .sequence
        
        // 设置播放列表并播放指定歌曲
        musicPlayer.setPlaylist(songsToPlay, startIndex: songIndex)
        
        // 加载对应的歌词文件（如果存在）
        loadLyricsForSong(song)
        
        // 开始播放
        if !musicPlayer.isPlaying {
            musicPlayer.togglePlayPause()
        }
    }
    
    // MARK: - 从头开始播放
    private func playFromBeginning() {
        let songsToPlay = filteredSongs
        guard !songsToPlay.isEmpty else { return }
        
        print("从第一首开始播放，共 \(songsToPlay.count) 首歌曲")
        
        // 设置为顺序播放模式
        musicPlayer.playbackMode = .sequence
        
        // 设置播放列表从第一首开始
        musicPlayer.setPlaylist(songsToPlay, startIndex: 0)
        
        // 加载第一首歌曲的歌词
        loadLyricsForSong(songsToPlay[0])
        
        // 开始播放
        if !musicPlayer.isPlaying {
            musicPlayer.togglePlayPause()
        }
    }
    
    // MARK: - 随机播放
    private func playRandomly() {
        let songsToPlay = filteredSongs
        guard !songsToPlay.isEmpty else { return }
        
        print("开始随机播放，共 \(songsToPlay.count) 首歌曲")
        
        // 随机选择一首歌作为开始
        let randomStartIndex = Int.random(in: 0..<songsToPlay.count)
        let selectedSong = songsToPlay[randomStartIndex]
        
        print("🎲 随机选择的索引: \(randomStartIndex), 歌曲: \(selectedSong.title)")
        
        // 先设置为随机播放模式
        musicPlayer.playbackMode = .shuffle
        
        // 设置播放列表，MusicPlayer会处理随机逻辑
        musicPlayer.setPlaylist(songsToPlay, startIndex: randomStartIndex)
        
        // 加载选中歌曲的歌词
        loadLyricsForSong(selectedSong)
        
        // 开始播放
        if !musicPlayer.isPlaying {
            musicPlayer.togglePlayPause()
        }
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        print("✅ 随机播放已开始，当前歌曲：\(selectedSong.title)")
    }
    
    // MARK: - 删除歌曲
    private func deleteSong(_ song: Song) {
        // 如果正在播放这首歌，先停止播放
        if musicPlayer.currentSong?.id == song.id {
            // 使用公共方法暂停播放
            if musicPlayer.isPlaying {
                musicPlayer.togglePlayPause()
            }
            // 清空当前歌曲状态（这些是公共属性，可以直接设置）
            musicPlayer.currentSong = nil
            musicPlayer.lyrics = []
        }
        
        // 从歌曲库中移除
        if let index = songLibrary.songs.firstIndex(where: { $0.id == song.id }) {
            songLibrary.songs.remove(at: index)
        }
        
        // 删除文件
        do {
            // 删除歌曲文件夹（包含音频和歌词文件）
            let songFolder = songLibrary.songsDirectory.appendingPathComponent(song.title)
            if FileManager.default.fileExists(atPath: songFolder.path) {
                try FileManager.default.removeItem(at: songFolder)
                print("删除歌曲文件夹成功: \(song.title)")
            }
        } catch {
            print("删除歌曲文件失败: \(error)")
        }
        
        // 如果删除后列表为空，重置库状态
        if songLibrary.songs.isEmpty {
            songLibrary.hasImportedLibrary = false
        }
    }
    
    // MARK: - 加载歌曲对应的歌词
    private func loadLyricsForSong(_ song: Song) {
        let songName = song.title
        let songFolder = songLibrary.songsDirectory.appendingPathComponent(songName)
        
        // 查找.lrc文件
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: songFolder, includingPropertiesForKeys: nil)
            if let lrcFile = contents.first(where: { $0.pathExtension.lowercased() == "lrc" }) {
                let lyricsContent = try String(contentsOf: lrcFile, encoding: .utf8)
                let parsedLyrics = musicPlayer.parseLRCContent(lyricsContent)
                
                DispatchQueue.main.async {
                    self.musicPlayer.lyrics = parsedLyrics
                    print("加载歌词成功，共 \(parsedLyrics.count) 行")
                }
            } else {
                // 清空歌词
                DispatchQueue.main.async {
                    self.musicPlayer.lyrics = []
                    print("未找到歌词文件")
                }
            }
        } catch {
            print("加载歌词失败: \(error)")
            DispatchQueue.main.async {
                self.musicPlayer.lyrics = []
            }
        }
    }
}

// MARK: - 增强版歌曲行视图（Apple Music风格）
struct SongRowView: View {
    let song: Song
    let isPlaying: Bool
    let isCurrentSong: Bool
    let onDelete: (() -> Void)?
    let onPlay: (() -> Void)?
    
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSongInfo = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放状态指示器 - Apple Music风格
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentSong ? AppColors.primaryOpacity15 : AppColors.adaptiveSecondaryBackground)
                    .frame(width: 48, height: 48) // Apple标准48pt
                
                if isPlaying {
                    // 播放中的波形动画
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                        .scaleEffect(1.1)
                } else if isCurrentSong {
                    // 当前歌曲但暂停
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                } else {
                    // 普通状态
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .animation(AppleAnimations.microInteraction, value: isPlaying)
            .shadow(color: isCurrentSong ? AppColors.lightShadow : .clear, radius: 2, x: 0, y: 1)
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(isCurrentSong ? AppColors.primary : .primary)
                    .lineLimit(1)
                    .animation(AppleAnimations.quickMicro, value: isCurrentSong)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 更多选项按钮 - 改进的触摸区域
            Button(action: {
                HapticManager.shared.buttonTap()
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44) // Apple标准触摸区域
                    .contentShape(Circle()) // 圆形触摸区域
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(AppleAnimations.microInteraction, value: isPressed)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPressed ? AppColors.primaryOpacity08 : Color.clear)
                .animation(AppleAnimations.quickMicro, value: isPressed)
        )
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppleAnimations.microInteraction, value: isPressed)
        .onTapGesture {
            HapticManager.shared.listSelection()
            onPlay?()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(AppleAnimations.quickMicro) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(AppleAnimations.quickMicro) {
                        isPressed = false
                    }
                }
        )
        
        // 操作菜单 - Apple风格
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(song.title),
                message: Text("选择操作"),
                buttons: [
                    .default(Text("播放")) {
                        HapticManager.shared.playControl()
                        onPlay?()
                    },
                    .default(Text("歌曲信息")) {
                        HapticManager.shared.buttonTap()
                        showingSongInfo = true
                    },
                    .destructive(Text("从库中删除")) {
                        HapticManager.shared.warning()
                        showingDeleteAlert = true
                    },
                    .cancel(Text("取消")) {
                        HapticManager.shared.buttonTap()
                    }
                ]
            )
        }
        
        // 删除确认对话框
        .alert("删除歌曲", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                HapticManager.shared.operationConfirm()
                onDelete?()
            }
            Button("取消", role: .cancel) {
                HapticManager.shared.buttonTap()
            }
        } message: {
            Text("确定要从音乐库中删除「\(song.title)」吗？此操作无法撤销。")
        }
        
        // 歌曲信息弹窗
        .sheet(isPresented: $showingSongInfo) {
            SongInfoView(song: song)
        }
        
        // 可访问性支持
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(song.title)，\(song.artist)")
        .accessibilityHint("双击播放，长按查看选项")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isPlaying ? "正在播放" : isCurrentSong ? "当前歌曲，已暂停" : "")
        .accessibilityAction(named: "播放") {
            HapticManager.shared.playControl()
            onPlay?()
        }
        .accessibilityAction(named: "删除") {
            showingDeleteAlert = true
        }
        .accessibilityAction(named: "查看信息") {
            showingSongInfo = true
        }
    }
}

// MARK: - 歌曲信息视图
struct SongInfoView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss
    @State private var audioDuration: TimeInterval? = nil // 添加状态变量来存储时长
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // 封面
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(colors: [.blue, .purple],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
                
                // 歌曲信息
                VStack(alignment: .leading, spacing: 16) {
                    InfoRow(label: "标题", value: song.title)
                    InfoRow(label: "艺术家", value: song.artist)
                    InfoRow(label: "文件名", value: song.url.lastPathComponent)
                    
                    if let fileSize = getFileSize(for: song.url) {
                        InfoRow(label: "文件大小", value: fileSize)
                    }
                    
                    if let duration = audioDuration {
                        InfoRow(label: "时长", value: formatDuration(duration))
                    } else {
                        HStack {
                            Text("时长")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    InfoRow(label: "文件格式", value: song.url.pathExtension.uppercased())
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("歌曲信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task { // 添加task来异步加载时长
                await loadAudioDuration()
            }
        }
    }
    
    // MARK: - 辅助方法
    private func getFileSize(for url: URL) -> String? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            print("获取文件大小失败: \(error)")
        }
        return nil
    }
    
    // 异步方法来获取音频时长
    private func loadAudioDuration() async {
        let asset = AVURLAsset(url: song.url)
        
        do {
            if #available(iOS 16.0, *) {
                let duration = try await asset.load(.duration)
                await MainActor.run {
                    if duration.isValid && !duration.isIndefinite {
                        self.audioDuration = CMTimeGetSeconds(duration)
                    }
                }
            } else {
                // 兼容旧版本
                await MainActor.run {
                    let duration = asset.duration
                    if duration.isValid && !duration.isIndefinite {
                        self.audioDuration = CMTimeGetSeconds(duration)
                    }
                }
            }
        } catch {
            print("获取音频时长失败: \(error)")
            await MainActor.run {
                self.audioDuration = nil
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 信息行组件
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}
