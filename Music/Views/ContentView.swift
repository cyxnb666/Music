//
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
                
                // 迷你播放器（只在歌曲列表界面且有歌曲播放时显示）
                if musicPlayer.currentSong != nil && songLibrary.hasImportedLibrary && !showingFullPlayer {
                    MiniPlayerView(onTap: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showingFullPlayer = true
                        }
                    })
                    .environmentObject(musicPlayer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // 播放器覆盖层 - 完全全屏
            if showingFullPlayer {
                PlayerView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showingFullPlayer = false
                    }
                })
                .environmentObject(musicPlayer)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .bottom)
                ))
                .zIndex(999)
                .ignoresSafeArea(.all) // 完全全屏
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
