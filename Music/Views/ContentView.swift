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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 主要内容区域
                if songLibrary.hasImportedLibrary {
                    // 如果已导入歌曲库，显示歌曲列表或播放器界面
                    if musicPlayer.currentSong != nil {
                        PlayerView()
                            .environmentObject(musicPlayer)
                    } else {
                        // 显示歌曲列表界面
                        SongListView()
                            .environmentObject(musicPlayer)
                            .environmentObject(songLibrary)
                    }
                } else {
                    // 显示欢迎界面，让用户导入文件夹
                    WelcomeView()
                        .environmentObject(musicPlayer)
                        .environmentObject(songLibrary)
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
        .onReceive(songLibrary.$songs) { songs in
            // 当歌曲库更新时的处理
            if !songs.isEmpty && musicPlayer.currentSong == nil {
                // 暂时不自动播放
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
