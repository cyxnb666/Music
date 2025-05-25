//
//  LyricLineView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 歌词行组件
struct LyricLineView: View {
    let lyric: LyricLine
    let isActive: Bool
    let progress: Double
    
    var body: some View {
        Text(lyric.text)
            .font(isActive ? .title3 : .body)
            .fontWeight(isActive ? .semibold : .regular)
            .foregroundColor(isActive ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .overlay(
                // 进度高亮效果
                GeometryReader { geometry in
                    Rectangle()
                        .fill(AppColors.primaryOpacity30)
                        .frame(width: geometry.size.width * progress)
                        .animation(.linear(duration: 0.1), value: progress)
                }
                .mask(
                    Text(lyric.text)
                        .font(isActive ? .title3 : .body)
                        .fontWeight(isActive ? .semibold : .regular)
                        .multilineTextAlignment(.center)
                )
                .opacity(isActive ? 1 : 0)
            )
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}
