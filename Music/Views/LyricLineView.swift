//
//  LyricLineView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 歌词行组件（Apple Music风格升级）
struct LyricLineView: View {
    let lyric: LyricLine
    let isActive: Bool
    let progress: Double
    
    @State private var animationTrigger = false
    @State private var isPressed = false
    
    var body: some View {
        ZStack {
            // 背景高亮（仅活跃行显示）
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.lyricsHighlight)
                    .scaleEffect(1.02)
                    .opacity(0.4)
                    .animation(AppleAnimations.microInteraction, value: isActive)
            }
            
            // 主要文字内容
            Text(lyric.text)
                .font(isActive ? .title3 : .body)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundColor(isActive ? AppColors.primary : .secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .overlay(
                    // 进度高亮效果 - 升级版
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress)
                            .opacity(0.7)
                            .animation(.linear(duration: 0.1), value: progress)
                    }
                    .mask(
                        Text(lyric.text)
                            .font(isActive ? .title3 : .body)
                            .fontWeight(isActive ? .semibold : .regular)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                    )
                    .opacity(isActive ? 1 : 0)
                )
                .scaleEffect(isActive ? 1.05 : 1.0)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .animation(AppleAnimations.standardTransition, value: isActive)
                .animation(AppleAnimations.microInteraction, value: isPressed)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // 点击动画效果和触觉反馈
            HapticManager.shared.lyricBeat()
            
            withAnimation(AppleAnimations.microInteraction) {
                animationTrigger.toggle()
            }
        }
        .simultaneousGesture(
            // 按压效果
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(AppleAnimations.quickMicro) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(AppleAnimations.quickMicro) {
                        isPressed = false
                    }
                }
        )
        // 可访问性支持
        .accessibilityElement(children: .combine)
        .accessibilityLabel("歌词：\(lyric.text)")
        .accessibilityHint(isActive ? "当前歌词" : "双击跳转到此处")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isActive ? "正在播放" : "")
    }
}

// MARK: - 预览
struct LyricLineView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 活跃状态歌词
            LyricLineView(
                lyric: LyricLine(time: 15, text: "这是当前播放的歌词行，应该高亮显示"),
                isActive: true,
                progress: 0.6
            )
            
            // 普通状态歌词
            LyricLineView(
                lyric: LyricLine(time: 20, text: "这是普通的歌词行"),
                isActive: false,
                progress: 0
            )
            
            // 长歌词测试
            LyricLineView(
                lyric: LyricLine(time: 25, text: "这是一行比较长的歌词，用来测试换行和布局效果，看看在不同屏幕尺寸下的表现如何"),
                isActive: false,
                progress: 0
            )
        }
        .padding()
        .background(AppColors.adaptiveBackground)
        .previewLayout(.sizeThatFits)
    }
}
