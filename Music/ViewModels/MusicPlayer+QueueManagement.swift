//
//  MusicPlayer+QueueManagement.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 播放队列管理扩展
extension MusicPlayer {
    
    // MARK: - 获取播放队列信息
    func getQueueInfo() -> (current: Int, total: Int, upcoming: [Song]) {
        guard !playlist.isEmpty else {
            return (current: 0, total: 0, upcoming: [])
        }
        
        let upcomingCount = min(5, playlist.count - currentIndex - 1)
        let upcoming = Array(playlist.suffix(from: currentIndex + 1).prefix(upcomingCount))
        
        return (
            current: currentIndex + 1,
            total: playlist.count,
            upcoming: upcoming
        )
    }
    
    // MARK: - 播放队列重排序
    func moveQueueItems(from source: IndexSet, to destination: Int) {
        guard !playlist.isEmpty else { return }
        
        // 计算实际的源索引和目标索引（相对于当前播放位置之后的歌曲）
        var adjustedSource = IndexSet()
        for index in source {
            let actualIndex = currentIndex + 1 + index
            if actualIndex < playlist.count {
                adjustedSource.insert(actualIndex)
            }
        }
        
        let adjustedDestination = currentIndex + 1 + destination
        
        // 确保目标索引有效
        guard adjustedDestination <= playlist.count else { return }
        
        // 处理不同播放模式
        switch playbackMode {
        case .sequence:
            moveItemsInSequenceMode(from: adjustedSource, to: adjustedDestination)
        case .shuffle:
            moveItemsInShuffleMode(from: adjustedSource, to: adjustedDestination)
        }
        
        print("播放队列重排序完成")
    }
    
    // MARK: - 顺序播放模式下的重排序
    private func moveItemsInSequenceMode(from source: IndexSet, to destination: Int) {
        // 直接在 playlist 和 originalPlaylist 中移动
        playlist.move(fromOffsets: source, toOffset: destination)
        originalPlaylist.move(fromOffsets: source, toOffset: destination)
        
        // 更新当前索引（如果有必要）
        updateCurrentIndexAfterMove(from: source, to: destination)
    }
    
    // MARK: - 随机播放模式下的重排序
    private func moveItemsInShuffleMode(from source: IndexSet, to destination: Int) {
        // 在随机模式下，我们需要：
        // 1. 移动 playlist 中的项目
        // 2. 相应地更新 shuffledIndices 数组
        // 3. 更新 originalPlaylist（保持与 shuffledIndices 的对应关系）
        
        // 先移动 playlist
        playlist.move(fromOffsets: source, toOffset: destination)
        
        // 获取被移动的原始索引
        var movedOriginalIndices: [Int] = []
        for index in source.sorted(by: >) {
            if index < shuffledIndices.count {
                movedOriginalIndices.append(shuffledIndices[index])
            }
        }
        
        // 移动 shuffledIndices
        shuffledIndices.move(fromOffsets: source, toOffset: destination)
        
        // 重建 originalPlaylist 以保持一致性
        let tempOriginalPlaylist = originalPlaylist
        originalPlaylist = []
        for shuffledIndex in shuffledIndices {
            if shuffledIndex < tempOriginalPlaylist.count {
                originalPlaylist.append(tempOriginalPlaylist[shuffledIndex])
            }
        }
        
        // 更新当前随机索引
        updateCurrentShuffleIndexAfterMove(from: source, to: destination)
    }
    
    // MARK: - 更新当前索引（顺序模式）
    private func updateCurrentIndexAfterMove(from source: IndexSet, to destination: Int) {
        // 在顺序模式下，当前播放的歌曲索引不会改变
        // 因为我们只移动当前歌曲之后的项目
        // 所以不需要更新 currentIndex
    }
    
    // MARK: - 更新当前随机索引（随机模式）
    private func updateCurrentShuffleIndexAfterMove(from source: IndexSet, to destination: Int) {
        // 在随机模式下，当前播放的歌曲在 shuffledIndices 中的位置是 currentShuffleIndex
        // 由于我们只移动当前歌曲之后的项目，所以 currentShuffleIndex 不需要改变
    }
}
