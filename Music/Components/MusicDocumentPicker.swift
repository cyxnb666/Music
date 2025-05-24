//
//  MusicDocumentPicker.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 音乐文件选择器
struct MusicDocumentPicker: UIViewControllerRepresentable {
    let completion: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .audio,
            UTType.mp3,
            UTType.mpeg4Audio, // m4a, aac
            UTType.wav,
            UTType(filenameExtension: "flac") ?? .audio,
            UTType(filenameExtension: "ogg") ?? .audio
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: MusicDocumentPicker
        
        init(_ parent: MusicDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("选择了音乐文件: \(urls)")
            parent.completion(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("音乐文件选择被取消")
        }
    }
}
