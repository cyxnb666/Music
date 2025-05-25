//
//  WelcomeView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 欢迎界面
struct WelcomeView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @EnvironmentObject var songLibrary: SongLibrary
    @State private var showingFolderPicker = false
    @State private var showingFolderInfo = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primary)
            
            Text("欢迎使用音乐播放器")
                .font(.title)
                .fontWeight(.bold)
            
            Text("导入您的音乐文件夹开始使用")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Button(action: {
                    print("点击导入音乐文件夹按钮")
                    showingFolderPicker = true
                }) {
                    Label("导入音乐文件夹", systemImage: "folder.badge.plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.primary)
                        .cornerRadius(12)
                }
                .opacity(songLibrary.isLoading ? 0.6 : 1.0)
                .disabled(songLibrary.isLoading)
                
                Button(action: {
                    showingFolderInfo = true
                }) {
                    Text("❓ 文件夹应该如何组织？")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 显示加载状态
                if songLibrary.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("正在扫描音乐文件...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showingFolderPicker) {
            FolderDocumentPicker { folderURL in
                if let folderURL = folderURL {
                    print("用户选择了文件夹: \(folderURL)")
                    songLibrary.importMusicFolder(folderURL)
                }
            }
        }
        .alert("音乐文件夹结构说明", isPresented: $showingFolderInfo) {
            Button("知道了") { }
        } message: {
            Text("""
请选择包含歌曲子文件夹的主文件夹。

文件夹结构应该是：
📁 我的音乐
  📁 七里香
    🎵 七里香.mp3
    📝 七里香.lrc
  📁 白色风车  
    🎵 白色风车.m4a
    📝 白色风车.lrc

每个歌曲文件夹名称将作为歌曲标题。
歌词文件(.lrc)是可选的。
""")
        }
    }
}
