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
    
    var body: some View {
        HStack {
            // 封面
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                )
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 2) {
                Text(musicPlayer.currentSong?.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack {
                    Text(musicPlayer.currentSong?.artist ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if !musicPlayer.lyrics.isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 15) {
                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    musicPlayer.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.secondary.opacity(0.3)),
            alignment: .top
        )
    }
}
