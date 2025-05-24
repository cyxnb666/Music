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
        NavigationView {
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
                .navigationTitle(songLibrary.hasImportedLibrary && !showingFullPlayer ? "我的音乐" : "")
                .navigationBarTitleDisplayMode(.large)
                
                // 播放器覆盖层 - 占据大部分屏幕但保留顶部状态栏
                if showingFullPlayer {
                    PlayerView(onDismiss: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showingFullPlayer = false
                        }
                    })
                    .environmentObject(musicPlayer)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .zIndex(999)
                }
            }
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
