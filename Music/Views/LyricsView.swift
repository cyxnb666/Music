//
//  LyricsView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 歌词界面（Apple Music风格）
struct LyricsView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @Environment(\.dismiss) private var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var showingScrollIndicator = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                AppColors.adaptiveBackground
                    .ignoresSafeArea()
                
                if musicPlayer.lyrics.isEmpty {
                    // 空状态视图
                    emptyLyricsView
                } else {
                    // 歌词内容
                    lyricsContent
                }
                
                // 滚动指示器
                if showingScrollIndicator {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ScrollIndicator()
                                .padding(.trailing, 20)
                                .padding(.bottom, 100)
                        }
                    }
                    .transition(.opacity)
                    .animation(AppleAnimations.quickMicro, value: showingScrollIndicator)
                }
            }
            .navigationTitle("歌词")
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
    
    // MARK: - 空状态视图
    private var emptyLyricsView: some View {
        VStack(spacing: 24) {
            // 图标
            ZStack {
                Circle()
                    .fill(AppColors.primaryOpacity08)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "text.quote")
                    .font(.system(size: 30))
                    .foregroundColor(AppColors.primary)
            }
            
            // 提示文字
            VStack(spacing: 8) {
                Text("暂无歌词")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("您可以在播放器界面导入 .lrc 歌词文件")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // 当前歌曲信息
            if let currentSong = musicPlayer.currentSong {
                VStack(spacing: 4) {
                    Text(currentSong.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(currentSong.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.adaptiveSecondaryBackground)
                )
            }
        }
        .transition(.scale.combined(with: .opacity))
        .animation(AppleAnimations.standardTransition, value: musicPlayer.lyrics.isEmpty)
    }
    
    // MARK: - 歌词内容
    private var lyricsContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 顶部间距
                    Spacer()
                        .frame(height: 40)
                    
                    // 歌词行
                    ForEach(Array(musicPlayer.lyrics.enumerated()), id: \.offset) { index, lyric in
                        LyricLineView(
                            lyric: lyric,
                            isActive: index == musicPlayer.currentLyricIndex,
                            progress: index == musicPlayer.currentLyricIndex ? musicPlayer.lyricProgress : 0
                        )
                        .id(index)
                        .onTapGesture {
                            HapticManager.shared.selectionChanged()
                            musicPlayer.seekToLyric(at: index)
                            
                            // 轻微的视觉反馈
                            withAnimation(AppleAnimations.microInteraction) {
                                // 可以添加点击效果
                            }
                        }
                        .animation(
                            AppleAnimations.staggeredListAnimation(index: index, stagger: 0.02),
                            value: musicPlayer.lyrics.count
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("歌词：\(lyric.text)")
                        .accessibilityHint(index == musicPlayer.currentLyricIndex ? "当前歌词" : "双击跳转到此处")
                        .accessibilityAddTraits(.isButton)
                    }
                    
                    // 底部间距
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
            .background(
                // 渐变遮罩效果
                VStack {
                    LinearGradient(
                        colors: [AppColors.adaptiveBackground, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)
                    
                    Spacer()
                    
                    LinearGradient(
                        colors: [Color.clear, AppColors.adaptiveBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 50)
                }
                .allowsHitTesting(false)
            )
            .onChange(of: musicPlayer.currentLyricIndex) { oldValue, newValue in
                // 自动滚动到当前歌词
                withAnimation(AppleAnimations.lyricsScroll) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
                
                // 显示滚动指示器
                showScrollIndicator()
            }
            .onAppear {
                // 初始滚动到当前歌词
                if musicPlayer.currentLyricIndex < musicPlayer.lyrics.count {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(AppleAnimations.lyricsScroll) {
                            proxy.scrollTo(musicPlayer.currentLyricIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 显示滚动指示器
    private func showScrollIndicator() {
        showingScrollIndicator = true
        
        // 2秒后隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(AppleAnimations.quickMicro) {
                showingScrollIndicator = false
            }
        }
    }
}

// LyricLineView 已在单独的文件中定义，这里不需要重复定义

// MARK: - 滚动指示器
struct ScrollIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("自动滚动")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.adaptiveSecondaryBackground)
                .shadow(color: AppColors.lightShadow, radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

// MARK: - 预览
struct LyricsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // 有歌词的预览
            LyricsView()
                .environmentObject({
                    let player = MusicPlayer()
                    player.currentSong = Song(title: "测试歌曲", artist: "测试艺术家", url: URL(fileURLWithPath: ""))
                    player.lyrics = [
                        LyricLine(time: 0, text: "这是第一句歌词"),
                        LyricLine(time: 5, text: "这是第二句歌词，可能会比较长一些用来测试换行效果"),
                        LyricLine(time: 10, text: "这是第三句歌词"),
                        LyricLine(time: 15, text: "当前播放的歌词"),
                        LyricLine(time: 20, text: "这是第五句歌词")
                    ]
                    player.currentLyricIndex = 3
                    player.lyricProgress = 0.6
                    return player
                }())
                .preferredColorScheme(.light)
            
            // 无歌词的预览
            LyricsView()
                .environmentObject({
                    let player = MusicPlayer()
                    player.currentSong = Song(title: "无歌词歌曲", artist: "测试艺术家", url: URL(fileURLWithPath: ""))
                    return player
                }())
                .preferredColorScheme(.dark)
        }
    }
}
