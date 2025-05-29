//
//  MusicPlayer+PlaylistManagement.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 播放列表管理扩展
extension MusicPlayer {
    
    // MARK: - 播放列表设置
    func setPlaylist(_ songs: [Song], startIndex: Int = 0) {
        print("🎵 设置播放列表，歌曲数量: \(songs.count), 起始索引: \(startIndex)")
        
        originalPlaylist = songs
        currentIndex = startIndex
        
        // 根据当前播放模式设置播放列表
        if playbackMode == .shuffle {
            setupShufflePlaylist(startIndex: startIndex)
        } else {
            playlist = songs
            shuffledIndices = Array(0..<songs.count)
        }
        
        // 加载当前歌曲
        if !playlist.isEmpty && currentIndex < playlist.count {
            let songToLoad = playlist[currentIndex]
            loadSong(songToLoad)
            print("✅ 加载歌曲: \(songToLoad.title), 当前索引: \(currentIndex)")
        }
    }
    
    // MARK: - 随机播放列表设置
    internal func setupShufflePlaylist(startIndex: Int) {
        guard !originalPlaylist.isEmpty && startIndex < originalPlaylist.count else {
            playlist = originalPlaylist
            shuffledIndices = Array(0..<originalPlaylist.count)
            currentIndex = 0
            return
        }
        
        shuffledIndices = Array(0..<originalPlaylist.count)
        let targetSong = originalPlaylist[startIndex]
        
        var remainingIndices = shuffledIndices.filter { $0 != startIndex }
        remainingIndices.shuffle()
        
        shuffledIndices = [startIndex] + remainingIndices
        playlist = shuffledIndices.map { originalPlaylist[$0] }
        
        currentIndex = 0
        currentShuffleIndex = 0
        
        print("🔀 随机播放列表已设置，起始歌曲: \(targetSong.title)")
        print("🎶 播放顺序: \(playlist.map { $0.title }.prefix(3).joined(separator: " -> "))...")
    }
    
    // MARK: - 添加到播放列表
    func addToPlaylist(_ song: Song) {
        originalPlaylist.append(song)
        if playbackMode == .shuffle {
            shufflePlaylist()
        } else {
            playlist.append(song)
        }
    }
    
    // MARK: - 随机播放处理
    internal func shufflePlaylist() {
        guard !originalPlaylist.isEmpty else { return }
        
        let currentSongToPreserve = currentSong
        shuffledIndices = Array(0..<originalPlaylist.count)
        
        if let currentSong = currentSongToPreserve,
           let originalIndex = originalPlaylist.firstIndex(where: { $0.id == currentSong.id }) {
            
            var remainingIndices = shuffledIndices.filter { $0 != originalIndex }
            remainingIndices.shuffle()
            
            shuffledIndices = Array(shuffledIndices[0..<currentIndex]) + [originalIndex] + remainingIndices
            if shuffledIndices.count > currentIndex + 1 {
                let afterCurrent = Array(shuffledIndices[(currentIndex + 1)...])
                shuffledIndices = Array(shuffledIndices[0...currentIndex]) + afterCurrent.shuffled()
            }
            
            currentShuffleIndex = currentIndex
        } else {
            shuffledIndices.shuffle()
            currentShuffleIndex = 0
            currentIndex = 0
        }
        
        playlist = shuffledIndices.map { originalPlaylist[$0] }
        print("🔀 播放列表已重新随机排序，当前索引: \(currentIndex)")
    }
    
    // MARK: - 恢复原始顺序
    internal func restoreOriginalOrder() {
        playlist = originalPlaylist
        
        if let currentSong = currentSong,
           let originalIndex = originalPlaylist.firstIndex(where: { $0.id == currentSong.id }) {
            currentIndex = originalIndex
        } else {
            currentIndex = 0
        }
        
        print("📋 播放列表已恢复原始顺序，当前索引: \(currentIndex)")
    }
    
    // MARK: - 播放指定索引的歌曲
    func playTrack(at index: Int) {
        guard index >= 0 && index < originalPlaylist.count else { return }
        
        if playbackMode == .shuffle {
            if let shuffleIndex = shuffledIndices.firstIndex(of: index) {
                currentShuffleIndex = shuffleIndex
            }
        } else {
            currentIndex = index
        }
        
        let song = originalPlaylist[index]
        loadSong(song)
        
        if !isPlaying {
            play()
        }
    }
}
