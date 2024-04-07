//
//  WebView.swift
//  swiftui-stream-test
//
//  Created by Preston Clayton on 7/30/22.
//

import SwiftUI
import WebKit
import SwiftSoup

//extension WKWebView {
//    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        return nil
//    }
//}
//
struct ReaderWebView: UIViewRepresentable, Equatable {
    @ObservedObject var model: WebViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    static func == (lhs: ReaderWebView, rhs: ReaderWebView) -> Bool {
        return true
    }
    
    let nextAction: ()->Void
    let prevAction: ()->Void
        
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ReaderWebView
        
        init(_ parent: ReaderWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("""
            function nextChapterVolume() {
                window.webkit.messageHandlers.callbackHandler.postMessage("next");
            }
            function prevChapterVolume() {
                window.webkit.messageHandlers.callbackHandler.postMessage("prev");
            }
            
            const skip = e => e.stopPropagation();
            
            document.addEventListener('dragstart', skip, true);
            document.addEventListener('selectstart', skip, true);
            document.addEventListener('copy', skip, true);
            document.addEventListener('cut', skip, true);
            document.addEventListener('paste', skip, true);
            document.addEventListener('contextmenu', skip, true);
            document.addEventListener('mousedown', skip, true);
            """)
            if parent.model.vertical == false {
                webView.isUserInteractionEnabled = true
            }
        }
        
        //disable changing main frame url
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let backgroundColor = colorScheme == .dark ? "000" : "FFF"
        let cssString = """
        @media screen and (max-width: 479px) {
            .container-reader-chapter {
                padding-top: 0;
           }
        }
        body.page-reader {
            background: #\(backgroundColor)!important;
        }
        .container-reader-chapter .iv-card {
            margin: 0;
        }
        #header {
            display: none;
        }
        #vi-smartbanner {
            display: none;
        }
        .mrt-bottom {
            display : none;
        }
        .dt-rate {
            display : none;
        }
        .navi-buttons {
            background: #\(backgroundColor)!important;
        }
        #main-wrapper.page-read-hoz {
            background: #\(backgroundColor);
            overflow: hidden;
        }
        .navi-buttons .nabu.nabu-right {
            display: none;
        }
        .navi-buttons .nabu.nabu-left {
            display: none;
        }
        .container-reader-hoz .ds-image {
            background: #\(backgroundColor);
        }
        .sc-dt-rate {
            display: none;
        }
        .ds-image .sc-btn {
            display: none;
        }
        .st-cmp-settings {
         display: none;
        }
        """.filter { !"\n".contains($0) }
        
        let jsString = """
        var style = document.createElement('style');
        style.innerHTML = '\(cssString)';
        document.head.appendChild(style);
        """
        
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        let userContentController = WKUserContentController()
        let userscript = WKUserScript(source: jsString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        prefs.allowsContentJavaScript = true
        userContentController.addUserScript(userscript)
        userContentController.add(ContentController(self), name: "callbackHandler")
        
        
        config.userContentController = userContentController
        config.defaultWebpagePreferences = prefs
        
        
        let webView = WKWebView(frame: .zero, configuration: config)
//        if #available(iOS 16.4, *) {
//            webView.isInspectable = true
//        }
        
        webView.navigationDelegate = context.coordinator
        
        model.webView = webView
        
        webView.scrollView.showsVerticalScrollIndicator = false
        
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if model.vertical == false {
            webView.isUserInteractionEnabled = false
        }
        let url = URL(string: model.chapter.link, relativeTo: baseurl)!
        
        if webView.url != url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    class ContentController: NSObject, WKScriptMessageHandler {
        var parent: ReaderWebView
        
        init(_ parent: ReaderWebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if(message.name == "callbackHandler") {
                if let callback = message.body as? String {
                    if callback == "next" {
                        parent.nextAction()
                    } else if callback == "prev" {
                        parent.prevAction()
                    }
                }
            }
        }
    }
}

class WebViewModel: ObservableObject {
    var webView: WKWebView?  {
        didSet {
            Task {
                await getReaderSettings()
            }
        }
    }
    @Published var loadingWebView = true

    @Published var vertical: Bool? = nil
    @Published var rtl: Bool? = nil
    
    @Published var index: Int? = nil
    @Published var isFirst: Bool = false
    @Published var isLast: Bool = false

    @Published var chapter: Chapter 
    
    let chapters: [Chapter]
    
    init(chapter: Chapter, chapters: [Chapter]) {
        self.chapter = chapter
        self.chapters = chapters
    }
    
    @MainActor
    func getReaderSettings() async {
        print("got reader settings")
        self.loadingWebView = false
        if let cookie = HTTPCookieStorage.shared.cookies(for: baseurl)?.first(where: {$0.name == "mr_settings"}) {
            if cookie.value.contains("vertical"){
                self.vertical = Optional(true)
            } else {
                self.vertical = Optional(false)
            }
            if cookie.value.contains("rtl"){
                self.rtl = Optional(true)
            } else {
                self.rtl = Optional(false)
            }
        } else {
            self.vertical = Optional(true)
            self.rtl = Optional(true)
        }
    }
}

let horizontalScript = """
var button = document.querySelector("[data-value=horizontal]");
button.click();
"""
let verticalScript = """
var button = document.querySelector("[data-value=vertical]");
button.click();
"""
let rtlScript = """
var button = document.querySelector("[data-value=rtl]");
button.click();
"""
let ltrScript = """
var button = document.querySelector("[data-value=ltr]");
button.click();
"""

let nextScript = """
nextChapterVolume();
"""
let prevScript = """
prevChapterVolume();
"""
let getTitleScript = """
var text = document.querySelector("#current-chapter");
return text.textContent;
"""
let getReadingModeScript = """
var mode = settings.readingMode
return mode == "vertical"
"""
let getReadingDirectionScript = """
var mode = settings.readingMode
return mode == "rtl"
"""
