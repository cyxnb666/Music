//
//  MusicPlayer+AudioSession.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 音频会话管理扩展
extension MusicPlayer {
    
    // MARK: - 音频会话设置
    internal func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            print("音频会话设置成功")
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - 通知观察器设置
    internal func setupNotificationObservers() {
        // 监听音频会话中断
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        // 监听应用进入前台
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - 音频会话中断处理
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        DispatchQueue.main.async {
            switch type {
            case .began:
                // 中断开始 - 暂停播放
                print("音频会话被中断，暂停播放")
                self.isPlaying = false
                self.updateNowPlayingInfo()
                
            case .ended:
                // 中断结束 - 同步播放器状态但不自动播放
                print("音频会话中断结束")
                self.syncPlayerState()
                
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - 应用重新激活处理
    @objc private func applicationDidBecomeActive() {
        // 应用重新激活时同步播放状态
        DispatchQueue.main.async {
            self.syncPlayerState()
        }
    }
}
