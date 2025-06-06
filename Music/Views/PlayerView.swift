//
//  PlayerView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 播放器界面
struct PlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @State private var showingLyrics = false
    @State private var showingLyricsPicker = false
    @State private var showingQueue = false
    @State private var dragOffset: CGSize = .zero
    @GestureState private var gestureOffset: CGSize = .zero
    
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    // MARK: - Apple标准手势阈值
    private let dismissThreshold: CGFloat = 150
    private let velocityThreshold: CGFloat = 1000
    private let dragIndicatorHeight: CGFloat = 5
    private let dragIndicatorWidth: CGFloat = 36
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 播放器主体 - 固定布局，无滚动
                VStack(spacing: 0) {
                    // 拖拽指示器
                    VStack {
                        RoundedRectangle(cornerRadius: dragIndicatorHeight / 2)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: dragIndicatorWidth, height: dragIndicatorHeight)
                            .padding(.top, 60) // 调整位置避开灵动岛
                    }
                    .frame(height: 80) // 固定高度
                    
                    // 主要内容区域 - 固定布局
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // 封面图片 - 英雄动画
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.primaryGradient)
                            .frame(width: min(280, geometry.size.width - 60), height: min(280, geometry.size.width - 60))
                            .matchedGeometryEffect(id: "albumArt", in: namespace)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                                    .matchedGeometryEffect(id: "musicIcon", in: namespace)
                            )
                            .scaleEffect(musicPlayer.isPlaying ? 1.05 : 1.0)
                            .animation(AppleAnimations.standardTransition, value: musicPlayer.isPlaying)
                            .shadow(color: AppColors.deepShadow, radius: 20, x: 0, y: 10)
                            .rotation3DEffect(
                                .degrees(Double(dragOffset.height + gestureOffset.height) * 0.05),
                                axis: (x: 1, y: 0, z: 0)
                            )
                        
                        Spacer().frame(height: 30)
                        
                        // 歌曲信息 - 英雄动画
                        VStack(spacing: 8) {
                            Text(musicPlayer.currentSong?.title ?? "未知歌曲")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .matchedGeometryEffect(id: "songTitle", in: namespace)
                            
                            Text(musicPlayer.currentSong?.artist ?? "未知艺术家")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .matchedGeometryEffect(id: "artistName", in: namespace)
                            
                            // 歌词状态指示
                            if !musicPlayer.lyrics.isEmpty {
                                Text("✓ 已加载歌词")
                                    .font(.caption)
                                    .foregroundColor(AppColors.success)
                                    .scaleEffect(1.05)
                                    .animation(AppleAnimations.microInteraction, value: !musicPlayer.lyrics.isEmpty)
                            } else {
                                Text("无歌词文件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 80) // 固定高度
                        .opacity(1.0 - Double(abs(dragOffset.height + gestureOffset.height)) / 300)
                        
                        Spacer().frame(height: 20)
                        
                        // 进度条板块 - 独立组件
                        ProgressSection(
                            currentTime: Binding(
                                get: { musicPlayer.currentTime },
                                set: { _ in } // 只读绑定，实际更新通过onSeek
                            ),
                            duration: musicPlayer.duration,
                            onSeek: { time in
                                HapticManager.shared.selectionChanged()
                                musicPlayer.seekTo(time: time)
                            }
                        )
                        .opacity(1.0 - Double(abs(dragOffset.height + gestureOffset.height)) / 400)
                        
                        Spacer().frame(height: 30)
                        
                        // 主要控制按钮
                        HStack(spacing: 50) {
                            Button(action: {
                                HapticManager.shared.trackChange()
                                musicPlayer.previousTrack()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .scaleEffect(0.9 + Double(abs(dragOffset.height + gestureOffset.height)) / 1000)
                            .accessibilityLabel("上一首")
                            .accessibilityAddTraits(.isButton)
                            
                            Button(action: {
                                HapticManager.shared.playControl()
                                musicPlayer.togglePlayPause()
                            }) {
                                Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(AppColors.primary)
                                    .matchedGeometryEffect(id: "playButton", in: namespace)
                            }
                            .scaleEffect(musicPlayer.isPlaying ? 1.1 : 1.0)
                            .animation(AppleAnimations.microInteraction, value: musicPlayer.isPlaying)
                            .accessibilityLabel(musicPlayer.isPlaying ? "暂停" : "播放")
                            .accessibilityAddTraits(.isButton)
                            
                            Button(action: {
                                HapticManager.shared.trackChange()
                                musicPlayer.nextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            .scaleEffect(0.9 + Double(abs(dragOffset.height + gestureOffset.height)) / 1000)
                            .accessibilityLabel("下一首")
                            .accessibilityAddTraits(.isButton)
                        }
                        .frame(height: 80) // 固定高度
                        
                        Spacer().frame(height: 40)
                        
                        // 功能按钮 - 歌词和队列并排
                        HStack(spacing: 60) {
                            Button(action: {
                                HapticManager.shared.buttonTap()
                                if musicPlayer.lyrics.isEmpty {
                                    showingLyricsPicker = true
                                } else {
                                    showingLyrics = true
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: musicPlayer.lyrics.isEmpty ? "text.quote" : "text.book.closed")
                                        .font(.title3)
                                        .foregroundColor(AppColors.primary)
                                    Text(musicPlayer.lyrics.isEmpty ? "导入歌词" : "查看歌词")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .accessibilityLabel("歌词")
                            .accessibilityAddTraits(.isButton)
                            .scaleEffect(0.95 + Double(abs(dragOffset.height + gestureOffset.height)) / 2000)
                            
                            Button(action: {
                                HapticManager.shared.buttonTap()
                                showingQueue = true
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "list.number")
                                        .font(.title3)
                                        .foregroundColor(AppColors.primary)
                                    Text("播放队列")
                                        .font(.caption)
                                        .foregroundColor(AppColors.primary)
                                }
                            }
                            .accessibilityLabel("播放队列")
                            .accessibilityAddTraits(.isButton)
                            .scaleEffect(0.95 + Double(abs(dragOffset.height + gestureOffset.height)) / 2000)
                        }
                        .frame(height: 60) // 固定高度
                        .opacity(1.0 - Double(abs(dragOffset.height + gestureOffset.height)) / 250)
                        
                        // 底部安全区域
                        Spacer().frame(height: 50)
                    }
                }
                .background(AppColors.adaptiveBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20)) // Apple标准20pt圆角
            .offset(y: max(0, dragOffset.height + gestureOffset.height)) // 只允许向下偏移
            .gesture(createDragGesture())
        }
        // Sheet展示
        .sheet(isPresented: $showingLyrics) {
            LyricsView()
                .environmentObject(musicPlayer)
        }
        .sheet(isPresented: $showingLyricsPicker) {
            LyricsDocumentPicker { urls in
                if let url = urls.first {
                    HapticManager.shared.fileImport()
                    musicPlayer.handleLyricsImport(url)
                }
            }
        }
        .sheet(isPresented: $showingQueue) {
            PlaybackQueueView()
                .environmentObject(musicPlayer)
        }
        .onAppear {
            dragOffset = .zero
        }
        // 可访问性支持
        .accessibilityElement(children: .contain)
        .accessibilityLabel("全屏播放器")
        .accessibilityHint("向下拖拽可关闭播放器")
        .accessibilityAddTraits(.allowsDirectInteraction)
        .accessibilityAction(named: "关闭播放器") {
            HapticManager.shared.playerClose()
            onDismiss()
        }
    }
    
    // MARK: - 创建拖拽手势
    private func createDragGesture() -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($gestureOffset) { value, state, _ in
                // 只允许向下拖拽，且只在垂直拖拽时响应
                if value.translation.height > 0 && abs(value.translation.height) > abs(value.translation.width) {
                    state = value.translation
                    
                    // 拖拽开始时的触觉反馈
                    if state.height > 10 && dragOffset == .zero {
                        HapticManager.shared.dragStart()
                    }
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let totalOffset = value.translation.height + velocity * 0.1
                
                // 判断是否应该关闭播放器
                if totalOffset > dismissThreshold || velocity > velocityThreshold {
                    HapticManager.shared.success()
                    onDismiss()
                } else {
                    // 回弹到原位
                    HapticManager.shared.selectionChanged()
                    withAnimation(AppleAnimations.standardTransition) {
                        dragOffset = .zero
                    }
                }
            }
    }
}

// MARK: - 预览
struct PlayerView_Previews: PreviewProvider {
    @Namespace static var namespace
    
    static var previews: some View {
        PlayerView(namespace: namespace) {
            print("Dismissed player")
        }
        .environmentObject({
            let player = MusicPlayer()
            player.currentSong = Song(title: "测试歌曲", artist: "测试艺术家", url: URL(fileURLWithPath: ""))
            player.currentTime = 120
            player.duration = 240
            player.isPlaying = true
            return player
        }())
        .preferredColorScheme(.light)
        
        PlayerView(namespace: namespace) {
            print("Dismissed player")
        }
        .environmentObject({
            let player = MusicPlayer()
            player.currentSong = Song(title: "测试歌曲", artist: "测试艺术家", url: URL(fileURLWithPath: ""))
            player.currentTime = 120
            player.duration = 240
            player.isPlaying = false
            return player
        }())
        .preferredColorScheme(.dark)
    }
}
