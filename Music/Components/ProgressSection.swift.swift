//
//  ProgressSection.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 进度条板块组件（Apple Music风格）
struct ProgressSection: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isInteracting = false
    @State private var showingTimeTooltip = false
    @State private var tooltipTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 时间信息栏（顶部）
            timeInfoView
                .opacity(isInteracting ? 1.0 : 0.8)
                .animation(AppleAnimations.quickMicro, value: isInteracting)
            
            Spacer().frame(height: 12)
            
            // 可拖拽进度条
            DraggableProgressView(
                currentTime: $currentTime,
                duration: duration,
                onSeek: { time in
                    onSeek(time)
                    
                    // 显示时间提示
                    tooltipTime = time
                    showTooltip()
                }
            )
            .padding(.horizontal, 30)
            .onChange(of: currentTime) { oldValue, newValue in
                // 检测用户是否在拖拽
                let timeDiff = abs(newValue - oldValue)
                if timeDiff > 1.0 { // 如果时间跳跃超过1秒，可能是用户操作
                    tooltipTime = newValue
                    showTooltip()
                }
            }
            
            Spacer().frame(height: 8)
            
            // 播放统计信息（可选显示）
            if duration > 0 {
                playbackStatsView
                    .opacity(0.6)
                    .animation(AppleAnimations.standardTransition, value: duration)
            }
        }
        .overlay(
            // 时间提示浮窗
            timeTooltip,
            alignment: .top
        )
    }
    
    // MARK: - 时间信息栏
    private var timeInfoView: some View {
        HStack {
            // 当前播放时间
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(currentTime))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .monospacedDigit()
                
                Text("已播放")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 进度百分比（中央）
            VStack(spacing: 2) {
                Text("\(Int((currentTime / max(duration, 1)) * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary)
                    .monospacedDigit()
                
                Text("进度")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .opacity(duration > 0 ? 1 : 0)
            
            Spacer()
            
            // 剩余时间
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatRemainingTime(currentTime, duration: duration))
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .monospacedDigit()
                
                Text("剩余")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - 播放统计信息
    private var playbackStatsView: some View {
        HStack {
            // 总时长
            Label {
                Text(formatTime(duration))
                    .font(.caption)
                    .monospacedDigit()
            } icon: {
                Image(systemName: "clock")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            // 音频格式（如果可用）
            Label {
                Text("音频")
                    .font(.caption)
            } icon: {
                Image(systemName: "waveform")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            // 播放模式指示（可选）
            Label {
                Text("立体声")
                    .font(.caption)
            } icon: {
                Image(systemName: "speaker.2")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 30)
        .padding(.top, 4)
    }
    
    // MARK: - 时间提示浮窗
    private var timeTooltip: some View {
        Group {
            if showingTimeTooltip {
                VStack(spacing: 4) {
                    Text(formatTime(tooltipTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                    
                    Text("跳转到此时间")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppColors.adaptiveSecondaryBackground)
                        .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
                )
                .transition(.scale.combined(with: .opacity))
                .animation(AppleAnimations.microInteraction, value: showingTimeTooltip)
            }
        }
    }
    
    // MARK: - 辅助方法
    
    /// 显示时间提示
    private func showTooltip() {
        showingTimeTooltip = true
        
        // 1.5秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(AppleAnimations.quickMicro) {
                showingTimeTooltip = false
            }
        }
    }
    
    /// 格式化时间显示
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /// 格式化剩余时间
    private func formatRemainingTime(_ currentTime: TimeInterval, duration: TimeInterval) -> String {
        let remaining = max(0, duration - currentTime)
        let totalSeconds = Int(remaining)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "-%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "-%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - 预览
struct ProgressSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // 正常播放状态
            ProgressSection(
                currentTime: .constant(125),
                duration: 245,
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
            
            // 长时间音频
            ProgressSection(
                currentTime: .constant(3725), // 1小时2分5秒
                duration: 7200, // 2小时
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
            
            // 开始状态
            ProgressSection(
                currentTime: .constant(0),
                duration: 180,
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
        }
        .background(AppColors.adaptiveBackground)
        .previewLayout(.sizeThatFits)
    }
}
