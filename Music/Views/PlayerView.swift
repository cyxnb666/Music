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
    
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 播放器主体 - 固定布局，无滚动
                VStack(spacing: 0) {
                    // 拖拽指示器
                    VStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .padding(.top, 60) // 调整位置避开灵动岛
                    }
                    .frame(height: 80) // 固定高度
                    
                    // 主要内容区域 - 固定布局
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // 封面图片
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppColors.primaryGradient)
                            .frame(width: min(280, geometry.size.width - 60), height: min(280, geometry.size.width - 60))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(musicPlayer.isPlaying ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: musicPlayer.isPlaying)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Spacer().frame(height: 30)
                        
                        // 歌曲信息
                        VStack(spacing: 8) {
                            Text(musicPlayer.currentSong?.title ?? "未知歌曲")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            
                            Text(musicPlayer.currentSong?.artist ?? "未知艺术家")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // 歌词状态指示
                            if !musicPlayer.lyrics.isEmpty {
                                Text("✓ 已加载歌词")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Text("无歌词文件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 80) // 固定高度
                        
                        Spacer().frame(height: 20)
                        
                        // 进度条板块 - 独立组件
                        ProgressSection(
                            currentTime: Binding(
                                get: { musicPlayer.currentTime },
                                set: { _ in } // 只读绑定，实际更新通过onSeek
                            ),
                            duration: musicPlayer.duration,
                            onSeek: { time in
                                musicPlayer.seekTo(time: time)
                            }
                        )
                        
                        Spacer().frame(height: 30)
                        
                        // 主要控制按钮
                        HStack(spacing: 50) {
                            Button(action: {
                                musicPlayer.previousTrack()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                            
                            Button(action: {
                                musicPlayer.togglePlayPause()
                            }) {
                                Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(AppColors.primary)
                            }
                            .scaleEffect(musicPlayer.isPlaying ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: musicPlayer.isPlaying)
                            
                            Button(action: {
                                musicPlayer.nextTrack()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(height: 80) // 固定高度
                        
                        Spacer().frame(height: 40)
                        
                        // 功能按钮 - 歌词和队列并排
                        HStack(spacing: 60) {
                            Button(action: {
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
                            
                            Button(action: {
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
                        }
                        .frame(height: 60) // 固定高度
                        
                        // 底部安全区域
                        Spacer().frame(height: 50)
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
            .clipShape(RoundedRectangle(cornerRadius: 16)) // 顶部圆角
            .offset(y: max(0, dragOffset.height)) // 只允许向下偏移
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        // 只允许向下拖拽，且只在垂直拖拽时响应
                        if value.translation.height > 0 && abs(value.translation.height) > abs(value.translation.width) {
                            dragOffset = value.translation
                        }
                    }
                    .onEnded { value in
                        // 如果拖拽距离超过阈值或拖拽速度足够快，则关闭播放器
                        if value.translation.height > 150 || value.predictedEndTranslation.height > 300 {
                            onDismiss()
                        } else {
                            // 否则回弹到原位
                            withAnimation(.easeOut(duration: 0.3)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
        .sheet(isPresented: $showingLyrics) {
            LyricsView()
                .environmentObject(musicPlayer)
        }
        .sheet(isPresented: $showingLyricsPicker) {
            LyricsDocumentPicker { urls in
                if let url = urls.first {
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
    }
}
