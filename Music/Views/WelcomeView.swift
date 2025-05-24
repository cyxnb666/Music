//
//  WelcomeView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 欢迎界面
struct WelcomeView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @State private var showingMusicPicker = false
    @State private var showingLyricsPicker = false
    @State private var showingLyricsInfo = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("欢迎使用音乐播放器")
                .font(.title)
                .fontWeight(.bold)
            
            Text("导入您的音乐文件开始播放")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                Button(action: {
                    print("点击导入音乐文件按钮")
                    showingMusicPicker = true
                }) {
                    Label("导入音乐文件", systemImage: "music.note.list")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                // 如果已经有音乐，显示导入歌词选项
                if musicPlayer.currentSong != nil {
                    VStack(spacing: 12) {
                        Button(action: {
                            showingLyricsPicker = true
                        }) {
                            Label("导入歌词文件", systemImage: "text.quote")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showingLyricsInfo = true
                        }) {
                            Text("❓ 什么是歌词文件？")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
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
            Text("歌词文件使用.lrc格式，内容示例：\n[00:12.50]第一句歌词\n[00:17.20]第二句歌词\n\n时间格式：[分钟:秒.毫秒]")
        }
    }
}
