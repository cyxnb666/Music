//
//  SongListView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

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
                        isCurrentSong: musicPlayer.currentSong?.id == song.id
                    )
                    .onTapGesture {
                        playSong(song)
                    }
                }
            }
            .listStyle(PlainListStyle())
            // 为迷你播放器留出底部空间
            .padding(.bottom, musicPlayer.currentSong != nil ? 70 : 0)
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
        
        // 加载歌曲到播放器
        musicPlayer.loadSong(song)
        
        // 加载对应的歌词文件（如果存在）
        loadLyricsForSong(song)
        
        // 开始播放
        musicPlayer.togglePlayPause()
    }
    
    // MARK: - 播放全部歌曲
    private func playAllSongs() {
        guard let firstSong = songLibrary.songs.first else { return }
        playSong(firstSong)
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

// MARK: - 歌曲行视图
struct SongRowView: View {
    let song: Song
    let isPlaying: Bool
    let isCurrentSong: Bool
    
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
            
            // 更多选项按钮
            Button(action: {
                // 暂时留空，以后可以添加更多功能
            }) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
