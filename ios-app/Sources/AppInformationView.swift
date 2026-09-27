import SwiftUI

struct AppInformationView: View {
    var body: some View {
        List {
            Section("館内ナビ") {
                Text("全国89施設の目的地検索と概算案内に対応しています。")
                Link("公開Web版を開く", destination: URL(string: "https://olesama.github.io/ayagawa-indoor-nav/")!)
            }
            Section("安全") {
                Text("距離・方向・経路には推定値が含まれます。現地の標識、施設係員、公式案内を優先してください。歩行中の画面注視は禁止です。")
            }
            Section("法的情報") {
                Link("利用規約", destination: URL(string: "https://olesama.github.io/ayagawa-indoor-nav/03_%E5%88%A9%E7%94%A8%E8%A6%8F%E7%B4%84.html")!)
                Link("プライバシーポリシー", destination: URL(string: "https://olesama.github.io/ayagawa-indoor-nav/04_%E3%83%95%E3%82%9A%E3%83%A9%E3%82%A4%E3%83%8F%E3%82%99%E3%82%B7%E3%83%BC%E3%83%9B%E3%82%9A%E3%83%AA%E3%82%B7%E3%83%BC.html")!)
            }
        }
        .navigationTitle("アプリ情報")
    }
}

