//  MiniPlayerView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 迷你播放器（底部悬浮矩形样式）
struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 封面
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )
                .scaleEffect(musicPlayer.isPlaying ? 1.0 : 0.95)
                .animation(.easeInOut(duration: 0.3), value: musicPlayer.isPlaying)
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 4) {
                Text(musicPlayer.currentSong?.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
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
            
            // 简化的进度条
            VStack(spacing: 2) {
                ProgressView(value: musicPlayer.currentTime, total: musicPlayer.duration)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
                
                HStack {
                    Text(formatTime(musicPlayer.currentTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                    Spacer()
                    Text(formatTime(musicPlayer.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(width: 60)
            
            // 控制按钮
            HStack(spacing: 12) {
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
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
