//
//  PlaybackQueueView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

// 在PlaybackQueueView.swift中需要修改的关键部分

// MARK: - 1. 在文件顶部修改导入和类定义
import SwiftUI

// MARK: - 播放队列视图（Apple Music风格）
struct PlaybackQueueView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 播放模式控制区域 - 升级版
                playbackControlsSection
                
                // 当前播放 - 升级版
                if let currentSong = musicPlayer.currentSong {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("正在播放")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        CurrentPlayingSongRow(song: currentSong)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(AppColors.adaptiveSecondaryBackground)
                }
                
                // 播放队列信息 - 升级版
                let queueInfo = musicPlayer.getQueueInfo()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("接下来播放")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(queueInfo.current)/\(queueInfo.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.primaryOpacity08)
                            .cornerRadius(8)
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
                        .transition(.scale.combined(with: .opacity))
                        .animation(AppleAnimations.standardTransition, value: queueInfo.upcoming.isEmpty)
                    } else {
                        List {
                            ForEach(Array(queueInfo.upcoming.enumerated()), id: \.element.id) { index, song in
                                UpcomingSongRow(
                                    song: song,
                                    position: index + 1,
                                    onPlay: {
                                        HapticManager.shared.listSelection()
                                        let actualIndex = musicPlayer.currentIndex + index + 1
                                        if actualIndex < musicPlayer.playlist.count {
                                            musicPlayer.playTrack(at: actualIndex)
                                        }
                                        dismiss()
                                    }
                                )
                                .animation(
                                    AppleAnimations.staggeredListAnimation(index: index, stagger: 0.05),
                                    value: queueInfo.upcoming.count
                                )
                            }
                            .onMove(perform: moveItems)
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                        .background(AppColors.adaptiveBackground)
                        .environment(\.editMode, .constant(.active))
                    }
                }
                .padding(.top)
            }
            .background(AppColors.adaptiveBackground)
            .navigationTitle("播放队列")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        HapticManager.shared.buttonTap()
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
        .onAppear {
            HapticManager.shared.prepare()
        }
    }
    
    // MARK: - 2. 升级播放模式控制区域
    private var playbackControlsSection: some View {
        VStack(spacing: 16) {
            Text("播放设置")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // 播放模式按钮 - 升级版
                Button(action: {
                    HapticManager.shared.modeToggle()
                    withAnimation(AppleAnimations.standardTransition) {
                        musicPlayer.togglePlaybackMode()
                    }
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(musicPlayer.playbackMode == .shuffle ? AppColors.primaryOpacity20 : AppColors.adaptiveSecondaryBackground)
                                .frame(width: 50, height: 50)
                                .shadow(color: AppColors.lightShadow, radius: 2, x: 0, y: 1)
                            
                            Image(systemName: musicPlayer.playbackMode.iconName)
                                .font(.title2)
                                .foregroundColor(musicPlayer.playbackMode == .shuffle ? AppColors.primary : .secondary)
                        }
                        .scaleEffect(musicPlayer.playbackMode == .shuffle ? 1.1 : 1.0)
                        .animation(AppleAnimations.microInteraction, value: musicPlayer.playbackMode == .shuffle)
                        
                        Text(musicPlayer.playbackMode.displayName)
                            .font(.caption)
                            .foregroundColor(musicPlayer.playbackMode == .shuffle ? AppColors.primary : .secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityLabel("播放模式")
                .accessibilityValue(musicPlayer.playbackMode.displayName)
                
                // 重复模式按钮 - 升级版
                Button(action: {
                    HapticManager.shared.modeToggle()
                    withAnimation(AppleAnimations.standardTransition) {
                        musicPlayer.toggleRepeatMode()
                    }
                }) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(musicPlayer.repeatMode != .off ? AppColors.primaryOpacity20 : AppColors.adaptiveSecondaryBackground)
                                .frame(width: 50, height: 50)
                                .shadow(color: AppColors.lightShadow, radius: 2, x: 0, y: 1)
                            
                            Image(systemName: musicPlayer.repeatMode.iconName)
                                .font(.title2)
                                .foregroundColor(musicPlayer.repeatMode != .off ? AppColors.primary : .secondary)
                        }
                        .scaleEffect(musicPlayer.repeatMode != .off ? 1.1 : 1.0)
                        .animation(AppleAnimations.microInteraction, value: musicPlayer.repeatMode != .off)
                        
                        Text(getRepeatDisplayText())
                            .font(.caption)
                            .foregroundColor(musicPlayer.repeatMode != .off ? AppColors.primary : .secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityLabel("重复模式")
                .accessibilityValue(getRepeatDisplayText())
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
        .background(AppColors.adaptiveSecondaryBackground)
    }
    
    // MARK: - 3. 升级拖拽重排序处理
    private func moveItems(from source: IndexSet, to destination: Int) {
        // 调用MusicPlayer的重排序方法
        musicPlayer.moveQueueItems(from: source, to: destination)
        
        // 提供触觉反馈
        HapticManager.shared.operationConfirm()
    }
    
    // MARK: - 4. 辅助方法保持不变
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

// MARK: - 5. 升级当前播放歌曲行
struct CurrentPlayingSongRow: View {
    let song: Song
    @EnvironmentObject var musicPlayer: MusicPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放动画指示器 - 升级版
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.primaryOpacity20)
                    .frame(width: 50, height: 50)
                    .shadow(color: AppColors.lightShadow, radius: 4, x: 0, y: 2)
                
                if musicPlayer.isPlaying {
                    Image(systemName: "waveform")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                        .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing)
                        .scaleEffect(1.1)
                } else {
                    Image(systemName: "pause.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                }
            }
            .animation(AppleAnimations.microInteraction, value: musicPlayer.isPlaying)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
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
                        .foregroundColor(AppColors.primary)
                }
                
                if musicPlayer.repeatMode != .off {
                    Image(systemName: musicPlayer.repeatMode.iconName)
                        .font(.caption2)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("当前播放：\(song.title)")
        .accessibilityValue(musicPlayer.isPlaying ? "正在播放" : "已暂停")
    }
}

// MARK: - 6. 升级即将播放歌曲行
struct UpcomingSongRow: View {
    let song: Song
    let position: Int
    let onPlay: () -> Void
    @Environment(\.editMode) private var editMode
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 序号（始终显示）
            Text("\(position)")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // 封面占位符 - 升级版
            RoundedRectangle(cornerRadius: 6)
                .fill(AppColors.adaptiveSecondaryBackground)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                )
                .shadow(color: AppColors.lightShadow, radius: 1, x: 0, y: 0.5)
            
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
                Button(action: {
                    HapticManager.shared.listSelection()
                    onPlay()
                }) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .background(AppColors.primaryOpacity08)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(AppleAnimations.microInteraction, value: isPressed)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppleAnimations.microInteraction, value: isPressed)
        .onTapGesture {
            // 只有在非编辑模式下才响应点击播放
            if editMode?.wrappedValue != .active {
                HapticManager.shared.listSelection()
                onPlay()
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("第\(position)首：\(song.title)")
        .accessibilityHint("双击播放")
        .accessibilityAddTraits(.isButton)
    }
}
