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
                    .background(Color.blue)
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
            
            // 歌曲列表
            List {
                ForEach(songLibrary.songs, id: \.id) { song in
                    SongRowView(
                        song: song,
                        isPlaying: musicPlayer.currentSong?.id == song.id && musicPlayer.isPlaying,
                        isCurrentSong: musicPlayer.currentSong?.id == song.id,
                        onDelete: {
                            deleteSong(song)
                        },
                        onPlay: {
                            playSong(song)
                        }
                    )
                }
            }
            .listStyle(PlainListStyle())
            // 为迷你播放器留出底部空间
            .padding(.bottom, musicPlayer.currentSong != nil ? 80 : 0)
        }
    }
    
    // MARK: - 列表头部
    private var listHeaderView: some View {
        VStack(spacing: 12) {
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
                        .foregroundColor(.blue)
                }
            }
            
            // 播放全部按钮
            if !songLibrary.songs.isEmpty {
                Button(action: {
                    playAllSongs()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("播放全部")
                            .fontWeight(.medium)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .padding(.top, 8) // 额外的顶部间距替代导航标题
        .background(Color(UIColor.systemBackground))
    }
    
    // MARK: - 播放歌曲
    private func playSong(_ song: Song) {
        print("播放歌曲: \(song.title)")
        
        // 找到歌曲在列表中的索引
        guard let songIndex = songLibrary.songs.firstIndex(where: { $0.id == song.id }) else {
            print("未找到歌曲索引")
            return
        }
        
        // 设置播放列表并播放指定歌曲
        musicPlayer.setPlaylist(songLibrary.songs, startIndex: songIndex)
        
        // 加载对应的歌词文件（如果存在）
        loadLyricsForSong(song)
        
        // 开始播放
        musicPlayer.togglePlayPause()
    }
    
    // MARK: - 播放全部歌曲
    private func playAllSongs() {
        guard !songLibrary.songs.isEmpty else { return }
        
        // 设置播放列表从第一首开始
        musicPlayer.setPlaylist(songLibrary.songs, startIndex: 0)
        
        // 加载第一首歌曲的歌词
        loadLyricsForSong(songLibrary.songs[0])
        
        // 开始播放
        musicPlayer.togglePlayPause()
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

// MARK: - 增强版歌曲行视图（支持上下文菜单）
struct SongRowView: View {
    let song: Song
    let isPlaying: Bool
    let isCurrentSong: Bool
    let onDelete: (() -> Void)?
    let onPlay: (() -> Void)?
    
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSongInfo = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放状态指示器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentSong ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if isPlaying {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                } else if isCurrentSong {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(isCurrentSong ? .blue : .primary)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 更多选项按钮 - 现在有功能了！
            Button(action: {
                showingActionSheet = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30) // 增大点击区域
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onPlay?()
        }
        
        // 操作菜单
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text(song.title),
                message: Text("选择操作"),
                buttons: [
                    .default(Text("播放")) {
                        onPlay?()
                    },
                    .default(Text("歌曲信息")) {
                        showingSongInfo = true
                    },
                    .destructive(Text("从库中删除")) {
                        showingDeleteAlert = true
                    },
                    .cancel(Text("取消"))
                ]
            )
        }
        
        // 删除确认对话框
        .alert("删除歌曲", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                onDelete?()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要从音乐库中删除「\(song.title)」吗？此操作无法撤销。")
        }
        
        // 歌曲信息弹窗
        .sheet(isPresented: $showingSongInfo) {
            SongInfoView(song: song)
        }
    }
}

// MARK: - 歌曲信息视图
struct SongInfoView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    if let duration = getAudioDuration(for: song.url) {
                        InfoRow(label: "时长", value: formatDuration(duration))
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
    
    private func getAudioDuration(for url: URL) -> TimeInterval? {
        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        guard duration.isValid && !duration.isIndefinite else { return nil }
        return CMTimeGetSeconds(duration)
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
