import SwiftUI
import WebKit

struct WebNavigationView: View {
    let facility: Facility
    @EnvironmentObject private var sensors: SensorManager

    var body: some View {
        WebAppView(facilityID: facility.id, sensors: sensors)
            .navigationTitle(facility.name)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { sensors.requestPermissionsAndStart() }
            .onDisappear { sensors.stopSensors() }
    }
}

struct WebAppView: UIViewRepresentable {
    let facilityID: String
    @ObservedObject var sensors: SensorManager

    func makeCoordinator() -> Coordinator { Coordinator(facilityID: facilityID) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.load(URLRequest(url: URL(string: "https://olesama.github.io/ayagawa-indoor-nav/")!, cachePolicy: .reloadRevalidatingCacheData))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let heading = sensors.heading.map { String($0) } ?? "null"
        let accuracy = sensors.horizontalAccuracy.map { String($0) } ?? "null"
        let script = "window.NativeKannaiNavi={heading:\(heading),accuracy:\(accuracy),steps:\(sensors.steps),walkedMeters:\(sensors.walkedMeters)};"
        webView.evaluateJavaScript(script)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let facilityID: String
        init(facilityID: String) { self.facilityID = facilityID }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let escaped = facilityID.replacingOccurrences(of: "'", with: "\\'")
            webView.evaluateJavaScript("if(typeof changeFacility==='function'){changeFacility('\(escaped)')}" )
        }
    }
}
