//
//  PlaybackQueueView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 播放队列视图
struct PlaybackQueueView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 播放模式控制区域
                playbackControlsSection
                
                // 当前播放
                if let currentSong = musicPlayer.currentSong {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("正在播放")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CurrentPlayingSongRow(song: currentSong)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.gray.opacity(0.1))
                }
                
                // 播放队列信息
                let queueInfo = musicPlayer.getQueueInfo()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("接下来播放")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(queueInfo.current)/\(queueInfo.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if queueInfo.upcoming.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("队列为空")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(Array(queueInfo.upcoming.enumerated()), id: \.element.id) { index, song in
                                UpcomingSongRow(
                                    song: song,
                                    position: index + 1,
                                    onPlay: {
                                        let actualIndex = musicPlayer.currentIndex + index + 1
                                        if actualIndex < musicPlayer.playlist.count {
                                            musicPlayer.playTrack(at: actualIndex)
                                        }
                                        dismiss()
                                    }
                                )
                            }
                            .onMove(perform: moveItems)
                        }
                        .listStyle(PlainListStyle())
                        .environment(\.editMode, .constant(.active)) // 始终启用编辑模式以支持拖拽
                    }
                }
                .padding(.top)
            }
            .navigationTitle("播放队列")
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
    
    // MARK: - 播放模式控制区域
    private var playbackControlsSection: some View {
        VStack(spacing: 16) {
            Text("播放设置")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // 播放模式按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        musicPlayer.togglePlaybackMode()
                    }
                    
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(musicPlayer.playbackMode == .shuffle ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: musicPlayer.playbackMode.iconName)
                                .font(.title2)
                                .foregroundColor(musicPlayer.playbackMode == .shuffle ? .blue : .secondary)
                        }
                        
                        Text(musicPlayer.playbackMode.displayName)
                            .font(.caption)
                            .foregroundColor(musicPlayer.playbackMode == .shuffle ? .blue : .secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                
                // 重复模式按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        musicPlayer.toggleRepeatMode()
                    }
                    
                    // 触觉反馈
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(musicPlayer.repeatMode != .off ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: musicPlayer.repeatMode.iconName)
                                .font(.title2)
                                .foregroundColor(musicPlayer.repeatMode != .off ? .blue : .secondary)
                        }
                        
                        Text(getRepeatDisplayText())
                            .font(.caption)
                            .foregroundColor(musicPlayer.repeatMode != .off ? .blue : .secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            // 当前模式说明
            Text(getCurrentModeDescription())
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    // MARK: - 拖拽重排序处理
    private func moveItems(from source: IndexSet, to destination: Int) {
        // 调用MusicPlayer的重排序方法
        musicPlayer.moveQueueItems(from: source, to: destination)
        
        // 提供触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - 辅助方法
    private func getRepeatDisplayText() -> String {
        switch musicPlayer.repeatMode {
        case .off: return "关闭重复"
        case .all: return "重复列表"
        case .one: return "单曲循环"
        }
    }
    
    private func getCurrentModeDescription() -> String {
        let playbackText = musicPlayer.playbackMode == .shuffle ? "随机播放" : "按顺序播放"
        let repeatText: String
        
        switch musicPlayer.repeatMode {
        case .off:
            repeatText = "播放完成后停止"
        case .all:
            repeatText = "列表播放完后重新开始"
        case .one:
            repeatText = "当前歌曲单曲循环"
        }
        
        return "\(playbackText)，\(repeatText)"
    }
}

// MARK: - 当前播放歌曲行
struct CurrentPlayingSongRow: View {
    let song: Song
    @EnvironmentObject var musicPlayer: MusicPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放动画指示器
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if musicPlayer.isPlaying {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                } else {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 播放模式指示器
            VStack(spacing: 2) {
                if musicPlayer.playbackMode == .shuffle {
                    Image(systemName: "shuffle")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if musicPlayer.repeatMode != .off {
                    Image(systemName: musicPlayer.repeatMode.iconName)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - 即将播放歌曲行
struct UpcomingSongRow: View {
    let song: Song
    let position: Int
    let onPlay: () -> Void
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        HStack(spacing: 12) {
            // 序号（始终显示）
            Text("\(position)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // 封面占位符
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(song.artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 播放按钮（仅在非编辑模式下显示）
            if editMode?.wrappedValue != .active {
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 只有在非编辑模式下才响应点击播放
            if editMode?.wrappedValue != .active {
                onPlay()
            }
        }
    }
}
