//
//  MusicPlayer+Settings.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 设置管理扩展
extension MusicPlayer {
    
    // MARK: - 持久化设置的键
    private struct SettingsKeys {
        static let playbackMode = "MusicPlayer.PlaybackMode"
        static let repeatMode = "MusicPlayer.RepeatMode"
        static let lastPlayedSongTitle = "MusicPlayer.LastPlayedSongTitle"
        static let lastPlayedTime = "MusicPlayer.LastPlayedTime"
    }
    
    // MARK: - 保存播放设置
    internal func savePlaybackSettings() {
        let defaults = UserDefaults.standard
        
        // 保存播放模式
        switch playbackMode {
        case .sequence:
            defaults.set("sequence", forKey: SettingsKeys.playbackMode)
        case .shuffle:
            defaults.set("shuffle", forKey: SettingsKeys.playbackMode)
        }
        
        // 保存重复模式
        switch repeatMode {
        case .off:
            defaults.set("off", forKey: SettingsKeys.repeatMode)
        case .all:
            defaults.set("all", forKey: SettingsKeys.repeatMode)
        case .one:
            defaults.set("one", forKey: SettingsKeys.repeatMode)
        }
        
        // 保存当前播放的歌曲信息（可选）
        if let currentSong = currentSong {
            defaults.set(currentSong.title, forKey: SettingsKeys.lastPlayedSongTitle)
            defaults.set(currentTime, forKey: SettingsKeys.lastPlayedTime)
        }
        
        print("✅ 播放设置已保存 - 播放模式: \(playbackMode.displayName), 重复模式: \(repeatMode.displayName)")
    }
    
    // MARK: - 加载播放设置
    internal func loadPlaybackSettings() {
        let defaults = UserDefaults.standard
        
        // 加载播放模式，默认为顺序播放
        let savedPlaybackMode = defaults.string(forKey: SettingsKeys.playbackMode) ?? "sequence"
        switch savedPlaybackMode {
        case "sequence":
            playbackMode = .sequence
        case "shuffle":
            playbackMode = .shuffle
        default:
            playbackMode = .sequence
        }
        
        // 加载重复模式，默认为关闭
        let savedRepeatMode = defaults.string(forKey: SettingsKeys.repeatMode) ?? "off"
        switch savedRepeatMode {
        case "off":
            repeatMode = .off
        case "all":
            repeatMode = .all
        case "one":
            repeatMode = .one
        default:
            repeatMode = .off
        }
        
        print("✅ 播放设置已加载 - 播放模式: \(playbackMode.displayName), 重复模式: \(repeatMode.displayName)")
    }
    
    // MARK: - 获取上次播放信息
    func getLastPlayedInfo() -> (songTitle: String?, lastTime: TimeInterval) {
        let defaults = UserDefaults.standard
        let songTitle = defaults.string(forKey: SettingsKeys.lastPlayedSongTitle)
        let lastTime = defaults.double(forKey: SettingsKeys.lastPlayedTime)
        return (songTitle, lastTime)
    }
    
    // MARK: - 清理持久化设置
    func clearSavedSettings() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: SettingsKeys.playbackMode)
        defaults.removeObject(forKey: SettingsKeys.repeatMode)
        defaults.removeObject(forKey: SettingsKeys.lastPlayedSongTitle)
        defaults.removeObject(forKey: SettingsKeys.lastPlayedTime)
        
        // 重置为默认值
        playbackMode = .sequence
        repeatMode = .off
        
        print("✅ 播放设置已重置为默认值")
    }
}
