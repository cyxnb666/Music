//
//  ColorTheme.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - Apple Music风格颜色主题
struct AppColors {
    // MARK: - Apple Music标准颜色
    
    /// Apple Music主红色 #FC3C44
    static let primary = Color(red: 252/255, green: 60/255, blue: 68/255)
    
    /// 次要颜色 - 保持原有的粉色作为辅助色
    static let secondary = Color.pink
    
    // MARK: - 动态适应颜色
    
    /// 适应性背景色 - 根据系统深色/浅色模式自动调整
    static let adaptiveBackground = Color(UIColor.systemBackground)
    
    /// 适应性二级背景色
    static let adaptiveSecondaryBackground = Color(UIColor.secondarySystemBackground)
    
    /// 适应性三级背景色
    static let adaptiveTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    /// 适应性分组背景色
    static let adaptiveGroupedBackground = Color(UIColor.systemGroupedBackground)
    
    // MARK: - 阴影和模糊效果
    
    /// 卡片阴影色 - 标准深度
    static let cardShadow = Color.black.opacity(0.1)
    
    /// 深度阴影色 - 用于悬浮元素
    static let deepShadow = Color.black.opacity(0.2)
    
    /// 轻微阴影色 - 用于微妙的层次
    static let lightShadow = Color.black.opacity(0.05)
    
    // MARK: - 功能色彩
    
    /// 强调色 - 与主色相同
    static let accent = primary
    
    /// 成功状态色 - 绿色（歌词加载成功等）
    static let success = Color.green
    
    /// 警告状态色
    static let warning = Color.orange
    
    /// 错误状态色
    static let error = Color.red
    
    /// 信息状态色
    static let info = Color.blue
    
    // MARK: - 渐变色组合
    
    /// Apple Music风格主渐变
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 柔和渐变 - 用于背景
    static var softGradient: LinearGradient {
        LinearGradient(
            colors: [primary.opacity(0.1), secondary.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// 深度渐变 - 用于覆盖层
    static var depthGradient: LinearGradient {
        LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Apple标准透明度版本
    
    /// 主色 8% 透明度 - 用于微妙背景
    static var primaryOpacity08: Color { primary.opacity(0.08) }
    
    /// 主色 15% 透明度 - 用于悬停状态
    static var primaryOpacity15: Color { primary.opacity(0.15) }
    
    /// 主色 20% 透明度 - 用于选中状态
    static var primaryOpacity20: Color { primary.opacity(0.2) }
    
    /// 主色 30% 透明度 - 用于强调背景
    static var primaryOpacity30: Color { primary.opacity(0.3) }
    
    /// 主色 50% 透明度 - 用于半透明元素
    static var primaryOpacity50: Color { primary.opacity(0.5) }
    
    // MARK: - 保持向后兼容的原有属性
    
    /// 渐变起始色（兼容性）
    static let gradientStart = primary
    
    /// 渐变结束色（兼容性）
    static let gradientEnd = secondary
    
    /// 原有的透明度版本（兼容性）
    static var primaryOpacity10: Color { primary.opacity(0.1) }
    
    // MARK: - 辅助功能颜色
    
    /// 高对比度主色 - 用于辅助功能增强
    static var highContrastPrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.accessibilityContrast == .high ?
                UIColor(red: 200/255, green: 20/255, blue: 30/255, alpha: 1.0) :
                UIColor(red: 252/255, green: 60/255, blue: 68/255, alpha: 1.0)
        })
    }
    
    // MARK: - 动态颜色方法
    
    /// 根据背景亮度自动选择前景色
    /// - Parameter backgroundColor: 背景颜色
    /// - Returns: 适合的前景色
    static func foregroundColor(for backgroundColor: Color) -> Color {
        // 简化实现，实际应用中可以根据背景亮度计算
        return Color.primary
    }
    
    /// 获取适应性的主色调，支持深色模式
    /// - Returns: 适应当前模式的主色
    static var adaptivePrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 255/255, green: 69/255, blue: 77/255, alpha: 1.0) :  // 深色模式稍微亮一点
                UIColor(red: 252/255, green: 60/255, blue: 68/255, alpha: 1.0)    // 浅色模式标准色
        })
    }
    
    // MARK: - 专用场景颜色
    
    /// 迷你播放器背景色
    static var miniPlayerBackground: Color {
        adaptiveBackground
    }
    
    /// 全屏播放器背景色
    static var fullPlayerBackground: Color {
        adaptiveSecondaryBackground
    }
    
    /// 歌词高亮色
    static var lyricsHighlight: Color {
        primaryOpacity30
    }
    
    /// 进度条轨道色
    static var progressTrack: Color {
        Color.gray.opacity(0.3)
    }
    
    /// 进度条填充色
    static var progressFill: Color {
        primary
    }
}
