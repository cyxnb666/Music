//
//  ColorTheme.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 应用颜色主题
struct AppColors {
    // 主色调 - 在这里修改为你喜欢的颜色
    static let primary = Color.purple      // 主要颜色（替换原来的蓝色）
    static let secondary = Color.pink      // 次要颜色（替换原来的紫色）
    
    // 渐变色组合
    static let gradientStart = Color.purple
    static let gradientEnd = Color.pink
    
    // 功能色彩
    static let accent = Color.purple       // 强调色
    static let success = Color.green       // 成功状态（歌词加载成功）
    
    // 创建渐变
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // 半透明版本
    static var primaryOpacity20: Color {
        primary.opacity(0.2)
    }
    
    static var primaryOpacity10: Color {
        primary.opacity(0.1)
    }
    
    static var primaryOpacity30: Color {
        primary.opacity(0.3)
    }
}
