//
//  MusicPlayer+RemoteControl.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation
import MediaPlayer
import UIKit

// MARK: - 远程控制扩展
extension MusicPlayer {
    
    // MARK: - 远程控制设置
    internal func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放/暂停按钮
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            self?.togglePlayPause()
            return .success
        }
        
        // 上一首/下一首
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.previousTrack()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.nextTrack()
            return .success
        }
        
        // 进度控制
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let event = event as? MPChangePlaybackPositionCommandEvent {
                self?.seekTo(time: event.positionTime)
                return .success
            }
            return .commandFailed
        }
        
        // 启用远程控制事件接收
        UIApplication.shared.beginReceivingRemoteControlEvents()
        print("远程控制设置完成")
    }
    
    // MARK: - 更新锁屏和控制中心的媒体信息
    internal func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // 设置默认封面图片
        if let image = UIImage(systemName: "music.note.list") {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
                return image
            }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("更新媒体信息: \(song.title)")
    }
}
