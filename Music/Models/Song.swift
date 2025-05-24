//
//  Song.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 数据模型
struct Song: Equatable {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL
    
    // 实现Equatable协议
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
