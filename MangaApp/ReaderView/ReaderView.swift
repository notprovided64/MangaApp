//
//  ReaderView.swift
//  WebViewTest
//
//  Created by Preston Clayton on 8/17/22.
//

import SwiftUI

struct ReaderView: View {
    @StateObject var model: WebViewModel
    
    let readerMode: Bool
    
    @State private var showNavigationBar = true
    var body: some View {
        ZStack {
            ReaderWebView(model: model, nextAction: {nextChapter()}, prevAction: {prevChapter()})
                .equatable()
        }
        .ignoresSafeArea(.container, edges: [.bottom])
        .navigationTitle(model.chapter.name)
        .task {
            checkIndex()
        }
        .persistentSystemOverlays(.hidden)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Menu("Reader Settings") {
                        Picker(selection: $model.vertical, label: Text("Reader Mode") ) {
                            Text("Vertical").tag(Optional(true))
                            Text("Horizontal").tag(Optional(false))
                        }
                        .onChange(of: model.vertical) { _ in
                            setReaderMode()
                        }
                        .disabled(model.loadingWebView)
                        if model.vertical == false {
                            Picker(selection: $model.rtl, label: Text("Reader Direction") ) {
                                Text("Right to Left").tag(Optional(true))
                                Text("Left to Right").tag(Optional(false))
                            }
                            .onChange(of: model.rtl) { _ in
                                setReaderDirection()
                            }
                            .disabled(model.loadingWebView)
                        }
                        Button() {
                            model.webView?.reload()
                        } label: { Label("Reload", systemImage: "arrow.clockwise") }
                            .disabled(model.loadingWebView)
                    }
                    Menu(readerMode ? "Chapters" : "Volumes"){
                        ForEach(model.chapters, id: \.self) { chapter in
                            if chapter.lang == model.chapter.lang {
                                Button() {
                                    model.chapter = chapter
                                    checkIndex()
                                } label: { Text(chapter.name) }
                            }
                        }
                    }
                    Button() {
                        nextChapter()
                    } label: { Label("Next", systemImage: "arrow.right") }
                        .disabled(model.loadingWebView || model.isLast)
                    Button() {
                        prevChapter()
                    } label: { Label("Previous", systemImage: "arrow.left") }
                        .disabled(model.loadingWebView || model.isFirst)
                } label : {
                    Image(systemName: "gearshape")
                }
            }
        }
        .toolbar(showNavigationBar ? .visible : .hidden)
        .simultaneousGesture(
            LongPressGesture()
                .onEnded { _ in
                    if model.vertical == false {
                        showNavigationBar.toggle()
                    }
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded { _ in
                    if model.vertical == true {
                        showNavigationBar.toggle()
                    }
                }
        )
    }
    func checkIndex() {
        if let index = model.chapters.firstIndex(of: model.chapter) {
            model.index = index
            model.isLast = index == 0
            model.isFirst = index == model.chapters.count-1
        }
    }
    
    func nextChapter() {
        if model.index != nil && !model.isLast {
            model.chapter = model.chapters[model.index!-1]
            checkIndex()
        }
    }
    func prevChapter() {
        if model.index != nil && !model.isFirst {
            model.chapter = model.chapters[model.index!+1]
            checkIndex()
        }
    }

    func setReaderMode() {
        if model.vertical == true {
            model.webView?.evaluateJavaScript(verticalScript)
        } else if model.vertical == false {
            model.webView?.evaluateJavaScript(horizontalScript)
        }
    }
    func setReaderDirection() {
        if model.rtl == true {
            model.webView?.evaluateJavaScript(rtlScript)
        } else if model.rtl == false{
            model.webView?.evaluateJavaScript(ltrScript)
        }
    }
}

//struct ReaderView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReaderView()
//    }
//}
