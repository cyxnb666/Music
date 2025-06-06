//
//  HapticManager.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/6/5.
//

import UIKit

/// 触觉反馈管理器 - 提供Apple Music级别的触觉体验
class HapticManager {
    static let shared = HapticManager()
    
    // MARK: - 反馈生成器
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - 私有初始化
    private init() {
        setupGenerators()
    }
    
    // MARK: - 设置和准备
    
    /// 初始化所有反馈生成器
    private func setupGenerators() {
        // 预准备所有生成器以减少延迟
        prepare()
    }
    
    /// 预准备反馈生成器以减少延迟（建议在应用启动时调用）
    func prepare() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - 基础反馈方法
    
    /// 轻触反馈 - 用于按钮点击
    func buttonTap() {
        lightImpactGenerator.impactOccurred()
    }
    
    /// 中等强度反馈 - 用于重要操作
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
    }
    
    /// 重触反馈 - 用于重要操作或错误
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
    }
    
    /// 选择变化反馈 - 用于滚动选择或切换
    func selectionChanged() {
        selectionGenerator.selectionChanged()
    }
    
    /// 成功反馈
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// 警告反馈
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    /// 错误反馈
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - 专用音乐应用反馈
    
    /// 播放控制反馈 - 播放/暂停按钮
    func playControl() {
        mediumImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// 拖拽开始反馈 - 进度条拖拽开始
    func dragStart() {
        heavyImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// 拖拽结束反馈 - 进度条拖拽结束
    func dragEnd() {
        mediumImpactGenerator.impactOccurred(intensity: 0.6)
    }
    
    /// 歌曲切换反馈 - 上一首/下一首
    func trackChange() {
        mediumImpactGenerator.impactOccurred()
        
        // 延迟一小段时间再给轻触反馈，创造双重反馈感
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.5)
        }
    }
    
    /// 模式切换反馈 - 随机播放/重复模式
    func modeToggle() {
        selectionGenerator.selectionChanged()
        
        // 稍微延迟给轻触反馈确认操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpactGenerator.impactOccurred(intensity: 0.6)
        }
    }
    
    /// 列表项选择反馈 - 歌曲列表选择
    func listSelection() {
        lightImpactGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// 界面转换反馈 - 迷你播放器展开
    func interfaceTransition() {
        mediumImpactGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// 操作确认反馈 - 删除、添加等操作
    func operationConfirm() {
        heavyImpactGenerator.impactOccurred(intensity: 0.9)
    }
    
    /// 文件导入反馈 - 文件导入成功
    func fileImport() {
        notificationGenerator.notificationOccurred(.success)
        
        // 延迟给一个轻触确认
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightImpactGenerator.impactOccurred()
        }
    }
    
    // MARK: - 复合反馈序列
    
    /// 播放器打开序列 - 复合反馈
    func playerOpen() {
        mediumImpactGenerator.impactOccurred(intensity: 0.6)
    }
    
    /// 播放器关闭序列 - 复合反馈
    func playerClose() {
        lightImpactGenerator.impactOccurred(intensity: 0.8)
    }
    
    /// 歌词同步反馈 - 轻微节拍感
    func lyricBeat() {
        lightImpactGenerator.impactOccurred(intensity: 0.3)
    }
    
    // MARK: - 智能反馈控制
    
    /// 检查设备是否支持触觉反馈
    var isHapticFeedbackSupported: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// 检查用户是否启用了系统触觉反馈
    var isSystemHapticsEnabled: Bool {
        // 注意：这个检查在iOS中比较复杂，这里提供基础实现
        return true // 实际应用中可能需要更复杂的检测
    }
    
    /// 安全执行触觉反馈（检查系统设置）
    /// - Parameter feedback: 要执行的反馈闭包
    func safelyExecute(_ feedback: @escaping () -> Void) {
        guard isHapticFeedbackSupported && isSystemHapticsEnabled else { return }
        feedback()
    }
}
