// MARK: - ContentView.swift (主界面)
import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var musicPlayer = MusicPlayer()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 主要内容区域
                if musicPlayer.currentSong != nil {
                    PlayerView()
                        .environmentObject(musicPlayer)
                } else {
                    WelcomeView()
                        .environmentObject(musicPlayer)
                }
                
                // 迷你播放器（如果有歌曲在播放）
                if musicPlayer.currentSong != nil {
                    MiniPlayerView()
                        .environmentObject(musicPlayer)
                }
            }
            .navigationTitle("我的音乐")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - 欢迎界面
struct WelcomeView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @State private var showingFilePicker = false
    @State private var showingLyricsPicker = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("欢迎使用音乐播放器")
                .font(.title)
                .fontWeight(.bold)
            
            Text("导入您的音乐文件开始播放")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                Button(action: {
                    showingFilePicker = true
                }) {
                    Label("导入音乐文件", systemImage: "music.note.list")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    showingLyricsPicker = true
                }) {
                    Label("导入歌词文件", systemImage: "text.quote")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                .disabled(musicPlayer.currentSong == nil)
            }
            .padding(.horizontal)
        }
        .padding()
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio, .movie],
            allowsMultipleSelection: false
        ) { result in
            musicPlayer.handleFileImport(result)
        }
        .fileImporter(
            isPresented: $showingLyricsPicker,
            allowedContentTypes: [.text],
            allowsMultipleSelection: false
        ) { result in
            musicPlayer.handleLyricsImport(result)
        }
    }
}

