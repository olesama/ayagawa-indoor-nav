import CoreLocation
import SwiftUI

struct SensorStatusView: View {
    @EnvironmentObject private var sensors: SensorManager

    var body: some View {
        List {
            Section("現在の状態") {
                LabeledContent("方位", value: sensors.heading.map { "\(Int($0))°" } ?? "未取得")
                LabeledContent("GPS精度", value: sensors.horizontalAccuracy.map { "±\(Int($0))m" } ?? "未取得")
                LabeledContent("歩数", value: "\(sensors.steps)歩")
                LabeledContent("推定歩行距離", value: String(format: "%.1fm", sensors.walkedMeters))
            }
            Section {
                Button("センサーを開始") { sensors.requestPermissionsAndStart() }
                Button("停止", role: .destructive) { sensors.stopSensors() }
            }
            Section("注意") {
                Text("GPSだけでは館内の階や通路を正確に特定できません。施設での実測・ビーコン等を導入するまでは、現地表示を優先してください。")
            }
        }
        .navigationTitle("センサー")
    }
}

