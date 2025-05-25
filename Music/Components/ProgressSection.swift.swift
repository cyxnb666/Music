//
//  ProgressSection.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 进度条板块组件（紧凑版）
struct ProgressSection: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    
    var body: some View {
        VStack(spacing: 0) { // 改为0间距
            // 可拖拽进度条
            DraggableProgressView(
                currentTime: $currentTime,
                duration: duration,
                onSeek: onSeek
            )
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - 预览
struct ProgressSection_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ProgressSection(
                currentTime: .constant(120),
                duration: 240,
                onSeek: { time in
                    print("Seek to: \(time)")
                }
            )
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
}
