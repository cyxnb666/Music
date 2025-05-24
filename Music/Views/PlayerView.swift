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
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
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
            
            // 歌曲信息
            VStack(spacing: 8) {
                Text(musicPlayer.currentSong?.title ?? "未知歌曲")
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
            .padding(.horizontal)
            
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
                
                Button(action: {
                    musicPlayer.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            
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
            
            Spacer()
        }
        .padding()
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
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
