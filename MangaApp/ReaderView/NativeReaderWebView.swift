//
//  WebView.swift
//  swiftui-stream-test
//
//  Created by Preston Clayton on 7/30/22.
//

import SwiftUI
import WebKit
import SwiftSoup

struct NativeReaderWebView: UIViewRepresentable {
    var url = URL(string: "https://mangareader.to/read/spy-x-family-86/ja/chapter-2")!
    var isFirstRun = true

    @Binding var links : [URL?]
    
    let unshuffleScript = """
    var p = new Promise(async (resolve, reject) => {
        try {
            const canvas = await imgReverser(link);
            const uri = canvas.toDataURL('image/jpeg', 1);
            resolve(uri);
        } catch(error) {
            reject(error);
        }
    });
    await p
    return p
    """
    
    let unshuffleScriptBatch = """
    var p = new Promise(async (resolve, reject) => {
        try {
            let images = [];
            const data = links;
            for(const d of data) {
                const canvas = await imgReverser(d);
                const uri = canvas.toDataURL('image/jpeg', 1);
                images.push(uri);
            }
            resolve(images);
        } catch(error) {
            reject(error);
        }
    });
    await p
    return p
    """
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: NativeReaderWebView
        
        init(_ parent: NativeReaderWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if self.parent.isFirstRun {
                Task {
                    let id = try await getChapterID(webView: webView)
                    
                    let url = URL(string: "ajax/image/list/chap/\(id)?quality=high", relativeTo: baseurl)!
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let json = try JSONDecoder().decode(mangaReaderImgRequest.self, from: data)
                    let doc: Document = try SwiftSoup.parse(json.html)
                    let linkArr = try doc.select("div.iv-card")
                    
                    if( (linkArr.count == 0) || !linkArr[0].hasClass("shuffled")) {
                        self.parent.links.append(contentsOf: try linkArr.map {try URL(string: $0.attr("data-url"))! } )
                    }
                    
                    let linkList = try linkArr.map {try $0.attr("data-url")}
                    
//                    await loadUnscrambledImagesBatch(webView: webView, list: linkList)
                    await loadUnscrambledImagesBatch(webView: webView, list: linkList)

                }
                
                insertCSSString(into: webView)
                print("Done Loading")
                
                self.parent.isFirstRun = false
            }
        }
        
        @MainActor
        func getChapterID(webView: WKWebView) async throws -> String {
            let value = try await webView.evaluateJavaScript("wrapper.dataset.readingId.toString()")
            return String(describing: value)
        }


        func insertCSSString(into webView: WKWebView) {
//            let cssString = """
//            #header { display: none;}
//            """
//            let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
            let jsString = """
            const element = document.getElementById("header");
            element.remove();
            const ad = document.getElementById("vi-smartbanner");
            ad.remove();
            """
            webView.evaluateJavaScript(jsString, completionHandler: nil)
        }
        
        func loadUnscrambledImages(webView: WKWebView, list: [String]) async -> Void {
            self.parent.links = Array(repeating: nil, count: list.count)
            for (index, link) in list.enumerated() {
                await webView.callAsyncJavaScript(self.parent.unshuffleScript, arguments: ["link" : link], in: nil, in: WKContentWorld.page) { result in
                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let data):
                        let url = URL(string: data as! String)!
                        self.parent.links[index] = url
                        sleep(1)
                    }
                }
            }
        }
        
        func loadUnscrambledImagesBatch(webView: WKWebView, list: [String]) async -> Void {
            await webView.callAsyncJavaScript(self.parent.unshuffleScriptBatch, arguments: ["links" : list], in: nil, in: WKContentWorld.page) { result in
                switch result {
                case .failure(let error):
                    print(error)
                case .success(let data):
                    for i in (data as! [String]) {
                        let url = URL(string: i)!
                        self.parent.links.append(url)
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs
        return WKWebView(frame: .zero, configuration: config)
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.navigationDelegate = context.coordinator
        webView.isHidden = true
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
