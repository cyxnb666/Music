//
//  AppleAnimations.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/6/5.
//

import SwiftUI

/// Apple Music标准动画配置
struct AppleAnimations {
    // MARK: - 标准动画定义
    
    /// 标准转换动画 - 0.35秒，Apple默认缓动
    static let standardTransition = Animation.interactiveSpring(
        response: 0.35,
        dampingFraction: 0.8,
        blendDuration: 0.25
    )
    
    /// 播放器转换动画 - 0.6秒响应，用于播放器展开/收起
    static let playerTransition = Animation.interactiveSpring(
        response: 0.6,
        dampingFraction: 0.8,
        blendDuration: 0.25
    )
    
    /// 微交互动画 - 0.2秒，用于按钮点击等小交互
    static let microInteraction = Animation.easeInOut(duration: 0.2)
    
    /// 快速微交互 - 0.15秒，用于状态切换
    static let quickMicro = Animation.easeInOut(duration: 0.15)
    
    /// Apple标准缓动曲线 - 贝塞尔曲线 (0.42, 0.0, 0.58, 1.0)
    static let appleEasing = Animation.timingCurve(0.42, 0.0, 0.58, 1.0, duration: 0.35)
    
    /// 弹性动画 - 用于强调性交互
    static let bounce = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)
    
    // MARK: - 列表动画
    
    /// 列表项动画 - 带渐入延迟效果
    /// - Parameter delay: 延迟时间（秒）
    /// - Returns: 配置好的动画
    static func listItemAnimation(delay: Double) -> Animation {
        return Animation.easeOut(duration: 0.3).delay(delay)
    }
    
    /// 列表项出现动画 - 从下方滑入
    static let listItemAppear = Animation.easeOut(duration: 0.4)
    
    /// 列表项消失动画 - 向上滑出
    static let listItemDisappear = Animation.easeIn(duration: 0.25)
    
    // MARK: - 专用动画
    
    /// 进度条拖拽动画
    static let progressDrag = Animation.interactiveSpring(
        response: 0.3,
        dampingFraction: 1.0,
        blendDuration: 0.1
    )
    
    /// 播放状态切换动画
    static let playStateChange = Animation.easeInOut(duration: 0.25)
    
    /// 歌词滚动动画
    static let lyricsScroll = Animation.easeInOut(duration: 0.5)
    
    // MARK: - 辅助方法
    
    /// 创建带随机延迟的动画，用于避免同时触发多个动画
    /// - Parameters:
    ///   - baseAnimation: 基础动画
    ///   - maxDelay: 最大随机延迟（秒）
    /// - Returns: 带随机延迟的动画
    static func withRandomDelay(_ baseAnimation: Animation, maxDelay: Double = 0.1) -> Animation {
        let randomDelay = Double.random(in: 0...maxDelay)
        return baseAnimation.delay(randomDelay)
    }
    
    /// 创建渐进式列表动画
    /// - Parameters:
    ///   - index: 项目索引
    ///   - stagger: 每项之间的延迟间隔
    /// - Returns: 配置好的渐进动画
    static func staggeredListAnimation(index: Int, stagger: Double = 0.025) -> Animation {
        return Animation.easeOut(duration: 0.4).delay(Double(index) * stagger)
    }
}
