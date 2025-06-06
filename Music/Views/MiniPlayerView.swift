//  MiniPlayerView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 迷你播放器（底部悬浮矩形样式）
struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    let namespace: Namespace.ID
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 封面 - 英雄动画支持
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.primaryGradient)
                .frame(width: 48, height: 48) // Apple标准48pt
                .matchedGeometryEffect(id: "albumArt", in: namespace)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .matchedGeometryEffect(id: "musicIcon", in: namespace)
                )
                .scaleEffect(musicPlayer.isPlaying ? 1.0 : 0.95)
                .animation(AppleAnimations.microInteraction, value: musicPlayer.isPlaying)
                .shadow(color: AppColors.lightShadow, radius: 4, x: 0, y: 2)
            
            // 歌曲信息 - 英雄动画支持
            VStack(alignment: .leading, spacing: 4) {
                Text(musicPlayer.currentSong?.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                    .matchedGeometryEffect(id: "songTitle", in: namespace)
                
                HStack(spacing: 6) {
                    Text(musicPlayer.currentSong?.artist ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .matchedGeometryEffect(id: "artistName", in: namespace)
                    
                    if !musicPlayer.lyrics.isEmpty {
                        Image(systemName: "text.quote")
                            .font(.caption2)
                            .foregroundColor(AppColors.success)
                            .scaleEffect(1.1)
                            .animation(AppleAnimations.quickMicro, value: !musicPlayer.lyrics.isEmpty)
                    }
                }
            }
            
            Spacer()
            
            // 简化的进度条
            VStack(spacing: 2) {
                ProgressView(value: musicPlayer.currentTime, total: musicPlayer.duration)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
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
                    HapticManager.shared.playControl()
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .matchedGeometryEffect(id: "playButton", in: namespace)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(musicPlayer.isPlaying ? 1.1 : 1.0)
                .animation(AppleAnimations.microInteraction, value: musicPlayer.isPlaying)
                .accessibilityLabel(musicPlayer.isPlaying ? "暂停" : "播放")
                .accessibilityAddTraits(.isButton)
                
                Button(action: {
                    HapticManager.shared.trackChange()
                    musicPlayer.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("下一首")
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12) // Apple标准12pt圆角
                .fill(AppColors.adaptiveBackground)
                .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .frame(height: 64) // Apple标准64pt高度
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .gesture(
            // 添加轻微的按压反馈
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    // 按压时轻微缩放
                }
                .onEnded { value in
                    // 如果移动距离很小，认为是点击
                    if abs(value.translation.width) < 10 && abs(value.translation.height) < 10 {
                        onTap()
                    }
                }
        )
        // 可访问性支持
        .accessibilityElement(children: .combine)
        .accessibilityLabel("迷你播放器")
        .accessibilityHint("双击打开全屏播放器")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(musicPlayer.isPlaying ? "正在播放" : "已暂停")
        // 自定义可访问性操作
        .accessibilityAction(named: "播放或暂停") {
            HapticManager.shared.playControl()
            musicPlayer.togglePlayPause()
        }
        .accessibilityAction(named: "下一首") {
            HapticManager.shared.trackChange()
            musicPlayer.nextTrack()
        }
        .accessibilityAction(named: "上一首") {
            HapticManager.shared.trackChange()
            musicPlayer.previousTrack()
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 预览
struct MiniPlayerView_Previews: PreviewProvider {
    @Namespace static var namespace
    
    static var previews: some View {
        VStack {
            Spacer()
            MiniPlayerView(namespace: namespace) {
                print("Tapped mini player")
            }
            .environmentObject({
                let player = MusicPlayer()
                player.currentSong = Song(title: "测试歌曲", artist: "测试艺术家", url: URL(fileURLWithPath: ""))
                player.currentTime = 120
                player.duration = 240
                player.isPlaying = true
                return player
            }())
        }
        .background(AppColors.adaptiveSecondaryBackground)
        .previewLayout(.sizeThatFits)
    }
}
