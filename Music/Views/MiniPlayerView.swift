//
//  MiniPlayerView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 迷你播放器
struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 播放进度条
            ProgressView(value: musicPlayer.currentTime, total: musicPlayer.duration)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 2)
            
            // 迷你播放器内容
            HStack(spacing: 12) {
                // 封面
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(musicPlayer.isPlaying ? 1.0 : 0.95)
                    .animation(.easeInOut(duration: 0.3), value: musicPlayer.isPlaying)
                
                // 歌曲信息
                VStack(alignment: .leading, spacing: 2) {
                    Text(musicPlayer.currentSong?.title ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(musicPlayer.currentSong?.artist ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if !musicPlayer.lyrics.isEmpty {
                            Image(systemName: "text.quote")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                // 控制按钮
                HStack(spacing: 20) {
                    Button(action: {
                        musicPlayer.togglePlayPause()
                    }) {
                        Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(musicPlayer.isPlaying ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: musicPlayer.isPlaying)
                    
                    Button(action: {
                        musicPlayer.nextTrack()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
        )
    }
}
