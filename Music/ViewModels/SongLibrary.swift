//
//  SongLibrary.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import Foundation

// MARK: - 歌曲库管理类
class SongLibrary: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var hasImportedLibrary = false
    
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let songsDirectoryName = "Songs"
    private let libraryConfigFileName = "SongLibrary.plist"
    
    var songsDirectory: URL {
        documentsPath.appendingPathComponent(songsDirectoryName)
    }
    
    var libraryConfigPath: URL {
        documentsPath.appendingPathComponent(libraryConfigFileName)
    }
    
    init() {
        loadLibraryStatus()
        if hasImportedLibrary {
            loadSongsFromLibrary()
        }
    }
    
    // MARK: - 导入音乐文件夹
    func importMusicFolder(_ folderURL: URL) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 确保权限访问
            let hasAccess = folderURL.startAccessingSecurityScopedResource()
            print("📁 开始访问文件夹权限: \(hasAccess)")
            
            if !hasAccess {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ 无法访问选择的文件夹")
                }
                return
            }
            
            defer {
                folderURL.stopAccessingSecurityScopedResource()
                print("📁 停止访问文件夹权限")
            }
            
            self.createSongsDirectoryIfNeeded()
            
            do {
                let songFolders = try self.scanMusicFolders(in: folderURL)
                print("📂 发现 \(songFolders.count) 个歌曲文件夹")
                
                if songFolders.isEmpty {
                    // 如果没有子文件夹，检查是否直接包含音频文件
                    let audioFiles = try self.scanAudioFiles(in: folderURL)
                    if !audioFiles.isEmpty {
                        print("🎵 直接在根目录发现 \(audioFiles.count) 个音频文件")
                        let importedSongs = self.processAudioFiles(audioFiles, rootURL: folderURL)
                        
                        DispatchQueue.main.async {
                            self.songs = importedSongs
                            self.hasImportedLibrary = true
                            self.isLoading = false
                            self.saveLibraryStatus()
                            print("✅ 成功导入 \(importedSongs.count) 首歌曲（直接模式）")
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            print("⚠️ 选择的文件夹中没有找到音频文件")
                        }
                    }
                    return
                }
                
                let importedSongs = self.processSongFolders(songFolders, rootURL: folderURL)
                
                DispatchQueue.main.async {
                    self.songs = importedSongs
                    self.hasImportedLibrary = true
                    self.isLoading = false
                    self.saveLibraryStatus()
                    print("✅ 成功导入 \(importedSongs.count) 首歌曲")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("❌ 导入失败: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 新增：扫描音频文件方法
    private func scanAudioFiles(in folderURL: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey])
        
        let audioFiles = contents.filter { url in
            let ext = url.pathExtension.lowercased()
            return ["mp3", "m4a", "wav", "flac", "aac"].contains(ext)
        }
        
        print("🔍 在 \(folderURL.lastPathComponent) 中发现 \(audioFiles.count) 个音频文件")
        return audioFiles
    }

    // MARK: - 新增：处理音频文件方法
    private func processAudioFiles(_ audioFiles: [URL], rootURL: URL) -> [Song] {
        var processedSongs: [Song] = []
        
        for audioFile in audioFiles {
            if let song = processSingleAudioFile(audioFile, rootURL: rootURL) {
                processedSongs.append(song)
            }
        }
        
        return processedSongs
    }

    // MARK: - 新增：处理单个音频文件
    private func processSingleAudioFile(_ audioFile: URL, rootURL: URL) -> Song? {
        let songName = audioFile.deletingPathExtension().lastPathComponent
        print("🎵 处理音频文件: \(songName)")
        
        do {
            // 创建目标文件夹
            let destinationFolder = songsDirectory.appendingPathComponent(songName)
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            
            let destinationAudioURL = destinationFolder.appendingPathComponent(audioFile.lastPathComponent)
            
            // 复制音频文件
            if FileManager.default.fileExists(atPath: destinationAudioURL.path) {
                try FileManager.default.removeItem(at: destinationAudioURL)
            }
            
            // 读取源文件数据并写入目标位置
            let audioData = try Data(contentsOf: audioFile)
            try audioData.write(to: destinationAudioURL)
            print("✅ 复制音频文件: \(audioFile.lastPathComponent)")
            
            // 查找同名歌词文件
            let lrcFile = audioFile.deletingPathExtension().appendingPathExtension("lrc")
            if FileManager.default.fileExists(atPath: lrcFile.path) {
                let destinationLrcURL = destinationFolder.appendingPathComponent(lrcFile.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationLrcURL.path) {
                    try FileManager.default.removeItem(at: destinationLrcURL)
                }
                
                let lrcData = try Data(contentsOf: lrcFile)
                try lrcData.write(to: destinationLrcURL)
                print("✅ 复制歌词文件: \(lrcFile.lastPathComponent)")
            }
            
            // 创建Song对象
            let song = Song(title: songName, artist: "未知艺术家", url: destinationAudioURL)
            print("✅ 成功处理歌曲: \(songName)")
            return song
            
        } catch {
            print("❌ 处理文件 \(songName) 失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 创建歌曲存储目录
    private func createSongsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: songsDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: songsDirectory, withIntermediateDirectories: true)
                print("创建歌曲目录: \(songsDirectory.path)")
            } catch {
                print("创建歌曲目录失败: \(error)")
            }
        }
    }
    
    // MARK: - 扫描音乐文件夹
    private func scanMusicFolders(in rootURL: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey])
        
        let songFolders = contents.filter { url in
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            return isDirectory.boolValue
        }
        
        print("发现 \(songFolders.count) 个歌曲文件夹")
        return songFolders
    }
    
    // MARK: - 处理歌曲文件夹
    private func processSongFolders(_ folders: [URL], rootURL: URL) -> [Song] {
        var processedSongs: [Song] = []
        
        for folderURL in folders {
            if let song = processSingleSongFolder(folderURL, rootURL: rootURL) {
                processedSongs.append(song)
            }
        }
        
        return processedSongs
    }
    
    // MARK: - 处理单个歌曲文件夹
    private func processSingleSongFolder(_ folderURL: URL, rootURL: URL) -> Song? {
        let songName = folderURL.lastPathComponent
        print("处理歌曲文件夹: \(songName)")
        
        do {
            // 确保有权限访问子文件夹
            let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            
            // 查找音频文件
            let audioFile = contents.first { url in
                let ext = url.pathExtension.lowercased()
                return ["mp3", "m4a", "wav", "flac", "aac"].contains(ext)
            }
            
            guard let audioFile = audioFile else {
                print("在文件夹 \(songName) 中未找到音频文件")
                return nil
            }
            
            // 查找歌词文件
            let lrcFile = contents.first { url in
                url.pathExtension.lowercased() == "lrc"
            }
            
            // 复制文件到app目录
            let destinationFolder = songsDirectory.appendingPathComponent(songName)
            try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
            
            let destinationAudioURL = destinationFolder.appendingPathComponent(audioFile.lastPathComponent)
            
            // 复制音频文件
            if FileManager.default.fileExists(atPath: destinationAudioURL.path) {
                try FileManager.default.removeItem(at: destinationAudioURL)
            }
            
            // 读取源文件数据并写入目标位置（避免权限问题）
            let audioData = try Data(contentsOf: audioFile)
            try audioData.write(to: destinationAudioURL)
            print("复制音频文件: \(audioFile.lastPathComponent)")
            
            // 复制歌词文件（如果存在）
            if let lrcFile = lrcFile {
                let destinationLrcURL = destinationFolder.appendingPathComponent(lrcFile.lastPathComponent)
                if FileManager.default.fileExists(atPath: destinationLrcURL.path) {
                    try FileManager.default.removeItem(at: destinationLrcURL)
                }
                
                let lrcData = try Data(contentsOf: lrcFile)
                try lrcData.write(to: destinationLrcURL)
                print("复制歌词文件: \(lrcFile.lastPathComponent)")
            }
            
            // 创建Song对象
            let song = Song(title: songName, artist: "未知艺术家", url: destinationAudioURL)
            print("成功处理歌曲: \(songName)")
            return song
            
        } catch {
            print("处理文件夹 \(songName) 失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 保存和加载库状态
    private func saveLibraryStatus() {
        let config = ["hasImportedLibrary": hasImportedLibrary]
        let data = try? PropertyListSerialization.data(fromPropertyList: config, format: .xml, options: 0)
        try? data?.write(to: libraryConfigPath)
    }
    
    private func loadLibraryStatus() {
        guard let data = try? Data(contentsOf: libraryConfigPath),
              let config = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Bool] else {
            return
        }
        hasImportedLibrary = config["hasImportedLibrary"] ?? false
    }
    
    private func loadSongsFromLibrary() {
        // 从本地存储的歌曲目录加载歌曲列表
        guard FileManager.default.fileExists(atPath: songsDirectory.path) else {
            print("歌曲目录不存在")
            return
        }
        
        do {
            let songFolders = try FileManager.default.contentsOfDirectory(at: songsDirectory, includingPropertiesForKeys: [.isDirectoryKey])
                .filter { url in
                    var isDirectory: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    return isDirectory.boolValue
                }
            
            var loadedSongs: [Song] = []
            
            for folderURL in songFolders {
                let songName = folderURL.lastPathComponent
                
                // 查找音频文件
                let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                if let audioFile = contents.first(where: { url in
                    let ext = url.pathExtension.lowercased()
                    return ["mp3", "m4a", "wav", "flac", "aac"].contains(ext)
                }) {
                    let song = Song(title: songName, artist: "未知艺术家", url: audioFile)
                    loadedSongs.append(song)
                }
            }
            
            DispatchQueue.main.async {
                self.songs = loadedSongs.sorted { $0.title < $1.title }
                print("从本地加载了 \(loadedSongs.count) 首歌曲")
            }
            
        } catch {
            print("加载本地歌曲失败: \(error)")
        }
    }
}
