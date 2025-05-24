//
//  MusicPlayer.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer // 添加MediaPlayer框架

// MARK: - 音乐播放器类
class MusicPlayer: ObservableObject {
    // 原有属性
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var lyrics: [LyricLine] = []
    @Published var currentLyricIndex = 0
    @Published var lyricProgress: Double = 0
    
    // 新增播放列表相关属性
    @Published var playlist: [Song] = []           // 当前播放列表
    @Published var originalPlaylist: [Song] = []   // 原始播放列表（用于shuffle）
    @Published var currentIndex: Int = 0           // 当前歌曲在列表中的索引
    @Published var playbackMode: PlaybackMode = .sequence
    @Published var repeatMode: RepeatMode = .off
    
    private var shuffledIndices: [Int] = []        // 随机播放的索引数组
    private var currentShuffleIndex: Int = 0       // 在随机数组中的当前位置
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    init() {
        setupAudioSession()
        setupRemoteTransportControls()
        setupNotificationObservers()
    }
    
    deinit {
        cleanupTimeObserver()
        // 清理远程控制
        UIApplication.shared.endReceivingRemoteControlEvents()
        // 清理通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 清理时间观察器的安全方法
    private func cleanupTimeObserver() {
        if let observer = timeObserver, let currentPlayer = player {
            currentPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            print("音频会话设置成功")
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - 远程控制设置
    private func setupRemoteTransportControls() {
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
    private func updateNowPlayingInfo() {
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
    
    // MARK: - 播放列表管理
    func setPlaylist(_ songs: [Song], startIndex: Int = 0) {
        originalPlaylist = songs
        playlist = songs
        currentIndex = startIndex
        shuffledIndices = Array(0..<songs.count)
        
        // 如果是随机模式，立即打乱
        if playbackMode == .shuffle {
            shufflePlaylist()
        }
        
        // 加载当前歌曲
        if !playlist.isEmpty && currentIndex < playlist.count {
            loadSong(playlist[currentIndex])
        }
    }
    
    func addToPlaylist(_ song: Song) {
        originalPlaylist.append(song)
        if playbackMode == .shuffle {
            // 重新生成随机序列
            shufflePlaylist()
        } else {
            playlist.append(song)
        }
    }
    
    // MARK: - 播放模式切换
    func togglePlaybackMode() {
        switch playbackMode {
        case .sequence:
            playbackMode = .shuffle
            shufflePlaylist()
        case .shuffle:
            playbackMode = .sequence
            restoreOriginalOrder()
        }
    }
    
    func toggleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }
    
    // MARK: - 随机播放处理
    private func shufflePlaylist() {
        guard !originalPlaylist.isEmpty else { return }
        
        // 创建随机索引数组
        shuffledIndices = Array(0..<originalPlaylist.count)
        
        // 如果有当前播放的歌曲，确保它在随机列表的第一位
        if let currentSong = currentSong,
           let originalIndex = originalPlaylist.firstIndex(where: { $0.id == currentSong.id }) {
            shuffledIndices.shuffle()
            // 将当前歌曲移到第一位
            if let shufflePos = shuffledIndices.firstIndex(of: originalIndex) {
                shuffledIndices.swapAt(0, shufflePos)
            }
            currentShuffleIndex = 0
        } else {
            shuffledIndices.shuffle()
            currentShuffleIndex = 0
        }
        
        // 更新播放列表
        playlist = shuffledIndices.map { originalPlaylist[$0] }
        currentIndex = 0
    }
    
    private func restoreOriginalOrder() {
        playlist = originalPlaylist
        
        // 找到当前歌曲在原始列表中的位置
        if let currentSong = currentSong,
           let originalIndex = originalPlaylist.firstIndex(where: { $0.id == currentSong.id }) {
            currentIndex = originalIndex
        }
    }
    
    // MARK: - 文件导入（保持原有逻辑）
    func handleFileImport(_ url: URL) {
        print("开始处理音乐文件导入: \(url.path)")
        
        // 开始访问安全范围的资源
        guard url.startAccessingSecurityScopedResource() else {
            print("无法访问文件")
            return
        }
        
        defer {
            // 确保在函数结束时停止访问
            url.stopAccessingSecurityScopedResource()
        }
        
        // 获取应用文档目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
        
        print("目标路径: \(destinationURL.path)")
        
        do {
            // 如果文件已存在，先删除
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("删除已存在的文件")
            }
            
            // 复制文件到应用沙盒
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("文件复制成功")
            
            // 提取文件信息
            let filename = url.deletingPathExtension().lastPathComponent
            let song = Song(title: filename, artist: "未知艺术家", url: destinationURL)
            
            print("创建歌曲对象: \(song.title)")
            
            // 在主线程更新UI，并清除之前的歌词
            DispatchQueue.main.async {
                self.lyrics = [] // 清除旧歌词
                self.loadSong(song)
            }
            
        } catch {
            print("文件处理失败: \(error.localizedDescription)")
        }
    }
    
    func handleLyricsImport(_ url: URL) {
        print("开始处理歌词文件导入: \(url.path)")
        
        guard url.startAccessingSecurityScopedResource() else {
            print("无法访问歌词文件")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let lyricsContent = try String(contentsOf: url, encoding: .utf8)
            let parsedLyrics = parseLRCContent(lyricsContent)
            
            DispatchQueue.main.async {
                self.lyrics = parsedLyrics
                print("歌词加载成功，共 \(parsedLyrics.count) 行")
                
                // 如果解析的歌词为空，尝试作为纯文本处理
                if parsedLyrics.isEmpty {
                    let plainTextLyrics = self.parseAsPlainText(lyricsContent)
                    self.lyrics = plainTextLyrics
                    print("作为纯文本处理歌词，共 \(plainTextLyrics.count) 行")
                }
            }
        } catch {
            print("歌词文件读取失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - LRC歌词解析（保持原有逻辑）
    func parseLRCContent(_ content: String) -> [LyricLine] {
        var lyricLines: [LyricLine] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // 匹配时间标签 [mm:ss.xx] 或 [mm:ss]
            let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{2}))?\](.*)"#
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if let match = regex?.firstMatch(in: line, range: range),
               match.numberOfRanges >= 4 {
                
                let minutes = Double((line as NSString).substring(with: match.range(at: 1))) ?? 0
                let seconds = Double((line as NSString).substring(with: match.range(at: 2))) ?? 0
                
                // 毫秒部分可能不存在
                var milliseconds: Double = 0
                if match.numberOfRanges > 4 && match.range(at: 3).location != NSNotFound {
                    milliseconds = Double((line as NSString).substring(with: match.range(at: 3))) ?? 0
                }
                
                let text = (line as NSString).substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
                
                let timeInterval = minutes * 60 + seconds + milliseconds / 100
                
                if !text.isEmpty {
                    lyricLines.append(LyricLine(time: timeInterval, text: text))
                }
            }
        }
        
        return lyricLines.sorted { $0.time < $1.time }
    }
    
    // 如果不是LRC格式，作为纯文本处理
    private func parseAsPlainText(_ content: String) -> [LyricLine] {
        let lines = content.components(separatedBy: .newlines)
        var lyricLines: [LyricLine] = []
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if !trimmedLine.isEmpty {
                // 假设每行歌词间隔3秒
                let time = Double(index) * 3.0
                lyricLines.append(LyricLine(time: time, text: trimmedLine))
            }
        }
        
        return lyricLines
    }
    
    // MARK: - 播放控制
    func loadSong(_ song: Song) {
        print("加载歌曲: \(song.title)")
        
        // 先清理旧的时间观察器（使用旧的player实例）
        cleanupTimeObserver()
        
        // 停止当前播放
        player?.pause()
        
        // 更新当前歌曲
        currentSong = song
        
        // 创建新的播放器实例
        let playerItem = AVPlayerItem(url: song.url)
        player = AVPlayer(playerItem: playerItem)
        
        // 重置时间相关的状态
        currentTime = 0
        duration = 0
        isPlaying = false
        
        // 设置新的时间观察器
        setupTimeObserver()
        
        // 设置播放结束监听
        setupPlayerItemObserver()
        
        // 获取时长
        if #available(iOS 16.0, *) {
            // 使用新的 async/await API
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
            // 使用旧的 API 以保持向后兼容
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
        
        print("歌曲加载完成: \(song.title)")
    }
    
    private func setupTimeObserver() {
        // 确保没有重复的观察器
        if timeObserver != nil {
            cleanupTimeObserver()
        }
        
        guard let currentPlayer = player else {
            print("无法设置时间观察器：播放器为空")
            return
        }
        
        // 添加时间观察器
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)) // 稍微降低频率
        timeObserver = currentPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            self.currentTime = CMTimeGetSeconds(time)
            self.updateLyricProgress()
            self.updateNowPlayingInfo()
            
