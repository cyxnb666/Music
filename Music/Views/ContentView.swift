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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 主要内容区域
                if musicPlayer.currentSong != nil {
                    PlayerView()
                        .environmentObject(musicPlayer)
                } else {
                    WelcomeView()
                        .environmentObject(musicPlayer)
                }
                
                // 迷你播放器（如果有歌曲在播放）
                if musicPlayer.currentSong != nil {
                    MiniPlayerView()
                        .environmentObject(musicPlayer)
                }
            }
            .navigationTitle("我的音乐")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
