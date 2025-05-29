//
//  MusicPlayer+PlaybackModes.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 播放模式管理扩展
extension MusicPlayer {
    
    // MARK: - 播放模式切换
    func togglePlaybackMode() {
        switch playbackMode {
        case .sequence:
            playbackMode = .shuffle
            if !playlist.isEmpty {
                shufflePlaylist()
            }
            print("🔀 切换到随机播放模式")
        case .shuffle:
            playbackMode = .sequence
            restoreOriginalOrder()
            print("📋 切换到顺序播放模式")
        }
    }
    
    // MARK: - 重复模式切换
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
            print("🔁 切换到重复列表模式")
        case .all:
            repeatMode = .one
            print("🔂 切换到单曲循环模式")
        case .one:
            repeatMode = .off
            print("⏹️ 关闭重复播放")
        }
    }
    
    // MARK: - 上一首
    func previousTrack() {
        guard !playlist.isEmpty else {
            seekTo(time: 0)
            return
        }
        
        // 如果当前播放时间超过3秒，先跳到歌曲开头
        if currentTime > 3.0 {
            seekTo(time: 0)
            return
        }
        
        let shouldContinuePlayingAfterLoad = isPlaying
        
        switch playbackMode {
        case .sequence:
            if currentIndex > 0 {
                currentIndex -= 1
            } else if repeatMode == .all {
                currentIndex = playlist.count - 1
            } else {
                seekTo(time: 0)
                pause()
                return
            }
            
        case .shuffle:
            if currentShuffleIndex > 0 {
                currentShuffleIndex -= 1
            } else if repeatMode == .all {
                currentShuffleIndex = shuffledIndices.count - 1
            } else {
                seekTo(time: 0)
                pause()
                return
            }
        }
        
        let song = playbackMode == .shuffle ?
            originalPlaylist[shuffledIndices[currentShuffleIndex]] :
            playlist[currentIndex]
        loadSong(song)
        
        if shouldContinuePlayingAfterLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.play()
            }
        }
    }
    
    // MARK: - 下一首
    func nextTrack() {
        guard !playlist.isEmpty else {
            seekTo(time: duration)
            return
        }
        
        // 单曲循环模式
        if repeatMode == .one {
            seekTo(time: 0)
            let shouldContinuePlayingAfterSeek = isPlaying
            if shouldContinuePlayingAfterSeek {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.play()
                }
            }
            return
        }
        
        let shouldContinuePlayingAfterLoad = isPlaying
        
        switch playbackMode {
        case .sequence:
            if currentIndex < playlist.count - 1 {
                currentIndex += 1
            } else if repeatMode == .all {
                currentIndex = 0
            } else {
                pause()
                return
            }
            
        case .shuffle:
            if currentShuffleIndex < shuffledIndices.count - 1 {
                currentShuffleIndex += 1
            } else if repeatMode == .all {
                shufflePlaylist()
                currentShuffleIndex = 0
            } else {
                pause()
                return
            }
        }
        
        let song = playbackMode == .shuffle ?
            originalPlaylist[shuffledIndices[currentShuffleIndex]] :
            playlist[currentIndex]
        loadSong(song)
        
        if shouldContinuePlayingAfterLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.play()
            }
        }
    }
}
