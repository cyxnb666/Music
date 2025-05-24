//
//  PlaybackMode.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 播放模式枚举
enum PlaybackMode: CaseIterable {
    case sequence   // 顺序播放
    case shuffle    // 随机播放
    
    var displayName: String {
        switch self {
        case .sequence: return "顺序播放"
        case .shuffle: return "随机播放"
        }
    }
    
    var iconName: String {
        switch self {
        case .sequence: return "list.number"
        case .shuffle: return "shuffle"
        }
    }
}

// MARK: - 重复模式枚举
enum RepeatMode: CaseIterable {
    case off        // 不重复
    case all        // 重复列表
    case one        // 单曲循环
    
    var displayName: String {
        switch self {
        case .off: return "关闭重复"
        case .all: return "重复列表"
        case .one: return "单曲循环"
        }
    }
    
    var iconName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }
}
