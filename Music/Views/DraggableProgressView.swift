//
//  DraggableProgressView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 可拖拽进度条（紧凑版）
struct DraggableProgressView: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    @State private var isTouching = false           // 是否正在触摸
    @State private var isDragging = false           // 是否正在拖拽移动
    @State private var dragStartTime: TimeInterval = 0  // 拖拽开始时的播放时间
    @State private var dragCurrentTime: TimeInterval = 0 // 拖拽过程中的时间
    @State private var startDragPoint: CGPoint = .zero   // 拖拽起始点
    
    private let minDragDistance: CGFloat = 10  // 最小拖拽距离阈值
    
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
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: getTrackHeight())
                    
                    // 已播放进度
                    RoundedRectangle(cornerRadius: getCornerRadius())
                        .fill(AppColors.primary) // 保持统一的主题色
                        .frame(
                            width: geometry.size.width * progress,
                            height: getTrackHeight()
                        )
                }
                .contentShape(Rectangle()) // 扩大点击区域
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // 首次触摸
                            if !isTouching {
                                isTouching = true
                                startDragPoint = value.startLocation
                                dragStartTime = currentTime // 记录开始拖拽时的播放时间
                                dragCurrentTime = currentTime
                                // 触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }
                            
                            // 检查是否开始真正的拖拽
                            let dragDistance = sqrt(
                                pow(value.location.x - startDragPoint.x, 2) +
                                pow(value.location.y - startDragPoint.y, 2)
                            )
                            
                            // 只有拖拽距离超过阈值才开始改变进度
                            if dragDistance > minDragDistance && !isDragging {
                                isDragging = true
                                // 拖拽开始的触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                            }
                            
                            // 如果正在拖拽，基于相对偏移计算新的时间
                            if isDragging {
                                let dragOffsetX = value.location.x - startDragPoint.x
                                let timeOffset = (dragOffsetX / geometry.size.width) * duration
                                let newTime = max(0, min(duration, dragStartTime + timeOffset))
                                dragCurrentTime = newTime
                            }
                        }
                        .onEnded { _ in
                            // 只有真正拖拽了才应用结果
                            if isDragging {
                                onSeek(dragCurrentTime)
                                
                                // 结束拖拽的触觉反馈
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // 延长 isDragging 状态，等待播放器更新位置
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isDragging = false
                                }
                            } else {
                                // 如果没有拖拽，立即重置触摸状态
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    isDragging = false
                                }
                            }
                            
                            // 重置触摸状态
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                isTouching = false
                            }
                        }
                )
            }
            .frame(height: 30) // 从50减少到30，减少占用空间
            .animation(.easeInOut(duration: 0.15), value: isTouching)
            .animation(.easeInOut(duration: 0.15), value: isDragging)
            
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
            .padding(.top, -8) // 增加负数padding让时间显示更贴近进度条
        }
    }
    
    // 根据状态返回进度条高度
    private func getTrackHeight() -> CGFloat {
        if isDragging || isTouching {
            return 14 // 触摸或拖拽时都是同样粗
        } else {
            return 8 // 基础状态
        }
    }
    
    // 根据状态返回圆角半径
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
        }
    }
}
