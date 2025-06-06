//
//  MusicPlayer.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer

// MARK: - 音乐播放器主类
class MusicPlayer: ObservableObject {
    // MARK: - 发布的属性
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var lyrics: [LyricLine] = []
    @Published var currentLyricIndex = 0
    @Published var lyricProgress: Double = 0
    
    // 播放列表相关属性
    @Published var playlist: [Song] = []
    @Published var originalPlaylist: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var playbackMode: PlaybackMode = .sequence {
        didSet {
            savePlaybackSettings()
        }
    }
    @Published var repeatMode: RepeatMode = .off {
        didSet {
            savePlaybackSettings()
        }
    }
    
    // MARK: - 内部属性
    internal var shuffledIndices: [Int] = []
    internal var currentShuffleIndex: Int = 0
    internal var player: AVPlayer?
    internal var timeObserver: Any?
    
    // MARK: - 初始化和清理
    init() {
        loadPlaybackSettings()
        setupAudioSession()
        setupRemoteTransportControls()
        setupNotificationObservers()
    }
    
    deinit {
        cleanupTimeObserver()
        UIApplication.shared.endReceivingRemoteControlEvents()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 基本播放控制
    func togglePlayPause() {
        // 添加触觉反馈
        HapticManager.shared.playControl()
        
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    internal func play() {
        guard let player = player else { return }
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.syncPlayerState()
        }
        
        print("开始播放")
    }
    
    internal func pause() {
        guard let player = player else { return }
        player.pause()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.syncPlayerState()
        }
        
        print("暂停播放")
    }
    
    func seekTo(time: TimeInterval) {
        // 添加进度跳转触觉反馈
        HapticManager.shared.selectionChanged()
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateNowPlayingInfo()
            }
        }
    }
    
    func seekToLyric(at index: Int) {
        guard index < lyrics.count else { return }
        let lyric = lyrics[index]
        
        // 歌词跳转的特殊触觉反馈
        HapticManager.shared.lyricBeat()
        
        seekTo(time: lyric.time)
    }
    
    // MARK: - 歌曲加载
    func loadSong(_ song: Song) {
        print("加载歌曲: \(song.title)")
        
        // 添加文件加载成功的触觉反馈
        HapticManager.shared.prepare()
        
        cleanupTimeObserver()
        player?.pause()
        
        currentSong = song
        
        let playerItem = AVPlayerItem(url: song.url)
        player = AVPlayer(playerItem: playerItem)
        
        currentTime = 0
        duration = 0
        isPlaying = false
        
        setupTimeObserver()
        setupPlayerItemObserver()
        loadSongDuration(from: playerItem)
        
        // 歌曲加载完成的触觉反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.success()
        }
        
        print("歌曲加载完成: \(song.title)")
    }
    
    // MARK: - 内部辅助方法
    internal func cleanupTimeObserver() {
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    internal func syncPlayerState() {
        guard let player = player else {
            if isPlaying {
                isPlaying = false
                updateNowPlayingInfo()
            }
            return
        }
        
        let actuallyPlaying = (player.timeControlStatus == .playing)
        
        if isPlaying != actuallyPlaying {
            print("同步播放状态: UI显示=\(isPlaying), 实际状态=\(actuallyPlaying)")
            isPlaying = actuallyPlaying
            updateNowPlayingInfo()
        }
    }
    
    private func loadSongDuration(from playerItem: AVPlayerItem) {
        if #available(iOS 16.0, *) {
            Task {
                do {
                    let assetDuration = try await playerItem.asset.load(.duration)
                    await MainActor.run {
                        if CMTimeGetSeconds(assetDuration).isFinite {
                            self.duration = CMTimeGetSeconds(assetDuration)
                            print("歌曲时长: \(self.duration) 秒")
                            self.updateNowPlayingInfo()
                        }
                    }
                } catch {
                    print("加载歌曲时长失败: \(error)")
                    await MainActor.run {
                        self.duration = 0
                    }
                }
            }
        } else {
            playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                DispatchQueue.main.async {
                    let duration = playerItem.asset.duration
                    if CMTimeGetSeconds(duration).isFinite {
                        self.duration = CMTimeGetSeconds(duration)
                        print("歌曲时长: \(self.duration) 秒")
                        self.updateNowPlayingInfo()
                    }
                }
            }
        }
    }
    
    private func setupTimeObserver() {
        if timeObserver != nil {
            cleanupTimeObserver()
        }
        
        guard let currentPlayer = player else {
            print("无法设置时间观察器：播放器为空")
            return
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = currentPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            self.currentTime = CMTimeGetSeconds(time)
            self.updateLyricProgress()
            self.updateNowPlayingInfo()
            self.syncPlayerState()
        }
        
        print("时间观察器设置完成")
    }
    
    private func setupPlayerItemObserver() {
        guard let playerItem = player?.currentItem else { return }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    @objc private func playerDidFinishPlaying() {
        DispatchQueue.main.async {
            self.playNext()
        }
    }
    
    // MARK: - 自动播放下一首
    func playNext() {
        nextTrack()
    }
}
