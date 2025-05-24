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
    @State private var showingMusicPicker = false
    @State private var showingLyricsPicker = false
    @State private var showingLyricsInfo = false
    @State private var dragOffset: CGSize = .zero
    
    let onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 顶部留白区域 - 类似Apple Music的设计
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 60) // 保留顶部空间，类似截图中的白色区域
                
                // 播放器主体
                VStack(spacing: 0) {
                    // 拖拽指示器和关闭按钮
                    VStack(spacing: 12) {
                        // 拖拽指示器
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 40, height: 4)
                            .padding(.top, 8)
                        
                        // 关闭按钮
                        HStack {
                            Button(action: {
                                onDismiss()
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text("正在播放")
                                .font(.headline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            // 占位符，保持布局平衡
                            Image(systemName: "chevron.down")
                                .font(.title2)
                                .opacity(0)
                        }
                        .padding(.horizontal)
                    }
                    .background(Color(UIColor.systemBackground))
                    
                    // 播放器内容
                    ScrollView {
                        VStack(spacing: 30) {
                            Spacer(minLength: 20)
                            
                            // 封面图片
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 280, height: 280)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                )
                                .scaleEffect(musicPlayer.isPlaying ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: musicPlayer.isPlaying)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            
                            // 歌曲信息
                            VStack(spacing: 8) {
                                Text(musicPlayer.currentSong?.title ?? "未知歌曲")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                
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
                            
                            // 进度条
                            VStack(spacing: 8) {
                                ProgressView(value: musicPlayer.currentTime, total: musicPlayer.duration)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                
                                HStack {
                                    Text(formatTime(musicPlayer.currentTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(formatTime(musicPlayer.duration))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // 控制按钮
                            HStack(spacing: 40) {
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
                                        .font(.system(size: 60))
                                        .foregroundColor(.blue)
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
                            
                            Divider()
                                .padding(.horizontal)
                            
                            // 功能按钮
                            HStack(spacing: 30) {
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
                                            .foregroundColor(.blue)
                                        Text(musicPlayer.lyrics.isEmpty ? "导入歌词" : "查看歌词")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Button(action: {
                                    showingLyricsInfo = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "questionmark.circle")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        Text("歌词格式")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Button(action: {
                                    showingMusicPicker = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus.circle")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                        Text("换歌曲")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 50)
                        }
                    }
                    .scrollDisabled(abs(dragOffset.height) > 10) // 拖拽时禁用滚动
                }
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16)) // 顶部圆角
            }
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
        .sheet(isPresented: $showingMusicPicker) {
            MusicDocumentPicker { urls in
                if let url = urls.first {
                    musicPlayer.handleFileImport(url)
                }
            }
        }
        .sheet(isPresented: $showingLyricsPicker) {
            LyricsDocumentPicker { urls in
                if let url = urls.first {
                    musicPlayer.handleLyricsImport(url)
                }
            }
        }
        .alert("LRC歌词文件格式", isPresented: $showingLyricsInfo) {
            Button("知道了") { }
        } message: {
            Text("歌词文件使用.lrc格式，内容示例：\n\n[00:12.50]第一句歌词\n[00:17.20]第二句歌词\n[00:21.80]第三句歌词\n\n时间格式：[分钟:秒.毫秒]歌词内容\n\n你可以从网上下载对应歌曲的.lrc文件，或自己制作。")
        }
        .onAppear {
            dragOffset = .zero
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