// MARK: - 播放器界面
struct PlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @State private var showingLyrics = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 封面图片
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 280, height: 280)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                )
                .scaleEffect(musicPlayer.isPlaying ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: musicPlayer.isPlaying)
            
            // 歌曲信息
            VStack(spacing: 8) {
                Text(musicPlayer.currentSong?.title ?? "未知歌曲")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(musicPlayer.currentSong?.artist ?? "未知艺术家")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 进度条
            VStack(spacing: 8) {
                ProgressView(value: musicPlayer.currentTime, total: musicPlayer.duration)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                HStack {
                    Text(formatTime(musicPlayer.currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(musicPlayer.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // 控制按钮
            HStack(spacing: 40) {
                Button(action: {
                    musicPlayer.previousTrack()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                }
                
                Button(action: {
                    musicPlayer.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            
            // 功能按钮
            HStack(spacing: 40) {
                Button(action: {
                    showingLyrics = true
                }) {
                    Image(systemName: "text.quote")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                .disabled(musicPlayer.lyrics.isEmpty)
                
                Button(action: {
                    // 导入新文件
                }) {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingLyrics) {
            LyricsView()
                .environmentObject(musicPlayer)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 歌词界面
struct LyricsView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(musicPlayer.lyrics.enumerated()), id: \.offset) { index, lyric in
                            LyricLineView(
                                lyric: lyric,
                                isActive: index == musicPlayer.currentLyricIndex,
                                progress: index == musicPlayer.currentLyricIndex ? musicPlayer.lyricProgress : 0
                            )
                            .id(index)
                            .onTapGesture {
                                musicPlayer.seekToLyric(at: index)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: musicPlayer.currentLyricIndex) { newIndex in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
            .navigationTitle("歌词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 歌词行组件
struct LyricLineView: View {
    let lyric: LyricLine
    let isActive: Bool
    let progress: Double
    
    var body: some View {
        Text(lyric.text)
            .font(isActive ? .title3 : .body)
            .fontWeight(isActive ? .semibold : .regular)
            .foregroundColor(isActive ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .overlay(
                // 进度高亮效果
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: geometry.size.width * progress)
                        .animation(.linear(duration: 0.1), value: progress)
                }
                .mask(
                    Text(lyric.text)
                        .font(isActive ? .title3 : .body)
                        .fontWeight(isActive ? .semibold : .regular)
                        .multilineTextAlignment(.center)
                )
                .opacity(isActive ? 1 : 0)
            )
            .scaleEffect(isActive ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

// MARK: - 迷你播放器
struct MiniPlayerView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    
    var body: some View {
        HStack {
            // 封面
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.white)
                )
            
            // 歌曲信息
            VStack(alignment: .leading, spacing: 2) {
                Text(musicPlayer.currentSong?.title ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(musicPlayer.currentSong?.artist ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 控制按钮
            HStack(spacing: 15) {
                Button(action: {
                    musicPlayer.togglePlayPause()
                }) {
                    Image(systemName: musicPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Button(action: {
                    musicPlayer.nextTrack()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(.secondary.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - 数据模型
struct Song {
    let id = UUID()
    let title: String
    let artist: String
    let url: URL
}

struct LyricLine {
    let time: TimeInterval
    let text: String
}

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
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // 开始访问安全范围的资源
            guard url.startAccessingSecurityScopedResource() else {
                print("无法访问文件")
                return
            }
            
            // 复制文件到应用沙盒
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsPath.appendingPathComponent(url.lastPathComponent)
            
            do {
                // 如果文件已存在，先删除
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // 复制文件
                try FileManager.default.copyItem(at: url, to: destinationURL)
                
                // 创建歌曲对象
                let filename = url.deletingPathExtension().lastPathComponent
                let song = Song(title: filename, artist: "未知艺术家", url: destinationURL)
                
                DispatchQueue.main.async {
                    self.loadSong(song)
                }
            } catch {
                print("文件复制失败: \(error)")
            }
            
            // 停止访问安全范围的资源
            url.stopAccessingSecurityScopedResource()
            
        case .failure(let error):
            print("文件导入失败: \(error)")
        }
    }
    
    func handleLyricsImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                print("无法访问歌词文件")
                return
            }
            
            do {
                let lyricsContent = try String(contentsOf: url, encoding: .utf8)
                let parsedLyrics = parseLRCContent(lyricsContent)
                
                DispatchQueue.main.async {
                    self.lyrics = parsedLyrics
                }
            } catch {
                print("歌词文件读取失败: \(error)")
            }
            
            url.stopAccessingSecurityScopedResource()
            
        case .failure(let error):
            print("歌词导入失败: \(error)")
        }
    }
    
    // MARK: - LRC歌词解析
    private func parseLRCContent(_ content: String) -> [LyricLine] {
        var lyricLines: [LyricLine] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            // 匹配时间标签 [mm:ss.xx]
            let pattern = #"\[(\d{2}):(\d{2})\.(\d{2})\](.*)"#
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if let match = regex?.firstMatch(in: line, range: range),
               match.numberOfRanges == 5 {
                
                let minutes = Double((line as NSString).substring(with: match.range(at: 1))) ?? 0
                let seconds = Double((line as NSString).substring(with: match.range(at: 2))) ?? 0
                let milliseconds = Double((line as NSString).substring(with: match.range(at: 3))) ?? 0
                let text = (line as NSString).substring(with: match.range(at: 4)).trimmingCharacters(in: .whitespaces)
                
                let timeInterval = minutes * 60 + seconds + milliseconds / 100
                
                if !text.isEmpty {
                    lyricLines.append(LyricLine(time: timeInterval, text: text))
                }
            }
        }
        
        return lyricLines.sorted { $0.time < $1.time }
    }
    
    // MARK: - 播放控制
    func loadSong(_ song: Song) {
        currentSong = song
        
        let playerItem = AVPlayerItem(url: song.url)
        player = AVPlayer(playerItem: playerItem)
        
        // 设置时间观察器
        setupTimeObserver()
        
        // 获取时长
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                let duration = playerItem.asset.duration
                self.duration = CMTimeGetSeconds(duration)
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
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func previousTrack() {
        // 实现上一首逻辑
        seekTo(time: 0)
    }
    
    func nextTrack() {
        // 实现下一首逻辑
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

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
