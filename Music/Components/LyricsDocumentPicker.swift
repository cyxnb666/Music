//
//  LyricsDocumentPicker.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 歌词文件选择器
struct LyricsDocumentPicker: UIViewControllerRepresentable {
    let completion: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            .text,
            .plainText,
            UTType(filenameExtension: "lrc") ?? .text,
            UTType(filenameExtension: "txt") ?? .text
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
        let parent: LyricsDocumentPicker
        
        init(_ parent: LyricsDocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            print("选择了歌词文件: \(urls)")
            parent.completion(urls)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("歌词文件选择被取消")
        }
    }
}
