//  ContentView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - ContentView.swift (主界面)
struct ContentView: View {
    @StateObject private var musicPlayer = MusicPlayer()
    @StateObject private var songLibrary = SongLibrary()
    @State private var showingFullPlayer = false
    
    // MARK: - 英雄动画命名空间
    @Namespace private var playerNamespace
    
    var body: some View {
        ZStack {
            // 主要内容区域
            VStack(spacing: 0) {
                if songLibrary.hasImportedLibrary {
                    // 显示歌曲列表界面
                    SongListView()
                        .environmentObject(musicPlayer)
                        .environmentObject(songLibrary)
                } else {
                    // 显示欢迎界面，让用户导入文件夹
                    WelcomeView()
                        .environmentObject(musicPlayer)
                        .environmentObject(songLibrary)
                }
                
                // 迷你播放器（底部悬浮，只在歌曲列表界面且有歌曲播放时显示）
                if musicPlayer.currentSong != nil && songLibrary.hasImportedLibrary && !showingFullPlayer {
                    MiniPlayerView(
                        namespace: playerNamespace,
                        onTap: {
                            // 触觉反馈
                            HapticManager.shared.interfaceTransition()
                            
                            // Apple标准播放器转换动画
                            withAnimation(AppleAnimations.playerTransition) {
                                showingFullPlayer = true
                            }
                        }
                    )
                    .environmentObject(musicPlayer)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .animation(AppleAnimations.standardTransition, value: musicPlayer.currentSong != nil)
                }
            }
            .background(AppColors.adaptiveBackground)
            
            // 播放器覆盖层 - 完全全屏
            if showingFullPlayer {
                PlayerView(
                    namespace: playerNamespace,
                    onDismiss: {
                        // 触觉反馈
                        HapticManager.shared.playerClose()
                        
                        // Apple标准播放器关闭动画
                        withAnimation(AppleAnimations.playerTransition) {
                            showingFullPlayer = false
                        }
                    }
                )
                .environmentObject(musicPlayer)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
                .zIndex(999)
                .ignoresSafeArea(.all) // 完全全屏
            }
        }
        .background(AppColors.adaptiveBackground)
        .onAppear {
            // 应用启动时准备触觉反馈
            HapticManager.shared.prepare()
        }
        .onChange(of: musicPlayer.currentSong) { oldValue, newValue in
            // 歌曲变化时的触觉反馈
            if oldValue != nil && newValue != nil && oldValue?.id != newValue?.id {
                HapticManager.shared.trackChange()
            }
        }
        .onChange(of: musicPlayer.isPlaying) { oldValue, newValue in
            // 播放状态变化时的触觉反馈
            if oldValue != newValue {
                HapticManager.shared.playControl()
            }
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
        
        ContentView()
            .preferredColorScheme(.dark)
    }
}