            // 定期检查播放状态是否同步（每0.5秒一次，不会太频繁）
            self.syncPlayerState()
        }
        
        print("时间观察器设置完成")
    }
    
    // MARK: - 播放结束监听
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
    
    private func setupNotificationObservers() {
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
    
    @objc private func applicationDidBecomeActive() {
        // 应用重新激活时同步播放状态
        DispatchQueue.main.async {
            self.syncPlayerState()
        }
    }

    private func syncPlayerState() {
        guard let player = player else {
            if isPlaying {
                isPlaying = false
                updateNowPlayingInfo()
            }
            return
        }
        
        // 根据播放器的实际状态同步UI状态
        let actuallyPlaying = (player.timeControlStatus == .playing)
        
        if isPlaying != actuallyPlaying {
            print("同步播放状态: UI显示=\(isPlaying), 实际状态=\(actuallyPlaying)")
            isPlaying = actuallyPlaying
            updateNowPlayingInfo()
        }
    }
    
    // MARK: - 播放控制方法
    private func play() {
        guard let player = player else { return }
        player.play()
        
        // 延迟一点检查状态，确保播放器状态已更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.syncPlayerState()
        }
        
        print("开始播放")
    }
    
    private func pause() {
        guard let player = player else { return }
        player.pause()
        
        // 延迟一点检查状态，确保播放器状态已更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.syncPlayerState()
        }
        
        print("暂停播放")
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    // MARK: - 修正的上一首/下一首方法
    func previousTrack() {
        guard !playlist.isEmpty else {
            // 如果没有播放列表，使用原有逻辑
            seekTo(time: 0)
            return
        }
        
        // 如果当前播放时间超过3秒，先跳到歌曲开头
        if currentTime > 3.0 {
            seekTo(time: 0)
            return
        }
        
        // 保存当前播放状态
        let shouldContinuePlayingAfterLoad = isPlaying
        
        switch playbackMode {
        case .sequence:
            if currentIndex > 0 {
                currentIndex -= 1
            } else if repeatMode == .all {
                currentIndex = playlist.count - 1
            } else {
                // 已经是第一首，跳到开头并暂停（按用户要求）
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
                // 已经是第一首，跳到开头并暂停（按用户要求）
                seekTo(time: 0)
                pause()
                return
            }
        }
        
        // 加载新歌曲
        let song = playbackMode == .shuffle ?
            originalPlaylist[shuffledIndices[currentShuffleIndex]] :
            playlist[currentIndex]
        loadSong(song)
        
        // 如果之前在播放，继续播放
        if shouldContinuePlayingAfterLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.play()
            }
        }
    }

    func nextTrack() {
        guard !playlist.isEmpty else {
            // 如果没有播放列表，使用原有逻辑
            seekTo(time: duration)
            return
        }
        
        // 单曲循环模式
        if repeatMode == .one {
            seekTo(time: 0)
            // 保存播放状态并继续播放
            let shouldContinuePlayingAfterSeek = isPlaying
            if shouldContinuePlayingAfterSeek {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.play()
                }
            }
            return
        }
        
        // 保存当前播放状态
        let shouldContinuePlayingAfterLoad = isPlaying
        
        switch playbackMode {
        case .sequence:
            if currentIndex < playlist.count - 1 {
                currentIndex += 1
            } else if repeatMode == .all {
                currentIndex = 0
            } else {
                // 已经是最后一首，停止播放（按用户要求）
                pause()
                return
            }
            
        case .shuffle:
            if currentShuffleIndex < shuffledIndices.count - 1 {
                currentShuffleIndex += 1
            } else if repeatMode == .all {
                // 重新打乱并从头开始
                shufflePlaylist()
                currentShuffleIndex = 0
            } else {
                // 已经是最后一首，停止播放（按用户要求）
                pause()
                return
            }
        }
        
        // 加载新歌曲
        let song = playbackMode == .shuffle ?
            originalPlaylist[shuffledIndices[currentShuffleIndex]] :
            playlist[currentIndex]
        loadSong(song)
        
        // 如果之前在播放，继续播放
        if shouldContinuePlayingAfterLoad {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.play()
            }
        }
    }
    
    // 判断是否应该继续播放
    private func wasPlaying() -> Bool {
        return isPlaying || player?.timeControlStatus == .playing
    }
    
    // MARK: - 自动播放下一首（歌曲结束时调用）
    func playNext() {
        nextTrack()
    }
    
    // MARK: - 播放指定索引的歌曲
    func playTrack(at index: Int) {
        guard index >= 0 && index < originalPlaylist.count else { return }
        
        if playbackMode == .shuffle {
            // 在随机模式下，需要找到该歌曲在随机数组中的位置
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
    
    func seekTo(time: TimeInterval) {
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
        seekTo(time: lyric.time)
    }
    
    // MARK: - 歌词同步
    private func updateLyricProgress() {
        guard !lyrics.isEmpty else { return }
        
        // 找到当前歌词索引
        var newIndex = 0
        for (index, lyric) in lyrics.enumerated() {
            if currentTime >= lyric.time {
                newIndex = index
            } else {
                break
            }
        }
        
        currentLyricIndex = newIndex
        
        // 计算当前歌词的进度
        if currentLyricIndex < lyrics.count {
            let currentLyric = lyrics[currentLyricIndex]
            let nextLyricTime = currentLyricIndex + 1 < lyrics.count ? lyrics[currentLyricIndex + 1].time : duration
            let lyricDuration = nextLyricTime - currentLyric.time
            let elapsed = currentTime - currentLyric.time
            lyricProgress = min(1.0, max(0.0, elapsed / lyricDuration))
        }
    }
    
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
}
