//
//  LyricsView.swift
//  Music
//
//  Created by Yaoxi Chen on 2025/5/24.
//

import SwiftUI

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
                .onChange(of: musicPlayer.currentLyricIndex) { oldValue, newValue in
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newValue, anchor: .center)
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
