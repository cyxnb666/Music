//
//  DraggableProgressView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 可拖拽进度条（Apple Music风格）
struct DraggableProgressView: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isTouching = false           // 是否正在触摸
    @State private var isDragging = false           // 是否正在拖拽移动
    @State private var dragStartTime: TimeInterval = 0  // 拖拽开始时的播放时间
    @State private var dragCurrentTime: TimeInterval = 0 // 拖拽过程中的时间
    @State private var startDragPoint: CGPoint = .zero   // 拖拽起始点
    @State private var hasTriggeredHaptic = false  // 是否已触发触觉反馈
    
    private let minDragDistance: CGFloat = 8  // Apple标准最小拖拽距离
    
    private var displayTime: TimeInterval {
        isDragging ? dragCurrentTime : currentTime
    }
    
    private var progress: Double {
        guard duration > 0 else { return 0 }
        return displayTime / duration
    }
    
    var body: some View {
        VStack(spacing: 0) { // 完全贴近，没有间距
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    RoundedRectangle(cornerRadius: getCornerRadius())
                        .fill(AppColors.progressTrack)
                        .frame(height: getTrackHeight())
                    
                    // 已播放进度
                    RoundedRectangle(cornerRadius: getCornerRadius())
                        .fill(AppColors.progressFill)
                        .frame(
                            width: geometry.size.width * progress,
                            height: getTrackHeight()
                        )
                    
                    // 拖拽指示器（只在拖拽时显示）
                    if isDragging {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 20, height: 20)
                            .shadow(color: AppColors.cardShadow, radius: 4, x: 0, y: 2)
                            .position(
                                x: geometry.size.width * progress,
                                y: getTrackHeight() / 2
                            )
                            .scaleEffect(isTouching ? 1.2 : 1.0)
                            .animation(AppleAnimations.microInteraction, value: isTouching)
                    }
                }
                .contentShape(Rectangle()) // 扩大点击区域
                .gesture(createProgressGesture(geometry: geometry))
            }
            .frame(height: 30) // Apple标准触摸区域
            .animation(AppleAnimations.progressDrag, value: isTouching)
            .animation(AppleAnimations.progressDrag, value: isDragging)
            
            // 时间显示
            HStack {
                Text(formatTime(displayTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                Text(formatRemainingTime(displayTime, duration: duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.top, -8) // 让时间显示更贴近进度条
            .animation(AppleAnimations.quickMicro, value: isDragging)
        }
    }
    
    // MARK: - 创建进度条手势
    private func createProgressGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                // 首次触摸
                if !isTouching {
                    isTouching = true
                    startDragPoint = value.startLocation
                    dragStartTime = currentTime
                    dragCurrentTime = currentTime
                    hasTriggeredHaptic = false
                    
                    // 准备触觉反馈
                    HapticManager.shared.prepare()
                    HapticManager.shared.buttonTap()
                }
                
                // 检查是否开始真正的拖拽
                let dragDistance = sqrt(
                    pow(value.location.x - startDragPoint.x, 2) +
                    pow(value.location.y - startDragPoint.y, 2)
                )
                
                // 只有拖拽距离超过阈值才开始改变进度
                if dragDistance > minDragDistance && !isDragging {
                    isDragging = true
                    if !hasTriggeredHaptic {
                        HapticManager.shared.dragStart()
                        hasTriggeredHaptic = true
                    }
                }
                
                // 如果正在拖拽，基于相对偏移计算新的时间
                if isDragging {
                    let dragOffsetX = value.location.x - startDragPoint.x
                    let timeOffset = (dragOffsetX / geometry.size.width) * duration
                    let newTime = max(0, min(duration, dragStartTime + timeOffset))
                    dragCurrentTime = newTime
                    
                    // 提供连续的轻微触觉反馈（节制使用）
                    let progressChanged = abs(newTime - dragStartTime) / duration
                    if progressChanged > 0.05 { // 每5%进度变化给一次反馈
                        HapticManager.shared.selectionChanged()
                        dragStartTime = newTime // 重置起点以避免频繁触发
                    }
                }
            }
            .onEnded { _ in
                // 只有真正拖拽了才应用结果
                if isDragging {
                    onSeek(dragCurrentTime)
                    HapticManager.shared.dragEnd()
                    
                    // 延长 isDragging 状态，等待播放器更新位置
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isDragging = false
                    }
                } else {
                    // 如果没有拖拽，可能是点击操作
                    let tapPosition = startDragPoint.x / geometry.size.width
                    let tapTime = tapPosition * duration
                    onSeek(tapTime)
                    HapticManager.shared.selectionChanged()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isDragging = false
                    }
                }
                
                // 重置触摸状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isTouching = false
                    hasTriggeredHaptic = false
                }
            }
    }
    
    // MARK: - 辅助方法
    
    /// 根据状态返回进度条高度
    private func getTrackHeight() -> CGFloat {
        if isDragging {
            return 6 // 拖拽时更粗
        } else if isTouching {
            return 4 // 触摸时中等
        } else {
            return 3 // 基础状态最细
        }
    }
    
    /// 根据状态返回圆角半径
    private func getCornerRadius() -> CGFloat {
        return getTrackHeight() / 2
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func formatRemainingTime(_ currentTime: TimeInterval, duration: TimeInterval) -> String {
        let remaining = duration - currentTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "-%01d:%02d", minutes, seconds)
    }
}

// MARK: - 预览
struct DraggableProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            DraggableProgressView(
                currentTime: .constant(120),
                duration: 240,
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
            
            DraggableProgressView(
                currentTime: .constant(0),
                duration: 180,
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
            .preferredColorScheme(.dark)
        }
        .background(AppColors.adaptiveBackground)
    }
}
