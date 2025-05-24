//
//  Song.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 数据模型
struct Song {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL
}
