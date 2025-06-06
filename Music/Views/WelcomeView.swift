//
//  WelcomeView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

// MARK: - 欢迎界面（Apple Music风格）
struct WelcomeView: View {
    @EnvironmentObject var musicPlayer: MusicPlayer
    @EnvironmentObject var songLibrary: SongLibrary
    @State private var showingFolderPicker = false
    @State private var showingFolderInfo = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var logoScale: CGFloat = 1.0
    @State private var contentOpacity: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                // Logo区域 - 增强动画
                VStack(spacing: 24) {
                    ZStack {
                        // 背景光晕效果
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                            .opacity(0.3)
                            .scaleEffect(logoScale)
                        
                        // 主图标
                        Circle()
                            .fill(AppColors.primaryGradient)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: AppColors.deepShadow, radius: 10, x: 0, y: 5)
                            .scaleEffect(logoScale)
                    }
                    .onAppear {
                        withAnimation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                        ) {
                            logoScale = 1.05
                        }
                    }
                    
                    // 标题文字
                    VStack(spacing: 8) {
                        Text("欢迎使用音乐播放器")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("导入您的音乐文件夹开始使用")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(0.8)
                    }
                }
                .opacity(contentOpacity)
                .scaleEffect(contentOpacity)
                .animation(AppleAnimations.standardTransition, value: contentOpacity)
                
                Spacer()
                
                // 操作按钮区域
                VStack(spacing: 20) {
                    // 主要导入按钮
                    Button(action: {
                        HapticManager.shared.interfaceTransition()
                        print("点击导入音乐文件夹按钮")
                        showingFolderPicker = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.title3)
                            Text("导入音乐文件夹")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.primaryGradient)
                                .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(songLibrary.isLoading)
                    .opacity(songLibrary.isLoading ? 0.6 : 1.0)
                    .animation(AppleAnimations.microInteraction, value: songLibrary.isLoading)
                    .accessibilityLabel("导入音乐文件夹")
                    .accessibilityHint("选择包含音乐文件的文件夹")
                    
                    // 帮助按钮
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        showingFolderInfo = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                            Text("文件夹应该如何组织？")
                                .font(.caption)
                        }
                        .foregroundColor(AppColors.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppColors.primaryOpacity08)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("查看文件夹组织帮助")
                    
                    // 加载状态指示器
                    if songLibrary.isLoading {
                        VStack(spacing: 12) {
                            // 自定义加载动画
                            HStack(spacing: 4) {
                                ForEach(0..<3) { index in
                                    Circle()
                                        .fill(AppColors.primary)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(logoScale)
                                        .animation(
                                            Animation.easeInOut(duration: 0.6)
                                                .repeatForever()
                                                .delay(Double(index) * 0.2),
                                            value: logoScale
                                        )
                                }
                            }
                            
                            Text("正在扫描音乐文件...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppColors.adaptiveSecondaryBackground)
                                .shadow(color: AppColors.lightShadow, radius: 4, x: 0, y: 2)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .animation(AppleAnimations.standardTransition, value: songLibrary.isLoading)
                    }
                }
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
                .animation(AppleAnimations.standardTransition, value: contentOpacity)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.adaptiveBackground,
                        AppColors.adaptiveSecondaryBackground.opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .sheet(isPresented: $showingFolderPicker) {
            FolderDocumentPicker { folderURL in
                if let folderURL = folderURL {
                    HapticManager.shared.fileImport()
                    print("用户选择了文件夹: \(folderURL)")
                    
                    // 添加加载动画
                    withAnimation(AppleAnimations.standardTransition) {
                        contentOpacity = 0.7
                    }
                    
                    songLibrary.importMusicFolder(folderURL)
                } else {
                    // 用户取消选择
                    showingError = true
                    errorMessage = "未选择文件夹"
                }
            }
        }
        .alert("音乐文件夹结构说明", isPresented: $showingFolderInfo) {
            Button("知道了") {
                HapticManager.shared.buttonTap()
            }
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
        // 错误处理覆盖层
        .overlay(
            Group {
                if showingError {
                    ZStack {
                        AppColors.adaptiveBackground.opacity(0.8)
                            .ignoresSafeArea()
                        
                        FilePermissionErrorView(
                            onRetry: {
                                showingError = false
                                showingFolderPicker = true
                            },
                            onDismiss: {
                                showingError = false
                            }
                        )
                    }
                    .transition(.opacity)
                    .animation(AppleAnimations.standardTransition, value: showingError)
                }
            }
        )
        .onAppear {
            HapticManager.shared.prepare()
            
            // 初始动画
            withAnimation(AppleAnimations.standardTransition.delay(0.3)) {
                contentOpacity = 1.0
            }
        }
        .onChange(of: songLibrary.isLoading) { oldValue, newValue in
            // 加载状态变化时恢复透明度
            if !newValue && oldValue {
                withAnimation(AppleAnimations.standardTransition) {
                    contentOpacity = 1.0
                }
                
                // 检查是否导入成功
                if songLibrary.songs.isEmpty && songLibrary.hasImportedLibrary == false {
                    showingError = true
                    errorMessage = "导入失败或未找到音频文件"
                }
            }
        }
    }
}

// MARK: - 自定义按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppleAnimations.microInteraction, value: configuration.isPressed)
    }
}

// MARK: - 预览
struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WelcomeView()
                .environmentObject(SongLibrary())
                .environmentObject(MusicPlayer())
                .preferredColorScheme(.light)
            
            WelcomeView()
                .environmentObject({
                    let library = SongLibrary()
                    library.isLoading = true
                    return library
                }())
                .environmentObject(MusicPlayer())
                .preferredColorScheme(.dark)
        }
    }
}
