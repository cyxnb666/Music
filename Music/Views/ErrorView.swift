//
//  ErrorView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/6/5.
//

import SwiftUI

// MARK: - 错误处理界面
struct ErrorView: View {
    let title: String
    let message: String
    let actionTitle: String?
    let onAction: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(
        title: String = "出现问题",
        message: String,
        actionTitle: String? = nil,
        onAction: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 错误图标
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 30))
                    .foregroundColor(.red)
            }
            
            // 错误信息
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // 操作按钮
            VStack(spacing: 12) {
                if let actionTitle = actionTitle, let onAction = onAction {
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        onAction()
                    }) {
                        Text(actionTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.primary)
                            .cornerRadius(12)
                    }
                }
                
                if let onDismiss = onDismiss {
                    Button("知道了") {
                        HapticManager.shared.buttonTap()
                        onDismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.adaptiveBackground)
                .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - 文件权限错误专用视图
struct FilePermissionErrorView: View {
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        ErrorView(
            title: "无法访问文件",
            message: """
            应用无法访问选择的音乐文件夹。这可能是因为：
            
            • 文件夹权限受限
            • 文件已被移动或删除
            • 系统安全设置限制
            
            请尝试重新选择文件夹，或选择其他位置的音乐文件。
            """,
            actionTitle: "重新选择文件夹",
            onAction: onRetry,
            onDismiss: onDismiss
        )
    }
}

// MARK: - 无音频文件错误视图
struct NoAudioFilesErrorView: View {
    let onRetry: () -> Void
    let onShowHelp: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // 图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
            }
            
            // 信息
            VStack(spacing: 8) {
                Text("未找到音频文件")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("选择的文件夹中没有找到支持的音频文件。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Text("支持的格式：MP3, M4A, WAV, FLAC, AAC")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            // 按钮
            VStack(spacing: 12) {
                Button("重新选择文件夹") {
                    HapticManager.shared.buttonTap()
                    onRetry()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary)
                .cornerRadius(12)
                
                Button("查看文件夹结构说明") {
                    HapticManager.shared.buttonTap()
                    onShowHelp()
                }
                .foregroundColor(AppColors.primary)
                
                Button("取消") {
                    HapticManager.shared.buttonTap()
                    onDismiss()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.adaptiveBackground)
                .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - 预览
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            ErrorView(
                title: "导入失败",
                message: "无法读取选择的音乐文件夹，请检查文件夹权限或重新选择。",
                actionTitle: "重试",
                onAction: { print("重试") },
                onDismiss: { print("关闭") }
            )
            
            FilePermissionErrorView(
                onRetry: { print("重试") },
                onDismiss: { print("关闭") }
            )
        }
        .background(AppColors.adaptiveSecondaryBackground)
    }
}
