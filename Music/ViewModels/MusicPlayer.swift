//
//  MusicPlayer.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - 音乐播放器类
class MusicPlayer: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var lyrics: [LyricLine] = []
    @Published var currentLyricIndex = 0
    @Published var lyricProgress: Double = 0
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    init() {
        setupAudioSession()
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话设置失败: \(error)")
        }
    }
    
    // MARK: - 文件导入
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
    
    // MARK: - LRC歌词解析
    private func parseLRCContent(_ content: String) -> [LyricLine] {
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
        currentSong = song
        
        let playerItem = AVPlayerItem(url: song.url)
        player = AVPlayer(playerItem: playerItem)
        
        // 设置时间观察器
        setupTimeObserver()
        
        // 获取时长
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                let duration = playerItem.asset.duration
                if CMTimeGetSeconds(duration).isFinite {
                    self.duration = CMTimeGetSeconds(duration)
                    print("歌曲时长: \(self.duration) 秒")
                }
            }
        }
    }
    
    private func setupTimeObserver() {
        // 移除旧的观察器
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        
        // 添加新的观察器
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
            self?.updateLyricProgress()
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
            print("暂停播放")
        } else {
            player.play()
            print("开始播放")
        }
        isPlaying.toggle()
    }
    
    func previousTrack() {
        seekTo(time: 0)
    }
    
    func nextTrack() {
        seekTo(time: duration)
    }
    
    func seekTo(time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
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
}
